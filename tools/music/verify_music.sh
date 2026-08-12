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

provenance="assets/music/provenance.json"
expected_names='act_1_guild_threshold_bgm
act_1_guild_threshold_boss
act_2_twilight_grotto_bgm
act_2_twilight_grotto_boss
act_3_abyssal_vault_bgm
act_3_abyssal_vault_boss'
failures=0
asset_hashes_file="$(mktemp)"
source_hashes_file="$(mktemp)"
trap 'rm -f "$asset_hashes_file" "$source_hashes_file"' EXIT

fail() {
  echo "[music-verify] FAIL $*" >&2
  failures=$((failures + 1))
}

res_path() {
  printf '%s\n' "${1#res://}"
}

within() {
  local measured="$1"
  local expected="$2"
  local tolerance="$3"
  [[ "$(printf 'delta=(%s)-(%s); if (delta < 0) delta=-delta; delta <= %s\n' \
    "$measured" "$expected" "$tolerance" | bc -l)" -eq 1 ]]
}

if [[ ! -s "$provenance" ]]; then
  echo "[music-verify] FAIL provenance missing or empty" >&2
  exit 1
fi
jq empty "$provenance"

actual_count="$(find assets/music -maxdepth 1 -type f -name '*.ogg' | wc -l | tr -d ' ')"
[[ "$actual_count" -eq 6 ]] || fail "expected 6 Ogg cues, found $actual_count"
track_count="$(jq '.tracks | length' "$provenance")"
unique_ids="$(jq -r '.tracks[].id' "$provenance" | sort -u | wc -l | tr -d ' ')"
[[ "$track_count" -eq 6 ]] || fail "provenance tracks=$track_count expected=6"
[[ "$unique_ids" -eq 6 ]] || fail "provenance unique_ids=$unique_ids expected=6"
jq -e '
  .human_feedback.classification == "accepted"
  and .human_feedback.final_acceptance_complete == true
  and (.human_feedback.review_uri | startswith("user://conversation/"))
' "$provenance" >/dev/null || fail "human acceptance record is incomplete"
jq -e '
  .runtime_integration.status == "approved_for_runtime"
  and .runtime_integration.player_count == 1
  and .runtime_integration.layering == false
  and .runtime_integration.same_cue_restart == false
' "$provenance" >/dev/null || fail "single-player runtime contract is incomplete"

