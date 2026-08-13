#!/usr/bin/env python3
from __future__ import annotations

import argparse
import filecmp
import hashlib
import json
import shutil
import subprocess
import tempfile
import importlib.util
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[4]
NORMALIZER = REPO / "tools/art_pipeline/world/act2_shared/normalize.py"
STATE = "CANDIDATE_MACHINE_CONFORMANT_H1_PENDING"
TOKEN = "ACT-II-S2-S3-H0"
RESERVED = {(244, 244, 244), (65, 166, 246)}
_LINEAGE_SPEC=importlib.util.spec_from_file_location("act2_lineage", REPO/"tools/art_pipeline/world/validate_act2_lineage.py")
assert _LINEAGE_SPEC and _LINEAGE_SPEC.loader
LINEAGE=importlib.util.module_from_spec(_LINEAGE_SPEC); _LINEAGE_SPEC.loader.exec_module(LINEAGE)
EXPECTED = {
    "world.pressure.ground_calm": ("act2-shared", "ground-calm.png", (32, 16)),
    "world.pressure.ground_runoff": ("act2-shared", "ground-runoff.png", (32, 16)),
    "world.pressure.route_plate": ("act2-shared", "route-plate.png", (32, 16)),
    "world.pressure.cadence_e": ("act2-shared", "cadence-e.png", (32, 16)),
    "world.pressure.cadence_s": ("act2-shared", "cadence-s.png", (32, 16)),
    "world.pressure.cadence_e_s": ("act2-shared", "cadence-e-s.png", (32, 16)),
    "world.pressure.cadence_s_e": ("act2-shared", "cadence-s-e.png", (32, 16)),
    "world.s2.elevated_manometer": ("s2", "elevated-manometer.png", (32, 24)),
    "world.s2.elevated_relief": ("s2", "elevated-relief.png", (32, 24)),
    "world.s2.spawn_louver": ("s2", "spawn-louver.png", (32, 32)),
    "world.s2.core_receiver": ("s2", "core-receiver.png", (32, 32)),
    "world.s2.backdrop_panorama": ("s2", "backdrop-panorama.png", (240, 120)),
}
OWNED_PREFIXES = (
    "art-src/world/act2-shared/", "art-src/world/s2/", "staging/assets/world/act2-shared/",
    "staging/assets/world/s2/", "staging/provenance/world/act2-shared/", "staging/provenance/world/s2/",
    "staging/qa/world/act2-shared/", "staging/qa/world/s2/", "assets/world/act2-shared/",
    "assets/world/s2/", "assets/provenance/fragments/act2-shared/", "assets/provenance/fragments/s2/",
    "tools/art_pipeline/world/act2_shared/", "tools/art_pipeline/world/s2/",
    "art-src/world/act2-references/", "art-src/world/s3/", "assets/world/s3/",
    "assets/provenance/fragments/s3/", "staging/assets/world/s3/", "staging/provenance/world/s3/",
    "staging/qa/world/s3/", "tools/art_pipeline/world/s3/", "tools/art_pipeline/world/validate_act2_lineage.py",
    "tools/presentation_qa/act2_candidate_contract_lint.gd", "assets/act2_candidate_manifest.tres",
)

def sha(path: Path) -> str:
    h = hashlib.sha256(); h.update(path.read_bytes()); return h.hexdigest()

def fail(msg: str) -> None:
    raise SystemExit("ACT2_S2_FAIL: " + msg)

def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))

def files(root: Path) -> dict[str, str]:
    return {p.relative_to(root).as_posix(): sha(p) for p in sorted(root.rglob("*")) if p.is_file()}

