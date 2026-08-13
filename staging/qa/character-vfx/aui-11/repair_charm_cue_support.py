#!/usr/bin/env python3
"""Add connected base-art support only where the frozen Charm cue contract is underfilled."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import sys
from pathlib import Path
from typing import Callable

from PIL import Image


SEMANTIC_MINIMUM = 128
AUTHORED_SIGNAL_TARGET = 200


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


def count_color(image: Image.Image, bounds: tuple[int, int, int, int], target: tuple[int, int, int]) -> int:
    return sum(
        1
        for y in range(bounds[1], bounds[3])
        for x in range(bounds[0], bounds[2])
        if image.getpixel((x, y))[3] and image.getpixel((x, y))[:3] == target
    )


def nearest_surviving(
    image: Image.Image,
    target_x: int,
    target_y: int,
    alpha_threshold: int,
) -> tuple[int, int, tuple[int, int, int, int]]:
    pixels = image.convert("RGBA").load()
    candidates = [
        (abs(x - target_x) + abs(y - target_y), y, x, pixels[x, y])
        for y in range(image.height)
        for x in range(image.width)
        if pixels[x, y][3] >= alpha_threshold
    ]
    if not candidates:
        raise ValueError("source has no alpha-surviving pixel")
    _, y, x, pixel = min(candidates)
    return x, y, pixel


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    parser.add_argument("--contract", required=True)
    parser.add_argument("--spec", required=True)
    parser.add_argument("--oracle", required=True)
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

    oracle_spec = importlib.util.spec_from_file_location("aui11_charm_oracle", Path(args.oracle).resolve())
    if oracle_spec is None or oracle_spec.loader is None:
        raise RuntimeError("cannot load Charm oracle")
    oracle = importlib.util.module_from_spec(oracle_spec)
    oracle_spec.loader.exec_module(oracle)

    contract_path = Path(args.contract).resolve()
    spec_path = Path(args.spec).resolve()
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    packet_spec = json.loads(spec_path.read_text(encoding="utf-8"))
    normalization = packet_spec["normalization"]
    resize_width, resize_height = normalization["resize"]
    alpha_threshold = normalization["alpha_threshold"]
    palette = [parse_hex(value) for value in packet_spec["palette"]]
    cell_size = (packet_spec["atlas"]["cell_width"], packet_spec["atlas"]["cell_height"])
    input_root = Path(args.input_root).resolve()
    output_root = Path(args.output_root).resolve()
    output_root.mkdir(parents=True, exist_ok=True)

    light = parse_hex(contract["stripe"]["light"])
    dark = parse_hex(contract["stripe"]["dark"])
    tab = parse_hex(contract["tab_color"])
    knot = parse_hex(contract["knot_color"])
    regions = contract["regions_sixteenths"]
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
        input_sha = sha256(source_path)
        edits: list[dict[str, object]] = []

        def current() -> tuple[Image.Image, Image.Image, tuple[int, int, int, int], dict[str, int]]:
            base, anchor = normalize(source)
            box = base.getchannel("A").getbbox()
            if box is None:
                raise ValueError(f"frame {index} became empty")
            bounds = (box[0], box[1], box[2] - 1, box[3] - 1)
            charmed = oracle.transform(base, index, contract)
            return base, charmed, bounds, anchor

        def add_final_pixel(final_x: int, final_y: int, reason: str) -> None:
            base, _, _, anchor = current()
            if base.getpixel((final_x, final_y))[3] > 0:
                return
            normalized_x = final_x - anchor["dx"]
            normalized_y = final_y - anchor["dy"]
            source_x = nearest_source_index(normalized_x, source.width, resize_width)
            source_y = nearest_source_index(normalized_y, source.height, resize_height)
            copied_x, copied_y, copied = nearest_surviving(source, source_x, source_y, alpha_threshold)
            source.putpixel((source_x, source_y), (*copied[:3], 255))
            repaired, _, repaired_bounds, _ = current()
            if repaired.getpixel((final_x, final_y))[3] == 0:
                raise AssertionError(f"frame {index}: support edit did not survive at {final_x},{final_y}")
            edits.append({
                "reason": reason,
                "final": [final_x, final_y],
                "source": [source_x, source_y],
                "copied_from": [copied_x, copied_y],
                "copied_rgb": list(copied[:3]),
                "bounds_after": list(repaired_bounds),
            })

        def candidates(
            cue_region: tuple[int, int, int, int],
            predicate: Callable[[int, int], bool],
            forbidden: set[tuple[int, int]],
        ) -> list[tuple[int, int]]:
            base, _, _, _ = current()
            center_x = (cue_region[0] + cue_region[2] - 1) // 2
            center_y = (cue_region[1] + cue_region[3] - 1) // 2
            result = []
            for y in range(cue_region[1], cue_region[3]):
                for x in range(cue_region[0], cue_region[2]):
                    if (x, y) in forbidden or not predicate(x, y) or base.getpixel((x, y))[3] > 0:
                        continue
                    if not any(
                        0 <= nx < base.width and 0 <= ny < base.height and base.getpixel((nx, ny))[3] > 0
                        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
                    ):
                        continue
                    result.append((abs(x - center_x) + abs(y - center_y), y, x))
            return [(x, y) for _, y, x in sorted(result)]

        base, charmed, bounds, _ = current()
        knot_center = (
            max(bounds[0], min(bounds[2], scaled(bounds[0], bounds[2] - bounds[0] + 1, regions["knot_center"][0]))),
            max(bounds[1], min(bounds[3], scaled(bounds[1], bounds[3] - bounds[1] + 1, regions["knot_center"][1]))),
        )
        knot_points = {
            knot_center,
            (knot_center[0] - 1, knot_center[1]),
            (knot_center[0] + 1, knot_center[1]),
            (knot_center[0], knot_center[1] - 1),
            (knot_center[0], knot_center[1] + 1),
        }
        for x, y in sorted(knot_points):
            if base.getpixel((x, y))[3] == 0:
                add_final_pixel(x, y, "knot_support")

        for tab_name in ("left_tab", "right_tab"):
            while True:
                base, charmed, bounds, _ = current()
                cue = region(bounds, regions[tab_name])
                measured = count_color(charmed, cue, tab)
                if measured >= 64:
                    break
                notch = (cue[2] - 1, cue[1]) if tab_name == "left_tab" else (cue[0], cue[1])
                available = candidates(cue, lambda _x, _y: True, knot_points | {notch})
                if not available:
                    raise AssertionError(f"frame {index}: cannot fill {tab_name} from {measured}")
                add_final_pixel(*available[0], f"{tab_name}_support")

        tab_regions: set[tuple[int, int]] = set()
        base, _, bounds, _ = current()
        for tab_name in ("left_tab", "right_tab"):
            cue = region(bounds, regions[tab_name])
            tab_regions.update((x, y) for y in range(cue[1], cue[3]) for x in range(cue[0], cue[2]))
        forbidden = tab_regions | knot_points
        stripe = contract["stripe"]
        for region_name in ("shoulder", "ankles"):
            for target_name, target_color, active in (("light", light, True), ("dark", dark, False)):
                while True:
                    base, charmed, bounds, _ = current()
                    cue = region(bounds, regions[region_name])
                    measured = count_color(charmed, cue, target_color)
                    if measured >= AUTHORED_SIGNAL_TARGET:
                        break
                    phase = stripe["frame_phase_multiplier"] * index
                    predicate = lambda x, y, desired=active: (((x + y + phase) % stripe["period"] < stripe["active_width"]) == desired)
                    available = candidates(cue, predicate, forbidden)
                    if not available:
                        raise AssertionError(f"frame {index}: cannot fill {region_name}_{target_name} from {measured}")
                    add_final_pixel(*available[0], f"{region_name}_{target_name}_support")

        destination = output_root / source_path.name
        source.save(destination, format="PNG", optimize=False, compress_level=9)
        final_base, final_charmed, final_bounds, _ = current()
        final_counts = {}
        for region_name in ("shoulder", "ankles"):
            cue = region(final_bounds, regions[region_name])
            final_counts[region_name] = {"light": count_color(final_charmed, cue, light), "dark": count_color(final_charmed, cue, dark)}
        for tab_name in ("left_tab", "right_tab"):
            cue = region(final_bounds, regions[tab_name])
            final_counts[tab_name] = {"tab": count_color(final_charmed, cue, tab)}
        final_knot = {
            (x - knot_center[0], y - knot_center[1])
            for y in range(knot_center[1] - 3, knot_center[1] + 4)
            for x in range(knot_center[0] - 3, knot_center[0] + 4)
            if final_charmed.getpixel((x, y))[3] and final_charmed.getpixel((x, y))[:3] == knot
        }
        records.append({
            "frame": index,
            "input_sha256": input_sha,
            "output_sha256": sha256(destination),
            "edit_count": len(edits),
            "edits": edits,
            "final_counts": final_counts,
            "final_knot_offsets": [list(value) for value in sorted(final_knot)],
        })

    report = {
        "schema_version": "mgs.aui11.charm-cue-support-repair.v1",
        "contract_sha256": sha256(contract_path),
        "spec_sha256": sha256(spec_path),
        "policy": "connected source support only; frozen regions, colors, semantic minimum 128, topology, and transform unchanged; authored signal target 200",
        "semantic_minimum_unchanged": SEMANTIC_MINIMUM,
        "authored_signal_target": AUTHORED_SIGNAL_TARGET,
        "frames": records,
    }
    report_path = Path(args.report).resolve()
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "edit_count": sum(item["edit_count"] for item in records), "report": str(report_path)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
