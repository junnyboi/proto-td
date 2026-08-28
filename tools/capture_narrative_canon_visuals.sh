#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-godot}
OUT=${1:-/tmp/proto-td-narrative-canon-visuals}
USER_DATA=${NARRATIVE_VISUAL_USER_DATA:-/tmp/proto-td-narrative-canon-userdata}
LOCALE=${NARRATIVE_VISUAL_LOCALE:-en-US}
TEXT_SCALE=${NARRATIVE_VISUAL_TEXT_SCALE:-1.50}
rm -rf "$OUT" "$USER_DATA"
mkdir -p "$OUT" "$USER_DATA"

capture() {
  local mode=$1
  local width=$2
  local height=$3
  local label=$4
  local entry=${5:-1}
  local stage=${6:-s9}
  local output="$OUT/$label.png"
  local log="$OUT/$label.log"

  timeout 180s xvfb-run -a -s "-screen 0 ${width}x${height}x24 -ac +extension GLX +render -noreset" \
    env GODOT_BIN="$GODOT_BIN" PROTO_TD_TEST_ARTIFACT_DIR="$USER_DATA/$label" \
    GODOT_SILENCE_ROOT_WARNING=1 "$ROOT/tools/run_godot_isolated.sh" \
      --display-driver x11 --audio-driver Dummy \
      --rendering-method gl_compatibility --resolution "${width}x${height}" \
      res://test/narrative_canon_visual_harness.tscn -- \
      "--mode=$mode" "--out=$output" "--locale=$LOCALE" \
      "--entry=$entry" "--stage=$stage" "--text-scale=$TEXT_SCALE" >"$log" 2>&1

  grep -q "NARRATIVE_VISUAL_CAPTURE_OK mode=$mode path=$output" "$log"
  identify -format '%wx%h' "$output" | grep -qx "${width}x${height}"
  if rg -n -i 'SCRIPT ERROR|ERROR:|FATAL|CRASH|missing resource|renderer.*fail|failed to load' "$log"; then
    return 1
  fi
}

capture title 1280 720 landscape-title
capture results 1280 720 landscape-results
capture title 720 1280 portrait-title
capture results 720 1280 portrait-results
for mode in staging premium training valhalla; do
  capture "$mode" 1280 720 "landscape-$mode"
  capture "$mode" 720 1280 "portrait-$mode"
done
for stage in s9 s12 s16; do
  capture campaign 1280 720 "$stage-landscape-campaign" 1 "$stage"
  capture campaign 720 1280 "$stage-portrait-campaign" 1 "$stage"
done
for entry in 1 2 3 4; do
  capture archive 1280 720 "landscape-archive-$entry" "$entry"
  capture archive_audio 1280 720 "landscape-archive-audio-$entry" "$entry"
  capture archive 720 1280 "portrait-archive-$entry" "$entry"
  capture archive_audio 720 1280 "portrait-archive-audio-$entry" "$entry"
done

sha256sum "$OUT"/*.png >"$OUT/SHA256SUMS"
printf 'NARRATIVE_CANON_VISUALS_OK %s locale=%s text_scale=%s\n' "$OUT" "$LOCALE" "$TEXT_SCALE"
identify "$OUT"/*.png
