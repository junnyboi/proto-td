#!/usr/bin/env python3
"""Reduce misleading bright ordinary-material highlights without changing grunt geometry."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

from PIL import Image


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    parser.add_argument("--spec", required=True)
    parser.add_argument("--input-root", required=True)
    parser.add_argument("--output-root", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()
    project = Path(args.project).resolve()
    sys.path.insert(0, str(project / "tools/art_pipeline/character_vfx"))
    from pixel_ops import anchor_in_cell, key_and_threshold, nearest_source_index, palette_map, parse_hex, remove_small_components, resize_nearest  # type: ignore[import-not-found]

    spec_path = Path(args.spec).resolve()
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    normalization = spec["normalization"]
    resize_width, resize_height = normalization["resize"]
    alpha_threshold = normalization["alpha_threshold"]
    palette = [parse_hex(value) for value in spec["palette"]]
    cell_size = (spec["atlas"]["cell_width"], spec["atlas"]["cell_height"])
    input_root = Path(args.input_root).resolve()
    output_root = Path(args.output_root).resolve()
    output_root.mkdir(parents=True, exist_ok=True)
    misleading = {parse_hex("#B4A384"), parse_hex("#D1C2A8"), parse_hex("#E0C99D")}
    replacement = parse_hex("#8B795B")
    records = []

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
        before, anchor = normalize(source)
        assignments = set()
        for final_y in range(before.height):
            for final_x in range(before.width):
                red, green, blue, alpha = before.getpixel((final_x, final_y))
                if alpha == 0 or (red, green, blue) not in misleading:
                    continue
                normalized_x = final_x - anchor["dx"]
                normalized_y = final_y - anchor["dy"]
                source_x = nearest_source_index(normalized_x, source.width, resize_width)
                source_y = nearest_source_index(normalized_y, source.height, resize_height)
                assignments.add((source_x, source_y))
        pixels = source.load()
        changed = 0
        for source_x, source_y in sorted(assignments):
            red, green, blue, alpha = pixels[source_x, source_y]
            if alpha >= alpha_threshold and (red, green, blue) != replacement:
                pixels[source_x, source_y] = (*replacement, alpha)
                changed += 1
        destination = output_root / source_path.name
        source.save(destination, format="PNG", optimize=False, compress_level=9)
        after, after_anchor = normalize(source)
        if before.getchannel("A").tobytes() != after.getchannel("A").tobytes():
            raise AssertionError(f"frame {index}: alpha changed")
        if anchor != after_anchor:
            raise AssertionError(f"frame {index}: anchor changed")
        remaining = sum(1 for pixel in after.getdata() if pixel[3] and pixel[:3] in misleading)
        records.append({
            "frame": index,
            "input_sha256": sha256(source_path),
            "output_sha256": sha256(destination),
            "changed_source_pixels": changed,
            "remaining_misleading_final_pixels": remaining,
            "alpha_unchanged": True,
            "anchor_unchanged": True,
        })
    report = {
        "schema_version": "mgs.aui11.grunt-base-highlight-reduction.v1",
        "spec_sha256": sha256(spec_path),
        "policy": "recolor occupied source samples mapping to the three brightest ordinary ceramic palette values; alpha, occupied coordinates, anchors, phase order, Charm contract, and review thresholds unchanged",
        "source_palette_values": ["#B4A384", "#D1C2A8", "#E0C99D"],
        "replacement": "#8B795B",
        "frames": records,
    }
    report_path = Path(args.report).resolve()
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "changed_source_pixels": sum(item["changed_source_pixels"] for item in records)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
