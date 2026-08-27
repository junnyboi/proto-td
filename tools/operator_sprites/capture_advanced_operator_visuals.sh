#!/usr/bin/env bash
set -euo pipefail

REPOSITORY="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
OUTPUT="${2:-/tmp/proto-td-advanced-operator-visuals}"
mkdir -p "$OUTPUT"
classes=(
  defender gunner mage_apprentice shock_trooper swordmaster immovable
  sniper sorcerer witch_doctor banner_guard sword_saint
)
for class_id in "${classes[@]}"; do
	  xvfb-run -a -s '-screen 0 1920x1080x24' env \
	    GODOT_SILENCE_ROOT_WARNING=1 \
	    godot --path "$REPOSITORY" --audio-driver Dummy \
    --script test/advanced_operator_visual_harness.gd \
    -- --class "$class_id" --output "$OUTPUT/${class_id}.png" \
    > "$OUTPUT/${class_id}.log" 2>&1
  grep -q 'ADVANCED_OPERATOR_VISUAL_CAPTURE_OK' "$OUTPUT/${class_id}.log"
done
printf 'ADVANCED_OPERATOR_VISUAL_MATRIX_OK output=%s classes=%d\n' "$OUTPUT" "${#classes[@]}"
