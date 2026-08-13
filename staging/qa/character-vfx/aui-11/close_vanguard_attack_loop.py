#!/usr/bin/env python3
"""Close Vanguard's row-1 attack loop by copying anticipation into recovery."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--master", required=True)
    parser.add_argument("--source-root", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()
    master_path = Path(args.master).resolve()
    source_root = Path(args.source_root).resolve()
    report_path = Path(args.report).resolve()
    frame_start = source_root / "frame_04.png"
    frame_recovery = source_root / "frame_07.png"
    before = {
        "master_sha256": sha256(master_path),
        "start_sha256": sha256(frame_start),
        "recovery_sha256": sha256(frame_recovery),
    }

    with Image.open(master_path) as raw:
        raw.load()
        master = raw.convert("RGBA")
    if master.size != (2560, 1440):
        raise ValueError(f"unexpected master size: {master.size}")
    start_cell = master.crop((0, 720, 640, 1440))
    master.paste(start_cell, (1920, 720))
    master.save(master_path, format="PNG", optimize=False, compress_level=9)
    shutil.copyfile(frame_start, frame_recovery)

    report = {
        "schema_version": "mgs.aui11.vanguard-loop-closure.v1",
        "operation": "copy_row1_frame0_to_row1_frame3",
        "reason": "attack recovery must close to anticipation without weakening loop_iou_min_0.92",
        "before": before,
        "after": {
            "master_sha256": sha256(master_path),
            "start_sha256": sha256(frame_start),
            "recovery_sha256": sha256(frame_recovery),
            "start_recovery_byte_equal": frame_start.read_bytes() == frame_recovery.read_bytes(),
        },
    }
    if report["after"]["start_recovery_byte_equal"] is not True:
        raise AssertionError("loop closure copy failed")
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "report": str(report_path)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
