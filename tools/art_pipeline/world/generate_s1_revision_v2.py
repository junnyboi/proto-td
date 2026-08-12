#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import shutil
from pathlib import Path

import PIL
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parents[3]
ART_SRC = REPO / "art-src/world/s1"
STAGING = REPO / "staging/assets/world/s1"
STAGING_PROVENANCE = REPO / "staging/provenance/world/s1"
RUNTIME = REPO / "assets/world/s1"
RUNTIME_PROVENANCE = REPO / "assets/provenance/world/s1"
QA = REPO / "staging/qa/world/s1"
CONTRACT = ART_SRC / "s1-world-asset-contract.json"
PALETTE = ART_SRC / "s1-derived-palette.json"
APPROVAL = REPO / "docs/media/AUI-DESIGN-D-REVISION-CORE-C-BACKDROP-B.json"
PANORAMA_SOURCE = ART_SRC / "s1-alpine-escarpment-source.png"
NORMALIZATION_REPORT = QA / "normalization-report.json"
REVISION_REPORT = QA / "revision-v2-report.json"
RESERVED = {(244, 244, 244): "#F4F4F4", (65, 166, 246): "#41A6F6"}

SPECS = {
    "world.s1.backdrop": ("s1-backdrop.png", (32, 16), "backdrop_b"),
    "world.s1.backdrop_ridge": ("s1-backdrop-ridge.png", (32, 24), "backdrop_b"),
    "world.s1.backdrop_peak": ("s1-backdrop-peak.png", (32, 32), "backdrop_b"),
    "world.s1.backdrop_mist": ("s1-backdrop-mist.png", (32, 16), "backdrop_b"),
    "world.s1.backdrop_panorama": ("s1-backdrop-panorama.png", (208, 104), "backdrop_b_production"),
    "world.s1.core_landmark": ("s1-core-landmark.png", (32, 32), "core_c"),
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def repo_path(path: Path) -> str:
    return path.relative_to(REPO).as_posix()


def read_json(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))


def rgba(value: tuple[int, int, int]) -> tuple[int, int, int, int]:
    return value[0], value[1], value[2], 255


def colors() -> dict[str, tuple[int, int, int]]:
    base = {name: rgb(value) for name, value in read_json(PALETTE).items()}
    base.update(
        {
            "mountain_deep": (45, 48, 51),
            "mountain_dark": (59, 61, 60),
            "mountain_mid": (78, 78, 72),
            "mountain_light": (101, 98, 87),
            "mountain_moss": (73, 80, 61),
            "mist_dark": (83, 88, 91),
            "mist_mid": (112, 117, 118),
            "storm_dark": (68, 112, 111),
            "storm_light": (130, 181, 174),
        }
    )
    collisions = {name: value for name, value in base.items() if value in RESERVED}
    if collisions:
        raise RuntimeError(f"reserved-color collision in revision palette: {collisions}")
    return base


