#!/usr/bin/env python3
"""Build eight explicit synthetic RGBA frames without importing production code."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw

BACKGROUND = (255, 0, 255, 255)
OUTLINE = (27, 34, 48, 255)
CLOTH = (83, 48, 105, 255)
ACCENT = (152, 75, 111, 255)
SKIN = (230, 195, 154, 255)
METAL = (151, 170, 193, 255)


def build_frame(index: int) -> Image.Image:
    image = Image.new("RGBA", (96, 96), BACKGROUND)
    draw = ImageDraw.Draw(image)
    sway = (-2, -1, 1, 2)[index % 4]
    attack = index >= 4

    # Hair/head, torso, coat tails, legs, and boots are a single connected body.
    draw.rectangle((39 + sway, 14, 56 + sway, 29), fill=OUTLINE)
    draw.rectangle((41 + sway, 16, 54 + sway, 27), fill=SKIN)
    draw.rectangle((36 + sway, 28, 59 + sway, 62), fill=OUTLINE)
    draw.rectangle((38 + sway, 30, 57 + sway, 59), fill=CLOTH)
    draw.polygon([(38 + sway, 58), (57 + sway, 58), (63 + sway, 77), (32 + sway, 77)], fill=OUTLINE)
    draw.polygon([(40 + sway, 58), (55 + sway, 58), (59 + sway, 74), (36 + sway, 74)], fill=ACCENT)
    draw.rectangle((37 + sway, 75, 45 + sway, 87), fill=OUTLINE)
    draw.rectangle((50 + sway, 75, 58 + sway, 87), fill=OUTLINE)
    draw.rectangle((34 + sway, 87, 45 + sway, 90), fill=OUTLINE)
    draw.rectangle((50 + sway, 87, 61 + sway, 90), fill=OUTLINE)

    # Pose-specific connected arm/weapon geometry makes all eight cells distinct.
    if attack:
        reach = 10 + (index - 4) * 3
        draw.rectangle((56 + sway, 36, 66 + sway + reach, 40), fill=OUTLINE)
        draw.rectangle((60 + sway, 37, 66 + sway + reach, 38), fill=METAL)
        draw.polygon(
            [(66 + sway + reach, 33), (74 + sway + reach, 38), (66 + sway + reach, 43)],
            fill=METAL,
        )
    else:
        lift = index * 2
        draw.rectangle((57 + sway, 34 - lift, 64 + sway, 58 - lift), fill=OUTLINE)
        draw.rectangle((59 + sway, 36 - lift, 62 + sway, 56 - lift), fill=METAL)

    # A valid detached 2x2 prop must survive component filtering.
    prop_x = 73 + (index % 2) * 4
    draw.rectangle((prop_x, 48, prop_x + 1, 49), fill=METAL)

    # One isolated opaque noise pixel must be removed.
    image.putpixel((5 + index, 5), OUTLINE)

    # Source semitransparency is an expected normalization success.
    image.putpixel((40 + sway, 31), (83, 48, 105, 25))
    image.putpixel((41 + sway, 31), (83, 48, 105, 26))
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output
    output.mkdir(parents=True, exist_ok=True)
    for path in output.glob("*.png"):
        path.unlink()
    for index in range(8):
        path = output / f"frame_{index:02d}.png"
        build_frame(index).save(path, format="PNG", optimize=False, compress_level=9)
    print(f"built=8 output={output.name}")


if __name__ == "__main__":
    main()
