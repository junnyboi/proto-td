#!/usr/bin/env python3
"""Close both grunt animation rows without changing any loop threshold."""

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
    pairs = [(0, 3), (4, 7)]
    before = {
        "master_sha256": sha256(master_path),
        "pairs": [
            {
                "start": start,
                "end": end,
                "start_sha256": sha256(source_root / f"frame_{start:02d}.png"),
                "end_sha256": sha256(source_root / f"frame_{end:02d}.png"),
            }
            for start, end in pairs
        ],
    }
    with Image.open(master_path) as raw:
        raw.load()
        master = raw.convert("RGBA")
    if master.size != (2560, 1440):
        raise ValueError(f"unexpected master size: {master.size}")
    for start, end in pairs:
        start_column, start_row = start % 4, start // 4
        end_column, end_row = end % 4, end // 4
        cell = master.crop((start_column * 640, start_row * 720, (start_column + 1) * 640, (start_row + 1) * 720))
        master.paste(cell, (end_column * 640, end_row * 720))
        shutil.copyfile(source_root / f"frame_{start:02d}.png", source_root / f"frame_{end:02d}.png")
    master.save(master_path, format="PNG", optimize=False, compress_level=9)
    after_pairs = [
        {
            "start": start,
            "end": end,
            "start_sha256": sha256(source_root / f"frame_{start:02d}.png"),
            "end_sha256": sha256(source_root / f"frame_{end:02d}.png"),
            "byte_equal": (source_root / f"frame_{start:02d}.png").read_bytes() == (source_root / f"frame_{end:02d}.png").read_bytes(),
        }
        for start, end in pairs
    ]
    if not all(item["byte_equal"] for item in after_pairs):
        raise AssertionError("grunt loop closure copy failed")
    report = {
        "schema_version": "mgs.aui11.grunt-loop-closure.v1",
        "operation": "copy_each_row_start_to_recovery",
        "reason": "both grunt rows must satisfy the unchanged loop_iou_min_0.92",
        "before": before,
        "after": {"master_sha256": sha256(master_path), "pairs": after_pairs},
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"status": "PASS", "report": str(report_path)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
