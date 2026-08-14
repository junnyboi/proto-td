#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import statistics
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image

SOURCE_CELL = 256
RUNTIME_CELL = 192
TARGET_SUBJECT_HEIGHT = 168
MAX_SUBJECT_WIDTH = 188
TARGET_PIVOT = (96, 180)
ALPHA_THRESHOLD = 127
DIRECTIONS = ("se", "ne", "nw", "sw")
STATES = {"idle": 24, "attack": 13}
CLASS_METADATA = {
    "vanguard_1": {"canon_class": "Shock Trooper", "display_height_px": 58},
    "guard_1": {"canon_class": "Swordmaster", "display_height_px": 60},
    "guard_2": {"canon_class": "Sword Saint", "display_height_px": 64},
}
SOURCE_MANIFEST_REL = Path(
    "assets/provenance/operators/td-025-remaining-source-manifest.json"
)
PLACEHOLDER_SOURCES = {
    ("guard_1", "attack", "ne"): "se",
}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def source_frames(path: Path, frame_count: int) -> list[Image.Image]:
    with Image.open(path) as raw:
        sheet = raw.convert("RGBA")
    expected = (SOURCE_CELL * frame_count, SOURCE_CELL)
    if sheet.size != expected:
        raise ValueError(f"{path}: expected source sheet {expected}, got {sheet.size}")
    frames: list[Image.Image] = []
    for index in range(frame_count):
        frame = sheet.crop(
            (index * SOURCE_CELL, 0, (index + 1) * SOURCE_CELL, SOURCE_CELL)
        )
        if frame.getchannel("A").getbbox() is None:
            raise ValueError(f"{path}: source frame {index} is empty")
        frames.append(frame)
    return frames


def runtime_frame(source: Image.Image, scale: float) -> Image.Image:
    bbox = source.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("cannot normalize an empty source frame")
    crop = source.crop(bbox)
    width = max(1, round(crop.width * scale))
    height = max(1, round(crop.height * scale))
    resized = crop.resize((width, height), Image.Resampling.NEAREST)
    rgba = np.asarray(resized.convert("RGBA")).copy()
    rgba[..., 3] = np.where(rgba[..., 3] > ALPHA_THRESHOLD, 255, 0).astype(
        np.uint8
    )
    rgba[rgba[..., 3] == 0, :3] = 0
    normalized = Image.fromarray(rgba, mode="RGBA")
    x = round(TARGET_PIVOT[0] - width / 2)
    y = TARGET_PIVOT[1] - height
    if x < 1 or y < 1 or x + width >= RUNTIME_CELL or y + height >= RUNTIME_CELL:
        raise ValueError(
            f"normalized frame violates runtime border: {(x, y, width, height)}"
        )
    canvas = Image.new("RGBA", (RUNTIME_CELL, RUNTIME_CELL), (0, 0, 0, 0))
    canvas.alpha_composite(normalized, (x, y))
    return canvas


def atlas(frames: list[Image.Image]) -> Image.Image:
    sheet = Image.new(
        "RGBA", (RUNTIME_CELL * len(frames), RUNTIME_CELL), (0, 0, 0, 0)
    )
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * RUNTIME_CELL, 0))
    return sheet


def frame_geometry(frames: list[Image.Image]) -> tuple[list[int], list[int]]:
    heights: list[int] = []
    areas: list[int] = []
    for frame in frames:
        alpha = np.asarray(frame.getchannel("A"))
        ys, xs = np.where(alpha > 0)
        if xs.size == 0:
            raise ValueError("empty frame during geometry measurement")
        heights.append(int(ys.max() - ys.min() + 1))
        areas.append(int(np.count_nonzero(alpha)))
    return heights, areas


