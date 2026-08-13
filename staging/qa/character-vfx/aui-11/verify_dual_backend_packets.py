#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
from copy import deepcopy
from pathlib import Path

from PIL import Image, __version__ as pillow_version

PACKETS = {
    "vanguard_1": "aui11-vanguard_1",
    "portrait_vanguard_1": "aui11-portrait_vanguard_1",
    "grunt": "aui11-grunt",
    "grunt_charmed": "aui11-grunt_charmed",
    "deploy": "aui11-deploy",
    "attack_hit": "aui11-attack_hit",
    "charm_vfx": "aui11-charm_vfx",
}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def parse_json(path: Path) -> dict[str, object]:
    def no_duplicates(pairs: list[tuple[str, object]]) -> dict[str, object]:
        result: dict[str, object] = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f"duplicate JSON member {key!r} in {path}")
            result[key] = value
        return result

    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=no_duplicates)


def image_rgba_hash(path: Path) -> str:
    with Image.open(path) as raw:
        raw.load()
        return sha(raw.convert("RGBA").tobytes())


def canonical_hash(value: object) -> str:
    return sha((json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode())


def normalized_metadata(value: dict[str, object]) -> dict[str, object]:
    result = deepcopy(value)
    result.pop("backend")
    result.pop("run_identity")
    result["atlas"].pop("file_sha256")
    result["contact"].pop("file_sha256")
    return result


def normalized_qa(value: dict[str, object]) -> dict[str, object]:
    result = deepcopy(value)
    for check in result["checks"]:
        check.pop("detail")
    return result


def file_record(path: Path) -> dict[str, object]:
    return {"sha256": sha(path.read_bytes()), "bytes": path.stat().st_size}


def run(command: list[str], log: Path, cwd: Path, env: dict[str, str]) -> None:
    result = subprocess.run(command, cwd=cwd, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60, check=False)
    log.write_text(result.stdout, encoding="utf-8")
    if result.returncode != 0:
        raise RuntimeError(f"command failed ({result.returncode}); see {log}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--evidence-root", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--godot", type=Path, required=True)
    args = parser.parse_args()
    project, evidence = args.project.resolve(), args.evidence_root.resolve()
    if pillow_version != "12.3.0":
        raise RuntimeError(f"Pillow version mismatch: {pillow_version}")
    if evidence.exists():
        shutil.rmtree(evidence)
    evidence.mkdir(parents=True)
    env = dict(os.environ)
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    env["PYTHONPYCACHEPREFIX"] = str(evidence / "pycache")
    packet_root = project / "staging/character-vfx/aui-11"
    manifest_path = packet_root / "batch-manifest.json"
    manifest = parse_json(manifest_path)
    manifest_packets = {item["logical_id"]: item for item in manifest["packets"]}
    checks = 0
    records = []
    for packet, slug in PACKETS.items():
        spec = packet_root / "specs" / f"{packet}.json"
        sources = packet_root / "sources" / packet
        source_records = [{"path": path.name, **file_record(path)} for path in sorted(sources.glob("frame_*.png"))]
        if len(source_records) != 8:
            raise AssertionError(f"{packet}: expected eight sources")
        checks += 1
        runs: dict[str, dict[str, dict[str, object]]] = {"python": {}, "godot": {}}
        for backend in ("python", "godot"):
            for identity in ("a", "b"):
                output = evidence / backend / f"run-{identity}" / packet
                log = evidence / "logs" / f"{backend}-{packet}-{identity}.log"
                log.parent.mkdir(parents=True, exist_ok=True)
                if backend == "python":
                    command = ["python3", "-B", str(project / "tools/art_pipeline/character_vfx/normalize.py"), "build", "--spec", str(spec), "--input-root", str(sources), "--output", str(output), "--clean"]
                else:
                    command = [str(args.godot), "--headless", "--path", str(project), "-s", "res://tools/art_pipeline/character_vfx/godot/normalize.gd", "--", "build", "--backend", "godot", "--spec", str(spec), "--input-root", str(sources), "--output", str(output), "--clean"]
                run(command, log, project, env)
                expected_files = {f"{slug}.png", f"{slug}.contact.png", f"{slug}.asset.json", f"{slug}.qa.json"}
                actual_files = {path.name for path in output.iterdir() if path.is_file()}
                if actual_files != expected_files:
                    raise AssertionError(f"{packet}/{backend}/{identity}: inventory {actual_files}")
                atlas = output / f"{slug}.png"
                contact = output / f"{slug}.contact.png"
                metadata_path = output / f"{slug}.asset.json"
                qa_path = output / f"{slug}.qa.json"
                metadata, qa = parse_json(metadata_path), parse_json(qa_path)
                if metadata["source_hashes"] != [{"path": item["path"], "sha256": item["sha256"]} for item in source_records]:
                    raise AssertionError(f"{packet}/{backend}/{identity}: source hashes")
                if qa["status"] != "PASS" or qa["checks_executed"] != 42 or not all(item["ok"] is True for item in qa["checks"]):
                    raise AssertionError(f"{packet}/{backend}/{identity}: QA")
                checks += 2
                runs[backend][identity] = {
                    "files": {path.name: file_record(path) for path in sorted(output.iterdir()) if path.is_file()},
                    "atlas_rgba_sha256": image_rgba_hash(atlas),
                    "contact_rgba_sha256": image_rgba_hash(contact),
                    "metadata_semantic_sha256": canonical_hash(normalized_metadata(metadata)),
                    "qa_semantic_sha256": canonical_hash(normalized_qa(qa)),
                }
        for backend in ("python", "godot"):
            if runs[backend]["a"]["files"] != runs[backend]["b"]["files"]:
                raise AssertionError(f"{packet}/{backend}: same-backend bytes")
            checks += 1
        for key in ("atlas_rgba_sha256", "contact_rgba_sha256", "metadata_semantic_sha256", "qa_semantic_sha256"):
            if runs["python"]["a"][key] != runs["godot"]["a"][key]:
                raise AssertionError(f"{packet}: cross-backend {key}")
            checks += 1
        canonical = manifest_packets[packet]["canonical_outputs"]
        for filename, field in ((f"{slug}.png", "atlas"), (f"{slug}.contact.png", "contact"), (f"{slug}.asset.json", "metadata"), (f"{slug}.qa.json", "qa")):
            if runs["python"]["a"]["files"][filename]["sha256"] != canonical[field]["sha256"] or runs["python"]["a"]["files"][filename]["bytes"] != canonical[field]["bytes"]:
                raise AssertionError(f"{packet}: staged canonical {field}")
            checks += 1
        records.append({"logical_id": packet, "spec": file_record(spec), "sources": source_records, "runs": runs})
    report = {
        "schema_version": 1,
        "status": "PASS",
        "checks_executed": checks,
        "external_evidence_id": "aui-11/fresh-dual-backend",
        "batch_manifest_sha256": sha(manifest_path.read_bytes()),
        "canonical_backend": manifest["canonical_backend"],
        "fallback_backend": manifest["fallback_backend"],
        "packets": records,
    }
    args.report.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "checks_executed": checks, "report": str(args.report)}, sort_keys=True))


if __name__ == "__main__":
    main()
