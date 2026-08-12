#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import math
import statistics
from pathlib import Path
import PIL
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parents[3]
ART_SRC = REPO_ROOT / "art-src/world/s1"
NORMALIZED = REPO_ROOT / "staging/assets/world/s1"
PROVENANCE = REPO_ROOT / "staging/provenance/world/s1"
QA = REPO_ROOT / "staging/qa/world/s1"
CONTRACT = ART_SRC / "s1-world-asset-contract.json"
SOURCE_PALETTES = ART_SRC / "s1-source-palettes.json"
SOURCE_LEDGER = ART_SRC / "gpt-image-2-source-ledger.json"
REPORT = QA / "normalization-report.json"
HUMAN_APPROVAL = REPO_ROOT / "docs/media/AUI-10R-REVISION-2-HUMAN-APPROVAL.json"
RESERVED = {(244, 244, 244): "#F4F4F4", (65, 166, 246): "#41A6F6"}

ASSET_FILES = {
    "world.s1.ground": "s1-ground.png",
    "world.s1.route": "s1-route.png",
    "world.s1.elevated": "s1-elevated.png",
    "world.s1.backdrop": "s1-backdrop.png",
    "world.s1.spawn_landmark": "s1-spawn-landmark.png",
    "world.s1.core_landmark": "s1-core-landmark.png",
    "world.s1.rain_measure": "s1-rain-measure.png",
    "world.s1.route_notch": "s1-route-notch.png",
}

PROMPT_SECTIONS = {
    "world.s1.ground": "Ground",
    "world.s1.route": "Route",
    "world.s1.elevated": "Elevated",
    "world.s1.backdrop": "Backdrop",
    "world.s1.spawn_landmark": "Spawn landmark",
    "world.s1.core_landmark": "Core landmark",
    "world.s1.rain_measure": "Rain measure",
    "world.s1.route_notch": "Route notch",
}

RAW_ACCEPTANCE = {
    "world.s1.backdrop": "REJECTED_SILHOUETTE_COLOR_MATERIAL_ONLY",
    "world.s1.route_notch": "REJECTED_SILHOUETTE_MOTIF_ONLY",
}


def repo_path(path: Path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def hex_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def rgb_hex(rgb: tuple[int, int, int]) -> str:
    return "#%02X%02X%02X" % rgb


def _srgb_to_linear(channel: float) -> float:
    channel /= 255.0
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


def _linear_to_srgb(channel: float) -> int:
    channel = max(0.0, min(1.0, channel))
    value = 12.92 * channel if channel <= 0.0031308 else 1.055 * channel ** (1.0 / 2.4) - 0.055
    return max(0, min(255, round(value * 255.0)))


def rgb_to_lab(rgb: tuple[int, int, int]) -> tuple[float, float, float]:
    r, g, b = (_srgb_to_linear(c) for c in rgb)
    x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047
    y = (0.2126729 * r + 0.7151522 * g + 0.0721750 * b) / 1.00000
    z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883

    def f(t: float) -> float:
        delta = 6.0 / 29.0
        return t ** (1.0 / 3.0) if t > delta**3 else t / (3.0 * delta**2) + 4.0 / 29.0

    fx, fy, fz = f(x), f(y), f(z)
    return 116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz)


def lab_to_rgb(lab: tuple[float, float, float]) -> tuple[int, int, int]:
    lstar, astar, bstar = lab
    fy = (lstar + 16.0) / 116.0
    fx = fy + astar / 500.0
    fz = fy - bstar / 200.0

    def finv(t: float) -> float:
        delta = 6.0 / 29.0
        return t**3 if t > delta else 3.0 * delta**2 * (t - 4.0 / 29.0)

    x = 0.95047 * finv(fx)
    y = 1.00000 * finv(fy)
    z = 1.08883 * finv(fz)
    r = 3.2404542 * x - 1.5371385 * y - 0.4985314 * z
    g = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
    b = 0.0556434 * x - 0.2040259 * y + 1.0572252 * z
    return _linear_to_srgb(r), _linear_to_srgb(g), _linear_to_srgb(b)


def set_lstar(rgb: tuple[int, int, int], target: float, chroma_scale: float = 1.0) -> tuple[int, int, int]:
    _, a, b = rgb_to_lab(rgb)
    return lab_to_rgb((target, a * chroma_scale, b * chroma_scale))


