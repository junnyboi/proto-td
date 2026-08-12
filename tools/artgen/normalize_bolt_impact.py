#!/usr/bin/env python3
"""Normalize a GPT Image Bolt master into a deterministic 48x48 TD32 sprite."""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import deque
from pathlib import Path

from PIL import Image

TD32 = {
    "INK": (0x1A, 0x1C, 0x2C),
    "PLUM": (0x5D, 0x27, 0x5D),
    "CRIMSON": (0xB1, 0x3E, 0x53),
    "CORAL": (0xEF, 0x7D, 0x57),
    "GOLD": (0xFF, 0xCD, 0x75),
    "LIME": (0xA7, 0xF0, 0x70),
    "GREEN": (0x38, 0xB7, 0x64),
    "TEAL": (0x25, 0x71, 0x79),
    "NAVY": (0x29, 0x36, 0x6F),
    "BLUE": (0x3B, 0x5D, 0xC9),
    "SKY": (0x41, 0xA6, 0xF6),
    "CYAN": (0x73, 0xEF, 0xF7),
    "WHITE": (0xF4, 0xF4, 0xF4),
    "STEEL": (0x94, 0xB0, 0xC2),
    "SLATE": (0x56, 0x6C, 0x86),
    "DUSK": (0x33, 0x3C, 0x57),
    "VOID": (0x0F, 0x0F, 0x1B),
    "PALE": (0xC7, 0xD6, 0xE8),
    "GRAY": (0x6E, 0x7A, 0x94),
    "DEEP_GREEN": (0x1A, 0x5F, 0x43),
    "WINE": (0x7A, 0x24, 0x36),
    "PALE_GOLD": (0xFF, 0xE9, 0xB0),
    "BRONZE": (0xA3, 0x70, 0x2B),
    "BROWN": (0x6B, 0x4A, 0x34),
    "UMBER": (0x3A, 0x2A, 0x24),
    "SKIN_SHADOW": (0x8A, 0x48, 0x36),
    "SKIN": (0xC7, 0x7B, 0x58),
    "SKIN_LIGHT": (0xE8, 0xB7, 0x96),
    "SKIN_PALE": (0xF6, 0xDC, 0xBF),
    "ORCHID": (0xC9, 0x64, 0xCF),
    "MAGENTA": (0x94, 0x21, 0x6A),
    "ROSE": (0xE3, 0x9A, 0xAC),
}

SOURCE_KEEP = {"PLUM", "WINE", "BRONZE", "GOLD", "PALE_GOLD", "WHITE"}
OUTPUT_PALETTE = {
    "PLUM": TD32["PLUM"],
    "BRONZE": TD32["BRONZE"],
    "GOLD": TD32["GOLD"],
    "PALE_GOLD": TD32["PALE_GOLD"],
}
TARGET_SIZE = 48
MIN_COMPONENT = 2
MIN_OPAQUE = 80
MIN_PALE_GOLD = 20


def _palette_image(colors: list[tuple[int, int, int]]) -> Image.Image:
    pal = Image.new("P", (1, 1))
    flat: list[int] = []
    for color in colors:
        flat.extend(color)
    flat.extend([0] * (768 - len(flat)))
    pal.putpalette(flat)
    return pal


