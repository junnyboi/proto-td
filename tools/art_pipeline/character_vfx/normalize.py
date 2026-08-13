#!/usr/bin/env python3
"""CLI for the AUI-34 canonical Python normalization backend."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PACKAGE_DIR = Path(__file__).resolve().parent
if str(PACKAGE_DIR) not in sys.path:
    sys.path.insert(0, str(PACKAGE_DIR))

from pipeline import build_packet, fail_payload, validate_packet  # noqa: E402


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    subparsers = result.add_subparsers(dest="command", required=True)
    for command in ("build", "validate"):
        sub = subparsers.add_parser(command)
        sub.add_argument("--spec", type=Path, required=True)
        sub.add_argument("--input-root", type=Path, required=True)
        sub.add_argument("--output", type=Path, required=True)
        if command == "build":
            sub.add_argument("--clean", action="store_true")
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "build":
            metadata = build_packet(args.spec, args.input_root, args.output, args.clean)
            payload = {
                "status": "PASS",
                "asset_id": metadata["asset_id"],
                "run_identity": metadata["run_identity"],
                "output": args.output.name,
            }
        else:
            result = validate_packet(args.output, args.spec, args.input_root)
            payload = {"status": "PASS", "checks_executed": result["checks_executed"], "output": args.output.name}
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
        return 0
    except Exception as error:  # fail-closed CLI boundary
        print(json.dumps(fail_payload(error), sort_keys=True, separators=(",", ":")), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