while IFS= read -r name; do
  case "$name" in
    act_1_guild_threshold_bgm) id="act_1_bgm"; expected_act=1; expected_role="bgm" ;;
    act_1_guild_threshold_boss) id="act_1_boss"; expected_act=1; expected_role="boss" ;;
    act_2_twilight_grotto_bgm) id="act_2_bgm"; expected_act=2; expected_role="bgm" ;;
    act_2_twilight_grotto_boss) id="act_2_boss"; expected_act=2; expected_role="boss" ;;
    act_3_abyssal_vault_bgm) id="act_3_bgm"; expected_act=3; expected_role="bgm" ;;
    act_3_abyssal_vault_boss) id="act_3_boss"; expected_act=3; expected_role="boss" ;;
    *) fail "unexpected cue name $name"; continue ;;
  esac

  matches="$(jq --arg id "$id" '[.tracks[] | select(.id == $id)] | length' "$provenance")"
  if [[ "$matches" -ne 1 ]]; then
    fail "$id provenance matches=$matches expected=1"
    continue
  fi
  track="$(jq -c --arg id "$id" '.tracks[] | select(.id == $id)' "$provenance")"
  asset="$(res_path "$(jq -r '.asset_path' <<< "$track")")"
  prompt="$(res_path "$(jq -r '.prompt_path' <<< "$track")")"
  source="$(res_path "$(jq -r '.source_path' <<< "$track")")"
  transcription="$(res_path "$(jq -r '.transcription_path' <<< "$track")")"
  import_file="${asset}.import"
  cue_failures_before="$failures"

  expected_asset="assets/music/${name}.ogg"
  expected_prompt="assets/music/prompts/${name}.txt"
  expected_source="assets/music/sources/${name}.mp3.source"
  expected_transcription="assets/music/evidence/transcriptions/${name}.json"
  [[ "$asset" == "$expected_asset" ]] || fail "$id asset path=$asset expected=$expected_asset"
  [[ "$prompt" == "$expected_prompt" ]] || fail "$id prompt path=$prompt expected=$expected_prompt"
  [[ "$source" == "$expected_source" ]] || fail "$id source path=$source expected=$expected_source"
  [[ "$transcription" == "$expected_transcription" ]] || \
    fail "$id transcription path=$transcription expected=$expected_transcription"

  for required in "$asset" "$prompt" "$source" "$transcription" "$import_file"; do
    [[ -s "$required" ]] || fail "$id missing or empty $required"
  done
  if [[ ! -s "$asset" || ! -s "$prompt" || ! -s "$source" || ! -s "$transcription" ]]; then
    continue
  fi

	grep -q 'Instrumental only, no vocals' "$prompt" || fail "$id prompt does not ban vocals"
	grep -q '^loop=true$' "$import_file" || fail "$id import is not loop-enabled"
	jq -e '
	  .placeholder == false
	  and .human_status == "accepted"
	  and (.human_review_uri | startswith("user://conversation/"))
	' <<< "$track" >/dev/null || fail "$id accepted human state is incomplete"
  [[ "$(jq -r '.act' <<< "$track")" == "$expected_act" ]] || fail "$id act mismatch"
  [[ "$(jq -r '.role' <<< "$track")" == "$expected_role" ]] || fail "$id role mismatch"

  asset_hash="$(sha256sum "$asset" | cut -d' ' -f1)"
  prompt_hash="$(sha256sum "$prompt" | cut -d' ' -f1)"
  source_hash="$(sha256sum "$source" | cut -d' ' -f1)"
  transcription_hash="$(sha256sum "$transcription" | cut -d' ' -f1)"
  [[ "$asset_hash" == "$(jq -r '.asset_sha256' <<< "$track")" ]] || fail "$id asset hash mismatch"
  [[ "$prompt_hash" == "$(jq -r '.prompt_sha256' <<< "$track")" ]] || fail "$id prompt hash mismatch"
  [[ "$source_hash" == "$(jq -r '.source_sha256' <<< "$track")" ]] || fail "$id source hash mismatch"
  [[ "$transcription_hash" == "$(jq -r '.transcription_sha256' <<< "$track")" ]] || \
    fail "$id transcription hash mismatch"
  printf '%s\n' "$asset_hash" >> "$asset_hashes_file"
  printf '%s\n' "$source_hash" >> "$source_hashes_file"

  asset_probe="$(ffprobe -v error -select_streams a:0 \
    -show_entries stream=codec_name,sample_rate,channels:format=duration -of json "$asset")"
  codec="$(jq -r '.streams[0].codec_name' <<< "$asset_probe")"
  sample_rate="$(jq -r '.streams[0].sample_rate' <<< "$asset_probe")"
  channels="$(jq -r '.streams[0].channels' <<< "$asset_probe")"
  duration="$(jq -r '.format.duration' <<< "$asset_probe")"
  [[ "$codec" == "vorbis" ]] || fail "$id codec=$codec expected=vorbis"
  [[ "$sample_rate" == "48000" ]] || fail "$id sample_rate=$sample_rate expected=48000"
  [[ "$channels" == "2" ]] || fail "$id channels=$channels expected=2"
  [[ "$(printf '%s >= 160 && %s <= 180\n' "$duration" "$duration" | bc -l)" -eq 1 ]] || \
    fail "$id duration=$duration expected=[160,180]"
  within "$duration" "$(jq -r '.duration_seconds' <<< "$track")" 0.05 || \
    fail "$id duration does not match provenance"

  source_probe="$(ffprobe -v error -select_streams a:0 \
    -show_entries stream=codec_name,sample_rate,channels:format=duration -of json "$source")"
  source_codec="$(jq -r '.streams[0].codec_name' <<< "$source_probe")"
  source_rate="$(jq -r '.streams[0].sample_rate' <<< "$source_probe")"
  source_channels="$(jq -r '.streams[0].channels' <<< "$source_probe")"
  source_duration="$(jq -r '.format.duration' <<< "$source_probe")"
  [[ "$source_codec" == "mp3" ]] || fail "$id source codec=$source_codec expected=mp3"
  [[ "$source_rate" == "44100" ]] || fail "$id source rate=$source_rate expected=44100"
  [[ "$source_channels" == "2" ]] || fail "$id source channels=$source_channels expected=2"
  within "$source_duration" "$(jq -r '.source_duration_seconds' <<< "$track")" 0.05 || \
    fail "$id source duration does not match provenance"

  jq empty "$transcription"
  [[ "$(jq '.segments | length' "$transcription")" -eq 0 ]] || fail "$id transcription has segments"
  [[ -z "$(jq -r '.full_text' "$transcription")" ]] || fail "$id transcription has text"
  within "$(jq -r '.duration' "$transcription")" "$source_duration" 0.1 || \
    fail "$id transcription duration does not match source"

  loudness_log="$(ffmpeg -nostdin -hide_banner -nostats -i "$asset" -af ebur128=peak=true -f null - 2>&1)"
  integrated="$(printf '%s\n' "$loudness_log" | awk '/Integrated loudness:/{found=1; next} found && /I:/{print $2; exit}')"
  true_peak="$(printf '%s\n' "$loudness_log" | awk '/True peak:/{found=1; next} found && /Peak:/{print $2; exit}')"
  [[ -n "$integrated" && -n "$true_peak" ]] || fail "$id loudness metrics missing"
  [[ "$(printf '%s >= -18.3 && %s <= -17.7\n' "$integrated" "$integrated" | bc -l)" -eq 1 ]] || \
    fail "$id integrated=${integrated}LUFS expected=[-18.3,-17.7]"
  [[ "$(printf '%s <= -1.5\n' "$true_peak" | bc -l)" -eq 1 ]] || \
    fail "$id true_peak=${true_peak}dBFS expected<=-1.5"
  within "$integrated" "$(jq -r '.integrated_loudness_lufs' <<< "$track")" 0.15 || \
    fail "$id loudness does not match provenance"
  within "$true_peak" "$(jq -r '.true_peak_dbfs' <<< "$track")" 0.15 || \
    fail "$id true peak does not match provenance"

  if ffmpeg -nostdin -hide_banner -nostats -i "$asset" -af silencedetect=noise=-50dB:d=2 \
      -f null - 2>&1 | grep -q 'silence_duration'; then
    fail "$id contains >=2s digital silence below -50dB"
  fi

  if [[ "$failures" -eq "$cue_failures_before" ]]; then
    echo "[music-verify] PASS $id duration=${duration}s source=${source_duration}s loudness=${integrated}LUFS peak=${true_peak}dBFS sha256=$asset_hash"
  fi
