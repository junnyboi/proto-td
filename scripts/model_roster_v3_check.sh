#!/bin/bash
set -euo pipefail

GODOT="${GODOT:-$HOME/bin/godot}"
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
grep -Fx 'CAMPAIGN_V3_MIGRATED_SHA256=81beccb348423bb83e431a4a94428c24f17872754add45ae4d51aa5dd7d347da' "$TMP/process_a.result" >/dev/null
grep -Fx 'CAMPAIGN_V3_MIGRATED_HASH=da67f175d2ae8950' "$TMP/process_a.result" >/dev/null
grep -Fx 'CAMPAIGN_V3_FRESH_SHA256=e348483cceee4651c697f323ad4db56dce5fedcd0c33f7551a36b5f35a9aff56' "$TMP/process_a.result" >/dev/null
grep -Fx 'CAMPAIGN_V3_FRESH_HASH=bf4a5c25be2b0efd' "$TMP/process_a.result" >/dev/null
grep -Fx 'CAMPAIGN_V3_VECTOR_OK' "$TMP/process_a.result" >/dev/null

jq -n \
  --arg verdict pass \
  --arg process_a_sha256 "$(sha256sum "$TMP/process_a.result" | awk '{print $1}')" \
  --arg process_b_sha256 "$(sha256sum "$TMP/process_b.result" | awk '{print $1}')" \
  '{verdict:$verdict, processes:2, byte_identical:true,
    process_a_sha256:$process_a_sha256, process_b_sha256:$process_b_sha256}' > "$OUT"

echo "[model-roster-v3] PASS (2 fresh processes, exact v3 roster/migration sentinels)"
