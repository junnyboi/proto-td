#!/bin/bash
set -euo pipefail

GODOT="${GODOT:-$HOME/bin/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="artifacts/model-roster/summary.json"
for arg in "$@"; do
  case "$arg" in
    --out=*) OUT="${arg#--out=}" ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done
cd "$ROOT"
mkdir -p "$(dirname "$OUT")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

run_one() {
  local name="$1"
  shift
  timeout 30 "$GODOT" --headless --path . -s tools/model_roster_runner.gd -- "$@" \
    >"$TMP/$name.log" 2>&1
  grep '^MODEL_ROSTER_RESULT=' "$TMP/$name.log" >"$TMP/$name.result"
  [[ "$(wc -l < "$TMP/$name.result")" -eq 1 ]]
  sed 's/^MODEL_ROSTER_RESULT=//' "$TMP/$name.result" >"$TMP/$name.json"
  jq -e . "$TMP/$name.json" >/dev/null
}

run_one normal
run_one reversed --reverse-inputs
cmp -s "$TMP/normal.json" "$TMP/reversed.json"

jq -e '
  .environment_sha256 == "cf4a272e5aa14a2c8606a6aa6de8efb8345af37d10c82ecf2e579987f7fdb8b6"
  and .fresh_checksum == "516eb349d33fbb40408d742f86ef0784fc8ab9c473ab66893a730c28712f0c6a"
  and .fresh_hash == "85f2c11018249153"
  and .campaign_uid == "ce46150984346591"
  and (.heroes | length) == 5
  and .fresh_reward_hero_id == "e54c103e46898f5d"
  and .paid_reward_hero_id == "fe0ff2c1e3ecc49d"
' "$TMP/normal.json" >/dev/null

jq -n \
  --arg verdict pass \
  --arg normal_sha256 "$(sha256sum "$TMP/normal.json" | awk '{print $1}')" \
  --arg reversed_sha256 "$(sha256sum "$TMP/reversed.json" | awk '{print $1}')" \
  --slurpfile manifest "$TMP/normal.json" \
  '{verdict:$verdict, processes:2, byte_identical:true,
    normal_sha256:$normal_sha256, reversed_sha256:$reversed_sha256,
    manifest:$manifest[0]}' > "$OUT"

echo "[model-roster] PASS (2 fresh processes, byte-identical)"
