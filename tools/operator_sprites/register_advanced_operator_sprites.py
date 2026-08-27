#!/usr/bin/env python3
"""Register the complete advanced-operator atlas matrix and archive provenance."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import shutil
from pathlib import Path
from typing import Any

from PIL import Image

CLASS_ORDER = (
    "defender", "gunner", "mage_apprentice", "shock_trooper", "swordmaster",
    "immovable", "sniper", "sorcerer", "witch_doctor", "banner_guard", "sword_saint",
)
GENDER_ORDER = ("female", "male")
ACTION_ORDER = ("idle", "attack")
DIRECTION_ORDER = ("ne", "nw", "se", "sw")
GENERATED_DIRECTION_ORDER = ("ne", "se")
MIRROR_SOURCE = {"nw": "ne", "sw": "se"}
FRAME_COUNTS = {"idle": 24, "attack": 13}
ROWS = {"idle": 3, "attack": 2}
SOURCE_MANIFEST_ID = "advanced_operator_sprites_v1"
BEGIN_MARKER = "; BEGIN GENERATED ADVANCED OPERATOR ANIMATIONS"
END_MARKER = "; END GENERATED ADVANCED OPERATOR ANIMATIONS"
LEGACY_BEGIN_MARKER = "# BEGIN GENERATED ADVANCED OPERATOR ANIMATIONS"
LEGACY_END_MARKER = "# END GENERATED ADVANCED OPERATOR ANIMATIONS"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def atlas_path(repository: Path, class_id: str, gender: str, action: str, direction: str) -> Path:
    return (
        repository / "assets/sprites/operators/animated" / class_id / gender
        / f"{action}_{direction}.webp"
    )


def logical_id(class_id: str, gender: str, action: str, direction: str) -> str:
    return f"op_anim_{class_id}_{gender}_{action}_{direction}"


def validation_path(source_root: Path, class_id: str, gender: str, action: str, direction: str) -> Path:
    return source_root / "runtime-previews" / class_id / gender / f"{action}_{direction}.validation.json"


def ensure_complete(repository: Path, source_root: Path) -> None:
    missing: list[str] = []
    for class_id in CLASS_ORDER:
        for gender in GENDER_ORDER:
            for action in ACTION_ORDER:
                for direction in DIRECTION_ORDER:
                    path = atlas_path(repository, class_id, gender, action, direction)
                    if not path.is_file():
                        missing.append(str(path))
                for direction in GENERATED_DIRECTION_ORDER:
                    record = validation_path(source_root, class_id, gender, action, direction)
                    if not record.is_file():
                        missing.append(str(record))
    if missing:
        raise FileNotFoundError("incomplete advanced-operator matrix:\n" + "\n".join(missing))


def write_resources(repository: Path) -> list[Path]:
    target = repository / "data/presentation/operator_visuals"
    created: list[Path] = []
    for class_id in CLASS_ORDER:
        for gender in GENDER_ORDER:
            template_id = f"{class_id}_{gender}"
            direction_map_idle = "\n".join(
                f'&"{direction}": &"{logical_id(class_id, gender, "idle", direction)}"'
                + ("," if index < len(DIRECTION_ORDER) - 1 else "")
                for index, direction in enumerate(DIRECTION_ORDER)
            )
            direction_map_attack = "\n".join(
                f'&"{direction}": &"{logical_id(class_id, gender, "attack", direction)}"'
                + ("," if index < len(DIRECTION_ORDER) - 1 else "")
                for index, direction in enumerate(DIRECTION_ORDER)
            )
            text = f'''[gd_resource type="Resource" script_class="OperatorAnimationDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/presentation/operator_animation_def.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
schema_version = 2
visual_id = &"operator_{template_id}"
idle_by_direction = {{
{direction_map_idle}
}}
attack_by_direction = {{
{direction_map_attack}
}}
idle_frame_count = 24
attack_frame_count = 13
fps = 12.0
pivot = Vector2(0.5, 1)
source_cell_px = 640
display_height_px = 64
normalized_subject_height_px = 600
placeholder = false
'''
            path = target / f"{template_id}.tres"
            path.write_text(text, encoding="utf-8")
            created.append(path)
    return created


def gd_manifest_entry(
    repository: Path,
    class_id: str,
    gender: str,
    action: str,
    direction: str,
) -> str:
    path = atlas_path(repository, class_id, gender, action, direction)
    identifier = logical_id(class_id, gender, action, direction)
    source_direction = MIRROR_SOURCE.get(direction, direction)
    source_kind = "mirrored" if direction in MIRROR_SOURCE else "generated"
    mirrored_from = source_direction if source_kind == "mirrored" else ""
    relative = path.relative_to(repository).as_posix()
    frames = FRAME_COUNTS[action]
    loop = "true" if action == "idle" else "false"
    return f'''&"{identifier}": {{
"animations": {{
&"{action}": {{
&"fps": 12.0,
&"length": {frames},
&"loop": {loop},
&"start": 0
}}
}},
"columns": 8,
"frames": {frames},
"pattern": "res://{relative}",
"pivot": Vector2(0.5, 1),
"placeholder": false,
"provenance": {{
&"action": "{action}",
&"atlas_sha256": "{sha256_file(path)}",
&"class_id": "{class_id}",
&"direction": "{direction}",
&"gender": "{gender}",
&"mirrored_from": "{mirrored_from}",
&"source_kind": "{source_kind}",
&"source_manifest_id": "{SOURCE_MANIFEST_ID}"
}},
"size": Vector2i(640, 640)
}}'''


def update_manifest(repository: Path) -> int:
    manifest_path = repository / "assets/manifest.tres"
    text = manifest_path.read_text(encoding="utf-8")
    schema_line = "schema_version = 3"
    if "\nschema_version = " in text:
        lines = text.splitlines()
        replaced = False
        for index, line in enumerate(lines):
            if not replaced and line.startswith("schema_version = "):
                lines[index] = schema_line
                replaced = True
        text = "\n".join(lines) + ("\n" if text.endswith("\n") else "")
    else:
        resource_script = 'script = ExtResource("1_g6syk")\n'
        if resource_script not in text:
            raise ValueError("assets/manifest.tres is missing its expected resource script")
        text = text.replace(resource_script, resource_script + schema_line + "\n", 1)
    for begin_marker, end_marker in (
        (BEGIN_MARKER, END_MARKER),
        (LEGACY_BEGIN_MARKER, LEGACY_END_MARKER),
    ):
        if begin_marker in text:
            start = text.index(",\n" + begin_marker)
            end = text.index(end_marker, start) + len(end_marker)
            text = text[:start] + text[end:]
    entries = [
        gd_manifest_entry(repository, class_id, gender, action, direction)
        for class_id in CLASS_ORDER
        for gender in GENDER_ORDER
        for action in ACTION_ORDER
        for direction in DIRECTION_ORDER
    ]
    insertion = ",\n" + BEGIN_MARKER + "\n" + ",\n".join(entries) + "\n" + END_MARKER
    # Insert before the entries Dictionary's final brace while retaining the
    # previous asset entry's own closing brace.
    closing = "\n}"
    if not text.endswith(closing + "\n") and not text.endswith(closing):
        raise ValueError("assets/manifest.tres does not end with the expected entries brace")
    suffix = "\n" if text.endswith("\n") else ""
    body = text[:-len(suffix)] if suffix else text
    body = body[:-len(closing)] + insertion + closing
    manifest_path.write_text(body + suffix, encoding="utf-8")
    return len(entries)


def image_geometry(path: Path) -> list[int]:
    with Image.open(path) as image:
        return [image.width, image.height]


def build_source_manifest(repository: Path, source_root: Path) -> dict[str, Any]:
    existing_path = source_root / "source_manifest.json"
    existing: dict[str, Any] = {}
    if existing_path.is_file():
        existing = json.loads(existing_path.read_text(encoding="utf-8"))
    references = existing.get("references", [])
    if not isinstance(references, list) or len(references) != 22:
        raise ValueError("source manifest must retain exactly 22 approved GPT Image 2 references")

    keyframes: list[dict[str, Any]] = []
    for class_id in CLASS_ORDER:
        for gender in GENDER_ORDER:
            for direction in GENERATED_DIRECTION_ORDER:
                path = source_root / "keyframes" / class_id / gender / f"keyframe_{direction}.png"
                if not path.is_file():
                    raise FileNotFoundError(path)
                keyframes.append({
                    "id": f"keyframe:{class_id}:{gender}:{direction}",
                    "class_id": class_id,
                    "gender": gender,
                    "direction": direction,
                    "model": "gpt-image-2",
                    "path": str(path),
                    "sha256": sha256_file(path),
                    "dimensions": image_geometry(path),
                    "approved": True,
                })

    carriers: list[dict[str, Any]] = []
    runtime_sequences: list[dict[str, Any]] = []
    for class_id in CLASS_ORDER:
        for gender in GENDER_ORDER:
            for action in ACTION_ORDER:
                for direction in GENERATED_DIRECTION_ORDER:
                    record_path = validation_path(source_root, class_id, gender, action, direction)
                    record = json.loads(record_path.read_text(encoding="utf-8"))
                    carrier_path = Path(record["carrier"])
                    carriers.append({
                        "id": f"carrier:{class_id}:{gender}:{action}:{direction}",
                        "class_id": class_id,
                        "gender": gender,
                        "action": action,
                        "direction": direction,
                        "model": "veo-3.1-fast",
                        "path": str(carrier_path),
                        "sha256": sha256_file(carrier_path),
                        "source_media": record["source_media"],
                        "first_keyframe": f"keyframe:{class_id}:{gender}:{direction}",
                        "last_keyframe": f"keyframe:{class_id}:{gender}:{direction}",
                        "approved": True,
                    })
                for direction in DIRECTION_ORDER:
                    path = atlas_path(repository, class_id, gender, action, direction)
                    source_direction = MIRROR_SOURCE.get(direction, direction)
                    record_path = validation_path(source_root, class_id, gender, action, source_direction)
                    record = json.loads(record_path.read_text(encoding="utf-8"))
                    runtime_sequences.append({
                        "id": logical_id(class_id, gender, action, direction),
                        "class_id": class_id,
                        "gender": gender,
                        "action": action,
                        "direction": direction,
                        "source_kind": "mirrored" if direction in MIRROR_SOURCE else "generated",
                        "mirrored_from": source_direction if direction in MIRROR_SOURCE else "",
                        "path": str(path),
                        "sha256": sha256_file(path),
                        "cell_size": [640, 640],
                        "columns": 8,
                        "atlas_dimensions": [5120, ROWS[action] * 640],
                        "frame_count": FRAME_COUNTS[action],
                        "fps": 12.0,
                        "encoding": "webp-vp8-q92-lossless-alpha",
                        "validation_record": str(record_path),
                        "carrier_sha256": record["carrier_sha256"],
                    })

    payload: dict[str, Any] = {
        "schema_version": 1,
        "id": SOURCE_MANIFEST_ID,
        "repository": str(repository),
        "reference_count": len(references),
        "keyframe_count": len(keyframes),
        "carrier_count": len(carriers),
        "runtime_sequence_count": len(runtime_sequences),
        "references": references,
        "keyframes": keyframes,
        "carriers": carriers,
        "runtime_sequences": runtime_sequences,
    }
    existing_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    tsv_path = source_root / "source_manifest.tsv"
    with tsv_path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
        writer.writerow(["kind", "id", "class_id", "gender", "action", "direction", "path", "sha256"])
        for row in references:
            writer.writerow([
                "reference", row["id"], row["class_id"], row["gender"], "", "",
                row["design_reference"], row["design_reference_sha256"],
            ])
        for row in keyframes:
            writer.writerow(["keyframe", row["id"], row["class_id"], row["gender"], "", row["direction"], row["path"], row["sha256"]])
        for row in carriers:
            writer.writerow(["carrier", row["id"], row["class_id"], row["gender"], row["action"], row["direction"], row["path"], row["sha256"]])
        for row in runtime_sequences:
            writer.writerow(["runtime", row["id"], row["class_id"], row["gender"], row["action"], row["direction"], row["path"], row["sha256"]])
    return payload


def write_archive_docs(repository: Path, source_root: Path) -> None:
    readme = source_root / "README.md"
    readme.write_text(
        "# Advanced Operator Sprite Source Archive\n\n"
        "Immutable GPT Image 2 reference boards and directional keyframes, 88 silent "
        "four-second Veo 3.1 Fast carriers, validation records, and the exact 176-sequence "
        "runtime projection for the eleven recruit-derived specializations. Runtime atlases "
        "use 640×640 cells with a 560–640px subject edge; in-game footprint is controlled "
        "only by Godot presentation scale. `source_manifest.json` is canonical and "
        "`source_manifest.tsv` is its review projection.\n",
        encoding="utf-8",
    )
    (source_root / "requirements.lock").write_text("Pillow==11.3.0\n", encoding="utf-8")
    tools_target = source_root / "tools"
    tools_target.mkdir(parents=True, exist_ok=True)
    for name in [
        "build_advanced_operator_sprites.py",
        "build_advanced_operator_matrix.py",
        "validate_advanced_operator_sprites.py",
        "register_advanced_operator_sprites.py",
        "prepare_reference_archive.py",
    ]:
        source = repository / "tools/operator_sprites" / name
        if source.is_file():
            shutil.copy2(source, tools_target / name)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", type=Path, required=True)
    parser.add_argument("--source-root", type=Path, required=True)
    args = parser.parse_args()
    repository = args.repository.resolve()
    source_root = args.source_root.resolve()
    ensure_complete(repository, source_root)
    resources = write_resources(repository)
    manifest_rows = update_manifest(repository)
    source_manifest = build_source_manifest(repository, source_root)
    write_archive_docs(repository, source_root)
    print(json.dumps({
        "resources": len(resources),
        "manifest_rows": manifest_rows,
        "references": source_manifest["reference_count"],
        "keyframes": source_manifest["keyframe_count"],
        "carriers": source_manifest["carrier_count"],
        "runtime_sequences": source_manifest["runtime_sequence_count"],
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
