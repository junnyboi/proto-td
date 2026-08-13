#!/usr/bin/env python3
"""Verify and reproduce AUI-11's frozen Phase 5 named review gates."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


APPROVED = {
    "f3c338ec52a394e3e02a92bad65ca00e881fd340673ee6c120dec09c86b3b883",
    "db59ac74296fe4cbf6c78a3011bf78cdfd1c7814c576c7f22e8d02853d7135c9",
    "f512c5022533c53c4a84bcfd036a513d13ee5ec2667cba15283dff21fd373ea8",
    "d6db376800af86f300f6fa8ea7c62865ce4c8bb05dadd9dbe9d470776fa22ee9",
    "64039ab91598423982031948fefc30b5f9b2d93b803d51617cb88fcea2aa8dd3",
    "0a13437c7284fac6fbaf9e67be8223443bbdb3e47158a46325d007d691d17667",
}
APPROVAL_TOKEN = "5ab42289310a3176718a2d2c4c70f91aa87041564aaac0c6652bbf3295ece93b"
QA_RELATIVE = Path("staging/qa/character-vfx/aui-11")
BUILDER_RELATIVE = QA_RELATIVE / "build_blind_review_inputs.py"
INPUT_MANIFEST_RELATIVE = QA_RELATIVE / "blind-review-inputs.json"
BLIND_RESULTS_RELATIVE = QA_RELATIVE / "blind-review-results.json"
ORIGINALITY_RESULTS_RELATIVE = QA_RELATIVE / "originality-review-results.json"
OUTPUT_RELATIVE = QA_RELATIVE / "blind-review-inputs"
ATLAS_RELATIVES = {
    "vanguard": Path("staging/character-vfx/aui-11/packets/vanguard_1/aui11-vanguard_1.png"),
    "grunt": Path("staging/character-vfx/aui-11/packets/grunt/aui11-grunt.png"),
    "grunt_charmed": Path("staging/character-vfx/aui-11/packets/grunt_charmed/aui11-grunt_charmed.png"),
}
OUTPUT_NAMES = {
    "grunt_silhouette": "blind-grunt-silhouette.png",
    "state_pair": "blind-grunt-state-pair.png",
    "vanguard_silhouette": "blind-vanguard-silhouette.png",
}
EXPECTED_BLIND = {
    "alpha_role": "allied_operator",
    "alpha_screen_facing": "screen_right",
    "beta_role": "hostile_construct",
    "beta_screen_facing": "screen_right",
    "charmed_side": "left",
}
BLIND_REVIEWER_KEYS = {
    "reviewer_id",
    "alpha_role",
    "alpha_screen_facing",
    "beta_role",
    "beta_screen_facing",
    "charmed_side",
    "alpha_reason",
    "beta_reason",
    "state_reason",
}
ROLE_VALUES = {"allied_operator", "hostile_construct", "other", "indistinguishable"}
FACING_VALUES = {"screen_right", "screen_left", "front", "rear", "indistinguishable"}
STATE_VALUES = {"left", "right", "indistinguishable"}
PACKET_CONCEPTS = {
    "vanguard_1": {
        "f3c338ec52a394e3e02a92bad65ca00e881fd340673ee6c120dec09c86b3b883",
        "db59ac74296fe4cbf6c78a3011bf78cdfd1c7814c576c7f22e8d02853d7135c9",
    },
    "portrait_vanguard_1": {
        "db59ac74296fe4cbf6c78a3011bf78cdfd1c7814c576c7f22e8d02853d7135c9",
        "d6db376800af86f300f6fa8ea7c62865ce4c8bb05dadd9dbe9d470776fa22ee9",
    },
    "grunt": {"f512c5022533c53c4a84bcfd036a513d13ee5ec2667cba15283dff21fd373ea8"},
    "grunt_charmed": {
        "f512c5022533c53c4a84bcfd036a513d13ee5ec2667cba15283dff21fd373ea8",
        "64039ab91598423982031948fefc30b5f9b2d93b803d51617cb88fcea2aa8dd3",
    },
    "deploy": {"0a13437c7284fac6fbaf9e67be8223443bbdb3e47158a46325d007d691d17667"},
    "attack_hit": {"0a13437c7284fac6fbaf9e67be8223443bbdb3e47158a46325d007d691d17667"},
    "charm_vfx": {
        "64039ab91598423982031948fefc30b5f9b2d93b803d51617cb88fcea2aa8dd3",
        "0a13437c7284fac6fbaf9e67be8223443bbdb3e47158a46325d007d691d17667",
    },
}
ORIGINALITY_KEYS = {
    "review_id",
    "packet_id",
    "verdict",
    "recognizable_copied_signature_found",
    "approved_concept_authenticated",
    "generation_ledger_authenticated",
    "checked_concept_hashes",
    "observations",
    "reason",
}


class Checks:
    def __init__(self) -> None:
        self.count = 0
        self.records: list[dict[str, object]] = []

    def require(self, condition: bool, name: str, detail: str = "") -> None:
        self.count += 1
        self.records.append({"name": name, "ok": bool(condition), "detail": detail})
        if not condition:
            raise AssertionError(f"{name}: {detail}")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def parse_json(path: Path) -> dict[str, object]:
    def reject_duplicates(pairs: list[tuple[str, object]]) -> dict[str, object]:
        value: dict[str, object] = {}
        for key, item in pairs:
            if key in value:
                raise ValueError(f"duplicate JSON member {key!r} in {path}")
            value[key] = item
        return value

    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=reject_duplicates)


def repository_path(project: Path, value: str) -> Path:
    if not value.startswith("res://"):
        raise ValueError(f"not a repository path: {value}")
    result = (project / value.removeprefix("res://")).resolve()
    if not result.is_relative_to(project):
        raise ValueError(f"repository path escapes root: {value}")
    return result


def check_file(checks: Checks, project: Path, record: dict[str, object], name: str) -> Path:
    checks.require(set(record) == {"path", "sha256", "bytes"}, f"{name}_schema")
    path = repository_path(project, str(record["path"]))
    checks.require(path.is_file() and not path.is_symlink(), f"{name}_file")
    checks.require(path.stat().st_size == record["bytes"], f"{name}_bytes")
    checks.require(sha256(path) == record["sha256"], f"{name}_sha256")
    return path


def verify_input_manifest(checks: Checks, project: Path) -> dict[str, object]:
    manifest_path = project / INPUT_MANIFEST_RELATIVE
    manifest = parse_json(manifest_path)
    expected_keys = {
        "schema_version",
        "batch_id",
        "background_rgba",
        "columns",
        "generator",
        "inputs",
        "outputs",
        "review_cell_px",
        "rows",
        "silhouette_rgba",
        "source_cell_px",
        "state_pair_order",
    }
    checks.require(set(manifest) == expected_keys, "input_manifest_schema")
    checks.require(manifest["schema_version"] == "mgs.aui11.blind-review-inputs.v1", "input_manifest_version")
    checks.require(manifest["batch_id"] == "AUI-11", "input_manifest_batch")
    checks.require(manifest["background_rgba"] == [230, 230, 230, 255], "input_manifest_background")
    checks.require(manifest["silhouette_rgba"] == [17, 17, 17, 255], "input_manifest_silhouette")
    checks.require(manifest["source_cell_px"] == 192 and manifest["review_cell_px"] == 72, "input_manifest_scale")
    checks.require(manifest["columns"] == 4 and manifest["rows"] == 2, "input_manifest_grid")
    checks.require(manifest["state_pair_order"] == {"left": "grunt_charmed", "right": "grunt"}, "input_manifest_state_order")
    checks.require(set(manifest["inputs"]) == set(ATLAS_RELATIVES), "input_manifest_inputs")
    checks.require(set(manifest["outputs"]) == set(OUTPUT_NAMES), "input_manifest_outputs")
    generator = check_file(checks, project, manifest["generator"], "input_generator")
    checks.require(generator == (project / BUILDER_RELATIVE).resolve(), "input_generator_path")
    for name, relative in sorted(ATLAS_RELATIVES.items()):
        path = check_file(checks, project, manifest["inputs"][name], f"input_atlas_{name}")
        checks.require(path == (project / relative).resolve(), f"input_atlas_{name}_path")
    for name, filename in sorted(OUTPUT_NAMES.items()):
        path = check_file(checks, project, manifest["outputs"][name], f"review_output_{name}")
        checks.require(path == (project / OUTPUT_RELATIVE / filename).resolve(), f"review_output_{name}_path")

    with tempfile.TemporaryDirectory(prefix="aui11-review-inputs-") as temporary:
        temporary_project = Path(temporary)
        for relative in [BUILDER_RELATIVE, *ATLAS_RELATIVES.values()]:
            destination = temporary_project / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(project / relative, destination)
        temporary_output = temporary_project / OUTPUT_RELATIVE
        temporary_manifest = temporary_project / INPUT_MANIFEST_RELATIVE
        result = subprocess.run(
            [
                sys.executable,
                "-B",
                str(temporary_project / BUILDER_RELATIVE),
                "--project",
                str(temporary_project),
                "--output-dir",
                str(temporary_output),
                "--manifest",
                str(temporary_manifest),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        checks.require(result.returncode == 0, "input_builder_rerun", result.stdout[-500:])
        checks.require(temporary_manifest.read_bytes() == manifest_path.read_bytes(), "input_manifest_reproduced")
        for filename in sorted(OUTPUT_NAMES.values()):
            checks.require(
                (temporary_output / filename).read_bytes() == (project / OUTPUT_RELATIVE / filename).read_bytes(),
                f"review_output_reproduced_{filename}",
            )
    return manifest


def verify_blind_results(checks: Checks, project: Path, input_manifest: dict[str, object]) -> dict[str, object]:
    path = project / BLIND_RESULTS_RELATIVE
    value = parse_json(path)
    expected_keys = {
        "schema_version",
        "batch_id",
        "input_manifest_sha256",
        "denominator",
        "threshold",
        "expected",
        "reviewers",
        "scores",
        "failures",
        "status",
    }
    checks.require(set(value) == expected_keys, "blind_results_schema")
    checks.require(value["schema_version"] == "mgs.aui11.blind-review-results.v1", "blind_results_version")
    checks.require(value["batch_id"] == "AUI-11", "blind_results_batch")
    checks.require(value["input_manifest_sha256"] == sha256(project / INPUT_MANIFEST_RELATIVE), "blind_results_input_binding")
    checks.require(value["denominator"] == 10 and value["threshold"] == 8, "blind_results_threshold")
    checks.require(value["expected"] == EXPECTED_BLIND, "blind_results_expected")
    reviewers = value["reviewers"]
    checks.require(len(reviewers) == 10, "blind_results_denominator")
    expected_ids = {f"blind-{index:02d}" for index in range(1, 11)}
    checks.require({item["reviewer_id"] for item in reviewers} == expected_ids, "blind_results_reviewer_ids")
    for item in reviewers:
        reviewer_id = item["reviewer_id"]
        checks.require(set(item) == BLIND_REVIEWER_KEYS, f"blind_{reviewer_id}_schema")
        checks.require(item["alpha_role"] in ROLE_VALUES and item["beta_role"] in ROLE_VALUES, f"blind_{reviewer_id}_roles")
        checks.require(item["alpha_screen_facing"] in FACING_VALUES and item["beta_screen_facing"] in FACING_VALUES, f"blind_{reviewer_id}_facings")
        checks.require(item["charmed_side"] in STATE_VALUES, f"blind_{reviewer_id}_state")
        checks.require(all(isinstance(item[key], str) and item[key].strip() for key in ("alpha_reason", "beta_reason", "state_reason")), f"blind_{reviewer_id}_reasons")

    gates = {
        "vanguard_role_facing": lambda item: item["alpha_role"] == EXPECTED_BLIND["alpha_role"] and item["alpha_screen_facing"] == EXPECTED_BLIND["alpha_screen_facing"],
        "grunt_role_facing": lambda item: item["beta_role"] == EXPECTED_BLIND["beta_role"] and item["beta_screen_facing"] == EXPECTED_BLIND["beta_screen_facing"],
        "charm_state": lambda item: item["charmed_side"] == EXPECTED_BLIND["charmed_side"],
    }
    scores = {name: sum(1 for item in reviewers if predicate(item)) for name, predicate in gates.items()}
    failures = {
        name: [item["reviewer_id"] for item in reviewers if not predicate(item)]
        for name, predicate in gates.items()
    }
    checks.require(value["scores"] == scores, "blind_results_scores", json.dumps(scores, sort_keys=True))
    checks.require(value["failures"] == failures, "blind_results_failures")
    for name, score in sorted(scores.items()):
        checks.require(score >= 8, f"blind_gate_{name}", f"{score}/10")
    checks.require(value["status"] == "PASS", "blind_results_status")
    return value


def verify_originality_results(checks: Checks, project: Path) -> dict[str, object]:
    path = project / ORIGINALITY_RESULTS_RELATIVE
    value = parse_json(path)
    expected_keys = {
        "schema_version",
        "batch_id",
        "approval_token_sha256",
        "approved_concept_sha256",
        "generation_ledger_sha256",
        "reviewed_packets",
        "reviews",
        "failures",
        "status",
    }
    checks.require(set(value) == expected_keys, "originality_results_schema")
    checks.require(value["schema_version"] == "mgs.aui11.originality-review-results.v1", "originality_results_version")
    checks.require(value["batch_id"] == "AUI-11", "originality_results_batch")
    checks.require(value["approval_token_sha256"] == APPROVAL_TOKEN, "originality_results_approval_token")
    checks.require(set(value["approved_concept_sha256"]) == APPROVED and len(value["approved_concept_sha256"]) == 6, "originality_results_approved_hashes")
    ledger = project / QA_RELATIVE / "generation-ledger.md"
    checks.require(value["generation_ledger_sha256"] == sha256(ledger), "originality_results_ledger_binding")
    checks.require(set(value["reviewed_packets"]) == set(PACKET_CONCEPTS), "originality_results_packet_bindings")
    for packet, fields in value["reviewed_packets"].items():
        checks.require(set(fields) == {"atlas", "contact", "metadata"}, f"originality_{packet}_binding_schema")
        slug = f"aui11-{packet}"
        expected = {
            "atlas": Path(f"staging/character-vfx/aui-11/packets/{packet}/{slug}.png"),
            "contact": Path(f"staging/character-vfx/aui-11/packets/{packet}/{slug}.contact.png"),
            "metadata": Path(f"staging/character-vfx/aui-11/packets/{packet}/{slug}.asset.json"),
        }
        for field, relative in expected.items():
            path = check_file(checks, project, fields[field], f"originality_{packet}_{field}_binding")
            checks.require(path == (project / relative).resolve(), f"originality_{packet}_{field}_path")
    reviews = value["reviews"]
    checks.require(len(reviews) == 7, "originality_results_count")
    checks.require({item["packet_id"] for item in reviews} == set(PACKET_CONCEPTS), "originality_results_packets")
    checks.require({item["review_id"] for item in reviews} == {f"orig-{index:02d}" for index in range(1, 8)}, "originality_results_ids")
    failures: list[str] = []
    for item in reviews:
        packet_id = item["packet_id"]
        checks.require(set(item) == ORIGINALITY_KEYS, f"originality_{packet_id}_schema")
        checks.require(item["review_id"] == f"orig-{list(PACKET_CONCEPTS).index(packet_id) + 1:02d}", f"originality_{packet_id}_id")
        checks.require(set(item["checked_concept_hashes"]) == PACKET_CONCEPTS[packet_id], f"originality_{packet_id}_concepts")
        checks.require(all(value in APPROVED for value in item["checked_concept_hashes"]), f"originality_{packet_id}_approved")
        checks.require(isinstance(item["reason"], str) and item["reason"].strip(), f"originality_{packet_id}_reason")
        checks.require(isinstance(item["observations"], list) and all(isinstance(entry, str) and entry.strip() for entry in item["observations"]), f"originality_{packet_id}_observations")
        passed = (
            item["verdict"] == "PASS"
            and item["recognizable_copied_signature_found"] is False
            and item["approved_concept_authenticated"] is True
            and item["generation_ledger_authenticated"] is True
        )
        if not passed:
            failures.append(packet_id)
        checks.require(passed, f"originality_{packet_id}_pass")
    checks.require(value["failures"] == failures, "originality_results_failures")
    checks.require(value["status"] == "PASS" and not failures, "originality_results_status")
    return value


def verify(project: Path, report: Path) -> None:
    checks = Checks()
    input_manifest = verify_input_manifest(checks, project)
    blind = verify_blind_results(checks, project, input_manifest)
    originality = verify_originality_results(checks, project)
    result = {
        "schema_version": "mgs.aui11.named-review-verification.v1",
        "batch_id": "AUI-11",
        "status": "PASS",
        "checks_executed": checks.count,
        "input_manifest_sha256": sha256(project / INPUT_MANIFEST_RELATIVE),
        "blind_results_sha256": sha256(project / BLIND_RESULTS_RELATIVE),
        "originality_results_sha256": sha256(project / ORIGINALITY_RESULTS_RELATIVE),
        "blind_scores": blind["scores"],
        "originality_reviews_passed": len(originality["reviews"]),
        "checks": checks.records,
    }
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "checks_executed": checks.count, "report": str(report)}, sort_keys=True))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()
    verify(Path(args.project).resolve(), Path(args.report).resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
