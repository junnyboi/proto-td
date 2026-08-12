from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Any

BASELINE_COMMIT = "975261e8e00a20a0b25fe17e7976d743d509c14b"
BASELINE_TREE = "cf4b3e1c0d8ae826c668765d994a032acbb8c0ad"
GODOT_VERSION = "4.7.1.stable.official.a13da4feb"
COMMON_SOURCES = {
    "res://tools/gen_assets.gd",
    "res://assets/asset_manifest.gd",
    "res://tools/pixel/pix.gd",
    "res://tools/pixel/palette.gd",
}


def validate_schema(value: Any, schema: dict[str, Any], root: dict[str, Any], path: str = "$") -> None:
    if "$ref" in schema:
        reference = schema["$ref"]
        if not isinstance(reference, str) or not reference.startswith("#/"):
            raise ValueError(f"unsupported schema reference at {path}: {reference}")
        resolved: Any = root
        for part in reference.removeprefix("#/").split("/"):
            resolved = resolved[part]
        validate_schema(value, resolved, root, path)
        return
    if "const" in schema and value != schema["const"]:
        raise ValueError(f"schema const mismatch at {path}")
    expected_type = schema.get("type")
    type_ok = {
        "object": isinstance(value, dict),
        "array": isinstance(value, list),
        "string": isinstance(value, str),
        "integer": isinstance(value, int) and not isinstance(value, bool),
        "null": value is None,
    }.get(expected_type, True)
    if not type_ok:
        raise ValueError(f"schema type mismatch at {path}: expected {expected_type}")
    if isinstance(value, dict):
        required = schema.get("required", [])
        missing = set(required) - set(value)
        if missing:
            raise ValueError(f"schema missing keys at {path}: {sorted(missing)}")
        properties = schema.get("properties", {})
        if schema.get("additionalProperties") is False:
            extra = set(value) - set(properties)
            if extra:
                raise ValueError(f"schema extra keys at {path}: {sorted(extra)}")
        for key, child in value.items():
            if key in properties:
                validate_schema(child, properties[key], root, f"{path}.{key}")
    if isinstance(value, list):
        if len(value) < int(schema.get("minItems", 0)):
            raise ValueError(f"schema minItems mismatch at {path}")
        if "items" in schema:
            for index, child in enumerate(value):
                validate_schema(child, schema["items"], root, f"{path}[{index}]")
    if isinstance(value, str):
        if len(value) < int(schema.get("minLength", 0)):
            raise ValueError(f"schema minLength mismatch at {path}")
        if "pattern" in schema and re.search(schema["pattern"], value) is None:
            raise ValueError(f"schema pattern mismatch at {path}")
    if isinstance(value, int) and not isinstance(value, bool) and "minimum" in schema:
        if value < int(schema["minimum"]):
            raise ValueError(f"schema minimum mismatch at {path}")


def canonical_bytes(document: dict[str, Any]) -> bytes:
    return (json.dumps(document, sort_keys=True, separators=(",", ":"), ensure_ascii=True) + "\n").encode("utf-8")


def disk_path(repo: Path, resource_path: str) -> Path:
    if not resource_path.startswith("res://"):
        raise ValueError(f"not a res path: {resource_path}")
    path = (repo / resource_path.removeprefix("res://")).resolve()
    if repo.resolve() not in path.parents:
        raise ValueError(f"path escapes repository: {resource_path}")
    return path