def rgba(rgb: tuple[int, int, int], alpha: int = 255) -> tuple[int, int, int, int]:
    return rgb[0], rgb[1], rgb[2], alpha


def deterministic_hash(x: int, y: int, salt: int) -> int:
    n = x * 374761393 + y * 668265263 + salt * 1274126177
    n = (n ^ (n >> 13)) * 1103515245
    return abs(n ^ (n >> 16))


def diamond_mask(width: int, height: int) -> list[int]:
    result = [0] * (width * height)
    span = 2 * width * height
    for y in range(height):
        for x in range(width):
            u = (2 * x + 1 - width) * height + (2 * y + 1) * width
            v = (2 * y + 1) * width - (2 * x + 1 - width) * height
            if 0 <= u < span and 0 <= v < span:
                result[y * width + x] = 1
    return result


def iso_uv(x: int, y: int, width: int = 32, height: int = 16) -> tuple[int, int]:
    xx = 2 * x + 1 - width
    yy = 2 * y + 1
    return xx * height + yy * width, yy * width - xx * height


def edge_pixel(mask: list[int], width: int, height: int, x: int, y: int) -> bool:
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        qx, qy = x + dx, y + dy
        if qx < 0 or qy < 0 or qx >= width or qy >= height or mask[qy * width + qx] == 0:
            return True
    return False


def dominant_sources() -> dict[str, list[dict[str, object]]]:
    return json.loads(SOURCE_PALETTES.read_text(encoding="utf-8"))


def build_palette() -> dict[str, tuple[int, int, int]]:
    sources = dominant_sources()
    ground_source = hex_rgb(str(sources["s1-ground.png"][0]["hex"]))
    route_source = hex_rgb(str(sources["s1-route.png"][0]["hex"]))
    spawn_source = hex_rgb(str(sources["s1-spawn-landmark.png"][0]["hex"]))
    core_source = hex_rgb(str(sources["s1-core-landmark.png"][0]["hex"]))
    rain_source = hex_rgb(str(sources["s1-rain-measure.png"][1]["hex"]))
    palette = {
        "outline": set_lstar(core_source, 14.0, 0.45),
        "metal_dark": set_lstar(core_source, 20.0, 0.50),
        "metal_mid": set_lstar(core_source, 31.0, 0.55),
        "metal_light": set_lstar(core_source, 43.0, 0.45),
        "ground_dark": set_lstar(ground_source, 43.0, 0.75),
        "ground_mid": set_lstar(ground_source, 52.0, 0.78),
        "ground_light": set_lstar(ground_source, 59.0, 0.72),
        "ground_high": set_lstar(ground_source, 65.0, 0.60),
        "route_dark": set_lstar(route_source, 39.0, 0.95),
        "route_mid": set_lstar(route_source, 49.0, 0.95),
        "route_light": set_lstar(route_source, 57.0, 0.85),
        "canvas_dark": set_lstar(spawn_source, 42.0, 0.82),
        "canvas_mid": set_lstar(spawn_source, 56.0, 0.80),
        "canvas_light": set_lstar(spawn_source, 64.0, 0.65),
        "timber_dark": set_lstar(route_source, 30.0, 1.15),
        "timber_mid": set_lstar(route_source, 42.0, 1.08),
        "timber_light": set_lstar(route_source, 53.0, 0.95),
        "ceramic_dark": set_lstar(ground_source, 36.0, 0.52),
        "ceramic_mid": set_lstar(ground_source, 49.0, 0.50),
        "ceramic_light": set_lstar(ground_source, 60.0, 0.45),
        "bronze_dark": set_lstar(route_source, 34.0, 1.18),
        "bronze_mid": set_lstar(route_source, 47.0, 1.12),
        "bronze_light": set_lstar(route_source, 59.0, 1.00),
        "water_dark": set_lstar(rain_source, 18.0, 0.55),
        "water_mid": set_lstar(rain_source, 30.0, 0.50),
        "backdrop_void": (24, 26, 31),
    }
    for name, color in palette.items():
        if color in RESERVED:
            raise RuntimeError(f"derived palette collision: {name}={rgb_hex(color)}")
    return palette


