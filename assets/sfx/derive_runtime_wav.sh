#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="$root/source-batch-manifest.json"

for tool in ffmpeg ffprobe jq sha256sum; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool" >&2; exit 2; }
done

while IFS=$'\t' read -r cue lane expected_source_hash; do
  source="$root/sources/$cue.wav.source"
  output="$root/$lane/$cue.wav"
  temp="$output.tmp.wav"
  test -f "$source"
  actual_source_hash="$(sha256sum "$source" | cut -d' ' -f1)"
  test "$actual_source_hash" = "$expected_source_hash"
  rm -f "$temp"
  ffmpeg -v error -nostdin -y -f wav -i "$source" -map 0:a:0 -ar 48000 -ac 2 -c:a pcm_s16le "$temp"
  readarray -t fields < <(
    ffprobe -v error -select_streams a:0 \
      -show_entries stream=codec_name,sample_rate,channels,bits_per_sample \
      -of default=noprint_wrappers=1:nokey=1 "$temp"
  )
  test "${fields[0]}" = "pcm_s16le"
  test "${fields[1]}" = "48000"
  test "${fields[2]}" = "2"
  test "${fields[3]}" = "16"
  mv "$temp" "$output"
done < <(jq -r '.records[] | [.cue, .lane, .deliverable_sha256] | @tsv' "$manifest")

printf 'RUNTIME_DERIVATION=PASS cues=10 codec=pcm_s16le rate=48000 channels=2\n'
