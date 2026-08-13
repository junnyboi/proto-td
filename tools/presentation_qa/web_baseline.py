from __future__ import annotations

import argparse
import calendar
import copy
import gzip
import hashlib
import http.server
import json
import os
import platform
import re
import shutil
import socketserver
import stat
import subprocess
import tempfile
import threading
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Iterable

from PIL import Image
from playwright.sync_api import Error as PlaywrightError
from playwright.sync_api import sync_playwright


ORACLE_SHA256 = "13f854775c671e7c508192e39d9adb55b3509a79a0d697a0b99fef41b5560b26"
APPROVAL_MANIFEST_SHA256 = "0c7530b9bfa54bf8581d42596393cedfe3e06b410230c5c8565fe0a97520c200"
OWNER_DECISION_SHA256 = "d616bc95eee2aeb3c226f167c2b45c71152d6856285b169af99eeabe7c1e3f17"
REMEDIATION_SHA256 = "f35c780661b606c9c18cd8945f8590a8adc68aaf31cb273bfefc50994301b38c"
PALETTE_CONTRACT_SHA256 = "70efb6f83b1c59d45d7a5a6cfb7e4cea4dd5058827b2f908fa290e7beaecab90"
SCENARIO_CONTRACT_SHA256 = "692f7f492cb94ed28d8f8c8a44b738846ef9037d6c923841b72388d099505a01"
OWNER_DECISION_SCHEMA_SHA256 = "d7ebb62374016850a2ec282b5391703d8d5626ff0470856797760270514987d6"
START_RECEIPT_SCHEMA_SHA256 = "9488c7b9693bc6acf8cdbda6da79e16145fb58449dbe12fe1e3413a8ed67b5de"
COMPLETION_RECEIPT_SCHEMA_SHA256 = "706bd40e9a9551a9bcf266899e17e345667bc8a967cce9df9e8288d9a6ec1901"
TRANSCRIPT_SCHEMA_SHA256 = "db49c0297bcc28c219d24445276216754b5b67e4a1600bf41c7aab736d074bb9"
LEGACY_SCHEMA_SHA256 = "00561745c7527fdab2c7f829e38526251db3b03ce585c867ea9fce1d77d262e6"
CONTRACT_SCHEMA_SHA256 = "9a45d80229ed1e09f666b8b614ed3c09a9305fec20cdf850d2340aed65065a71"

PALETTE_ORDER = ("backdrop", "panel", "body", "muted", "primary", "selected", "focus", "boundary")
IMAGE_SIZE = (1280, 720)
REDUCED_SIZE = (640, 360)
REDUCED_BYTES = 230400
WAIT_BUDGETS = (1000, 3000, 6000, 12000)
FAILURE_CODES = (
    "APPROVAL_MANIFEST_INVALID",
    "CURRENT_MISSING",
    "DIMENSIONS_MISMATCH",
    "ORACLE_DIGEST_MISMATCH",
    "ORACLE_INVALID",
    "OWNER_DECISION_INVALID",
    "PALETTE_CONTRACT_DIGEST_MISMATCH",
    "PALETTE_CONTRACT_INVALID",
    "PROVENANCE_INVALID",
    "REDUCED_STREAM_INVALID",
    "REFERENCE_ALIAS",
    "REFERENCE_MISSING",
    "REPORT_INCONSISTENT",
    "RUN_RECEIPT_INVALID",
    "SCENARIO_INVALID",
    "SCHEMA_DIGEST_MISMATCH",
    "SIGNATURE_MISMATCH",
    "TRANSCRIPT_INVALID",
)

GENERATION_REQUIRED_OPTIONS = (
    "--repo", "--out", "--candidate", "--tree", "--run-receipt",
    "--run-receipt-sha256", "--owner-decision", "--owner-decision-sha256",
    "--palette-contract", "--oracle-contract", "--oracle-sha256",
    "--approval-manifest", "--approval-manifest-sha256", "--owner-decision-schema",
    "--owner-decision-schema-sha256", "--start-receipt-schema",
    "--start-receipt-schema-sha256", "--completion-receipt-schema",
    "--completion-receipt-schema-sha256", "--transcript-schema",
    "--transcript-schema-sha256", "--legacy-schema", "--legacy-schema-sha256",
    "--contract-schema", "--contract-schema-sha256",
)
VERIFY_REQUIRED_OPTIONS = (
    "--verify-output", "--repo", "--candidate", "--tree", "--run-receipt",
    "--run-receipt-sha256", "--completion-receipt", "--completion-receipt-sha256",
    "--owner-decision", "--owner-decision-sha256", "--palette-contract",
    "--oracle-contract", "--oracle-sha256", "--approval-manifest",
    "--approval-manifest-sha256", "--owner-decision-schema",
    "--owner-decision-schema-sha256", "--start-receipt-schema",
    "--start-receipt-schema-sha256", "--completion-receipt-schema",
    "--completion-receipt-schema-sha256", "--transcript-schema",
    "--transcript-schema-sha256", "--legacy-schema", "--legacy-schema-sha256",
    "--contract-schema", "--contract-schema-sha256",
)

BROWSER_LAUNCH_ARGS = (
    "--no-sandbox",
    "--enable-unsafe-swiftshader",
    "--use-angle=swiftshader",
    "--disable-dev-shm-usage",
    "--disable-background-networking",
    "--disable-component-update",
    "--disable-default-apps",
    "--disable-extensions",
    "--disable-sync",
    "--metrics-recording-only",
    "--no-first-run",
)

EXPECTED_MANIFEST_MEMBERS = {
    "remediation": ("AUI-12-WEB-BASELINE-REMEDIATION.md", REMEDIATION_SHA256),
    "oracle": ("AUI-12-WEB-ORACLE.json", ORACLE_SHA256),
    "owner_decision_schema": ("AUI-12-WEB-OWNER-DECISION-SCHEMA.json", OWNER_DECISION_SCHEMA_SHA256),
    "start_receipt_schema": ("AUI-12-WEB-START-RECEIPT-SCHEMA.json", START_RECEIPT_SCHEMA_SHA256),
    "completion_receipt_schema": ("AUI-12-WEB-COMPLETION-RECEIPT-SCHEMA.json", COMPLETION_RECEIPT_SCHEMA_SHA256),
    "transcript_schema": ("AUI-12-WEB-RUN-TRANSCRIPT-SCHEMA.json", TRANSCRIPT_SCHEMA_SHA256),
    "legacy_schema": ("AUI-12-WEB-BASELINE-LEGACY-SCHEMA.json", LEGACY_SCHEMA_SHA256),
    "contract_schema": ("AUI-12-WEB-BASELINE-CONTRACT-SCHEMA.json", CONTRACT_SCHEMA_SHA256),
    "component_contract": ("AUI-12-COMPONENT-CONTRACT.json", PALETTE_CONTRACT_SHA256),
    "scenario_contract": ("AUI-12-SCENARIO-CONTRACT.json", SCENARIO_CONTRACT_SHA256),
}


class ContractError(RuntimeError):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


class SchemaValidationError(ValueError):
    pass


class HeaderHandler(http.server.SimpleHTTPRequestHandler):
    server_version = "AUI00Baseline/1"

    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
        super().end_headers()

    def log_message(self, format_string: str, *args: object) -> None:
        server_log = getattr(self.server, "request_log", None)
        if isinstance(server_log, list):
            server_log.append(format_string % args)


class ReusableServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True


