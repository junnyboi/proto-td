#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_VERSION_PREFIX="${EXPECTED_GODOT_VERSION_PREFIX:-4.7.2.stable.official.}"
IMPORT_TIMEOUT_SECONDS="${QUICK_CHECK_IMPORT_TIMEOUT_SECONDS:-180}"
BOOT_TIMEOUT_SECONDS="${QUICK_CHECK_BOOT_TIMEOUT_SECONDS:-60}"
SCENARIO_TIMEOUT_SECONDS="${QUICK_CHECK_SCENARIO_TIMEOUT_SECONDS:-120}"

resolve_godot() {
  if [[ -n "${GODOT:-}" ]]; then
    printf '%s\n' "$GODOT"
    return
  fi
  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return
  fi
  if command -v godot4 >/dev/null 2>&1; then
    command -v godot4
    return
  fi
  if [[ -x "$HOME/.local/bin/godot" ]]; then
    printf '%s\n' "$HOME/.local/bin/godot"
    return
  fi
  if [[ -x "$HOME/bin/godot" ]]; then
    printf '%s\n' "$HOME/bin/godot"
    return
  fi
  echo '[quick-check] RED Godot executable not found; set GODOT or run the project bootstrap' >&2
  return 127
}

GODOT_BIN="$(resolve_godot)"
[[ -x "$GODOT_BIN" ]] || {
  echo "[quick-check] RED Godot is not executable: $GODOT_BIN" >&2
  exit 127
}

version="$($GODOT_BIN --version)"
[[ "$version" == "$EXPECTED_VERSION_PREFIX"* ]] || {
  echo "[quick-check] RED expected Godot ${EXPECTED_VERSION_PREFIX}*, got $version" >&2
  exit 2
}

WORK_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/protos-quick-check.XXXXXX")"
trap 'rm -rf "$WORK_ROOT"' EXIT
IMPORT_LOG="$WORK_ROOT/import.log"
BOOT_LOG="$WORK_ROOT/boot.log"
SCENARIO_LOG="$WORK_ROOT/scenario-boot.log"
FATAL_PATTERN='SCRIPT ERROR:|Parse Error:|Failed to load script|Failed to instantiate an autoload|Could not find type|Cannot open file|Failed loading resource'

print_failure() {
  local label="$1"
  local log="$2"
  echo "[quick-check] RED $label" >&2
  cat "$log" >&2
}

cd "$ROOT"
export GODOT_SILENCE_ROOT_WARNING=1

echo "[quick-check] engine=$version path=$GODOT_BIN"
if ! timeout "${IMPORT_TIMEOUT_SECONDS}s" "$GODOT_BIN" --headless --path . --editor --quit --import >"$IMPORT_LOG" 2>&1; then
  print_failure 'import command failed' "$IMPORT_LOG"
  exit 1
fi
if grep -Eq "$FATAL_PATTERN" "$IMPORT_LOG"; then
  print_failure 'import reported fatal parser/resource text' "$IMPORT_LOG"
  exit 1
fi
echo '[quick-check] import=PASS'

if ! timeout "${BOOT_TIMEOUT_SECONDS}s" "$GODOT_BIN" --headless --path . --fixed-fps 60 --quit-after 120 >"$BOOT_LOG" 2>&1; then
  print_failure 'bounded boot command failed' "$BOOT_LOG"
  exit 1
fi
if grep -Eq "$FATAL_PATTERN" "$BOOT_LOG"; then
  print_failure 'bounded boot reported fatal parser/resource text' "$BOOT_LOG"
  exit 1
fi
echo '[quick-check] boot=PASS frames=120'

if ! timeout "${SCENARIO_TIMEOUT_SECONDS}s" "$GODOT_BIN" --headless --path . --fixed-fps 60 -s selftest/harness.gd -- --scenario=boot --seed=42 >"$SCENARIO_LOG" 2>&1; then
  print_failure 'deterministic boot scenario command failed' "$SCENARIO_LOG"
  exit 1
fi
if grep -Eq "$FATAL_PATTERN|\[FAIL\]" "$SCENARIO_LOG"; then
  print_failure 'deterministic boot scenario reported a failure' "$SCENARIO_LOG"
  exit 1
fi
if ! grep -Fq '[RESULT] pass (' "$SCENARIO_LOG"; then
  print_failure 'deterministic boot scenario did not publish a pass result' "$SCENARIO_LOG"
  exit 1
fi
result_line="$(grep -F '[RESULT] pass (' "$SCENARIO_LOG" | tail -1)"
echo "[quick-check] scenario=PASS $result_line"
echo '[quick-check] ALL GREEN'
