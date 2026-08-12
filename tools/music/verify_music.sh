#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

for tool in ffmpeg ffprobe jq bc sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "[music-verify] missing required tool: $tool" >&2
    exit 2
  }
done

root="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$root"

expected_names='act_1_guild_threshold_bgm
act_1_guild_threshold_boss
act_2_twilight_grotto_bgm
act_2_twilight_grotto_boss
act_3_abyssal_vault_bgm
act_3_abyssal_vault_boss'

failures=0
actual_count="$(find assets/music -maxdepth 1 -type f -name '*.ogg' | wc -l | tr -d ' ')"
if [[ "$actual_count" -ne 6 ]]; then
  echo "[music-verify] FAIL expected 6 Ogg cues, found $actual_count" >&2
  failures=$((failures + 1))
fi

hashes_file="$(mktemp)"
trap 'rm -f "$hashes_file"' EXIT

while IFS= read -r name; do
  asset="assets/music/${name}.ogg"
  prompt="assets/music/prompts/${name}.txt"
  import_file="${asset}.import"
  cue_failures=0

  if [[ ! -s "$asset" ]]; then
    echo "[music-verify] FAIL $name missing or empty asset" >&2
    failures=$((failures + 1))
    continue
  fi
  if [[ ! -s "$prompt" ]]; then
    echo "[music-verify] FAIL $name missing or empty prompt" >&2
    failures=$((failures + 1))
    continue
  fi
  if ! grep -q 'Instrumental only, no vocals' "$prompt"; then
    echo "[music-verify] FAIL $name prompt does not pin instrumental-only output" >&2
    cue_failures=$((cue_failures + 1))
  fi
  if [[ ! -s "$import_file" ]] || ! grep -q '^loop=true$' "$import_file"; then
    echo "[music-verify] FAIL $name import is not loop-enabled" >&2
    cue_failures=$((cue_failures + 1))
  fi

  probe="$(ffprobe -v error -select_streams a:0 \
    -show_entries stream=codec_name,sample_rate,channels:format=duration \
    -of json "$asset")"
  codec="$(jq -r '.streams[0].codec_name' <<< "$probe")"
  sample_rate="$(jq -r '.streams[0].sample_rate' <<< "$probe")"
  channels="$(jq -r '.streams[0].channels' <<< "$probe")"
  duration="$(jq -r '.format.duration' <<< "$probe")"

  if [[ "$codec" != "vorbis" ]]; then
    echo "[music-verify] FAIL $name codec=$codec expected=vorbis" >&2
    cue_failures=$((cue_failures + 1))
  fi
  if [[ "$sample_rate" != "48000" ]]; then
    echo "[music-verify] FAIL $name sample_rate=$sample_rate expected=48000" >&2
    cue_failures=$((cue_failures + 1))
  fi
  if [[ "$channels" != "2" ]]; then
    echo "[music-verify] FAIL $name channels=$channels expected=2" >&2
    cue_failures=$((cue_failures + 1))
  fi
  if [[ "$(printf '%s < 160 || %s > 180\n' "$duration" "$duration" | bc -l)" -eq 1 ]]; then
    echo "[music-verify] FAIL $name duration=$duration expected=[160,180]" >&2
    cue_failures=$((cue_failures + 1))
  fi

  loudness_log="$(ffmpeg -nostdin -hide_banner -nostats -i "$asset" -af ebur128=peak=true -f null - 2>&1)"
  integrated="$(printf '%s\n' "$loudness_log" | awk '/Integrated loudness:/{found=1; next} found && /I:/{print $2; exit}')"
  true_peak="$(printf '%s\n' "$loudness_log" | awk '/True peak:/{found=1; next} found && /Peak:/{print $2; exit}')"
  if [[ -z "$integrated" ]] || [[ -z "$true_peak" ]]; then
    echo "[music-verify] FAIL $name loudness metrics missing" >&2
    cue_failures=$((cue_failures + 1))
  else
    if [[ "$(printf '%s < -18.3 || %s > -17.7\n' "$integrated" "$integrated" | bc -l)" -eq 1 ]]; then
      echo "[music-verify] FAIL $name integrated=${integrated}LUFS expected=[-18.3,-17.7]" >&2
      cue_failures=$((cue_failures + 1))
    fi
    if [[ "$(printf '%s > -1.5\n' "$true_peak" | bc -l)" -eq 1 ]]; then
      echo "[music-verify] FAIL $name true_peak=${true_peak}dBFS expected<=-1.5" >&2
      cue_failures=$((cue_failures + 1))
    fi
  fi

  if ffmpeg -nostdin -hide_banner -nostats -i "$asset" -af silencedetect=noise=-50dB:d=2 \
      -f null - 2>&1 | grep -q 'silence_duration'; then
    echo "[music-verify] FAIL $name contains >=2s digital silence below -50dB" >&2
    cue_failures=$((cue_failures + 1))
  fi

  hash="$(sha256sum "$asset" | cut -d' ' -f1)"
  printf '%s\n' "$hash" >> "$hashes_file"
  failures=$((failures + cue_failures))
  if [[ "$cue_failures" -eq 0 ]]; then
    echo "[music-verify] PASS $name duration=${duration}s loudness=${integrated}LUFS peak=${true_peak}dBFS sha256=$hash"
  fi
done <<< "$expected_names"

unique_hashes="$(sort -u "$hashes_file" | wc -l | tr -d ' ')"
if [[ "$unique_hashes" -ne 6 ]]; then
  echo "[music-verify] FAIL unique content hashes=$unique_hashes expected=6" >&2
  failures=$((failures + 1))
fi

if [[ "$failures" -ne 0 ]]; then
  echo "[music-verify] RED failures=$failures" >&2
  exit 1
fi

echo "[music-verify] ALL GREEN cues=6 unique_hashes=6"