def build_foothill(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    image = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    profile = [(0, 15), (0, 11), (5, 8), (9, 10), (13, 5), (17, 7), (22, 4), (27, 8), (31, 6), (31, 15)]
    draw.polygon(profile, fill=rgba(p["mountain_dark"]))
    draw.line(profile[1:-1], fill=rgba(p["outline"]), width=1)
    draw.polygon([(3, 12), (8, 9), (12, 11), (8, 15), (2, 15)], fill=rgba(p["mountain_mid"]))
    draw.polygon([(14, 9), (21, 5), (27, 10), (25, 15), (15, 15)], fill=rgba(p["mountain_deep"]))
    draw.line((4, 13, 9, 11, 12, 12), fill=rgba(p["mountain_light"]), width=1)
    for point in ((6, 8), (19, 7), (25, 9), (29, 7)):
        draw.point(point, fill=rgba(p["mountain_moss"]))
    return image


def build_ridge(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    image = Image.new("RGBA", (32, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    profile = [(0, 23), (0, 14), (4, 11), (7, 12), (11, 6), (15, 9), (19, 4), (23, 10), (27, 8), (31, 12), (31, 23)]
    draw.polygon(profile, fill=rgba(p["mountain_dark"]))
    draw.line(profile[1:-1], fill=rgba(p["outline"]), width=1)
    draw.polygon([(1, 17), (8, 12), (14, 15), (12, 23), (1, 23)], fill=rgba(p["mountain_mid"]))
    draw.polygon([(13, 14), (19, 5), (24, 12), (28, 23), (12, 23)], fill=rgba(p["mountain_deep"]))
    draw.line((4, 18, 10, 15, 14, 16), fill=rgba(p["mountain_light"]), width=1)
    draw.line((18, 11, 21, 8, 24, 13), fill=rgba(p["mountain_mid"]), width=1)
    draw.line((3, 20, 12, 20), fill=rgba(p["outline"]), width=1)
    draw.line((17, 18, 29, 18), fill=rgba(p["outline"]), width=1)
    for point in ((5, 12), (9, 11), (26, 9), (28, 10)):
        draw.point(point, fill=rgba(p["mountain_moss"]))
    return image


def build_peak(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    image = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    silhouette = [(0, 31), (2, 22), (7, 18), (10, 12), (13, 14), (17, 3), (20, 9), (23, 7), (27, 18), (31, 23), (31, 31)]
    draw.polygon(silhouette, fill=rgba(p["mountain_dark"]))
    draw.line(silhouette[1:-1], fill=rgba(p["outline"]), width=1)
    draw.polygon([(1, 31), (8, 19), (13, 15), (16, 31)], fill=rgba(p["mountain_mid"]))
    draw.polygon([(16, 31), (17, 4), (23, 9), (31, 31)], fill=rgba(p["mountain_deep"]))
    draw.polygon([(13, 14), (17, 4), (20, 10), (17, 9)], fill=rgba(p["mountain_light"]))
    draw.line((5, 25, 12, 21, 15, 22), fill=rgba(p["mountain_light"]), width=1)
    draw.line((19, 17, 25, 14, 28, 20), fill=rgba(p["mountain_mid"]), width=1)
    draw.line((2, 28, 14, 28), fill=rgba(p["outline"]), width=1)
    draw.line((18, 25, 31, 25), fill=rgba(p["outline"]), width=1)
    for point in ((6, 20), (9, 18), (25, 16), (27, 18)):
        draw.point(point, fill=rgba(p["mountain_moss"]))
    return image


def build_mist(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    image = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.polygon([(0, 13), (3, 9), (8, 10), (11, 6), (16, 8), (20, 5), (25, 8), (29, 7), (31, 10), (31, 15), (0, 15)], fill=rgba(p["mist_dark"]))
    draw.polygon([(2, 13), (7, 10), (12, 11), (16, 8), (20, 10), (25, 8), (30, 11), (30, 14), (2, 14)], fill=rgba(p["mist_mid"]))
    draw.line((0, 14, 8, 12, 15, 13, 23, 11, 31, 12), fill=rgba(p["mountain_light"]), width=1)
    for x, y in ((5, 10), (14, 9), (22, 8), (28, 9)):
        draw.rectangle((x, y, x + 2, y + 1), fill=rgba(p["mist_mid"]))
    return image


def build_panorama(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    image = Image.new("RGBA", (384, 216), rgba(p["backdrop_void"]))
    draw = ImageDraw.Draw(image)
    # Distant angular horizon, kept darker than the playable limestone.
    distant = [
        (0, 84), (18, 54), (31, 67), (49, 38), (65, 63), (86, 30),
        (104, 58), (126, 25), (147, 62), (168, 36), (192, 70),
        (215, 32), (238, 61), (260, 27), (282, 56), (306, 34),
        (329, 67), (351, 40), (384, 76), (384, 126), (0, 126),
    ]
    draw.polygon(distant, fill=rgba(p["mountain_deep"]))
    draw.line(distant[:-2], fill=rgba(p["outline"]), width=1)
    # Mid ridge shelves establish the selected alpine-escarpment identity.
    left_mid = [
        (0, 118), (13, 92), (38, 82), (60, 95), (81, 76),
        (105, 99), (126, 86), (151, 111), (151, 157), (0, 157),
    ]
    right_mid = [
        (233, 111), (255, 88), (279, 96), (302, 73), (326, 94),
        (349, 82), (373, 99), (384, 91), (384, 158), (233, 158),
    ]
    draw.polygon(left_mid, fill=rgba(p["mountain_dark"]))
    draw.polygon(right_mid, fill=rgba(p["mountain_dark"]))
    draw.line(left_mid[:-2], fill=rgba(p["outline"]), width=1)
    draw.line(right_mid[:-2], fill=rgba(p["outline"]), width=1)
    # Cloud-filled ravines are opaque hard-pixel bands, never soft gradients.
    draw.polygon(
        [(0, 124), (38, 115), (77, 123), (113, 112), (157, 124), (202, 116),
         (247, 126), (289, 114), (333, 123), (384, 116), (384, 143), (0, 143)],
        fill=rgba(p["mist_dark"]),
    )
    draw.polygon(
        [(0, 134), (55, 128), (101, 137), (152, 129), (207, 138),
         (263, 130), (322, 139), (384, 132), (384, 149), (0, 149)],
        fill=rgba(p["mist_mid"]),
    )
    # Near framing cliffs leave the central battlefield area visually quiet.
    left_near = [
        (0, 112), (24, 103), (50, 116), (71, 145), (87, 177),
        (68, 216), (0, 216),
    ]
    right_near = [
        (384, 105), (360, 112), (337, 135), (318, 171), (313, 216),
        (384, 216),
    ]
    draw.polygon(left_near, fill=rgba(p["mountain_mid"]))
    draw.polygon(right_near, fill=rgba(p["mountain_mid"]))
    draw.line(left_near[:-2], fill=rgba(p["outline"]), width=2)
    draw.line(right_near[:-2], fill=rgba(p["outline"]), width=2)
    # Broken lower escarpment shelves and strata; no diamond/grid affordances.
    draw.polygon(
        [(0, 189), (38, 174), (78, 187), (118, 180), (151, 195),
         (193, 184), (231, 197), (271, 181), (316, 192), (354, 178),
         (384, 191), (384, 216), (0, 216)],
        fill=rgba(p["mountain_dark"]),
    )
    for x, y, span in ((6, 155, 49), (19, 171, 42), (326, 154, 47), (338, 171, 38),
                       (42, 199, 58), (119, 204, 44), (230, 205, 57), (301, 198, 52)):
        draw.line((x, y, x + span, y), fill=rgba(p["outline"]), width=2)
        draw.line((x + 4, y - 2, x + span - 7, y - 2), fill=rgba(p["mountain_light"]), width=1)
    # Sparse hardy trees and shrubs provide scale without competing with units.
    for x, y in ((21, 98), (54, 113), (83, 88), (292, 91), (329, 110), (362, 94),
                 (33, 180), (74, 193), (310, 187), (353, 175)):
        draw.line((x, y, x, y + 7), fill=rgba(p["outline"]), width=1)
        draw.polygon([(x, y - 7), (x - 3, y), (x + 3, y)], fill=rgba(p["mountain_moss"]))
        draw.polygon([(x, y - 4), (x - 4, y + 3), (x + 4, y + 3)], fill=rgba(p["mountain_moss"]))
    # Thin rim lights preserve layered silhouettes at the dark-value floor.
    draw.line((0, 118, 38, 83, 80, 96, 126, 87, 151, 111), fill=rgba(p["mountain_light"]), width=1)
    draw.line((233, 111, 279, 97, 302, 74, 349, 83, 384, 92), fill=rgba(p["mountain_light"]), width=1)
    # Exact native crop corresponding to S1's 416x208 runtime diamond bounds.
    # Mountains now occupy visible corner space instead of sitting beyond the
    # map-fit viewport where they would render honestly but never be seen.
    return image.crop((88, 56, 296, 160))


def build_source_panorama(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    if not PANORAMA_SOURCE.is_file():
        raise FileNotFoundError(f"missing approved panorama source: {PANORAMA_SOURCE}")
    with Image.open(PANORAMA_SOURCE) as source:
        small = source.convert("RGB").resize((208, 104), Image.Resampling.BOX)
    allowed = [
        p["backdrop_void"],
        p["outline"],
        p["mountain_deep"],
        p["mountain_dark"],
        p["mountain_mid"],
        p["mountain_light"],
        p["mountain_moss"],
        p["mist_dark"],
        p["mist_mid"],
        p["metal_dark"],
        p["metal_mid"],
        p["water_mid"],
    ]
    palette_image = Image.new("P", (1, 1))
    flat_palette = [channel for color in allowed for channel in color]
    flat_palette.extend([0] * (768 - len(flat_palette)))
    palette_image.putpalette(flat_palette)
    quantized = small.quantize(
        palette=palette_image,
        dither=Image.Dither.NONE,
    )
    return quantized.convert("RGBA")


def build_orrery(p: dict[str, tuple[int, int, int]]) -> Image.Image:
    image = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    # Isometric masonry plinth and two low buttresses.
    draw.polygon([(5, 26), (16, 21), (27, 26), (16, 31)], fill=rgba(p["outline"]))
    draw.polygon([(7, 25), (16, 22), (25, 25), (16, 29)], fill=rgba(p["ground_mid"]))
    draw.polygon([(7, 25), (16, 29), (16, 31), (6, 27)], fill=rgba(p["ceramic_dark"]))
    draw.polygon([(16, 29), (25, 25), (26, 27), (16, 31)], fill=rgba(p["metal_dark"]))
    draw.rectangle((3, 24, 8, 28), fill=rgba(p["outline"]))
    draw.rectangle((4, 24, 7, 26), fill=rgba(p["ground_dark"]))
    draw.rectangle((24, 24, 29, 28), fill=rgba(p["outline"]))
    draw.rectangle((25, 24, 28, 26), fill=rgba(p["ground_dark"]))
    # Three open brass arcs: strong negative space, never a pressure vessel.
    arcs = [
        [(23, 2), (16, 2), (9, 5), (5, 10), (4, 16), (7, 21), (13, 24)],
        [(22, 6), (16, 5), (11, 7), (8, 11), (8, 16), (11, 20), (16, 22)],
        [(20, 9), (16, 8), (13, 10), (12, 14), (13, 18), (17, 20)],
    ]
    for points in arcs:
        draw.line(points, fill=rgba(p["outline"]), width=3, joint="curve")
        draw.line(points, fill=rgba(p["bronze_light"]), width=1, joint="curve")
    # Uprights connect the open arcs to the plinth.
    draw.line((13, 24, 13, 27), fill=rgba(p["outline"]), width=3)
    draw.line((13, 24, 13, 27), fill=rgba(p["bronze_mid"]), width=1)
    draw.line((21, 20, 21, 26), fill=rgba(p["outline"]), width=3)
    draw.line((21, 20, 21, 26), fill=rgba(p["bronze_mid"]), width=1)
    # Suspended angular cloudstone with muted non-reserved cyan fissure.
    draw.line((18, 8, 18, 11), fill=rgba(p["outline"]), width=1)
    stone = [(18, 10), (22, 14), (19, 19), (14, 16), (14, 12)]
    draw.polygon(stone, fill=rgba(p["outline"]))
    draw.polygon([(18, 11), (21, 14), (18, 17), (15, 15), (15, 12)], fill=rgba(p["metal_light"]))
    draw.line((16, 13, 18, 14, 17, 16, 19, 17), fill=rgba(p["storm_light"]), width=1)
    draw.point((20, 14), fill=rgba(p["storm_dark"]))
    return image


def inspect(path: Path, expected: tuple[int, int]) -> dict[str, object]:
    with Image.open(path) as source:
        image = source.convert("RGBA")
        partial = 0
        opaque = 0
        reserved = {label: 0 for label in RESERVED.values()}
        for red, green, blue, alpha in image.get_flattened_data():
            if 0 < alpha < 255:
                partial += 1
            if alpha == 255:
                opaque += 1
                if (red, green, blue) in RESERVED:
                    reserved[RESERVED[(red, green, blue)]] += 1
        return {
            "path": repo_path(path),
            "sha256": sha256(path),
            "size": list(image.size),
            "expected_size": list(expected),
            "geometry_gate": "PASS" if image.size == expected else "FAIL",
            "hard_alpha_gate": "PASS" if partial == 0 else "FAIL",
            "partial_alpha_pixels": partial,
            "opaque_pixels": opaque,
            "opaque_bbox": list(image.getbbox()) if image.getbbox() else None,
            "reserved_exact_pixel_counts": reserved,
            "reserved_color_gate": "PASS" if sum(reserved.values()) == 0 else "FAIL",
        }


def provenance(logical_id: str, path: Path, runtime: bool) -> dict[str, object]:
    approval = read_json(APPROVAL)
    _, _, concept_key = SPECS[logical_id]
    concept = approval["gpt_image_2_concepts"][concept_key]
    prompt = approval["gpt_image_2_concepts"]["prompt_contract"]
    raw_source = {
        "retention": "external owner-approval archive",
        "file": concept["external_filename"],
        "sha256": concept["sha256"],
        "acceptance_state": "POSEIDON_APPROVED_CONCEPT_DIRECTION",
    }
    if "repository_source" in concept:
        repository_source = REPO / concept["repository_source"]
        if sha256(repository_source) != concept["repository_source_sha256"]:
            raise RuntimeError("approved panorama repository-source hash mismatch")
        raw_source["repository_source"] = concept["repository_source"]
        raw_source["repository_source_sha256"] = concept["repository_source_sha256"]
    return {
        "schema_version": 1,
        "logical_id": logical_id,
        "state": (
            "RUNTIME_INTEGRATED_MACHINE_CONFORMANT_HUMAN_FINAL_UNSET"
            if runtime
            else "STAGED_MACHINE_CONFORMANT_HUMAN_FINAL_UNSET"
        ),
        "final_file": repo_path(path),
        "final_file_sha256": sha256(path),
        "raw_source": raw_source,
        "placement_state": (
            "RUNTIME_BOUND_PRESENTATION_ONLY"
            if runtime
            else "STAGED_PRESENTATION_ROLE_DEFINED"
        ),
        "approval_packet": {
            "token": "AUI-DESIGN-D",
            "revision_token": approval["approval_token"],
            "receipt": repo_path(APPROVAL),
            "receipt_sha256": sha256(APPROVAL),
            "verified": True,
        },
        "generator": {
            "tool": "manus-tools/generate_image",
            "model": "gpt-image-2",
            "seed": None,
            "seed_reason": "service does not expose a stable seed; accepted concept is hash-pinned",
            "prompt_contract": prompt["external_filename"],
            "prompt_contract_sha256": prompt["sha256"],
            "prompt_section": "Cloud-Seal Orrery" if concept_key == "core_c" else "Alpine Escarpment",
            "approved_reference_hashes": [concept["sha256"]],
            "approval_manifest": repo_path(APPROVAL),
            "approval_manifest_sha256": sha256(APPROVAL),
        },
        "normalization": {
            "recipe": "owner-approved GPT Image 2 concept -> contract-authored native pixel synthesis -> hard alpha",
            "tool": repo_path(Path(__file__).resolve()),
            "tool_sha256": sha256(Path(__file__).resolve()),
            "asset_contract": repo_path(CONTRACT),
            "asset_contract_sha256": sha256(CONTRACT),
            "derived_palette": repo_path(PALETTE),
            "derived_palette_sha256": sha256(PALETTE),
            "python": f"{__import__('sys').version_info.major}.{__import__('sys').version_info.minor}.{__import__('sys').version_info.micro}",
            "pillow": PIL.__version__,
        },
        "reserved_colors": {
            "forbidden": ["#F4F4F4", "#41A6F6"],
            "gate": "PASS",
        },
        "human_acceptance": {
            "final_art": False,
            "acceptor": None,
            "timestamp_utc": None,
            "accepting_commit": None,
        },
        "license_source": "original AI-assisted concept under project-controlled prompt/reference set; deterministic native synthesis",
    }


def refresh_existing_sidecars() -> None:
    contract_hash = sha256(CONTRACT)
    for root in (STAGING_PROVENANCE, RUNTIME_PROVENANCE):
        if not root.is_dir():
            continue
        for path in root.glob("*.provenance.json"):
            sidecar = read_json(path)
            if sidecar.get("logical_id") in SPECS:
                continue
            normalization = sidecar.setdefault("normalization", {})
            normalization["asset_contract"] = repo_path(CONTRACT)
            normalization["asset_contract_sha256"] = contract_hash
            write_json(path, sidecar)


def contact_sheet(paths: dict[str, Path]) -> dict[str, object]:
    card_w, card_h = 240, 240
    sheet = Image.new("RGBA", (card_w * len(paths), card_h), (24, 26, 31, 255))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, (logical_id, path) in enumerate(paths.items()):
        with Image.open(path) as source:
            image = source.convert("RGBA")
            scale = max(1, min(6, (card_w - 20) // image.width, (card_h - 55) // image.height))
            up = image.resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST)
        x = index * card_w + (card_w - up.width) // 2
        y = 35 + (card_h - 45 - up.height) // 2
        sheet.alpha_composite(up, (x, y))
        draw.text((index * card_w + 8, 8), logical_id, fill=(220, 216, 202, 255), font=font)
    path = QA / "s1-revision-v2-contact-sheet.png"
    sheet.save(path)
    return {"path": repo_path(path), "sha256": sha256(path), "size": list(sheet.size)}


def main() -> None:
    for directory in (STAGING, STAGING_PROVENANCE, RUNTIME, RUNTIME_PROVENANCE, QA):
        directory.mkdir(parents=True, exist_ok=True)
    p = colors()
    images = {
        "world.s1.backdrop": build_foothill(p),
        "world.s1.backdrop_ridge": build_ridge(p),
        "world.s1.backdrop_peak": build_peak(p),
        "world.s1.backdrop_mist": build_mist(p),
        "world.s1.backdrop_panorama": build_source_panorama(p),
        "world.s1.core_landmark": build_orrery(p),
    }
    staging_paths: dict[str, Path] = {}
    runtime_paths: dict[str, Path] = {}
    for logical_id, image in images.items():
        filename, _, _ = SPECS[logical_id]
        staging_path = STAGING / filename
        runtime_path = RUNTIME / filename
        image.save(staging_path, format="PNG", optimize=False, compress_level=9)
        shutil.copy2(staging_path, runtime_path)
        staging_paths[logical_id] = staging_path
        runtime_paths[logical_id] = runtime_path

    refresh_existing_sidecars()
    for logical_id, path in staging_paths.items():
        sidecar_name = logical_id.replace(".", "_") + ".provenance.json"
        write_json(STAGING_PROVENANCE / sidecar_name, provenance(logical_id, path, False))
        write_json(
            RUNTIME_PROVENANCE / sidecar_name,
            provenance(logical_id, runtime_paths[logical_id], True),
        )

    contract = read_json(CONTRACT)
    expected = {entry["id"]: tuple(entry["native_size"]) for entry in contract["assets"]}
    all_staging = {
        entry["id"]: STAGING / entry["id"].replace("world.s1.", "s1-").replace("_", "-")
        for entry in contract["assets"]
    }
    all_staging = {logical_id: path.with_suffix(".png") for logical_id, path in all_staging.items()}
    inspected = {logical_id: inspect(path, expected[logical_id]) for logical_id, path in all_staging.items()}
    all_pass = all(
        data["geometry_gate"] == "PASS"
        and data["hard_alpha_gate"] == "PASS"
        and data["reserved_color_gate"] == "PASS"
        and data["opaque_pixels"] > 0
        for data in inspected.values()
    )
    legacy = read_json(NORMALIZATION_REPORT)
    legacy["status"] = "RUNTIME_INTEGRATED_MACHINE_CONFORMANT_HUMAN_FINAL_UNSET"
    legacy["contract"] = {"path": repo_path(CONTRACT), "sha256": sha256(CONTRACT)}
    legacy["normalizer"] = {
        "path": repo_path(Path(__file__).resolve()),
        "sha256": sha256(Path(__file__).resolve()),
    }
    legacy["pipeline"] = "GPT Image 2 owner-approved concepts -> deterministic contract-native synthesis -> hard alpha/runtime PNGs -> provenance + QA"
    legacy["assets"] = inspected
    legacy["contact_sheet"] = contact_sheet(staging_paths)
    legacy["machine_gate"] = "PASS" if all_pass else "FAIL"
    legacy["final_art_acceptance"] = "UNSET_HUMAN_ONLY"
    legacy["runtime_binding"] = "BOUND_AGENT_D_S1_PRESENTATION"
    legacy["writes_owned_staging_only"] = False
    write_json(NORMALIZATION_REPORT, legacy)

    report = {
        "schema_version": 1,
        "package": "AUI-10R-REVISION-2",
        "status": "RUNTIME_INTEGRATED_MACHINE_CONFORMANT_HUMAN_FINAL_UNSET",
        "approval_manifest": {"path": repo_path(APPROVAL), "sha256": sha256(APPROVAL)},
        "asset_contract": {"path": repo_path(CONTRACT), "sha256": sha256(CONTRACT)},
        "generator": {"path": repo_path(Path(__file__).resolve()), "sha256": sha256(Path(__file__).resolve())},
        "assets": {logical_id: inspect(path, SPECS[logical_id][1]) for logical_id, path in staging_paths.items()},
        "contact_sheet": legacy["contact_sheet"],
        "machine_gate": "PASS" if all_pass else "FAIL",
        "human_final_art": False,
    }
    write_json(REVISION_REPORT, report)
    print(json.dumps({"verdict": report["machine_gate"], "assets": report["assets"]}, indent=2))


if __name__ == "__main__":
    main()
