#!/usr/bin/env python3
"""Inject directory-publication failures without adding production test hooks."""

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


def seed(root: Path, label: str) -> tuple[Path, Path]:
    output = root / f"{label}-output"
    candidate = root / f".{label}-output.candidate.1"
    output.mkdir()
    candidate.mkdir()
    (output / "generation.txt").write_text("old\n", encoding="utf-8")
    (candidate / "generation.txt").write_text("new\n", encoding="utf-8")
    return output, candidate


def cutover_failure(root: Path) -> None:
    output, candidate = seed(root, "cutover")
    original = pipeline.os.replace

    def replace(source: Path, destination: Path) -> None:
        if Path(source) == candidate and Path(destination) == output:
            raise OSError("injected cutover failure")
        original(source, destination)

    pipeline.os.replace = replace
    failed = False
    try:
        pipeline._publish(candidate, output, clean=True)
    except OSError:
        failed = True
    finally:
        pipeline.os.replace = original
    if not failed or (output / "generation.txt").read_text(encoding="utf-8") != "old\n":
        raise RuntimeError("cutover failure did not restore accepted generation")
    rollback = list(root.glob(".cutover-output.rollback.*"))
    if rollback:
        raise RuntimeError(f"cutover rollback debris={rollback}")


def rollback_failure(root: Path) -> None:
    output, candidate = seed(root, "rollback")
    original = pipeline.os.replace

    def replace(source: Path, destination: Path) -> None:
        source_path, destination_path = Path(source), Path(destination)
        if source_path == candidate and destination_path == output:
            raise OSError("injected cutover failure")
        if source_path.name.startswith(".rollback-output.rollback.") and destination_path == output:
            raise OSError("injected rollback failure")
        original(source, destination)

    pipeline.os.replace = replace
    failed = False
    detail = ""
    try:
        pipeline._publish(candidate, output, clean=True)
    except pipeline.PipelineError as error:
        failed = True
        detail = str(error)
    finally:
        pipeline.os.replace = original
    backups = list(root.glob(".rollback-output.rollback.*"))
    if not failed or "accepted packet preserved" not in detail or len(backups) != 1:
        raise RuntimeError(f"rollback salvage failed={failed} detail={detail!r} backups={backups}")
    if (backups[0] / "generation.txt").read_text(encoding="utf-8") != "old\n":
        raise RuntimeError("rollback failure did not preserve accepted bytes in named backup")


def cleanup_failure(root: Path) -> None:
    output, candidate = seed(root, "cleanup")
    original = pipeline.shutil.rmtree

    def rmtree(path: Path) -> None:
        if Path(path).name.startswith(".cleanup-output.rollback."):
            raise OSError("injected cleanup failure")
        original(path)

    pipeline.shutil.rmtree = rmtree
    try:
        pipeline._publish(candidate, output, clean=True)
    finally:
        pipeline.shutil.rmtree = original
    if (output / "generation.txt").read_text(encoding="utf-8") != "new\n":
        raise RuntimeError("cleanup failure changed committed generation")
    backups = list(root.glob(".cleanup-output.rollback.*"))
    if len(backups) != 1 or (backups[0] / "generation.txt").read_text(encoding="utf-8") != "old\n":
        raise RuntimeError("cleanup failure did not retain recoverable stale backup")
    second_candidate = root / ".cleanup-output.candidate.2"
    second_candidate.mkdir()
    (second_candidate / "generation.txt").write_text("newer\n", encoding="utf-8")
    pipeline._publish(second_candidate, output, clean=True)
    if (output / "generation.txt").read_text(encoding="utf-8") != "newer\n":
        raise RuntimeError("stale backup wedged the second same-process publication")
    stale_backups = list(root.glob(".cleanup-output.rollback.*"))
    if len(stale_backups) != 1 or stale_backups[0] != backups[0]:
        raise RuntimeError(f"second publication changed stale-backup set={stale_backups}")
    original(backups[0])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    args = parser.parse_args()
    if args.root.exists():
        shutil.rmtree(args.root)
    args.root.mkdir(parents=True)
    cutover_failure(args.root)
    rollback_failure(args.root)
    cleanup_failure(args.root)
    print("publication-faults PASS cases=3")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
