#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path

TOKEN = "ACT-II-S2-S3-H0"
STATE = "CANDIDATE_MACHINE_CONFORMANT_H1_PENDING"
MODEL = "gpt-image-2"
PROVIDER = "Manus built-in image generation"
TOOL = "Manus built-in image generation / generate_image"
PACKETS = {
    "act2-shared": {
        "ledger": "source-ledger.json",
        "source": "act2-shared-production-source.png",
        "refs": [
            "art-src/world/act2-references/act2-shared-style-material-board.png",
            "art-src/world/act2-references/act2-shared-tile-route-kit.png",
            "art-src/world/act2-references/act2-stage-owned-endpoints-blockers.png",
        ],
        "min_rejected": 0,
    },
    "s2": {
        "ledger": "source-ledger.json",
        "source": "s2-production-source.png",
        "refs": [
            "art-src/world/act2-references/act2-shared-style-material-board.png",
            "art-src/world/act2-references/s2-counterpressure-transfer-hall-keyframe-v2.png",
            "art-src/world/act2-references/act2-shared-tile-route-kit.png",
            "art-src/world/act2-references/act2-stage-owned-endpoints-blockers.png",
        ],
        "min_rejected": 0,
    },
    "s3": {
        "ledger": "gpt-image-2-source-ledger.json",
        "source": "s3-production-source.png",
        "refs": [
            "art-src/world/act2-references/act2-shared-style-material-board.png",
            "art-src/world/act2-references/s3-compressed-strata-lockhall-keyframe-v6.png",
            "art-src/world/act2-references/act2-stage-owned-endpoints-blockers.png",
            "art-src/world/s3/rejected/s3-pre-lineage-source.png",
        ],
        "min_rejected": 2,
    },
}
H0_REFERENCES = {
    "act2-shared-style-material-board.png",
    "act2-shared-tile-route-kit.png",
    "act2-stage-owned-endpoints-blockers.png",
    "s2-counterpressure-transfer-hall-keyframe-v2.png",
    "s3-compressed-strata-lockhall-keyframe-v6.png",
}

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def load(path: Path) -> dict:
    value=json.loads(path.read_text(encoding="utf-8"))
    assert isinstance(value,dict), path
    return value

def validate(root: Path) -> list[str]:
    root=root.resolve(); seen_h0=set()
    ref_dir=root/"art-src/world/act2-references"
    assert {p.name for p in ref_dir.iterdir() if p.is_file()} == H0_REFERENCES
    for packet,spec in PACKETS.items():
        base=root/f"art-src/world/{packet}"
        selection_path=base/"production-source-selection.json"
        prompt_path=base/"production-prompt-contract.md"
        source_path=base/spec["source"]
        ledger_path=base/spec["ledger"]
        for path in (selection_path,prompt_path,source_path,ledger_path): assert path.is_file(), path
        selection=load(selection_path); ledger=load(ledger_path)
        assert selection["packet"]==packet and selection["state"]==STATE
        assert selection["approval_token"]==TOKEN and selection["human_final_art"] is False
        assert selection["selection_count"]==1
        assert selection["prompt"]=={"path":prompt_path.relative_to(root).as_posix(),"sha256":sha(prompt_path)}
        references=selection["references"]
        assert [r["path"] for r in references]==spec["refs"]
        assert len({r["path"] for r in references})==len(references)
        for reference in references:
            path=root/reference["path"]
            assert path.is_file() and sha(path)==reference["sha256"] and reference["role"]
            if path.parent==ref_dir: seen_h0.add(path.name)
        generator=selection["generator"]
        assert generator["model"]==MODEL and generator["provider"]==PROVIDER and generator["tool"]==TOOL
        assert generator["generation_id"] is None and generator["seed"] is None
        assert "UNAVAILABLE" in generator["generation_id_reason"] and generator["generation_id_reason"]
        assert "UNAVAILABLE" in generator["seed_reason"] and generator["seed_reason"]
        selected=selection["selected_candidate"]
        selected_path=root/selected["path"]
        assert selected_path.is_file() and sha(selected_path)==selected["sha256"] and selected["reason"]
        assert selected["canonical_source_path"]==source_path.relative_to(root).as_posix()
        assert sha(source_path)==selected["sha256"]
        rejected=selection["rejected_candidates"]
        assert isinstance(rejected,list) and len(rejected)>=spec["min_rejected"]
        if packet != "s3": assert rejected == []
        seen_candidates={selected["path"]}
        for item in rejected:
            assert set(item)>={"path","sha256","reason"}
            path=root/item["path"]
            assert path.is_file() and sha(path)==item["sha256"] and item["reason"]
            assert item["path"] not in seen_candidates
            seen_candidates.add(item["path"])
        if packet=="s3":
            assert len(rejected)>=2
            assert any("zigzag/diamond terrain rhythm" in x["reason"] for x in rejected)
            assert any(x.get("lineage_complete") is False and "REJECTED for lineage incompleteness" in x["reason"] for x in rejected)
        assert ledger["state"]==STATE and ledger["approval_token"]==TOKEN and ledger["human_final_art"] is False
        assert ledger["prompt"]==selection["prompt"] and ledger["references"]==references
        assert ledger["selection"]=={"path":selection_path.relative_to(root).as_posix(),"sha256":sha(selection_path)}
        ledger_generator=ledger["generator"] if "generator" in ledger else ledger
        for key in ("model","provider","tool","generation_id","generation_id_reason","seed","seed_reason"):
            assert ledger_generator[key]==generator[key]
        if packet=="s3":
            assert ledger["source"]==source_path.relative_to(root).as_posix() and ledger["source_sha256"]==sha(source_path)
            assert ledger["selected_candidate"]==selected
        else:
            assert ledger["source"]["path"]==source_path.relative_to(root).as_posix() and ledger["source"]["sha256"]==sha(source_path)
            assert ledger["approval"]["content_hash_launch_dependency"] is False
        serialized=json.dumps(selection)+json.dumps(ledger)
        assert "ACT-II-S2-S3-H0" in serialized
        forbidden=("human_final_art\": true","approved_content_hash_gates_launch\": true","content_hash_launch_dependency\": true")
        assert not any(token in serialized for token in forbidden)
    assert seen_h0==H0_REFERENCES
    return ["exactly three packet ledgers", "exactly five unique H0 reference files", "prompt/reference/selection/source/candidate hashes bound", "truthful generator null facts and rejection structures"]

def main() -> int:
    ap=argparse.ArgumentParser(); ap.add_argument("--repo-root",type=Path,default=Path(__file__).resolve().parents[3]); args=ap.parse_args()
    print(json.dumps({"status":"PASS","checks":validate(args.repo_root)},sort_keys=True)); return 0
if __name__=="__main__": raise SystemExit(main())