done <<< "$expected_names"

unique_asset_hashes="$(sort -u "$asset_hashes_file" | wc -l | tr -d ' ')"
unique_source_hashes="$(sort -u "$source_hashes_file" | wc -l | tr -d ' ')"
[[ "$unique_asset_hashes" -eq 6 ]] || fail "unique asset hashes=$unique_asset_hashes expected=6"
[[ "$unique_source_hashes" -eq 6 ]] || fail "unique source hashes=$unique_source_hashes expected=6"

rejected_path="$(res_path "$(jq -r '.deviations[] | select(.id == "D-MUSIC-1") | .rejected_source_path' "$provenance")")"
rejected_hash="$(jq -r '.deviations[] | select(.id == "D-MUSIC-1") | .rejected_source_sha256' "$provenance")"
if [[ ! -s "$rejected_path" ]]; then
  fail "D-MUSIC-1 rejected source missing"
else
  [[ "$(sha256sum "$rejected_path" | cut -d' ' -f1)" == "$rejected_hash" ]] || \
    fail "D-MUSIC-1 rejected source hash mismatch"
  rejected_duration="$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$rejected_path")"
  within "$rejected_duration" 162.403208 0.05 || fail "D-MUSIC-1 rejected duration mismatch"
fi

if [[ "$failures" -ne 0 ]]; then
  echo "[music-verify] RED failures=$failures" >&2
  exit 1
fi

echo "[music-verify] ALL GREEN cues=6 unique_assets=6 unique_sources=6 transcriptions=6"