def class_row(
    repo: Path,
    source_root: Path,
    source_inventory: dict[tuple[str, str, str], dict[str, Any]],
    class_id: str,
) -> tuple[dict[str, Any], str]:
    metadata = CLASS_METADATA[class_id]
    report_path = source_root / class_id / "character-normalization.json"
    report = json.loads(report_path.read_text(encoding="utf-8"))
    if report.get("status") != "PASS_TECHNICAL_STAGED_NOT_DELIVERABLE":
        raise ValueError(f"{class_id}: source report is not a technical pass")
    if report.get("character") != class_id:
        raise ValueError(f"{class_id}: source report character mismatch")
    report_states = report.get("states")
    if not isinstance(report_states, dict) or set(report_states) != set(STATES):
        raise ValueError(f"{class_id}: source report state set mismatch")

    families: dict[str, Any] = {}
    state_geometry: dict[str, Any] = {}
    state_areas: dict[str, list[int]] = {}
    state_heights: dict[str, list[int]] = {}
    output_root = repo / "assets/sprites/operators/animated" / class_id
    output_root.mkdir(parents=True, exist_ok=True)

    source_cache: dict[tuple[str, str], list[Image.Image]] = {}
    maximum_width = 0
    maximum_height = 0
    for state, frame_count in STATES.items():
        report_outputs = report_states[state].get("outputs")
        if not isinstance(report_outputs, dict) or set(report_outputs) != set(DIRECTIONS):
            raise ValueError(f"{class_id}/{state}: source direction set mismatch")
        for direction in DIRECTIONS:
            source_path = source_root / class_id / f"{class_id}_{state}_{direction}.png"
            report_output = report_outputs[direction]
            if Path(str(report_output.get("path", ""))).resolve() != source_path.resolve():
                raise ValueError(f"{class_id}/{state}/{direction}: source path mismatch")
            if sha256(source_path) != report_output.get("sha256"):
                raise ValueError(f"{class_id}/{state}/{direction}: stale source sheet")
            frames = source_frames(source_path, frame_count)
            source_cache[(state, direction)] = frames
            for frame in frames:
                bbox = frame.getchannel("A").getbbox()
                if bbox is None:
                    raise ValueError(f"{class_id}/{state}/{direction}: empty source frame")
                maximum_width = max(maximum_width, bbox[2] - bbox[0])
                maximum_height = max(maximum_height, bbox[3] - bbox[1])
    normalization_scale = min(
        float(TARGET_SUBJECT_HEIGHT) / float(maximum_height),
        float(MAX_SUBJECT_WIDTH) / float(maximum_width),
    )
    if not 0.1 <= normalization_scale <= 16.0:
        raise ValueError(f"{class_id}: unsafe runtime normalization scale {normalization_scale}")

    for state, frame_count in STATES.items():
        report_outputs = report_states[state].get("outputs")
        if not isinstance(report_outputs, dict) or set(report_outputs) != set(DIRECTIONS):
            raise ValueError(f"{class_id}/{state}: source direction set mismatch")
        families[state] = {}
        state_areas[state] = []
        state_heights[state] = []
        for direction in DIRECTIONS:
            source = source_cache[(state, direction)]
            source_metadata = source_inventory[(class_id, state, direction)]
            expected_placeholder = PLACEHOLDER_SOURCES.get((class_id, state, direction))
            if bool(source_metadata.get("placeholder", False)) != (
                expected_placeholder is not None
            ):
                raise ValueError(
                    f"{class_id}/{state}/{direction}: source placeholder flag mismatch"
                )
            if source_metadata.get("placeholder_source_direction") != expected_placeholder:
                raise ValueError(
                    f"{class_id}/{state}/{direction}: source placeholder direction mismatch"
                )
            runtime = [runtime_frame(frame, normalization_scale) for frame in source]
            runtime_heights, runtime_areas = frame_geometry(runtime)
            state_heights[state].extend(runtime_heights)
            state_areas[state].extend(runtime_areas)
            target = output_root / f"{state}_{direction}.png"
            atlas(runtime).save(target, optimize=True)
            raw_rgba = b"".join(frame.tobytes() for frame in runtime)
            resource_path = (
                f"res://assets/sprites/operators/animated/{class_id}/"
                f"{state}_{direction}.png"
            )
            families[state][direction] = {
                "asset_id": f"operator_anim_{class_id}_{state}_{direction}",
                "binary_alpha": True,
                "border_clear": True,
                "frame_count": frame_count,
                "max_opaque_pixels": max(runtime_areas),
                "min_opaque_pixels": min(runtime_areas),
                "path": resource_path,
                "placeholder": expected_placeholder is not None,
                "placeholder_source_direction": expected_placeholder,
                "generation_provider": str(source_metadata["provider"]),
                "generation_model": str(source_metadata["model"]),
                "source_video_sha256": str(source_metadata["source_sha256"]),
                "rgba_sha256": sha256_bytes(raw_rgba),
                "selected_source_frames": list(range(frame_count)),
                "sha256": sha256(target),
            }
            if any(height >= RUNTIME_CELL - 1 for height in runtime_heights):
                raise ValueError(f"{class_id}/{state}/{direction}: runtime frame clipped")
        state_geometry[state] = {
            "median_alpha_area_px": statistics.median(state_areas[state]),
            "median_height_px": statistics.median(state_heights[state]),
        }

    idle_height = float(state_geometry["idle"]["median_height_px"])
    idle_area = float(state_geometry["idle"]["median_alpha_area_px"])
    return (
        {
            "attack_to_idle_alpha_area_ratio": (
                float(state_geometry["attack"]["median_alpha_area_px"]) / idle_area
            ),
            "attack_to_idle_height_ratio": (
                float(state_geometry["attack"]["median_height_px"]) / idle_height
            ),
            "canon_class": metadata["canon_class"],
            "display_height_px": metadata["display_height_px"],
            "families": families,
            "normalization_scale": normalization_scale,
            "normalized_subject_height_px": round(idle_height),
            "state_geometry": state_geometry,
            "template_id": class_id,
        },
        sha256(report_path),
    )


