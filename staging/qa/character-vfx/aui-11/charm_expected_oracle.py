#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image


def sha_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def parse_hex(value: str) -> tuple[int, int, int]:
    if len(value) != 7 or value[0] != "#":
        raise ValueError(f"invalid color {value!r}")
    return tuple(int(value[index:index + 2], 16) for index in (1, 3, 5))


def scaled(left: int, span: int, numerator: int) -> int:
    return left + span * numerator // 16


def region(bounds: tuple[int, int, int, int], values: list[int]) -> tuple[int, int, int, int]:
    left, top, right, bottom = bounds
    width = right - left + 1
    height = bottom - top + 1
    return (
        max(left, min(right + 1, scaled(left, width, values[0]))),
        max(top, min(bottom + 1, scaled(top, height, values[1]))),
        max(left, min(right + 1, scaled(left, width, values[2]))),
        max(top, min(bottom + 1, scaled(top, height, values[3]))),
    )


def transform(cell: Image.Image, index: int, contract: dict[str, object]) -> Image.Image:
    image = cell.convert("RGBA")
    width, height = image.size
    if [width, height] != contract["cell_size"]:
        raise ValueError("unexpected cell size")
    data = list(image.getdata())
    occupied = [position for position, pixel in enumerate(data) if pixel[3] > 0]
    if not occupied:
        raise ValueError("empty base cell")
    xs = [position % width for position in occupied]
    ys = [position // width for position in occupied]
    bounds = (min(xs), min(ys), max(xs), max(ys))
    base_palette = [parse_hex(value) for value in contract["base_palette"]]
    target_palette = [parse_hex(value) for value in contract["target_palette"]]
    palette_map = dict(zip(base_palette, target_palette))
    for position, (red, green, blue, alpha) in enumerate(data):
        if alpha > 0:
            data[position] = (*palette_map.get((red, green, blue), (red, green, blue)), alpha)

    stripe = contract["stripe"]
    light = parse_hex(stripe["light"])
    dark = parse_hex(stripe["dark"])
    regions = contract["regions_sixteenths"]
    for name in ("shoulder", "ankles"):
        x0, y0, x1, y1 = region(bounds, regions[name])
        for y in range(y0, y1):
            for x in range(x0, x1):
                position = y * width + x
                if data[position][3] == 0:
                    continue
                active = (x + y + stripe["frame_phase_multiplier"] * index) % stripe["period"] < stripe["active_width"]
                data[position] = (*(light if active else dark), data[position][3])

    tab_color = parse_hex(contract["tab_color"])
    for name in ("left_tab", "right_tab"):
        x0, y0, x1, y1 = region(bounds, regions[name])
        notch = (x1 - 1, y0) if name == "left_tab" else (x0, y0)
        for y in range(y0, y1):
            for x in range(x0, x1):
                if (x, y) == notch:
                    continue
                position = y * width + x
                if data[position][3] > 0:
                    data[position] = (*tab_color, data[position][3])

    knot_color = parse_hex(contract["knot_color"])
    left, top, right, bottom = bounds
    span_width = right - left + 1
    span_height = bottom - top + 1
    center_x = max(left, min(right, scaled(left, span_width, regions["knot_center"][0])))
    center_y = max(top, min(bottom, scaled(top, span_height, regions["knot_center"][1])))
    for x, y in (
        (center_x, center_y),
        (center_x - 1, center_y),
        (center_x + 1, center_y),
        (center_x, center_y - 1),
        (center_x, center_y + 1),
    ):
        if not (0 <= x < width and 0 <= y < height):
            continue
        position = y * width + x
        if data[position][3] > 0:
            data[position] = (*knot_color, data[position][3])

    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    result.putdata(data)
    return result


def main() -> None:
    if len(sys.argv) != 5:
        raise SystemExit("usage: oracle.py CONTRACT BASE_ATLAS OUTPUT_ROOT EXPECTED_JSON")
    contract_path = Path(sys.argv[1])
    base_path = Path(sys.argv[2])
    output_root = Path(sys.argv[3])
    expected_path = Path(sys.argv[4])
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    if contract["contract_id"] != "charm-grunt-v1":
        raise ValueError("unexpected contract")
    with Image.open(base_path) as raw:
        raw.load()
        atlas = raw.convert("RGBA")
    if atlas.size != (768, 384):
        raise ValueError(f"unexpected base atlas {atlas.size}")
    output_root.mkdir(parents=True, exist_ok=True)
    frames = []
    for index in range(8):
        row = index // 4
        column = index % 4
        base = atlas.crop((column * 192, row * 192, (column + 1) * 192, (row + 1) * 192))
        charmed = transform(base, index, contract)
        if base.getchannel("A").tobytes() != charmed.getchannel("A").tobytes():
            raise AssertionError("alpha changed")
        path = output_root / f"frame_{index:02d}.png"
        charmed.save(path, format="PNG", optimize=False, compress_level=9)
        rgba = charmed.tobytes()
        alpha = charmed.getchannel("A").tobytes()
        occupancy = bytes(1 if value else 0 for value in alpha)
        rgb = bytes(channel for pixel in charmed.getdata() for channel in pixel[:3])
        frames.append(
            {
                "index": index,
                "file": path.name,
                "file_sha256": sha_bytes(path.read_bytes()),
                "rgba_sha256": sha_bytes(rgba),
                "rgb_sha256": sha_bytes(rgb),
                "alpha_sha256": sha_bytes(alpha),
                "occupancy_sha256": sha_bytes(occupancy),
                "base_alpha_sha256": sha_bytes(base.getchannel("A").tobytes()),
                "base_occupancy_sha256": sha_bytes(bytes(1 if value else 0 for value in base.getchannel("A").tobytes())),
            }
        )
    expected = {
        "schema_version": 1,
        "contract_id": contract["contract_id"],
        "contract_sha256": sha_bytes(contract_path.read_bytes()),
        "base_atlas_sha256": sha_bytes(base_path.read_bytes()),
        "base_atlas_rgba_sha256": sha_bytes(atlas.tobytes()),
        "frames": frames,
    }
    expected_path.parent.mkdir(parents=True, exist_ok=True)
    expected_path.write_text(json.dumps(expected, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "expected": str(expected_path)}, sort_keys=True))


if __name__ == "__main__":
    main()
