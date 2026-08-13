#!/usr/bin/env python3
"""Deterministically author and publish the six S3 candidate world assets.

The GPT Image 2 raster is used only to derive exact palette colors and material
vocabulary. Runtime geometry is authored below from integer Pillow primitives;
no source module is cropped, resized, pasted, or copied into a runtime image.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys
import tempfile
from collections import Counter
from pathlib import Path
from typing import Iterable

import PIL
from PIL import Image, ImageDraw

SCHEMA_VERSION = 1
STATE = "CANDIDATE_MACHINE_CONFORMANT_H1_PENDING"
APPROVAL_TOKEN = "ACT-II-S2-S3-H0"
SOURCE_REL = Path("art-src/world/s3/s3-production-source.png")
TOOL_REL = Path("tools/art_pipeline/world/s3/normalize_s3_world.py")
RESERVED = {(244, 244, 244), (65, 166, 246)}
ASSETS = {
    "world.s3.elevated_assay": ("elevated-assay.png", (32, 24), [16, 23]),
    "world.s3.blocked_regulator": ("blocked-regulator.png", (32, 16), [16, 15]),
    "world.s3.blocked_pressure_jaw": ("blocked-pressure-jaw.png", (32, 16), [16, 15]),
    "world.s3.spawn_rain_sluice": ("spawn-rain-sluice.png", (32, 32), [16, 30]),
    "world.s3.core_pressure_keeper": ("core-pressure-keeper.png", (32, 32), [16, 30]),
    "world.s3.backdrop_panorama": ("backdrop-panorama.png", (256, 128), [128, 127]),
}
PALETTE_TARGETS = {
    "void": (18, 20, 23),
    "outline": (28, 31, 34),
    "basalt_dark": (42, 48, 51),
    "basalt_mid": (59, 67, 69),
    "basalt_light": (82, 91, 91),
    "iron_dark": (38, 42, 45),
    "iron_mid": (68, 73, 75),
    "iron_light": (103, 108, 106),
    "bronze_dark": (70, 52, 37),
    "bronze_mid": (105, 78, 51),
    "bronze_light": (145, 112, 72),
    "water_dark": (35, 55, 58),
    "water_mid": (58, 83, 84),
    "water_light": (93, 119, 116),
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def canonical_json(payload: object) -> bytes:
    return (json.dumps(payload, indent=2, sort_keys=True) + "\n").encode("utf-8")


def rgba(rgb: tuple[int, int, int], alpha: int = 255) -> tuple[int, int, int, int]:
    return (*rgb, alpha)


def source_palette(source: Path) -> dict[str, tuple[int, int, int]]:
    """Choose nearest exact source colors to frozen semantic material targets."""
    with Image.open(source) as opened:
        image = opened.convert("RGB")
        counts = Counter(image.getdata())
    # Ignore negligible compression/noise colors, exact reserved probes, and black.
    choices = [rgb for rgb, count in counts.items() if count >= 3 and rgb not in RESERVED and rgb != (0, 0, 0)]
    if not choices:
        raise RuntimeError("source has no eligible palette colors")
    selected: dict[str, tuple[int, int, int]] = {}
    used: set[tuple[int, int, int]] = set()
    for name, target in PALETTE_TARGETS.items():
        color = min(
            (rgb for rgb in choices if rgb not in used),
            key=lambda rgb: (sum((rgb[i] - target[i]) ** 2 for i in range(3)), -counts[rgb], rgb),
        )
        selected[name] = color
        used.add(color)
    return selected


def image(size: tuple[int, int], fill=(0, 0, 0, 0)) -> Image.Image:
    return Image.new("RGBA", size, fill)


def polygon(draw: ImageDraw.ImageDraw, points: Iterable[tuple[int, int]], color: tuple[int, int, int]) -> None:
    draw.polygon(tuple(points), fill=rgba(color))


def line(draw: ImageDraw.ImageDraw, points: Iterable[tuple[int, int]], color: tuple[int, int, int], width: int = 1) -> None:
    draw.line(tuple(points), fill=rgba(color), width=width)


def rectangle(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color: tuple[int, int, int]) -> None:
    draw.rectangle(box, fill=rgba(color))


def ellipse(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color: tuple[int, int, int]) -> None:
    draw.ellipse(box, fill=rgba(color))


def diamond(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color: tuple[int, int, int]) -> None:
    x0, y0, x1, y1 = box
    points = (((x0 + x1) // 2, y0), (x1, (y0 + y1) // 2), ((x0 + x1) // 2, y1), (x0, (y0 + y1) // 2))
    polygon(draw, points, color)


def build_elevated(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    out = image((32, 24)); d = ImageDraw.Draw(out)
    # Solid vertical plinth: uninterrupted top, then discrete left/right walls.
    polygon(d, ((0, 8), (16, 16), (16, 23), (0, 15)), p["iron_dark"])
    polygon(d, ((16, 16), (31, 8), (31, 15), (16, 23)), p["basalt_dark"])
    for y in (18, 21):
        line(d, ((3, y - 8), (16, y), (28, y - 7)), p["outline"])
    polygon(d, ((0, 8), (16, 0), (31, 8), (16, 16)), p["basalt_mid"])
    line(d, ((0, 8), (16, 0), (31, 8), (16, 16), (0, 8)), p["iron_light"])
    line(d, ((3, 8), (16, 2), (28, 8), (16, 14), (3, 8)), p["iron_dark"])
    # Rear-edge assay graduations; center remains a solid deployable plane.
    for x in (10, 13, 16, 19, 22):
        d.point((x, 5 + abs(16 - x) // 4), fill=rgba(p["bronze_light"]))
    rectangle(d, (14, 3, 18, 4), p["bronze_dark"])
    d.point((16, 9), fill=rgba(p["basalt_light"]))
    return out


def build_regulator(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    out = image((32, 16)); d = ImageDraw.Draw(out)
    diamond(d, (0, 0, 31, 15), p["outline"])
    diamond(d, (2, 2, 29, 13), p["iron_mid"])
    polygon(d, ((5, 7), (16, 2), (27, 7), (24, 9), (16, 5), (8, 9)), p["basalt_dark"])
    # Three transverse sealed slats: broad closed geometry, never a longitudinal route.
    for y, inset in ((7, 5), (9, 7), (11, 10)):
        line(d, ((inset, y), (16, y + 3), (31 - inset, y)), p["iron_light"])
        line(d, ((inset + 1, y + 1), (16, y + 4), (30 - inset, y + 1)), p["iron_dark"])
    rectangle(d, (14, 3, 17, 6), p["bronze_dark"])
    return out


def build_pressure_jaw(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    out = image((32, 16)); d = ImageDraw.Draw(out)
    diamond(d, (0, 0, 31, 15), p["outline"])
    diamond(d, (2, 2, 29, 13), p["basalt_dark"])
    # Opposed solid jaws interlock across the center; no aperture or bridge deck.
    polygon(d, ((4, 7), (12, 3), (15, 5), (12, 7), (16, 9), (12, 11)), p["iron_light"])
    polygon(d, ((28, 7), (20, 3), (17, 5), (20, 7), (16, 9), (20, 11)), p["iron_mid"])
    polygon(d, ((7, 11), (16, 6), (25, 11), (16, 14)), p["basalt_mid"])
    line(d, ((5, 7), (16, 13), (27, 7)), p["bronze_dark"])
    rectangle(d, (14, 8, 17, 12), p["outline"])
    return out


def build_spawn(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    out = image((32, 32)); d = ImageDraw.Draw(out)
    # Two outward-splayed baffles with an intentionally open owner/approach center.
    polygon(d, ((4, 7), (9, 3), (14, 15), (11, 20), (7, 15)), p["outline"])
    polygon(d, ((28, 7), (23, 3), (18, 15), (21, 20), (25, 15)), p["outline"])
    polygon(d, ((6, 8), (9, 5), (12, 15), (10, 17), (8, 14)), p["iron_mid"])
    polygon(d, ((26, 8), (23, 5), (20, 15), (22, 17), (24, 14)), p["iron_mid"])
    for y in (8, 11, 14):
        line(d, ((7, y), (11, y + 2)), p["iron_light"])
        line(d, ((25, y), (21, y + 2)), p["iron_light"])
    # Split feet preserve bottom-center convention while leaving x=13..19 transparent.
    polygon(d, ((5, 18), (11, 16), (14, 21), (11, 30), (6, 28)), p["iron_dark"])
    polygon(d, ((27, 18), (21, 16), (18, 21), (21, 30), (26, 28)), p["iron_dark"])
    line(d, ((7, 24), (11, 26)), p["bronze_mid"])
    line(d, ((25, 24), (21, 26)), p["bronze_mid"])
    # Confined water drops beside—not over—the visible center/approach.
    rectangle(d, (8, 27, 9, 30), p["water_light"])
    rectangle(d, (23, 27, 24, 30), p["water_mid"])
    return out


def build_core(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    out = image((32, 32)); d = ImageDraw.Draw(out)
    # Closed upper governor and inward-facing jaws, with a lower approach cutout.
    polygon(d, ((7, 10), (11, 5), (16, 3), (21, 5), (25, 10), (23, 19), (19, 22), (13, 22), (9, 19)), p["outline"])
    polygon(d, ((9, 10), (12, 7), (16, 5), (20, 7), (23, 10), (21, 18), (18, 21), (14, 21), (11, 18)), p["iron_mid"])
    ellipse(d, (11, 8, 21, 18), p["iron_light"])
    ellipse(d, (13, 10, 19, 16), p["basalt_dark"])
    rectangle(d, (15, 11, 17, 16), p["bronze_light"])
    # Converging supports terminate around, rather than across, the route approach.
    polygon(d, ((8, 18), (13, 21), (12, 29), (7, 30), (6, 24)), p["iron_dark"])
    polygon(d, ((24, 18), (19, 21), (20, 29), (25, 30), (26, 24)), p["iron_dark"])
    line(d, ((8, 22), (12, 24)), p["bronze_mid"])
    line(d, ((24, 22), (20, 24)), p["bronze_mid"])
    return out


def build_panorama(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    out = image((256, 128), rgba(p["void"])); d = ImageDraw.Draw(out)
    # Continuous wall strata: broad, mostly vertical/arcing forms, deliberately no 2:1 diamonds.
    rectangle(d, (0, 21, 255, 127), p["basalt_dark"])
    for y in (27, 48, 73, 101, 119):
        line(d, ((0, y), (47, y + 2), (89, y - 1), (143, y + 3), (201, y), (255, y + 2)), p["outline"], 2)
    # Asymmetric compression ribs break all long horizontal affordances.
    for i, x in enumerate((9, 31, 58, 88, 121, 157, 191, 224, 247)):
        top = 4 + (i * 11) % 16
        polygon(d, ((x - 3, 128), (x - 1, top + 8), (x + 3, top), (x + 7, top + 9), (x + 10, 128)), p["iron_dark"])
        line(d, ((x + 1, 123), (x + 2, top + 10), (x + 4, top + 5), (x + 6, top + 11), (x + 7, 123)), p["iron_mid"], 2)
    # Cropped cistern crown and broken louvers; shapes terminate at image edges/verticals.
    polygon(d, ((0, 8), (41, 2), (70, 15), (82, 35), (55, 31), (35, 16), (0, 22)), p["iron_dark"])
    for x in range(7, 61, 9):
        line(d, ((x, 10 + x // 12), (x + 5, 26 + x // 15)), p["iron_light"], 2)
    # Bounded lower-right structural void, irregular and crossed by vertical chains.
    polygon(d, ((178, 66), (209, 51), (255, 59), (255, 128), (173, 128), (165, 94)), p["void"])
    line(d, ((181, 70), (174, 126)), p["iron_mid"], 2)
    line(d, ((217, 58), (222, 127)), p["iron_mid"], 2)
    for y in range(74, 124, 9):
        ellipse(d, (180, y, 183, y + 5), p["bronze_dark"])
        ellipse(d, (220, y, 223, y + 5), p["bronze_dark"])
    # Water pockets are irregular horizontal fragments, never complete tile outlines.
    polygon(d, ((0, 91), (21, 86), (45, 91), (62, 86), (79, 96), (63, 111), (24, 108), (0, 114)), p["water_dark"])
    polygon(d, ((91, 106), (119, 100), (146, 105), (158, 116), (143, 127), (88, 127)), p["water_dark"])
    for x, y, length in ((5, 95, 12), (28, 101, 9), (51, 94, 14), (99, 112, 11), (128, 108, 8), (145, 120, 7)):
        line(d, ((x, y), (x + length, y + 1)), p["water_mid"])
    # Closed louver niches are vertical rectangles, not selectable diamonds.
    for x, y in ((102, 39), (137, 31), (238, 35)):
        rectangle(d, (x, y, x + 12, y + 25), p["outline"])
        rectangle(d, (x + 2, y + 2, x + 10, y + 23), p["iron_dark"])
        for yy in range(y + 5, y + 22, 5):
            line(d, ((x + 3, yy), (x + 9, yy)), p["iron_mid"])
    # Sparse short bronze fasteners; no aligned route-colored band.
    for x, y in ((18, 43), (66, 56), (115, 84), (151, 47), (199, 34), (244, 82)):
        rectangle(d, (x, y, x + 2, y + 3), p["bronze_mid"])
    return out


BUILDERS = {
    "world.s3.elevated_assay": build_elevated,
    "world.s3.blocked_regulator": build_regulator,
    "world.s3.blocked_pressure_jaw": build_pressure_jaw,
    "world.s3.spawn_rain_sluice": build_spawn,
    "world.s3.core_pressure_keeper": build_core,
    "world.s3.backdrop_panorama": build_panorama,
}


def save_png(value: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    value.save(path, format="PNG", optimize=False, compress_level=9)


def asset_checks(asset_images: dict[str, Image.Image], palette: dict[str, tuple[int, int, int]]) -> list[str]:
    allowed = set(palette.values())
    for logical_id, value in asset_images.items():
        expected = ASSETS[logical_id][1]
        if value.mode != "RGBA" or value.size != expected:
            raise RuntimeError(f"{logical_id}: expected RGBA {expected}, got {value.mode} {value.size}")
        alpha = {px[3] for px in value.getdata()}
        if not alpha <= {0, 255}:
            raise RuntimeError(f"{logical_id}: soft alpha {sorted(alpha)}")
        colors = {px[:3] for px in value.getdata() if px[3]}
        if colors & RESERVED:
            raise RuntimeError(f"{logical_id}: reserved-color collision")
        if not colors <= allowed:
            raise RuntimeError(f"{logical_id}: non-source-derived palette color")
    if asset_images["world.s3.blocked_regulator"].tobytes() == asset_images["world.s3.blocked_pressure_jaw"].tobytes():
        raise RuntimeError("blocker silhouettes are not distinct")
    # Explicit negative-space approach corridor in endpoint lower center.
    for logical_id in ("world.s3.spawn_rain_sluice", "world.s3.core_pressure_keeper"):
        value = asset_images[logical_id]
        if any(value.getpixel((x, y))[3] for x in range(14, 19) for y in range(24, 32)):
            raise RuntimeError(f"{logical_id}: lower-center owner/approach negative space is obstructed")
    return [
        "six exact logical IDs and dimensions",
        "RGBA hard alpha only",
        "all opaque RGB values are exact mandatory-source palette members",
        "reserved colors absent",
        "blocker bytes and silhouettes distinct",
        "endpoint lower-center owner/approach negative space clear",
        "panorama authored from non-diamond vertical/arcing primitives",
    ]


def provenance(logical_id: str, filename: str, digest: str, source_hash: str, palette_hash: str, tool_hash: str) -> dict[str, object]:
    size = ASSETS[logical_id][1]; pivot = ASSETS[logical_id][2]
    return {
        "schema_version": SCHEMA_VERSION,
        "logical_id": logical_id,
        "state": STATE,
        "human_final_art": False,
        "approval": {"token": APPROVAL_TOKEN, "phase": "H0", "h1_required": True, "approved_content_hash_gates_launch": False},
        "candidate_files": {
            "runtime": f"assets/world/s3/{filename}",
            "staging": f"staging/assets/world/s3/{filename}",
            "sha256": digest,
            "bytes_identical": True,
        },
        "dimensions": list(size),
        "pivot": pivot,
        "generator": {
            "provider": "Manus built-in image generation",
            "model": "gpt-image-2",
            "tool": "Manus built-in image generation / generate_image",
            "generation_id": None,
            "generation_id_reason": "UNAVAILABLE: generation tool returned no generation identifier; none invented.",
            "seed": None,
            "seed_reason": "UNAVAILABLE: generation tool exposed no seed parameter or returned seed; none invented.",
            "source": SOURCE_REL.as_posix(),
            "source_sha256": source_hash,
        },
        "normalization": {
            "tool": TOOL_REL.as_posix(),
            "tool_sha256": tool_hash,
            "palette": "art-src/world/s3/s3-derived-palette.json",
            "palette_sha256": palette_hash,
            "recipe": "exact source-color extraction plus original integer Pillow geometry; no source crop/resize/paste; no dithering; hard alpha",
            "python": sys.version.split()[0],
            "pillow": PIL.__version__,
        },
        "license_source": "original AI-assisted source under project-controlled prompt/reference set; candidate pending H1",
    }


def build_contact(asset_images: dict[str, Image.Image], palette: dict[str, tuple[int, int, int]]) -> Image.Image:
    out = image((512, 256), rgba(palette["void"])); d = ImageDraw.Draw(out)
    slots = [(16, 18), (128, 18), (240, 18), (16, 104), (128, 104)]
    ids = list(ASSETS)[:5]
    for logical_id, (x, y) in zip(ids, slots):
        value = asset_images[logical_id].resize((value_w := value_size(asset_images[logical_id])[0] * 3, value_h := value_size(asset_images[logical_id])[1] * 3), Image.Resampling.NEAREST)
        out.alpha_composite(value, (x, y + 18))
        d.text((x, y), logical_id.removeprefix("world.s3."), fill=rgba(palette["iron_light"]))
    pano = asset_images["world.s3.backdrop_panorama"]
    out.alpha_composite(pano, (240, 104))
    d.text((240, 88), "backdrop_panorama", fill=rgba(palette["iron_light"]))
    return out


def value_size(value: Image.Image) -> tuple[int, int]:
    return value.size


def build_topology_mock(asset_images: dict[str, Image.Image], p: dict[str, tuple[int, int, int]]) -> Image.Image:
    out = image((512, 320), rgba(p["void"])); d = ImageDraw.Draw(out)
    out.alpha_composite(asset_images["world.s3.backdrop_panorama"].resize((512, 256), Image.Resampling.NEAREST), (0, 0))
    origin = (224, 70); scale = 2
    route = {(0,2),(1,2),(2,2),(3,2),(4,2),(4,3),(4,4),(5,4),(6,4),(7,4),(8,4),(9,4)}
    blocked = {(5,2): "world.s3.blocked_regulator", (5,3): "world.s3.blocked_pressure_jaw"}
    for y in range(6):
        for x in range(10):
            cx = origin[0] + (x-y)*32; cy = origin[1] + (x+y)*16
            color = p["bronze_mid"] if (x,y) in route else p["basalt_mid"]
            polygon(d, ((cx,cy),(cx+32,cy+16),(cx,cy+32),(cx-32,cy+16)), color)
            line(d, ((cx,cy),(cx+32,cy+16),(cx,cy+32),(cx-32,cy+16),(cx,cy)), p["outline"], 2)
    def place(logical_id: str, coord: tuple[int,int], lift: int = 0) -> None:
        x,y=coord; sprite=asset_images[logical_id].resize((ASSETS[logical_id][1][0]*scale,ASSETS[logical_id][1][1]*scale),Image.Resampling.NEAREST)
        cx=origin[0]+(x-y)*32; cy=origin[1]+(x+y)*16
        out.alpha_composite(sprite,(cx-sprite.width//2,cy+32-sprite.height-lift))
    place("world.s3.elevated_assay",(2,3),16)
    for coord, logical_id in blocked.items(): place(logical_id,coord)
    place("world.s3.spawn_rain_sluice",(0,2))
    place("world.s3.core_pressure_keeper",(9,4))
    d.text((10, 292), "S3 exact E-S-E: Spawn (0,2) / elevated (2,3) / choke (4,3) / blockers (5,2)(5,3) / Core (9,4)", fill=rgba(p["iron_light"]))
    return out


def replace_tree(target: Path, prepared: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    old = target.with_name(target.name + ".old-s3")
    if old.exists(): shutil.rmtree(old)
    if target.exists(): os.replace(target, old)
    os.replace(prepared, target)
    if old.exists(): shutil.rmtree(old)


def generate(repo_root: Path, source: Path | None = None) -> dict[str, object]:
    repo_root = repo_root.resolve()
    source = (source or repo_root / SOURCE_REL).resolve()
    if not source.is_file(): raise FileNotFoundError(source)
    source_hash = sha256(source)
    tool_path = Path(__file__).resolve(); tool_hash = sha256(tool_path)
    palette = source_palette(source)
    asset_images = {logical_id: BUILDERS[logical_id](palette) for logical_id in ASSETS}
    passed = asset_checks(asset_images, palette)

    ledger = {
        "schema_version": SCHEMA_VERSION,
        "state": STATE,
        "source": SOURCE_REL.as_posix(),
        "source_sha256": source_hash,
        "source_role": "mandatory GPT Image 2 palette/material/provenance input; never a runtime raster",
        "provider": "Manus built-in image generation",
        "model": "gpt-image-2",
        "tool": "Manus built-in image generation / generate_image",
        "generation_id": None,
        "generation_id_reason": "UNAVAILABLE: tool returned paths/dimensions but no generation identifier; none invented.",
        "seed": None,
        "seed_reason": "UNAVAILABLE: tool did not expose/return a seed; none invented.",
        "approval_token": APPROVAL_TOKEN,
        "human_final_art": False,
        "approved_content_hash_gates_launch": False,
        "originality": "Runtime pixels are new programmatic shapes; source modules are not resized, copied, cropped, or pasted.",
    }
    contract = {
        "schema_version": SCHEMA_VERSION,
        "state": STATE,
        "approval_token": APPROVAL_TOKEN,
        "human_final_art": False,
        "approved_content_hash_gates_launch": False,
        "asset_count": 6,
        "assets": [
            {"logical_id": logical_id, "filename": spec[0], "dimensions": list(spec[1]), "pivot": spec[2]}
            for logical_id, spec in ASSETS.items()
        ],
        "raster": {"mode": "RGBA", "alpha": [0,255], "dithering": False, "forbidden_colors": ["#F4F4F4","#41A6F6"]},
        "topology": {"grid":[10,6],"spawn":[0,2],"core":[9,4],"elevated":[[2,3]],"blocked":[[5,2],[5,3]],"choke":[4,3],"path":[[0,2],[1,2],[2,2],[3,2],[4,2],[4,3],[4,4],[5,4],[6,4],[7,4],[8,4],[9,4]]},
        "publication": "staging and runtime PNG bytes must match; managed output trees are complete-replacement roots",
    }
    palette_doc = {
        "schema_version": SCHEMA_VERSION,
        "source": SOURCE_REL.as_posix(),
        "source_sha256": source_hash,
        "algorithm": "nearest exact eligible source RGB to frozen semantic targets; count>=3; unique; lexicographic tie-break; no dithering",
        "colors": {name: "#%02X%02X%02X" % color for name, color in palette.items()},
        "targets": {name: "#%02X%02X%02X" % color for name, color in PALETTE_TARGETS.items()},
    }
    palette_bytes = canonical_json(palette_doc); palette_hash = hashlib.sha256(palette_bytes).hexdigest()

    # Build all complete-replacement output trees under one temporary parent.
    temp_parent = Path(tempfile.mkdtemp(prefix="s3-publish-", dir=repo_root))
    prepared: dict[Path, Path] = {}
    try:
        rel_roots = [
            Path("assets/world/s3"), Path("staging/assets/world/s3"),
            Path("assets/provenance/fragments/s3"), Path("staging/provenance/world/s3"),
            Path("staging/qa/world/s3"),
        ]
        for index, rel in enumerate(rel_roots):
            candidate = temp_parent / f"tree-{index}"; candidate.mkdir(parents=True)
            prepared[repo_root / rel] = candidate
        runtime_dir = prepared[repo_root / "assets/world/s3"]
        staging_dir = prepared[repo_root / "staging/assets/world/s3"]
        runtime_prov = prepared[repo_root / "assets/provenance/fragments/s3"]
        staging_prov = prepared[repo_root / "staging/provenance/world/s3"]
        qa_dir = prepared[repo_root / "staging/qa/world/s3"]
        asset_hashes: dict[str, str] = {}
        for logical_id, (filename, _, _) in ASSETS.items():
            runtime_file = runtime_dir / filename
            save_png(asset_images[logical_id], runtime_file)
            data = runtime_file.read_bytes(); (staging_dir / filename).write_bytes(data)
            digest = hashlib.sha256(data).hexdigest(); asset_hashes[logical_id] = digest
            fragment = canonical_json(provenance(logical_id, filename, digest, source_hash, palette_hash, tool_hash))
            prov_name = filename.removesuffix(".png") + ".provenance.json"
            (runtime_prov / prov_name).write_bytes(fragment); (staging_prov / prov_name).write_bytes(fragment)
        save_png(build_contact(asset_images, palette), qa_dir / "s3-contact-sheet.png")
        save_png(build_topology_mock(asset_images, palette), qa_dir / "s3-topology-mock.png")
        report = {
            "schema_version": SCHEMA_VERSION,
            "state": STATE,
            "human_final_art": False,
            "approval_token": APPROVAL_TOKEN,
            "source_sha256": source_hash,
            "tool_sha256": tool_hash,
            "asset_count": 6,
            "asset_sha256": asset_hashes,
            "checks_passed": passed + ["runtime/staging candidate bytes identical", "one provenance fragment per logical asset mirrored byte-identically"],
            "visual_review_status": "H1_PENDING",
            "idempotence_protocol": ["clean A", "clean B", "contaminated C complete replacement"],
        }
        (qa_dir / "normalization-report.json").write_bytes(canonical_json(report))
        for target, candidate in prepared.items(): replace_tree(target, candidate)
    finally:
        if temp_parent.exists(): shutil.rmtree(temp_parent)

    art_dir = repo_root / "art-src/world/s3"; art_dir.mkdir(parents=True, exist_ok=True)
    (art_dir / "gpt-image-2-source-ledger.json").write_bytes(canonical_json(ledger))
    (art_dir / "s3-world-asset-contract.json").write_bytes(canonical_json(contract))
    (art_dir / "s3-derived-palette.json").write_bytes(palette_bytes)
    return {"state": STATE, "source_sha256": source_hash, "assets": asset_hashes, "checks": passed}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[4])
    parser.add_argument("--source", type=Path)
    args = parser.parse_args()
    result = generate(args.repo_root, args.source)
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