def manifest_row(logical_id: str, asset: dict[str, Any], provenance: str) -> str:
    state = "idle" if "_idle_" in logical_id else "attack"
    frame_count = int(asset["frame_count"])
    loop = "true" if state == "idle" else "false"
    placeholder = "true" if bool(asset.get("placeholder", False)) else "false"
    return "\n".join(
        [
            f'&"{logical_id}": {{',
            '"animations": {',
            f'&"{state}": {{',
            '&"fps": 12.0,',
            f'&"length": {frame_count},',
            f'&"loop": {loop},',
            '&"start": 0',
            "}",
            "},",
            f'"frames": {frame_count},',
            f'"pattern": "{asset["path"]}",',
            '"pivot": Vector2(0.5, 0.94),',
            f'"placeholder": {placeholder},',
            f'"provenance_sha256": "{provenance}",',
            '"size": Vector2i(192, 192)',
            "}",
        ]
    )


def rewrite_manifest(repo: Path, compact: dict[str, Any]) -> None:
    rows: list[tuple[str, dict[str, Any]]] = []
    for class_entry in compact["classes"]:
        class_id = class_entry["template_id"]
        for state in STATES:
            for direction in DIRECTIONS:
                logical_id = f"op_anim_{class_id}_{state}_{direction}"
                rows.append((logical_id, class_entry["families"][state][direction]))
    rows.sort(key=lambda value: value[0])
    rendered: list[str] = []
    for logical_id, asset in rows:
        sidecar = repo / "assets/provenance" / f"{logical_id}.provenance.json"
        provenance = sha256(sidecar) if sidecar.is_file() else "0" * 64
        rendered.append(manifest_row(logical_id, asset, provenance))
    manifest_path = repo / "assets/manifest.tres"
    manifest = manifest_path.read_text(encoding="utf-8")
    start = manifest.find('\n&"op_anim_')
    end = manifest.rfind("\n}")
    if start < 0 or end <= start:
        raise ValueError("operator animation manifest block not found")
    manifest_path.write_text(
        manifest[:start] + "\n" + ",\n".join(rendered) + manifest[end:],
        encoding="utf-8",
    )


