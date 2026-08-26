#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-godot}
OUT=${1:-/tmp/proto-td-narrative-canon-visuals}
USER_DATA=${NARRATIVE_VISUAL_USER_DATA:-/tmp/proto-td-narrative-canon-userdata}
rm -rf "$OUT" "$USER_DATA"
mkdir -p "$OUT" "$USER_DATA"

capture() {
  local mode=$1
  local width=$2
  local height=$3
  local label=$4
  local output="$OUT/$label.png"
  local log="$OUT/$label.log"

  xvfb-run -a -s "-screen 0 ${width}x${height}x24 -ac +extension GLX +render -noreset" \
    env XDG_DATA_HOME="$USER_DATA/$label" GODOT_SILENCE_ROOT_WARNING=1 \
    "$GODOT_BIN" --path "$ROOT" --display-driver x11 --audio-driver Dummy \
      --rendering-method gl_compatibility --resolution "${width}x${height}" \
      res://test/narrative_canon_visual_harness.tscn -- \
      "--mode=$mode" "--out=$output" >"$log" 2>&1

  grep -q "NARRATIVE_VISUAL_CAPTURE_OK mode=$mode path=$output" "$log"
  identify -format '%wx%h' "$output" | grep -qx "${width}x${height}"
  if rg -n -i 'SCRIPT ERROR|ERROR:|FATAL|CRASH|missing resource|renderer.*fail|failed to load' "$log"; then
    return 1
  fi
}

capture title 1280 720 landscape-title
capture archive 1280 720 landscape-archive
capture results 1280 720 landscape-results
capture title 720 1280 portrait-title
capture archive 720 1280 portrait-archive

sha256sum "$OUT"/*.png >"$OUT/SHA256SUMS"
printf 'NARRATIVE_CANON_VISUALS_OK %s\n' "$OUT"
identify "$OUT"/*.png
