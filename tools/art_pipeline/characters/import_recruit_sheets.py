#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Iterable

from PIL import Image

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


def source_background(image: Image.Image) -> tuple[int, int, int]:
    rgba = image.convert("RGBA")
    corners = [
        rgba.getpixel((0, 0))[:3],
        rgba.getpixel((rgba.width - 1, 0))[:3],
        rgba.getpixel((0, rgba.height - 1))[:3],
        rgba.getpixel((rgba.width - 1, rgba.height - 1))[:3],
    ]
    return tuple(sorted(channel)[len(channel) // 2] for channel in zip(*corners))


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
    output_path: Path,
) -> None:
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
    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path, format="PNG", optimize=False, compress_level=9)


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

    portraits: list[Image.Image] = []
    final_rows: list[dict[str, object]] = []
    for index, portrait_id in enumerate(PORTRAIT_IDS):
        portrait = normalize_subject(
            portrait_source.crop(portrait_crop(index)),
            PORTRAIT_SIZE,
            PORTRAIT_MARGIN,
        )
        stats = validate_native(portrait, PORTRAIT_SIZE, portrait_id)
        path = repo / f"assets/portraits/{portrait_id}.png"
        save_atomic(portrait, path)
        portraits.append(portrait)
        final_rows.append(
            {
                "logical_id": f"portrait_{portrait_id}",
                "path": path.relative_to(repo).as_posix(),
                "sha256": sha256_file(path),
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
        save_atomic(frame, path)
        final_rows.append(
            {
                "logical_id": "recruit",
                "frame": index,
                "path": path.relative_to(repo).as_posix(),
                "sha256": sha256_file(path),
                "size": list(FIELD_SIZE),
                "stats": stats,
            }
        )
    if max(bottom_rows) - min(bottom_rows) > 1:
        raise ValueError(f"Recruit frame feet drift exceeds one pixel: {bottom_rows}")

    portrait_hashes = [row["sha256"] for row in final_rows[:8]]
    if len(set(portrait_hashes)) != 8:
        raise ValueError("Recruit portraits are not byte-distinct")

    if review_dir is not None:
        review_dir.mkdir(parents=True, exist_ok=True)
        contact_path = review_dir / "recruit-final-contact-sheet.png"
        build_contact_sheet(portraits, frames, contact_path)
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
