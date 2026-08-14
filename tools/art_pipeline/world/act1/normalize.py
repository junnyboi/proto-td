#!/usr/bin/env python3
"""Normalize owner-supplied shared Act I world art deterministically.

The three supplied tile images are authoritative. Their visible isometric
objects are isolated from black/magenta editor residue, cropped, and fitted to
the exact runtime geometry requested by the owner: 64x32 flat faces and a
64x48 raised face plus wall. The blocked role is a contrast transform of the
supplied ground. Endpoint seals remain sparse overlays over their ground cells.
"""

from __future__ import annotations

import hashlib
import io
import json
from pathlib import Path
from typing import Final

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

REPO: Final = Path(__file__).resolve().parents[4]
SOURCE_ROOT: Final = REPO / "art-src/world/act1"
OWNER_TILE_ROOT: Final = SOURCE_ROOT / "owner-tiles"
MARKER_ROOT: Final = SOURCE_ROOT / "endpoint-markers"
RUNTIME_ROOT: Final = REPO / "assets/world/act1"
STAGING_ROOT: Final = REPO / "staging/assets/world/act1"
FRAGMENT_ROOT: Final = REPO / "assets/provenance/fragments/act1"
MANIFEST_PATH: Final = REPO / "assets/act1_shared_manifest.tres"
APPROVAL_TOKEN: Final = "ACT-I-S1-S3-OWNER-TILES-V2"
ROLE_SIZES: Final = {
    "ground": (64, 32),
    "route": (64, 32),
    "raised": (64, 48),
    "blocked": (64, 32),
    "spawn": (64, 32),
    "core": (64, 32),
}
OWNER_SOURCES: Final = {
    "ground": OWNER_TILE_ROOT / "ground-source.png",
    "route": OWNER_TILE_ROOT / "route-source.png",
    "raised": OWNER_TILE_ROOT / "elevated-source.png",
}
MARKER_SOURCES: Final = {
    "spawn": MARKER_ROOT / "spawn-marker-source.png",
    "core": MARKER_ROOT / "core-marker-source.png",
}
PANORAMA_SIZE: Final = (512, 256)
PANORAMA_SOURCE: Final = SOURCE_ROOT / "s1-alpine-escarpment-panorama-source.png"


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def _png_bytes(image: Image.Image) -> bytes:
    stream = io.BytesIO()
    image.save(stream, format="PNG", compress_level=9, optimize=False)
    return stream.getvalue()


def _threshold(channel: Image.Image, low: int, high: int = 255) -> Image.Image:
    return channel.point(lambda value: 255 if low <= value <= high else 0)


