#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-godot}
OUT=${1:-/tmp/proto-td-mission-cinematic-visuals}
USER_DATA=${MISSION_CINEMATIC_VISUAL_USER_DATA:-/tmp/proto-td-mission-cinematic-visual-userdata}
TEXT_SCALE=${MISSION_CINEMATIC_VISUAL_TEXT_SCALE:-1.50}
rm -rf "$OUT" "$USER_DATA"
mkdir -p "$OUT" "$USER_DATA"

capture() {
  local locale=$1
  local mode=$2
  local stage=$3
  local width=$4
  local height=$5
  local orientation=$6
  local label="${locale}-${stage}-${orientation}-${mode}"
  local output="$OUT/$label.png"
  local log="$OUT/$label.log"

  timeout 150s xvfb-run -a -s "-screen 0 ${width}x${height}x24 -ac +extension GLX +render -noreset" \
    env XDG_DATA_HOME="$USER_DATA/$label" GODOT_SILENCE_ROOT_WARNING=1 \
    "$GODOT_BIN" --path "$ROOT" --display-driver x11 --audio-driver Dummy \
      --rendering-method gl_compatibility --resolution "${width}x${height}" \
      res://test/mission_cinematic_visual_harness.tscn -- \
      "--mode=$mode" "--stage=$stage" "--out=$output" \
      "--locale=$locale" "--text-scale=$TEXT_SCALE" >"$log" 2>&1

  grep -q "MISSION_CINEMATIC_VISUAL_OK mode=$mode path=$output locale=$locale stage=$stage" "$log"
  identify -format '%wx%h' "$output" | grep -qx "${width}x${height}"
  if rg -n -i 'SCRIPT ERROR|Parse Error|ERROR:|FATAL|CRASH|missing resource|renderer.*fail|failed to load|Resource still in use|ObjectDB instances leaked' "$log"; then
    return 1
  fi
}

for locale in en-US zh-CN; do
  capture "$locale" gate s1 1280 720 landscape
  capture "$locale" player s16 1280 720 landscape
  capture "$locale" gate s1 720 1280 portrait
  capture "$locale" player s16 720 1280 portrait
  capture "$locale" skip s1 1280 720 landscape
  capture "$locale" skip s1 720 1280 portrait
  capture "$locale" replay s1 1280 720 landscape
  capture "$locale" replay s1 720 1280 portrait
done

sha256sum "$OUT"/*.png > "$OUT/SHA256SUMS"
printf 'MISSION_CINEMATIC_VISUALS_OK %s text_scale=%s captures=%s\n' "$OUT" "$TEXT_SCALE" "$(find "$OUT" -maxdepth 1 -type f -name '*.png' | wc -l)"
identify "$OUT"/*.png
