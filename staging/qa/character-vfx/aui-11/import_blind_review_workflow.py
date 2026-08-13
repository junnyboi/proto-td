#!/usr/bin/env python3
"""Import a workflow/run blind-review result into AUI-11's canonical evidence schema."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workflow-output", required=True)
    parser.add_argument("--input-manifest", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    workflow_path = Path(args.workflow_output).resolve()
    manifest_path = Path(args.input_manifest).resolve()
    output_path = Path(args.output).resolve()
    raw = json.loads(workflow_path.read_text(encoding="utf-8"))
    values = raw["blind"]
    if len(values) != 10 or not all(item.get("ok") is True for item in values):
        raise ValueError("workflow must contain ten successful blind reviewers")
    reviewers = []
    for index, wrapper in enumerate(values, start=1):
        item = dict(wrapper["value"])
        item["reviewer_id"] = f"blind-{index:02d}"
        reviewers.append(item)
    expected = {
        "alpha_role": "allied_operator",
        "alpha_screen_facing": "screen_right",
        "beta_role": "hostile_construct",
        "beta_screen_facing": "screen_right",
        "charmed_side": "left",
    }
    gates = {
        "vanguard_role_facing": lambda item: item["alpha_role"] == expected["alpha_role"] and item["alpha_screen_facing"] == expected["alpha_screen_facing"],
        "grunt_role_facing": lambda item: item["beta_role"] == expected["beta_role"] and item["beta_screen_facing"] == expected["beta_screen_facing"],
        "charm_state": lambda item: item["charmed_side"] == expected["charmed_side"],
    }
    scores = {name: sum(1 for item in reviewers if predicate(item)) for name, predicate in gates.items()}
    failures = {name: [item["reviewer_id"] for item in reviewers if not predicate(item)] for name, predicate in gates.items()}
    if any(score < 8 for score in scores.values()):
        raise AssertionError(f"blind threshold failed: {scores}")
    result = {
        "schema_version": "mgs.aui11.blind-review-results.v1",
        "batch_id": "AUI-11",
        "input_manifest_sha256": sha256(manifest_path),
        "denominator": 10,
        "threshold": 8,
        "expected": expected,
        "reviewers": reviewers,
        "scores": scores,
        "failures": failures,
        "status": "PASS",
    }
    output_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "scores": scores, "output": str(output_path)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