def _remove_magenta_fringe(image: Image.Image) -> Image.Image:
    cleaned = image.copy()
    pixels = cleaned.load()
    for y in range(cleaned.height):
        for x in range(cleaned.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha < 16 or (red - green > 25 and blue - green > 25):
                pixels[x, y] = (red, green, blue, 0)
    return cleaned


def _owner_object(source: Path, target_size: tuple[int, int]) -> Image.Image:
    with Image.open(source) as opened:
        rgba = opened.convert("RGBA")
    red, green, blue, source_alpha = rgba.split()
    brightest = ImageChops.lighter(red, ImageChops.lighter(green, blue))
    dark = brightest.point(lambda value: 255 if value < 28 else 0)
    magenta = ImageChops.multiply(
        ImageChops.multiply(_threshold(red, 80), _threshold(blue, 80)),
        _threshold(green, 0, 110),
    )
    background = ImageChops.lighter(dark, magenta)
    connectivity = ImageChops.invert(background)
    for x in range(connectivity.width):
        if connectivity.getpixel((x, 0)) == 0:
            ImageDraw.floodfill(connectivity, (x, 0), 128, thresh=0)
        if connectivity.getpixel((x, connectivity.height - 1)) == 0:
            ImageDraw.floodfill(connectivity, (x, connectivity.height - 1), 128, thresh=0)
    for y in range(connectivity.height):
        if connectivity.getpixel((0, y)) == 0:
            ImageDraw.floodfill(connectivity, (0, y), 128, thresh=0)
        if connectivity.getpixel((connectivity.width - 1, y)) == 0:
            ImageDraw.floodfill(connectivity, (connectivity.width - 1, y), 128, thresh=0)
    exterior = connectivity.point(lambda value: 255 if value == 128 else 0)
    rgba.putalpha(ImageChops.multiply(source_alpha, ImageChops.invert(exterior)))
    bbox = rgba.getbbox()
    if bbox is None:
        raise ValueError(f"owner tile has no visible object: {source}")
    if bbox == (0, 0, rgba.width, rgba.height):
        raise ValueError(f"owner tile canvas residue was not isolated: {source}")
    fitted = rgba.crop(bbox).resize(target_size, Image.Resampling.LANCZOS)
    return _remove_magenta_fringe(fitted)


def _blocked_from_ground(ground: Image.Image) -> Image.Image:
    alpha = ground.getchannel("A")
    muted = ImageEnhance.Color(ground.convert("RGB")).enhance(0.18)
    muted = ImageEnhance.Brightness(muted).enhance(0.58)
    result = muted.convert("RGBA")
    result.putalpha(alpha)
    return result


def _endpoint_overlay(role: str) -> Image.Image:
    with Image.open(MARKER_SOURCES[role]) as opened:
        rgba = opened.convert("RGBA").resize(ROLE_SIZES[role], Image.Resampling.LANCZOS)
    red, green, blue, source_alpha = rgba.split()
    if role == "spawn":
        seed = ImageChops.multiply(
            _threshold(red, 130),
            ImageChops.multiply(
                ImageChops.subtract(red, green).point(lambda value: 255 if value > 35 else 0),
                ImageChops.subtract(red, blue).point(lambda value: 255 if value > 18 else 0),
            ),
        )
    else:
        seed = ImageChops.multiply(
            _threshold(blue, 140),
            ImageChops.multiply(
                _threshold(green, 120),
                ImageChops.multiply(
                    ImageChops.subtract(blue, red).point(lambda value: 255 if value > 45 else 0),
                    ImageChops.subtract(green, red).point(lambda value: 255 if value > 20 else 0),
                ),
            ),
        )
    rgba.putalpha(ImageChops.multiply(source_alpha, seed.filter(ImageFilter.MaxFilter(3))))
    return rgba


def _normalize_panorama() -> bytes:
    with Image.open(PANORAMA_SOURCE) as opened:
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


def _fragment(
    logical_id: str,
    filename: str,
    size: tuple[int, int],
    payload: bytes,
    source: Path,
    operation: str,
) -> dict:
    runtime = f"assets/world/act1/{filename}"
    staging = f"staging/assets/world/act1/{filename}"
    return {
        "schema_version": 1,
        "logical_id": logical_id,
        "state": "OWNER_TILE_DIRECTION_APPROVED_RUNTIME_CAPTURE_PENDING",
        "human_final_art": False,
        "approval": {
            "token": APPROVAL_TOKEN,
            "human_final_art": False,
            "scope": "owner-supplied shared Act I tiles for S1-S3",
        },
        "source": {
            "path": source.relative_to(REPO).as_posix(),
            "sha256": sha256_file(source),
        },
        "normalization": {
            "tool": "Pillow",
            "operation": operation,
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

    ground = _owner_object(OWNER_SOURCES["ground"], ROLE_SIZES["ground"])
    role_images = {
        "ground": ground,
        "route": _owner_object(OWNER_SOURCES["route"], ROLE_SIZES["route"]),
        "raised": _owner_object(OWNER_SOURCES["raised"], ROLE_SIZES["raised"]),
        "blocked": _blocked_from_ground(ground),
        "spawn": _endpoint_overlay("spawn"),
        "core": _endpoint_overlay("core"),
    }
    role_sources = {
        "ground": (OWNER_SOURCES["ground"], "canvas strip + crop + fit to 2:1 face"),
        "route": (OWNER_SOURCES["route"], "canvas strip + crop + fit to 2:1 face"),
        "raised": (OWNER_SOURCES["raised"], "canvas strip + crop + fit to 64x48 raised face"),
        "blocked": (OWNER_SOURCES["ground"], "ground face contrast transform"),
        "spawn": (MARKER_SOURCES["spawn"], "transparent endpoint marker extraction"),
        "core": (MARKER_SOURCES["core"], "transparent endpoint marker extraction"),
    }
    records: list[tuple[str, str, tuple[int, int], bytes, Path, str]] = []
    for role, size in ROLE_SIZES.items():
        payload = _png_bytes(role_images[role])
        filename = f"{role}.png"
        _write_pair(filename, payload)
        source, operation = role_sources[role]
        records.append((f"world.act1.{role}", filename, size, payload, source, operation))

    panorama = _normalize_panorama()
    _write_pair("panorama.png", panorama)
    records.append(
        (
            "world.act1.panorama",
            "panorama.png",
            PANORAMA_SIZE,
            panorama,
            PANORAMA_SOURCE,
            "center crop to 2:1 panorama",
        )
    )

    manifest_records: list[tuple[str, str, tuple[int, int], str]] = []
    for logical_id, filename, size, payload, source, operation in records:
        fragment = _fragment(logical_id, filename, size, payload, source, operation)
        path = FRAGMENT_ROOT / f"{logical_id.replace('.', '_')}.provenance.json"
        path.write_text(json.dumps(fragment, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        manifest_records.append((logical_id, filename, size, sha256_file(path)))

    MANIFEST_PATH.write_text(_manifest_text(manifest_records), encoding="utf-8")
    print(f"ACT1_WORLD_NORMALIZED roles={len(ROLE_SIZES)} panorama=1 token={APPROVAL_TOKEN}")


if __name__ == "__main__":
    normalize()