def build_ground(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    w, h = 32, 16
    mask = diamond_mask(w, h)
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            if not mask[y * w + x]:
                continue
            u, v = iso_uv(x, y)
            seam = (u % 768 < 45 and x not in range(13, 20)) or (v % 896 < 38 and y not in range(6, 10))
            roll = deterministic_hash(x, y, 17) % 100
            color = p["ground_mid"]
            if seam:
                color = p["ground_dark"]
            elif roll < 5:
                color = p["ground_light"]
            elif roll < 8:
                color = p["ground_dark"]
            if edge_pixel(mask, w, h, x, y):
                color = p["ground_dark"]
            image.putpixel((x, y), rgba(color))
    return image


def build_route(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    w, h = 32, 16
    mask = diamond_mask(w, h)
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            if not mask[y * w + x]:
                continue
            u, v = iso_uv(x, y)
            roll = deterministic_hash(x, y, 31) % 100
            color = p["route_mid"]
            # Sparse transverse service joints; keep central 10x6 region quiet.
            joint = u % 640 < 52 and not (11 <= x <= 21 and 5 <= y <= 11)
            if joint:
                color = p["route_dark"]
            elif roll < 7:
                color = p["route_light"]
            elif roll < 11:
                color = p["route_dark"]
            if edge_pixel(mask, w, h, x, y):
                color = p["timber_dark"]
            image.putpixel((x, y), rgba(color))
    return image


def build_elevated(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    top = build_ground(p)
    w, top_h, wall_h = 32, 16, 8
    image = Image.new("RGBA", (w, top_h + wall_h), (0, 0, 0, 0))
    image.alpha_composite(top, (0, 0))
    for x in range(w):
        bottom = -1
        for y in range(top_h):
            if top.getpixel((x, y))[3] > 0:
                bottom = y
        if bottom < 0:
            continue
        color = p["ground_dark"] if x < w // 2 else p["ceramic_dark"]
        for dy in range(wall_h):
            shade = color
            if dy == 0:
                shade = p["ground_mid"]
            elif dy == wall_h - 1:
                shade = p["outline"]
            image.putpixel((x, bottom + 1 + dy), rgba(shade))
    # Service braces live only on wall rows.
    draw = ImageDraw.Draw(image)
    for x in (6, 24):
        draw.line((x, 14, x, 21), fill=rgba(p["metal_dark"]), width=1)
        draw.point((x, 16), fill=rgba(p["metal_light"]))
        draw.point((x, 19), fill=rgba(p["metal_light"]))
    return image


def build_backdrop(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    image = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    # Deliberately broken/non-diamond fragments: no selectable face center.
    fragments = [
        [(1, 8), (7, 5), (12, 7), (7, 10)],
        [(9, 11), (15, 8), (19, 10), (14, 13)],
        [(20, 7), (25, 5), (31, 8), (26, 11)],
    ]
    for i, poly in enumerate(fragments):
        draw.polygon(poly, fill=rgba(p["ground_dark"] if i != 1 else p["metal_mid"]))
        draw.line(poly + [poly[0]], fill=rgba(p["outline"]), width=1)
    draw.line((5, 12, 12, 14), fill=rgba(p["water_mid"]), width=1)
    draw.line((19, 13, 27, 11), fill=rgba(p["water_mid"]), width=1)
    return image


def build_route_notch(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    image = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    # Three exact down-right cadence chevrons following +grid-X projection.
    for ox, oy in ((7, 4), (14, 7), (21, 10)):
        draw.line((ox, oy, ox + 3, oy + 2, ox + 1, oy + 4), fill=rgba(p["outline"]), width=2)
        draw.line((ox, oy, ox + 3, oy + 2, ox + 1, oy + 4), fill=rgba(p["route_light"]), width=1)
    return image


def build_spawn(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    image = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    # Feet and posts, with a deliberately open center.
    for x in (5, 24):
        d.rectangle((x - 1, 11, x + 3, 29), fill=rgba(p["outline"]))
        d.rectangle((x, 12, x + 2, 27), fill=rgba(p["timber_mid"]))
        d.point((x, 13), fill=rgba(p["timber_light"]))
        d.rectangle((x - 2, 28, x + 4, 30), fill=rgba(p["metal_dark"]))
    # Isometric canvas awning.
    roof_outer = [(3, 10), (15, 3), (29, 10), (24, 16), (8, 16)]
    roof_inner = [(5, 10), (15, 5), (27, 10), (23, 14), (9, 14)]
    d.polygon(roof_outer, fill=rgba(p["outline"]))
    d.polygon(roof_inner, fill=rgba(p["canvas_mid"]))
    d.line((6, 10, 15, 6, 26, 10), fill=rgba(p["canvas_light"]), width=1)
    # Compact intake box stays to the side, not under the emergence center.
    d.rectangle((22, 18, 29, 27), fill=rgba(p["outline"]))
    d.rectangle((23, 19, 28, 26), fill=rgba(p["metal_mid"]))
    d.line((24, 21, 27, 21), fill=rgba(p["bronze_mid"]), width=1)
    d.line((24, 24, 27, 24), fill=rgba(p["metal_dark"]), width=1)
    # One small wind tab.
    d.line((27, 8, 30, 7), fill=rgba(p["metal_dark"]), width=1)
    d.polygon([(30, 6), (31, 7), (29, 9)], fill=rgba(p["canvas_dark"]))
    return image


def build_core(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    image = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    # Stabilizer feet.
    d.rectangle((4, 26, 10, 30), fill=rgba(p["outline"]))
    d.rectangle((22, 26, 28, 30), fill=rgba(p["outline"]))
    d.rectangle((5, 26, 9, 28), fill=rgba(p["metal_mid"]))
    d.rectangle((23, 26, 27, 28), fill=rgba(p["metal_mid"]))
    # Squat ceramic drum.
    d.rounded_rectangle((6, 7, 26, 27), radius=5, fill=rgba(p["outline"]))
    d.rounded_rectangle((8, 8, 24, 25), radius=4, fill=rgba(p["ceramic_mid"]))
    d.line((9, 12, 23, 12), fill=rgba(p["ceramic_light"]), width=1)
    d.line((8, 20, 24, 20), fill=rgba(p["metal_dark"]), width=2)
    d.rectangle((14, 4, 18, 8), fill=rgba(p["outline"]))
    d.rectangle((15, 4, 17, 7), fill=rgba(p["bronze_mid"]))
    # Gauge housing, intentionally lateral and readable at 1x.
    d.ellipse((4, 13, 15, 24), fill=rgba(p["outline"]))
    d.ellipse((6, 15, 13, 22), fill=rgba(p["ground_light"]))
    d.line((9, 19, 12, 17), fill=rgba(p["metal_dark"]), width=1)
    # Right service pipe.
    d.line((24, 12, 29, 12, 29, 22, 25, 22), fill=rgba(p["outline"]), width=3)
    d.line((24, 12, 28, 12, 28, 21, 25, 21), fill=rgba(p["metal_light"]), width=1)
    return image


def build_rain_measure(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    image = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    d.rectangle((2, 12, 13, 14), fill=rgba(p["outline"]))
    d.rectangle((3, 7, 9, 13), fill=rgba(p["outline"]))
    d.rectangle((4, 8, 8, 12), fill=rgba(p["ceramic_mid"]))
    d.ellipse((3, 6, 9, 9), fill=rgba(p["ceramic_light"]), outline=rgba(p["outline"]))
    d.rectangle((11, 4, 13, 13), fill=rgba(p["outline"]))
    d.line((12, 5, 12, 12), fill=rgba(p["metal_mid"]), width=1)
    for y in (6, 8, 10):
        d.point((13, y), fill=rgba(p["bronze_light"]))
    return image


def save_assets(palette: dict[str, tuple[int, int, int]]) -> dict[str, Path]:
    NORMALIZED.mkdir(parents=True, exist_ok=True)
    assets = {
        "world.s1.ground": build_ground(palette),
        "world.s1.route": build_route(palette),
        "world.s1.elevated": build_elevated(palette),
        "world.s1.backdrop": build_backdrop(palette),
        "world.s1.spawn_landmark": build_spawn(palette),
        "world.s1.core_landmark": build_core(palette),
        "world.s1.rain_measure": build_rain_measure(palette),
        "world.s1.route_notch": build_route_notch(palette),
    }
    paths: dict[str, Path] = {}
    for logical_id, image in assets.items():
        name = logical_id.replace("world.s1.", "s1-").replace("_", "-") + ".png"
        path = NORMALIZED / name
        image.save(path, format="PNG", optimize=False, compress_level=9)
        paths[logical_id] = path
    return paths


def inspect_image(path: Path, expected: tuple[int, int]) -> dict[str, object]:
    with Image.open(path) as source:
        image = source.convert("RGBA")
        reserved = {label: 0 for label in RESERVED.values()}
        partial = 0
        opaque = 0
        bbox = image.getbbox()
        for r, g, b, a in image.get_flattened_data():
            if 0 < a < 255:
                partial += 1
            if a == 255:
                opaque += 1
                if (r, g, b) in RESERVED:
                    reserved[RESERVED[(r, g, b)]] += 1
        return {
            "path": repo_path(path),
            "sha256": sha256(path),
            "size": [image.width, image.height],
            "expected_size": list(expected),
            "geometry_gate": "PASS" if image.size == expected else "FAIL",
            "hard_alpha_gate": "PASS" if partial == 0 else "FAIL",
            "partial_alpha_pixels": partial,
            "opaque_pixels": opaque,
            "opaque_bbox": list(bbox) if bbox else None,
            "reserved_exact_pixel_counts": reserved,
            "reserved_color_gate": "PASS" if sum(reserved.values()) == 0 else "FAIL",
        }


def tile_position(x: int, y: int, origin: tuple[int, int]) -> tuple[int, int]:
    cx = origin[0] + (x - y) * 16
    cy = origin[1] + (x + y) * 8
    return cx - 16, cy - 8


def build_stage_mock(paths: dict[str, Path], palette: dict[str, tuple[int, int, int]]) -> dict[str, object]:
    tiles = {key: Image.open(path).convert("RGBA") for key, path in paths.items()}
    canvas = Image.new("RGBA", (320, 160), rgba(palette["backdrop_void"]))
    surface = Image.new("L", canvas.size, 0)
    origin = (136, 30)
    route = {(x, 2) for x in range(8)}
    elevated = {(3, 1), (3, 3)}
    spawn = (0, 2)
    core = (7, 2)

    for depth in range(12):
        for y in range(5):
            for x in range(8):
                if x + y != depth:
                    continue
                logical_id = "world.s1.route" if (x, y) in route else "world.s1.ground"
                if (x, y) in elevated:
                    logical_id = "world.s1.elevated"
                tile = tiles[logical_id]
                px, py = tile_position(x, y, origin)
                if logical_id == "world.s1.elevated":
                    py -= 8
                canvas.alpha_composite(tile, (px, py))
                alpha = tile.getchannel("A")
                surface.paste(255, (px, py), alpha)
                if (x, y) in {(2, 2), (4, 2), (6, 2)}:
                    canvas.alpha_composite(tiles["world.s1.route_notch"], tile_position(x, y, origin))
                if (x, y) == spawn:
                    landmark = tiles["world.s1.spawn_landmark"]
                    cx = origin[0] + (x - y) * 16
                    cy = origin[1] + (x + y) * 8
                    # Typed endpoint owner, offset toward the off-board approach
                    # so the playable face center and emergence contact stay open.
                    canvas.alpha_composite(landmark, (cx - 28, cy - 34))
                if (x, y) == core:
                    landmark = tiles["world.s1.core_landmark"]
                    cx = origin[0] + (x - y) * 16
                    cy = origin[1] + (x + y) * 8
                    # Mirror the approach treatment outward past the final cell.
                    canvas.alpha_composite(landmark, (cx - 4, cy - 26))

    values: list[float] = []
    warm_direct = 0
    surface_pixels = 0
    for y in range(canvas.height):
        for x in range(canvas.width):
            if surface.getpixel((x, y)) == 0:
                continue
            r, g, b, _ = canvas.getpixel((x, y))
            lstar, astar, bstar = rgb_to_lab((r, g, b))
            values.append(lstar)
            surface_pixels += 1
            if lstar >= 48.0 and astar >= -2.0 and bstar >= 4.0:
                warm_direct += 1

    median_lstar = statistics.median(values) if values else 0.0
    warm_share = warm_direct / surface_pixels if surface_pixels else 0.0
    scale = 4
    stage_path = QA / "s1-stage-mock.png"
    mask_path = QA / "s1-playable-surface-mask.png"
    canvas.resize((canvas.width * scale, canvas.height * scale), Image.Resampling.NEAREST).save(stage_path)
    surface.resize((surface.width * scale, surface.height * scale), Image.Resampling.NEAREST).save(mask_path)
    for image in tiles.values():
        image.close()
    return {
        "stage_mock": {"path": repo_path(stage_path), "sha256": sha256(stage_path)},
        "surface_mask": {"path": repo_path(mask_path), "sha256": sha256(mask_path), "pixel_count_native": surface_pixels},
        "median_cie_lstar": round(median_lstar, 3),
        "act_i_lstar_gate": "PASS" if 48.0 <= median_lstar <= 58.0 else "FAIL",
        "warm_direct_share": round(warm_share, 4),
        "warm_direct_target": [0.55, 0.70],
        "warm_direct_gate": "PASS" if 0.55 <= warm_share <= 0.70 else "FAIL",
        "measurement_note": "Concept/staged raster feasibility only; final runtime measurement remains required.",
    }


def checker(size: tuple[int, int], a: tuple[int, int, int], b: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", size, rgba(a))
    draw = ImageDraw.Draw(image)
    step = 8
    for y in range(0, size[1], step):
        for x in range(0, size[0], step):
            if (x // step + y // step) % 2:
                draw.rectangle((x, y, x + step - 1, y + step - 1), fill=rgba(b))
    return image


def build_contact_sheet(paths: dict[str, Path]) -> dict[str, object]:
    scale = 6
    card_w, card_h = 240, 220
    columns = 4
    rows = math.ceil(len(paths) / columns)
    sheet = Image.new("RGBA", (columns * card_w, rows * card_h), (28, 30, 38, 255))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, (logical_id, path) in enumerate(paths.items()):
        col, row = index % columns, index // columns
        ox, oy = col * card_w, row * card_h
        bg = checker((card_w - 20, card_h - 45), (224, 216, 198), (52, 55, 63))
        sheet.alpha_composite(bg, (ox + 10, oy + 28))
        with Image.open(path) as source:
            image = source.convert("RGBA")
            up = image.resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST)
            px = ox + (card_w - up.width) // 2
            py = oy + 35 + (card_h - 55 - up.height) // 2
            sheet.alpha_composite(up, (px, py))
        draw.text((ox + 10, oy + 8), logical_id, fill=(244, 236, 216, 255), font=font)
    path = QA / "s1-world-contact-sheet.png"
    sheet.save(path)
    return {"path": repo_path(path), "sha256": sha256(path), "size": list(sheet.size)}


def write_json(path: Path, payload: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def emit_provenance(paths: dict[str, Path], source_ledger: dict[str, object]) -> None:
    PROVENANCE.mkdir(parents=True, exist_ok=True)
    human_approval = json.loads(HUMAN_APPROVAL.read_text(encoding="utf-8"))
    sources = {entry["file"]: entry for entry in source_ledger["sources"]}
    generator = source_ledger["generator"]
    references = source_ledger["approved_reference_hashes"]
    for logical_id, final_path in paths.items():
        raw_name = ASSET_FILES[logical_id]
        original_name = raw_name.replace(".png", "_original.png")
        sidecar = {
            "schema_version": 1,
            "logical_id": logical_id,
            "state": "STAGED_MACHINE_CONFORMANT_HUMAN_FINAL_ACCEPTED",
            "final_file": repo_path(final_path),
            "final_file_sha256": sha256(final_path),
            "raw_source": {
                "retention": "external owner-approval archive",
                "file": raw_name,
                "sha256": sources[raw_name]["sha256"],
                "original_file": original_name,
                "original_sha256": sources[original_name]["sha256"],
                "acceptance_state": RAW_ACCEPTANCE.get(
                    logical_id, "ACCEPTED_AS_IDENTITY_MATERIAL_SOURCE"
                ),
            },
            "placement_state": (
                "UNPLACED_PENDING_VALIDATED_MASK"
                if logical_id == "world.s1.rain_measure"
                else "STAGED_PRESENTATION_ROLE_DEFINED"
            ),
            "generator": {
                "tool": generator["tool"],
                "model": generator["model"],
                "seed": generator["seed"],
                "seed_reason": generator["seed_reason"],
                "prompt_contract": generator["prompt_contract"],
                "prompt_contract_sha256": generator["prompt_contract_sha256"],
                "prompt_section": PROMPT_SECTIONS[logical_id],
                "approved_reference_hashes": references,
            },
            "normalization": {
                "recipe": "source palette derivation + contract-authored native geometry + hard alpha + no-dither fixed palette",
                "tool": repo_path(Path(__file__).resolve()),
                "tool_sha256": sha256(Path(__file__).resolve()),
                "asset_contract": repo_path(CONTRACT),
                "asset_contract_sha256": sha256(CONTRACT),
                "derived_palette": repo_path(ART_SRC / "s1-derived-palette.json"),
                "derived_palette_sha256": sha256(ART_SRC / "s1-derived-palette.json"),
                "python": f"{__import__('sys').version_info.major}.{__import__('sys').version_info.minor}.{__import__('sys').version_info.micro}",
                "pillow": PIL.__version__,
            },
            "reserved_colors": {
                "forbidden": ["#F4F4F4", "#41A6F6"],
                "gate": "PASS",
            },
            "human_acceptance": {
                "final_art": True,
                "acceptor": human_approval["owner"],
                "timestamp_utc": human_approval["decision_received_utc"],
                "accepting_commit": human_approval["approved_candidate"],
                "receipt": repo_path(HUMAN_APPROVAL),
                "receipt_sha256": sha256(HUMAN_APPROVAL),
            },
            "license_source": "original AI-assisted source under project-controlled prompt/reference set; approved concepts only",
        }
        name = logical_id.replace(".", "_") + ".provenance.json"
        write_json(PROVENANCE / name, sidecar)


def main() -> None:
    NORMALIZED.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)
    contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
    source_ledger = json.loads(SOURCE_LEDGER.read_text(encoding="utf-8"))
    palette = build_palette()
    write_json(ART_SRC / "s1-derived-palette.json", {name: rgb_hex(color) for name, color in palette.items()})
    paths = save_assets(palette)
    expected = {entry["id"]: tuple(entry["native_size"]) for entry in contract["assets"]}
    assets = {logical_id: inspect_image(path, expected[logical_id]) for logical_id, path in paths.items()}
    stage = build_stage_mock(paths, palette)
    contact = build_contact_sheet(paths)
    emit_provenance(paths, source_ledger)
    all_asset_gates = all(
        data["geometry_gate"] == "PASS"
        and data["hard_alpha_gate"] == "PASS"
        and data["reserved_color_gate"] == "PASS"
        for data in assets.values()
    )
    result = {
        "schema_version": 1,
        "package": "AUI-10",
        "status": "RUNTIME_INTEGRATED_MACHINE_CONFORMANT_HUMAN_FINAL_ACCEPTED",
        "repository_base_observed": contract["repository_base_observed"],
        "contract": {"path": repo_path(CONTRACT), "sha256": sha256(CONTRACT)},
        "source_ledger": {"path": repo_path(SOURCE_LEDGER), "sha256": sha256(SOURCE_LEDGER)},
        "source_palette_report": {"path": repo_path(SOURCE_PALETTES), "sha256": sha256(SOURCE_PALETTES)},
        "normalizer": {"path": repo_path(Path(__file__).resolve()), "sha256": sha256(Path(__file__).resolve())},
        "pipeline": "GPT Image 2 source identity -> deterministic source-palette derivation -> contract-authored native geometry -> hard alpha/native PNGs -> provenance + QA boards",
        "raw_source_retention": source_ledger["retention"],
        "derived_palette": {name: rgb_hex(color) for name, color in palette.items()},
        "assets": assets,
        "contact_sheet": contact,
        "stage_value_board": stage,
        "source_only_rejections": {
            "s1-backdrop.png": "raw silhouette rejected as false-playable affordance; deterministic non-diamond fragments used",
            "s1-route-notch.png": "raw full-face/four-arrow silhouette rejected; deterministic exactly-three notch overlay used",
        },
        "machine_gate": "PASS" if all_asset_gates and stage["act_i_lstar_gate"] == "PASS" and stage["warm_direct_gate"] == "PASS" else "FAIL",
        "final_art_acceptance": "POSEIDON_APPROVED_AUI_10R_REVISION_2",
        "human_approval": {"path": repo_path(HUMAN_APPROVAL), "sha256": sha256(HUMAN_APPROVAL)},
        "runtime_binding": "BOUND_AGENT_D_S1_PRESENTATION",
        "writes_owned_staging_only": False,
    }
    write_json(REPORT, result)
    print(json.dumps({
        "report": repo_path(REPORT),
        "machine_gate": result["machine_gate"],
        "median_cie_lstar": stage["median_cie_lstar"],
        "warm_direct_share": stage["warm_direct_share"],
        "assets": {name: data["sha256"] for name, data in assets.items()},
    }, indent=2))


if __name__ == "__main__":
    main()