def check_package(root: Path) -> None:
    LINEAGE.validate(root)
    if len(EXPECTED) != 12: fail("logical inventory is not exactly 12")
    for family in ("act2-shared", "s2"):
        contract = load(root / f"art-src/world/{family}/asset-contract.json")
        ledger = load(root / f"art-src/world/{family}/source-ledger.json")
        if contract["candidate_state"] != STATE or ledger["state"] != STATE: fail("candidate state drift")
        if contract["approval_token"] != TOKEN or ledger["approval_token"] != TOKEN: fail("approval token drift")
        if ledger["human_final_art"] is not False or ledger["approval"]["content_hash_launch_dependency"] is not False: fail("false H1/final dependency claim")
        generator = ledger["generator"]
        if generator["model"] != "gpt-image-2" or generator["provider"] != "Manus built-in image generation" or generator["tool"] != "Manus built-in image generation / generate_image": fail("generator lineage drift")
        if generator["generation_id"] is not None or generator["seed"] is not None: fail("generation ID/seed must remain null")
        if "UNAVAILABLE" not in generator["generation_id_reason"] or "UNAVAILABLE" not in generator["seed_reason"]: fail("unavailable generation facts not truthful")
        source = root / ledger["source"]["path"]
        if not source.is_file() or sha(source) != ledger["source"]["sha256"]: fail("production-source receipt mismatch")
    actual = []
    for logical, (family, name, size) in EXPECTED.items():
        runtime = root / f"assets/world/{family}/{name}"; staged = root / f"staging/assets/world/{family}/{name}"
        actual.append(runtime)
        if not runtime.is_file() or not staged.is_file() or runtime.read_bytes() != staged.read_bytes(): fail(f"runtime/staged byte mismatch: {logical}")
        with Image.open(runtime) as source:
            im = source.convert("RGBA")
            if im.size != size: fail(f"size mismatch: {logical}")
            if not im.getbbox(): fail(f"empty asset: {logical}")
            for r, g, b, a in im.get_flattened_data():
                if a not in (0, 255): fail(f"soft alpha: {logical}")
                if a == 255 and (r, g, b) in RESERVED: fail(f"reserved color: {logical}")
        for provbase in (root / f"assets/provenance/fragments/{family}", root / f"staging/provenance/world/{family}"):
            side = load(provbase / (logical.replace(".", "_") + ".provenance.json"))
            if side["state"] != STATE or side["human_final_art"] is not False: fail(f"provenance state: {logical}")
            if side["final_file_sha256"] != sha(runtime) or side["approval"]["token"] != TOKEN: fail(f"provenance receipt: {logical}")
    for family in ("act2-shared", "s2"):
        expected_names = {name for _, (fam, name, _) in EXPECTED.items() if fam == family}
        if {p.name for p in (root / f"assets/world/{family}").glob("*.png")} != expected_names: fail(f"runtime candidate set drift: {family}")
        if {p.name for p in (root / f"staging/assets/world/{family}").glob("*.png")} != expected_names: fail(f"staged candidate set drift: {family}")
    for endpoint in ("spawn-louver.png", "core-receiver.png"):
        with Image.open(root / f"assets/world/s2/{endpoint}") as src:
            im = src.convert("RGBA")
            if im.getpixel((16, 30))[3] != 255: fail(f"bottom-center contact missing: {endpoint}")
            # Compact envelope and an open approach window immediately above contact.
            if im.getbbox()[0] < 3 or im.getbbox()[2] > 30 or im.getbbox()[3] > 31: fail(f"endpoint envelope not compact: {endpoint}")
            transparent = sum(im.getpixel((x, y))[3] == 0 for y in range(14, 27) for x in range(12, 20))
            if transparent < 45: fail(f"endpoint owner/approach negative space insufficient: {endpoint}")
    report = load(root / "staging/qa/world/s2/normalization-report.json")
    topo = report["topology"]
    if topo["grid"] != [10, 5] or topo["route"] != [[x, 2] for x in range(10)] or topo["elevated"] != [[3, 1], [3, 3]]: fail("S2 topology drift")
    if topo["false_route_in_panorama"] is not False or topo["complete_playable_diamond_in_panorama"] is not False: fail("panorama topology claim drift")
    if not (root / "staging/qa/world/s2/s2-topology-mock.png").is_file(): fail("topology mock absent")
    if len(list((root / "assets/provenance/fragments/act2-shared").glob("*.json"))) != 7: fail("shared provenance count")
    if len(list((root / "assets/provenance/fragments/s2").glob("*.json"))) != 5: fail("S2 provenance count")

def hygiene(root: Path) -> None:
    forbidden = ("/home/" + "ubuntu/", "OPENAI_" + "API_KEY=", "github_" + "pat_", "Bearer " + "sk-", "PRIVATE " + "KEY-----")
    for prefix in OWNED_PREFIXES:
        base = root / prefix
        if not base.exists(): continue
        for path in ([base] if base.is_file() else base.rglob("*")):
            if not path.is_file() or path.suffix.lower() in {".png", ".jpg", ".jpeg", ".pyc"}: continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            for marker in forbidden:
                if marker in text: fail(f"source hygiene marker in {path.relative_to(root)}")
    if list((root / "staging").rglob("*.import")): fail("staging import sidecar present")
    if list((root / "art-src/world/act2-shared").rglob("*.import")) or list((root / "art-src/world/s2").rglob("*.import")): fail("source import sidecar present")

