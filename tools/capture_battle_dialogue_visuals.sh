#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-godot}
OUT=${1:-/tmp/proto-td-battle-dialogue-visuals}
USER_DATA=${BATTLE_DIALOGUE_USER_DATA:-/tmp/proto-td-battle-dialogue-userdata}
rm -rf "$OUT" "$USER_DATA"
mkdir -p "$OUT" "$USER_DATA"

capture() {
  local mode=$1
  local width=$2
  local height=$3
  local label=$4
  local output="$OUT/$label.png"
  local log="$OUT/$label.log"

  timeout 120s xvfb-run -a -s "-screen 0 ${width}x${height}x24 -ac +extension GLX +render -noreset" \
    env XDG_DATA_HOME="$USER_DATA/$label" GODOT_SILENCE_ROOT_WARNING=1 \
    "$GODOT_BIN" --path "$ROOT" --display-driver x11 --audio-driver Dummy \
      --rendering-method gl_compatibility --resolution "${width}x${height}" \
      res://test/battle_dialogue_visual_harness.tscn -- \
      "--mode=$mode" "--out=$output" >"$log" 2>&1

  grep -q "BATTLE_DIALOGUE_VISUAL_OK mode=$mode path=$output" "$log"
  identify -format '%wx%h' "$output" | grep -qx "${width}x${height}"
  if rg -n -i 'SCRIPT ERROR|ERROR:|FATAL|CRASH|missing resource|renderer.*fail|failed to load' "$log"; then
    return 1
  fi
}

capture start 1280 720 landscape-mission-start
capture mid 1280 720 landscape-mid-wave
capture start 720 1280 portrait-mission-start
capture mid 720 1280 portrait-mid-wave

sha256sum "$OUT"/*.png >"$OUT/SHA256SUMS"
printf 'BATTLE_DIALOGUE_VISUALS_OK %s\n' "$OUT"
identify "$OUT"/*.png
