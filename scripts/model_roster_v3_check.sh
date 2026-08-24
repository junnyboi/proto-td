#!/bin/bash
set -euo pipefail

GODOT="${GODOT:-$HOME/.local/bin/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="artifacts/model-roster-v3/summary.json"
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
  timeout 60 "$GODOT" --headless --path . \
    -s test/fixtures/p16/campaign_v3_vector.gd >"$TMP/$name.log" 2>&1
  grep '^CAMPAIGN_V3_' "$TMP/$name.log" >"$TMP/$name.result"
  [[ "$(wc -l < "$TMP/$name.result")" -eq 5 ]]
  ! grep -q '^CAMPAIGN_V3_VECTOR_FAIL=' "$TMP/$name.log"
}

run_one process_a
run_one process_b
cmp -s "$TMP/process_a.result" "$TMP/process_b.result"
grep -Fx 'CAMPAIGN_V3_MIGRATED_SHA256=2c87014e626af106e514434358f3c3148a9baa1e6da7f6c88718654d8b1101d5' "$TMP/process_a.result" >/dev/null
grep -Fx 'CAMPAIGN_V3_MIGRATED_HASH=4160b69281d05165' "$TMP/process_a.result" >/dev/null
grep -Fx 'CAMPAIGN_V3_FRESH_SHA256=a43eb6ca96e9b5c0004aa1527caa1f023e3aaf007fc1545c95485c1760e52c3c' "$TMP/process_a.result" >/dev/null
grep -Fx 'CAMPAIGN_V3_FRESH_HASH=b62636c0071a53c4' "$TMP/process_a.result" >/dev/null
grep -Fx 'CAMPAIGN_V3_VECTOR_OK' "$TMP/process_a.result" >/dev/null

jq -n \
  --arg verdict pass \
  --arg process_a_sha256 "$(sha256sum "$TMP/process_a.result" | awk '{print $1}')" \
  --arg process_b_sha256 "$(sha256sum "$TMP/process_b.result" | awk '{print $1}')" \
  '{verdict:$verdict, processes:2, byte_identical:true,
    process_a_sha256:$process_a_sha256, process_b_sha256:$process_b_sha256}' > "$OUT"

echo "[model-roster-v3] PASS (2 fresh processes, exact v3 roster/migration sentinels)"
