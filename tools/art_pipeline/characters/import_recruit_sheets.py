#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import io
import json
import sys
from pathlib import Path
from typing import Iterable

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from recruit_approval import authenticate_recruit_approval

from import_round5_sheets import (
    PALETTE,
    PALETTE_RGB,
    add_outline,
    crouched,
    distance_sq,
    largest_component,
    border_background,
    save_atomic,
    shifted,
    upper_shift,
)

PORTRAIT_SOURCE_SIZE = (2304, 1536)
FIELD_SOURCE_SIZE = (1920, 1920)
PORTRAIT_GRID = (4, 2)
PORTRAIT_CELL_SIZE = (
    PORTRAIT_SOURCE_SIZE[0] // PORTRAIT_GRID[0],
    PORTRAIT_SOURCE_SIZE[1] // PORTRAIT_GRID[1],
)
PORTRAIT_SIZE = (128, 128)
FIELD_SIZE = (32, 32)
PORTRAIT_MARGIN = 3
FIELD_MARGIN = 2
FIELD_BACKGROUND = (241, 29, 236)
FIELD_BACKGROUND_MAX_DISTANCE = 32
MAGENTA_MIN_RED = 235
MAGENTA_MAX_GREEN = 40
MAGENTA_MIN_BLUE = 220
PRIMARY_COMPONENT_MIN_RATIO = 0.95
SECONDARY_COMPONENT_MAX_RATIO = 0.05
PORTRAIT_IDS = [f"recruit_{index:02d}" for index in range(8)]
RESERVED_RGB = {
    tuple(bytes.fromhex("f4f4f4")),
    tuple(bytes.fromhex("41a6f6")),
}
RECRUIT_PALETTE_RGB = [
    color
    for color in PALETTE_RGB
    if color not in {
        tuple(bytes.fromhex("c964cf")),
        tuple(bytes.fromhex("94216a")),
        tuple(bytes.fromhex("e39aac")),
    }
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[3])
    parser.add_argument("--review-dir", type=Path)
    return parser.parse_args()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def png_bytes(image: Image.Image) -> bytes:
    output = io.BytesIO()
    image.save(output, format="PNG", optimize=False, compress_level=9)
    return output.getvalue()


