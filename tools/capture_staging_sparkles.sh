#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-godot}
OUT_DIR=${1:-"$ROOT/build/staging-sparkle-regressions"}
USER_DATA=${STAGING_SPARKLE_USER_DATA:-/tmp/proto-td-staging-sparkle-userdata}

rm -rf "$OUT_DIR" "$USER_DATA"
mkdir -p "$OUT_DIR" "$USER_DATA"

capture() {
  local label=$1
  local width=$2
  local height=$3
  local output="$OUT_DIR/$label.png"
  local log="$OUT_DIR/$label.log"

  timeout 180s xvfb-run -a -s "-screen 0 ${width}x${height}x24 -ac +extension GLX +render -noreset" \
    env GODOT_BIN="$GODOT_BIN" PROTO_TD_TEST_ARTIFACT_DIR="$USER_DATA/$label" \
    GODOT_SILENCE_ROOT_WARNING=1 "$ROOT/tools/run_godot_isolated.sh" \
      --display-driver x11 --audio-driver Dummy \
      --rendering-method gl_compatibility --resolution "${width}x${height}" \
      res://test/staging_sparkles_visual_harness.tscn -- \
      "--output=$output" >"$log" 2>&1

  grep -q "STAGING_SPARKLES_VISUAL_OK|$output|${width}x${height}" "$log"
  identify -format '%wx%h' "$output" | grep -qx "${width}x${height}"
  if rg -n -i 'SCRIPT ERROR|ERROR:|FATAL|CRASH|missing resource|renderer.*fail|failed to load' "$log"; then
    return 1
  fi
}

capture staging-sparkles-landscape 1280 720
capture staging-sparkles-portrait 720 1280

sha256sum "$OUT_DIR"/*.png >"$OUT_DIR/SHA256SUMS"
printf '%s\n' 'STAGING_SPARKLE_SCREENSHOT_REGRESSIONS_OK'
identify "$OUT_DIR"/*.png
