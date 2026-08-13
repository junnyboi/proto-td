#!/usr/bin/env python3
"""Refresh AUI-11 manifest records after an owned packet promotion."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

PACKETS = {
    "vanguard_1": ("aui11-vanguard_1", "vanguard_1-master.png"),
    "portrait_vanguard_1": ("aui11-portrait_vanguard_1", "portrait_vanguard_1-master.png"),
    "grunt": ("aui11-grunt", "grunt-master.png"),
    "grunt_charmed": ("aui11-grunt_charmed", "grunt-master.png"),
    "deploy": ("aui11-deploy", "vfx_deploy-master.png"),
    "attack_hit": ("aui11-attack_hit", "vfx_attack_hit-master.png"),
    "charm_vfx": ("aui11-charm_vfx", "vfx_charm-master.png"),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgba_sha256(path: Path) -> str:
    with Image.open(path) as raw:
        raw.load()
        return hashlib.sha256(raw.convert("RGBA").tobytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    parser.add_argument("--godot-output-root", required=True)
    args = parser.parse_args()
    project = Path(args.project).resolve()
    godot_root = Path(args.godot_output_root).resolve()
    root = project / "staging/character-vfx/aui-11"
    manifest_path = root / "batch-manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    def record(path: Path) -> dict[str, object]:
        return {
            "path": "res://" + path.relative_to(project).as_posix(),
            "sha256": sha256(path),
            "bytes": path.stat().st_size,
        }

    by_id = {item["logical_id"]: item for item in manifest["packets"]}
    refreshed = []
    for packet, (slug, master_name) in PACKETS.items():
        current = by_id[packet]
        source_root = root / "sources" / packet
        packet_root = root / "packets" / packet
        godot_packet = godot_root / packet
        current["master"] = record(root / "masters" / master_name)
        current["spec"] = record(root / "specs" / f"{packet}.json")
        sources = sorted(source_root.glob("frame_*.png"))
        if [path.name for path in sources] != [f"frame_{index:02d}.png" for index in range(8)]:
            raise AssertionError(f"{packet}: source inventory")
        current["sources"] = [record(path) for path in sources]
        current["canonical_outputs"] = {
            "atlas": record(packet_root / f"{slug}.png"),
            "contact": record(packet_root / f"{slug}.contact.png"),
            "metadata": record(packet_root / f"{slug}.asset.json"),
            "qa": record(packet_root / f"{slug}.qa.json"),
        }
        current["fallback_decoded_rgba_sha256"] = {
            "atlas": rgba_sha256(godot_packet / f"{slug}.png"),
            "contact": rgba_sha256(godot_packet / f"{slug}.contact.png"),
        }
        refreshed.append(current)
    manifest["packets"] = refreshed
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "manifest_sha256": sha256(manifest_path)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
