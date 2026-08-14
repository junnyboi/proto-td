#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import io
import json
import re
from pathlib import Path
from typing import Any

from PIL import Image

HEROES = ("caster_1", "caster_2", "defender_2", "sniper_1", "sniper_2")
DIRECTIONS = ("se", "ne", "nw", "sw")
STATE_SPECS = {
    "idle": {"source": "idle", "indices": tuple(range(24)), "loop": True},
    "attack": {"source": "attacking", "indices": tuple(range(0, 25, 2)), "loop": False},
}
RUNTIME_CELL = (192, 192)
SOURCE_CELL = (256, 256)
PIVOT = (0.5, 0.94)
FPS = 12.0
DISPLAY_HEIGHT = 64
DEFAULT_PACKAGE = Path("/home/ubuntu/deliverables/aetheria-chibi-sprites-part-2-completed")
SOURCE_MANIFEST_REL = Path("assets/provenance/operators/aetheria-part2-source-manifest.json")
COMPACT_MANIFEST_REL = Path("assets/provenance/operators/operator-animation-v1.json")
ASSET_MANIFEST_REL = Path("assets/manifest.tres")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_path(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def png_bytes(image: Image.Image) -> bytes:
    output = io.BytesIO()
    image.save(output, format="PNG", optimize=False, compress_level=9)
    return output.getvalue()


def hard_alpha(image: Image.Image) -> Image.Image:
    source = image.convert("RGBA")
    output = Image.new("RGBA", source.size, (0, 0, 0, 0))
    src = source.load()
    dst = output.load()
    for y in range(source.height):
        for x in range(source.width):
            red, green, blue, alpha = src[x, y]
            if alpha >= 128:
                dst[x, y] = (red, green, blue, 255)
    return output


def runtime_atlas(source_path: Path, indices: tuple[int, ...]) -> tuple[Image.Image, dict[str, Any]]:
    with Image.open(source_path) as opened:
        source = opened.convert("RGBA")
    if source.size != (SOURCE_CELL[0] * 25, SOURCE_CELL[1]):
        raise ValueError(f"{source_path}: expected 25 cells at 256x256, got {source.size}")
    frames: list[Image.Image] = []
    opaque_counts: list[int] = []
    heights: list[int] = []
    for index in indices:
        frame = source.crop((index * SOURCE_CELL[0], 0, (index + 1) * SOURCE_CELL[0], SOURCE_CELL[1]))
        frame = hard_alpha(frame.resize(RUNTIME_CELL, Image.Resampling.LANCZOS))
        alpha = frame.getchannel("A")
        if sum(alpha.histogram()[1:255]) != 0:
            raise ValueError(f"{source_path}: runtime alpha is not binary")
        bbox = alpha.getbbox()
        if bbox is None:
            raise ValueError(f"{source_path}: frame {index} became empty")
        if bbox[1] == 0 or bbox[3] == RUNTIME_CELL[1]:
            raise ValueError(f"{source_path}: frame {index} occupies a vertical border")
        opaque_counts.append(alpha.histogram()[255])
        heights.append(bbox[3] - bbox[1])
        frames.append(frame)
    atlas = Image.new("RGBA", (RUNTIME_CELL[0] * len(frames), RUNTIME_CELL[1]), (0, 0, 0, 0))
    for frame_index, frame in enumerate(frames):
        atlas.alpha_composite(frame, (frame_index * RUNTIME_CELL[0], 0))
    return atlas, {
        "binary_alpha": True,
        "border_clear": True,
        "frame_count": len(frames),
        "max_opaque_pixels": max(opaque_counts),
        "min_opaque_pixels": min(opaque_counts),
        "median_height_px": sorted(heights)[len(heights) // 2],
        "selected_source_frames": list(indices),
    }


def source_rows(package: Path) -> tuple[dict[tuple[str, str, str], dict[str, Any]], bytes]:
    path = package / "integration/ASSET-MANIFEST.json"
    raw = path.read_bytes()
    document = json.loads(raw)
    if document.get("schema_version") != 1 or document.get("package") != "aetheria-chibi-sprites-part-2":
        raise ValueError("unexpected Part 2 source manifest")
    rows: dict[tuple[str, str, str], dict[str, Any]] = {}
    for row in document.get("assets", []):
        key = (str(row.get("hero")), str(row.get("state")), str(row.get("direction")))
        if key in rows:
            raise ValueError(f"duplicate source row: {key}")
        rows[key] = row
    expected = {
        (hero, source_state, direction)
        for hero in HEROES
        for source_state in ("idle", "attacking")
        for direction in DIRECTIONS
    }
    if set(rows) != expected:
        raise ValueError(f"Part 2 source inventory mismatch: expected {len(expected)}, got {len(rows)}")
    for key, row in rows.items():
        source = package / str(row["path"])
        if not source.is_file() or sha256_path(source) != row.get("sha256"):
            raise ValueError(f"{key}: source missing or hash mismatch")
        if (row.get("frame_width"), row.get("frame_height"), row.get("frame_count")) != (256, 256, 25):
            raise ValueError(f"{key}: source geometry mismatch")
    placeholders = [row for row in rows.values() if bool(row.get("placeholder", False))]
    exact = sorted((row["hero"], row["state"], row["direction"], row.get("placeholder_source_direction")) for row in placeholders)
    if exact:
        raise ValueError(f"unexpected placeholder set: {exact}")
    return rows, raw


def render_manifest_row(logical_id: str, row: dict[str, Any], provenance_digest: str) -> str:
    state = row["state"]
    loop = "true" if row["loop"] else "false"
    placeholder = "true" if row["placeholder"] else "false"
    return (
        f'&"{logical_id}": {{\n'
        '"animations": {\n'
        f'&"{state}": {{\n'
        f'&"fps": {FPS:.1f},\n'
        f'&"length": {row["frame_count"]},\n'
        f'&"loop": {loop},\n'
        '&"start": 0\n'
        '}\n'
        '},\n'
        f'"frames": {row["frame_count"]},\n'
        f'"pattern": "{row["path"]}",\n'
        f'"pivot": Vector2({PIVOT[0]}, {PIVOT[1]}),\n'
        f'"placeholder": {placeholder},\n'
        f'"provenance_sha256": "{provenance_digest}",\n'
        f'"size": Vector2i({RUNTIME_CELL[0]}, {RUNTIME_CELL[1]})\n'
        '},'
    )


def existing_provenance_hashes(manifest: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for hero in HEROES:
        for state in STATE_SPECS:
            for direction in DIRECTIONS:
                logical_id = f"op_anim_{hero}_{state}_{direction}"
                pattern = re.compile(
                    rf'&"{re.escape(logical_id)}": \{{.*?"provenance_sha256": "([0-9a-f]{{64}})"',
                    re.DOTALL,
                )
                match = pattern.search(manifest)
                if match:
                    result[logical_id] = match.group(1)
    return result


def manifest_entry_span(document: str, logical_id: str) -> tuple[int, int] | None:
    marker = f'\n&"{logical_id}": {{'
    start = document.find(marker)
    if start < 0:
        return None
    brace_start = document.find("{", start + 1)
    depth = 0
    in_string = False
    escaped = False
    for index in range(brace_start, len(document)):
        char = document[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                end = index + 1
                if end < len(document) and document[end] == ",":
                    end += 1
                return start, end
    raise ValueError(f"{logical_id}: unterminated manifest row")


def compile_asset_manifest(current: str, rows: dict[str, dict[str, Any]]) -> str:
    target_ids = sorted(rows)
    hashes = existing_provenance_hashes(current)
    starts: list[tuple[int, int]] = []
    for logical_id in target_ids:
        span = manifest_entry_span(current, logical_id)
        if span is not None:
            starts.append(span)
    for start, end in sorted(starts, reverse=True):
        current = current[:start] + current[end:]
    block_rows = [
        render_manifest_row(logical_id, rows[logical_id], hashes.get(logical_id, "0" * 64))
        for logical_id in target_ids
    ]
    anchor = current.find('\n&"op_anim_')
    if anchor < 0:
        anchor = current.rfind("\n}")
    if anchor < 0:
        raise ValueError("asset manifest entries block not found")
    return current[:anchor] + "\n" + "\n".join(block_rows) + current[anchor:]


def build_compact_document(
    current: dict[str, Any],
    runtime_rows: dict[str, dict[str, Any]],
    source_manifest_sha: str,
) -> dict[str, Any]:
    by_hero: dict[str, dict[str, Any]] = {}
    for hero in HEROES:
        families: dict[str, Any] = {}
        state_heights: dict[str, list[int]] = {}
        for state in STATE_SPECS:
            families[state] = {}
            state_heights[state] = []
            for direction in DIRECTIONS:
                logical_id = f"op_anim_{hero}_{state}_{direction}"
                row = runtime_rows[logical_id]
                families[state][direction] = {
                    "asset_id": f"operator_anim_{hero}_{state}_{direction}",
                    "binary_alpha": True,
                    "border_clear": True,
                    "frame_count": row["frame_count"],
                    "max_opaque_pixels": row["max_opaque_pixels"],
                    "min_opaque_pixels": row["min_opaque_pixels"],
                    "path": row["path"],
                    "placeholder": row["placeholder"],
                    "placeholder_source_direction": row["placeholder_source_direction"],
                    "rgba_sha256": row["rgba_sha256"],
                    "selected_source_frames": row["selected_source_frames"],
                    "sha256": row["sha256"],
                    "source_sha256": row["source_sha256"],
                }
                state_heights[state].append(row["median_height_px"])
        by_hero[hero] = {
            "display_height_px": DISPLAY_HEIGHT,
            "families": families,
            "normalization_scale": 0.75,
            "normalized_subject_height_px": 158,
            "source_manifest_sha256": source_manifest_sha,
            "state_geometry": {
                state: {"median_height_px": sorted(values)[len(values) // 2]}
                for state, values in state_heights.items()
            },
            "template_id": hero,
        }
    existing = {
        str(row.get("template_id")): row
        for row in current.get("classes", [])
        if isinstance(row, dict) and str(row.get("template_id")) not in HEROES
    }
    existing.update(by_hero)
    current["classes"] = [existing[key] for key in sorted(existing)]
    acceptance = current.setdefault("acceptance", {})
    admitted = sorted(set(acceptance.get("accepted_classes", [])) | set(HEROES))
    acceptance["accepted_classes"] = admitted
    acceptance["blocked_classes_use_legacy_fallback"] = sorted(
        set(("vanguard_1", "vanguard_2", "guard_1", "guard_2", "defender_1", "defender_2", "sniper_1", "sniper_2", "caster_1", "caster_2")) - set(admitted)
    )
    acceptance["status"] = "part2_runtime_integrated_all_native"
    current["known_placeholders"] = []
    current["source_packages"] = [
        {
            "name": "aetheria-chibi-sprites-part-2",
            "manifest": f"res://{SOURCE_MANIFEST_REL.as_posix()}",
            "manifest_sha256": source_manifest_sha,
        }
    ]
    current["pivot"] = [PIVOT[0], PIVOT[1]]
    return current


def build(repo: Path, package: Path) -> tuple[dict[Path, bytes], str, bytes]:
    source_inventory, source_manifest_raw = source_rows(package)
    source_manifest_sha = sha256_bytes(source_manifest_raw)
    outputs: dict[Path, bytes] = {repo / SOURCE_MANIFEST_REL: source_manifest_raw}
    runtime_rows: dict[str, dict[str, Any]] = {}
    for hero in HEROES:
        for state, spec in STATE_SPECS.items():
            source_state = str(spec["source"])
            indices = tuple(spec["indices"])
            for direction in DIRECTIONS:
                source_row = source_inventory[(hero, source_state, direction)]
                source_path = package / str(source_row["path"])
                atlas, metrics = runtime_atlas(source_path, indices)
                raw = png_bytes(atlas)
                output_rel = Path(f"assets/sprites/operators/animated/{hero}/{state}_{direction}.png")
                outputs[repo / output_rel] = raw
                logical_id = f"op_anim_{hero}_{state}_{direction}"
                runtime_rows[logical_id] = {
                    **metrics,
                    "state": state,
                    "direction": direction,
                    "frame_count": len(indices),
                    "loop": bool(spec["loop"]),
                    "path": f"res://{output_rel.as_posix()}",
                    "placeholder": bool(source_row.get("placeholder", False)),
                    "placeholder_source_direction": source_row.get("placeholder_source_direction"),
                    "rgba_sha256": sha256_bytes(atlas.tobytes()),
                    "sha256": sha256_bytes(raw),
                    "source_sha256": str(source_row["sha256"]),
                    "selected_source_frames": list(indices),
                }
    compact_path = repo / COMPACT_MANIFEST_REL
    compact = json.loads(compact_path.read_text(encoding="utf-8"))
    compact = build_compact_document(compact, runtime_rows, source_manifest_sha)
    outputs[compact_path] = (json.dumps(compact, indent=2, sort_keys=True) + "\n").encode("utf-8")
    manifest_path = repo / ASSET_MANIFEST_REL
    manifest = compile_asset_manifest(manifest_path.read_text(encoding="utf-8"), runtime_rows)
    return outputs, manifest, source_manifest_raw


def run(repo: Path, package: Path, check: bool) -> None:
    outputs, manifest, _ = build(repo, package)
    mismatches: list[str] = []
    for path, raw in outputs.items():
        if check:
            if not path.is_file() or path.read_bytes() != raw:
                mismatches.append(str(path.relative_to(repo)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(raw)
    manifest_path = repo / ASSET_MANIFEST_REL
    if check:
        if manifest_path.read_text(encoding="utf-8") != manifest:
            mismatches.append(str(ASSET_MANIFEST_REL))
    else:
        manifest_path.write_text(manifest, encoding="utf-8")
    if mismatches:
        raise ValueError(f"Part 2 runtime outputs are missing or stale: {sorted(mismatches)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path("."))
    parser.add_argument("--package", type=Path, default=DEFAULT_PACKAGE)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    run(args.repo.resolve(), args.package.resolve(), args.check)
    print("AETHERIA_PART2_IMPORT_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
