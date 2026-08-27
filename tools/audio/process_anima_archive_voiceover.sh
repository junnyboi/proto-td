#!/usr/bin/env bash
set -euo pipefail

# Reproducibly normalize the approved Anima Archive source WAVs and encode the
# repository-owned runtime streams. Source WAVs remain outside the repository.
# Usage: process_anima_archive_voiceover.sh [source_root] [output_root]

SOURCE_ROOT="${1:-/home/ubuntu/anima-archive-tts}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_ROOT="${2:-${REPO_ROOT}/assets/audio/narrative/anima-archive}"
TARGET_I="-16"
TARGET_TP="-2.3"
TARGET_LRA="11"
LOCALES=(en-US zh-CN)
IDS=(stewardship choir equation garden)

for command_name in ffmpeg jq; do
  command -v "${command_name}" >/dev/null 2>&1 || {
    printf 'Required command not found: %s\n' "${command_name}" >&2
    exit 1
  }
done

for locale in "${LOCALES[@]}"; do
  mkdir -p "${OUTPUT_ROOT}/${locale}"
  for stable_id in "${IDS[@]}"; do
    input="${SOURCE_ROOT}/${locale}/${stable_id}.wav"
    output="${OUTPUT_ROOT}/${locale}/${stable_id}.ogg"
    [[ -f "${input}" ]] || {
      printf 'Missing approved source: %s\n' "${input}" >&2
      exit 1
    }

    analysis="$({
      ffmpeg -nostdin -hide_banner -nostats -i "${input}" \
        -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:print_format=json" \
        -f null -
    } 2>&1)"
    measurements="$(sed -n '/^{/,/^}/p' <<<"${analysis}")"
    [[ -n "${measurements}" ]] || {
      printf 'Loudness analysis failed: %s\n' "${input}" >&2
      exit 1
    }

    measured_i="$(jq -r '.input_i' <<<"${measurements}")"
    measured_tp="$(jq -r '.input_tp' <<<"${measurements}")"
    measured_lra="$(jq -r '.input_lra' <<<"${measurements}")"
    measured_thresh="$(jq -r '.input_thresh' <<<"${measurements}")"
    offset="$(jq -r '.target_offset' <<<"${measurements}")"

    ffmpeg -nostdin -hide_banner -loglevel error -y -i "${input}" \
      -map_metadata -1 -vn -ac 1 -ar 48000 \
      -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:measured_I=${measured_i}:measured_TP=${measured_tp}:measured_LRA=${measured_lra}:measured_thresh=${measured_thresh}:offset=${offset}:linear=false:print_format=summary" \
      -c:a libvorbis -q:a 5 "${output}"
    printf 'Encoded %s/%s -> %s\n' "${locale}" "${stable_id}" "${output}"
  done
done