def digest_row(repo: Path, resource_path: str) -> dict[str, Any]:
    path = disk_path(repo, resource_path)
    if not path.is_file():
        raise FileNotFoundError(resource_path)
    data = path.read_bytes()
    return {"path": resource_path, "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)}


def source_paths(logical_id: str) -> list[str]:
    result = set(COMMON_SOURCES)
    if logical_id.startswith("tile_"):
        result.add("res://tools/pixel/art_tiles.gd")
    elif logical_id.startswith("portrait_"):
        operator_id = logical_id.removeprefix("portrait_")
        result.update(
            {
                "res://tools/pixel/art_operators.gd",
                "res://tools/pixel/art_portraits.gd",
                "res://data/operator_def.gd",
                f"res://data/operators/{operator_id}.tres",
            }
        )
    elif logical_id.startswith("trap_") or logical_id.startswith("icon_"):
        result.add("res://tools/pixel/art_props.gd")
    elif logical_id in {
        "caster_1", "caster_2", "defender_1", "defender_2", "guard_1", "guard_2",
        "sniper_1", "sniper_2", "vanguard_1", "vanguard_2",
    }:
        result.update(
            {
                "res://tools/pixel/art_operators.gd",
                "res://data/operator_def.gd",
                f"res://data/operators/{logical_id}.tres",
            }
        )
    else:
        base_id = logical_id.removesuffix("_charmed")
        result.update(
            {
                "res://tools/pixel/art_enemies.gd",
                "res://data/enemy_def.gd",
                f"res://data/enemies/{base_id}.tres",
            }
        )
    return sorted(result)


def final_paths(entry: dict[str, Any]) -> list[str]:
    pattern = entry["pattern"]
    frames = entry["frames"]
    if not isinstance(pattern, str) or not pattern.startswith("res://"):
        raise ValueError("invalid pattern")
    if not isinstance(frames, int) or isinstance(frames, bool) or frames < 1:
        raise ValueError("invalid frames")
    if frames == 1:
        return [pattern]
    if pattern.count("%d") != 1:
        raise ValueError(f"multi-frame pattern lacks one %d: {pattern}")
    return [pattern % index for index in range(frames)]


def build_document(repo: Path, logical_id: str, entry: dict[str, Any]) -> dict[str, Any]:
    generator = digest_row(repo, "res://tools/gen_assets.gd")
    return {
        "schema_version": 1,
        "logical_id": logical_id,
        "source_type": "deterministic_project_generator",
        "final_files": [digest_row(repo, path) for path in sorted(final_paths(entry))],
        "source_files": [digest_row(repo, path) for path in source_paths(logical_id)],
        "recipe": {
            "command": "godot --headless --path . -s tools/gen_assets.gd",
            "godot_version": GODOT_VERSION,
            "generator_path": "res://tools/gen_assets.gd",
            "generator_sha256": generator["sha256"],
        },
        "generation": {
            "provider": None,
            "model": None,
            "generation_id": None,
            "seed": None,
            "unsupported_reason": "deterministic hand-authored project generator; stochastic provider fields do not apply",
        },
        "migration": {
            "baseline_commit": BASELINE_COMMIT,
            "baseline_tree": BASELINE_TREE,
            "migrated_at_utc": None,
            "status": "current_bytes_authenticated",
        },
        "acceptance": {
            "state": "unknown_per_current_byte",
            "human_accepter": None,
            "accepted_at_utc": None,
            "accepting_commit": None,
            "source": "FEATURES.json:LA records family-level Lane A acceptance at c8ee84d and 218aaea but does not prove every current byte",
            "reason": "current inventory includes later additions or modifications, so no immutable per-asset human acceptance fact was inferred",
        },
        "license": {
            "spdx": "LicenseRef-Project-Owned",
            "source": "hand-authored deterministic pixel recipes in repository",
            "human_contribution": "selection, pixel recipes, palette, normalization, and accepted Lane A arrangement",
        },
    }


def validate_document(repo: Path, document: dict[str, Any], logical_id: str, entry: dict[str, Any]) -> None:
    expected = build_document(repo, logical_id, entry)
    if document != expected:
        raise ValueError(f"noncanonical or stale provenance: {logical_id}")
    if canonical_bytes(document) != canonical_bytes(expected):
        raise ValueError(f"canonical serialization mismatch: {logical_id}")
    final_paths_seen = [row["path"] for row in document["final_files"]]
    source_paths_seen = [row["path"] for row in document["source_files"]]
    if final_paths_seen != sorted(set(final_paths_seen)):
        raise ValueError(f"duplicate/unsorted final files: {logical_id}")
    if source_paths_seen != source_paths(logical_id):
        raise ValueError(f"source closure mismatch: {logical_id}")


def load_inventory(path: Path) -> dict[str, dict[str, Any]]:
    parsed = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(parsed, dict) or set(parsed) != {"entries"} or not isinstance(parsed["entries"], dict):
        raise ValueError("inventory must contain only entries")
    return parsed["entries"]


def run(repo: Path, inventory_path: Path, write: bool) -> None:
    entries = load_inventory(inventory_path)
    schema = json.loads((repo / "tools/presentation_qa/provenance_schema_v1.json").read_text(encoding="utf-8"))
    output = repo / "assets/provenance"
    output.mkdir(parents=True, exist_ok=True)
    expected_names = {f"{logical_id}.provenance.json" for logical_id in entries}
    existing_names = {path.name for path in output.glob("*.provenance.json")}
    extras = existing_names - expected_names
    if extras:
        raise ValueError(f"unexpected provenance sidecars: {sorted(extras)}")
    for logical_id in sorted(entries):
        entry = entries[logical_id]
        document = build_document(repo, logical_id, entry)
        target = output / f"{logical_id}.provenance.json"
        if write:
            target.write_bytes(canonical_bytes(document))
        if not target.is_file():
            raise FileNotFoundError(target)
        raw = target.read_bytes()
        if not raw.endswith(b"\n") or raw.count(b"\n") != 1:
            raise ValueError(f"noncanonical newline/whitespace: {logical_id}")
        parsed = json.loads(raw)
        validate_schema(parsed, schema, schema)
        validate_document(repo, parsed, logical_id, entry)
        if raw != canonical_bytes(parsed):
            raise ValueError(f"noncanonical bytes: {logical_id}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--inventory", type=Path, required=True)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    run(args.repo.resolve(), args.inventory.resolve(), args.write)
    print("AUI00_PROVENANCE_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