def write_resource(
    repo: Path,
    class_id: str,
    display_height: int,
    provenance_sha256: str,
    class_entry: dict[str, Any],
) -> None:
    def mapping(state: str) -> str:
        lines = ["{"]
        for index, direction in enumerate(("ne", "nw", "se", "sw")):
            comma = "," if index < 3 else ""
            lines.append(
                f'&"{direction}": &"op_anim_{class_id}_{state}_{direction}"{comma}'
            )
        lines.append("}")
        return "\n".join(lines)

    placeholder_sources: dict[str, str] = {}
    for state in STATES:
        for direction in DIRECTIONS:
            asset = class_entry["families"][state][direction]
            source_direction = asset.get("placeholder_source_direction")
            if source_direction is not None:
                placeholder_sources[
                    f"op_anim_{class_id}_{state}_{direction}"
                ] = str(source_direction)
    placeholder_lines = ["{"]
    for index, logical_id in enumerate(sorted(placeholder_sources)):
        comma = "," if index < len(placeholder_sources) - 1 else ""
        placeholder_lines.append(
            f'&"{logical_id}": &"{placeholder_sources[logical_id]}"{comma}'
        )
    placeholder_lines.append("}")
    placeholder_map = "\n".join(placeholder_lines)
    placeholder = "true" if placeholder_sources else "false"

    text = f'''[gd_resource type="Resource" script_class="OperatorAnimationDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/presentation/operator_animation_def.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
schema_version = 1
visual_id = &"operator_{class_id}"
idle_by_direction = {mapping("idle")}
attack_by_direction = {mapping("attack")}
idle_frame_count = 24
attack_frame_count = 13
fps = 12.0
pivot = Vector2(0.5, 0.94)
display_height_px = {display_height}
normalized_subject_height_px = {int(class_entry["normalized_subject_height_px"])}
provenance_sha256 = "{provenance_sha256}"
placeholder = {placeholder}
placeholder_source_by_logical_id = {placeholder_map}
'''
    target = repo / "data/presentation/operator_visuals" / f"{class_id}.tres"
    target.write_text(text, encoding="utf-8")


def run(repo: Path, source_root: Path, classes: list[str]) -> None:
    unknown = set(classes) - set(CLASS_METADATA)
    if unknown:
        raise ValueError(f"unsupported operator classes: {sorted(unknown)}")
    compact_path = repo / "assets/provenance/operators/operator-animation-v1.json"
    compact = json.loads(compact_path.read_text(encoding="utf-8"))
    source_document = json.loads(
        (repo / SOURCE_MANIFEST_REL).read_text(encoding="utf-8")
    )
    if source_document.get("status") != "PASS_SOURCE_ASSEMBLY":
        raise ValueError("remaining source manifest is not an assembly pass")
    source_inventory = {
        (str(row["character"]), str(row["state"]), str(row["direction"])): row
        for row in source_document.get("rows", [])
    }
    expected_inventory = {
        (class_id, state, direction)
        for class_id in CLASS_METADATA
        for state in STATES
        for direction in DIRECTIONS
    }
    if set(source_inventory) != expected_inventory:
        raise ValueError("remaining source manifest inventory mismatch")
    existing = {
        str(row["template_id"]): row
        for row in compact.get("classes", [])
        if isinstance(row, dict) and row.get("template_id")
    }
    report_hashes: dict[str, str] = {}
    for class_id in classes:
        existing[class_id], report_hashes[class_id] = class_row(
            repo, source_root, source_inventory, class_id
        )
    compact["classes"] = [existing[key] for key in sorted(existing)]
    compact["acceptance"]["accepted_classes"] = sorted(
        set(compact["acceptance"].get("accepted_classes", [])) | set(classes)
    )
    compact["acceptance"]["blocked_classes_use_legacy_fallback"] = sorted(
        value
        for value in compact["acceptance"].get(
            "blocked_classes_use_legacy_fallback", []
        )
        if value not in classes
    )
    compact["acceptance"]["status"] = (
        "all_ten_operator_classes_integrated_with_one_declared_placeholder"
    )
    known_placeholders = {
        str(row["logical_id"]): str(row["source_direction"])
        for row in compact.get("known_placeholders", [])
    }
    for (class_id, state, direction), source_direction in PLACEHOLDER_SOURCES.items():
        known_placeholders[
            f"op_anim_{class_id}_{state}_{direction}"
        ] = source_direction
    compact["known_placeholders"] = [
        {"logical_id": logical_id, "source_direction": known_placeholders[logical_id]}
        for logical_id in sorted(known_placeholders)
    ]
    compact_path.write_text(
        json.dumps(compact, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    for class_id in classes:
        write_resource(
            repo,
            class_id,
            int(CLASS_METADATA[class_id]["display_height_px"]),
            report_hashes[class_id],
            existing[class_id],
        )
    rewrite_manifest(repo, compact)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path("."))
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--class-id", action="append", required=True, dest="classes")
    args = parser.parse_args()
    run(args.repo.resolve(), args.source_root.resolve(), args.classes)
    print("OPERATOR_ANIMATION_IMPORT_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
