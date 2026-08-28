#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-godot}
OUT=${1:-/tmp/proto-td-battle-dialogue-visuals}
USER_DATA=${BATTLE_DIALOGUE_USER_DATA:-/tmp/proto-td-battle-dialogue-userdata}
LOCALE=${BATTLE_DIALOGUE_LOCALE:-en-US}
TEXT_SCALE=${BATTLE_DIALOGUE_TEXT_SCALE:-1.50}
STAGES=${BATTLE_DIALOGUE_STAGES:-"s1 s3 s7 s8"}
rm -rf "$OUT" "$USER_DATA"
mkdir -p "$OUT" "$USER_DATA"

capture() {
  local mode=$1
  local width=$2
  local height=$3
  local label=$4
  local stage=$5
  local output="$OUT/$label.png"
  local log="$OUT/$label.log"

  timeout 120s xvfb-run -a -s "-screen 0 ${width}x${height}x24 -ac +extension GLX +render -noreset" \
    env GODOT_BIN="$GODOT_BIN" PROTO_TD_TEST_ARTIFACT_DIR="$USER_DATA/$label" \
    GODOT_SILENCE_ROOT_WARNING=1 "$ROOT/tools/run_godot_isolated.sh" \
      --display-driver x11 --audio-driver Dummy \
      --rendering-method gl_compatibility --resolution "${width}x${height}" \
      res://test/battle_dialogue_visual_harness.tscn -- \
      "--mode=$mode" "--out=$output" "--locale=$LOCALE" \
      "--stage=$stage" "--text-scale=$TEXT_SCALE" >"$log" 2>&1

  grep -q "BATTLE_DIALOGUE_VISUAL_OK mode=$mode path=$output" "$log"
  identify -format '%wx%h' "$output" | grep -qx "${width}x${height}"
  if rg -n -i 'SCRIPT ERROR|ERROR:|FATAL|CRASH|missing resource|renderer.*fail|failed to load' "$log"; then
    return 1
  fi
}

for stage in $STAGES; do
  capture start 1280 720 "$stage-landscape-mission-start" "$stage"
  capture mid 1280 720 "$stage-landscape-mid-wave" "$stage"
  capture start 720 1280 "$stage-portrait-mission-start" "$stage"
  capture mid 720 1280 "$stage-portrait-mid-wave" "$stage"
done

sha256sum "$OUT"/*.png >"$OUT/SHA256SUMS"
printf 'BATTLE_DIALOGUE_VISUALS_OK %s locale=%s text_scale=%s stages=%s\n' "$OUT" "$LOCALE" "$TEXT_SCALE" "$STAGES"
identify "$OUT"/*.png
