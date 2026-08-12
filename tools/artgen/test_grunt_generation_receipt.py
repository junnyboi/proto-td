#!/usr/bin/env python3
"""Adversarial negative controls for the grunt generation-receipt gate."""

from __future__ import annotations

import argparse
import copy
import hashlib
import importlib.util
import json
import shutil
import tempfile
from pathlib import Path
from typing import Callable

Mutation = Callable[[dict[str, object]], None]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_compiler(path: Path):
    spec = importlib.util.spec_from_file_location("grunt_compiler", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def write_manifest(bundle: Path) -> None:
    lines = []
    for path in sorted(candidate for candidate in bundle.rglob("*") if candidate.is_file()):
        if path.name == "sha256.txt":
            continue
        lines.append(f"{sha256(path)}  ./{path.relative_to(bundle).as_posix()}")
    (bundle / "sha256.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


def request(receipt: dict[str, object], request_id: str) -> dict[str, object]:
    requests = receipt["requests"]
    assert isinstance(requests, list)
    return next(item for item in requests if item["request_id"] == request_id)


def mutate_delete_contracts(receipt: dict[str, object]) -> None:
    receipt.pop("action_contracts")


def mutate_delete_request(receipt: dict[str, object]) -> None:
    requests = receipt["requests"]
    assert isinstance(requests, list)
    requests.pop()


def mutate_disclosures(receipt: dict[str, object]) -> None:
    receipt["disclosures"] = ["x"]


def mutate_tool(receipt: dict[str, object]) -> None:
    request(receipt, "keyframe_walk_se")["tool"] = "invented/provider"


def mutate_model(receipt: dict[str, object]) -> None:
    request(receipt, "keyframe_walk_se")["model"] = "invented-model"


def mutate_prompt_hash(receipt: dict[str, object]) -> None:
    request(receipt, "keyframe_walk_se")["canonical_reproduction_prompt_sha256"] = "0" * 64


def mutate_reference_hash(receipt: dict[str, object]) -> None:
    request(receipt, "keyframe_walk_se")["references"][0]["sha256"] = "0" * 64


def mutate_output_hash(receipt: dict[str, object]) -> None:
    request(receipt, "video_walk_se")["output"]["sha256"] = "0" * 64


def mutate_seed_status(receipt: dict[str, object]) -> None:
    request(receipt, "keyframe_walk_se")["seed_status"] = ""


def mutate_provider_status(receipt: dict[str, object]) -> None:
    request(receipt, "keyframe_walk_se")["provider_request_id_status"] = ""


def mutate_local_id(receipt: dict[str, object]) -> None:
    request(receipt, "keyframe_walk_se")["local_receipt_id"] = "0" * 64


def mutate_job_spec(receipt: dict[str, object]) -> None:
    receipt["confirmed_job_spec"]["sha256"] = "0" * 64


def mutate_builder(receipt: dict[str, object]) -> None:
    receipt["deterministic_postprocess"]["walk_builder"]["sha256"] = "0" * 64


def mutate_source_derivation(receipt: dict[str, object]) -> None:
    receipt["compiled_source_sheets"]["walk_se"]["derivation"] = ""


MUTATIONS: dict[str, Mutation] = {
    "action_contracts_required": mutate_delete_contracts,
    "request_graph_complete": mutate_delete_request,
    "disclosures_nonvacuous": mutate_disclosures,
    "tool_allowlist": mutate_tool,
    "model_allowlist": mutate_model,
    "prompt_hash_bound": mutate_prompt_hash,
    "reference_hash_bound": mutate_reference_hash,
    "output_hash_bound": mutate_output_hash,
    "seed_disclosure_required": mutate_seed_status,
    "provider_id_disclosure_required": mutate_provider_status,
    "local_receipt_id_bound": mutate_local_id,
    "job_spec_bound": mutate_job_spec,
    "builder_bound": mutate_builder,
    "source_derivation_required": mutate_source_derivation,
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compiler", required=True, type=Path)
    parser.add_argument("--receipt", required=True, type=Path)
    parser.add_argument("--bundle", required=True, type=Path)
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()

    compiler = load_compiler(args.compiler.resolve())
    source_paths = {
        (state, direction): args.input_dir.resolve() / f"chibi_grunt_{state}_{direction}.png"
        for state in compiler.STATES
        for direction in compiler.DIRECTIONS
    }
    original = json.loads(args.receipt.read_text(encoding="utf-8"))
    compiler.validate_generation_receipt(
        args.receipt.resolve(), args.bundle.resolve(), source_paths
    )

    results = []
    for name, mutate in MUTATIONS.items():
        with tempfile.TemporaryDirectory(prefix=f"td015-{name}-") as temp_name:
            temp = Path(temp_name)
            bundle = temp / "bundle"
            shutil.copytree(args.bundle, bundle)
            receipt = copy.deepcopy(original)
            mutate(receipt)
            receipt_path = temp / "receipt.json"
            serialized = json.dumps(receipt, indent=2, sort_keys=True) + "\n"
            receipt_path.write_text(serialized, encoding="utf-8")
            bundle_receipt = bundle / "grunt_animation.generation_receipt.json"
            bundle_receipt.chmod(0o644)
            bundle_receipt.write_text(serialized, encoding="utf-8")
            (bundle / "sha256.txt").chmod(0o644)
            write_manifest(bundle)
            rejected = False
            message = ""
            try:
                compiler.validate_generation_receipt(receipt_path, bundle, source_paths)
            except RuntimeError as error:
                rejected = True
                message = str(error)
            if not rejected:
                raise RuntimeError(f"negative control passed: {name}")
            results.append({"name": name, "status": "REJECTED", "detail": message})

    report = {
        "status": "PASS",
        "positive_control": "ACCEPTED",
        "negative_controls": results,
        "negative_control_count": len(results),
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "negative_controls": len(results)}))


if __name__ == "__main__":
    main()
