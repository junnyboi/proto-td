#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import re
import subprocess
import sys
from pathlib import Path


def load_provenance_module(repo: Path):
    path = repo / "tools/presentation_qa/provenance.py"
    spec = importlib.util.spec_from_file_location("operator_animation_provenance", path)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load provenance module")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def atlas_entries(repo: Path) -> dict[str, dict[str, object]]:
    compact_path = repo / "assets/provenance/operators/operator-animation-v1.json"
    compact = json.loads(compact_path.read_text(encoding="utf-8"))
    rows: dict[str, dict[str, object]] = {}
    for class_row in compact.get("classes", []):
        class_id = str(class_row.get("template_id", ""))
        families = class_row.get("families", {})
        for state in ("idle", "attack"):
            directions = families.get(state, {})
            for direction in ("se", "ne", "nw", "sw"):
                asset = directions.get(direction, {})
                logical_id = f"op_anim_{class_id}_{state}_{direction}"
                path = str(asset.get("path", ""))
                frames = int(asset.get("frame_count", 0))
                if not path.startswith("res://") or frames < 1:
                    raise ValueError(f"{logical_id}: invalid compact atlas row")
                rows[logical_id] = {"pattern": path, "frames": frames}
    if len(rows) != 16:
        raise ValueError(f"expected 16 operator animation rows, got {len(rows)}")
    return rows


def sidecar_digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def replace_manifest_hash(manifest: str, logical_id: str, digest: str) -> str:
    pattern = re.compile(
        rf'(&"{re.escape(logical_id)}": \{{.*?"provenance_sha256": ")[0-9a-f]{{64}}(")',
        re.DOTALL,
    )
    updated, count = pattern.subn(rf"\g<1>{digest}\g<2>", manifest, count=1)
    if count != 1:
        raise ValueError(f"{logical_id}: manifest row missing or ambiguous")
    return updated


def run(repo: Path, write: bool) -> None:
    validator = repo / "tools/art_pipeline/characters/validate_operator_animation_runtime.py"
    subprocess.run([sys.executable, str(validator), "--repo", str(repo)], check=True)
    provenance = load_provenance_module(repo)
    entries = atlas_entries(repo)
    output = repo / "assets/provenance"
    manifest_path = repo / "assets/manifest.tres"
    manifest = manifest_path.read_text(encoding="utf-8")

    for logical_id in sorted(entries):
        document = provenance.build_document(repo, logical_id, entries[logical_id])
        raw = provenance.canonical_bytes(document)
        target = output / f"{logical_id}.provenance.json"
        if write:
            target.write_bytes(raw)
        if not target.is_file() or target.read_bytes() != raw:
            raise ValueError(f"{logical_id}: missing or stale canonical sidecar")
        provenance.validate_schema(document, json.loads(
            (repo / "tools/presentation_qa/provenance_schema_v1.json").read_text(encoding="utf-8")
        ), json.loads(
            (repo / "tools/presentation_qa/provenance_schema_v1.json").read_text(encoding="utf-8")
        ))
        manifest = replace_manifest_hash(manifest, logical_id, sidecar_digest(target))

    if write:
        manifest_path.write_text(manifest, encoding="utf-8")
    elif manifest_path.read_text(encoding="utf-8") != manifest:
        raise ValueError("operator animation manifest provenance hashes are stale")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path("."))
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    run(args.repo.resolve(), args.write)
    print("OPERATOR_ANIMATION_PROVENANCE_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
