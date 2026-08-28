#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-godot}
OUT_DIR=${1:-"$ROOT/build/title-onboarding-regressions"}
USER_DATA=${TITLE_ONBOARDING_USER_DATA:-/tmp/proto-td-title-onboarding-userdata}

rm -rf "$OUT_DIR" "$USER_DATA"
mkdir -p "$OUT_DIR" "$USER_DATA"

capture() {
  local label=$1
  local width=$2
  local height=$3
  local mode=$4
  local locale=${5:-en-US}
  local output="$OUT_DIR/$label.png"
  local log="$OUT_DIR/$label.log"

  timeout 180s xvfb-run -a -s "-screen 0 ${width}x${height}x24 -ac +extension GLX +render -noreset" \
    env XDG_DATA_HOME="$USER_DATA/$label" GODOT_SILENCE_ROOT_WARNING=1 \
    "$GODOT_BIN" --path "$ROOT" --display-driver x11 --audio-driver Dummy \
      --rendering-method gl_compatibility --resolution "${width}x${height}" \
      res://test/title_onboarding_visual_harness.tscn -- \
      "--output=$output" "--mode=$mode" "--locale=$locale" >"$log" 2>&1

  grep -q "TITLE_ONBOARDING_VISUAL_OK|$output|${width}x${height}|mode=$mode|locale=$locale" "$log"
  identify -format '%wx%h' "$output" | grep -qx "${width}x${height}"
  if rg -n -i 'SCRIPT ERROR|ERROR:|FATAL|CRASH|missing resource|renderer.*fail|failed to load' "$log"; then
    return 1
  fi
}

capture tutorial-mission-landscape 1280 720 mission
capture tutorial-resonance-landscape 1280 720 resonance
capture tutorial-mission-portrait 720 1280 mission
capture tutorial-resonance-portrait 720 1280 resonance
capture operation-focus-landscape 1280 720 operation_focus
capture command-settings-button-landscape 1280 720 command_settings_button
capture command-settings-modal-landscape 1280 720 command_settings_modal
capture command-settings-button-portrait 720 1280 command_settings_button
capture command-settings-button-narrow 390 844 command_settings_button
capture next-operation-mission-control-landscape 1280 720 mission_control

sha256sum "$OUT_DIR"/*.png >"$OUT_DIR/SHA256SUMS"
printf '%s\n' 'TITLE_ONBOARDING_SCREENSHOT_REGRESSIONS_OK'
identify "$OUT_DIR"/*.png
