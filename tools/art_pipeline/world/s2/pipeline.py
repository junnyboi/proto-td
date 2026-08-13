#!/usr/bin/env python3
"""S2 lane entry point; delegates to the unified 12-asset atomic producer/validator."""
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[4]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("generate", "validate"))
    args = parser.parse_args()
    tool = REPO / "tools/art_pipeline/world/act2_shared" / ("normalize.py" if args.action == "generate" else "validate.py")
    subprocess.run(["python3", str(tool)], cwd=REPO, check=True)


if __name__ == "__main__":
    main()
