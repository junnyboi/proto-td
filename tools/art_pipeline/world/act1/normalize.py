#!/usr/bin/env python3
"""Deterministically normalize the approved shared Act I source packet.

The synthesized role sources are smooth, high-resolution RGBA renders, not pixel
art. They are resized with Pillow LANCZOS while retaining alpha. The approved
16:9 panorama is center-cropped to 2:1 before the same smooth downsampling.
Runtime and staging PNGs are emitted from the same encoded bytes.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Final

from PIL import Image

REPO: Final = Path(__file__).resolve().parents[4]
SOURCE_ROOT: Final = REPO / "art-src/world/act1"
ROLE_ROOT: Final = SOURCE_ROOT / "synthesized-roles"
RUNTIME_ROOT: Final = REPO / "assets/world/act1"
STAGING_ROOT: Final = REPO / "staging/assets/world/act1"
FRAGMENT_ROOT: Final = REPO / "assets/provenance/fragments/act1"
MANIFEST_PATH: Final = REPO / "assets/act1_shared_manifest.tres"
APPROVAL_TOKEN: Final = "ACT-I-S1-S3-SYNTHESIS-V1"
ROLE_SIZES: Final = {
    "ground": (64, 32),
    "route": (64, 32),
    "raised": (64, 48),
    "blocked": (64, 32),
    "spawn": (64, 32),
    "core": (64, 32),
}
PANORAMA_SIZE: Final = (512, 256)


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def _png_bytes(image: Image.Image) -> bytes:
    import io

    stream = io.BytesIO()
    image.save(stream, format="PNG", compress_level=9, optimize=False)
    return stream.getvalue()


def _normalize_role(role: str) -> bytes:
    source = ROLE_ROOT / f"act1-{role}.png"
    with Image.open(source) as opened:
        rgba = opened.convert("RGBA")
        normalized = rgba.resize(ROLE_SIZES[role], Image.Resampling.LANCZOS)
    return _png_bytes(normalized)


def _normalize_panorama() -> bytes:
    source = SOURCE_ROOT / "act1-alpine-panorama-flux-a.jpg"
    with Image.open(source) as opened:
        rgb = opened.convert("RGB")
        crop_height = rgb.width // 2
        if crop_height > rgb.height:
            raise ValueError(f"panorama is narrower than 2:1: {rgb.size}")
        top = (rgb.height - crop_height) // 2
        cropped = rgb.crop((0, top, rgb.width, top + crop_height))
        normalized = cropped.resize(PANORAMA_SIZE, Image.Resampling.LANCZOS)
    return _png_bytes(normalized)


def _clear_generated_files(root: Path, suffix: str) -> None:
    root.mkdir(parents=True, exist_ok=True)
    for path in root.iterdir():
        if path.is_file() and path.name.endswith(suffix):
            path.unlink()


def _write_pair(filename: str, payload: bytes) -> None:
    (RUNTIME_ROOT / filename).write_bytes(payload)
    (STAGING_ROOT / filename).write_bytes(payload)


def _fragment(logical_id: str, filename: str, size: tuple[int, int], payload: bytes, source: Path) -> dict:
    runtime = f"assets/world/act1/{filename}"
    staging = f"staging/assets/world/act1/{filename}"
    return {
        "schema_version": 1,
        "logical_id": logical_id,
        "state": "SYNTHESIS_DIRECTION_APPROVED_RUNTIME_CAPTURE_PENDING",
        "human_final_art": False,
        "approval": {
            "token": APPROVAL_TOKEN,
            "human_final_art": False,
            "scope": "shared Act I world-art direction for S1-S3",
        },
        "source": {
            "path": source.relative_to(REPO).as_posix(),
            "sha256": sha256_file(source),
        },
        "normalization": {
            "tool": "Pillow",
            "resampling": "LANCZOS",
            "target_size": list(size),
            "alpha_preserved": filename != "panorama.png",
            "panorama_center_crop_to_2_1": filename == "panorama.png",
        },
        "candidate_files": {
            "runtime": runtime,
            "staging": staging,
            "sha256": sha256_bytes(payload),
            "bytes_identical": True,
        },
    }


def _manifest_text(records: list[tuple[str, str, tuple[int, int], str]]) -> str:
    lines = [
        '[gd_resource type="Resource" script_class="AssetManifest" load_steps=2 format=3]',
        "",
        '[ext_resource type="Script" path="res://assets/asset_manifest.gd" id="1"]',
        "",
        "[resource]",
        'script = ExtResource("1")',
        "schema_version = 2",
        "entries = {",
    ]
    for index, (logical_id, filename, size, fragment_hash) in enumerate(sorted(records)):
        comma = "," if index + 1 < len(records) else ""
        lines.extend(
            [
                f'&"{logical_id}": {{',
                '"animations": {&"default": {&"fps": 1.0, &"length": 1, &"loop": true, &"start": 0}},',
                '"frames": 1,',
                f'"pattern": "res://assets/world/act1/{filename}",',
                '"pivot": Vector2(0.5, 0.5),',
                '"placeholder": true,',
                f'"provenance_sha256": "{fragment_hash}",',
                f'"size": Vector2i({size[0]}, {size[1]})',
                f'}}{comma}',
            ]
        )
    lines.extend(["}", ""])
    return "\n".join(lines)


def normalize() -> None:
    _clear_generated_files(RUNTIME_ROOT, ".png")
    _clear_generated_files(STAGING_ROOT, ".png")
    _clear_generated_files(FRAGMENT_ROOT, ".json")

    records: list[tuple[str, str, tuple[int, int], bytes, Path]] = []
    for role, size in ROLE_SIZES.items():
        payload = _normalize_role(role)
        filename = f"{role}.png"
        _write_pair(filename, payload)
        records.append((f"world.act1.{role}", filename, size, payload, ROLE_ROOT / f"act1-{role}.png"))

    panorama = _normalize_panorama()
    _write_pair("panorama.png", panorama)
    records.append(("world.act1.panorama", "panorama.png", PANORAMA_SIZE, panorama, SOURCE_ROOT / "act1-alpine-panorama-flux-a.jpg"))

    manifest_records: list[tuple[str, str, tuple[int, int], str]] = []
    for logical_id, filename, size, payload, source in records:
        fragment = _fragment(logical_id, filename, size, payload, source)
        path = FRAGMENT_ROOT / f"{logical_id.replace('.', '_')}.provenance.json"
        path.write_text(json.dumps(fragment, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        manifest_records.append((logical_id, filename, size, sha256_file(path)))

    MANIFEST_PATH.write_text(_manifest_text(manifest_records), encoding="utf-8")

    print(f"ACT1_WORLD_NORMALIZED roles={len(ROLE_SIZES)} panorama=1 token={APPROVAL_TOKEN}")


if __name__ == "__main__":
    normalize()