def source_background(image: Image.Image) -> tuple[int, int, int]:
    rgba = image.convert("RGBA")
    corners = [
        rgba.getpixel((0, 0))[:3],
        rgba.getpixel((rgba.width - 1, 0))[:3],
        rgba.getpixel((0, rgba.height - 1))[:3],
        rgba.getpixel((rgba.width - 1, rgba.height - 1))[:3],
    ]
    return tuple(sorted(channel)[len(channel) // 2] for channel in zip(*corners))


def foreground_components(image: Image.Image, min_alpha: int = 32) -> list[dict[str, object]]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    opaque = bytearray(1 if value >= min_alpha else 0 for value in rgba.getchannel("A").tobytes())
    seen = bytearray(width * height)
    components: list[dict[str, object]] = []
    for key, value in enumerate(opaque):
        if not value or seen[key]:
            continue
        stack = [key]
        seen[key] = 1
        keys: list[int] = []
        while stack:
            current = stack.pop()
            keys.append(current)
            x = current % width
            y = current // width
            for neighbor_x, neighbor_y in (
                (x - 1, y),
                (x + 1, y),
                (x, y - 1),
                (x, y + 1),
            ):
                if neighbor_x < 0 or neighbor_x >= width or neighbor_y < 0 or neighbor_y >= height:
                    continue
                neighbor = neighbor_y * width + neighbor_x
                if opaque[neighbor] and not seen[neighbor]:
                    seen[neighbor] = 1
                    stack.append(neighbor)
        xs = [component_key % width for component_key in keys]
        ys = [component_key // width for component_key in keys]
        components.append(
            {
                "pixels": len(keys),
                "bbox": (min(xs), min(ys), max(xs) + 1, max(ys) + 1),
            }
        )
    components.sort(key=lambda row: int(row["pixels"]), reverse=True)
    return components


def validate_source_subject(source: Image.Image, label: str, field: bool) -> None:
    background = source_background(source)
    if not (
        background[0] >= MAGENTA_MIN_RED
        and background[1] <= MAGENTA_MAX_GREEN
        and background[2] >= MAGENTA_MIN_BLUE
    ):
        raise ValueError(f"{label}: source background is not the approved magenta key: {background}")
    if field:
        if background != FIELD_BACKGROUND:
            raise ValueError(f"{label}: field background signature changed: {background}")
        border: list[tuple[int, int, int]] = []
        rgba = source.convert("RGBA")
        for x in range(rgba.width):
            border.extend([rgba.getpixel((x, 0))[:3], rgba.getpixel((x, rgba.height - 1))[:3]])
        for y in range(rgba.height):
            border.extend([rgba.getpixel((0, y))[:3], rgba.getpixel((rgba.width - 1, y))[:3]])
        if any(
            distance_sq(pixel, FIELD_BACKGROUND) > FIELD_BACKGROUND_MAX_DISTANCE**2
            for pixel in border
        ):
            raise ValueError(f"{label}: field border is not the approved solid chroma-key field")
    keyed = remove_chroma_fringe(border_background(source), background)
    components = foreground_components(keyed)
    if not components:
        raise ValueError(f"{label}: source contains no foreground subject")
    total_pixels = sum(int(row["pixels"]) for row in components)
    primary_pixels = int(components[0]["pixels"])
    primary_ratio = primary_pixels / total_pixels
    if primary_ratio < PRIMARY_COMPONENT_MIN_RATIO:
        raise ValueError(
            f"{label}: ambiguous or detached foreground components, primary_ratio={primary_ratio:.6f}"
        )
    if len(components) > 1:
        secondary_ratio = int(components[1]["pixels"]) / primary_pixels
        if secondary_ratio > SECONDARY_COMPONENT_MAX_RATIO:
            raise ValueError(
                f"{label}: peer foreground component, secondary_ratio={secondary_ratio:.6f}"
            )
    left, top, right, bottom = components[0]["bbox"]
    width_ratio = (right - left) / source.width
    height_ratio = (bottom - top) / source.height
    area_ratio = primary_pixels / (source.width * source.height)
    min_width = 0.15 if field else 0.40
    min_area = 0.05 if field else 0.20
    alpha = keyed.getchannel("A")
    top_contact = any(alpha.getpixel((x, 0)) >= 32 for x in range(source.width))
    bottom_contact = any(
        alpha.getpixel((x, source.height - 1)) >= 32 for x in range(source.width)
    )
    if top_contact or top < round(source.height * 0.03):
        raise ValueError(f"{label}: principal subject is clipped at the top edge")
    if bottom_contact:
        raise ValueError(f"{label}: principal subject is clipped at the bottom edge")
    if field:
        left_contact = any(alpha.getpixel((0, y)) >= 32 for y in range(source.height))
        right_contact = any(
            alpha.getpixel((source.width - 1, y)) >= 32 for y in range(source.height)
        )
        if left_contact or right_contact or left <= 0 or right >= source.width:
            raise ValueError(f"{label}: field subject is clipped at a side edge")
    else:
        upper_limit = round(source.height * 0.60)
        upper_left_contact = any(alpha.getpixel((0, y)) >= 32 for y in range(upper_limit))
        upper_right_contact = any(
            alpha.getpixel((source.width - 1, y)) >= 32 for y in range(upper_limit)
        )
        if upper_left_contact or upper_right_contact:
            raise ValueError(f"{label}: portrait head or upper body is clipped at a side edge")
    if width_ratio < min_width or height_ratio < 0.50 or area_ratio < min_area:
        raise ValueError(
            f"{label}: incomplete foreground occupancy width={width_ratio:.4f} "
            f"height={height_ratio:.4f} area={area_ratio:.4f}"
        )


def remove_chroma_fringe(
    image: Image.Image,
    background: tuple[int, int, int],
    tolerance: int = 140,
    passes: int = 3,
) -> Image.Image:
    rgba = image.convert("RGBA")
    for _ in range(passes):
        pixels = rgba.load()
        to_clear: list[tuple[int, int]] = []
        for y in range(1, rgba.height - 1):
            for x in range(1, rgba.width - 1):
                red, green, blue, alpha = pixels[x, y]
                if alpha == 0 or distance_sq((red, green, blue), background) > tolerance * tolerance:
                    continue
                touches_transparent = any(
                    pixels[x + dx, y + dy][3] == 0
                    for dx, dy in (
                        (-1, -1), (0, -1), (1, -1),
                        (-1, 0), (1, 0),
                        (-1, 1), (0, 1), (1, 1),
                    )
                )
                if touches_transparent:
                    to_clear.append((x, y))
        if not to_clear:
            break
        for x, y in to_clear:
            pixels[x, y] = (0, 0, 0, 0)
    return rgba


def hard_alpha_and_recruit_palette(image: Image.Image) -> Image.Image:
    source = image.convert("RGBA")
    output = Image.new("RGBA", source.size, (0, 0, 0, 0))
    source_pixels = source.load()
    target_pixels = output.load()
    for y in range(source.height):
        for x in range(source.width):
            red, green, blue, alpha = source_pixels[x, y]
            if alpha < 40:
                continue
            color = min(
                RECRUIT_PALETTE_RGB,
                key=lambda candidate: distance_sq((red, green, blue), candidate),
            )
            target_pixels[x, y] = (*color, 255)
    return output


def normalize_subject(source: Image.Image, size: tuple[int, int], margin: int) -> Image.Image:
    keyed = border_background(source)
    subject = largest_component(remove_chroma_fringe(keyed, source_background(source)))
    bbox = subject.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("source crop became empty after background removal")
    subject = subject.crop(bbox)
    target_width = max(1, size[0] - 2 * margin)
    target_height = max(1, size[1] - 2 * margin)
    scale = min(target_width / subject.width, target_height / subject.height)
    resized = subject.resize(
        (max(1, round(subject.width * scale)), max(1, round(subject.height * scale))),
        Image.Resampling.LANCZOS,
    )
    output = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (size[0] - resized.width) // 2
    y = size[1] - margin - resized.height
    output.alpha_composite(resized, (x, y))
    return hard_alpha_and_recruit_palette(output)


def portrait_crop(index: int) -> tuple[int, int, int, int]:
    column = index % PORTRAIT_GRID[0]
    row = index // PORTRAIT_GRID[0]
    left = column * PORTRAIT_CELL_SIZE[0]
    top = row * PORTRAIT_CELL_SIZE[1]
    return (
        left,
        top,
        left + PORTRAIT_CELL_SIZE[0],
        top + PORTRAIT_CELL_SIZE[1],
    )


def validate_native(image: Image.Image, expected: tuple[int, int], label: str) -> dict[str, int]:
    rgba = image.convert("RGBA")
    if rgba.size != expected:
        raise ValueError(f"{label}: expected {expected}, found {rgba.size}")
    allowed = set(PALETTE_RGB)
    alpha_values: set[int] = set()
    opaque_colors: set[tuple[int, int, int]] = set()
    transparent_rgb_nonzero = 0
    opaque_pixels = 0
    raw = rgba.tobytes()
    for offset in range(0, len(raw), 4):
        red, green, blue, alpha = raw[offset : offset + 4]
        alpha_values.add(alpha)
        rgb = (red, green, blue)
        if alpha == 0:
            if rgb != (0, 0, 0):
                transparent_rgb_nonzero += 1
            continue
        opaque_pixels += 1
        opaque_colors.add(rgb)
        if rgb not in allowed:
            raise ValueError(f"{label}: off-palette opaque color {rgb}")
        if rgb in RESERVED_RGB:
            raise ValueError(f"{label}: reserved probe color {rgb}")
    if not alpha_values.issubset({0, 255}):
        raise ValueError(f"{label}: soft alpha values {sorted(alpha_values)}")
    if transparent_rgb_nonzero != 0:
        raise ValueError(f"{label}: {transparent_rgb_nonzero} transparent pixels retain RGB")
    if opaque_pixels == 0:
        raise ValueError(f"{label}: no opaque pixels")
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError(f"{label}: no alpha bounds")
    left, top, right, bottom = bbox
    # Character feet intentionally may touch the final row for the manifest's
    # bottom-center pivot. Top and side clearance remain mandatory.
    if left <= 0 or top <= 0 or right >= expected[0] or bottom > expected[1]:
        raise ValueError(f"{label}: missing transparent safe margin, bbox={bbox}")
    return {
        "opaque_pixels": opaque_pixels,
        "palette_colors": len(opaque_colors),
        "left": left,
        "top": top,
        "right": right,
        "bottom": bottom,
    }


def checker_card(image: Image.Image, scale: int, card_size: tuple[int, int]) -> Image.Image:
    card = Image.new("RGBA", card_size, (30, 34, 45, 255))
    pixels = card.load()
    for y in range(card.height):
        for x in range(card.width):
            pixels[x, y] = (44, 48, 68, 255) if (x // 16 + y // 16) % 2 == 0 else (36, 40, 54, 255)
    preview = image.resize(
        (image.width * scale, image.height * scale),
        Image.Resampling.NEAREST,
    )
    x = (card.width - preview.width) // 2
    y = (card.height - preview.height) // 2
    card.alpha_composite(preview, (x, y))
    return card


def build_contact_sheet(
    portraits: Iterable[Image.Image],
    frames: Iterable[Image.Image],
) -> Image.Image:
    portrait_cards = [checker_card(image, 2, (272, 272)) for image in portraits]
    frame_cards = [checker_card(image, 5, (176, 176)) for image in frames]
    pad = 16
    width = pad + 4 * (272 + pad)
    height = pad + 2 * (272 + pad) + 24 + 176 + pad
    canvas = Image.new("RGBA", (width, height), (24, 27, 39, 255))
    for index, card in enumerate(portrait_cards):
        x = pad + (index % 4) * (272 + pad)
        y = pad + (index // 4) * (272 + pad)
        canvas.alpha_composite(card, (x, y))
    frame_width = len(frame_cards) * 176 + max(0, len(frame_cards) - 1) * pad
    frame_x = (width - frame_width) // 2
    frame_y = pad + 2 * (272 + pad) + 24
    for index, card in enumerate(frame_cards):
        canvas.alpha_composite(card, (frame_x + index * (176 + pad), frame_y))
    return canvas


def publish_approved_outputs(
    repo: Path,
    pending_images: list[tuple[Path, Image.Image]],
    generated_assets: dict[str, bytes],
    contact_image: Image.Image,
    contact_path: Path | None,
) -> None:
    authenticate_recruit_approval(
        repo,
        generated_assets=generated_assets,
        generated_contact_sheet=png_bytes(contact_image),
    )
    for path, image in pending_images:
        save_atomic(image, path)
    if contact_path is not None:
        contact_path.parent.mkdir(parents=True, exist_ok=True)
        save_atomic(contact_image, contact_path)


def run(repo: Path, review_dir: Path | None) -> None:
    source_root = repo / "art-src/characters/recruit"
    portrait_source_path = source_root / "recruit-portrait-treatment-sheet.png"
    field_source_path = source_root / "recruit-field-master.png"
    portrait_source = Image.open(portrait_source_path).convert("RGBA")
    field_source = Image.open(field_source_path).convert("RGBA")
    if portrait_source.size != PORTRAIT_SOURCE_SIZE:
        raise ValueError(
            f"unexpected portrait source size: {portrait_source.size}; expected {PORTRAIT_SOURCE_SIZE}"
        )
    if field_source.size != FIELD_SOURCE_SIZE:
        raise ValueError(
            f"unexpected field source size: {field_source.size}; expected {FIELD_SOURCE_SIZE}"
        )
    validate_source_subject(field_source, "Recruit field source", True)

    portraits: list[Image.Image] = []
    final_rows: list[dict[str, object]] = []
    pending_images: list[tuple[Path, Image.Image]] = []
    generated_assets: dict[str, bytes] = {}
    for index, portrait_id in enumerate(PORTRAIT_IDS):
        source_crop = portrait_source.crop(portrait_crop(index))
        validate_source_subject(source_crop, f"Recruit portrait source {index:02d}", False)
        portrait = normalize_subject(
            source_crop,
            PORTRAIT_SIZE,
            PORTRAIT_MARGIN,
        )
        stats = validate_native(portrait, PORTRAIT_SIZE, portrait_id)
        path = repo / f"assets/portraits/{portrait_id}.png"
        encoded = png_bytes(portrait)
        resource_path = f"res://{path.relative_to(repo).as_posix()}"
        generated_assets[resource_path] = encoded
        pending_images.append((path, portrait))
        portraits.append(portrait)
        final_rows.append(
            {
                "logical_id": f"portrait_{portrait_id}",
                "path": path.relative_to(repo).as_posix(),
                "sha256": hashlib.sha256(encoded).hexdigest(),
                "size": list(PORTRAIT_SIZE),
                "stats": stats,
            }
        )

    base = add_outline(normalize_subject(field_source, FIELD_SIZE, FIELD_MARGIN))
    frames = [
        base,
        shifted(base, 0, 1),
        upper_shift(base, 1),
        upper_shift(base, -1, 1),
        crouched(base),
    ]
    bottom_rows: list[int] = []
    for index, frame in enumerate(frames):
        stats = validate_native(frame, FIELD_SIZE, f"recruit_{index}")
        bottom_rows.append(int(stats["bottom"]))
        path = repo / f"assets/sprites/recruit_{index}.png"
        encoded = png_bytes(frame)
        resource_path = f"res://{path.relative_to(repo).as_posix()}"
        generated_assets[resource_path] = encoded
        pending_images.append((path, frame))
        final_rows.append(
            {
                "logical_id": "recruit",
                "frame": index,
                "path": path.relative_to(repo).as_posix(),
                "sha256": hashlib.sha256(encoded).hexdigest(),
                "size": list(FIELD_SIZE),
                "stats": stats,
            }
        )
    if max(bottom_rows) - min(bottom_rows) > 1:
        raise ValueError(f"Recruit frame feet drift exceeds one pixel: {bottom_rows}")

    portrait_hashes = [row["sha256"] for row in final_rows[:8]]
    if len(set(portrait_hashes)) != 8:
        raise ValueError("Recruit portraits are not byte-distinct")

    contact_image = build_contact_sheet(portraits, frames)
    contact_path = review_dir / "recruit-final-contact-sheet.png" if review_dir is not None else None
    publish_approved_outputs(
        repo,
        pending_images,
        generated_assets,
        contact_image,
        contact_path,
    )

    if review_dir is not None:
        review_dir.mkdir(parents=True, exist_ok=True)
        assert contact_path is not None
        report = {
            "schema_version": 1,
            "source_files": [
                {
                    "path": portrait_source_path.relative_to(repo).as_posix(),
                    "sha256": sha256_file(portrait_source_path),
                    "size": list(PORTRAIT_SOURCE_SIZE),
                },
                {
                    "path": field_source_path.relative_to(repo).as_posix(),
                    "sha256": sha256_file(field_source_path),
                    "size": list(FIELD_SOURCE_SIZE),
                },
            ],
            "portrait_grid": {
                "columns": PORTRAIT_GRID[0],
                "rows": PORTRAIT_GRID[1],
                "cell_size": list(PORTRAIT_CELL_SIZE),
            },
            "palette": PALETTE,
            "alpha": "binary",
            "reserved_colors_absent": ["#f4f4f4", "#41a6f6"],
            "final_files": final_rows,
            "contact_sheet": {
                "path": contact_path.relative_to(repo).as_posix(),
                "sha256": sha256_file(contact_path),
            },
        }
        (review_dir / "recruit-import-report.json").write_text(
            json.dumps(report, indent=2) + "\n",
            encoding="utf-8",
        )


if __name__ == "__main__":
    args = parse_args()
    run(args.repo.resolve(), args.review_dir.resolve() if args.review_dir else None)
