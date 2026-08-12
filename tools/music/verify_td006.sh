#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

for tool in ffmpeg ffprobe jq bc sha256sum grep; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "[td006-verify] missing required tool: $tool" >&2
    exit 2
  }
done

root="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$root"

provenance="assets/music/provenance.json"
failures=0

fail() {
  echo "[td006-verify] FAIL $*" >&2
  failures=$((failures + 1))
}

within() {
  local measured="$1"
  local expected="$2"
  local tolerance="$3"
  [[ "$(printf 'd=(%s)-(%s); if (d < 0) d=-d; d <= %s\n' \
    "$measured" "$expected" "$tolerance" | bc -l)" -eq 1 ]]
}

measure_mean_dbfs() {
  local input="$1"
  local filter="${2:-}"
  local chain="volumedetect"
  if [[ -n "$filter" ]]; then
    chain="${filter},volumedetect"
  fi
  ffmpeg -nostdin -hide_banner -i "$input" -af "$chain" -f null - 2>&1 \
    | awk -F': ' '/mean_volume:/{sub(/ dB$/, "", $2); print $2; exit}'
}

jq empty "$provenance"
[[ "$(jq -r '.catalog_revision' "$provenance")" -eq 2 ]] || fail "catalog_revision must be 2"
[[ "$(jq -r '.human_feedback.classification' "$provenance")" == "prompt-change" ]] || \
  fail "human feedback classification must remain prompt-change"
jq -e '.human_feedback.final_acceptance_complete == false' "$provenance" >/dev/null || \
  fail "final human acceptance must remain incomplete"

# Three untouched slots must remain byte-identical to TD-003.
declare -A untouched_assets=(
  [act_1_guild_threshold_boss]="18a61cc77adc10f502e7cbc21d1af9d5075c472be2348bc390d67b45ad175109"
  [act_2_twilight_grotto_bgm]="b3642eed59512d03ff14739c21419db318e21eec72b5446439d7a0a14158c887"
  [act_2_twilight_grotto_boss]="43892acb139a1917605293071fad7f3525ecb2f31a2f4337fc81e54da8729c34"
)
declare -A untouched_sources=(
  [act_1_guild_threshold_boss]="94f93e0cc28d18c5f2e87464c38cb77fc74b7f9928024af6dd000e75530afb17"
  [act_2_twilight_grotto_bgm]="80a223c231ed7f4b10a536688699b39dda8caa4a3ab885630fd1172fc5b6fdbb"
  [act_2_twilight_grotto_boss]="94dc792bd7cd4800d51363eb1ac59fe87fd0dea76258ca387535ce42d817670b"
)
for name in "${!untouched_assets[@]}"; do
  asset="assets/music/${name}.ogg"
  source="assets/music/sources/${name}.mp3.source"
  [[ "$(sha256sum "$asset" | cut -d' ' -f1)" == "${untouched_assets[$name]}" ]] || \
    fail "$name shipping asset changed outside TD-006 scope"
  [[ "$(sha256sum "$source" | cut -d' ' -f1)" == "${untouched_sources[$name]}" ]] || \
    fail "$name retained source changed outside TD-006 scope"
done

# Named references may inform the human brief but never enter generator prompts.
for prompt in \
  assets/music/prompts/act_1_guild_threshold_bgm.txt \
  assets/music/prompts/act_3_abyssal_vault_bgm.txt \
  assets/music/prompts/act_3_abyssal_vault_boss.txt; do
  if grep -Eqi 'Frieren|Genshin|Baldur|Hisaishi|artist|soundtrack' "$prompt"; then
    fail "named imitation reference leaked into $prompt"
  fi
done

grep -Fq '78 BPM in D Dorian' assets/music/prompts/act_1_guild_threshold_bgm.txt || \
  fail "Act I prompt does not pin calmer tempo and mode"
grep -Fq 'peaceful, patient, tender, and quietly wise' assets/music/prompts/act_1_guild_threshold_bgm.txt || \
  fail "Act I prompt does not pin peaceful target"
grep -Fq 'never heroic' assets/music/prompts/act_1_guild_threshold_bgm.txt || \
  fail "Act I prompt does not reject heroic brass pressure"
grep -Fq 'conspicuously echoing' assets/music/prompts/act_3_abyssal_vault_bgm.txt || \
  fail "Act III BGM prompt does not pin cavern echoes"
grep -Fq 'not depressed, hopeless, funereal' assets/music/prompts/act_3_abyssal_vault_bgm.txt || \
  fail "Act III BGM prompt does not reject depressive/funereal character"
grep -Fq 'epic dark-fantasy war track' assets/music/prompts/act_3_abyssal_vault_boss.txt || \
  fail "Act III boss prompt does not pin epic war identity"
