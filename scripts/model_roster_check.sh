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
	.environment_sha256 == "766d1404bfa53e650cc419c49fde338eb20334611b49a19cd095a789f6f525b5"
	and .fresh_checksum == "69270968b2fedd82f98de96cf6ad530ad8e694d241aabdba5ab97a396e1b664b"
	and .fresh_hash == "baa4d62d418258a5"
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
