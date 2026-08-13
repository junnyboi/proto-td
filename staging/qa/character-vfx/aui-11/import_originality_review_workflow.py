#!/usr/bin/env python3
"""Import workflow/run originality reviews into AUI-11's canonical evidence schema."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

APPROVED = [
    "f3c338ec52a394e3e02a92bad65ca00e881fd340673ee6c120dec09c86b3b883",
    "db59ac74296fe4cbf6c78a3011bf78cdfd1c7814c576c7f22e8d02853d7135c9",
    "f512c5022533c53c4a84bcfd036a513d13ee5ec2667cba15283dff21fd373ea8",
    "d6db376800af86f300f6fa8ea7c62865ce4c8bb05dadd9dbe9d470776fa22ee9",
    "64039ab91598423982031948fefc30b5f9b2d93b803d51617cb88fcea2aa8dd3",
    "0a13437c7284fac6fbaf9e67be8223443bbdb3e47158a46325d007d691d17667",
]
PACKETS = ["vanguard_1", "portrait_vanguard_1", "grunt", "grunt_charmed", "deploy", "attack_hit", "charm_vfx"]
SLUGS = {packet: f"aui11-{packet}" for packet in PACKETS}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workflow-output", required=True)
    parser.add_argument("--project", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    raw = json.loads(Path(args.workflow_output).read_text(encoding="utf-8"))
    wrappers = raw["originality"]
    if len(wrappers) != 7 or not all(item.get("ok") is True for item in wrappers):
        raise ValueError("workflow must contain seven successful originality reviewers")
    reviews = [dict(item["value"]) for item in wrappers]
    for index, (packet, review) in enumerate(zip(PACKETS, reviews), start=1):
        if review["review_id"] != f"orig-{index:02d}" or review["packet_id"] != packet:
            raise ValueError(f"review identity mismatch at {index}")
    failures = [
        review["packet_id"]
        for review in reviews
        if not (
            review["verdict"] == "PASS"
            and review["recognizable_copied_signature_found"] is False
            and review["approved_concept_authenticated"] is True
            and review["generation_ledger_authenticated"] is True
        )
    ]
    if failures:
        raise AssertionError(f"originality review failures: {failures}")
    project = Path(args.project).resolve()
    packet_root = project / "staging/character-vfx/aui-11/packets"

    def locator(path: Path) -> dict[str, object]:
        return {
            "path": "res://" + path.relative_to(project).as_posix(),
            "sha256": sha256(path),
            "bytes": path.stat().st_size,
        }

    reviewed_packets = {}
    for packet in PACKETS:
        root = packet_root / packet
        slug = SLUGS[packet]
        reviewed_packets[packet] = {
            "atlas": locator(root / f"{slug}.png"),
            "contact": locator(root / f"{slug}.contact.png"),
            "metadata": locator(root / f"{slug}.asset.json"),
        }
    result = {
        "schema_version": "mgs.aui11.originality-review-results.v1",
        "batch_id": "AUI-11",
        "approval_token_sha256": "5ab42289310a3176718a2d2c4c70f91aa87041564aaac0c6652bbf3295ece93b",
        "approved_concept_sha256": APPROVED,
        "generation_ledger_sha256": sha256(project / "staging/qa/character-vfx/aui-11/generation-ledger.md"),
        "reviewed_packets": reviewed_packets,
        "reviews": reviews,
        "failures": failures,
        "status": "PASS",
    }
    output = Path(args.output).resolve()
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "reviews": len(reviews), "output": str(output)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
