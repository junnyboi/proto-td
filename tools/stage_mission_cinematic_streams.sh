#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${MISSION_CINEMATIC_SOURCE:-${ROOT}/assets/cinematics/missions}"
OUT="${1:-${ROOT}/build/web/mission-cinematics}"
VIDEO_DIR="${SOURCE}/video"
AUDIO_DIR="${SOURCE}/audio"
POSTER_DIR="${SOURCE}/posters"
FFPROBE="${FFPROBE:-ffprobe}"
POSTER_POLICY="${MISSION_CINEMATIC_POSTER_POLICY:-core}"

command -v "$FFPROBE" >/dev/null
[[ "$POSTER_POLICY" == "core" || "$POSTER_POLICY" == "stage" ]]
mapfile -t videos < <(find "$VIDEO_DIR" -maxdepth 1 -type f -name 's*.ogv' -printf '%f\n' 2>/dev/null | sort -V)
[[ ${#videos[@]} -eq 16 ]]
mkdir -p "$OUT/video"
rm -f "$OUT/video"/*.ogv
if [[ "$POSTER_POLICY" == "stage" ]]; then
  mkdir -p "$OUT/posters"
  rm -f "$OUT/posters"/*.webp
fi

TSV="$OUT/manifest.tsv"
JSON_ROWS="$OUT/.manifest.rows"
printf 'stage_id\tvideo_file\tvideo_bytes\tvideo_sha256\tduration_seconds\taudio_file\taudio_bytes\taudio_sha256\tposter_policy\n' > "$TSV"
: > "$JSON_ROWS"

for index in $(seq 1 16); do
  stage="s${index}"
  video="$VIDEO_DIR/${stage}.ogv"
  audio="$AUDIO_DIR/${stage}.ogg"
  poster="$POSTER_DIR/${stage}.webp"
  [[ -f "$video" ]]
  [[ "$(basename "$video")" == "${stage}.ogv" ]]
  [[ -f "$poster" ]]
  duration="$($FFPROBE -v error -show_entries format=duration -of default=nk=1:nw=1 "$video")"
  awk -v duration="$duration" 'BEGIN { exit !(duration > 0 && duration <= 8.05) }'
  video_bytes="$(stat -c %s "$video")"
  video_sha="$(sha256sum "$video" | cut -d' ' -f1)"
  audio_file=""
  audio_bytes=0
  audio_sha=""
  if [[ -f "$audio" ]]; then
    audio_duration="$($FFPROBE -v error -show_entries format=duration -of default=nk=1:nw=1 "$audio")"
    awk -v duration="$audio_duration" 'BEGIN { exit !(duration > 0 && duration <= 8.05) }'
    audio_file="${stage}.ogg"
    audio_bytes="$(stat -c %s "$audio")"
    audio_sha="$(sha256sum "$audio" | cut -d' ' -f1)"
    mkdir -p "$OUT/audio"
    cp -f "$audio" "$OUT/audio/${stage}.ogg"
  fi
  cp -f "$video" "$OUT/video/${stage}.ogv"
  if [[ "$POSTER_POLICY" == "stage" ]]; then
    cp -f "$poster" "$OUT/posters/${stage}.webp"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$stage" "${stage}.ogv" "$video_bytes" "$video_sha" "$duration" \
    "$audio_file" "$audio_bytes" "$audio_sha" "$POSTER_POLICY" >> "$TSV"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$stage" "$video_bytes" "$video_sha" "$duration" "$audio_file" "$audio_bytes" "$audio_sha" "$POSTER_POLICY" >> "$JSON_ROWS"
done

python3 - "$JSON_ROWS" "$OUT/manifest.json" <<'PY'
import json
import sys
from pathlib import Path

rows = []
for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    stage, video_bytes, video_sha, duration, audio_file, audio_bytes, audio_sha, poster_policy = line.split("\t")
    rows.append({
        "stage_id": stage,
        "video": {"file": f"{stage}.ogv", "bytes": int(video_bytes), "sha256": video_sha, "duration_seconds": float(duration)},
        "audio": {"file": audio_file, "bytes": int(audio_bytes), "sha256": audio_sha} if audio_file else None,
        "poster_policy": poster_policy,
    })
Path(sys.argv[2]).write_text(json.dumps({"schema_version": 1, "stages": rows}, indent=2) + "\n", encoding="utf-8")
PY
rm -f "$JSON_ROWS"
printf 'Staged 16 verified mission cinematic streams in %s\n' "$OUT"