def sha256(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def canonical_json_bytes(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode("utf-8")


def write_canonical_fsync(path: Path, value: Any) -> None:
    data = canonical_json_bytes(value)
    with path.open("wb") as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())


def _json_equal(first: Any, second: Any) -> bool:
    if isinstance(first, bool) or isinstance(second, bool):
        return type(first) is type(second) and first == second
    if isinstance(first, (int, float)) and isinstance(second, (int, float)):
        return first == second
    return type(first) is type(second) and first == second


def _resolve_ref(root: dict[str, Any], reference: str) -> dict[str, Any]:
    if not reference.startswith("#/"):
        raise SchemaValidationError(f"unsupported schema reference: {reference}")
    current: Any = root
    for token in reference[2:].split("/"):
        token = token.replace("~1", "/").replace("~0", "~")
        if not isinstance(current, dict) or token not in current:
            raise SchemaValidationError(f"unresolved schema reference: {reference}")
        current = current[token]
    if not isinstance(current, dict):
        raise SchemaValidationError(f"schema reference is not an object: {reference}")
    return current


def validate_json_schema(instance: Any, schema: dict[str, Any]) -> None:
    """Validate the JSON Schema 2020-12 subset used by the six frozen schemas."""

    def visit(value: Any, rule: dict[str, Any], path: str) -> None:
        if "$ref" in rule:
            visit(value, _resolve_ref(schema, str(rule["$ref"])), path)

        expected_type = rule.get("type")
        if expected_type is not None:
            allowed = [expected_type] if isinstance(expected_type, str) else expected_type

            def is_type(name: str) -> bool:
                return {
                    "object": isinstance(value, dict),
                    "array": isinstance(value, list),
                    "string": isinstance(value, str),
                    "integer": isinstance(value, int) and not isinstance(value, bool),
                    "number": isinstance(value, (int, float)) and not isinstance(value, bool),
                    "boolean": isinstance(value, bool),
                    "null": value is None,
                }.get(name, False)

            if not any(is_type(str(name)) for name in allowed):
                raise SchemaValidationError(f"{path}: expected type {allowed}")

        if "const" in rule and not _json_equal(value, rule["const"]):
            raise SchemaValidationError(f"{path}: const mismatch")
        if "enum" in rule and not any(_json_equal(value, item) for item in rule["enum"]):
            raise SchemaValidationError(f"{path}: enum mismatch")

        if isinstance(value, dict):
            required = rule.get("required", [])
            missing = [name for name in required if name not in value]
            if missing:
                raise SchemaValidationError(f"{path}: missing required {missing}")
            properties = rule.get("properties", {})
            if rule.get("additionalProperties") is False:
                extras = sorted(set(value) - set(properties))
                if extras:
                    raise SchemaValidationError(f"{path}: additional properties {extras}")
            for name, child_rule in properties.items():
                if name in value:
                    visit(value[name], child_rule, f"{path}.{name}")

        if isinstance(value, list):
            if "minItems" in rule and len(value) < int(rule["minItems"]):
                raise SchemaValidationError(f"{path}: too few items")
            if "maxItems" in rule and len(value) > int(rule["maxItems"]):
                raise SchemaValidationError(f"{path}: too many items")
            if rule.get("uniqueItems"):
                encoded = [json.dumps(item, sort_keys=True, separators=(",", ":")) for item in value]
                if len(encoded) != len(set(encoded)):
                    raise SchemaValidationError(f"{path}: duplicate items")
            prefix = rule.get("prefixItems", [])
            for index, child_rule in enumerate(prefix):
                if index < len(value):
                    visit(value[index], child_rule, f"{path}[{index}]")
            items = rule.get("items")
            if isinstance(items, dict):
                for index in range(len(prefix), len(value)):
                    visit(value[index], items, f"{path}[{index}]")
            if "contains" in rule:
                matches = 0
                for item in value:
                    try:
                        visit(item, rule["contains"], path)
                        matches += 1
                    except SchemaValidationError:
                        pass
                if matches < int(rule.get("minContains", 1)):
                    raise SchemaValidationError(f"{path}: contains count")

        if isinstance(value, str):
            if "minLength" in rule and len(value) < int(rule["minLength"]):
                raise SchemaValidationError(f"{path}: string too short")
            if "pattern" in rule and re.search(str(rule["pattern"]), value) is None:
                raise SchemaValidationError(f"{path}: pattern mismatch")

        if isinstance(value, (int, float)) and not isinstance(value, bool):
            if "minimum" in rule and value < rule["minimum"]:
                raise SchemaValidationError(f"{path}: below minimum")
            if "maximum" in rule and value > rule["maximum"]:
                raise SchemaValidationError(f"{path}: above maximum")

        for child_rule in rule.get("allOf", []):
            visit(value, child_rule, path)
        if "oneOf" in rule:
            matches = 0
            for child_rule in rule["oneOf"]:
                try:
                    visit(value, child_rule, path)
                    matches += 1
                except SchemaValidationError:
                    pass
            if matches != 1:
                raise SchemaValidationError(f"{path}: oneOf matched {matches}")
        if "not" in rule:
            try:
                visit(value, rule["not"], path)
            except SchemaValidationError:
                pass
            else:
                raise SchemaValidationError(f"{path}: prohibited by not")
        if "if" in rule:
            try:
                visit(value, rule["if"], path)
                condition = True
            except SchemaValidationError:
                condition = False
            if condition and "then" in rule:
                visit(value, rule["then"], path)
            if not condition and "else" in rule:
                visit(value, rule["else"], path)

    visit(instance, schema, "$")


def load_json(path: Path, code: str) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ContractError(code, f"invalid JSON {path}: {error}") from error


def load_schema_document(path: Path, expected_hash: str) -> dict[str, Any]:
    require_regular_canonical(path, "SCHEMA_DIGEST_MISMATCH")
    if sha256(path) != expected_hash:
        raise ContractError("SCHEMA_DIGEST_MISMATCH", f"schema digest mismatch: {path}")
    value = load_json(path, "SCHEMA_DIGEST_MISMATCH")
    if not isinstance(value, dict) or value.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
        raise ContractError("SCHEMA_DIGEST_MISMATCH", f"invalid schema document: {path}")
    return value


def load_canonical_schema_instance(path: Path, schema: dict[str, Any], code: str) -> dict[str, Any]:
    require_regular_canonical(path, code)
    value = load_json(path, code)
    if not isinstance(value, dict):
        raise ContractError(code, f"record is not an object: {path}")
    try:
        validate_json_schema(value, schema)
    except SchemaValidationError as error:
        raise ContractError(code, f"schema validation failed for {path}: {error}") from error
    if path.read_bytes() != canonical_json_bytes(value):
        raise ContractError(code, f"noncanonical JSON encoding: {path}")
    return value


def require_regular_canonical(path: Path, code: str) -> Path:
    if not path.is_absolute() or str(path) != str(path.resolve(strict=False)):
        raise ContractError(code, f"path is not canonical absolute: {path}")
    try:
        metadata = path.lstat()
    except OSError as error:
        raise ContractError(code, f"missing path: {path}") from error
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISREG(metadata.st_mode):
        raise ContractError(code, f"path is not a regular non-symlink file: {path}")
    return path


def require_directory_canonical(path: Path, code: str, may_be_absent: bool = False) -> Path:
    if not path.is_absolute() or str(path) != str(path.resolve(strict=False)):
        raise ContractError(code, f"directory is not canonical absolute: {path}")
    if not path.exists() and may_be_absent:
        return path
    if not path.is_dir() or path.is_symlink():
        raise ContractError(code, f"not a real directory: {path}")
    return path


def canonical_export_files(out: Path, code: str = "TRANSCRIPT_INVALID") -> list[Path]:
    """Return every canonical regular non-symlink file under the real OUT/web."""
    web_root = out / "web"
    require_directory_canonical(web_root, code)
    paths: list[Path] = []
    for child in web_root.rglob("*"):
        try:
            metadata = child.lstat()
        except OSError as error:
            raise ContractError(code, f"unreadable Web export child: {child}") from error
        if stat.S_ISLNK(metadata.st_mode):
            raise ContractError(code, f"Web export child is a symlink: {child}")
        resolved = child.resolve(strict=False)
        if child != resolved or not is_relative_to(resolved, web_root):
            raise ContractError(code, f"Web export child is not canonical under OUT/web: {child}")
        if stat.S_ISDIR(metadata.st_mode):
            continue
        if not stat.S_ISREG(metadata.st_mode):
            raise ContractError(code, f"Web export child is not a regular file: {child}")
        paths.append(child)
    paths.sort(key=lambda path: path.relative_to(out).as_posix().encode("utf-8"))
    return paths


def is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def command_version(command: list[str]) -> str:
    result = subprocess.run(command, text=True, capture_output=True, check=False, timeout=30)
    lines = (result.stdout or result.stderr).strip().splitlines()
    return lines[0] if lines else "unknown"


def directory_size(path: Path) -> int:
    return sum(item.stat().st_size for item in path.rglob("*") if item.is_file())


def gzip_size(path: Path) -> int:
    total = 0
    for item in sorted(candidate for candidate in path.rglob("*") if candidate.is_file()):
        total += len(gzip.compress(item.read_bytes(), compresslevel=9, mtime=0))
    return total


def title_signal(path: Path) -> dict[str, Any]:
    image = Image.open(path).convert("RGB")
    width, height = image.size
    crop = image.crop((width // 5, height // 5, width * 4 // 5, height * 4 // 5))
    pixels = list(crop.get_flattened_data())
    bright = sum(1 for red, green, blue in pixels if red > 185 and green > 185 and blue > 185)
    dark = sum(1 for red, green, blue in pixels if red < 70 and green < 70 and blue < 70)
    corner_pixels: list[tuple[int, int, int]] = []
    for box in (
        (0, 0, 64, 64),
        (width - 64, 0, width, 64),
        (0, height - 64, 64, height),
        (width - 64, height - 64, width, height),
    ):
        corner_pixels.extend(image.crop(box).get_flattened_data())
    corner_luma = sum((red + green + blue) / 3.0 for red, green, blue in corner_pixels) / len(corner_pixels)
    title_background_band = 50.0 <= corner_luma <= 130.0
    visible = bright >= 100 and dark >= 100 and title_background_band and (width, height) == IMAGE_SIZE
    return {
        "bright_center_pixels": bright,
        "corner_luma": round(corner_luma, 3),
        "dark_center_pixels": dark,
        "dimensions": [width, height],
        "title_background_band": title_background_band,
        "visible": visible,
    }


def console_errors(stderr: str) -> list[str]:
    errors: list[str] = []
    for line in stderr.splitlines():
        lowered = line.lower()
        is_console = "console" in lowered or "uncaught" in lowered
        is_error = any(token in lowered for token in ("error", "exception", "typeerror", "referenceerror"))
        if is_console and is_error:
            errors.append(line.strip())
    return errors


def browser_command(chromium: str) -> list[str]:
    return ["playwright.chromium.launch", chromium, *BROWSER_LAUNCH_ARGS]


def run_browser(chromium: str, url: str, screenshot: Path, wait_budget_ms: int) -> dict[str, Any]:
    started = time.monotonic()
    browser_console: list[str] = []
    error_text = ""
    exit_code = 0
    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(
                executable_path=chromium, headless=True, args=list(BROWSER_LAUNCH_ARGS)
            )
            page = browser.new_page(viewport={"width": 1280, "height": 720})
            page.on(
                "console",
                lambda message: browser_console.append(f"{message.type}: {message.text}")
                if message.type == "error" else None,
            )
            page.on("pageerror", lambda error: browser_console.append(f"pageerror: {error}"))
            response = page.goto(url, wait_until="commit", timeout=30000)
            if response is None or not response.ok:
                browser_console.append(f"navigation error: {response.status if response is not None else 'no response'}")
            page.wait_for_timeout(wait_budget_ms)
            page.screenshot(path=str(screenshot))
            browser.close()
    except (PlaywrightError, TimeoutError) as error:
        exit_code = 1
        error_text = str(error)
    wall_ms = round((time.monotonic() - started) * 1000)
    signal = title_signal(screenshot) if screenshot.is_file() else {
        "bright_center_pixels": 0,
        "dark_center_pixels": 0,
        "dimensions": None,
        "visible": False,
    }
    return {
        "command": browser_command(chromium),
        "console_errors": browser_console,
        "exit_code": exit_code,
        "maximum_resident_kib": None,
        "screenshot": screenshot.name if screenshot.is_file() else None,
        "signal": signal,
        "stderr_log": f"chromium-{wait_budget_ms}.stderr.log",
        "wait_budget_ms": wait_budget_ms,
        "wall_ms": wall_ms,
        "stderr": error_text + ("\n" if error_text else ""),
    }


def parse_component_contract(path: Path, expected_hash: str | None = None) -> tuple[tuple[int, int, int], ...]:
    if expected_hash is not None and sha256(path) != expected_hash:
        raise ContractError("PALETTE_CONTRACT_DIGEST_MISMATCH", f"component digest mismatch: {path}")
    value = load_json(path, "PALETTE_CONTRACT_INVALID")
    try:
        colors = value["tokens"]["colors"]
        if not isinstance(colors, dict):
            raise TypeError("colors")
        raw_values = [colors[name] for name in PALETTE_ORDER]
        if any(not isinstance(item, str) or re.fullmatch(r"[0-9A-F]{6}FF", item) is None for item in raw_values):
            raise ValueError("palette values must be uppercase RRGGBBFF")
        if len(set(raw_values)) != len(raw_values):
            raise ValueError("required palette values must be unique")
        return tuple(tuple(int(item[offset:offset + 2], 16) for offset in (0, 2, 4)) for item in raw_values)
    except (KeyError, TypeError, ValueError) as error:
        raise ContractError("PALETTE_CONTRACT_INVALID", f"invalid component palette contract: {error}") from error


def parse_oracle_contract(path: Path, expected_hash: str | None = None) -> dict[str, Any]:
    if expected_hash is not None and sha256(path) != expected_hash:
        raise ContractError("ORACLE_DIGEST_MISMATCH", f"oracle digest mismatch: {path}")
    value = load_json(path, "ORACLE_INVALID")
    try:
        algorithm = value["algorithm"]
        arguments = value["argument_case_sets"]
        if value["schema_version"] != 4 or value["oracle_id"] != "AUI-12-WEB-DIFFERENTIAL-V3":
            raise ValueError("identity")
        if algorithm["id"] != "nearest_palette_2x2_majority_sha256_v1":
            raise ValueError("algorithm")
        if algorithm["dimensions"] != [1280, 720] or algorithm["palette_order"] != list(PALETTE_ORDER):
            raise ValueError("algorithm geometry/palette")
        if arguments["generation_required_options"] != list(GENERATION_REQUIRED_OPTIONS):
            raise ValueError("generation options")
        if arguments["verify_required_options"] != list(VERIFY_REQUIRED_OPTIONS):
            raise ValueError("verify options")
        if tuple(value["failure_code_enum"]) != FAILURE_CODES:
            raise ValueError("failure codes")
    except (KeyError, TypeError, ValueError) as error:
        raise ContractError("ORACLE_INVALID", f"invalid oracle contract: {error}") from error
    return value


def nearest_palette_label(rgb: tuple[int, int, int], palette: tuple[tuple[int, int, int], ...]) -> int:
    red, green, blue = rgb
    best_index = 0
    best_distance: int | None = None
    for index, (token_red, token_green, token_blue) in enumerate(palette):
        distance = (red - token_red) ** 2 + (green - token_green) ** 2 + (blue - token_blue) ** 2
        if best_distance is None or distance < best_distance:
            best_distance = distance
            best_index = index
    return best_index


def majority_label(labels: Iterable[int]) -> int:
    counts = [0] * len(PALETTE_ORDER)
    for label in labels:
        counts[label] += 1
    return min(range(len(counts)), key=lambda index: (-counts[index], index))


def categorical_stream_from_image(
    image_or_path: Image.Image | Path,
    palette: tuple[tuple[int, int, int], ...],
) -> bytes:
    close_image = not isinstance(image_or_path, Image.Image)
    image = Image.open(image_or_path) if close_image else image_or_path
    try:
        rgb_image = image.convert("RGB")
        if rgb_image.size != IMAGE_SIZE:
            raise ContractError("DIMENSIONS_MISMATCH", f"image dimensions are {rgb_image.size}")
        pixels = rgb_image.load()
        cache: dict[tuple[int, int, int], int] = {}

        def label(pixel: tuple[int, int, int]) -> int:
            found = cache.get(pixel)
            if found is None:
                found = nearest_palette_label(pixel, palette)
                cache[pixel] = found
            return found

        reduced = bytearray()
        for y in range(0, IMAGE_SIZE[1], 2):
            for x in range(0, IMAGE_SIZE[0], 2):
                reduced.append(majority_label((
                    label(pixels[x, y]),
                    label(pixels[x + 1, y]),
                    label(pixels[x, y + 1]),
                    label(pixels[x + 1, y + 1]),
                )))
        if len(reduced) != REDUCED_BYTES:
            raise ContractError("REDUCED_STREAM_INVALID", f"reduced stream length {len(reduced)}")
        return bytes(reduced)
    finally:
        if close_image:
            image.close()


def differential_signal(
    reference: Path,
    current: Path,
    palette: tuple[tuple[int, int, int], ...],
    palette_sha: str = PALETTE_CONTRACT_SHA256,
    oracle_sha: str = ORACLE_SHA256,
    reference_stream: bytes | None = None,
) -> dict[str, Any]:
    if not reference.is_file():
        raise ContractError("REFERENCE_MISSING", f"missing reference: {reference}")
    reference_image_sha = sha256(reference)
    if reference_stream is None:
        reference_stream = categorical_stream_from_image(reference, palette)
    if len(reference_stream) != REDUCED_BYTES:
        raise ContractError("REDUCED_STREAM_INVALID", "reference reduced stream has wrong length")
    reference_signature = hashlib.sha256(reference_stream).hexdigest()
    signal: dict[str, Any] = {
        "mode": "native_web_differential_v3",
        "visible": False,
        "dimensions": None,
        "palette_contract_sha256": palette_sha,
        "oracle_sha256": oracle_sha,
        "reference_image_sha256": reference_image_sha,
        "current_image_sha256": None,
        "reference_signature_sha256": reference_signature,
        "current_signature_sha256": None,
        "reduced_width": REDUCED_SIZE[0],
        "reduced_height": REDUCED_SIZE[1],
        "reduced_bytes": REDUCED_BYTES,
        "label_mismatches": None,
        "failures": [],
    }
    if not current.is_file():
        signal["failures"] = ["CURRENT_MISSING"]
        return signal
    signal["current_image_sha256"] = sha256(current)
    with Image.open(current) as image:
        signal["dimensions"] = list(image.size)
    if tuple(signal["dimensions"]) != IMAGE_SIZE:
        signal["failures"] = ["DIMENSIONS_MISMATCH"]
        return signal
    current_stream = categorical_stream_from_image(current, palette)
    if len(current_stream) != REDUCED_BYTES:
        signal["failures"] = ["REDUCED_STREAM_INVALID"]
        return signal
    current_signature = hashlib.sha256(current_stream).hexdigest()
    mismatches = sum(first != second for first, second in zip(reference_stream, current_stream, strict=True))
    signal["current_signature_sha256"] = current_signature
    signal["label_mismatches"] = mismatches
    failures: list[str] = []
    if current_signature != reference_signature or mismatches != 0:
        failures.append("SIGNATURE_MISMATCH")
    signal["failures"] = sorted(failures)
    signal["visible"] = not failures
    return signal


def git_identity(repo: Path) -> tuple[str, str, bool]:
    def run(arguments: list[str]) -> str:
        result = subprocess.run(
            ["git", "-C", str(repo), *arguments], text=True, capture_output=True,
            check=False, timeout=30,
        )
        if result.returncode != 0:
            raise ContractError("PROVENANCE_INVALID", result.stderr.strip() or "git command failed")
        return result.stdout.strip()

    candidate = run(["rev-parse", "HEAD"])
    tree = run(["rev-parse", "HEAD^{tree}"])
    clean = run(["status", "--porcelain", "--untracked-files=all"]) == ""
    return candidate, tree, clean


def expected_shot_names(scenario_contract: dict[str, Any]) -> list[str]:
    names = [f"{name}.png" for name in scenario_contract.get("shot_basenames", [])]
    if len(names) != 62 or len(names) != len(set(names)):
        raise ContractError("SCENARIO_INVALID", "scenario contract does not define 62 unique shots")
    return names


def exact_shot_set_sha256(names: Iterable[str]) -> str:
    encoded = b"".join(name.encode("utf-8") + b"\n" for name in sorted(names, key=lambda item: item.encode("utf-8")))
    return hashlib.sha256(encoded).hexdigest()


def validate_native_outputs(native_root: Path, repo: Path, challenge: str) -> dict[str, Any]:
    reference_path = native_root / "ui_title_1280x720_standard.png"
    try:
        reference_metadata = reference_path.lstat()
    except OSError:
        reference_metadata = None
    if reference_metadata is not None and (
        stat.S_ISLNK(reference_metadata.st_mode) or not stat.S_ISREG(reference_metadata.st_mode)
    ):
        raise ContractError("REFERENCE_ALIAS", "native reference is not a regular non-symlink file")
    scenario_path = repo / "selftest/scenarios/ui_shell_floor.gd.contract.json"
    require_regular_canonical(scenario_path, "SCENARIO_INVALID")
    if sha256(scenario_path) != SCENARIO_CONTRACT_SHA256:
        raise ContractError("SCENARIO_INVALID", "scenario contract digest mismatch")
    scenario_contract = load_json(scenario_path, "SCENARIO_INVALID")
    shots = expected_shot_names(scenario_contract)
    report_path = native_root / "report.json"
    supplemental_path = native_root / "ui-shell-report.json"
    report = load_json(report_path, "SCENARIO_INVALID")
    supplemental = load_json(supplemental_path, "SCENARIO_INVALID")
    expected_set = set(shots)
    actual_png = {path.name for path in native_root.glob("*.png") if path.is_file() and not path.is_symlink()}
    if not expected_set.issubset(actual_png):
        raise ContractError("SCENARIO_INVALID", "native shot file set mismatch")
    if actual_png - expected_set:
        raise ContractError("PROVENANCE_INVALID", "native output set contains stale PNG files")
    if report.get("scenario") != "ui_shell_floor" or report.get("seed") != 42 or report.get("result") != "pass":
        raise ContractError("SCENARIO_INVALID", "native report identity/result mismatch")
    checks = report.get("checks")
    if not isinstance(checks, list) or len(checks) != 142 or any(not isinstance(row, dict) or row.get("ok") is not True for row in checks):
        raise ContractError("SCENARIO_INVALID", "native checks are not exactly 142 passing checks")
    report_shots = report.get("shots")
    if not isinstance(report_shots, list) or len(report_shots) != 62 or len(set(report_shots)) != 62 or set(report_shots) != expected_set:
        raise ContractError("SCENARIO_INVALID", "native report shot set mismatch")
    if report.get("pixel_skipped") != []:
        raise ContractError("SCENARIO_INVALID", "native report contains pixel skips")
    if supplemental.get("scenario") != "ui_shell_floor" or supplemental.get("seed") != 42:
        raise ContractError("SCENARIO_INVALID", "supplemental identity mismatch")
    if supplemental.get("release_challenge") != challenge:
        raise ContractError("RUN_RECEIPT_INVALID", "supplemental challenge mismatch")
    if supplemental.get("completion_sentinel") is not True:
        raise ContractError("SCENARIO_INVALID", "supplemental completion sentinel mismatch")
    if supplemental.get("inventory_states") != 60 or supplemental.get("inventory_failures") != 0:
        raise ContractError("SCENARIO_INVALID", "supplemental inventory mismatch")
    actual_regular = {
        path.relative_to(native_root).as_posix()
        for path in native_root.rglob("*")
        if path.is_file() and not path.is_symlink()
    }
    expected_regular = expected_set | {"report.json", "ui-shell-report.json"}
    if expected_regular - actual_regular:
        raise ContractError("SCENARIO_INVALID", "native output set contains missing files")
    if actual_regular - expected_regular:
        raise ContractError("PROVENANCE_INVALID", "native output set contains stale regular files")
    return {
        "scenario_contract": scenario_contract,
        "shots": shots,
        "report_path": report_path,
        "report": report,
        "supplemental_path": supplemental_path,
        "supplemental": supplemental,
    }


def output_rows(out: Path, paths: Iterable[Path]) -> list[dict[str, str]]:
    rows = [{"relpath": path.relative_to(out).as_posix(), "sha256": sha256(path)} for path in paths]
    rows.sort(key=lambda row: row["relpath"].encode("utf-8"))
    if len(rows) != len({row["relpath"] for row in rows}):
        raise ContractError("TRANSCRIPT_INVALID", "duplicate transcript output")
    return rows


def validate_approval_package(args: argparse.Namespace) -> dict[str, Any]:
    supplied = {
        "owner_decision_schema": (args.owner_decision_schema, args.owner_decision_schema_sha256, OWNER_DECISION_SCHEMA_SHA256),
        "start_receipt_schema": (args.start_receipt_schema, args.start_receipt_schema_sha256, START_RECEIPT_SCHEMA_SHA256),
        "completion_receipt_schema": (args.completion_receipt_schema, args.completion_receipt_schema_sha256, COMPLETION_RECEIPT_SCHEMA_SHA256),
        "transcript_schema": (args.transcript_schema, args.transcript_schema_sha256, TRANSCRIPT_SCHEMA_SHA256),
        "legacy_schema": (args.legacy_schema, args.legacy_schema_sha256, LEGACY_SCHEMA_SHA256),
        "contract_schema": (args.contract_schema, args.contract_schema_sha256, CONTRACT_SCHEMA_SHA256),
    }
    schemas: dict[str, dict[str, Any]] = {}
    for name, (path, supplied_hash, expected_hash) in supplied.items():
        if supplied_hash != expected_hash:
            raise ContractError("SCHEMA_DIGEST_MISMATCH", f"wrong supplied {name} digest")
        schemas[name] = load_schema_document(path, expected_hash)

    manifest_path: Path = args.approval_manifest
    require_regular_canonical(manifest_path, "APPROVAL_MANIFEST_INVALID")
    if args.approval_manifest_sha256 != APPROVAL_MANIFEST_SHA256 or sha256(manifest_path) != APPROVAL_MANIFEST_SHA256:
        raise ContractError("APPROVAL_MANIFEST_INVALID", "approval manifest digest mismatch")
    manifest = load_json(manifest_path, "APPROVAL_MANIFEST_INVALID")
    if manifest.get("schema_version") != 3 or manifest.get("manifest_id") != "AUI-12-D-WEB-1-OWNER-DECISION-V3":
        raise ContractError("APPROVAL_MANIFEST_INVALID", "approval manifest identity mismatch")
    members = manifest.get("members")
    if not isinstance(members, dict) or set(members) != set(EXPECTED_MANIFEST_MEMBERS):
        raise ContractError("APPROVAL_MANIFEST_INVALID", "approval manifest member set mismatch")
    member_paths: dict[str, Path] = {}
    for name, (expected_name, expected_hash) in EXPECTED_MANIFEST_MEMBERS.items():
        row = members.get(name)
        if not isinstance(row, dict) or row != {"path": expected_name, "sha256": expected_hash}:
            raise ContractError("APPROVAL_MANIFEST_INVALID", f"approval manifest member mismatch: {name}")
        member_path = (manifest_path.parent / expected_name).resolve(strict=False)
        if member_path.parent != manifest_path.parent:
            raise ContractError("APPROVAL_MANIFEST_INVALID", f"manifest member escapes directory: {name}")
        require_regular_canonical(member_path, "APPROVAL_MANIFEST_INVALID")
        if sha256(member_path) != expected_hash:
            raise ContractError("APPROVAL_MANIFEST_INVALID", f"manifest member hash mismatch: {name}")
        member_paths[name] = member_path

    expected_argument_paths = {
        "oracle": args.oracle_contract,
        "component_contract": args.palette_contract,
        "owner_decision_schema": args.owner_decision_schema,
        "start_receipt_schema": args.start_receipt_schema,
        "completion_receipt_schema": args.completion_receipt_schema,
        "transcript_schema": args.transcript_schema,
        "legacy_schema": args.legacy_schema,
        "contract_schema": args.contract_schema,
    }
    for name, argument_path in expected_argument_paths.items():
        if argument_path != member_paths[name]:
            raise ContractError("APPROVAL_MANIFEST_INVALID", f"argument does not name manifest member: {name}")

    if args.oracle_sha256 != ORACLE_SHA256:
        raise ContractError("ORACLE_DIGEST_MISMATCH", "wrong supplied oracle digest")
    oracle = parse_oracle_contract(args.oracle_contract, ORACLE_SHA256)
    require_regular_canonical(args.palette_contract, "PALETTE_CONTRACT_INVALID")
    palette = parse_component_contract(args.palette_contract, PALETTE_CONTRACT_SHA256)

    require_regular_canonical(args.owner_decision, "OWNER_DECISION_INVALID")
    contract_out = args.out if args.out is not None else args.verify_output
    if (
        args.owner_decision == manifest_path
        or args.owner_decision.parent != manifest_path.parent
        or (contract_out is not None and is_relative_to(args.owner_decision, contract_out))
    ):
        raise ContractError(
            "OWNER_DECISION_INVALID",
            "owner decision must be a distinct canonical file in the manifest parent and outside OUT",
        )
    if args.owner_decision_sha256 != OWNER_DECISION_SHA256 or sha256(args.owner_decision) != OWNER_DECISION_SHA256:
        raise ContractError("OWNER_DECISION_INVALID", "owner decision digest mismatch")
    owner_decision = load_json(args.owner_decision, "OWNER_DECISION_INVALID")
    try:
        validate_json_schema(owner_decision, schemas["owner_decision_schema"])
    except SchemaValidationError as error:
        raise ContractError("OWNER_DECISION_INVALID", str(error)) from error
    if owner_decision.get("manifest_sha256") != APPROVAL_MANIFEST_SHA256:
        raise ContractError("OWNER_DECISION_INVALID", "owner decision manifest binding mismatch")
    return {
        "schemas": schemas,
        "manifest": manifest,
        "member_paths": member_paths,
        "owner_decision": owner_decision,
        "oracle": oracle,
        "palette": palette,
    }


def utc_to_unix_ns(value: str) -> int:
    match = re.fullmatch(r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})\.(\d{9})Z", value)
    if match is None:
        raise ValueError("UTC value must have exactly nine fractional digits")
    parsed = datetime.strptime(match.group(1), "%Y-%m-%dT%H:%M:%S").replace(tzinfo=timezone.utc)
    return calendar.timegm(parsed.utctimetuple()) * 1_000_000_000 + int(match.group(2))


def validate_start_receipt(
    args: argparse.Namespace,
    schema: dict[str, Any],
    repo: Path,
    out: Path,
) -> dict[str, Any]:
    receipt = load_canonical_schema_instance(args.run_receipt, schema, "RUN_RECEIPT_INVALID")
    if args.run_receipt_sha256 != sha256(args.run_receipt):
        raise ContractError("RUN_RECEIPT_INVALID", "start receipt digest mismatch")
    try:
        if utc_to_unix_ns(receipt["created_utc"]) != receipt["created_unix_ns"]:
            raise ContractError("RUN_RECEIPT_INVALID", "start UTC/ns mismatch")
    except ValueError as error:
        raise ContractError("RUN_RECEIPT_INVALID", str(error)) from error
    if receipt["repo_realpath"] != str(repo) or receipt["out_realpath"] != str(out):
        raise ContractError("RUN_RECEIPT_INVALID", "start receipt path binding mismatch")
    release_root = Path(receipt["release_root_realpath"])
    require_directory_canonical(release_root, "RUN_RECEIPT_INVALID")
    if out.parent != release_root or args.run_receipt.parent != release_root or is_relative_to(args.run_receipt, out):
        raise ContractError("RUN_RECEIPT_INVALID", "start receipt location mismatch")
    if receipt["candidate"] != args.candidate or receipt["tree"] != args.tree:
        raise ContractError("RUN_RECEIPT_INVALID", "start receipt git binding mismatch")
    return receipt


def native_argv(godot: str, repo: Path, out: Path, challenge: str) -> list[str]:
    return [
        "xvfb-run", "-a", godot, "--path", str(repo), "--resolution", "1280x720",
        "-s", "selftest/harness.gd", "--", "--scenario=ui_shell_floor", "--seed=42",
        f"--release-challenge={challenge}", f"--shots={out / 'native-reference'}",
    ]


def export_argv(godot: str, repo: Path, out: Path) -> list[str]:
    return [
        godot, "--headless", "--path", str(repo), "--export-release", "Web",
        str(out / "web/index.html"),
    ]


def event_record(kind: str, argv: list[str], started: int, ended: int, exit_code: int,
                 outputs: list[dict[str, str]]) -> dict[str, Any]:
    if ended <= started:
        ended = started + 1
    return {
        "kind": kind,
        "argv": argv,
        "started_unix_ns": started,
        "ended_unix_ns": ended,
        "exit_code": exit_code,
        "outputs": outputs,
    }


def transcript_document(
    challenge: str, candidate: str, tree: str, started: int,
    events: list[dict[str, Any]], ended: int | None = None,
) -> dict[str, Any]:
    final_ended = ended if ended is not None else (events[-1]["ended_unix_ns"] if events else started)
    return {
        "schema_version": 1,
        "record_id": "AUI-12-WEB-RUN-TRANSCRIPT-V1",
        "challenge": challenge,
        "candidate": candidate,
        "tree": tree,
        "started_unix_ns": started,
        "ended_unix_ns": max(final_ended, started),
        "events": events,
    }


def _test_browser_attempts(path: str | None) -> list[dict[str, Any]] | None:
    if path is None:
        return None
    if os.environ.get("AUI_WEB_BASELINE_TEST_MODE") != "1" or os.environ.get("PYTHONHASHSEED") != "0":
        raise ContractError("PROVENANCE_INVALID", "test browser seam is disabled")
    fixture = Path(path).resolve(strict=False)
    temp_root = Path(tempfile.gettempdir()).resolve()
    require_regular_canonical(fixture, "PROVENANCE_INVALID")
    if not is_relative_to(fixture, temp_root):
        raise ContractError("PROVENANCE_INVALID", "test browser fixture must be under the temporary directory")
    value = load_json(fixture, "PROVENANCE_INVALID")
    if not isinstance(value, list) or not value:
        raise ContractError("PROVENANCE_INVALID", "test browser fixture must contain attempts")
    return value


def _serve_browser_attempts(
    chromium: str,
    export_dir: Path,
    out: Path,
    challenge: str,
    injected: list[dict[str, Any]] | None,
    signal_builder: Callable[[Path], dict[str, Any]],
    event_sink: Callable[[dict[str, Any]], None] | None = None,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[str]]:
    request_log: list[str] = []
    events: list[dict[str, Any]] = []
    attempts: list[dict[str, Any]] = []
    server: ReusableServer | None = None
    thread: threading.Thread | None = None
    previous_cwd = Path.cwd()
    try:
        os.chdir(export_dir)
        server = ReusableServer(("127.0.0.1", 0), HeaderHandler)
        setattr(server, "request_log", request_log)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        url = f"http://127.0.0.1:{server.server_address[1]}/index.html?release_challenge={challenge}"
        for index, budget in enumerate(WAIT_BUDGETS):
            screenshot = out / f"web-{budget}.png"
            started = time.time_ns()
            if injected is None:
                attempt = run_browser(chromium, url, screenshot, budget)
            else:
                if index >= len(injected):
                    break
                attempt = copy.deepcopy(injected[index])
                source = attempt.pop("screenshot_source", None)
                if source is not None:
                    source_path = Path(source).resolve(strict=False)
                    require_regular_canonical(source_path, "PROVENANCE_INVALID")
                    if not is_relative_to(source_path, Path(tempfile.gettempdir()).resolve()):
                        raise ContractError("PROVENANCE_INVALID", "injected screenshot must be temporary")
                    shutil.copyfile(source_path, screenshot)
                with urllib.request.urlopen(url, timeout=30) as response:
                    if response.status != 200:
                        raise ContractError("PROVENANCE_INVALID", "test navigation failed")
                attempt.setdefault("command", browser_command(chromium))
                attempt.setdefault("console_errors", [])
                attempt.setdefault("exit_code", 0)
                attempt.setdefault("maximum_resident_kib", None)
                attempt["screenshot"] = screenshot.name if screenshot.is_file() else None
                attempt.setdefault("stderr_log", f"chromium-{budget}.stderr.log")
                attempt.setdefault("wait_budget_ms", budget)
                attempt.setdefault("wall_ms", 0)
                attempt.setdefault("stderr", "")
            ended = time.time_ns()
            stderr_path = out / attempt["stderr_log"]
            stderr_path.write_text(attempt.pop("stderr", ""), encoding="utf-8")
            if attempt.get("screenshot") is None or not screenshot.is_file():
                raise ContractError("CURRENT_MISSING", f"browser attempt {budget} did not produce a screenshot")
            attempt["signal"] = signal_builder(screenshot)
            attempts.append(attempt)
            event = event_record(
                "browser_attempt", browser_command(chromium), started, ended,
                int(attempt["exit_code"]), output_rows(out, [screenshot, stderr_path]),
            )
            events.append(event)
            if event_sink is not None:
                event_sink(event)
            if attempt["exit_code"] == 0 and attempt["signal"]["visible"]:
                break
    finally:
        if server is not None:
            server.shutdown()
            server.server_close()
        if thread is not None:
            thread.join(timeout=5)
        os.chdir(previous_cwd)
    return attempts, events, request_log


def legacy_main(args: argparse.Namespace) -> int:
    repo = args.repo.resolve()
    output = args.out.resolve()
    if output.exists() and any(output.iterdir()):
        raise SystemExit(f"output must be absent or empty: {output}")
    output.mkdir(parents=True, exist_ok=True)
    export_dir = output / "web"
    export_dir.mkdir()
    export_log = output / "godot-export.log"
    command = export_argv(args.godot, repo, output)
    export_started = time.monotonic()
    export_result = subprocess.run(command, text=True, capture_output=True, check=False, timeout=180)
    export_wall_ms = round((time.monotonic() - export_started) * 1000)
    export_log.write_text(export_result.stdout + export_result.stderr, encoding="utf-8")
    if export_result.returncode != 0 or not (export_dir / "index.html").is_file():
        raise SystemExit("Web export failed; see godot-export.log")

    request_log: list[str] = []
    previous_cwd = Path.cwd()
    server: ReusableServer | None = None
    thread: threading.Thread | None = None
    attempts: list[dict[str, Any]] = []
    try:
        os.chdir(export_dir)
        server = ReusableServer(("127.0.0.1", 0), HeaderHandler)
        setattr(server, "request_log", request_log)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        url = f"http://127.0.0.1:{server.server_address[1]}/index.html"
        for budget in WAIT_BUDGETS:
            screenshot = output / f"web-{budget}.png"
            attempt = run_browser(args.chromium, url, screenshot, budget)
            (output / attempt["stderr_log"]).write_text(attempt.pop("stderr"), encoding="utf-8")
            attempts.append(attempt)
            if attempt["exit_code"] == 0 and attempt["signal"]["visible"]:
                break
    finally:
        if server is not None:
            server.shutdown()
            server.server_close()
        if thread is not None:
            thread.join(timeout=5)
        os.chdir(previous_cwd)

    visible_attempts = [attempt for attempt in attempts if attempt["signal"]["visible"]]
    all_console_errors = [error for attempt in attempts for error in attempt["console_errors"]]
    maximum_memory = max(
        (attempt["maximum_resident_kib"] for attempt in attempts if attempt["maximum_resident_kib"] is not None),
        default=None,
    )
    report = {
        "schema_version": 1,
        "result": "pass" if visible_attempts and not all_console_errors and all(
            attempt["exit_code"] == 0 for attempt in attempts
        ) else "fail",
        "repo": str(repo),
        "export": {
            "command": command,
            "compressed_gzip_bytes": gzip_size(export_dir),
            "exit_code": export_result.returncode,
            "file_count": sum(1 for item in export_dir.rglob("*") if item.is_file()),
            "uncompressed_bytes": directory_size(export_dir),
            "wall_ms": export_wall_ms,
        },
        "browser": {
            "attempts": attempts,
            "console_errors": all_console_errors,
            "first_title_visible_wait_ms": visible_attempts[0]["wait_budget_ms"] if visible_attempts else None,
            "maximum_resident_kib": maximum_memory,
            "memory_status": "measured" if maximum_memory is not None else "unsupported",
            "request_count": len(request_log),
        },
        "environment": {
            "chromium": command_version([args.chromium, "--version"]),
            "godot": command_version([args.godot, "--version"]),
            "os": platform.platform(),
            "tool_sha256": sha256(Path(__file__).resolve()),
        },
    }
    (output / "server.log").write_text("\n".join(request_log) + "\n", encoding="utf-8")
    (output / "web-baseline.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report["result"] == "pass" else 1


def generation_main(args: argparse.Namespace) -> int:
    repo = args.repo
    out = args.out
    require_directory_canonical(repo, "PROVENANCE_INVALID")
    require_directory_canonical(out, "PROVENANCE_INVALID", may_be_absent=True)
    if out.exists() and any(out.iterdir()):
        raise ContractError("PROVENANCE_INVALID", f"output must be absent or empty: {out}")
    out.mkdir(parents=True, exist_ok=True)
    package = validate_approval_package(args)
    before_candidate, before_tree, clean_before = git_identity(repo)
    if not clean_before or (before_candidate, before_tree) != (args.candidate, args.tree):
        raise ContractError("PROVENANCE_INVALID", "candidate/tree/clean precondition mismatch")
    receipt = validate_start_receipt(args, package["schemas"]["start_receipt_schema"], repo, out)
    challenge = receipt["challenge"]
    transcript_started = time.time_ns()
    if transcript_started < receipt["created_unix_ns"]:
        raise ContractError("RUN_RECEIPT_INVALID", "transcript begins before receipt")
    events: list[dict[str, Any]] = []
    transcript_path = out / "run-transcript.json"

    def append_transcript_event(event: dict[str, Any]) -> None:
        events.append(event)
        write_canonical_fsync(
            transcript_path,
            transcript_document(
                challenge, args.candidate, args.tree, transcript_started,
                events, event["ended_unix_ns"],
            ),
        )

    write_canonical_fsync(
        transcript_path,
        transcript_document(challenge, args.candidate, args.tree, transcript_started, events),
    )

    native_root = out / "native-reference"
    native_root.mkdir()
    native_command = native_argv(args.godot, repo, out, challenge)
    native_started = time.time_ns()
    native_result = subprocess.run(native_command, text=True, capture_output=True, check=False, timeout=240)
    native_ended = time.time_ns()
    if native_result.returncode != 0:
        raise ContractError("SCENARIO_INVALID", f"native scenario failed: {native_result.stderr[-2000:]}")
    native = validate_native_outputs(native_root, repo, challenge)
    native_paths = [native_root / name for name in native["shots"]] + [native["report_path"], native["supplemental_path"]]
    append_transcript_event(event_record(
        "native_ui_shell_floor", native_command, native_started, native_ended,
        native_result.returncode, output_rows(out, native_paths),
    ))

    export_dir = out / "web"
    export_dir.mkdir()
    export_command = export_argv(args.godot, repo, out)
    export_started_ns = time.time_ns()
    export_started = time.monotonic()
    export_result = subprocess.run(export_command, text=True, capture_output=True, check=False, timeout=180)
    export_wall_ms = round((time.monotonic() - export_started) * 1000)
    export_ended_ns = time.time_ns()
    (out / "godot-export.log").write_text(export_result.stdout + export_result.stderr, encoding="utf-8")
    if export_result.returncode != 0 or not (export_dir / "index.html").is_file():
        raise ContractError("PROVENANCE_INVALID", "Web export failed")
    export_paths = canonical_export_files(out)
    append_transcript_event(event_record(
        "web_export", export_command, export_started_ns, export_ended_ns,
        export_result.returncode, output_rows(out, export_paths),
    ))

    reference = native_root / "ui_title_1280x720_standard.png"
    reference_stream = categorical_stream_from_image(reference, package["palette"])
    injected = _test_browser_attempts(args.test_browser_fixture)
    attempts, _browser_events, request_log = _serve_browser_attempts(
        args.chromium, export_dir, out, challenge, injected,
        lambda screenshot: differential_signal(
            reference, screenshot, package["palette"], reference_stream=reference_stream,
        ),
        append_transcript_event,
    )
    server_log = out / "server.log"
    server_log.write_text("\n".join(request_log) + "\n", encoding="utf-8")
    challenge_request = f"GET /index.html?release_challenge={challenge} HTTP/"
    if sum(challenge_request in row for row in request_log) != len(attempts):
        raise ContractError("RUN_RECEIPT_INVALID", "server log challenge navigation count mismatch")

    all_console_errors = [error for attempt in attempts for error in attempt["console_errors"]]
    visible_attempts = [attempt for attempt in attempts if attempt["signal"]["visible"]]
    maximum_memory = max(
        (attempt["maximum_resident_kib"] for attempt in attempts if attempt["maximum_resident_kib"] is not None),
        default=None,
    )
    transcript = transcript_document(challenge, args.candidate, args.tree, transcript_started, events, time.time_ns())
    write_canonical_fsync(transcript_path, transcript)
    try:
        validate_json_schema(transcript, package["schemas"]["transcript_schema"])
    except SchemaValidationError as error:
        raise ContractError("TRANSCRIPT_INVALID", str(error)) from error

    after_candidate, after_tree, clean_after = git_identity(repo)
    if not clean_after or (after_candidate, after_tree) != (args.candidate, args.tree):
        raise ContractError("PROVENANCE_INVALID", "candidate/tree/clean postcondition mismatch")
    reference_stat = reference.lstat()
    if stat.S_ISLNK(reference_stat.st_mode) or reference_stat.st_nlink != 1:
        raise ContractError("REFERENCE_ALIAS", "reference is linked")
    report = {
        "schema_version": 1,
        "result": "pass" if visible_attempts and not all_console_errors and all(
            attempt["exit_code"] == 0 for attempt in attempts
        ) else "fail",
        "repo": str(repo),
        "export": {
            "command": export_command,
            "compressed_gzip_bytes": gzip_size(export_dir),
            "exit_code": export_result.returncode,
            "file_count": len(export_paths),
            "uncompressed_bytes": directory_size(export_dir),
            "wall_ms": export_wall_ms,
        },
        "browser": {
            "signal_mode": "native_web_differential_v3",
            "candidate": args.candidate,
            "tree": args.tree,
            "repo_clean_before": clean_before,
            "repo_clean_after": clean_after,
            "run_challenge": challenge,
            "run_receipt_relpath": f"../{args.run_receipt.name}",
            "run_receipt_sha256": sha256(args.run_receipt),
            "run_transcript_relpath": "run-transcript.json",
            "run_transcript_sha256": sha256(transcript_path),
            "server_log_sha256": sha256(server_log),
            "approval_manifest_sha256": APPROVAL_MANIFEST_SHA256,
            "owner_decision_relpath": str(args.owner_decision),
            "owner_decision_sha256": OWNER_DECISION_SHA256,
            "remediation_sha256": REMEDIATION_SHA256,
            "owner_decision_schema_sha256": OWNER_DECISION_SCHEMA_SHA256,
            "start_receipt_schema_sha256": START_RECEIPT_SCHEMA_SHA256,
            "completion_receipt_schema_sha256": COMPLETION_RECEIPT_SCHEMA_SHA256,
            "transcript_schema_sha256": TRANSCRIPT_SCHEMA_SHA256,
            "palette_contract_sha256": PALETTE_CONTRACT_SHA256,
            "oracle_sha256": ORACLE_SHA256,
            "legacy_schema_sha256": LEGACY_SCHEMA_SHA256,
            "contract_schema_sha256": CONTRACT_SCHEMA_SHA256,
            "scenario_contract_sha256": SCENARIO_CONTRACT_SHA256,
            "native_report_relpath": "native-reference/report.json",
            "native_report_sha256": sha256(native["report_path"]),
            "native_supplemental_relpath": "native-reference/ui-shell-report.json",
            "native_supplemental_sha256": sha256(native["supplemental_path"]),
            "reference_image_relpath": "native-reference/ui_title_1280x720_standard.png",
            "reference_image_sha256": sha256(reference),
            "reference_signature_sha256": hashlib.sha256(reference_stream).hexdigest(),
            "exact_shot_set_sha256": exact_shot_set_sha256(native["shots"]),
            "attempts": attempts,
            "console_errors": all_console_errors,
            "first_title_visible_wait_ms": visible_attempts[0]["wait_budget_ms"] if visible_attempts else None,
            "maximum_resident_kib": maximum_memory,
            "memory_status": "measured" if maximum_memory is not None else "unsupported",
            "request_count": len(request_log),
        },
        "environment": {
            "chromium": command_version([args.chromium, "--version"]),
            "godot": command_version([args.godot, "--version"]),
            "os": platform.platform(),
            "tool_sha256": sha256(Path(__file__).resolve()),
        },
    }
    try:
        validate_json_schema(report, package["schemas"]["contract_schema"])
    except SchemaValidationError as error:
        raise ContractError("REPORT_INCONSISTENT", str(error)) from error
    report_path = out / "web-baseline.json"
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report["result"] == "pass" else 1


def _same_regular_file(path: Path, expected_root: Path, relpath: str, code: str) -> Path:
    expected = expected_root / relpath
    if path != expected or not is_relative_to(path, expected_root):
        raise ContractError(code, f"path binding mismatch: {path}")
    require_regular_canonical(path, code)
    return path


def _check_transcript_times(start: dict[str, Any], transcript: dict[str, Any], completion: dict[str, Any]) -> None:
    if not (start["created_unix_ns"] <= transcript["started_unix_ns"]):
        raise ContractError("TRANSCRIPT_INVALID", "start follows transcript")
    events = transcript["events"]
    if not events or transcript["started_unix_ns"] > events[0]["started_unix_ns"]:
        raise ContractError("TRANSCRIPT_INVALID", "first event ordering invalid")
    previous_end: int | None = None
    for event in events:
        if event["started_unix_ns"] >= event["ended_unix_ns"]:
            raise ContractError("TRANSCRIPT_INVALID", "event interval invalid")
        if previous_end is not None and previous_end > event["started_unix_ns"]:
            raise ContractError("TRANSCRIPT_INVALID", "event order overlaps")
        previous_end = event["ended_unix_ns"]
    if previous_end is None or previous_end > transcript["ended_unix_ns"]:
        raise ContractError("TRANSCRIPT_INVALID", "transcript end invalid")
    if transcript["ended_unix_ns"] > completion["completed_unix_ns"]:
        raise ContractError("TRANSCRIPT_INVALID", "completion precedes transcript")


def verify_output_main(args: argparse.Namespace) -> int:
    repo = args.repo
    out = args.verify_output
    require_directory_canonical(repo, "PROVENANCE_INVALID")
    require_directory_canonical(out, "PROVENANCE_INVALID")
    package = validate_approval_package(args)
    candidate, tree, clean = git_identity(repo)
    if not clean or (candidate, tree) != (args.candidate, args.tree):
        raise ContractError("PROVENANCE_INVALID", "candidate/tree/clean mismatch")
    start = validate_start_receipt(args, package["schemas"]["start_receipt_schema"], repo, out)
    completion = load_canonical_schema_instance(
        args.completion_receipt, package["schemas"]["completion_receipt_schema"], "RUN_RECEIPT_INVALID",
    )
    if args.completion_receipt_sha256 != sha256(args.completion_receipt):
        raise ContractError("RUN_RECEIPT_INVALID", "completion receipt digest mismatch")
    release_root = Path(start["release_root_realpath"])
    if args.completion_receipt.parent != release_root or is_relative_to(args.completion_receipt, out):
        raise ContractError("RUN_RECEIPT_INVALID", "completion receipt location mismatch")
    try:
        if utc_to_unix_ns(completion["completed_utc"]) != completion["completed_unix_ns"]:
            raise ContractError("RUN_RECEIPT_INVALID", "completion UTC/ns mismatch")
    except ValueError as error:
        raise ContractError("RUN_RECEIPT_INVALID", str(error)) from error
    if completion["challenge"] != start["challenge"] or completion["run_receipt_sha256"] != sha256(args.run_receipt):
        raise ContractError("RUN_RECEIPT_INVALID", "completion start/challenge binding mismatch")
    if completion["completed_unix_ns"] < start["created_unix_ns"]:
        raise ContractError("RUN_RECEIPT_INVALID", "completion precedes start")

    transcript_path = _same_regular_file(out / "run-transcript.json", out, "run-transcript.json", "TRANSCRIPT_INVALID")
    transcript = load_canonical_schema_instance(
        transcript_path, package["schemas"]["transcript_schema"], "TRANSCRIPT_INVALID",
    )
    report_path = _same_regular_file(out / "web-baseline.json", out, "web-baseline.json", "REPORT_INCONSISTENT")
    server_log = _same_regular_file(out / "server.log", out, "server.log", "RUN_RECEIPT_INVALID")
    report = load_json(report_path, "REPORT_INCONSISTENT")
    try:
        validate_json_schema(report, package["schemas"]["contract_schema"])
    except SchemaValidationError as error:
        raise ContractError("REPORT_INCONSISTENT", str(error)) from error
    browser = report.get("browser", {})
    if transcript.get("challenge") != start["challenge"] or browser.get("run_challenge") != start["challenge"]:
        raise ContractError("RUN_RECEIPT_INVALID", "challenge binding mismatch")
    server_rows = server_log.read_text(encoding="utf-8").splitlines()
    if transcript.get("candidate") != args.candidate or transcript.get("tree") != args.tree:
        raise ContractError("PROVENANCE_INVALID", "transcript git identity mismatch")
    _check_transcript_times(start, transcript, completion)

    native_root = out / "native-reference"
    require_directory_canonical(native_root, "SCENARIO_INVALID")
    native = validate_native_outputs(native_root, repo, start["challenge"])
    reference = _same_regular_file(
        native_root / "ui_title_1280x720_standard.png", out,
        "native-reference/ui_title_1280x720_standard.png", "REFERENCE_MISSING",
    )
    reference_stat = reference.lstat()
    if reference_stat.st_nlink != 1:
        raise ContractError("REFERENCE_ALIAS", "reference hardlink count is not one")
    reference_stream = categorical_stream_from_image(reference, package["palette"])
    reference_signature = hashlib.sha256(reference_stream).hexdigest()

    events = transcript["events"]
    attempts = browser.get("attempts")
    if not isinstance(attempts, list) or not attempts or len(events) != 2 + len(attempts):
        raise ContractError("TRANSCRIPT_INVALID", "browser event cardinality mismatch")
    challenge_request = f"GET /index.html?release_challenge={start['challenge']} HTTP/"
    exact_challenge_requests = sum(challenge_request in row for row in server_rows)
    index_navigations = [row for row in server_rows if "GET /index.html" in row and " HTTP/" in row]
    if exact_challenge_requests != len(attempts) or len(index_navigations) != len(attempts):
        raise ContractError(
            "RUN_RECEIPT_INVALID",
            "server log must contain exactly one exact challenge-bearing navigation per browser attempt",
        )
    if any(challenge_request not in row for row in index_navigations):
        raise ContractError("RUN_RECEIPT_INVALID", "browser attempt navigation lacks exact challenge")
    expected_native_argv = native_argv(args.godot, repo, out, start["challenge"])
    expected_export_argv = export_argv(args.godot, repo, out)
    if events[0]["kind"] != "native_ui_shell_floor" or events[0]["argv"] != expected_native_argv:
        raise ContractError("TRANSCRIPT_INVALID", "native event argv mismatch")
    if events[1]["kind"] != "web_export" or events[1]["argv"] != expected_export_argv:
        raise ContractError("TRANSCRIPT_INVALID", "export event argv mismatch")
    if events[0]["exit_code"] != 0 or events[1]["exit_code"] != report["export"]["exit_code"]:
        raise ContractError("TRANSCRIPT_INVALID", "native/export exit mismatch")
    native_paths = [native_root / name for name in native["shots"]] + [native["report_path"], native["supplemental_path"]]
    if events[0]["outputs"] != output_rows(out, native_paths):
        raise ContractError("TRANSCRIPT_INVALID", "native output set/hash mismatch")
    export_paths = canonical_export_files(out)
    if events[1]["outputs"] != output_rows(out, export_paths):
        raise ContractError("TRANSCRIPT_INVALID", "export output set/hash mismatch")

    recomputed_attempts: list[dict[str, Any]] = []
    for index, attempt in enumerate(attempts):
        event = events[index + 2]
        if event["kind"] != "browser_attempt" or event["argv"] != browser_command(args.chromium):
            raise ContractError("TRANSCRIPT_INVALID", "browser argv mismatch")
        if attempt.get("command") != browser_command(args.chromium) or event["exit_code"] != attempt.get("exit_code"):
            raise ContractError("TRANSCRIPT_INVALID", "browser command/exit mismatch")
        screenshot_name = attempt.get("screenshot")
        stderr_name = attempt.get("stderr_log")
        if not isinstance(screenshot_name, str) or re.fullmatch(r"web-[0-9]+\.png", screenshot_name) is None:
            raise ContractError("REPORT_INCONSISTENT", "invalid browser screenshot path")
        if screenshot_name != f"web-{attempt.get('wait_budget_ms')}.png":
            raise ContractError("REPORT_INCONSISTENT", "browser screenshot/wait conflict")
        screenshot = _same_regular_file(out / screenshot_name, out, screenshot_name, "CURRENT_MISSING")
        stderr_path = _same_regular_file(out / str(stderr_name), out, str(stderr_name), "REPORT_INCONSISTENT")
        if event["outputs"] != output_rows(out, [screenshot, stderr_path]):
            raise ContractError("TRANSCRIPT_INVALID", "browser output set/hash mismatch")
        if screenshot.stat().st_dev == reference_stat.st_dev and screenshot.stat().st_ino == reference_stat.st_ino:
            raise ContractError("REFERENCE_ALIAS", "reference/current inode alias")
        signal = differential_signal(
            reference, screenshot, package["palette"], reference_stream=reference_stream,
        )
        if attempt.get("signal") != signal:
            raise ContractError("REPORT_INCONSISTENT", "browser signal does not match recomputation")
        recomputed_attempts.append(attempt)

    all_errors = [error for attempt in recomputed_attempts for error in attempt["console_errors"]]
    visible = [attempt for attempt in recomputed_attempts if attempt["signal"]["visible"]]
    expected_result = "pass" if visible and not all_errors and all(attempt["exit_code"] == 0 for attempt in recomputed_attempts) else "fail"
    expected_first = visible[0]["wait_budget_ms"] if visible else None
    expected_memory = max(
        (attempt["maximum_resident_kib"] for attempt in recomputed_attempts if attempt["maximum_resident_kib"] is not None),
        default=None,
    )
    request_count = len(server_rows)
    fixed_browser = {
        "signal_mode": "native_web_differential_v3",
        "candidate": args.candidate,
        "tree": args.tree,
        "repo_clean_before": True,
        "repo_clean_after": True,
        "run_challenge": start["challenge"],
        "run_receipt_relpath": f"../{args.run_receipt.name}",
        "run_receipt_sha256": sha256(args.run_receipt),
        "run_transcript_relpath": "run-transcript.json",
        "run_transcript_sha256": sha256(transcript_path),
        "server_log_sha256": sha256(server_log),
        "approval_manifest_sha256": APPROVAL_MANIFEST_SHA256,
        "owner_decision_relpath": str(args.owner_decision),
        "owner_decision_sha256": OWNER_DECISION_SHA256,
        "remediation_sha256": REMEDIATION_SHA256,
        "owner_decision_schema_sha256": OWNER_DECISION_SCHEMA_SHA256,
        "start_receipt_schema_sha256": START_RECEIPT_SCHEMA_SHA256,
        "completion_receipt_schema_sha256": COMPLETION_RECEIPT_SCHEMA_SHA256,
        "transcript_schema_sha256": TRANSCRIPT_SCHEMA_SHA256,
        "palette_contract_sha256": PALETTE_CONTRACT_SHA256,
        "oracle_sha256": ORACLE_SHA256,
        "legacy_schema_sha256": LEGACY_SCHEMA_SHA256,
        "contract_schema_sha256": CONTRACT_SCHEMA_SHA256,
        "scenario_contract_sha256": SCENARIO_CONTRACT_SHA256,
        "native_report_relpath": "native-reference/report.json",
        "native_report_sha256": sha256(native["report_path"]),
        "native_supplemental_relpath": "native-reference/ui-shell-report.json",
        "native_supplemental_sha256": sha256(native["supplemental_path"]),
        "reference_image_relpath": "native-reference/ui_title_1280x720_standard.png",
        "reference_image_sha256": sha256(reference),
        "reference_signature_sha256": reference_signature,
        "exact_shot_set_sha256": exact_shot_set_sha256(native["shots"]),
        "attempts": recomputed_attempts,
        "console_errors": all_errors,
        "first_title_visible_wait_ms": expected_first,
        "maximum_resident_kib": expected_memory,
        "memory_status": "measured" if expected_memory is not None else "unsupported",
        "request_count": request_count,
    }
    if browser != fixed_browser or report.get("result") != expected_result or report.get("repo") != str(repo):
        raise ContractError("REPORT_INCONSISTENT", "contract report binding mismatch")
    expected_export = {
        "command": expected_export_argv,
        "compressed_gzip_bytes": gzip_size(out / "web"),
        "exit_code": events[1]["exit_code"],
        "file_count": len(export_paths),
        "uncompressed_bytes": directory_size(out / "web"),
        "wall_ms": report["export"].get("wall_ms"),
    }
    if report["export"] != expected_export:
        raise ContractError("REPORT_INCONSISTENT", "export report mismatch")
    if (
        expected_result != "pass"
        or report.get("result") != "pass"
        or events[1]["exit_code"] != 0
        or report["export"].get("exit_code") != 0
        or not recomputed_attempts
        or any(attempt["exit_code"] != 0 for attempt in recomputed_attempts)
        or all_errors
        or not visible
    ):
        raise ContractError("REPORT_INCONSISTENT", "verify-output recomputed result is not exactly pass")
    if report.get("environment", {}).get("tool_sha256") != sha256(Path(__file__).resolve()):
        raise ContractError("REPORT_INCONSISTENT", "tool hash mismatch")
    expected_completion_hashes = {
        "run_transcript_sha256": sha256(transcript_path),
        "web_report_sha256": sha256(report_path),
        "server_log_sha256": sha256(server_log),
        "native_report_sha256": sha256(native["report_path"]),
        "native_supplemental_sha256": sha256(native["supplemental_path"]),
        "reference_image_sha256": sha256(reference),
    }
    for field, expected in expected_completion_hashes.items():
        if completion[field] != expected:
            raise ContractError("RUN_RECEIPT_INVALID", f"completion hash mismatch: {field}")
    visible_relpath = completion["visible_web_image_relpath"]
    if visible_relpath not in {attempt["screenshot"] for attempt in visible}:
        raise ContractError("RUN_RECEIPT_INVALID", "completion visible image is not visible")
    visible_path = _same_regular_file(out / visible_relpath, out, visible_relpath, "CURRENT_MISSING")
    if completion["visible_web_image_sha256"] != sha256(visible_path):
        raise ContractError("RUN_RECEIPT_INVALID", "completion visible image hash mismatch")
    print("PASS_CONTENT_EQUIVALENT")
    return 0


def option_names(argv: list[str]) -> set[str]:
    return {token.split("=", 1)[0] for token in argv if token.startswith("--")}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    path_options = (
        "repo", "out", "verify_output", "run_receipt", "completion_receipt", "owner_decision",
        "palette_contract", "oracle_contract", "approval_manifest", "owner_decision_schema",
        "start_receipt_schema", "completion_receipt_schema", "transcript_schema", "legacy_schema",
        "contract_schema",
    )
    for name in path_options:
        parser.add_argument(f"--{name.replace('_', '-')}", type=Path)
    value_options = (
        "candidate", "tree", "run_receipt_sha256", "completion_receipt_sha256",
        "owner_decision_sha256", "oracle_sha256", "approval_manifest_sha256",
        "owner_decision_schema_sha256", "start_receipt_schema_sha256",
        "completion_receipt_schema_sha256", "transcript_schema_sha256", "legacy_schema_sha256",
        "contract_schema_sha256",
    )
    for name in value_options:
        parser.add_argument(f"--{name.replace('_', '-')}")
    parser.add_argument("--godot", default=str(Path.home() / "bin/godot"))
    parser.add_argument("--chromium", default=shutil.which("chromium") or "chromium")
    parser.add_argument("--test-browser-fixture", help=argparse.SUPPRESS)
    return parser


def canonicalize_args(args: argparse.Namespace) -> None:
    for name, value in vars(args).items():
        if isinstance(value, Path):
            setattr(args, name, value.absolute().resolve(strict=False))


def main(argv: list[str] | None = None) -> int:
    import sys

    actual = list(sys.argv[1:] if argv is None else argv)
    names = option_names(actual)
    contract_names = set(GENERATION_REQUIRED_OPTIONS) | set(VERIFY_REQUIRED_OPTIONS)
    explicit_contract = bool(names & (contract_names - {"--repo", "--out"}))
    if "--verify-output" in names:
        if not set(VERIFY_REQUIRED_OPTIONS).issubset(names) or "--out" in names:
            build_parser().error("verify-output requires all 27 frozen options together")
        mode = "verify"
    elif explicit_contract:
        if not set(GENERATION_REQUIRED_OPTIONS).issubset(names) or "--verify-output" in names or "--completion-receipt" in names:
            build_parser().error("generation requires all 25 frozen options together")
        mode = "generation"
    else:
        if not {"--repo", "--out"}.issubset(names) or names - {"--repo", "--out", "--godot", "--chromium"}:
            build_parser().error("legacy invocation requires --repo --out [--godot --chromium]")
        mode = "legacy"
    parser = build_parser()
    args = parser.parse_args(actual)
    canonicalize_args(args)
    try:
        if mode == "legacy":
            return legacy_main(args)
        if mode == "generation":
            return generation_main(args)
        return verify_output_main(args)
    except ContractError as error:
        print(f"{error.code}: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
