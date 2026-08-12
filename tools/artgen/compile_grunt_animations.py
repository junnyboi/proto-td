#!/usr/bin/env python3
"""Compile validated grunt source sheets into Godot-ready TD32 atlases."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Iterable

import numpy as np
from PIL import Image, ImageOps

FRAME_SIZE = 256
FRAME_COUNT = 25
SHEET_SIZE = (FRAME_SIZE * FRAME_COUNT, FRAME_SIZE)
STATES = ("walk", "attack")
DIRECTIONS = ("se", "sw", "ne", "nw")
CORE_MIRRORS = (("se", "sw"), ("ne", "nw"))

PALETTE_HEX = (
    "1a1c2c", "5d275d", "b13e53", "ef7d57", "ffcd75", "a7f070", "38b764", "257179",
    "29366f", "3b5dc9", "41a6f6", "73eff7", "f4f4f4", "94b0c2", "566c86", "333c57",
    "0f0f1b", "c7d6e8", "6e7a94", "1a5f43", "7a2436", "ffe9b0", "a3702b", "6b4a34",
    "3a2a24", "8a4836", "c77b58", "e8b796", "f6dcbf", "c964cf", "94216a", "e39aac",
)
WHITE = "f4f4f4"
SKY = "41a6f6"
VOID = "0f0f1b"
CYAN = "73eff7"
ROSE = "e39aac"
CHARM_RAMP = ("29366f", "3b5dc9", SKY, CYAN)


def rgb(hex_value: str) -> tuple[int, int, int]:
    return tuple(int(hex_value[index : index + 2], 16) for index in (0, 2, 4))


BASE_HEX = tuple(value for value in PALETTE_HEX if value not in (WHITE, SKY))
BASE_RGB = np.asarray([rgb(value) for value in BASE_HEX], dtype=np.int32)
HEX_TO_RGB = {value: rgb(value) for value in PALETTE_HEX}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def frame(sheet: Image.Image, index: int) -> Image.Image:
    return sheet.crop((index * FRAME_SIZE, 0, (index + 1) * FRAME_SIZE, FRAME_SIZE)).convert("RGBA")


def validate_source(path: Path) -> Image.Image:
    with Image.open(path) as opened:
        sheet = opened.convert("RGBA")
    if sheet.size != SHEET_SIZE:
        raise RuntimeError(f"{path}: {sheet.size} != {SHEET_SIZE}")
    for index in range(FRAME_COUNT):
        alpha = frame(sheet, index).getchannel("A")
        bbox = alpha.getbbox()
        if bbox is None:
            raise RuntimeError(f"{path}: empty frame {index}")
        if bbox[0] < 2 or bbox[1] < 2 or bbox[2] > FRAME_SIZE - 2 or bbox[3] > FRAME_SIZE - 2:
            raise RuntimeError(f"{path}: unsafe frame {index} bbox {bbox}")
    if not np.array_equal(np.asarray(frame(sheet, 0)), np.asarray(frame(sheet, FRAME_COUNT - 1))):
        raise RuntimeError(f"{path}: nonzero loop seam")
    return sheet


def nearest_base_rgba(source: Image.Image) -> Image.Image:
    array = np.asarray(source.convert("RGBA"), dtype=np.uint8)
    alpha = np.where(array[..., 3] >= 128, 255, 0).astype(np.uint8)
    opaque = alpha == 255
    output = np.zeros_like(array)
    if np.any(opaque):
        colors = array[..., :3][opaque].astype(np.int32)
        distances = ((colors[:, None, :] - BASE_RGB[None, :, :]) ** 2).sum(axis=2)
        output[..., :3][opaque] = BASE_RGB[np.argmin(distances, axis=1)].astype(np.uint8)
    output[..., 3] = alpha
    return Image.fromarray(output, "RGBA")


def stamp_heart(array: np.ndarray, at_x: int, at_y: int, scale: int = 4) -> None:
    pattern = ((0, 0), (2, 0), (0, 1), (1, 1), (2, 1), (1, 2))
    color = np.asarray((*HEX_TO_RGB[ROSE], 255), dtype=np.uint8)
    for px, py in pattern:
        x0 = at_x + px * scale
        y0 = at_y + py * scale
        x1 = min(array.shape[1], x0 + scale)
        y1 = min(array.shape[0], y0 + scale)
        if x0 >= 0 and y0 >= 0 and x1 > x0 and y1 > y0:
            array[y0:y1, x0:x1] = color


def charm_frame(base: Image.Image) -> Image.Image:
    array = np.asarray(base.convert("RGBA"), dtype=np.uint8).copy()
    opaque = array[..., 3] == 255
    if not np.any(opaque):
        raise RuntimeError("Cannot charm an empty frame")
    void_rgb = np.asarray(HEX_TO_RGB[VOID], dtype=np.uint8)
    outline = opaque & np.all(array[..., :3] == void_rgb, axis=2)
    body = opaque & ~outline
    array[..., :3][outline] = np.asarray(HEX_TO_RGB[CYAN], dtype=np.uint8)
    if np.any(body):
        body_rgb = array[..., :3][body].astype(np.float32) / 255.0
        luminance = body_rgb @ np.asarray([0.2126, 0.7152, 0.0722], dtype=np.float32)
        buckets = np.select(
            (luminance < 0.18, luminance < 0.38, luminance < 0.62),
            (0, 1, 2),
            default=3,
        )
        ramp = np.asarray([HEX_TO_RGB[value] for value in CHARM_RAMP], dtype=np.uint8)
        array[..., :3][body] = ramp[buckets]
    ys, xs = np.nonzero(opaque)
    top = int(ys.min())
    mid = int(round((int(xs.min()) + int(xs.max())) * 0.5))
    stamp_heart(array, mid - 22, max(2, top - 10))
    stamp_heart(array, mid + 8, max(2, top - 16))
    return Image.fromarray(array, "RGBA")


def map_sheet(sheet: Image.Image, transform) -> Image.Image:
    output = Image.new("RGBA", SHEET_SIZE, (0, 0, 0, 0))
    for index in range(FRAME_COUNT):
        output.alpha_composite(transform(frame(sheet, index)), (index * FRAME_SIZE, 0))
    return output


def mirror_sheet_cells(sheet: Image.Image) -> Image.Image:
    return map_sheet(sheet, ImageOps.mirror)


def opaque_colors(sheet: Image.Image) -> set[str]:
    array = np.asarray(sheet.convert("RGBA"), dtype=np.uint8)
    values = np.unique(array[array[..., 3] == 255, :3], axis=0)
    return {"%02x%02x%02x" % tuple(int(channel) for channel in value) for value in values}


def assert_mirror(source: Image.Image, target: Image.Image, label: str) -> None:
    for index in range(FRAME_COUNT):
        expected = np.asarray(ImageOps.mirror(frame(source, index)))
        actual = np.asarray(frame(target, index))
        if not np.array_equal(expected, actual):
            raise RuntimeError(f"{label}: mirror mismatch at frame {index}")


def assert_output(sheet: Image.Image, label: str, charmed: bool) -> None:
    if sheet.size != SHEET_SIZE:
        raise RuntimeError(f"{label}: bad sheet size {sheet.size}")
    array = np.asarray(sheet.convert("RGBA"), dtype=np.uint8)
    if not set(np.unique(array[..., 3])).issubset({0, 255}):
        raise RuntimeError(f"{label}: soft alpha")
    colors = opaque_colors(sheet)
    allowed = set(PALETTE_HEX) - {WHITE}
    if not charmed:
        allowed.discard(SKY)
    extra = colors - allowed
    if extra:
        raise RuntimeError(f"{label}: off-palette {sorted(extra)}")
    if WHITE in colors or (not charmed and SKY in colors):
        raise RuntimeError(f"{label}: reserved-color violation")
    if charmed and SKY not in colors:
        raise RuntimeError(f"{label}: charmed SKY signal absent")
    if not np.array_equal(np.asarray(frame(sheet, 0)), np.asarray(frame(sheet, FRAME_COUNT - 1))):
        raise RuntimeError(f"{label}: nonzero output loop seam")
    for index in range(FRAME_COUNT):
        if frame(sheet, index).getchannel("A").getbbox() is None:
            raise RuntimeError(f"{label}: empty frame {index}")


def save(sheet: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path, optimize=True)


def iter_keys() -> Iterable[tuple[str, str]]:
    for state in STATES:
        for direction in DIRECTIONS:
            yield state, direction


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--output-dir", default=Path("assets/sprites"), type=Path)
    parser.add_argument(
        "--provenance", default=Path("assets/sprites/grunt_animation.provenance.json"), type=Path
    )
    args = parser.parse_args()
    input_dir = args.input_dir.resolve()
    output_dir = args.output_dir.resolve()
    provenance_path = args.provenance.resolve()

    sources: dict[tuple[str, str], Image.Image] = {}
    source_paths: dict[tuple[str, str], Path] = {}
    for state, direction in iter_keys():
        path = input_dir / f"chibi_grunt_{state}_{direction}.png"
        source_paths[(state, direction)] = path
        sources[(state, direction)] = validate_source(path)
    for state in STATES:
        for source_direction, target_direction in CORE_MIRRORS:
            assert_mirror(
                sources[(state, source_direction)],
                sources[(state, target_direction)],
                f"source {state} {source_direction}->{target_direction}",
            )

    base: dict[tuple[str, str], Image.Image] = {}
    charmed: dict[tuple[str, str], Image.Image] = {}
    outputs: dict[str, dict[str, object]] = {}
    for state, direction in iter_keys():
        base[(state, direction)] = map_sheet(sources[(state, direction)], nearest_base_rgba)
    for state in STATES:
        for core in ("se", "ne"):
            charmed[(state, core)] = map_sheet(base[(state, core)], charm_frame)
        charmed[(state, "sw")] = mirror_sheet_cells(charmed[(state, "se")])
        charmed[(state, "nw")] = mirror_sheet_cells(charmed[(state, "ne")])

    for state in STATES:
        for source_direction, target_direction in CORE_MIRRORS:
            assert_mirror(
                base[(state, source_direction)],
                base[(state, target_direction)],
                f"base {state} {source_direction}->{target_direction}",
            )
            assert_mirror(
                charmed[(state, source_direction)],
                charmed[(state, target_direction)],
                f"charmed {state} {source_direction}->{target_direction}",
            )

    for state, direction in iter_keys():
        for suffix, sheet, is_charmed in (
            ("", base[(state, direction)], False),
            ("_charmed", charmed[(state, direction)], True),
        ):
            logical_id = f"grunt_anim_{state}_{direction}{suffix}"
            assert_output(sheet, logical_id, is_charmed)
            path = output_dir / f"{logical_id}.png"
            save(sheet, path)
            outputs[logical_id] = {
                "path": path.relative_to(output_dir.parent.parent).as_posix(),
                "sha256": sha256(path),
                "bytes": path.stat().st_size,
                "size": list(sheet.size),
                "frame_size": [FRAME_SIZE, FRAME_SIZE],
                "frames": FRAME_COUNT,
                "fps": 12,
                "charmed": is_charmed,
            }

    provenance = {
        "schema": "mgs.generated-sprite-atlas.v1",
        "asset_family": "grunt_directional_animation",
        "status": "machine_conformant_human_review_required",
        "source_contract": {
            "character": "front-facing chibi robot grunt supplied by user",
            "art_style": "reference-matched painterly tactical-game chibi",
            "states": list(STATES),
            "directions": list(DIRECTIONS),
            "frame_size": [FRAME_SIZE, FRAME_SIZE],
            "frames": FRAME_COUNT,
            "fps": 12,
            "loop_closure": "frame 24 is exact frame 0",
        },
        "generation": {
            "keyframes": "gpt-image-2 reference-guided variations",
            "video": "veo3.1-fast for Walk SE/NE and Attack SE",
            "approved_fallback": "Attack NE uses phase-locked gpt-image-2 image sequence after video quota exhaustion",
            "postprocess": "full-cycle temporal compression, endpoint preservation, exact closure, bottom anchoring, transparent extraction, exact mirroring",
        },
        "compile": {
            "script": "tools/artgen/compile_grunt_animations.py",
            "td32_quantization": True,
            "alpha": "hard 0/255",
            "base_reserved_exclusions": [WHITE, SKY],
            "charmed_derivation": "ally-blue luminance ramp plus two rose hearts",
            "mirror_pairs": {"se": "sw", "ne": "nw"},
        },
        "sources": {
            f"{state}_{direction}": {
                "file": source_paths[(state, direction)].name,
                "sha256": sha256(source_paths[(state, direction)]),
            }
            for state, direction in iter_keys()
        },
        "outputs": outputs,
    }
    provenance_path.parent.mkdir(parents=True, exist_ok=True)
    provenance_path.write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "outputs": len(outputs), "provenance": str(provenance_path)}))


if __name__ == "__main__":
    main()
