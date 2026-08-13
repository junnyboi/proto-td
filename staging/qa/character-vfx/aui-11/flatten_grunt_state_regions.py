#!/usr/bin/env python3
"""Flatten base value texture only inside frozen Charm cue regions for blind-state legibility."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

from PIL import Image


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


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


def rgb(value: str) -> tuple[int, int, int]:
    return tuple(bytes.fromhex(value[1:]))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    parser.add_argument("--contract", required=True)
    parser.add_argument("--spec", required=True)
    parser.add_argument("--input-root", required=True)
    parser.add_argument("--output-root", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()

    project = Path(args.project).resolve()
    sys.path.insert(0, str(project / "tools/art_pipeline/character_vfx"))
    from pixel_ops import (  # type: ignore[import-not-found]
        anchor_in_cell,
        key_and_threshold,
        nearest_source_index,
        opaque_bounds,
        palette_map,
        parse_hex,
        remove_small_components,
        resize_nearest,
    )

    contract_path = Path(args.contract).resolve()
    spec_path = Path(args.spec).resolve()
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    packet_spec = json.loads(spec_path.read_text(encoding="utf-8"))
    normalization = packet_spec["normalization"]
    resize_width, resize_height = normalization["resize"]
    alpha_threshold = normalization["alpha_threshold"]
    palette = [parse_hex(value) for value in packet_spec["palette"]]
    cell_size = (packet_spec["atlas"]["cell_width"], packet_spec["atlas"]["cell_height"])
    field_color = rgb("#B4A384")
    detail_color = rgb("#D1C2A8")
    input_root = Path(args.input_root).resolve()
    output_root = Path(args.output_root).resolve()
    output_root.mkdir(parents=True, exist_ok=True)
    records: list[dict[str, object]] = []

    def normalize(source: Image.Image) -> tuple[Image.Image, dict[str, int]]:
        image = resize_nearest(source, resize_width, resize_height)
        image = key_and_threshold(image, parse_hex(normalization["background_key"]), alpha_threshold)
        image = palette_map(image, palette)
        image = remove_small_components(image, normalization["minimum_component_size"])
        return anchor_in_cell(image, cell_size, normalization["anchor_x"], normalization["anchor_foot_y"])

    for index in range(8):
        source_path = input_root / f"frame_{index:02d}.png"
        with Image.open(source_path) as raw:
            raw.load()
            source = raw.convert("RGBA")
        base, anchor = normalize(source)
        box = base.getchannel("A").getbbox()
        if box is None:
            raise ValueError(f"frame {index} empty")
        bounds = (box[0], box[1], box[2] - 1, box[3] - 1)
        regions = contract["regions_sixteenths"]
        assignments: dict[tuple[int, int], tuple[int, tuple[int, int, int], str, list[int]]] = {}

        def assign(cue: tuple[int, int, int, int], priority: int, color_value: tuple[int, int, int], reason: str) -> None:
            for final_y in range(cue[1], cue[3]):
                for final_x in range(cue[0], cue[2]):
                    if base.getpixel((final_x, final_y))[3] == 0:
                        continue
                    normalized_x = final_x - anchor["dx"]
                    normalized_y = final_y - anchor["dy"]
                    source_x = nearest_source_index(normalized_x, source.width, resize_width)
                    source_y = nearest_source_index(normalized_y, source.height, resize_height)
                    key = (source_x, source_y)
                    previous = assignments.get(key)
                    if previous is None or priority >= previous[0]:
                        assignments[key] = (priority, color_value, reason, [final_x, final_y])

        for name in ("shoulder", "ankles"):
            assign(region(bounds, regions[name]), 1, field_color, f"{name}_field")
        for name in ("left_tab", "right_tab"):
            assign(region(bounds, regions[name]), 2, detail_color, f"{name}_detail_field")
        knot_center = (
            max(bounds[0], min(bounds[2], scaled(bounds[0], bounds[2] - bounds[0] + 1, regions["knot_center"][0]))),
            max(bounds[1], min(bounds[3], scaled(bounds[1], bounds[3] - bounds[1] + 1, regions["knot_center"][1]))),
        )
        knot_field = (knot_center[0] - 3, knot_center[1] - 3, knot_center[0] + 4, knot_center[1] + 4)
        assign(knot_field, 3, detail_color, "knot_detail_field")

        changed = []
        source_pixels = source.load()
        for (source_x, source_y), (_, color_value, reason, final_point) in sorted(assignments.items()):
            red, green, blue, alpha = source_pixels[source_x, source_y]
            if alpha < alpha_threshold:
                raise AssertionError(f"frame {index}: mapped source below alpha threshold")
            if (red, green, blue) != color_value:
                source_pixels[source_x, source_y] = (*color_value, alpha)
                changed.append({"source": [source_x, source_y], "final_sample": final_point, "from_rgb": [red, green, blue], "to_rgb": list(color_value), "reason": reason})

        destination = output_root / source_path.name
        source.save(destination, format="PNG", optimize=False, compress_level=9)
        repaired, repaired_anchor = normalize(source)
        if repaired.getchannel("A").tobytes() != base.getchannel("A").tobytes():
            raise AssertionError(f"frame {index}: alpha changed")
        if repaired_anchor != anchor:
            raise AssertionError(f"frame {index}: anchor changed")
        records.append({
            "frame": index,
            "input_sha256": sha256(source_path),
            "output_sha256": sha256(destination),
            "changed_source_pixels": len(changed),
            "changes": changed,
            "alpha_unchanged": True,
            "anchor_unchanged": True,
            "field_color": "#B4A384",
            "detail_field_color": "#D1C2A8",
        })

    report = {
        "schema_version": "mgs.aui11.grunt-state-region-flatten.v1",
        "contract_sha256": sha256(contract_path),
        "spec_sha256": sha256(spec_path),
        "policy": "recolor existing occupied source samples only inside frozen cue regions; alpha/anchor/geometry unchanged",
        "frames": records,
    }
    report_path = Path(args.report).resolve()
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "changed_source_pixels": sum(item["changed_source_pixels"] for item in records), "report": str(report_path)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
