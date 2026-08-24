#!/usr/bin/env bash
# Fast, scope-aware validation entrypoint. See docs/validation.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCENARIO="${VALIDATION_SCENARIO:-boot}"
FOCUSED_TEST=""
RENDER=0
WEB=0

usage() {
  cat <<'EOF'
Usage: scripts/validate.sh [--scenario=NAME] [--test=res://test/test_name.gd] [--render] [--web]

Default: import, bounded headless boot, GUT smoke, and one deterministic headless scenario.
  --test=PATH      Replace the smoke GUT file with one focused test file.
  --scenario=NAME  Replace the default boot scenario.
  --render         Also run the selected scenario in the windowed render lane.
  --web            Also export a release Web bundle and verify HTML/JS/WASM/PCK files.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --scenario=*) SCENARIO="${arg#--scenario=}" ;;
    --test=*) FOCUSED_TEST="${arg#--test=}" ;;
    --render) RENDER=1 ;;
    --web) WEB=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[validate] unknown argument: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

resolve_godot() {
  if [[ -n "${GODOT:-}" ]]; then
    printf '%s\n' "$GODOT"
  elif command -v godot >/dev/null 2>&1; then
    command -v godot
  elif command -v godot4 >/dev/null 2>&1; then
    command -v godot4
  elif [[ -x "$HOME/.local/bin/godot" ]]; then
    printf '%s\n' "$HOME/.local/bin/godot"
  else
    echo '[validate] Godot not found; run the project bootstrap first' >&2
    return 127
  fi
}

GODOT_BIN="$(resolve_godot)"
GODOT_VERSION="$($GODOT_BIN --version)"
if [[ "$GODOT_VERSION" != 4.7.2.stable.official.* ]]; then
  echo "[validate] expected Godot 4.7.2 stable, got $GODOT_VERSION" >&2
  exit 2
fi

ARTIFACT_ROOT="$ROOT/artifacts/validation"
USER_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/protos-validate.XXXXXX")"
QUIET_OVERRIDE=0
cleanup() {
  [[ "$QUIET_OVERRIDE" -eq 0 ]] || rm -f "$ROOT/override.cfg"
  rm -rf "$USER_ROOT"
}
trap cleanup EXIT
rm -rf "$ARTIFACT_ROOT"
mkdir -p "$ARTIFACT_ROOT" "$USER_ROOT/data" "$USER_ROOT/config" "$USER_ROOT/cache"

FATAL_PATTERN='SCRIPT ERROR:|Parse Error:|Failed to load script|Failed to instantiate an autoload|Failed loading resource|Cannot open file|Could not resolve|Invalid call|Invalid access'
RESULTS='[]'

run_check() {
  local name="$1" budget="$2" log="$ARTIFACT_ROOT/$1.log" start end code
  shift 2
  start=$(date +%s)
  set +e
  GODOT_SILENCE_ROOT_WARNING=1 \
    XDG_DATA_HOME="$USER_ROOT/data" \
    XDG_CONFIG_HOME="$USER_ROOT/config" \
    XDG_CACHE_HOME="$USER_ROOT/cache" \
    timeout "${budget}s" "$@" >"$log" 2>&1
  code=$?
  set -e
  end=$(date +%s)
  if [[ $code -ne 0 ]] || grep -Eq "$FATAL_PATTERN" "$log"; then
    echo "[validate] $name FAIL (exit=$code)" >&2
    cat "$log" >&2
    RESULTS=$(jq -c --arg n "$name" --argjson s "$((end - start))" '. + [{check:$n,status:"fail",seconds:$s}]' <<<"$RESULTS")
    printf '%s\n' "$RESULTS" | jq '.' > "$ARTIFACT_ROOT/summary.json"
    if [[ $code -ne 0 ]]; then exit "$code"; else exit 1; fi
  fi
  RESULTS=$(jq -c --arg n "$name" --argjson s "$((end - start))" '. + [{check:$n,status:"pass",seconds:$s}]' <<<"$RESULTS")
  echo "[validate] $name PASS ($((end - start))s)"
}

