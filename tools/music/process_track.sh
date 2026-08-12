#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <input-audio> <output.ogg>" >&2
  exit 2
fi

input="$1"
output="$2"
fade_seconds="4"
target_i="-18"
target_lra="14"
target_tp="-1.5"

for tool in ffmpeg ffprobe jq bc; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "missing required tool: $tool" >&2
    exit 2
  }
done

test -s "$input" || {
  echo "input missing or empty: $input" >&2
  exit 2
}

mkdir -p "$(dirname "$output")"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

source_duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input")"
minimum_duration="$(printf '%s * 4\n' "$fade_seconds" | bc -l)"
if [[ "$(printf '%s <= %s\n' "$source_duration" "$minimum_duration" | bc -l)" -eq 1 ]]; then
	echo "source must exceed four crossfade windows: duration=$source_duration fade=$fade_seconds" >&2
	exit 2
fi

tail_window="$(printf '%s * 2\n' "$fade_seconds" | bc -l)"
tail_start="$(printf '%s - %s\n' "$source_duration" "$tail_window" | bc -l)"
middle_end="$tail_start"
middle="$work_dir/middle.wav"
tail="$work_dir/tail.wav"
head="$work_dir/head.wav"
seam="$work_dir/seam.wav"
concat_list="$work_dir/concat.txt"
looped="$work_dir/looped.wav"

# Rotate the source by one crossfade window. Keep an eight-second tail so its
# first four seconds remain intact while its final four seconds crossfade into
# the original first four seconds. The endpoint and start both meet at the
# original t=4 musical state.
ffmpeg -hide_banner -loglevel error -y -i "$input" \
	-af "atrim=start=${fade_seconds}:end=${middle_end},asetpts=PTS-STARTPTS,aresample=48000" \
	-c:a pcm_s24le -ar 48000 -ac 2 "$middle"

ffmpeg -hide_banner -loglevel error -y -i "$input" \
	-af "atrim=start=${tail_start}:end=${source_duration},asetpts=PTS-STARTPTS,aresample=48000" \
	-c:a pcm_s24le -ar 48000 -ac 2 "$tail"

ffmpeg -hide_banner -loglevel error -y -i "$input" \
	-af "atrim=start=0:end=${fade_seconds},asetpts=PTS-STARTPTS,aresample=48000" \
	-c:a pcm_s24le -ar 48000 -ac 2 "$head"

ffmpeg -hide_banner -loglevel error -y -i "$tail" -i "$head" \
	-filter_complex "[0:a][1:a]acrossfade=d=${fade_seconds}:c1=tri:c2=tri[out]" \
	-map '[out]' -c:a pcm_s24le -ar 48000 -ac 2 "$seam"

printf "file '%s'\nfile '%s'\n" "$middle" "$seam" > "$concat_list"
ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i "$concat_list" \
	-c:a copy "$looped"

analysis_log="$work_dir/loudnorm-analysis.log"
ffmpeg -hide_banner -nostats -i "$looped" \
  -af "loudnorm=I=${target_i}:LRA=${target_lra}:TP=${target_tp}:print_format=json" \
  -f null - > /dev/null 2> "$analysis_log"

analysis_json="$(sed -n '/^{/,/^}/p' "$analysis_log")"
test -n "$analysis_json" || {
  echo "loudnorm analysis JSON missing for $input" >&2
  cat "$analysis_log" >&2
  exit 2
}

input_i="$(jq -r '.input_i' <<< "$analysis_json")"
input_lra="$(jq -r '.input_lra' <<< "$analysis_json")"
input_tp="$(jq -r '.input_tp' <<< "$analysis_json")"
input_thresh="$(jq -r '.input_thresh' <<< "$analysis_json")"
target_offset="$(jq -r '.target_offset' <<< "$analysis_json")"

ffmpeg -hide_banner -loglevel error -y -i "$looped" \
  -af "loudnorm=I=${target_i}:LRA=${target_lra}:TP=${target_tp}:measured_I=${input_i}:measured_LRA=${input_lra}:measured_TP=${input_tp}:measured_thresh=${input_thresh}:offset=${target_offset}:linear=true:print_format=summary" \
  -c:a libvorbis -q:a 6 -ar 48000 -ac 2 "$output"

printf 'processed=%s\n' "$output"
printf 'source_duration=%s\n' "$source_duration"
printf 'loop_crossfade_seconds=%s\n' "$fade_seconds"
printf 'source_codec=%s\n' "$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$input")"
printf 'output_duration=%s\n' "$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$output")"
printf 'output_sha256=%s\n' "$(sha256sum "$output" | cut -d' ' -f1)"
