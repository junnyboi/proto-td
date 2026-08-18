#!/usr/bin/env python3
from __future__ import annotations

import ast
import hashlib
import json
import re
import subprocess
from pathlib import Path
from typing import Any

APPROVAL_PATH = "res://docs/media/PHASE-6-RECRUIT-EXACT-BYTE-APPROVAL.json"
APPROVED_CANDIDATE = "f43c6dcdaba4e8df188b27a09363cbbba410afd2"
APPROVED_AT_UTC = "2026-08-18T07:05:49Z"
APPROVED_MANIFEST_SHA256 = "9d0b170c899b23ce9220dd1b649e27ab9a1118121eff405787f88ddca3d60641"
APPROVED_ASSET_SET_SHA256 = "378c4aa274de77c336f8847c21d589c8f9d9db30a4ccbfd50bafefccd89f0bf8"
APPROVED_ASSET_PATHS = [
    *(f"res://assets/portraits/recruit_{index:02d}.png" for index in range(8)),
    *(f"res://assets/sprites/recruit_{index}.png" for index in range(5)),
]
APPROVED_SOURCE_PATHS = [
    "res://art-src/characters/recruit/recruit-portrait-treatment-sheet.png",
    "res://art-src/characters/recruit/recruit-field-master.png",
]
APPROVED_CONTACT_PATHS = [
    "res://docs/media/phase6-recruit-final-contact-sheet.png",
    "res://docs/media/phase6-recruit-runtime-contact-sheet.png",
]
APPROVED_LOGICAL_IDS = [
    *(f"portrait_recruit_{index:02d}" for index in range(8)),
    "recruit",
]
AUTHORIZED_MUTATION = (
    "flip only the nine approved Recruit manifest placeholder flags to false and regenerate "
    "their provenance without changing approved PNG bytes"
)
APPROVAL_TEXT = (
    "ACCEPT Phase 6 Recruit exact bytes at manifest SHA-256 "
    f"{APPROVED_MANIFEST_SHA256} and ordered asset-set SHA-256 "
    f"{APPROVED_ASSET_SET_SHA256}."
)
TOP_LEVEL_KEYS = {
    "accepted_at_utc",
    "accepted_candidate_commit",
    "approval_text",
    "approved_manifest_sha256",
    "closure_authority",
    "contact_sheets",
    "feature",
    "human_accepter",
    "ordered_asset_set_sha256",
    "ordered_assets",
    "phase",
    "schema_version",
    "source_authority",
    "verdict",
}
ROW_KEYS = {"bytes", "path", "sha256"}


def _disk_path(repo: Path, resource_path: str) -> Path:
    if not resource_path.startswith("res://"):
        raise ValueError(f"Recruit approval path is not res://: {resource_path}")
    resolved = (repo / resource_path.removeprefix("res://")).resolve()
    if repo.resolve() not in resolved.parents:
        raise ValueError(f"Recruit approval path escapes repository: {resource_path}")
    return resolved