run_check import 120 "$GODOT_BIN" --headless --path . --import
run_check boot 60 "$GODOT_BIN" --headless --fixed-fps 60 --path . --quit-after 120

TEST_PATH="${FOCUSED_TEST:-res://test/test_smoke.gd}"
run_check gut-focused 120 "$GODOT_BIN" --headless -d -s addons/gut/gut_cmdln.gd -gtest="$TEST_PATH" -gexit
grep -Eq 'Tests[[:space:]]+[1-9][0-9]*' "$ARTIFACT_ROOT/gut-focused.log" || {
  echo '[validate] GUT reported zero tests or no parseable test count' >&2
  exit 1
}

[[ -f "selftest/scenarios/$SCENARIO.gd" ]] || {
  echo "[validate] scenario not found: $SCENARIO" >&2
  exit 2
}
rm -f "artifacts/$SCENARIO/report.json"
run_check scenario-headless 120 "$GODOT_BIN" --headless --fixed-fps 60 --path . -s selftest/harness.gd -- \
  --scenario="$SCENARIO" --seed=42 --shots="res://artifacts/$SCENARIO"
jq -e --arg scenario "$SCENARIO" \
  '.result == "pass" and .scenario == $scenario and (.checks | length) > 0' \
  "artifacts/$SCENARIO/report.json" >/dev/null

if [[ "$RENDER" -eq 1 ]]; then
  printf '[display]\nwindow/size/no_focus=true\n' > override.cfg
  QUIET_OVERRIDE=1
  rm -f "artifacts/$SCENARIO/report.json" "artifacts/$SCENARIO"/*.png
  WINDOW_CMD=("$GODOT_BIN" --path . --resolution 1280x720 -s selftest/harness.gd -- \
    --scenario="$SCENARIO" --seed=42 --shots="res://artifacts/$SCENARIO")
  if [[ -z "${DISPLAY:-}" ]] && command -v xvfb-run >/dev/null 2>&1; then
    WINDOW_CMD=(xvfb-run -a "${WINDOW_CMD[@]}")
  fi
  run_check scenario-windowed 120 "${WINDOW_CMD[@]}"
  jq -e --arg scenario "$SCENARIO" \
    '.result == "pass" and .scenario == $scenario and (.checks | length) > 0 and (.shots | length) > 0' \
    "artifacts/$SCENARIO/report.json" >/dev/null
  rm -f override.cfg
  QUIET_OVERRIDE=0
fi

if [[ "$WEB" -eq 1 ]]; then
  TEMPLATE_SOURCE="$HOME/.local/share/godot/export_templates/4.7.2.stable/web_nothreads_release.zip"
  [[ -s "$TEMPLATE_SOURCE" ]] || {
    echo "[validate] missing Godot 4.7.2 Web template: $TEMPLATE_SOURCE" >&2
    exit 2
  }
  TEMPLATE_DIR="$USER_ROOT/data/godot/export_templates/4.7.2.stable"
  mkdir -p "$TEMPLATE_DIR"
  cp "$TEMPLATE_SOURCE" "$TEMPLATE_DIR/web_nothreads_release.zip"
  WEB_OUT="$ROOT/artifacts/web"
  rm -rf "$WEB_OUT"
  mkdir -p "$WEB_OUT"
  run_check web-export 300 "$GODOT_BIN" --headless --path . --export-release Web "$WEB_OUT/index.html"
  for required in index.html index.js index.wasm index.pck; do
    [[ -s "$WEB_OUT/$required" ]] || {
      echo "[validate] missing or empty Web artifact: $required" >&2
      exit 1
    }
  done
  sha256sum "$WEB_OUT"/index.html "$WEB_OUT"/index.js "$WEB_OUT"/index.wasm "$WEB_OUT"/index.pck \
    > "$ARTIFACT_ROOT/web-sha256.txt"
fi

printf '%s\n' "$RESULTS" | jq '.' > "$ARTIFACT_ROOT/summary.json"
echo "[validate] ALL GREEN engine=$GODOT_VERSION scenario=$SCENARIO render=$RENDER web=$WEB"
