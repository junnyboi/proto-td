#!/bin/bash
# L5 bot playtest runner.
#   playtest.sh <bot> [--seed N] [--ticks N]
# Supported lane: headless + --fixed-fps 60 -> telemetry only, seconds of wall
# clock. Render evidence is owned by scripts/verify.sh --full: seeded windowed
# scenarios capture bounded viewport PNGs and run their pixel probes under Xvfb.
set -u
GODOT="${GODOT:-$HOME/bin/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOT="${1:?usage: playtest.sh <bot> [--seed N] [--ticks N]}"
shift
SEED=42
TICKS=3600
while [[ $# -gt 0 ]]; do
  case "$1" in
    --seed) SEED="$2"; shift 2 ;;
    --ticks) TICKS="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
mkdir -p "$ROOT/artifacts"

# plain string (not array): bash 3.2 + set -u rejects empty-array expansion
RUNNER=""
if [[ "$(uname)" == "Linux" ]] && command -v xvfb-run >/dev/null; then
  RUNNER="xvfb-run -a"
fi

# shell timeout = generous outer watchdog over the runner's own --max-ticks
BUDGET=$(( TICKS / 10 + 120 ))

$RUNNER timeout "$BUDGET" "$GODOT" --headless --fixed-fps 60 --path "$ROOT" -- \
  --playtest="$BOT" --seed="$SEED" --max-ticks="$TICKS"
CODE=$?
if [[ $CODE -eq 124 ]]; then
  echo "[PLAYTEST] shell timeout after ${BUDGET}s" >&2
fi
exit $CODE
