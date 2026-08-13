#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[3]
DEFAULT_OUTPUT = REPO / "art-src/world/s1/s1-alpine-escarpment-source.png"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Prepare a bounded 2:1 source raster from an approved GPT Image 2 panorama."
    )
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    with Image.open(args.input) as source:
        image = source.convert("RGB")
        target_ratio = 2.0
        source_ratio = image.width / image.height
        if source_ratio < target_ratio:
            crop_height = round(image.width / target_ratio)
            top = (image.height - crop_height) // 2
            crop = image.crop((0, top, image.width, top + crop_height))
        else:
            crop_width = round(image.height * target_ratio)
            left = (image.width - crop_width) // 2
            crop = image.crop((left, 0, left + crop_width, image.height))
        bounded = crop.resize((832, 416), Image.Resampling.BOX)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    bounded.save(args.output, format="PNG", optimize=False, compress_level=9)
    print(f"{args.output}: {bounded.size[0]}x{bounded.size[1]} sha256={sha256(args.output)}")


if __name__ == "__main__":
    main()
