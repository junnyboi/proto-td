#!/usr/bin/env python3
"""Build reviewed GPT Image 2 premium portraits into Godot runtime assets.

The 1920x1920 generated sources remain immutable under docs/. This builder
writes one 512x512 Field Team/Training identity portrait and one top-biased
640x800 Premium Resonance derivative per canonical premium hero, then records
stable hashes and an inspection catalog.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "docs/portraits/premium/sources"
RUNTIME_DIR = ROOT / "assets/portraits/premium"
FULLSIZE_DIR = ROOT / "assets/portraits/fullsize"
REPORT_PATH = ROOT / "docs/portraits/premium/ASSET_REPORT.json"
CHECKSUM_PATH = ROOT / "docs/portraits/premium/SHA256SUMS"
CATALOG_PATH = ROOT / "docs/portraits/premium/CATALOG.png"
SOURCE_SIZE = (1920, 1920)
RUNTIME_SIZE = (512, 512)
FULLSIZE_SIZE = (640, 800)
FULLSIZE_SUBJECT_SIZE = (640, 640)
FULLSIZE_TOP = 0

HEROES = (
    "archive_caster",
    "lunaris_vessel",
    "reliquary_duelist",
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_one(hero_id: str) -> dict[str, object]:
    source_path = SOURCE_DIR / f"{hero_id}.png"
    runtime_path = RUNTIME_DIR / f"{hero_id}.png"
    fullsize_path = FULLSIZE_DIR / f"{hero_id}_fullsize.webp"
    if not source_path.is_file():
        raise FileNotFoundError(source_path)

    source = Image.open(source_path).convert("RGB")
    if source.size != SOURCE_SIZE:
        raise RuntimeError(f"source must be exactly {SOURCE_SIZE}: {source_path} is {source.size}")

    runtime_path.parent.mkdir(parents=True, exist_ok=True)
    runtime = source.resize(RUNTIME_SIZE, Image.Resampling.LANCZOS)
    runtime.save(runtime_path, format="PNG", optimize=True)

    # Preserve every focus/weapon extremity in a 4:5 compatibility derivative.
    # Primary screens use the square identity directly; this top-biased file
    # remains for backward-compatible consumers that require the legacy shape.
    fullsize_path.parent.mkdir(parents=True, exist_ok=True)
    fullsize = Image.new("RGB", FULLSIZE_SIZE, (7, 8, 18))
    subject = source.resize(FULLSIZE_SUBJECT_SIZE, Image.Resampling.LANCZOS)
    fullsize.paste(subject, (0, FULLSIZE_TOP))
    fullsize.save(fullsize_path, format="WEBP", lossless=True, method=6)

    return {
        "hero_id": hero_id,
        "generator": "GPT Image 2",
        "source": str(source_path.relative_to(ROOT)),
        "source_size": list(source.size),
        "source_sha256": sha256(source_path),
        "runtime": str(runtime_path.relative_to(ROOT)),
        "runtime_size": list(runtime.size),
        "runtime_sha256": sha256(runtime_path),
        "resonance": str(fullsize_path.relative_to(ROOT)),
        "resonance_size": list(fullsize.size),
        "resonance_sha256": sha256(fullsize_path),
        "resonance_subject_top": FULLSIZE_TOP,
    }


def build_catalog() -> None:
    gap = 24
    catalog = Image.new(
        "RGB",
        (RUNTIME_SIZE[0] * len(HEROES) + gap * (len(HEROES) - 1), RUNTIME_SIZE[1]),
        (8, 9, 19),
    )
    for index, hero_id in enumerate(HEROES):
        image = Image.open(RUNTIME_DIR / f"{hero_id}.png").convert("RGB")
        catalog.paste(image, (index * (RUNTIME_SIZE[0] + gap), 0))
    catalog.save(CATALOG_PATH, format="PNG", optimize=True)


def main() -> None:
    expected = {f"{hero_id}.png" for hero_id in HEROES}
    actual = {path.name for path in SOURCE_DIR.glob("*.png")}
    if expected != actual:
        raise RuntimeError(
            f"premium source matrix mismatch; missing={sorted(expected - actual)}, "
            f"unexpected={sorted(actual - expected)}"
        )

    records = [build_one(hero_id) for hero_id in HEROES]
    source_hashes = [str(record["source_sha256"]) for record in records]
    runtime_hashes = [str(record["runtime_sha256"]) for record in records]
    if len(source_hashes) != len(set(source_hashes)):
        raise RuntimeError("GPT Image 2 premium sources are not unique by SHA-256")
    if len(runtime_hashes) != len(set(runtime_hashes)):
        raise RuntimeError("premium runtime portraits are not unique by SHA-256")

    build_catalog()
    report = {
        "schema_version": 1,
        "generator": "GPT Image 2",
        "hero_count": len(records),
        "source_size": list(SOURCE_SIZE),
        "runtime_size": list(RUNTIME_SIZE),
        "resonance_size": list(FULLSIZE_SIZE),
        "records": records,
    }
    REPORT_PATH.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    checksum_paths = sorted(
        list(SOURCE_DIR.glob("*.png"))
        + list(RUNTIME_DIR.glob("*.png"))
        + [FULLSIZE_DIR / f"{hero_id}_fullsize.webp" for hero_id in HEROES]
        + [CATALOG_PATH]
    )
    CHECKSUM_PATH.write_text(
        "".join(f"{sha256(path)}  {path.relative_to(ROOT)}\n" for path in checksum_paths),
        encoding="utf-8",
    )
    print(f"built {len(records)} premium identity portraits and {len(records)} Resonance derivatives")


if __name__ == "__main__":
    main()
