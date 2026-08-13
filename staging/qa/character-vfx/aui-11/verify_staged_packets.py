#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

EXPECTED_PACKET_IDS = {
    "vanguard_1",
    "portrait_vanguard_1",
    "grunt",
    "grunt_charmed",
    "deploy",
    "attack_hit",
    "charm_vfx",
}
APPROVED = [
    "f3c338ec52a394e3e02a92bad65ca00e881fd340673ee6c120dec09c86b3b883",
    "db59ac74296fe4cbf6c78a3011bf78cdfd1c7814c576c7f22e8d02853d7135c9",
    "f512c5022533c53c4a84bcfd036a513d13ee5ec2667cba15283dff21fd373ea8",
    "d6db376800af86f300f6fa8ea7c62865ce4c8bb05dadd9dbe9d470776fa22ee9",
    "64039ab91598423982031948fefc30b5f9b2d93b803d51617cb88fcea2aa8dd3",
    "0a13437c7284fac6fbaf9e67be8223443bbdb3e47158a46325d007d691d17667",
]
RESERVED = {bytes((244, 244, 244)), bytes((65, 166, 246))}
VFX_RANGES = {
    "deploy": ((72, 108), (36, 72), (2000, 6500)),
    "attack_hit": ((32, 56), (18, 40), (350, 1800)),
    "charm_vfx": ((44, 72), (22, 44), (900, 2800)),
}
CLAIM_COMMIT = "553c21ec4129b8a29f1e51301d522ae9a37d41a0"
OWNED_PREFIXES = (
    "staging/character-vfx/aui-11/",
    "staging/qa/character-vfx/aui-11/",
    "staging/provenance/characters/aui-11/",
    "staging/provenance/vfx/aui-11/",
)
OWNED_FILES = {
    "docs/art/character-vfx/AUI-11-production-packets.md",
    "docs/handoffs/AUI-11-agent-e-production.md",
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
    path = (project / value.removeprefix("res://")).resolve()
    if not path.is_relative_to(project.resolve()):
        raise ValueError(f"path escapes repository: {value}")
    return path


def check_file(checks: Checks, project: Path, record: dict[str, object], name: str) -> Path:
    checks.require(set(record) == {"path", "sha256", "bytes"}, f"{name}_schema")
    path = repository_path(project, str(record["path"]))
    checks.require(path.is_file() and not path.is_symlink(), f"{name}_file", str(record["path"]))
    checks.require(path.stat().st_size == record["bytes"], f"{name}_bytes")
    checks.require(sha256(path) == record["sha256"], f"{name}_sha256")
    return path


def is_owned(path: str) -> bool:
    return path in OWNED_FILES or path.startswith(OWNED_PREFIXES)


def git_scope_checks(checks: Checks, project: Path) -> None:
    subprocess.run(["git", "-C", str(project), "cat-file", "-e", f"{CLAIM_COMMIT}^{{commit}}"], check=True)
    changed = set(subprocess.check_output(["git", "-C", str(project), "diff", "--name-only", CLAIM_COMMIT, "--"], text=True).splitlines())
    changed.update(subprocess.check_output(["git", "-C", str(project), "ls-files", "--others", "--exclude-standard"], text=True).splitlines())
    checks.require(bool(changed), "git_scope_nonempty")
    checks.require(all(is_owned(path) for path in changed), "git_scope_owned", ",".join(sorted(path for path in changed if not is_owned(path))))
    statuses = subprocess.check_output(["git", "-C", str(project), "diff", "--name-status", CLAIM_COMMIT, "--"], text=True).splitlines()
    checks.require(not any(line.startswith("D\t") for line in statuses), "git_scope_no_deletions")
    forbidden = {
        "FEATURES.json",
        "assets/manifest.tres",
        "docs/todo.md",
        "docs/completed.md",
        "docs/plans/AUI-IMPLEMENTATION-STATUS.md",
    }
    checks.require(not (changed & forbidden), "git_scope_forbidden_files")
    checks.require(not any(path.startswith(("assets/sprites/", "scenes/", "models/", "localization/", "playtests/")) for path in changed), "git_scope_forbidden_prefixes")


def canonical_hash(value: object) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n"
    return hashlib.sha256(payload.encode()).hexdigest()


def metadata_semantic_hash(value: dict[str, object]) -> str:
    result = json.loads(json.dumps(value))
    result.pop("backend")
    result.pop("run_identity")
    result["atlas"].pop("file_sha256")
    result["contact"].pop("file_sha256")
    return canonical_hash(result)


def qa_semantic_hash(value: dict[str, object]) -> str:
    result = json.loads(json.dumps(value))
    for item in result["checks"]:
        item.pop("detail")
    return canonical_hash(result)


def rgba(path: Path) -> Image.Image:
    with Image.open(path) as raw:
        raw.load()
        return raw.convert("RGBA")


def cells(atlas: Image.Image) -> list[Image.Image]:
    return [
        atlas.crop((column * 192, row * 192, (column + 1) * 192, (row + 1) * 192))
        for row in range(2)
        for column in range(4)
    ]


def occupied(cell: Image.Image) -> bytes:
    return bytes(1 if value else 0 for value in cell.getchannel("A").tobytes())


def overlap(left: bytes, right: bytes) -> float:
    intersection = sum(1 for a, b in zip(left, right) if a and b)
    union = sum(1 for a, b in zip(left, right) if a or b)
    return 1.0 if union == 0 else intersection / union


def center(cell: Image.Image) -> tuple[int, int]:
    box = cell.getchannel("A").getbbox()
    if box is None:
        raise ValueError("empty cell")
    return (box[0] + box[2] - 1) // 2, (box[1] + box[3] - 1) // 2


def bbox_metrics(cell: Image.Image) -> tuple[int, int, int, int, int]:
    box = cell.getchannel("A").getbbox()
    if box is None:
        return 0, 0, 0, 0, 0
    area = sum(1 for value in cell.getchannel("A").tobytes() if value)
    return box[2] - box[0], box[3] - box[1], area, (box[0] + box[2] - 1) // 2, box[3] - 1


def open_window(cell: Image.Image, width: int, height: int) -> int:
    box = cell.getchannel("A").getbbox()
    if box is None:
        return 255
    x0 = 96 - width // 2
    y0 = 180 - (box[3] - box[1]) // 2 - height // 2
    values = cell.getchannel("A").crop((x0, y0, x0 + width, y0 + height)).tobytes()
    return max(values, default=255)


def verify_bound_oracles(checks: Checks, project: Path, manifest: dict[str, object]) -> None:
    root = project / "staging/character-vfx/aui-11"
    qa = project / "staging/qa/character-vfx/aui-11"
    bindings = manifest["qa_bindings"]
    checks.require(
        set(bindings) == {
            "dual_backend",
            "attack_hit_transform",
            "charm_vfx_transform",
            "charm_semantics",
            "named_reviews",
            "facing_state_corrections",
        },
        "qa_binding_groups",
    )
    checks.require(set(bindings["dual_backend"]) == {"verifier"}, "dual_binding_schema")
    check_file(checks, project, bindings["dual_backend"]["verifier"], "dual_backend_verifier")
    attack = bindings["attack_hit_transform"]
    checks.require(
        set(attack)
        == {
            "contract",
            "producer",
            "verifier",
            "receipt",
            "pretransform_sources",
            "extractor",
            "extraction_receipt",
            "generation_prompt",
            "measurements",
            "visual_audit",
        },
        "attack_binding_schema",
    )
    contract = check_file(checks, project, attack["contract"], "attack_contract")
    check_file(checks, project, attack["producer"], "attack_producer")
    verifier = check_file(checks, project, attack["verifier"], "attack_verifier")
    receipt_path = check_file(checks, project, attack["receipt"], "attack_receipt")
    check_file(checks, project, attack["extractor"], "attack_extractor")
    extraction_receipt = check_file(checks, project, attack["extraction_receipt"], "attack_extraction_receipt")
    check_file(checks, project, attack["generation_prompt"], "attack_generation_prompt")
    measurements_path = check_file(checks, project, attack["measurements"], "attack_measurements")
    visual_audit_path = check_file(checks, project, attack["visual_audit"], "attack_visual_audit")
    pretransform = [check_file(checks, project, item, f"attack_pretransform_{index}") for index, item in enumerate(attack["pretransform_sources"])]
    checks.require([path.name for path in pretransform] == [f"frame_{index:02d}.png" for index in range(8)], "attack_pretransform_inventory")
    attack_receipt = parse_json(receipt_path)
    checks.require(attack_receipt["status"] == "PASS" and len(attack_receipt["inputs"]) == 8 and len(attack_receipt["outputs"]) == 8, "attack_receipt_status")
    checks.require(parse_json(extraction_receipt)["schema_version"] == "mgs.aui11.attack-hit-source-extraction.v1", "attack_extraction_schema")
    visual_audit = parse_json(visual_audit_path)
    checks.require(visual_audit["verdict"] == "PASS" and visual_audit["measurements_pass"] is True and all(visual_audit["visible_contract"].values()), "attack_visual_audit_pass")
    measurements = parse_json(measurements_path)
    checks.require(len(measurements["frames"]) == 8 and all(frame["components_8_connected"] >= 7 for frame in measurements["frames"]), "attack_measurement_components")
    checks.require(all(loop["iou"] >= 0.92 for loop in measurements["loops"]), "attack_measurement_loops")
    checks.require(attack_receipt["contract_sha256"] == sha256(contract), "attack_receipt_contract")
    for index, path in enumerate(pretransform):
        checks.require(attack_receipt["inputs"][index]["file_sha256"] == sha256(path), f"attack_receipt_input_{index}")
    attack_sources = {item["path"].rsplit("/", 1)[-1]: item for item in next(item for item in manifest["packets"] if item["logical_id"] == "attack_hit")["sources"]}
    for index, item in enumerate(attack_receipt["outputs"]):
        expected = attack_sources[f"frame_{index:02d}.png"]
        checks.require(item["expected_final"]["file_sha256"] == expected["sha256"] and item["expected_final"]["bytes"] == expected["bytes"], f"attack_receipt_output_{index}")
    with tempfile.TemporaryDirectory(prefix="aui11-attack-oracle-") as temporary:
        temporary_root = Path(temporary)
        rerun_report = temporary_root / "report.json"
        result = subprocess.run(
            [sys.executable, "-B", str(verifier), "--contract", str(contract), "--input-root", str(qa / "attack-hit-pretransform"), "--expected-root", str(root / "sources/attack_hit"), "--output-root", str(temporary_root / "reconstructed"), "--report", str(rerun_report)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        checks.require(result.returncode == 0, "attack_oracle_rerun", result.stdout[-500:])
        checks.require(parse_json(rerun_report) == attack_receipt, "attack_oracle_receipt_reproduced")

    charm_vfx = bindings["charm_vfx_transform"]
    charm_vfx_keys = {
        "contract",
        "producer",
        "verifier",
        "receipt",
        "pretransform_sources",
        "extractor",
        "extraction_receipt",
        "generation_prompt",
        "measurer",
        "measurements",
        "visual_audit",
    }
    checks.require(set(charm_vfx) == charm_vfx_keys, "charm_vfx_binding_schema")
    charm_vfx_paths = {
        key: check_file(checks, project, value, f"charm_vfx_{key}")
        for key, value in charm_vfx.items()
        if key != "pretransform_sources"
    }
    charm_vfx_pretransform = [
        check_file(checks, project, item, f"charm_vfx_pretransform_{index}")
        for index, item in enumerate(charm_vfx["pretransform_sources"])
    ]
    checks.require(
        [path.name for path in charm_vfx_pretransform]
        == [f"frame_{index:02d}.png" for index in range(8)],
        "charm_vfx_pretransform_inventory",
    )
    charm_vfx_receipt = parse_json(charm_vfx_paths["receipt"])
    checks.require(
        charm_vfx_receipt["status"] == "PASS"
        and len(charm_vfx_receipt["inputs"]) == 8
        and len(charm_vfx_receipt["outputs"]) == 8,
        "charm_vfx_receipt_status",
    )
    checks.require(
        parse_json(charm_vfx_paths["extraction_receipt"])["schema_version"]
        == "mgs.aui11.charm-vfx-source-extraction.v1",
        "charm_vfx_extraction_schema",
    )
    charm_vfx_audit = parse_json(charm_vfx_paths["visual_audit"])
    checks.require(
        charm_vfx_audit["verdict"] == "PASS"
        and charm_vfx_audit["measurements_pass"] is True
        and all(charm_vfx_audit["visible_contract"].values()),
        "charm_vfx_visual_audit_pass",
    )
    charm_vfx_measurements = parse_json(charm_vfx_paths["measurements"])
    checks.require(len(charm_vfx_measurements["frames"]) == 8, "charm_vfx_measurement_frames")
    for frame in charm_vfx_measurements["frames"]:
        checks.require(44 <= frame["width"] <= 72, f"charm_vfx_width_{frame['frame']}")
        checks.require(22 <= frame["height"] <= 44, f"charm_vfx_height_{frame['frame']}")
        checks.require(900 <= frame["opaque"] <= 2800, f"charm_vfx_area_{frame['frame']}")
        checks.require(93 <= frame["center_x"] <= 99 and frame["foot"] == 180, f"charm_vfx_anchor_{frame['frame']}")
        checks.require(frame["open_center_max_alpha"] == 0, f"charm_vfx_open_center_{frame['frame']}")
    frame_six = charm_vfx_measurements["frames"][6]
    checks.require(frame_six["components_8_connected"] == 6, "charm_vfx_frame6_component_count")
    checks.require(all(loop["iou"] >= 0.92 for loop in charm_vfx_measurements["loops"]), "charm_vfx_measurement_loops")
    checks.require(charm_vfx_receipt["contract_sha256"] == sha256(charm_vfx_paths["contract"]), "charm_vfx_receipt_contract")
    for index, path in enumerate(charm_vfx_pretransform):
        checks.require(charm_vfx_receipt["inputs"][index]["file_sha256"] == sha256(path), f"charm_vfx_receipt_input_{index}")
    charm_vfx_sources = {
        item["path"].rsplit("/", 1)[-1]: item
        for item in next(item for item in manifest["packets"] if item["logical_id"] == "charm_vfx")["sources"]
    }
    for index, item in enumerate(charm_vfx_receipt["outputs"]):
        expected = charm_vfx_sources[f"frame_{index:02d}.png"]
        checks.require(
            item["expected_final"]["file_sha256"] == expected["sha256"]
            and item["expected_final"]["bytes"] == expected["bytes"],
            f"charm_vfx_receipt_output_{index}",
        )
    with tempfile.TemporaryDirectory(prefix="aui11-charm-vfx-oracle-") as temporary:
        temporary_root = Path(temporary)
        rerun_report = temporary_root / "transform-report.json"
        result = subprocess.run(
            [
                sys.executable,
                "-B",
                str(charm_vfx_paths["verifier"]),
                "--contract",
                str(charm_vfx_paths["contract"]),
                "--input-root",
                str(qa / "charm-vfx-pretransform"),
                "--expected-root",
                str(root / "sources/charm_vfx"),
                "--output-root",
                str(temporary_root / "reconstructed"),
                "--report",
                str(rerun_report),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        checks.require(result.returncode == 0, "charm_vfx_oracle_rerun", result.stdout[-500:])
        checks.require(parse_json(rerun_report) == charm_vfx_receipt, "charm_vfx_oracle_receipt_reproduced")
        rerun_measurements = temporary_root / "measurements.json"
        result = subprocess.run(
            [
                sys.executable,
                "-B",
                str(charm_vfx_paths["measurer"]),
                str(root / "packets/charm_vfx/aui11-charm_vfx.png"),
                "--report",
                str(rerun_measurements),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        checks.require(result.returncode == 0, "charm_vfx_measurement_rerun", result.stdout[-500:])
        checks.require(parse_json(rerun_measurements) == charm_vfx_measurements, "charm_vfx_measurement_reproduced")

    charm = bindings["charm_semantics"]
    expected_keys = {"contract", "expected", "transform_report", "transformer", "expected_oracle", "semantic_verifier", "semantic_receipt"}
    checks.require(set(charm) == expected_keys, "charm_binding_schema")
    charm_paths = {key: check_file(checks, project, value, f"charm_{key}") for key, value in charm.items()}
    semantic_receipt = parse_json(charm_paths["semantic_receipt"])
    checks.require(semantic_receipt["status"] == "PASS" and len(semantic_receipt["frames"]) == 8, "charm_semantic_status")
    checks.require(semantic_receipt["contract_sha256"] == sha256(charm_paths["contract"]), "charm_semantic_contract")
    checks.require(semantic_receipt["expected_sha256"] == sha256(charm_paths["expected"]), "charm_semantic_expected")
    checks.require(semantic_receipt["transform_report_sha256"] == sha256(charm_paths["transform_report"]), "charm_semantic_transform_report")
    with tempfile.TemporaryDirectory(prefix="aui11-charm-oracle-") as temporary:
        rerun_report = Path(temporary) / "report.json"
        packets = root / "packets"
        result = subprocess.run(
            [sys.executable, "-B", str(charm_paths["semantic_verifier"]), "--contract", str(charm_paths["contract"]), "--expected", str(charm_paths["expected"]), "--transform-report", str(charm_paths["transform_report"]), "--base-atlas", str(packets / "grunt/aui11-grunt.png"), "--charmed-atlas", str(packets / "grunt_charmed/aui11-grunt_charmed.png"), "--charmed-source-root", str(root / "sources/grunt_charmed"), "--report", str(rerun_report)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        checks.require(result.returncode == 0, "charm_oracle_rerun", result.stdout[-500:])
        checks.require(parse_json(rerun_report) == semantic_receipt, "charm_oracle_receipt_reproduced")

    named = bindings["named_reviews"]
    named_keys = {
        "input_builder",
        "input_manifest",
        "inputs",
        "blind_results",
        "originality_results",
        "verifier",
        "receipt",
    }
    checks.require(set(named) == named_keys, "named_binding_schema")
    named_paths = {
        key: check_file(checks, project, value, f"named_{key}")
        for key, value in named.items()
        if key != "inputs"
    }
    named_inputs = [
        check_file(checks, project, value, f"named_input_{index}")
        for index, value in enumerate(named["inputs"])
    ]
    checks.require(
        [path.name for path in named_inputs]
        == [
            "blind-grunt-silhouette.png",
            "blind-grunt-state-pair.png",
            "blind-vanguard-silhouette.png",
        ],
        "named_input_inventory",
    )
    named_receipt = parse_json(named_paths["receipt"])
    blind_results = parse_json(named_paths["blind_results"])
    checks.require(
        named_receipt["status"] == "PASS"
        and named_receipt["blind_scores"] == blind_results["scores"]
        and all(score >= 8 for score in named_receipt["blind_scores"].values())
        and named_receipt["originality_reviews_passed"] == 7,
        "named_receipt_status",
    )
    with tempfile.TemporaryDirectory(prefix="aui11-named-review-") as temporary:
        rerun_report = Path(temporary) / "report.json"
        result = subprocess.run(
            [
                sys.executable,
                "-B",
                str(named_paths["verifier"]),
                "--project",
                str(project),
                "--report",
                str(rerun_report),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        checks.require(
            result.returncode == 0,
            "named_review_rerun",
            "" if result.returncode == 0 else result.stdout[-500:],
        )
        checks.require(parse_json(rerun_report) == named_receipt, "named_review_receipt_reproduced")

    corrections = bindings["facing_state_corrections"]
    correction_keys = {
        "extractor",
        "extraction_receipt",
        "cue_support_transform",
        "cue_support_receipt",
        "state_value_transform",
        "state_value_receipt",
        "base_highlight_transform",
        "base_highlight_receipt",
        "vanguard_loop_transform",
        "vanguard_loop_receipt",
        "grunt_loop_transform",
        "grunt_loop_receipt",
        "promotion_receipt",
    }
    checks.require(set(corrections) == correction_keys, "correction_binding_schema")
    correction_paths = {
        key: check_file(checks, project, value, f"correction_{key}")
        for key, value in corrections.items()
    }
    checks.require(
        parse_json(correction_paths["extraction_receipt"])["schema_version"]
        == "mgs.aui11.facing-source-extraction.v1",
        "correction_extraction_schema",
    )
    checks.require(
        parse_json(correction_paths["cue_support_receipt"])["schema_version"]
        == "mgs.aui11.charm-cue-support-repair.v1",
        "correction_cue_support_schema",
    )
    checks.require(
        parse_json(correction_paths["state_value_receipt"])["schema_version"]
        == "mgs.aui11.grunt-state-region-flatten.v1",
        "correction_state_value_schema",
    )
    checks.require(
        parse_json(correction_paths["base_highlight_receipt"])["schema_version"]
        == "mgs.aui11.grunt-base-highlight-reduction.v1",
        "correction_base_highlight_schema",
    )
    loop_receipt = parse_json(correction_paths["vanguard_loop_receipt"])
    checks.require(
        loop_receipt["schema_version"] == "mgs.aui11.vanguard-loop-closure.v1"
        and loop_receipt["after"]["start_recovery_byte_equal"] is True,
        "correction_vanguard_loop_schema",
    )
    grunt_loop_receipt = parse_json(correction_paths["grunt_loop_receipt"])
    checks.require(
        grunt_loop_receipt["schema_version"] == "mgs.aui11.grunt-loop-closure.v1"
        and all(item["byte_equal"] is True for item in grunt_loop_receipt["after"]["pairs"]),
        "correction_grunt_loop_schema",
    )
    checks.require(
        parse_json(correction_paths["promotion_receipt"])["schema_version"]
        == "mgs.aui11.round6-promotion.v1",
        "correction_promotion_schema",
    )


def verify_dual_receipt(checks: Checks, project: Path, manifest: dict[str, object]) -> None:
    receipt_path = project / "staging/qa/character-vfx/aui-11/dual-backend-bound-receipt.json"
    receipt = parse_json(receipt_path)
    checks.require(set(receipt) == {"schema_version", "status", "checks_executed", "external_evidence_id", "batch_manifest_sha256", "canonical_backend", "fallback_backend", "packets"}, "dual_receipt_schema")
    checks.require(receipt["schema_version"] == 1 and receipt["external_evidence_id"] == "aui-11/fresh-dual-backend", "dual_receipt_identity")
    checks.require(receipt["status"] == "PASS" and receipt["checks_executed"] == 133, "dual_receipt_status")
    checks.require(receipt["batch_manifest_sha256"] == sha256(project / "staging/character-vfx/aui-11/batch-manifest.json"), "dual_receipt_manifest")
    checks.require(receipt["canonical_backend"] == manifest["canonical_backend"] and receipt["fallback_backend"] == manifest["fallback_backend"], "dual_receipt_backends")
    packets = {item["logical_id"]: item for item in manifest["packets"]}
    records = {item["logical_id"]: item for item in receipt["packets"]}
    checks.require(set(records) == EXPECTED_PACKET_IDS, "dual_receipt_packet_ids")
    for packet in sorted(EXPECTED_PACKET_IDS):
        record, manifest_packet = records[packet], packets[packet]
        checks.require(set(record) == {"logical_id", "spec", "sources", "runs"}, f"dual_{packet}_schema")
        checks.require(set(record["runs"]) == {"python", "godot"} and all(set(record["runs"][backend]) == {"a", "b"} for backend in ("python", "godot")), f"dual_{packet}_run_schema")
        checks.require(record["spec"]["sha256"] == manifest_packet["spec"]["sha256"] and record["spec"]["bytes"] == manifest_packet["spec"]["bytes"], f"dual_{packet}_spec")
        manifest_sources = [{"path": item["path"].rsplit("/", 1)[-1], "sha256": item["sha256"], "bytes": item["bytes"]} for item in manifest_packet["sources"]]
        checks.require(record["sources"] == manifest_sources, f"dual_{packet}_sources")
        python_a = record["runs"]["python"]["a"]
        python_b = record["runs"]["python"]["b"]
        godot_a = record["runs"]["godot"]["a"]
        godot_b = record["runs"]["godot"]["b"]
        run_keys = {"files", "atlas_rgba_sha256", "contact_rgba_sha256", "metadata_semantic_sha256", "qa_semantic_sha256"}
        checks.require(all(set(item) == run_keys for item in (python_a, python_b, godot_a, godot_b)), f"dual_{packet}_run_record_schema")
        expected_filenames = {item["path"].rsplit("/", 1)[-1] for item in manifest_packet["canonical_outputs"].values()}
        for backend, identity, run_record in (("python", "a", python_a), ("python", "b", python_b), ("godot", "a", godot_a), ("godot", "b", godot_b)):
            checks.require(set(run_record["files"]) == expected_filenames, f"dual_{packet}_{backend}_{identity}_file_inventory")
            checks.require(all(set(file_record) == {"sha256", "bytes"} for file_record in run_record["files"].values()), f"dual_{packet}_{backend}_{identity}_file_schema")
        checks.require(python_a == python_b, f"dual_{packet}_python_exact")
        checks.require(godot_a == godot_b, f"dual_{packet}_godot_exact")
        for identity, python_run, godot_run in (("a", python_a, godot_a), ("b", python_b, godot_b)):
            for key in ("atlas_rgba_sha256", "contact_rgba_sha256", "metadata_semantic_sha256", "qa_semantic_sha256"):
                checks.require(python_run[key] == godot_run[key], f"dual_{packet}_{identity}_{key}")
        for field in ("atlas", "contact", "metadata", "qa"):
            output = manifest_packet["canonical_outputs"][field]
            filename = output["path"].rsplit("/", 1)[-1]
            checks.require(python_a["files"][filename]["sha256"] == output["sha256"] and python_a["files"][filename]["bytes"] == output["bytes"], f"dual_{packet}_canonical_{field}")
        atlas_name = manifest_packet["canonical_outputs"]["atlas"]["path"].rsplit("/", 1)[-1]
        contact_name = manifest_packet["canonical_outputs"]["contact"]["path"].rsplit("/", 1)[-1]
        for identity, godot_run in (("a", godot_a), ("b", godot_b)):
            checks.require(godot_run["atlas_rgba_sha256"] == manifest_packet["fallback_decoded_rgba_sha256"]["atlas"], f"dual_{packet}_{identity}_fallback_atlas")
            checks.require(godot_run["contact_rgba_sha256"] == manifest_packet["fallback_decoded_rgba_sha256"]["contact"], f"dual_{packet}_{identity}_fallback_contact")
        metadata = parse_json(repository_path(project, manifest_packet["canonical_outputs"]["metadata"]["path"]))
        qa = parse_json(repository_path(project, manifest_packet["canonical_outputs"]["qa"]["path"]))
        for identity, python_run in (("a", python_a), ("b", python_b)):
            checks.require(python_run["atlas_rgba_sha256"] == hashlib.sha256(rgba(repository_path(project, manifest_packet["canonical_outputs"]["atlas"]["path"])).tobytes()).hexdigest(), f"dual_{packet}_{identity}_atlas_recomputed")
            checks.require(python_run["contact_rgba_sha256"] == hashlib.sha256(rgba(repository_path(project, manifest_packet["canonical_outputs"]["contact"]["path"])).tobytes()).hexdigest(), f"dual_{packet}_{identity}_contact_recomputed")
            checks.require(python_run["metadata_semantic_sha256"] == metadata_semantic_hash(metadata), f"dual_{packet}_{identity}_metadata_semantic")
            checks.require(python_run["qa_semantic_sha256"] == qa_semantic_hash(qa), f"dual_{packet}_{identity}_qa_semantic")
            checks.require(atlas_name in python_run["files"] and contact_name in python_run["files"], f"dual_{packet}_{identity}_named_outputs")
    with tempfile.TemporaryDirectory(prefix="aui11-dual-backend-") as temporary:
        temporary_root = Path(temporary)
        verifier = project / "staging/qa/character-vfx/aui-11/verify_dual_backend_packets.py"
        rerun_report = temporary_root / "receipt.json"
        godot = Path(os.environ.get("GODOT", str(Path.home() / "bin/godot")))
        result = subprocess.run(
            [sys.executable, "-B", str(verifier), "--project", str(project), "--evidence-root", str(temporary_root / "evidence"), "--report", str(rerun_report), "--godot", str(godot)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=900,
            check=False,
        )
        checks.require(result.returncode == 0, "dual_receipt_rerun", "" if result.returncode == 0 else result.stdout[-1000:])
        checks.require(parse_json(rerun_report) == receipt, "dual_receipt_reproduced")


def verify_provenance(checks: Checks, project: Path, manifest: dict[str, object]) -> None:
    expected_top = {"schema_version", "package", "state", "production_assets_emitted", "runtime_assets_changed", "runtime_binding", "human_final_art", "approval_token_sha256", "reference_manifest_sha256", "approved_concept_sha256", "generation", "foreground_extraction", "normalization", "evidence", "license", "asset_domain", "packet_ids"}
    expected_evidence_paths = {
        "attack_hit_transform": "res://staging/qa/character-vfx/aui-11/attack-hit-transform-receipt.json",
        "attack_hit_visual_audit": "res://staging/qa/character-vfx/aui-11/attack-hit-v2-visual-audit.json",
        "batch_manifest": "res://staging/character-vfx/aui-11/batch-manifest.json",
        "charm_vfx_transform": "res://staging/qa/character-vfx/aui-11/charm-vfx-transform-receipt.json",
        "charm_vfx_visual_audit": "res://staging/qa/character-vfx/aui-11/charm-vfx-r4-visual-audit.json",
        "charm_semantics": "res://staging/qa/character-vfx/aui-11/charm-semantic-verification.json",
        "dual_backend_verification": "res://staging/qa/character-vfx/aui-11/dual-backend-bound-receipt.json",
        "dual_backend_verifier": "res://staging/qa/character-vfx/aui-11/verify_dual_backend_packets.py",
        "generation_ledger": "res://staging/qa/character-vfx/aui-11/generation-ledger.md",
        "named_review_verification": "res://staging/qa/character-vfx/aui-11/named-review-verification.json",
        "blind_review_results": "res://staging/qa/character-vfx/aui-11/blind-review-results.json",
        "originality_review_results": "res://staging/qa/character-vfx/aui-11/originality-review-results.json",
        "facing_source_extraction": "res://staging/qa/character-vfx/aui-11/facing-source-extraction.json",
        "charm_cue_support": "res://staging/qa/character-vfx/aui-11/charm-cue-support-repair.json",
        "grunt_state_value_cleanup": "res://staging/qa/character-vfx/aui-11/grunt-state-region-flatten.json",
        "grunt_base_highlight_reduction": "res://staging/qa/character-vfx/aui-11/grunt-base-highlight-reduction.json",
        "vanguard_loop_closure": "res://staging/qa/character-vfx/aui-11/vanguard-loop-closure.json",
        "grunt_loop_closure": "res://staging/qa/character-vfx/aui-11/grunt-loop-closure.json",
        "promotion_receipt": "res://staging/qa/character-vfx/aui-11/round6-promotion.json",
        "staged_verifier": "res://staging/qa/character-vfx/aui-11/verify_staged_packets.py",
        "visual_review": "res://staging/qa/character-vfx/aui-11/final-packet-visual-review.md",
    }
    expected_generators = [
        "res://tools/art_pipeline/character_vfx/pipeline.py",
        "res://tools/art_pipeline/character_vfx/pixel_ops.py",
        "res://tools/art_pipeline/character_vfx/godot/pipeline.gd",
        "res://tools/art_pipeline/character_vfx/godot/pixel_ops.gd",
    ]
    expected_assignment = {"attack_hit": "isnet-general-use", "charm_vfx": "isnet-general-use", "deploy": "isnet-general-use", "grunt": "isnet-general-use", "portrait_vanguard_1": "u2net_human_seg", "vanguard_1": "isnet-general-use"}
    expected_models = {
        "isnet-general-use": {"path": "external-model-cache://isnet-general-use.onnx", "sha256": "60920e99c45464f2ba57bee2ad08c919a52bbf852739e96947fbb4358c0d964a"},
        "u2net_human_seg": {"path": "external-model-cache://u2net_human_seg.onnx", "sha256": "01eb6a29a5c4d8edb30b56adad9bb3a2a0535338e480724a213e0acfd2d1c73c"},
    }
    domain_packets = {"characters": ["vanguard_1", "portrait_vanguard_1", "grunt", "grunt_charmed"], "vfx": ["deploy", "attack_hit", "charm_vfx"]}
    for domain, packet_ids in domain_packets.items():
        path = project / f"staging/provenance/{domain}/aui-11/batch-provenance.json"
        value = parse_json(path)
        checks.require(set(value) == expected_top, f"provenance_{domain}_schema")
        checks.require(value["schema_version"] == 1 and value["package"] == "AUI-11" and value["asset_domain"] == domain and value["packet_ids"] == packet_ids, f"provenance_{domain}_identity")
        checks.require(value["state"] == manifest["state"] and value["production_assets_emitted"] is True and value["runtime_assets_changed"] is False, f"provenance_{domain}_state")
        checks.require(value["runtime_binding"] == manifest["runtime_binding"] and value["human_final_art"] == manifest["human_final_art"], f"provenance_{domain}_barriers")
        checks.require(value["approval_token_sha256"] == manifest["approval_token_sha256"] and value["approved_concept_sha256"] == manifest["approved_concept_sha256"], f"provenance_{domain}_approval")
        checks.require(value["reference_manifest_sha256"] == manifest["reference_manifest_sha256"] == "0389dd44621684d65636c5d4d549311ab39e090d77ca9560b7522f107162c1d6", f"provenance_{domain}_reference_manifest")
        generation = value["generation"]
        checks.require(set(generation) == {"generation_id", "model", "provider", "seed", "unsupported_reason"}, f"provenance_{domain}_generation_schema")
        checks.require(generation == {"generation_id": None, "model": "gpt-image-2", "provider": "OpenAI", "seed": None, "unsupported_reason": "service does not expose stable generation IDs or seeds; prompts, accepted concepts, masters, and normalized packet bytes are hash-pinned"}, f"provenance_{domain}_generation")
        foreground = value["foreground_extraction"]
        checks.require(set(foreground) == {"model_assignment", "models", "provider", "version"}, f"provenance_{domain}_foreground_schema")
        checks.require(foreground["provider"] == "rembg" and foreground["version"] == "2.0.67" and foreground["model_assignment"] == expected_assignment and foreground["models"] == expected_models, f"provenance_{domain}_foreground")
        normalization = value["normalization"]
        checks.require(set(normalization) == {"canonical_backend", "fallback_backend", "generator_files", "seed"}, f"provenance_{domain}_normalization_schema")
        checks.require(normalization["canonical_backend"] == {"name": "python-pillow", "pillow": "12.3.0", "python": "3.12.3"}, f"provenance_{domain}_canonical_backend")
        checks.require(normalization["fallback_backend"] == {"godot": "4.7.1.stable.official.a13da4feb", "name": "godot-image"} and normalization["seed"] is None, f"provenance_{domain}_fallback_backend")
        checks.require(set(value["evidence"]) == set(expected_evidence_paths), f"provenance_{domain}_evidence_schema")
        for key in sorted(expected_evidence_paths):
            record = value["evidence"][key]
            checks.require(record["path"] == expected_evidence_paths[key], f"provenance_{domain}_evidence_{key}_path")
            check_file(checks, project, record, f"provenance_{domain}_evidence_{key}")
        checks.require([record["path"] for record in normalization["generator_files"]] == expected_generators, f"provenance_{domain}_generator_schema")
        for index, record in enumerate(normalization["generator_files"]):
            check_file(checks, project, record, f"provenance_{domain}_generator_{index}")
        checks.require(value["license"] == {"human_contribution": "direction, approved concept selection, rejection decisions, deterministic transformation contracts, and runtime-boundary ownership", "source": "original GPT Image 2 production masters and project-controlled deterministic normalization", "spdx": "LicenseRef-Project-Owned"}, f"provenance_{domain}_license")


def verify(project: Path, report_path: Path) -> None:
    checks = Checks()
    root = project / "staging" / "character-vfx" / "aui-11"
    manifest_path = root / "batch-manifest.json"
    manifest = parse_json(manifest_path)
    checks.require(manifest["schema_version"] == 1 and manifest["batch_id"] == "AUI-11", "manifest_identity")
    checks.require(manifest["state"] == "PRODUCTION_PACKETS_STAGED_RUNTIME_UNBOUND", "manifest_state")
    checks.require(manifest["production_assets_emitted"] is True, "production_emitted")
    checks.require(manifest["runtime_assets_changed"] is False, "runtime_assets_unchanged")
    checks.require(manifest["runtime_binding"] == "UNBOUND_AGENT_F_SEAM", "runtime_unbound")
    checks.require(manifest["human_final_art"] == "UNSET_HUMAN_ONLY", "human_final_unset")
    checks.require(manifest["approval_token_sha256"] == "5ab42289310a3176718a2d2c4c70f91aa87041564aaac0c6652bbf3295ece93b", "approval_token")
    checks.require(manifest["approved_concept_sha256"] == APPROVED, "approved_hashes")
    packet_records = manifest["packets"]
    checks.require(len(packet_records) == 7, "packet_count")
    checks.require({record["logical_id"] for record in packet_records} == EXPECTED_PACKET_IDS, "packet_ids")
    git_scope_checks(checks, project)
    verify_bound_oracles(checks, project, manifest)
    verify_dual_receipt(checks, project, manifest)
    verify_provenance(checks, project, manifest)
    products: dict[str, list[Image.Image]] = {}
    for record in packet_records:
        packet = str(record["logical_id"])
        prefix = f"packet_{packet}"
        checks.require(record["state"] == "PRODUCTION_PACKET_STAGED_RUNTIME_UNBOUND", f"{prefix}_state")
        checks.require(record["human_final_art"] == "UNSET_HUMAN_ONLY", f"{prefix}_human_final")
        checks.require(record["runtime_binding"] == "UNBOUND_AGENT_F_SEAM", f"{prefix}_runtime")
        check_file(checks, project, record["master"], f"{prefix}_master")
        check_file(checks, project, record["spec"], f"{prefix}_spec")
        source_records = record["sources"]
        checks.require(len(source_records) == 8, f"{prefix}_source_count")
        source_paths = [check_file(checks, project, item, f"{prefix}_source_{index}") for index, item in enumerate(source_records)]
        checks.require([path.name for path in source_paths] == [f"frame_{index:02d}.png" for index in range(8)], f"{prefix}_source_order")
        outputs = record["canonical_outputs"]
        atlas_path = check_file(checks, project, outputs["atlas"], f"{prefix}_atlas")
        contact_path = check_file(checks, project, outputs["contact"], f"{prefix}_contact")
        metadata_path = check_file(checks, project, outputs["metadata"], f"{prefix}_metadata")
        qa_path = check_file(checks, project, outputs["qa"], f"{prefix}_qa_file")
        atlas = rgba(atlas_path)
        contact = rgba(contact_path)
        metadata = parse_json(metadata_path)
        qa = parse_json(qa_path)
        checks.require(atlas.size == (768, 384), f"{prefix}_atlas_size", str(atlas.size))
        checks.require(contact.size == (1536, 256), f"{prefix}_contact_size", str(contact.size))
        checks.require(qa["status"] == "PASS" and qa["checks_executed"] == 42, f"{prefix}_qa")
        checks.require(all(item["ok"] is True for item in qa["checks"]), f"{prefix}_qa_checks")
        checks.require(metadata["provenance"]["approved_concept_sha256"] == APPROVED, f"{prefix}_metadata_approval")
        checks.require(metadata["human_final_art"] == "UNSET_HUMAN_ONLY", f"{prefix}_metadata_human")
        checks.require(metadata["runtime_binding"] == "UNBOUND_AGENT_F_SEAM", f"{prefix}_metadata_runtime")
        checks.require(metadata["atlas"]["rgba_sha256"] == hashlib.sha256(atlas.tobytes()).hexdigest(), f"{prefix}_atlas_rgba")
        checks.require(metadata["contact"]["rgba_sha256"] == hashlib.sha256(contact.tobytes()).hexdigest(), f"{prefix}_contact_rgba")
        checks.require(record["fallback_decoded_rgba_sha256"]["atlas"] == hashlib.sha256(atlas.tobytes()).hexdigest(), f"{prefix}_fallback_atlas")
        checks.require(record["fallback_decoded_rgba_sha256"]["contact"] == hashlib.sha256(contact.tobytes()).hexdigest(), f"{prefix}_fallback_contact")
        frame_cells = cells(atlas)
        for index, cell in enumerate(frame_cells):
            alpha = cell.getchannel("A")
            checks.require(alpha.getbbox() is not None, f"{prefix}_nonempty_{index}")
            border = alpha.crop((0, 0, 192, 1)).tobytes() + alpha.crop((0, 191, 192, 192)).tobytes() + alpha.crop((0, 0, 1, 192)).tobytes() + alpha.crop((191, 0, 192, 192)).tobytes()
            checks.require(max(border, default=0) == 0, f"{prefix}_border_{index}")
            rgba_bytes = cell.tobytes()
            reserved = any(
                rgba_bytes[offset + 3] and rgba_bytes[offset : offset + 3] in RESERVED
                for offset in range(0, len(rgba_bytes), 4)
            )
            checks.require(not reserved, f"{prefix}_reserved_{index}")
        for index in range(7):
            checks.require(frame_cells[index].tobytes() != frame_cells[index + 1].tobytes(), f"{prefix}_adjacent_{index}")
        for start in (0, 4):
            value = overlap(occupied(frame_cells[start]), occupied(frame_cells[start + 3]))
            first, last = center(frame_cells[start]), center(frame_cells[start + 3])
            drift = max(abs(first[0] - last[0]), abs(first[1] - last[1]))
            checks.require(value >= 0.92, f"{prefix}_loop_iou_{start}", f"iou={value:.6f}")
            checks.require(drift <= 1, f"{prefix}_loop_drift_{start}", f"drift={drift}")
        products[packet] = frame_cells

    for index, (base, charmed) in enumerate(zip(products["grunt"], products["grunt_charmed"])):
        checks.require(base.getchannel("A").tobytes() == charmed.getchannel("A").tobytes(), f"charm_alpha_{index}")
        differences = sum(1 for left, right in zip(base.convert("L").tobytes(), charmed.convert("L").tobytes()) if left != right)
        checks.require(differences >= 128, f"charm_grayscale_{index}", f"different={differences}")

    metrics: dict[str, list[tuple[int, int, int, int, int]]] = {}
    for packet, ranges in VFX_RANGES.items():
        metrics[packet] = [bbox_metrics(cell) for cell in products[packet]]
        for index, values in enumerate(metrics[packet]):
            width, height, area, center_x, bottom = values
            checks.require(ranges[0][0] <= width <= ranges[0][1], f"{packet}_width_{index}", str(width))
            checks.require(ranges[1][0] <= height <= ranges[1][1], f"{packet}_height_{index}", str(height))
            checks.require(ranges[2][0] <= area <= ranges[2][1], f"{packet}_area_{index}", str(area))
            checks.require(center_x == 96 and bottom == 180, f"{packet}_anchor_{index}", str(values))
    for index in range(8):
        checks.require(metrics["attack_hit"][index][0] < metrics["deploy"][index][0] and metrics["attack_hit"][index][0] < metrics["charm_vfx"][index][0], f"attack_width_order_{index}")
        checks.require(metrics["attack_hit"][index][2] < metrics["deploy"][index][2] and metrics["attack_hit"][index][2] < metrics["charm_vfx"][index][2], f"attack_area_order_{index}")
        checks.require(open_window(products["deploy"][index], 18, 10) == 0, f"deploy_open_{index}")
        checks.require(open_window(products["charm_vfx"][index], 10, 6) == 0, f"charm_vfx_open_{index}")

    report = {
        "schema_version": 1,
        "status": "PASS",
        "checks_executed": checks.count,
        "manifest_sha256": sha256(manifest_path),
        "packets": sorted(EXPECTED_PACKET_IDS),
        "checks": checks.records,
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "checks_executed": checks.count, "report": str(report_path)}, sort_keys=True))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    verify(args.project.resolve(), args.report.resolve())


if __name__ == "__main__":
    main()
