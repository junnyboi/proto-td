#!/usr/bin/env python3
"""S2 entry point for shared + S2 package and replacement validation."""
from __future__ import annotations

import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[4]

if __name__ == "__main__":
    subprocess.run(
        ["python3", str(REPO / "tools/art_pipeline/world/act2_shared/validate.py")],
        cwd=REPO,
        check=True,
    )
