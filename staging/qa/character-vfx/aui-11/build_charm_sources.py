#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def color(value: str) -> tuple[int, int, int]:
    return int(value[1:3], 16), int(value[3:5], 16), int(value[5:7], 16)


def endpoint(origin: int, span: int, value: int) -> int:
    return origin + span * value // 16


def main() -> None:
    if len(sys.argv) != 6:
        raise SystemExit("usage: build CONTRACT BASE_ATLAS EXPECTED_JSON OUTPUT_ROOT REPORT")
    contract_path, base_path, expected_path, output_root, report_path = map(Path, sys.argv[1:])
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    expected = json.loads(expected_path.read_text(encoding="utf-8"))
    with Image.open(base_path) as raw:
        raw.load()
        atlas = raw.convert("RGBA")
    if atlas.size != (768, 384):
        raise ValueError("base atlas size mismatch")
    if digest(contract_path.read_bytes()) != expected["contract_sha256"]:
        raise ValueError("contract digest mismatch")
    if digest(base_path.read_bytes()) != expected["base_atlas_sha256"]:
        raise ValueError("base atlas file digest mismatch")
    if digest(atlas.tobytes()) != expected["base_atlas_rgba_sha256"]:
        raise ValueError("base atlas RGBA digest mismatch")

    palette = dict(zip(map(color, contract["base_palette"]), map(color, contract["target_palette"])))
    regions = contract["regions_sixteenths"]
    stripe = contract["stripe"]
    light = color(stripe["light"])
    dark = color(stripe["dark"])
    tab = color(contract["tab_color"])
    knot = color(contract["knot_color"])
    output_root.mkdir(parents=True, exist_ok=True)
    records = []

    for index in range(8):
        row, column = divmod(index, 4)
        base = atlas.crop((column * 192, row * 192, (column + 1) * 192, (row + 1) * 192))
        data = list(base.getdata())
        occupied = [position for position, pixel in enumerate(data) if pixel[3] > 0]
        xs = [position % 192 for position in occupied]
        ys = [position // 192 for position in occupied]
        left, top, right, bottom = min(xs), min(ys), max(xs), max(ys)
        width, height = right - left + 1, bottom - top + 1

        for position, pixel in enumerate(data):
            if pixel[3] > 0:
                data[position] = (*palette.get(pixel[:3], pixel[:3]), pixel[3])

        for name in ("shoulder", "ankles"):
            values = regions[name]
            x0, y0 = endpoint(left, width, values[0]), endpoint(top, height, values[1])
            x1, y1 = endpoint(left, width, values[2]), endpoint(top, height, values[3])
            for y in range(max(top, y0), min(bottom + 1, y1)):
                for x in range(max(left, x0), min(right + 1, x1)):
                    position = y * 192 + x
                    if data[position][3] > 0:
                        selected = (x + y + stripe["frame_phase_multiplier"] * index) % stripe["period"] < stripe["active_width"]
                        data[position] = (*(light if selected else dark), data[position][3])

        for name in ("left_tab", "right_tab"):
            values = regions[name]
            x0, y0 = endpoint(left, width, values[0]), endpoint(top, height, values[1])
            x1, y1 = endpoint(left, width, values[2]), endpoint(top, height, values[3])
            notch = (x1 - 1, y0) if name == "left_tab" else (x0, y0)
            for y in range(max(top, y0), min(bottom + 1, y1)):
                for x in range(max(left, x0), min(right + 1, x1)):
                    position = y * 192 + x
                    if (x, y) != notch and data[position][3] > 0:
                        data[position] = (*tab, data[position][3])

        center = (
            endpoint(left, width, regions["knot_center"][0]),
            endpoint(top, height, regions["knot_center"][1]),
        )
        for x, y in (
            center,
            (center[0] - 1, center[1]),
            (center[0] + 1, center[1]),
            (center[0], center[1] - 1),
            (center[0], center[1] + 1),
        ):
            if 0 <= x < 192 and 0 <= y < 192:
                position = y * 192 + x
                if data[position][3] > 0:
                    data[position] = (*knot, data[position][3])

        result = Image.new("RGBA", (192, 192), (0, 0, 0, 0))
        result.putdata(data)
        path = output_root / f"frame_{index:02d}.png"
        result.save(path, format="PNG", optimize=False, compress_level=9)
        rgba = result.tobytes()
        alpha = result.getchannel("A").tobytes()
        occupancy = bytes(1 if value else 0 for value in alpha)
        rgb = bytes(channel for pixel in result.getdata() for channel in pixel[:3])
        actual = {
            "index": index,
            "file": path.name,
            "file_sha256": digest(path.read_bytes()),
            "rgba_sha256": digest(rgba),
            "rgb_sha256": digest(rgb),
            "alpha_sha256": digest(alpha),
            "occupancy_sha256": digest(occupancy),
            "base_alpha_sha256": digest(base.getchannel("A").tobytes()),
            "base_occupancy_sha256": digest(bytes(1 if value else 0 for value in base.getchannel("A").tobytes())),
        }
        if actual != expected["frames"][index]:
            raise AssertionError(f"oracle mismatch frame={index} actual={actual} expected={expected['frames'][index]}")
        records.append(actual)

    report = {
        "schema_version": 1,
        "status": "PASS",
        "contract_id": contract["contract_id"],
        "oracle": str(expected_path),
        "frames": records,
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "report": str(report_path)}, sort_keys=True))


if __name__ == "__main__":
    main()