def run_trials() -> dict:
    parent = Path(tempfile.mkdtemp(prefix="act2-s2-trials-"))
    try:
        roots = {n: parent / n for n in ("A", "B", "C")}
        for root in roots.values():
            root.mkdir()
            for family, source_name in (
                ("act2-shared", "act2-shared-production-source.png"),
                ("s2", "s2-production-source.png"),
            ):
                destination = root / f"art-src/world/{family}/{source_name}"
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(REPO / f"art-src/world/{family}/{source_name}", destination)
                for name in ("production-prompt-contract.md", "production-source-selection.json"):
                    shutil.copy2(REPO / f"art-src/world/{family}/{name}", destination.parent / name)
            references=root/"art-src/world/act2-references"; references.mkdir(parents=True,exist_ok=True)
            for reference in (REPO/"art-src/world/act2-references").iterdir(): shutil.copy2(reference,references/reference.name)
            s3base=root/"art-src/world/s3"; s3base.mkdir(parents=True,exist_ok=True)
            for rel in ("production-prompt-contract.md","production-source-selection.json","gpt-image-2-source-ledger.json","s3-production-source.png"):
                shutil.copy2(REPO/f"art-src/world/s3/{rel}",s3base/rel)
            for rel in ("candidates/s3-production-candidate-a.png","candidates/s3-production-candidate-b.png","rejected/s3-pre-lineage-source.png"):
                dest=s3base/rel; dest.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(REPO/f"art-src/world/s3/{rel}",dest)
        subprocess.run(["python3", str(NORMALIZER), "--output-root", str(roots["A"])], check=True, capture_output=True, text=True)
        subprocess.run(["python3", str(NORMALIZER), "--output-root", str(roots["B"])], check=True, capture_output=True, text=True)
        # C contains stale junk in every generated output class; producer must replace it.
        for stale in ("assets/world/s2/stale.png", "assets/provenance/fragments/act2-shared/stale.json", "staging/assets/world/act2-shared/stale.png", "staging/provenance/world/s2/stale.json", "staging/qa/world/s2/stale.txt"):
            p = roots["C"] / stale; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(b"STALE")
        subprocess.run(["python3", str(NORMALIZER), "--output-root", str(roots["C"])], check=True, capture_output=True, text=True)
        for root in roots.values(): check_package(root); hygiene(root)
        a, b, c = files(roots["A"]), files(roots["B"]), files(roots["C"])
        if a != b: fail("clean A/B file sets or bytes differ")
        if a != c: fail("contaminated C was not exact replacement")
        before = files(roots["C"])
        subprocess.run(["python3", str(NORMALIZER), "--output-root", str(roots["C"])], check=True, capture_output=True, text=True)
        if before != files(roots["C"]): fail("second run is not byte-idempotent")
        return {"clean_a_b": "IDENTICAL", "contaminated_c": "REPLACED_EXACTLY", "second_run": "BYTE_NO_OP", "files": len(a)}
    finally:
        shutil.rmtree(parent, ignore_errors=True)

def main() -> None:
    ap = argparse.ArgumentParser(); ap.add_argument("--skip-trials", action="store_true"); args = ap.parse_args()
    check_package(REPO); hygiene(REPO)
    tracked = subprocess.run(["git", "status", "--porcelain"], cwd=REPO, check=True, capture_output=True, text=True).stdout.splitlines()
    unexpected = []
    for line in tracked:
        path = line[3:].split(" -> ")[-1]
        if not any(path == p.rstrip("/") or path.startswith(p) or p.startswith(path.rstrip("/") + "/") for p in OWNED_PREFIXES): unexpected.append(line)
    if unexpected: fail("unexpected dirty paths: " + repr(unexpected))
    result = {"verdict": "PASS", "logical_assets": 12, "source_hygiene": "PASS", "runtime_staged_bytes": "IDENTICAL"}
    if not args.skip_trials: result["trials"] = run_trials()
    print(json.dumps(result, indent=2, sort_keys=True))
if __name__ == "__main__": main()
