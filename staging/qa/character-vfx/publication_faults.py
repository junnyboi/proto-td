#!/usr/bin/env python3
"""Inject directory-publication failures without production test hooks."""

from __future__ import annotations

import argparse
import base64
import os
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


def snapshot(root: Path) -> dict[str, tuple[str, bytes | str | None]]:
    result: dict[str, tuple[str, bytes | str | None]] = {}

    def visit(directory: Path) -> None:
        for path in sorted(directory.iterdir(), key=lambda entry: entry.name):
            relative = path.relative_to(root).as_posix()
            if path.is_symlink():
                result[relative] = ("symlink", os.readlink(path))
            elif path.is_dir():
                result[relative] = ("directory", None)
                visit(path)
            elif path.is_file():
                result[relative] = ("file", path.read_bytes())
            else:
                result[relative] = ("other", None)

    visit(root)
    return result


def salvage_snapshot(path: Path) -> dict[str, tuple[str, bytes | str | None]]:
    payload = pipeline.load_json(path)
    if payload.get("schema_version") != 1 or not isinstance(payload.get("entries"), list):
        raise RuntimeError("salvage payload schema mismatch")
    result: dict[str, tuple[str, bytes | str | None]] = {}
    for entry in payload["entries"]:
        relative = entry["path"]
        entry_type = entry["type"]
        if entry_type == "directory":
            result[relative] = ("directory", None)
        elif entry_type == "symlink":
            result[relative] = ("symlink", entry["target"])
        elif entry_type == "file":
            result[relative] = ("file", base64.b64decode(entry["data_base64"], validate=True))
        else:
            raise RuntimeError(f"unknown salvage entry type={entry_type!r}")
    return result


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
    before = snapshot(output)
    original = pipeline._remove_tree

    def remove_tree(path: Path) -> None:
        if Path(path).name.startswith(".cleanup-output.rollback."):
            raise OSError("injected cleanup failure before deletion")
        original(path)

    pipeline._remove_tree = remove_tree
    failed = False
    detail = ""
    try:
        pipeline._publish(candidate, output, clean=True)
    except pipeline.PipelineError as error:
        failed = True
        detail = str(error)
    finally:
        pipeline._remove_tree = original
    if not failed or "backup cleanup failed" not in detail:
        raise RuntimeError(f"cleanup failure did not return nonzero detail={detail!r}")
    if (output / "generation.txt").read_text(encoding="utf-8") != "new\n":
        raise RuntimeError("cleanup failure changed committed generation")
    backups = [path for path in root.glob(".cleanup-output.rollback.*") if path.is_dir()]
    salvages = list(root.glob(".cleanup-output.rollback.*.salvage.json"))
    if len(backups) != 1 or snapshot(backups[0]) != before:
        raise RuntimeError("cleanup failure did not retain complete prior packet")
    if len(salvages) != 1 or salvage_snapshot(salvages[0]) != before:
        raise RuntimeError("cleanup failure did not retain complete salvage archive")
    second_candidate = root / ".cleanup-output.candidate.2"
    second_candidate.mkdir()
    (second_candidate / "generation.txt").write_text("newer\n", encoding="utf-8")
    pipeline._publish(second_candidate, output, clean=True)
    if (output / "generation.txt").read_text(encoding="utf-8") != "newer\n":
        raise RuntimeError("stale rollback wedged the second same-process publication")
    stale_backups = [path for path in root.glob(".cleanup-output.rollback.*") if path.is_dir()]
    if stale_backups != backups:
        raise RuntimeError(f"second publication changed stale-backup set={stale_backups}")
    original(backups[0])
    salvages[0].unlink()


def cleanup_preflight_failure(root: Path) -> None:
    output, candidate = seed(root, "preflight")
    blocked = output / "blocked"
    blocked.mkdir()
    (blocked / "sentinel.txt").write_bytes(b"complete-rollback-required\n")
    before = snapshot(output)
    blocked.chmod(0)
    failed = False
    detail = ""
    try:
        pipeline._publish(candidate, output, clean=True)
    except pipeline.PipelineError as error:
        failed = True
        detail = str(error)
    backups = [path for path in root.glob(".preflight-output.rollback.*") if path.is_dir()]
    salvages = list(root.glob(".preflight-output.rollback.*.salvage.json"))
    if len(backups) == 1:
        (backups[0] / "blocked").chmod(0o700)
    if not failed or "backup salvage failed" not in detail or len(backups) != 1 or salvages:
        raise RuntimeError(f"preflight failure was not fail-closed detail={detail!r}")
    if (output / "generation.txt").read_text(encoding="utf-8") != "new\n":
        raise RuntimeError("preflight failure invalidated new packet")
    if snapshot(backups[0]) != before:
        raise RuntimeError("preflight failure changed prior rollback bytes or inventory")
    pipeline._remove_tree(backups[0])


