#!/usr/bin/env python3
"""Audit Protos localization catalogs and production source coverage.

The audit is deterministic and network-free. It verifies English/Simplified Chinese
key parity, placeholder parity, production localization-key coverage, and likely
hard-coded user-visible copy. Reviewed scene defaults are explicitly allowlisted
only when runtime code replaces them through UiCopy before presentation.
"""

from __future__ import annotations

import argparse
import ast
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRODUCTION_ROOTS = [
    ROOT / "autoloads",
    ROOT / "scripts",
    ROOT / "scenes",
    ROOT / "sim",
    ROOT / "data",
]
SOURCE_SUFFIXES = {".gd", ".tscn", ".tres", ".json"}
KEY_RE = re.compile(r'[&]?"((?:ui|data)\.[A-Za-z0-9_.]*[A-Za-z0-9_])"')
PLACEHOLDER_RE = re.compile(r"\{([A-Za-z][A-Za-z0-9_]*)\}")
VISIBLE_PATTERNS = [
    re.compile(
        r"\b(?:text|title|placeholder_text|tooltip_text|accessibility_name|"
        r'accessibility_description)\s*=\s*("(?:[^"\\]|\\.)*")'
    ),
    re.compile(r'\.set_text\(\s*("(?:[^"\\]|\\.)*")'),
    re.compile(r'\b(?:Label|Button|CheckButton|RichTextLabel)\.new\(\s*("(?:[^"\\]|\\.)*")'),
]
IGNORE_LITERAL = re.compile(
    r"^(?:|[A-Za-z0-9_./:-]+|res://.*|user://.*|uid://.*|"
    r"[0-9 .,:;_+*/%<>=!&|?×←→↔↕•—-]+)$"
)
FORMAT_TOKEN_RE = re.compile(r"%(?:\d+\$)?[-+#0 ]*(?:\d+|\*)?(?:\.\d+)?[diouxXeEfFgGscv%]")

# These are authored editor defaults. title.gd/title_settings.gd overwrite them
# through UiCopy during _ready() and on every locale_changed signal.
REVIEWED_RUNTIME_DEFAULTS = {
    ("scripts/ui/title.gd", "PROTOS DEFENSE"),
    ("scenes/ui/title_settings.tscn", "MASTER VOLUME"),
    ("scenes/ui/title_settings.tscn", "MUSIC VOLUME"),
    ("scenes/ui/title_settings.tscn", "SFX VOLUME"),
    ("scenes/ui/title_settings.tscn", "MUSIC // ON"),
    ("scenes/ui/title_settings.tscn", "FRAME LIMIT"),
    ("scenes/ui/title_settings.tscn", "ANIMATED BACKGROUND // ON"),
    ("scenes/ui/title_settings.tscn", "Settings could not be saved."),
}


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "docs" / "localization" / "latest-audit.json",
        help="JSON report destination",
    )
    parser.add_argument(
        "--strict-hardcoded",
        action="store_true",
        help="fail when unresolved hard-coded visible candidates remain",
    )
    return parser.parse_args()


def _decode_literal(token: str) -> str:
    value = ast.literal_eval(token)
    return value if isinstance(value, str) else str(value)


def _is_format_only(value: str) -> bool:
    remainder = FORMAT_TOKEN_RE.sub("", value)
    return re.search(r"[A-Za-z\u3400-\u9fff]", remainder) is None


def _catalog(locale: str) -> dict[str, str]:
    path = ROOT / "localization" / f"{locale}.json"
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload["entries"]


def main() -> int:
    args = _parse_args()
    catalogs = {locale: _catalog(locale) for locale in ("en-US", "zh-CN")}
    english = catalogs["en-US"]
    chinese = catalogs["zh-CN"]

    used_keys: dict[str, list[str]] = {}
    hardcoded: list[dict[str, object]] = []
    for base in PRODUCTION_ROOTS:
        if not base.exists():
            continue
        paths = sorted(
            path for path in base.rglob("*")
            if path.is_file() and path.suffix in SOURCE_SUFFIXES
        )
        for path in paths:
            relative = path.relative_to(ROOT).as_posix()
            try:
                lines = path.read_text(encoding="utf-8").splitlines()
            except UnicodeDecodeError:
                continue
            for line_number, line in enumerate(lines, 1):
                stripped = line.strip()
                if stripped.startswith(("#", ";")):
                    continue
                for match in KEY_RE.finditer(line):
                    used_keys.setdefault(match.group(1), []).append(
                        f"{relative}:{line_number}"
                    )
                if path.suffix not in {".gd", ".tscn"}:
                    continue
                for pattern in VISIBLE_PATTERNS:
                    for match in pattern.finditer(line):
                        value = _decode_literal(match.group(1))
                        if value.startswith(("ui.", "data.")):
                            continue
                        if IGNORE_LITERAL.fullmatch(value) or _is_format_only(value):
                            continue
                        if (relative, value) in REVIEWED_RUNTIME_DEFAULTS:
                            continue
                        if re.search(r"[A-Za-z\u3400-\u9fff]", value):
                            hardcoded.append(
                                {
                                    "path": relative,
                                    "line": line_number,
                                    "text": value,
                                    "source": stripped,
                                }
                            )

    missing_chinese = sorted(set(english) - set(chinese))
    extra_chinese = sorted(set(chinese) - set(english))
    placeholder_drift = []
    for key in sorted(set(english) & set(chinese)):
        english_placeholders = sorted(PLACEHOLDER_RE.findall(english[key]))
        chinese_placeholders = sorted(PLACEHOLDER_RE.findall(chinese[key]))
        if english_placeholders != chinese_placeholders:
            placeholder_drift.append(
                {
                    "key": key,
                    "english": english_placeholders,
                    "chinese": chinese_placeholders,
                }
            )

    identical = [
        {"key": key, "value": english[key]}
        for key in sorted(set(english) & set(chinese))
        if english[key] == chinese[key]
    ]
    missing_catalog_keys = sorted(set(used_keys) - set(english))
    report = {
        "catalog_counts": {locale: len(entries) for locale, entries in catalogs.items()},
        "missing_chinese": missing_chinese,
        "extra_chinese": extra_chinese,
        "placeholder_drift": placeholder_drift,
        "identical_values": identical,
        "production_key_count": len(used_keys),
        "missing_catalog_keys": [
            {"key": key, "locations": used_keys[key]} for key in missing_catalog_keys
        ],
        "unreferenced_catalog_keys": sorted(set(english) - set(used_keys)),
        "hardcoded_visible_candidates": hardcoded,
        "reviewed_runtime_defaults": [
            {"path": path, "text": text}
            for path, text in sorted(REVIEWED_RUNTIME_DEFAULTS)
        ],
    }
    output = args.output if args.output.is_absolute() else ROOT / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    summary = {
        "catalog_counts": report["catalog_counts"],
        "missing_chinese": len(missing_chinese),
        "extra_chinese": len(extra_chinese),
        "placeholder_drift": len(placeholder_drift),
        "identical_values": len(identical),
        "production_key_count": len(used_keys),
        "missing_catalog_keys": len(missing_catalog_keys),
        "unreferenced_catalog_keys": len(report["unreferenced_catalog_keys"]),
        "hardcoded_visible_candidates": len(hardcoded),
        "report": str(output),
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    structural_failure = bool(
        missing_chinese or extra_chinese or placeholder_drift or missing_catalog_keys
    )
    if structural_failure or (args.strict_hardcoded and hardcoded):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