def _clean_components(mask: Image.Image) -> Image.Image:
    px = mask.load()
    width, height = mask.size
    seen: set[tuple[int, int]] = set()
    keep: set[tuple[int, int]] = set()
    for y in range(height):
        for x in range(width):
            if px[x, y] == 0 or (x, y) in seen:
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            seen.add((x, y))
            component: list[tuple[int, int]] = []
            while queue:
                point = queue.popleft()
                component.append(point)
                cx, cy = point
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    if px[nx, ny] == 0 or (nx, ny) in seen:
                        continue
                    seen.add((nx, ny))
                    queue.append((nx, ny))
            if len(component) >= MIN_COMPONENT:
                keep.update(component)
    cleaned = Image.new("L", mask.size, 0)
    out = cleaned.load()
    for x, y in keep:
        out[x, y] = 255
    return cleaned


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize(source: Path, destination: Path, report_path: Path) -> None:
    source_image = Image.open(source).convert("RGBA")
    rgb = source_image.convert("RGB")
    names = list(TD32)
    indexed = rgb.quantize(
        palette=_palette_image([TD32[name] for name in names]),
        dither=Image.Dither.NONE,
    )
    source_alpha = source_image.getchannel("A")
    keep_indices = {names.index(name) for name in SOURCE_KEEP}
    color_mask = indexed.point([255 if idx in keep_indices else 0 for idx in range(256)])
    mask = Image.new("L", source_image.size, 0)
    mask_pixels = mask.load()
    color_pixels = color_mask.load()
    alpha_pixels = source_alpha.load()
    for y in range(source_image.height):
        for x in range(source_image.width):
            if color_pixels[x, y] and alpha_pixels[x, y] > 16:
                mask_pixels[x, y] = 255

    bbox = mask.getbbox()
    if bbox is None:
        raise RuntimeError("No Bolt-colored foreground pixels found")
    crop = source_image.crop(bbox)
    crop_mask = mask.crop(bbox)
    side = max(crop.width, crop.height)
    padded_side = max(side + 2, int(round(side * 1.16)))
    offset = ((padded_side - crop.width) // 2, (padded_side - crop.height) // 2)
    padded_rgb = Image.new("RGB", (padded_side, padded_side), (0, 0, 0))
    padded_mask = Image.new("L", (padded_side, padded_side), 0)
    padded_rgb.paste(crop.convert("RGB"), offset)
    padded_mask.paste(crop_mask, offset)

    resized_rgb = padded_rgb.resize((TARGET_SIZE, TARGET_SIZE), Image.Resampling.NEAREST)
    resized_mask = padded_mask.resize((TARGET_SIZE, TARGET_SIZE), Image.Resampling.NEAREST)
    resized_mask = _clean_components(resized_mask)

    output_names = list(OUTPUT_PALETTE)
    output_indexed = resized_rgb.quantize(
        palette=_palette_image([OUTPUT_PALETTE[name] for name in output_names]),
        dither=Image.Dither.NONE,
    )
    output = output_indexed.convert("RGBA")
    output.putalpha(resized_mask.point(lambda value: 255 if value else 0))
    destination.parent.mkdir(parents=True, exist_ok=True)
    output.save(destination, optimize=False)

    alpha_values = set(output.getchannel("A").getdata())
    if not alpha_values.issubset({0, 255}):
        raise RuntimeError(f"Alpha is not binary: {sorted(alpha_values)}")
    opaque_colors: dict[str, int] = {name: 0 for name in output_names}
    color_to_name = {color: name for name, color in OUTPUT_PALETTE.items()}
    for red, green, blue, alpha in output.getdata():
        if alpha == 0:
            continue
        name = color_to_name.get((red, green, blue))
        if name is None:
            raise RuntimeError(f"Off-palette opaque color: {(red, green, blue)}")
        opaque_colors[name] += 1
    opaque_count = sum(opaque_colors.values())
    if opaque_count < MIN_OPAQUE:
        raise RuntimeError(f"Too few opaque pixels: {opaque_count} < {MIN_OPAQUE}")
    if opaque_colors["PALE_GOLD"] < MIN_PALE_GOLD:
        raise RuntimeError(
            f"Probe color budget too small: {opaque_colors['PALE_GOLD']} < {MIN_PALE_GOLD}"
        )
    output_bbox = output.getchannel("A").getbbox()
    if output_bbox is None:
        raise RuntimeError("Output is empty")
    if output_bbox[0] < 1 or output_bbox[1] < 1 or output_bbox[2] > 47 or output_bbox[3] > 47:
        raise RuntimeError(f"Opaque pixels violate the one-pixel border: {output_bbox}")

    report = {
        "source": str(source),
        "source_sha256": _sha256(source),
        "output": str(destination),
        "output_sha256": _sha256(destination),
        "size": [TARGET_SIZE, TARGET_SIZE],
        "alpha_values": sorted(alpha_values),
        "opaque_bbox": list(output_bbox),
        "opaque_pixels": opaque_count,
        "color_counts": opaque_colors,
        "source_keep": sorted(SOURCE_KEEP),
        "output_palette": {name: "#%02x%02x%02x" % color for name, color in OUTPUT_PALETTE.items()},
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("report", type=Path)
    args = parser.parse_args()
    normalize(args.source, args.destination, args.report)


if __name__ == "__main__":
    main()
