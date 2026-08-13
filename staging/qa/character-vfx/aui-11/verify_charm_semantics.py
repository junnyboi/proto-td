#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def color(value: str) -> tuple[int, int, int]:
    return tuple(bytes.fromhex(value[1:]))


def scaled(origin: int, span: int, numerator: int) -> int:
    return origin + span * numerator // 16


def region(bounds: tuple[int, int, int, int], values: list[int]) -> tuple[int, int, int, int]:
    left, top, right, bottom = bounds
    width, height = right - left + 1, bottom - top + 1
    return (
        max(left, min(right + 1, scaled(left, width, values[0]))),
        max(top, min(bottom + 1, scaled(top, height, values[1]))),
        max(left, min(right + 1, scaled(left, width, values[2]))),
        max(top, min(bottom + 1, scaled(top, height, values[3]))),
    )


def luminance(value: tuple[int, int, int]) -> int:
    return (299 * value[0] + 587 * value[1] + 114 * value[2]) // 1000


def crop(atlas: Image.Image, index: int) -> Image.Image:
    x, y = (index % 4) * 192, (index // 4) * 192
    return atlas.crop((x, y, x + 192, y + 192))


def count_color(image: Image.Image, bounds: tuple[int, int, int, int], target: tuple[int, int, int]) -> int:
    return sum(
        1
        for y in range(bounds[1], bounds[3])
        for x in range(bounds[0], bounds[2])
        if image.getpixel((x, y))[3] and image.getpixel((x, y))[:3] == target
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", type=Path, required=True)
    parser.add_argument("--expected", type=Path, required=True)
    parser.add_argument("--transform-report", type=Path, required=True)
    parser.add_argument("--base-atlas", type=Path, required=True)
    parser.add_argument("--charmed-atlas", type=Path, required=True)
    parser.add_argument("--charmed-source-root", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    contract = json.loads(args.contract.read_text(encoding="utf-8"))
    expected = json.loads(args.expected.read_text(encoding="utf-8"))
    transform = json.loads(args.transform_report.read_text(encoding="utf-8"))
    if sha(args.contract.read_bytes()) != expected["contract_sha256"]:
        raise AssertionError("Charm contract hash mismatch")
    if transform["frames"] != expected["frames"] or transform["status"] != "PASS":
        raise AssertionError("Charm transform report does not match independent expected fixture")
    with Image.open(args.base_atlas) as raw:
        raw.load()
        base_atlas = raw.convert("RGBA")
    with Image.open(args.charmed_atlas) as raw:
        raw.load()
        charmed_atlas = raw.convert("RGBA")
    if sha(args.base_atlas.read_bytes()) != expected["base_atlas_sha256"] or sha(base_atlas.tobytes()) != expected["base_atlas_rgba_sha256"]:
        raise AssertionError("base atlas is not the oracle-bound input")
    light = color(contract["stripe"]["light"])
    dark = color(contract["stripe"]["dark"])
    tab = color(contract["tab_color"])
    knot = color(contract["knot_color"])
    if luminance(light) - luminance(dark) < 96:
        raise AssertionError("binding cue luminance separation below pin")
    if abs(luminance(tab) - luminance(knot)) < 24:
        raise AssertionError("tab/knot luminance separation below pin")
    records = []
    for index in range(8):
        base = crop(base_atlas, index)
        charmed = crop(charmed_atlas, index)
        expected_frame = expected["frames"][index]
        source = args.charmed_source_root / f"frame_{index:02d}.png"
        if sha(source.read_bytes()) != expected_frame["file_sha256"]:
            raise AssertionError(f"frame {index} source file hash mismatch")
        if sha(charmed.tobytes()) != expected_frame["rgba_sha256"]:
            raise AssertionError(f"frame {index} atlas RGBA mismatch")
        base_alpha = base.getchannel("A").tobytes()
        charmed_alpha = charmed.getchannel("A").tobytes()
        if base_alpha != charmed_alpha:
            raise AssertionError(f"frame {index} alpha drift")
        box = base.getchannel("A").getbbox()
        if box is None:
            raise AssertionError(f"frame {index} empty base")
        bounds = (box[0], box[1], box[2] - 1, box[3] - 1)
        cue_counts = {}
        for name in ("shoulder", "ankles"):
            cue_region = region(bounds, contract["regions_sixteenths"][name])
            light_count = count_color(charmed, cue_region, light)
            dark_count = count_color(charmed, cue_region, dark)
            if light_count < 128 or dark_count < 128:
                raise AssertionError(f"frame {index} {name} binding cue missing: {light_count}/{dark_count}")
            cue_counts[name] = {"light": light_count, "dark": dark_count, "region": list(cue_region)}
        for name in ("left_tab", "right_tab"):
            cue_region = region(bounds, contract["regions_sixteenths"][name])
            tab_count = count_color(charmed, cue_region, tab)
            if tab_count < 64:
                raise AssertionError(f"frame {index} {name} cue missing: {tab_count}")
            cue_counts[name] = {"tab": tab_count, "region": list(cue_region)}
        left, top, right, bottom = bounds
        center_x = max(left, min(right, scaled(left, right - left + 1, contract["regions_sixteenths"]["knot_center"][0])))
        center_y = max(top, min(bottom, scaled(top, bottom - top + 1, contract["regions_sixteenths"]["knot_center"][1])))
        knot_points = [(center_x, center_y), (center_x - 1, center_y), (center_x + 1, center_y), (center_x, center_y - 1), (center_x, center_y + 1)]
        expected_knot_offsets = {(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)}
        measured_knot_offsets = {
            (x - center_x, y - center_y)
            for y in range(center_y - 3, center_y + 4)
            for x in range(center_x - 3, center_x + 4)
            if charmed.getpixel((x, y))[3] and charmed.getpixel((x, y))[:3] == knot
        }
        if measured_knot_offsets != expected_knot_offsets:
            raise AssertionError(f"frame {index} knot topology mismatch: {sorted(measured_knot_offsets)}")
        gray_difference = sum(
            1
            for base_pixel, charmed_pixel in zip(base.convert("L").tobytes(), charmed.convert("L").tobytes())
            if base_pixel != charmed_pixel
        )
        if gray_difference < 128:
            raise AssertionError(f"frame {index} grayscale distinction below pin")
        records.append({
            "frame": index,
            "alpha_sha256": sha(charmed_alpha),
            "cue_counts": cue_counts,
            "knot_points": [list(point) for point in knot_points],
            "knot_local_count": len(measured_knot_offsets),
            "knot_exclusion_radius": 3,
            "grayscale_different_pixels": gray_difference,
        })
    report = {
        "schema_version": 1,
        "status": "PASS",
        "contract_sha256": sha(args.contract.read_bytes()),
        "expected_sha256": sha(args.expected.read_bytes()),
        "transform_report_sha256": sha(args.transform_report.read_bytes()),
        "pins": {
            "binding_light_per_region_min": 128,
            "binding_dark_per_region_min": 128,
            "tab_pixels_per_region_min": 64,
            "knot_pixels_exact": 5,
            "knot_exclusion_radius": 3,
            "binding_luminance_delta_min": 96,
            "tab_knot_luminance_delta_min": 24,
            "grayscale_different_pixels_min": 128,
        },
        "frames": records,
    }
    args.report.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "frames": len(records)}, sort_keys=True))


if __name__ == "__main__":
    main()
