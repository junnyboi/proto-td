#!/usr/bin/env python3
"""Normalize processed enemy sheets to ~600px cells and emit a Godot manifest."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import cv2
import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
PROCESSED = REPO / "docs" / "enemy-variants" / "processed"
OUTPUT = REPO / "assets" / "enemy-variants"
MANIFEST = REPO / "assets" / "enemy_variant_manifest.tres"
TARGET_LONG_EDGE = 620
RUNTIME_COLUMNS = 4
CHROMA_HAZE_ALPHA_CUTOFF = 128
COMPONENT_MIN_PIXELS = 64
COMPONENT_MIN_RATIO = 0.005
UNION_MARGIN = 12
EXPECTED_ENEMIES = ("shieldbearer", "breacher", "interceptor")
EXPECTED_ACTIONS = ("attack", "walk")
EXPECTED_DIRECTIONS = ("ne", "nw", "se", "sw")


def repository_relative(raw_path: str) -> str:
    path = Path(raw_path)
    if path.is_absolute():
        path = path.relative_to(REPO)
    normalized = path.as_posix()
    if not (REPO / normalized).is_file():
        raise ValueError(f"missing source carrier: {normalized}")
    return normalized


def clean_frame(frame: Image.Image) -> tuple[Image.Image, tuple[int, int, int, int]]:
    rgba = np.array(frame.convert("RGBA"), dtype=np.uint8)
    alpha = rgba[:, :, 3]
    alpha[alpha <= CHROMA_HAZE_ALPHA_CUTOFF] = 0
    binary = (alpha > 0).astype(np.uint8)
    count, labels, stats, _centroids = cv2.connectedComponentsWithStats(
        binary, connectivity=8
    )
    candidates: list[tuple[int, int]] = []
    height, width = alpha.shape
    for label in range(1, count):
        x, y, component_width, component_height, area = stats[label]
        touches_border = (
            x == 0
            or y == 0
            or x + component_width >= width
            or y + component_height >= height
        )
        if not touches_border:
            candidates.append((label, int(area)))
    if not candidates:
        raise ValueError("no non-border foreground component found")
    largest_area = max(area for _label, area in candidates)
    keep_threshold = min(
        largest_area,
        max(COMPONENT_MIN_PIXELS, round(largest_area * COMPONENT_MIN_RATIO)),
    )
    keep_labels = [label for label, area in candidates if area >= keep_threshold]
    keep_mask = np.isin(labels, keep_labels)
    rgba[~keep_mask, 3] = 0
    ys, xs = np.nonzero(keep_mask)
    bbox = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    return Image.fromarray(rgba, "RGBA"), bbox


def normalize_sequence(source_json: Path) -> dict[str, Any]:
    data = json.loads(source_json.read_text(encoding="utf-8"))
    data["source_video"] = repository_relative(str(data["source_video"]))
    source_json.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    sequence = str(data["sequence"])
    direction, action = sequence.lower().split("_", maxsplit=1)
    enemy = source_json.parents[1].name
    if enemy not in EXPECTED_ENEMIES:
        raise ValueError(f"unexpected enemy directory: {enemy}")
    if action not in EXPECTED_ACTIONS or direction not in EXPECTED_DIRECTIONS:
        raise ValueError(f"unexpected sequence: {sequence}")
    frame_count = int(data["frame_count"])
    if frame_count != 8:
        raise ValueError(f"{enemy}/{sequence}: expected 8 frames, got {frame_count}")
    cell_width = int(data["cell_width"])
    cell_height = int(data["cell_height"])
    source_sheet = source_json.with_name(str(data["sheet"]))
    with Image.open(source_sheet) as image:
        image = image.convert("RGBA")
        if image.size != (cell_width * frame_count, cell_height):
            raise ValueError(
                f"{enemy}/{sequence}: sheet size {image.size} does not match "
                f"{cell_width * frame_count}x{cell_height}"
            )
        cleaned: list[Image.Image] = []
        bboxes: list[tuple[int, int, int, int]] = []
        for index in range(frame_count):
            frame = image.crop(
                (index * cell_width, 0, (index + 1) * cell_width, cell_height)
            )
            clean, bbox = clean_frame(frame)
            cleaned.append(clean)
            bboxes.append(bbox)
        union = (
            max(0, min(bbox[0] for bbox in bboxes) - UNION_MARGIN),
            max(0, min(bbox[1] for bbox in bboxes) - UNION_MARGIN),
            min(cell_width, max(bbox[2] for bbox in bboxes) + UNION_MARGIN),
            min(cell_height, max(bbox[3] for bbox in bboxes) + UNION_MARGIN),
        )
        union_width = union[2] - union[0]
        union_height = union[3] - union[1]
        scale = TARGET_LONG_EDGE / float(max(union_width, union_height))
        runtime_width = max(1, round(union_width * scale))
        runtime_height = max(1, round(union_height * scale))
        runtime_rows = (frame_count + RUNTIME_COLUMNS - 1) // RUNTIME_COLUMNS
        output_sheet = Image.new(
            "RGBA", (runtime_width * RUNTIME_COLUMNS, runtime_height * runtime_rows)
        )
        for index, frame in enumerate(cleaned):
            frame = frame.crop(union)
            if frame.size != (runtime_width, runtime_height):
                frame = frame.resize(
                    (runtime_width, runtime_height), Image.Resampling.LANCZOS
                )
            output_sheet.alpha_composite(
                frame,
                (
                    (index % RUNTIME_COLUMNS) * runtime_width,
                    (index // RUNTIME_COLUMNS) * runtime_height,
                ),
            )
    runtime_alpha = output_sheet.getchannel("A").point(
        lambda value: 0 if value <= 16 else value
    )
    output_sheet.putalpha(runtime_alpha)
    output_name = f"{enemy}_{action}_{direction}.webp"
    output_path = OUTPUT / output_name
    output_sheet.save(output_path, "WEBP", lossless=True, method=4)
    alpha = output_sheet.getchannel("A")
    alpha_min, alpha_max = alpha.getextrema()
    if alpha_min != 0 or alpha_max < 128:
        raise ValueError(
            f"{output_name}: expected transparent background and visible subject alpha; "
            f"got {alpha_min}..{alpha_max}"
        )
    runtime_data = {
        "schema": "protos.enemy-variant.sequence.v1",
        "enemy": enemy,
        "action": action,
        "direction": direction,
        "mirrored_from": data.get("mirrored_from"),
        "frame_count": frame_count,
        "playback_fps": float(data["playback_fps"]),
        "loop": action == "walk",
        "columns": RUNTIME_COLUMNS,
        "rows": runtime_rows,
        "cell_width": runtime_width,
        "cell_height": runtime_height,
        "sheet": output_name,
        "source_cell_width": cell_width,
        "source_cell_height": cell_height,
        "source_video": data["source_video"],
        "background_removed": data["background_removed"],
    }
    (OUTPUT / f"{enemy}_{action}_{direction}.json").write_text(
        json.dumps(runtime_data, indent=2) + "\n", encoding="utf-8"
    )
    return runtime_data


def godot_bool(value: bool) -> str:
    return "true" if value else "false"


def write_manifest(rows: list[dict[str, Any]]) -> None:
    lines = [
        '[gd_resource type="Resource" script_class="AssetManifest" format=3]',
        "",
        '[ext_resource type="Script" path="res://assets/asset_manifest.gd" id="1_manifest"]',
        "",
        "[resource]",
        'script = ExtResource("1_manifest")',
        "entries = {",
    ]
    for index, row in enumerate(sorted(rows, key=lambda value: (value["enemy"], value["action"], value["direction"]))):
        asset_id = "enemy_variant_%s_%s_%s" % (
            row["enemy"],
            row["action"],
            row["direction"],
        )
        lines.extend(
            [
                f'&"{asset_id}": {{',
                '"animations": {',
                '&"default": {',
                f'&"fps": {float(row["playback_fps"]):.1f},',
                f'&"length": {int(row["frame_count"])},',
                f'&"loop": {godot_bool(bool(row["loop"]))},',
                '&"start": 0',
                "}",
                "},",
				f'"columns": {int(row["columns"])},',
                f'"frames": {int(row["frame_count"])},',
                f'"pattern": "res://assets/enemy-variants/{row["sheet"]}",',
                '"pivot": Vector2(0.5, 1),',
                '"placeholder": false,',
                f'"size": Vector2i({int(row["cell_width"])}, {int(row["cell_height"])})',
                "}" + ("," if index + 1 < len(rows) else ""),
            ]
        )
    lines.extend(["}", ""])
    MANIFEST.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for old in OUTPUT.glob("*"):
        if old.is_file():
            old.unlink()
    rows = [normalize_sequence(path) for path in sorted(PROCESSED.glob("*/*/*.json"))]
    expected = len(EXPECTED_ENEMIES) * len(EXPECTED_ACTIONS) * len(EXPECTED_DIRECTIONS)
    if len(rows) != expected:
        raise ValueError(f"expected {expected} sequences, found {len(rows)}")
    write_manifest(rows)
    print(json.dumps({"status": "ok", "sequences": len(rows), "target_long_edge": TARGET_LONG_EDGE}))


if __name__ == "__main__":
    main()
