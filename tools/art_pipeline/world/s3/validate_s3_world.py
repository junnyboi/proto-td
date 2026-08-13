#!/usr/bin/env python3
"""Validate the complete S3 candidate packet without requiring peer code."""
from __future__ import annotations

import argparse
import ast
import hashlib
import json
from pathlib import Path
from PIL import Image

ASSETS = {
    "world.s3.elevated_assay": ("elevated-assay.png", (32, 24), [16, 23]),
    "world.s3.blocked_regulator": ("blocked-regulator.png", (32, 16), [16, 15]),
    "world.s3.blocked_pressure_jaw": ("blocked-pressure-jaw.png", (32, 16), [16, 15]),
    "world.s3.spawn_rain_sluice": ("spawn-rain-sluice.png", (32, 32), [16, 30]),
    "world.s3.core_pressure_keeper": ("core-pressure-keeper.png", (32, 32), [16, 30]),
    "world.s3.backdrop_panorama": ("backdrop-panorama.png", (256, 128), [128, 127]),
}
STATE = "CANDIDATE_MACHINE_CONFORMANT_H1_PENDING"
RESERVED = {(244, 244, 244), (65, 166, 246)}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def exact_names(path: Path, suffix: str) -> set[str]:
    return {p.name for p in path.iterdir() if p.is_file() and p.name.endswith(suffix)}


def validate(root: Path) -> list[str]:
    root = root.resolve(); passed: list[str] = []
    source = root / "art-src/world/s3/s3-production-source.png"
    ledger = json.loads((root / "art-src/world/s3/gpt-image-2-source-ledger.json").read_text())
    contract = json.loads((root / "art-src/world/s3/s3-world-asset-contract.json").read_text())
    palette_doc = json.loads((root / "art-src/world/s3/s3-derived-palette.json").read_text())
    assert source.is_file() and ledger["source_sha256"] == sha256(source)
    assert ledger["model"] == "gpt-image-2" and ledger["generation_id"] is None and ledger["seed"] is None
    assert ledger["approval_token"] == "ACT-II-S2-S3-H0" and ledger["human_final_art"] is False
    assert ledger["state"] == STATE and ledger["approved_content_hash_gates_launch"] is False
    assert contract["asset_count"] == 6 and contract["state"] == STATE
    assert [a["logical_id"] for a in contract["assets"]] == list(ASSETS)
    assert contract["topology"]["path"] == [[0,2],[1,2],[2,2],[3,2],[4,2],[4,3],[4,4],[5,4],[6,4],[7,4],[8,4],[9,4]]
    passed.append("portable ledger/contract truth and exact topology")

    runtime = root / "assets/world/s3"; staging = root / "staging/assets/world/s3"
    expected_pngs = {spec[0] for spec in ASSETS.values()}
    assert exact_names(runtime, ".png") == expected_pngs
    assert exact_names(staging, ".png") == expected_pngs
    allowed = {tuple(int(value[i:i+2], 16) for i in (1,3,5)) for value in palette_doc["colors"].values()}
    source_hash = sha256(source)
    seen_hashes: set[str] = set()
    for logical_id, (filename, size, pivot) in ASSETS.items():
        rp = runtime / filename; sp = staging / filename
        assert rp.read_bytes() == sp.read_bytes()
        assert sha256(rp) != source_hash
        seen_hashes.add(sha256(rp))
        with Image.open(rp) as image:
            assert image.mode == "RGBA" and image.size == size
            pixels = list(image.get_flattened_data()); alpha = {px[3] for px in pixels}
            colors = {px[:3] for px in pixels if px[3]}
            assert alpha <= {0, 255} and not (colors & RESERVED) and colors <= allowed
        prov_name = filename.removesuffix(".png") + ".provenance.json"
        a = root / "assets/provenance/fragments/s3" / prov_name
        b = root / "staging/provenance/world/s3" / prov_name
        assert a.read_bytes() == b.read_bytes()
        record = json.loads(a.read_text())
        assert record["logical_id"] == logical_id and record["state"] == STATE
        assert record["human_final_art"] is False and record["approval"]["approved_content_hash_gates_launch"] is False
        assert record["candidate_files"]["sha256"] == sha256(rp)
        assert record["dimensions"] == list(size) and record["pivot"] == pivot
        assert record["generator"]["model"] == "gpt-image-2"
        assert record["generator"]["source_sha256"] == source_hash
        assert record["generator"]["generation_id"] is None and record["generator"]["seed"] is None
    assert len(seen_hashes) == 6
    passed.append("six unique exact-size hard-alpha palette-constrained assets")
    passed.append("runtime/staging and mirrored provenance bytes match")

    expected_prov = {name.removesuffix(".png") + ".provenance.json" for name in expected_pngs}
    assert exact_names(root / "assets/provenance/fragments/s3", ".json") == expected_prov
    assert exact_names(root / "staging/provenance/world/s3", ".json") == expected_prov
    report = json.loads((root / "staging/qa/world/s3/normalization-report.json").read_text())
    assert report["asset_count"] == 6 and report["state"] == STATE and report["human_final_art"] is False
    for name in ("s3-contact-sheet.png", "s3-topology-mock.png"):
        with Image.open(root / "staging/qa/world/s3" / name) as image:
            image.verify()
    passed.append("QA report/contact sheet/topology mock present")

    # Source hygiene: source is never copied to publication roots and generator only opens it for palette extraction.
    assert not any(p.name == source.name for base in (runtime, staging) for p in base.rglob("*"))
    normalizer = root / "tools/art_pipeline/world/s3/normalize_s3_world.py"
    tree = ast.parse(normalizer.read_text(encoding="utf-8"))
    source_calls = []
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) and node.name == "source_palette":
            source_calls = [n.func.attr for n in ast.walk(node) if isinstance(n, ast.Call) and isinstance(n.func, ast.Attribute)]
    assert "crop" not in source_calls and "resize" not in source_calls and "paste" not in source_calls and "alpha_composite" not in source_calls
    passed.append("source hygiene: mandatory source is palette/provenance-only, never runtime raster")

    # Semantic shape checks independent of authored metadata.
    reg = (runtime / "blocked-regulator.png").read_bytes(); jaw = (runtime / "blocked-pressure-jaw.png").read_bytes()
    assert reg != jaw
    for filename in ("spawn-rain-sluice.png", "core-pressure-keeper.png"):
        with Image.open(runtime / filename) as endpoint:
            assert all(endpoint.getpixel((x,y))[3] == 0 for x in range(14,19) for y in range(24,32))
    with Image.open(runtime / "backdrop-panorama.png") as pano:
        # A complete native playable diamond would require a 32x16 closed outline; forbid the route bronze
        # palette from forming any long horizontal continuation in the panorama.
        bronze = {tuple(int(palette_doc["colors"][key][i:i+2],16) for i in (1,3,5)) for key in ("bronze_dark","bronze_mid","bronze_light")}
        for y in range(pano.height):
            run = 0
            for x in range(pano.width):
                run = run + 1 if pano.getpixel((x,y))[:3] in bronze else 0
                assert run < 16
    passed.append("distinct sealed blockers, endpoint approach cutouts, no panorama bronze continuation")
    return passed


def main() -> int:
    parser = argparse.ArgumentParser(); parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[4])
    args = parser.parse_args(); passed = validate(args.repo_root)
    print(json.dumps({"status":"PASS","checks":passed}, sort_keys=True)); return 0


if __name__ == "__main__": raise SystemExit(main())
