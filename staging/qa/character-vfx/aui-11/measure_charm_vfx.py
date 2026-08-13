#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path

from PIL import Image


def component_records(mask: bytes, width: int, height: int) -> list[dict[str, object]]:
    remaining = {index for index, value in enumerate(mask) if value}
    records = []
    while remaining:
        pixels = [remaining.pop()]
        queue = deque(pixels)
        while queue:
            index = queue.popleft()
            x, y = index % width, index // width
            for yy in range(max(0, y - 1), min(height, y + 2)):
                for xx in range(max(0, x - 1), min(width, x + 2)):
                    neighbor = yy * width + xx
                    if neighbor in remaining:
                        remaining.remove(neighbor)
                        queue.append(neighbor)
                        pixels.append(neighbor)
        xs = [index % width for index in pixels]
        ys = [index // width for index in pixels]
        records.append({"area": len(pixels), "bounds": [min(xs), min(ys), max(xs) + 1, max(ys) + 1]})
    return sorted(records, key=lambda record: (record["bounds"][1], record["bounds"][0]))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("atlas")
    parser.add_argument("--report", required=True)
    args = parser.parse_args()
    with Image.open(args.atlas) as raw:
        raw.load()
        atlas = raw.convert("RGBA")
    frames = []
    masks = []
    for index in range(8):
        row, column = divmod(index, 4)
        cell = atlas.crop((column * 192, row * 192, (column + 1) * 192, (row + 1) * 192))
        alpha = cell.getchannel("A")
        box = alpha.getbbox()
        if box is None:
            raise ValueError(f"frame {index} empty")
        mask = bytes(1 if value else 0 for value in alpha.tobytes())
        masks.append(mask)
        width, height = box[2] - box[0], box[3] - box[1]
        cy = 180 - height // 2
        components = component_records(mask, 192, 192)
        frames.append({
            "frame": index,
            "width": width,
            "height": height,
            "opaque": sum(mask),
            "center_x": (box[0] + box[2] - 1) // 2,
            "foot": box[3] - 1,
            "open_center_max_alpha": max(alpha.crop((91, cy - 3, 101, cy + 3)).tobytes(), default=0),
            "components_8_connected": len(components),
            "components": components,
        })
    loops = []
    for start, end in ((0, 3), (4, 7)):
        intersection = sum(1 for left, right in zip(masks[start], masks[end]) if left and right)
        union = sum(1 for left, right in zip(masks[start], masks[end]) if left or right)
        loops.append({"start": start, "end": end, "iou": intersection / union})
    result = {"frames": frames, "loops": loops}
    Path(args.report).write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
