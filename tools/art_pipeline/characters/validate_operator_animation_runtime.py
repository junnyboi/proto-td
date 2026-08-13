#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

EXPECTED_CLASSES = {
    "caster_1",
    "caster_2",
    "defender_1",
    "defender_2",
    "sniper_1",
    "sniper_2",
    "vanguard_2",
}
EXPECTED_STATES = {"idle": 24, "attack": 13}
EXPECTED_DIRECTIONS = {"se", "ne", "nw", "sw"}
EXPECTED_CELL = (192, 192)
EXPECTED_PIVOT = (0.5, 0.94)
EXPECTED_PLACEHOLDERS = {
    ("sniper_2", "attack", "ne"): "se",
    ("sniper_2", "attack", "nw"): "sw",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate(repo: Path) -> None:
    provenance_path = repo / "assets/provenance/operators/operator-animation-v1.json"
    document = json.loads(provenance_path.read_text(encoding="utf-8"))
    if document.get("schema") != "td-025-operator-animation-runtime-v1":
        raise ValueError("operator animation provenance schema mismatch")
    if tuple(document.get("runtime_cell", [])) != EXPECTED_CELL:
        raise ValueError("operator animation runtime cell mismatch")
    if tuple(document.get("pivot", [])) != EXPECTED_PIVOT:
        raise ValueError("operator animation runtime pivot mismatch")
    classes = document.get("classes")
    if not isinstance(classes, list):
        raise ValueError("operator animation class list missing")
    by_id = {row.get("template_id"): row for row in classes if isinstance(row, dict)}
    if set(by_id) != EXPECTED_CLASSES:
        raise ValueError(f"operator animation class set mismatch: {sorted(by_id)}")

    seen: set[str] = set()
    for class_id in sorted(EXPECTED_CLASSES):
        row = by_id[class_id]
        families = row.get("families")
        if not isinstance(families, dict) or set(families) != set(EXPECTED_STATES):
            raise ValueError(f"{class_id}: family set mismatch")
        for state, frame_count in EXPECTED_STATES.items():
            directions = families[state]
            if not isinstance(directions, dict) or set(directions) != EXPECTED_DIRECTIONS:
                raise ValueError(f"{class_id}/{state}: direction set mismatch")
            for direction in sorted(EXPECTED_DIRECTIONS):
                asset = directions[direction]
                asset_id = str(asset.get("asset_id", ""))
                expected_id = f"operator_anim_{class_id}_{state}_{direction}"
                if asset_id != expected_id or asset_id in seen:
                    raise ValueError(f"{class_id}/{state}/{direction}: logical id mismatch")
                seen.add(asset_id)
                expected_source = EXPECTED_PLACEHOLDERS.get((class_id, state, direction))
                if bool(asset.get("placeholder", False)) != (expected_source is not None):
                    raise ValueError(f"{asset_id}: placeholder flag mismatch")
                if asset.get("placeholder_source_direction") != expected_source:
                    raise ValueError(f"{asset_id}: placeholder source mismatch")
                rel_path = str(asset.get("path", ""))
                if not rel_path.startswith("res://"):
                    raise ValueError(f"{asset_id}: invalid resource path")
                path = repo / rel_path.removeprefix("res://")
                if not path.is_file() or sha256(path) != asset.get("sha256"):
                    raise ValueError(f"{asset_id}: missing or stale runtime atlas")
                with Image.open(path) as image:
                    rgba = image.convert("RGBA")
                    if rgba.size != (EXPECTED_CELL[0] * frame_count, EXPECTED_CELL[1]):
                        raise ValueError(f"{asset_id}: atlas dimensions mismatch")
                    alpha = rgba.getchannel("A")
                    if sum(alpha.histogram()[1:255]) != 0:
                        raise ValueError(f"{asset_id}: alpha is not binary")
                    if alpha.crop((0, 0, rgba.width, 1)).getbbox() is not None:
                        raise ValueError(f"{asset_id}: top border is occupied")
                    if alpha.crop((0, rgba.height - 1, rgba.width, rgba.height)).getbbox() is not None:
                        raise ValueError(f"{asset_id}: bottom border is occupied")
    if len(seen) != len(EXPECTED_CLASSES) * len(EXPECTED_STATES) * len(EXPECTED_DIRECTIONS):
        raise ValueError(f"operator animation atlas count mismatch: {len(seen)}")
    known = document.get("known_placeholders")
    expected_known = [
        {"logical_id": "op_anim_sniper_2_attack_ne", "source_direction": "se"},
        {"logical_id": "op_anim_sniper_2_attack_nw", "source_direction": "sw"},
    ]
    if known != expected_known:
        raise ValueError(f"operator animation known placeholder mismatch: {known}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path("."))
    args = parser.parse_args()
    validate(args.repo.resolve())
    print("OPERATOR_ANIMATION_RUNTIME_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