grep -Fq 'not depressed, hopeless, funereal, or nihilistic' assets/music/prompts/act_3_abyssal_vault_boss.txt || \
  fail "Act III boss prompt does not reject depressive/funereal character"
grep -Fq 'Make the cavern conspicuously echoing' assets/music/prompts/act_3_abyssal_vault_boss.txt || \
  fail "Act III boss prompt does not pin cavern echoes"

for id in act_1_bgm act_3_bgm act_3_boss; do
  track="$(jq -c --arg id "$id" '.tracks[] | select(.id == $id)' "$provenance")"
  [[ -n "$track" ]] || { fail "$id provenance missing"; continue; }
  [[ "$(jq -r '.revision' <<< "$track")" -eq 2 ]] || fail "$id revision must be 2"
  jq -e '.placeholder == true' <<< "$track" >/dev/null || fail "$id placeholder must remain true"
  asset="${id/act_1_bgm/act_1_guild_threshold_bgm}"
  asset="${asset/act_3_bgm/act_3_abyssal_vault_bgm}"
  asset="${asset/act_3_boss/act_3_abyssal_vault_boss}"
  asset="assets/music/${asset}.ogg"
  actual_hash="$(sha256sum "$asset" | cut -d' ' -f1)"
  [[ "$actual_hash" == "$(jq -r '.asset_sha256' <<< "$track")" ]] || fail "$id asset hash mismatch"
  [[ "$actual_hash" != "$(jq -r '.supersedes_asset_sha256' <<< "$track")" ]] || \
    fail "$id replacement matches superseded bytes"
done

# Prove the requested Act III low-band increase after normalized processing.
for id in act_3_bgm act_3_boss; do
  track="$(jq -c --arg id "$id" '.tracks[] | select(.id == $id)' "$provenance")"
  if [[ "$id" == "act_3_bgm" ]]; then
    asset="assets/music/act_3_abyssal_vault_bgm.ogg"
    expected_preprocess="bass=g=4:f=180:w=0.7"
  else
    asset="assets/music/act_3_abyssal_vault_boss.ogg"
    expected_preprocess="bass=g=3:f=180:w=0.7"
  fi
  [[ "$(jq -r '.preprocess' <<< "$track")" == "$expected_preprocess" ]] || \
    fail "$id preprocess recipe mismatch"
  full_mean="$(measure_mean_dbfs "$asset")"
  low_mean="$(measure_mean_dbfs "$asset" 'lowpass=f=220')"
  pinned_full="$(jq -r '.full_mean_dbfs' <<< "$track")"
  pinned_low="$(jq -r '.low_220_mean_dbfs' <<< "$track")"
  predecessor_low="$(jq -r '.supersedes_low_220_mean_dbfs' <<< "$track")"
  within "$full_mean" "$pinned_full" 0.15 || fail "$id full-band mean mismatch"
  within "$low_mean" "$pinned_low" 0.15 || fail "$id sub-220 Hz mean mismatch"
  [[ "$(printf '%s >= (%s + 0.5)\n' "$low_mean" "$predecessor_low" | bc -l)" -eq 1 ]] || \
    fail "$id sub-220 Hz gain is <0.5 dB versus predecessor"
  echo "[td006-verify] LOW-BAND $id full=${full_mean}dBFS low220=${low_mean}dBFS predecessor=${predecessor_low}dBFS"
done

rejected="assets/music/sources/rejected_act_3_abyssal_vault_bgm_short.mp3.source"
expected_rejected_hash="$(jq -r '.deviations[] | select(.id == "D-MUSIC-5") | .rejected_source_sha256' "$provenance")"
[[ -s "$rejected" ]] || fail "D-MUSIC-5 rejected source missing"
[[ "$(sha256sum "$rejected" | cut -d' ' -f1)" == "$expected_rejected_hash" ]] || \
  fail "D-MUSIC-5 rejected source hash mismatch"
rejected_duration="$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$rejected")"
within "$rejected_duration" 110.785250 0.05 || fail "D-MUSIC-5 rejected duration mismatch"
[[ ! -e "${rejected}.import" ]] || fail "rejected source must not be imported"
[[ "$(jq '[.deviations[] | select(.id == "D-MUSIC-8")] | length' "$provenance")" -eq 1 ]] || \
  fail "D-MUSIC-8 low-shelf deviation must be recorded once"

if [[ "$failures" -ne 0 ]]; then
  echo "[td006-verify] RED failures=$failures" >&2
  exit 1
fi

echo "[td006-verify] ALL GREEN replacements=3 untouched=3 low_band_gains=2 rejected_sources=1 placeholders=3"
