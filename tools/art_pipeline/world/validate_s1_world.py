#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import subprocess
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[3]
ART_SRC = REPO / "art-src/world/s1"
ASSETS = REPO / "staging/assets/world/s1"
PROVENANCE = REPO / "staging/provenance/world/s1"
PRESENTATION = REPO / "staging/presentation/world/s1/stage-presentation.json"
QA = REPO / "staging/qa/world/s1"
CONTRACT = ART_SRC / "s1-world-asset-contract.json"
SOURCE_LEDGER = ART_SRC / "gpt-image-2-source-ledger.json"
PROMPT_CONTRACT = ART_SRC / "s1-world-gpt-image-2-prompts.md"
DERIVED_PALETTE = ART_SRC / "s1-derived-palette.json"
REPORT = QA / "normalization-report.json"
STAGE = REPO / "data/stages/s1.tres"
RESERVED = {(244, 244, 244): "#F4F4F4", (65, 166, 246): "#41A6F6"}
EXPECTED_NAMES = {
    "world.s1.ground": "s1-ground.png",
    "world.s1.route": "s1-route.png",
    "world.s1.elevated": "s1-elevated.png",
    "world.s1.backdrop": "s1-backdrop.png",
    "world.s1.spawn_landmark": "s1-spawn-landmark.png",
    "world.s1.core_landmark": "s1-core-landmark.png",
    "world.s1.rain_measure": "s1-rain-measure.png",
    "world.s1.route_notch": "s1-route-notch.png",
}
OWNED_ROOTS = (
    ART_SRC,
    ASSETS,
    PROVENANCE,
    PRESENTATION.parent,
    QA,
    REPO / "tools/art_pipeline/world",
    REPO / "docs/art/world",
    REPO / "docs/handoffs/AUI-10-agent-d.md",
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def fail(message: str) -> None:
    raise SystemExit(f"AUI10_FAIL: {message}")


def repo_path(path: Path) -> str:
    return path.relative_to(REPO).as_posix()


def load(path: Path) -> object:
    return json.loads(path.read_text(encoding="utf-8"))


def scan_hygiene() -> None:
    forbidden = (
        "/home/" + "ubuntu/",
        "OPENAI_" + "API_KEY=",
        "g" + "hp_",
        "github_" + "pat_",
        "Bearer " + "sk-",
        "PRIVATE " + "KEY-----",
    )
    for root in OWNED_ROOTS:
        paths = [root] if root.is_file() else list(root.rglob("*"))
        for path in paths:
            if not path.is_file() or path.suffix.lower() in {".png", ".jpg", ".jpeg"}:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            for marker in forbidden:
                if marker in text:
                    fail(f"protected/internal marker {marker!r} in {repo_path(path)}")


def main() -> None:
    contract = load(CONTRACT)
    source_ledger = load(SOURCE_LEDGER)
    report = load(REPORT)
    presentation = load(PRESENTATION)

    gdignore = REPO / "staging/.gdignore"
    if not gdignore.is_file():
        fail("staging/.gdignore is missing; unbound assets could be auto-imported")
    imported_sidecars = sorted((REPO / "staging").rglob("*.import"))
    if imported_sidecars:
        fail(f"unbound staging contains Godot import sidecars: {[repo_path(path) for path in imported_sidecars]}")

    if contract["status"] != "STAGED_IN_AGENT_D_LANE_RUNTIME_UNBOUND":
        fail("asset contract status is not staged/unbound")
    if report["status"] != "STAGED_IN_AGENT_D_LANE_RUNTIME_UNBOUND":
        fail("normalization report status is not staged/unbound")
    if report["machine_gate"] != "PASS":
        fail("normalization machine gate is not PASS")
    if report["final_art_acceptance"] != "UNSET_HUMAN_ONLY":
        fail("human final-art acceptance was inferred")
    if report["runtime_binding"] != "UNBOUND_AGENT_F_SEAM":
        fail("runtime integration seam is not fail-closed")
    if source_ledger["generator"]["model"] != "gpt-image-2":
        fail("source model is not gpt-image-2")
    if source_ledger["generator"]["prompt_contract"] != repo_path(PROMPT_CONTRACT):
        fail("prompt contract path is not portable")
    if source_ledger["generator"]["prompt_contract_sha256"] != sha256(PROMPT_CONTRACT):
        fail("prompt contract hash mismatch")
    if len(source_ledger["sources"]) != 16:
        fail("source ledger must contain eight keyed and eight original records")
    if len({entry["file"] for entry in source_ledger["sources"]}) != 16:
        fail("source ledger filenames are not unique")
    if report["contract"]["sha256"] != sha256(CONTRACT):
        fail("normalization report contract hash mismatch")
    if report["source_ledger"]["sha256"] != sha256(SOURCE_LEDGER):
        fail("normalization report source-ledger hash mismatch")
    normalizer = REPO / report["normalizer"]["path"]
    if report["normalizer"]["sha256"] != sha256(normalizer):
        fail("normalization report tool hash mismatch")

    expected_sizes = {entry["id"]: tuple(entry["native_size"]) for entry in contract["assets"]}
    actual_assets = sorted(ASSETS.glob("*.png"))
    if {path.name for path in actual_assets} != set(EXPECTED_NAMES.values()):
        fail("staged asset filename set differs from the contract")

    asset_hashes: dict[str, str] = {}
    for logical_id, name in EXPECTED_NAMES.items():
        path = ASSETS / name
        with Image.open(path) as source:
            image = source.convert("RGBA")
            if image.size != expected_sizes[logical_id]:
                fail(f"geometry mismatch for {logical_id}: {image.size}")
            opaque = 0
            for r, g, b, a in image.get_flattened_data():
                if 0 < a < 255:
                    fail(f"soft alpha in {logical_id}")
                if a == 255:
                    opaque += 1
                    if (r, g, b) in RESERVED:
                        fail(f"reserved color {RESERVED[(r, g, b)]} in {logical_id}")
            if opaque == 0:
                fail(f"vacuous transparent asset: {logical_id}")
        digest = sha256(path)
        asset_hashes[logical_id] = digest
        if report["assets"][logical_id]["sha256"] != digest:
            fail(f"normalization report hash mismatch for {logical_id}")

    sidecars = sorted(PROVENANCE.glob("*.provenance.json"))
    if len(sidecars) != len(EXPECTED_NAMES):
        fail("provenance coverage is not one-to-one")
    covered: set[str] = set()
    for path in sidecars:
        sidecar = load(path)
        logical_id = sidecar["logical_id"]
        if logical_id not in EXPECTED_NAMES or logical_id in covered:
            fail(f"invalid/duplicate provenance logical id: {logical_id}")
        covered.add(logical_id)
        final_path = ASSETS / EXPECTED_NAMES[logical_id]
        if sidecar["final_file"] != repo_path(final_path):
            fail(f"non-portable final path in {path.name}")
        if sidecar["final_file_sha256"] != asset_hashes[logical_id]:
            fail(f"final hash mismatch in {path.name}")
        if sidecar["generator"]["model"] != "gpt-image-2":
            fail(f"wrong generator in {path.name}")
        if sidecar["generator"]["prompt_contract_sha256"] != sha256(PROMPT_CONTRACT):
            fail(f"prompt hash mismatch in {path.name}")
        if sidecar["normalization"]["tool_sha256"] != sha256(normalizer):
            fail(f"normalizer hash mismatch in {path.name}")
        if sidecar["normalization"]["asset_contract_sha256"] != sha256(CONTRACT):
            fail(f"contract hash mismatch in {path.name}")
        if sidecar["normalization"]["derived_palette_sha256"] != sha256(DERIVED_PALETTE):
            fail(f"palette hash mismatch in {path.name}")
        if sidecar["human_acceptance"]["final_art"] is not False:
            fail(f"human acceptance inferred in {path.name}")
        if sidecar["reserved_colors"]["gate"] != "PASS":
            fail(f"reserved-color gate is not PASS in {path.name}")
    if covered != set(EXPECTED_NAMES):
        fail("missing logical-id provenance coverage")

    stage_sha = sha256(STAGE)
    if presentation["status"] != "STAGED_UNBOUND" or presentation["non_authoritative"] is not True:
        fail("presentation payload is not non-authoritative and fail-closed")
    if presentation["authoritative_stage_resource_sha256"] != stage_sha:
        fail("presentation payload was authored against a different S1 resource")
    for key in ("grid_size", "path", "spawn", "core", "elevated"):
        if presentation["authoritative_geometry"][key] != contract["stage"][key]:
            fail(f"presentation geometry differs from contract: {key}")
    if presentation["generic_prop_anchors"] != []:
        fail("generic prop anchors were guessed")
    if presentation["route_cadence"]["cells"] != [[2, 2], [4, 2], [6, 2]]:
        fail("sparse route cadence contract drifted")

    scan_hygiene()

    status = subprocess.check_output(["git", "status", "--short"], cwd=REPO, text=True).splitlines()
    unexpected = [line for line in status if not any(path in line for path in (
        "art-src/", "staging/", "tools/art_pipeline/", "docs/art/world/", "docs/handoffs/AUI-10-agent-d.md", "docs/todo.md"
    ))]
    if unexpected:
        fail(f"unexpected dirty paths: {unexpected}")

    print(json.dumps({
        "verdict": "PASS",
        "assets": len(actual_assets),
        "provenance_sidecars": len(sidecars),
        "source_records": len(source_ledger["sources"]),
        "median_cie_lstar": report["stage_value_board"]["median_cie_lstar"],
        "warm_direct_share": report["stage_value_board"]["warm_direct_share"],
        "stage_resource_sha256": stage_sha,
        "runtime_binding": "UNBOUND_AGENT_F_SEAM",
        "human_final_art": "UNSET",
    }, indent=2))


if __name__ == "__main__":
    main()
