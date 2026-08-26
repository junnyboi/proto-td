#!/usr/bin/env bash
set -euo pipefail

prod="${PRODUCTION_ROOT:-/home/ubuntu/projects/proto-td-9a1e4085/audio-production-slow-field-blizzard}"
repo="${REPOSITORY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
out="$repo/assets/sfx/combat"
mkdir -p "$out"

master_cue() {
  local input="$1" offset="$2" duration="$3" target_lufs="$4" true_peak="$5" fade_out="$6" output="$7"
  local fade_start
  fade_start=$(printf '%s-%s\n' "$duration" "$fade_out" | bc)
  ffmpeg -hide_banner -loglevel error -y -ss "$offset" -t "$duration" -i "$input" -vn \
    -af "aresample=48000,highpass=f=45,lowpass=f=15500,loudnorm=I=${target_lufs}:LRA=7:TP=${true_peak},afade=t=in:st=0:d=0.02,afade=t=out:st=${fade_start}:d=${fade_out}" \
    -ar 48000 -ac 2 -c:a pcm_s16le "$output"
}

master_cue \
  "$prod/slow-field-cast-carrier.mp4" 0.0 2.90 -18 -2.0 0.25 \
  "$out/slow_field_cast.wav"
master_cue \
  "$prod/slow-field-expire-carrier.mp4" 0.45 2.95 -21 -3.0 0.35 \
  "$out/slow_field_expire.wav"

printf '%s\n' 'Slow Field runtime SFX derivatives created:'
for file in "$out/slow_field_cast.wav" "$out/slow_field_expire.wav"; do
  ffprobe -v error -show_entries format=duration,size:stream=codec_name,sample_rate,channels \
    -of default=noprint_wrappers=1 "$file"
  sha256sum "$file"
done
