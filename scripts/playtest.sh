#!/bin/bash
# L5 bot playtest runner.
#   playtest.sh <bot> [--seed N] [--ticks N] [--render] [--out DIR]
# Default lane: headless + --fixed-fps 60 -> telemetry only, seconds of wall
# clock. --render lane: windowed Movie Maker -> telemetry + deterministic PNG
# frames + wav (exercised from Phase 9 on). On Linux the headless lane runs
# under xvfb-run -a unchanged.
set -u
GODOT="${GODOT:-$HOME/bin/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOT="${1:?usage: playtest.sh <bot> [--seed N] [--ticks N] [--render] [--out DIR]}"
shift
SEED=42
TICKS=3600
RENDER=0
OUT="$ROOT/artifacts"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --seed) SEED="$2"; shift 2 ;;
    --ticks) TICKS="$2"; shift 2 ;;
    --render) RENDER=1; shift ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
mkdir -p "$OUT"

# Bots exercise real production save paths, so their Godot user data must never
# resolve to a developer/player profile. Generic inherited XDG variables are
# not proof of isolation, so every invocation gets a fresh disposable root.
PLAYTEST_USER_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/prototype-td-playtest.XXXXXX")"
export XDG_DATA_HOME="$PLAYTEST_USER_ROOT/data"
export XDG_CONFIG_HOME="$PLAYTEST_USER_ROOT/config"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
cleanup_user_root() {
	rm -rf "$PLAYTEST_USER_ROOT"
}
trap cleanup_user_root EXIT

# plain string (not array): bash 3.2 + set -u rejects empty-array expansion
RUNNER=""
if [[ "$(uname)" == "Linux" ]] && command -v xvfb-run >/dev/null; then
  RUNNER="xvfb-run -a"
fi

# shell timeout = generous outer watchdog over the runner's own --max-ticks
BUDGET=$(( TICKS / 10 + 120 ))

if [[ "$RENDER" == "1" ]]; then
  mkdir -p "$OUT/frames"
  $RUNNER timeout "$BUDGET" "$GODOT" --path "$ROOT" --resolution 1280x720 \
    --write-movie "$OUT/frames/f.png" --fixed-fps 30 -- \
    --playtest="$BOT" --seed="$SEED" --max-ticks="$TICKS"
else
  $RUNNER timeout "$BUDGET" "$GODOT" --headless --fixed-fps 60 --path "$ROOT" -- \
    --playtest="$BOT" --seed="$SEED" --max-ticks="$TICKS"
fi
CODE=$?
if [[ $CODE -eq 124 ]]; then
  echo "[PLAYTEST] shell timeout after ${BUDGET}s" >&2
fi
exit $CODE
