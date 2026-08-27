#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SOURCE="$TMP/source"
OUT="$TMP/out"
mkdir -p "$SOURCE/video" "$SOURCE/audio" "$SOURCE/posters"
FIXTURE="$ROOT/assets/cinematics/gacha/video/lunaris-vessel-landscape.ogv"
[[ -f "$FIXTURE" ]]
for index in $(seq 1 16); do
  cp "$FIXTURE" "$SOURCE/video/s${index}.ogv"
  : > "$SOURCE/posters/s${index}.webp"
done
cp "$ROOT/assets/cinematics/gacha/audio/lunaris-vessel-cinematic.ogg" "$SOURCE/audio/s1.ogg"
MISSION_CINEMATIC_SOURCE="$SOURCE" "$ROOT/tools/stage_mission_cinematic_streams.sh" "$OUT"
[[ "$(find "$OUT/video" -maxdepth 1 -type f -name 's*.ogv' | wc -l)" -eq 16 ]]
[[ "$(awk 'END { print NR }' "$OUT/manifest.tsv")" -eq 17 ]]
[[ "$(jq '.stages | length' "$OUT/manifest.json")" -eq 16 ]]
[[ "$(jq -r '.stages[0].audio.file' "$OUT/manifest.json")" == "s1.ogg" ]]
[[ "$(jq -r '.stages[1].audio' "$OUT/manifest.json")" == "null" ]]
rm "$SOURCE/video/s16.ogv"
if MISSION_CINEMATIC_SOURCE="$SOURCE" "$ROOT/tools/stage_mission_cinematic_streams.sh" "$TMP/missing" >/dev/null 2>&1; then
  echo "missing mission carrier was accepted" >&2
  exit 1
fi
cp "$FIXTURE" "$SOURCE/video/s16.ogv"
ffmpeg -v error -f lavfi -i color=c=black:s=16x16:d=8.2 -c:v libtheora -an -y "$SOURCE/video/s16.ogv"
if MISSION_CINEMATIC_SOURCE="$SOURCE" "$ROOT/tools/stage_mission_cinematic_streams.sh" "$TMP/long" >/dev/null 2>&1; then
  echo "overlong mission carrier was accepted" >&2
  exit 1
fi
printf 'MISSION_CINEMATIC_STAGING_TEST_OK\n'
