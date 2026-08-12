#!/usr/bin/env python3
"""Run AUI-34 same-backend, negative, and cross-backend oracles."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any, Callable

from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
TOOLS = REPO / "tools/art_pipeline/character_vfx"
FIXTURES = HERE / "fixtures"
SPEC = FIXTURES / "spec.json"
EXPECTED = FIXTURES / "expected.json"
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from canonical_io import write_canonical_json  # noqa: E402
from oracle import Counter, compare_backend_content, compare_directories, load, verify_packet, verify_sources  # noqa: E402
from pixel_ops import (  # noqa: E402
    key_and_threshold,
    nearest_source_index,
    palette_map,
    remove_small_components,
)


class VerificationError(RuntimeError):
    """A verifier or subprocess contract failed."""


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--backend", choices=("python", "godot", "differential"), required=True)
    parser.add_argument("--clean", action="store_true")
    parser.add_argument("--seed", type=int, required=True)
    parser.add_argument("--input-root", type=Path, required=True)
    parser.add_argument("--process-timeout-seconds", type=int, required=True)
    parser.add_argument("--evidence-root", type=Path, required=True)
    parser.add_argument("--godot", type=Path, default=Path(os.environ.get("GODOT", Path.home() / "bin/godot")))
    return parser.parse_args()


def run(command: list[str], timeout_seconds: int, expected_success: bool = True) -> subprocess.CompletedProcess[str]:
    environment = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}
    result = subprocess.run(
        command,
        cwd=REPO,
        env=environment,
        text=True,
        capture_output=True,
        timeout=timeout_seconds,
        check=False,
    )
    if expected_success and result.returncode != 0:
        raise VerificationError(
            f"subprocess expected=0 actual={result.returncode} stderr={result.stderr.strip()!r} stdout={result.stdout.strip()!r}"
        )
    if not expected_success and result.returncode == 0:
        raise VerificationError(f"subprocess expected=nonzero actual=0 stdout={result.stdout.strip()!r}")
    return result


def python_command(spec: Path, input_root: Path, output: Path, clean: bool = True, validate: bool = False) -> list[str]:
    command = [
        sys.executable, "-B", str(TOOLS / "normalize.py"), "validate" if validate else "build",
        "--spec", str(spec), "--input-root", str(input_root), "--output", str(output),
    ]
    if clean and not validate:
        command.append("--clean")
    return command


def pure_integer_checks(counter: Counter, expected: dict[str, Any]) -> None:
    cases = {"1_to_1": (1, 1), "1_to_9": (1, 9), "9_to_1": (9, 1), "2_to_3": (2, 3), "3_to_2": (3, 2), "4_to_7": (4, 7), "7_to_4": (7, 4)}
    for name, (source_size, destination_size) in cases.items():
        measured = [nearest_source_index(index, source_size, destination_size) for index in range(destination_size)]
        counter.equal(f"nearest.hand.{name}", measured, expected["nearest_index"][name])
    for source_size in range(1, 10):
        for destination_size in range(1, 10):
            measured = [nearest_source_index(index, source_size, destination_size) for index in range(destination_size)]
            formula = [min(source_size - 1, (index * source_size) // destination_size) for index in range(destination_size)]
            counter.equal(f"nearest.exhaustive.{source_size}.{destination_size}", measured, formula)

    alpha = Image.new("RGBA", (2, 1), (10, 20, 30, 0))
    alpha.putpixel((0, 0), (10, 20, 30, 25))
    alpha.putpixel((1, 0), (10, 20, 30, 26))
    thresholded = key_and_threshold(alpha, (255, 0, 255), 26)
    counter.equal("alpha.25", thresholded.getpixel((0, 0)), (0, 0, 0, 0))
    counter.equal("alpha.26", thresholded.getpixel((1, 0)), (10, 20, 30, 255))

    tied = Image.new("RGBA", (1, 1), (1, 0, 0, 255))
    mapped = palette_map(tied, [(0, 0, 0), (2, 0, 0)])
    counter.equal("palette.tie_first", mapped.getpixel((0, 0)), (0, 0, 0, 255))

    components = Image.new("RGBA", (6, 3), (0, 0, 0, 0))
    components.putpixel((0, 0), (1, 2, 3, 255))
    for coordinate in ((3, 0), (4, 0), (3, 1), (4, 1)):
        components.putpixel(coordinate, (1, 2, 3, 255))
    filtered = remove_small_components(components, 2)
    counter.equal("component.single_removed", filtered.getpixel((0, 0)), (0, 0, 0, 0))
    counter.true(
        "component.detached_2x2_preserved",
        all(filtered.getpixel(coordinate)[3] == 255 for coordinate in ((3, 0), (4, 0), (3, 1), (4, 1))),
        "2x2 detached component changed",
    )


def _mutated_spec(root: Path, name: str, mutate: Callable[[dict[str, Any]], None]) -> Path:
    value = copy.deepcopy(load(SPEC))
    mutate(value)
    path = root / f"{name}.json"
    write_canonical_json(path, value)
    return path


def _expect_build_failure(
    spec_path: Path,
    input_root: Path,
    output: Path,
    timeout_seconds: int,
    counter: Counter,
    expected_detail: str,
) -> None:
    if output.exists():
        shutil.rmtree(output)
    result = run(python_command(spec_path, input_root, output), timeout_seconds, expected_success=False)
    counter.true("negative.exit_nonzero", result.returncode != 0, f"actual={result.returncode}")
    counter.true("negative.measured_detail", expected_detail in result.stderr, f"needle={expected_detail!r} stderr={result.stderr!r}")
    counter.true("negative.no_publication", not output.exists(), f"output_exists={output.exists()}")


def _custom_input_root(root: Path, name: str) -> Path:
    destination = root / name
    destination.mkdir(parents=True)
    for source in sorted(FIXTURES.joinpath("source").glob("*.png")):
        shutil.copy2(source, destination / source.name)
    return destination


def negative_checks(valid_packet: Path, root: Path, timeout_seconds: int, counter: Counter) -> None:
    specs = root / "specs"
    specs.mkdir(parents=True)
    cases: list[tuple[str, Callable[[dict[str, Any]], None], str]] = [
        ("unknown_key", lambda value: value.update({"unexpected": True}), "spec.keys"),
        ("missing_frame", lambda value: value["frames"].pop(), "frames.count"),
        ("duplicate_cell", lambda value: value["frames"][1].update({"row": 0, "column": 0}), "duplicate"),
        ("wrong_grid", lambda value: value["atlas"].update({"width": 767}), "atlas expected"),
        ("wrong_pivot", lambda value: value["atlas"].update({"pivot": [0.5, 0.93]}), "atlas expected"),
        ("malformed_color", lambda value: value["palette"].__setitem__(0, "#ffffff"), "#RRGGBB-uppercase"),
        ("version", lambda value: value.update({"schema_version": 2}), "schema_version"),
        ("version_bool", lambda value: value.update({"schema_version": True}), "schema_version"),
        ("atlas_bool", lambda value: value["atlas"].update({"width": True}), "atlas expected"),
        ("animation_float_int", lambda value: value["animations"][1].update({"fps": 8.0}), "animations expected"),
        ("threshold_float_int", lambda value: value["normalization"].update({"alpha_threshold": 26.0}), "normalization.alpha_threshold"),
        ("absolute", lambda value: value["frames"][0].update({"path": "/tmp/frame.png"}), "path-escape"),
        ("dotdot", lambda value: value["frames"][0].update({"path": "../frame.png"}), "path-escape"),
        ("backslash", lambda value: value["frames"][0].update({"path": "folder\\frame.png"}), "forbidden-separator"),
        ("colon", lambda value: value["frames"][0].update({"path": "C:frame.png"}), "forbidden-separator"),
        ("missing_source", lambda value: value["frames"][0].update({"path": "absent.png"}), "FileNotFoundError"),
        ("bad_resize", lambda value: value["normalization"].update({"resize": [0, 96]}), "normalization.resize"),
        ("reserved_palette", lambda value: value["palette"].__setitem__(0, "#F4F4F4"), "reserved-collision"),
    ]
    for name, mutate, detail in cases:
        spec_path = _mutated_spec(specs, name, mutate)
        _expect_build_failure(spec_path, FIXTURES / "source", root / f"out-{name}", timeout_seconds, counter, detail)

    symlink_root = _custom_input_root(root, "symlink-root")
    outside = root / "outside.png"
    shutil.copy2(FIXTURES / "source/frame_00.png", outside)
    (symlink_root / "frame_00.png").unlink()
    (symlink_root / "frame_00.png").symlink_to(outside)
    _expect_build_failure(SPEC, symlink_root, root / "out-symlink", timeout_seconds, counter, "realpath-escape")

    empty_root = _custom_input_root(root, "empty-root")
    Image.new("RGBA", (96, 96), (255, 0, 255, 255)).save(empty_root / "frame_00.png", format="PNG")
    _expect_build_failure(SPEC, empty_root, root / "out-empty", timeout_seconds, counter, "opaque_pixels")

    border_root = _custom_input_root(root, "border-root")
    Image.new("RGBA", (96, 96), (27, 34, 48, 255)).save(border_root / "frame_00.png", format="PNG")
    border_spec = _mutated_spec(specs, "border", lambda value: value["normalization"].update({"resize": [192, 192]}))
    _expect_build_failure(border_spec, border_root, root / "out-border", timeout_seconds, counter, "border-contact")

    tamper_cases: list[tuple[str, Callable[[Path], None], str]] = []

    def semitransparent(packet: Path) -> None:
        path = packet / "fixture-aui34.png"
        with Image.open(path) as source:
            image = source.convert("RGBA")
        image.putpixel((0, 0), (0, 0, 0, 128))
        image.save(path, format="PNG", optimize=False, compress_level=9)

    def reserved(packet: Path) -> None:
        path = packet / "fixture-aui34.png"
        with Image.open(path) as source:
            image = source.convert("RGBA")
        image.putpixel((0, 0), (244, 244, 244, 255))
        image.save(path, format="PNG", optimize=False, compress_level=9)

    def wrong_dimensions(packet: Path) -> None:
        path = packet / "fixture-aui34.png"
        with Image.open(path) as source:
            image = source.convert("RGBA").crop((0, 0, 767, 384))
        image.save(path, format="PNG", optimize=False, compress_level=9)

    def wrong_hash(packet: Path) -> None:
        path = packet / "fixture-aui34.asset.json"
        value = load(path)
        value["atlas"]["file_sha256"] = "0" * 64
        write_canonical_json(path, value)

    tamper_cases.extend([
        ("semitransparent", semitransparent, "binary_alpha"),
        ("reserved", reserved, "palette_membership"),
        ("wrong_dimensions", wrong_dimensions, "atlas_dimensions"),
        ("wrong_hash", wrong_hash, "packet.metadata"),
    ])
    for name, mutate, detail in tamper_cases:
        packet = root / f"tamper-{name}"
        shutil.copytree(valid_packet, packet)
        mutate(packet)
        result = run(python_command(SPEC, FIXTURES / "source", packet, validate=True), timeout_seconds, expected_success=False)
        counter.true(f"tamper.{name}.nonzero", result.returncode != 0, f"actual={result.returncode}")
        counter.true(f"tamper.{name}.detail", detail in result.stderr, f"stderr={result.stderr!r}")

    replacement = root / "replacement-preserved"
    shutil.copytree(valid_packet, replacement)
    replacement_before = {path.name: path.read_bytes() for path in replacement.iterdir() if path.is_file()}
    bad_replacement_spec = _mutated_spec(specs, "replacement-failure", lambda value: value.update({"schema_version": 2}))
    result = run(
        python_command(bad_replacement_spec, FIXTURES / "source", replacement, clean=True),
        timeout_seconds,
        expected_success=False,
    )
    counter.true("replacement.failure_nonzero", result.returncode != 0, f"actual={result.returncode}")
    counter.true("replacement.directory_preserved", replacement.is_dir(), f"exists={replacement.exists()}")
    replacement_after = {path.name: path.read_bytes() for path in replacement.iterdir() if path.is_file()}
    counter.equal("replacement.bytes_preserved", replacement_after, replacement_before)

    def json_tamper(name: str, target: str, mutate_json: Callable[[dict[str, Any]], None], detail: str) -> None:
        packet = root / f"json-{name}"
        shutil.copytree(valid_packet, packet)
        path = packet / target
        value = load(path)
        mutate_json(value)
        write_canonical_json(path, value)
        result = run(python_command(SPEC, FIXTURES / "source", packet, validate=True), timeout_seconds, expected_success=False)
        counter.true(f"json.{name}.nonzero", result.returncode != 0, f"actual={result.returncode}")
        counter.true(f"json.{name}.detail", detail in result.stderr, f"stderr={result.stderr!r}")

    json_tamper("metadata_unknown", "fixture-aui34.asset.json", lambda value: value.update({"unknown": 1}), "packet.metadata")
    json_tamper("metadata_missing", "fixture-aui34.asset.json", lambda value: value.pop("state"), "packet.metadata")
    json_tamper("metadata_identity", "fixture-aui34.asset.json", lambda value: value.update({"asset_id": "false.id"}), "packet.metadata")
    json_tamper("metadata_backend", "fixture-aui34.asset.json", lambda value: value["backend"].update({"name": "false"}), "packet.metadata")
    json_tamper("metadata_run", "fixture-aui34.asset.json", lambda value: value.update({"run_identity": "0" * 64}), "packet.metadata")
    json_tamper("metadata_provenance", "fixture-aui34.asset.json", lambda value: value["provenance"].update({"tool": "false"}), "packet.metadata")
    json_tamper("metadata_float_type", "fixture-aui34.asset.json", lambda value: value.update({"schema_version": 1.0}), "packet.metadata")
    json_tamper("metadata_nested_type", "fixture-aui34.asset.json", lambda value: value["atlas"].update({"width": True}), "packet.metadata")
    json_tamper("report_unknown", "fixture-aui34.qa.json", lambda value: value.update({"unknown": 1}), "packet.report")
    json_tamper("report_anchors", "fixture-aui34.qa.json", lambda value: value["measurements"].update({"anchors": []}), "packet.report")
    json_tamper("report_float_type", "fixture-aui34.qa.json", lambda value: value.update({"checks_executed": 42.0}), "packet.report")

    noncanonical = root / "json-noncanonical"
    shutil.copytree(valid_packet, noncanonical)
    noncanonical_path = noncanonical / "fixture-aui34.asset.json"
    noncanonical_path.write_text(json.dumps(load(noncanonical_path), indent=2) + "\n", encoding="utf-8")
    result = run(python_command(SPEC, FIXTURES / "source", noncanonical, validate=True), timeout_seconds, expected_success=False)
    counter.true("json.noncanonical.nonzero", result.returncode != 0, f"actual={result.returncode}")
    counter.true("json.noncanonical.detail", "canonical_bytes" in result.stderr, f"stderr={result.stderr!r}")

    duplicate = root / "json-duplicate"
    shutil.copytree(valid_packet, duplicate)
    duplicate_path = duplicate / "fixture-aui34.asset.json"
    original = duplicate_path.read_text(encoding="utf-8")
    duplicate_path.write_text('{"schema_version":1,' + original[1:], encoding="utf-8")
    result = run(python_command(SPEC, FIXTURES / "source", duplicate, validate=True), timeout_seconds, expected_success=False)
    counter.true("json.duplicate.nonzero", result.returncode != 0, f"actual={result.returncode}")
    counter.true("json.duplicate.detail", "duplicate JSON key" in result.stderr, f"stderr={result.stderr!r}")

    reencoded = root / "png-reencoded"
    shutil.copytree(valid_packet, reencoded)
    reencoded_atlas = reencoded / "fixture-aui34.png"
    with Image.open(reencoded_atlas) as source:
        image = source.convert("RGBA")
    image.save(reencoded_atlas, format="PNG", optimize=False, compress_level=0)
    metadata_path = reencoded / "fixture-aui34.asset.json"
    metadata = load(metadata_path)
    metadata["atlas"]["file_sha256"] = hashlib.sha256(reencoded_atlas.read_bytes()).hexdigest()
    write_canonical_json(metadata_path, metadata)
    result = run(python_command(SPEC, FIXTURES / "source", reencoded, validate=True), timeout_seconds, expected_success=False)
    counter.true("png.reencoded.nonzero", result.returncode != 0, f"actual={result.returncode}")
    counter.true("png.reencoded.detail", "png_canonical_bytes" in result.stderr, f"stderr={result.stderr!r}")

    unknown_directory = root / "packet-unknown-directory"
    shutil.copytree(valid_packet, unknown_directory)
    (unknown_directory / "unknown-payload").mkdir()
    result = run(python_command(SPEC, FIXTURES / "source", unknown_directory, validate=True), timeout_seconds, expected_success=False)
    counter.true("packet.unknown_directory.nonzero", result.returncode != 0, f"actual={result.returncode}")
    counter.true("packet.unknown_directory.detail", "packet.inventory" in result.stderr, f"stderr={result.stderr!r}")

    symlink_packet = root / "packet-symlink"
    shutil.copytree(valid_packet, symlink_packet)
    symlink_target = root / "symlink-target.png"
    shutil.copy2(symlink_packet / "fixture-aui34.contact.png", symlink_target)
    (symlink_packet / "fixture-aui34.contact.png").unlink()
    (symlink_packet / "fixture-aui34.contact.png").symlink_to(symlink_target)
    result = run(python_command(SPEC, FIXTURES / "source", symlink_packet, validate=True), timeout_seconds, expected_success=False)
    counter.true("packet.symlink.nonzero", result.returncode != 0, f"actual={result.returncode}")
    counter.true("packet.symlink.detail", "non-regular-or-symlink" in result.stderr, f"stderr={result.stderr!r}")

    late_accepted = root / "late-accepted"
    shutil.copytree(valid_packet, late_accepted)
    result = run(
        [sys.executable, "-B", str(HERE / "late_candidate_failure.py"), "--spec", str(SPEC),
         "--input-root", str(FIXTURES / "source"), "--accepted", str(late_accepted)],
        timeout_seconds,
    )
    counter.true("replacement.late_candidate", "PASS" in result.stdout, f"stdout={result.stdout!r}")

    result = run(
        [sys.executable, "-B", str(HERE / "publication_faults.py"), "--root", str(root / "publication-faults")],
        timeout_seconds,
    )
    counter.true("publication.fault_matrix", "cases=3" in result.stdout, f"stdout={result.stdout!r}")


def python_lane(root: Path, input_root: Path, timeout_seconds: int, expected: dict[str, Any], counter: Counter) -> tuple[Path, Path]:
    fixture_a, fixture_b = root / "fixture-build-a", root / "fixture-build-b"
    for destination in (fixture_a, fixture_b):
        run(
            [sys.executable, "-B", str(FIXTURES / "build_source_fixtures.py"), "--output", str(destination)],
            timeout_seconds,
        )
    compare_directories(fixture_a, fixture_b, counter, "fixture_builder.cross_process")
    verify_sources(fixture_a, expected, counter)
    verify_sources(input_root, expected, counter)
    pure_integer_checks(counter, expected)
    first, second = root / "run-a", root / "run-b"
    run(python_command(SPEC, input_root, first), timeout_seconds)
    run(python_command(SPEC, input_root, second), timeout_seconds)
    compare_directories(first, second, counter, "python.cross_process")
    verify_packet(first, expected, counter, canonical_png=True)
    verify_packet(second, expected, counter, canonical_png=True)
    negative_checks(first, root / "negative", timeout_seconds, counter)
    return first, second


def godot_lane(root: Path, input_root: Path, timeout_seconds: int, expected: dict[str, Any], counter: Counter, godot: Path) -> tuple[Path, Path]:
    del root, input_root, timeout_seconds, expected, counter, godot
    raise VerificationError("Godot backend not implemented yet")


def main() -> int:
    args = arguments()
    if args.seed != 42:
        raise SystemExit(f"seed expected=42 actual={args.seed}")
    input_root = args.input_root.resolve(strict=True)
    expected = load(EXPECTED)
    evidence_root = args.evidence_root.resolve()
    if evidence_root.exists():
        if not args.clean:
            raise SystemExit("evidence root exists and --clean was not supplied")
        shutil.rmtree(evidence_root)
    evidence_root.mkdir(parents=True)
    counter = Counter()
    try:
        if args.backend == "python":
            python_lane(evidence_root, input_root, args.process_timeout_seconds, expected, counter)
        elif args.backend == "godot":
            godot_lane(evidence_root, input_root, args.process_timeout_seconds, expected, counter, args.godot)
        else:
            python_packet, _ = python_lane(evidence_root / "python", input_root, args.process_timeout_seconds, expected, counter)
            godot_packet, _ = godot_lane(evidence_root / "godot", input_root, args.process_timeout_seconds, expected, counter, args.godot)
            compare_backend_content(python_packet, godot_packet, counter)
        if counter.checks <= 0:
            raise VerificationError("zero checks executed")
        summary = {
            "schema_version": 1,
            "status": "PASS",
            "backend": args.backend,
            "seed": args.seed,
            "checks_executed": counter.checks,
            "input_root": "staging/qa/character-vfx/fixtures/source",
            "evidence_scope": "external-runtime-only",
        }
        write_canonical_json(evidence_root / "summary.json", summary)
        print(json.dumps(summary, sort_keys=True, separators=(",", ":")))
        return 0
    except Exception as error:
        summary = {
            "schema_version": 1,
            "status": "FAIL",
            "backend": args.backend,
            "seed": args.seed,
            "checks_executed": counter.checks,
            "error_type": type(error).__name__,
            "detail": str(error),
        }
        write_canonical_json(evidence_root / "summary.json", summary)
        print(json.dumps(summary, sort_keys=True, separators=(",", ":")), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
