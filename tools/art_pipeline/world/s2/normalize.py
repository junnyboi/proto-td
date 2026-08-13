#!/usr/bin/env python3
"""S2 entry point for the atomic shared + S2 deterministic producer."""
from __future__ import annotations

import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[4]

if __name__ == "__main__":
    subprocess.run(
        ["python3", str(REPO / "tools/art_pipeline/world/act2_shared/normalize.py")],
        cwd=REPO,
        check=True,
    )