def _digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _canonical_bytes(document: dict[str, Any]) -> bytes:
    return (
        json.dumps(document, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n"
    ).encode("utf-8")


def _candidate_manifest(repo: Path) -> bytes:
    result = subprocess.run(
        [
            "git",
            "-C",
            str(repo),
            "show",
            f"{APPROVED_CANDIDATE}:assets/manifest.tres",
        ],
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        raise ValueError("Recruit approval candidate manifest is unavailable from Git")
    return result.stdout


def _manifest_entry(text: str, logical_id: str) -> str:
    marker = f'&"{logical_id}": {{'
    start = text.find(marker)
    if start < 0:
        raise ValueError(f"Recruit manifest entry missing: {logical_id}")
    brace = text.find("{", start)
    depth = 0
    quoted = False
    escaped = False
    for index in range(brace, len(text)):
        char = text[index]
        if quoted:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quoted = False
            continue
        if char == '"':
            quoted = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start : index + 1]
    raise ValueError(f"Recruit manifest entry is unterminated: {logical_id}")


def _manifest_entry_keys(text: str) -> list[str]:
    match = re.search(r"\bentries\s*=\s*\{", text)
    if match is None:
        raise ValueError("Recruit manifest entries dictionary is missing")
    index = text.find("{", match.start())
    depth = 0
    keys: list[str] = []
    while index < len(text):
        char = text[index]
        if char == "#" or text.startswith("//", index):
            newline = text.find("\n", index)
            index = len(text) if newline < 0 else newline + 1
            continue
        if char == '"':
            start = index
            index += 1
            escaped = False
            while index < len(text):
                current = text[index]
                if escaped:
                    escaped = False
                elif current == "\\":
                    escaped = True
                elif current == '"':
                    break
                index += 1
            if index >= len(text):
                raise ValueError("Recruit manifest contains an unterminated string")
            raw = text[start : index + 1]
            after = index + 1
            while after < len(text):
                while after < len(text) and text[after].isspace():
                    after += 1
                if after < len(text) and text[after] == "#":
                    newline = text.find("\n", after)
                    after = len(text) if newline < 0 else newline + 1
                    continue
                if text.startswith("//", after):
                    newline = text.find("\n", after)
                    after = len(text) if newline < 0 else newline + 1
                    continue
                break
            if depth == 1 and after < len(text) and text[after] == ":":
                try:
                    key = ast.literal_eval(raw)
                except (SyntaxError, ValueError) as error:
                    raise ValueError("Recruit manifest key escape is invalid") from error
                if not isinstance(key, str):
                    raise ValueError("Recruit manifest dictionary key is not text")
                keys.append(key)
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return keys
            if depth < 0:
                raise ValueError("Recruit manifest entries dictionary is malformed")
        index += 1
    raise ValueError("Recruit manifest entries dictionary is unterminated")


def _recruit_manifest_ids(text: str) -> list[str]:
    ids = _manifest_entry_keys(text)
    return [
        logical_id
        for logical_id in ids
        if logical_id == "recruit" or logical_id.startswith("portrait_recruit_")
    ]


def _closed_manifest_entry(repo: Path, approved_entry: str, logical_id: str) -> str:
    expected = approved_entry.replace('"placeholder": true', '"placeholder": false', 1)
    sidecar = repo / f"assets/provenance/{logical_id}.provenance.json"
    if not sidecar.is_file():
        raise ValueError(f"Recruit provenance sidecar is missing: {logical_id}")
    provenance_digest = _digest(sidecar.read_bytes())
    expected, count = re.subn(
        r'"provenance_sha256": "[0-9a-f]{64}"',
        f'"provenance_sha256": "{provenance_digest}"',
        expected,
        count=1,
    )
    if count != 1:
        raise ValueError(f"Recruit approved manifest provenance field is malformed: {logical_id}")
    return expected


def _validate_current_manifest(
    repo: Path,
    approved_manifest: bytes,
    current_manifest: bytes,
) -> None:
    try:
        approved_text = approved_manifest.decode("utf-8")
        current_text = current_manifest.decode("utf-8")
    except UnicodeDecodeError as error:
        raise ValueError("Recruit manifest is not UTF-8") from error
    expected_ids = set(APPROVED_LOGICAL_IDS)
    approved_ids = _recruit_manifest_ids(approved_text)
    current_ids = _recruit_manifest_ids(current_text)
    if len(approved_ids) != len(expected_ids) or set(approved_ids) != expected_ids:
        raise ValueError("Recruit approved manifest logical ID closure mismatch")
    if len(current_ids) != len(expected_ids) or set(current_ids) != expected_ids:
        raise ValueError("Recruit current manifest logical ID closure mismatch")
    for logical_id in APPROVED_LOGICAL_IDS:
        approved_entry = _manifest_entry(approved_text, logical_id)
        current_entry = _manifest_entry(current_text, logical_id)
        if current_entry != _closed_manifest_entry(repo, approved_entry, logical_id):
            raise ValueError(f"Recruit current manifest projection mismatch: {logical_id}")


def _validate_rows(
    repo: Path,
    rows: Any,
    expected_paths: list[str],
    label: str,
    generated: dict[str, bytes] | None = None,
    file_overrides: dict[str, bytes] | None = None,
) -> list[dict[str, Any]]:
    if not isinstance(rows, list) or len(rows) != len(expected_paths):
        raise ValueError(f"Recruit approval {label} count mismatch")
    actual_paths: list[str] = []
    validated: list[dict[str, Any]] = []
    for row in rows:
        if not isinstance(row, dict) or set(row) != ROW_KEYS:
            raise ValueError(f"Recruit approval {label} row schema mismatch")
        path = row.get("path")
        size = row.get("bytes")
        digest = row.get("sha256")
        if not isinstance(path, str) or not isinstance(size, int) or isinstance(size, bool):
            raise ValueError(f"Recruit approval {label} row type mismatch")
        if not isinstance(digest, str) or len(digest) != 64:
            raise ValueError(f"Recruit approval {label} digest type mismatch")
        actual_paths.append(path)
        if generated is None:
            if file_overrides is not None and path in file_overrides:
                data = file_overrides[path]
            else:
                disk = _disk_path(repo, path)
                if not disk.is_file():
                    raise ValueError(f"Recruit approval {label} file missing: {path}")
                data = disk.read_bytes()
        else:
            if path not in generated:
                raise ValueError(f"Recruit approval generated {label} file missing: {path}")
            data = generated[path]
        if len(data) != size or _digest(data) != digest:
            raise ValueError(f"Recruit approval {label} bytes mismatch: {path}")
        validated.append(row)
    if actual_paths != expected_paths or len(set(actual_paths)) != len(actual_paths):
        raise ValueError(f"Recruit approval {label} path order mismatch")
    if generated is not None and set(generated) != set(expected_paths):
        raise ValueError(f"Recruit approval generated {label} closure mismatch")
    return validated


def validate_recruit_approval(
    repo: Path,
    document: dict[str, Any],
    raw: bytes,
    *,
    generated_assets: dict[str, bytes] | None = None,
    generated_contact_sheet: bytes | None = None,
    candidate_manifest: bytes | None = None,
    current_manifest: bytes | None = None,
    file_overrides: dict[str, bytes] | None = None,
) -> dict[str, Any]:
    repo = repo.resolve()
    if not isinstance(document, dict) or set(document) != TOP_LEVEL_KEYS:
        raise ValueError("Recruit exact-byte approval record schema mismatch")
    if raw != _canonical_bytes(document):
        raise ValueError("Recruit exact-byte approval record is not canonical")
    exact = {
        "schema_version": 1,
        "phase": 6,
        "feature": "Recruit art and Memorial presentation",
        "verdict": "ACCEPT",
        "human_accepter": "Poseidon",
        "accepted_at_utc": APPROVED_AT_UTC,
        "accepted_candidate_commit": APPROVED_CANDIDATE,
        "approved_manifest_sha256": APPROVED_MANIFEST_SHA256,
        "ordered_asset_set_sha256": APPROVED_ASSET_SET_SHA256,
        "approval_text": APPROVAL_TEXT,
    }
    for key, expected in exact.items():
        if document.get(key) != expected:
            raise ValueError(f"Recruit exact-byte approval field mismatch: {key}")
    closure = document.get("closure_authority")
    if not isinstance(closure, dict) or set(closure) != {
        "approved_logical_ids",
        "authorized_mutation",
    }:
        raise ValueError("Recruit approval closure authority schema mismatch")
    if closure.get("approved_logical_ids") != APPROVED_LOGICAL_IDS:
        raise ValueError("Recruit approval logical ID order mismatch")
    if closure.get("authorized_mutation") != AUTHORIZED_MUTATION:
        raise ValueError("Recruit approval mutation authority mismatch")

    assets = _validate_rows(
        repo,
        document.get("ordered_assets"),
        APPROVED_ASSET_PATHS,
        "asset",
        generated_assets,
        file_overrides,
    )
    canonical_lines = "".join(
        f"{row['path'].removeprefix('res://')}\t{row['sha256']}\n" for row in assets
    ).encode("utf-8")
    if _digest(canonical_lines) != APPROVED_ASSET_SET_SHA256:
        raise ValueError("Recruit approval ordered asset-set digest mismatch")
    _validate_rows(
        repo,
        document.get("source_authority"),
        APPROVED_SOURCE_PATHS,
        "source",
        file_overrides=file_overrides,
    )
    contacts = _validate_rows(
        repo,
        document.get("contact_sheets"),
        APPROVED_CONTACT_PATHS,
        "contact sheet",
        file_overrides=file_overrides,
    )
    if generated_contact_sheet is not None:
        expected_contact = contacts[0]
        if (
            len(generated_contact_sheet) != expected_contact["bytes"]
            or _digest(generated_contact_sheet) != expected_contact["sha256"]
        ):
            raise ValueError("Recruit generated review contact sheet is not the approved byte set")
    manifest_bytes = candidate_manifest if candidate_manifest is not None else _candidate_manifest(repo)
    if _digest(manifest_bytes) != APPROVED_MANIFEST_SHA256:
        raise ValueError("Recruit approval candidate manifest digest mismatch")
    current_manifest_bytes = (
        current_manifest
        if current_manifest is not None
        else (repo / "assets/manifest.tres").read_bytes()
    )
    _validate_current_manifest(repo, manifest_bytes, current_manifest_bytes)
    return document


def authenticate_recruit_approval(
    repo: Path,
    *,
    generated_assets: dict[str, bytes] | None = None,
    generated_contact_sheet: bytes | None = None,
    candidate_manifest: bytes | None = None,
    current_manifest: bytes | None = None,
    file_overrides: dict[str, bytes] | None = None,
) -> dict[str, Any]:
    repo = repo.resolve()
    approval_file = _disk_path(repo, APPROVAL_PATH)
    if not approval_file.is_file():
        raise ValueError("Recruit exact-byte approval record is missing")
    raw = approval_file.read_bytes()
    try:
        document = json.loads(raw)
    except json.JSONDecodeError as error:
        raise ValueError("Recruit exact-byte approval record is invalid JSON") from error
    return validate_recruit_approval(
        repo,
        document,
        raw,
        generated_assets=generated_assets,
        generated_contact_sheet=generated_contact_sheet,
        candidate_manifest=candidate_manifest,
        current_manifest=current_manifest,
        file_overrides=file_overrides,
    )
