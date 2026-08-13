#!/usr/bin/env python3
"""Prove a late candidate-validation failure preserves the accepted packet."""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
TOOLS = HERE.parents[2] / "tools/art_pipeline/character_vfx"
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

import pipeline  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spec", type=Path, required=True)
    parser.add_argument("--input-root", type=Path, required=True)
    parser.add_argument("--accepted", type=Path, required=True)
    args = parser.parse_args()
    before = {path.name: path.read_bytes() for path in args.accepted.iterdir() if path.is_file()}
    original_validate = pipeline.validate_packet

    def corrupt_then_validate(packet_dir: Path, spec_path: Path, input_root: Path) -> dict[str, object]:
        (packet_dir / "unknown-payload").mkdir()
        return original_validate(packet_dir, spec_path, input_root)

    pipeline.validate_packet = corrupt_then_validate
    failed = False
    try:
        pipeline.build_packet(args.spec, args.input_root, args.accepted, clean=True)
    except pipeline.PipelineError as error:
        failed = "packet.inventory" in str(error)
    finally:
        pipeline.validate_packet = original_validate
    after = {path.name: path.read_bytes() for path in args.accepted.iterdir() if path.is_file()}
    debris = sorted(
        path.name
        for path in args.accepted.parent.iterdir()
        if path.name.startswith(f".{args.accepted.name}.")
    )
    if not failed or before != after or debris:
        print(f"late-candidate-preservation failed={failed} bytes_equal={before == after} debris={debris}", file=sys.stderr)
        return 2
    print("late-candidate-preservation PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