def cleanup_partial_removal_failure(root: Path) -> None:
    output, candidate = seed(root, "partial")
    (output / "second.txt").write_bytes(b"second-old-file\n")
    before = snapshot(output)
    original = pipeline._remove_tree

    def remove_tree(path: Path) -> None:
        target = Path(path)
        if target.name.startswith(".partial-output.rollback."):
            (target / "generation.txt").unlink()
            raise OSError("injected cleanup failure after partial deletion")
        original(target)

    pipeline._remove_tree = remove_tree
    failed = False
    detail = ""
    try:
        pipeline._publish(candidate, output, clean=True)
    except pipeline.PipelineError as error:
        failed = True
        detail = str(error)
    finally:
        pipeline._remove_tree = original
    if not failed or "backup cleanup failed" not in detail:
        raise RuntimeError(f"partial cleanup did not return nonzero detail={detail!r}")
    if (output / "generation.txt").read_text(encoding="utf-8") != "new\n":
        raise RuntimeError("partial cleanup invalidated new generation")
    backups = [path for path in root.glob(".partial-output.rollback.*") if path.is_dir()]
    salvages = list(root.glob(".partial-output.rollback.*.salvage.json"))
    if len(backups) != 1 or snapshot(backups[0]) == before:
        raise RuntimeError("partial cleanup fault did not delete a live rollback entry")
    if len(salvages) != 1 or salvage_snapshot(salvages[0]) != before:
        raise RuntimeError("partial cleanup did not retain complete salvage archive")
    original(backups[0])
    salvages[0].unlink()


def cleanup_symlinks(root: Path) -> None:
    target_directory = root / "external-directory"
    target_directory.mkdir()
    directory_sentinel = target_directory / "sentinel.txt"
    directory_sentinel.write_bytes(b"directory-sentinel\n")
    file_sentinel = root / "external-file.txt"
    file_sentinel.write_bytes(b"file-sentinel\n")

    output, candidate = seed(root, "child-links")
    (output / "linked-directory").symlink_to(target_directory, target_is_directory=True)
    (output / "linked-file").symlink_to(file_sentinel)
    pipeline._publish(candidate, output, clean=True)
    if directory_sentinel.read_bytes() != b"directory-sentinel\n":
        raise RuntimeError("child-directory symlink cleanup escaped rollback")
    if file_sentinel.read_bytes() != b"file-sentinel\n":
        raise RuntimeError("child-file symlink cleanup escaped rollback")

    root_target = root / "root-link-target"
    root_target.mkdir()
    root_sentinel = root_target / "sentinel.txt"
    root_sentinel.write_bytes(b"root-sentinel\n")
    root_output = root / "root-link-output"
    root_output.symlink_to(root_target, target_is_directory=True)
    root_candidate = root / ".root-link-output.candidate.1"
    root_candidate.mkdir()
    (root_candidate / "generation.txt").write_text("new\n", encoding="utf-8")
    pipeline._publish(root_candidate, root_output, clean=True)
    if root_sentinel.read_bytes() != b"root-sentinel\n":
        raise RuntimeError("root symlink cleanup escaped rollback")


def version_guards(root: Path) -> None:
    spec = HERE / "fixtures/spec.json"
    input_root = HERE / "fixtures/source"
    valid_packet = root / "version-valid"
    pipeline.build_packet(spec, input_root, valid_packet, clean=False)
    valid_before = snapshot(valid_packet)
    original_python = pipeline.platform.python_version
    original_pillow = pipeline.PIL.__version__

    def expect_mismatch(label: str, python_version: str, pillow_version: str) -> None:
        pipeline.platform.python_version = lambda: python_version
        pipeline.PIL.__version__ = pillow_version
        build_output = root / f"version-{label}-build"
        try:
            pipeline.build_packet(spec, input_root, build_output, clean=False)
        except pipeline.PipelineError as error:
            if "backend.version" not in str(error):
                raise RuntimeError(f"{label} build failure lacked measured detail") from error
        else:
            raise RuntimeError(f"{label} build boundary accepted version mismatch")
        if build_output.exists() or list(root.glob(f".{build_output.name}.candidate.*")):
            raise RuntimeError(f"{label} build mismatch created output or candidate")
        try:
            pipeline.validate_packet(valid_packet, spec, input_root)
        except pipeline.PipelineError as error:
            if "backend.version" not in str(error):
                raise RuntimeError(f"{label} validate failure lacked measured detail") from error
        else:
            raise RuntimeError(f"{label} validate boundary accepted version mismatch")
        if snapshot(valid_packet) != valid_before:
            raise RuntimeError(f"{label} validate mismatch changed packet bytes")

    try:
        expect_mismatch("python", "3.12.4", original_pillow)
        expect_mismatch("pillow", original_python(), "12.3.1")
    finally:
        pipeline.platform.python_version = original_python
        pipeline.PIL.__version__ = original_pillow
    pipeline._require_backend_versions()


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
    cleanup_preflight_failure(args.root)
    cleanup_partial_removal_failure(args.root)
    cleanup_symlinks(args.root)
    version_guards(args.root)
    print("publication-faults PASS cases=7")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
