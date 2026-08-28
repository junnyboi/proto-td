#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-godot}
OUT_DIR=${1:-"$ROOT/build/title-responsive-regressions"}
USER_DATA=${TITLE_RESPONSIVE_USER_DATA:-/tmp/proto-td-title-responsive-userdata}

rm -rf "$OUT_DIR" "$USER_DATA"
mkdir -p "$OUT_DIR" "$USER_DATA"

capture() {
  local label=$1
	local width=$2
	local height=$3
	local settings=$4
	local settings_focus=${5:-}
  local output="$OUT_DIR/$label.png"
  local log="$OUT_DIR/$label.log"

	timeout 180 xvfb-run -a -s "-screen 0 ${width}x${height}x24 -ac +extension GLX +render -noreset" \
    env GODOT_BIN="$GODOT_BIN" PROTO_TD_TEST_ARTIFACT_DIR="$USER_DATA/$label" \
    GODOT_SILENCE_ROOT_WARNING=1 "$ROOT/tools/run_godot_isolated.sh" \
      --display-driver x11 --audio-driver Dummy \
      --rendering-method gl_compatibility --resolution "${width}x${height}" \
	      res://test/title_responsive_visual_harness.tscn -- \
	      "--output=$output" "--settings=$settings" \
	      "--settings-focus=$settings_focus" >"$log" 2>&1

  grep -q "TITLE_RESPONSIVE_VISUAL_OK|$output|${width}x${height}|settings=$settings" "$log"
  identify -format '%wx%h' "$output" | grep -qx "${width}x${height}"
  if rg -n -i 'SCRIPT ERROR|ERROR:|FATAL|CRASH|missing resource|renderer.*fail|failed to load' "$log"; then
    return 1
  fi
}

capture ultrawide-title 2560 1080 false
capture ultrawide-settings 2560 1080 true
capture managed-tall-landscape-title 1280 1100 false
capture short-landscape-title 1024 576 false
capture short-landscape-settings 1024 576 true
capture portrait-title 720 1280 false
capture portrait-settings-network 720 1280 true background-downloads

sha256sum "$OUT_DIR"/*.png >"$OUT_DIR/SHA256SUMS"
printf '%s\n' 'TITLE_RESPONSIVE_SCREENSHOT_REGRESSIONS_OK'
identify "$OUT_DIR"/*.png
