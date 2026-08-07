#!/bin/bash
# L6 quality gate over bot telemetry. Tier 1 (stability) is absolute; tier 2
# bands stay empty until human playtest round 1 writes them (the gate only
# holds lines humans drew). Verdict names which check failed and by how much
# (artifacts/gate.json) — that string is agent food for the retune.
#   quality_gate.sh [telemetry.json]
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TELEMETRY="${1:-$ROOT/artifacts/telemetry.json}"
THRESHOLDS="$ROOT/playtests/thresholds.json"
GATE_OUT="$ROOT/artifacts/gate.json"
mkdir -p "$ROOT/artifacts"

fail() {
  jq -n --arg verdict "NO-GO" --arg reason "$1" \
    '{verdict: $verdict, failures: [$reason]}' > "$GATE_OUT"
  echo "[GATE] NO-GO: $1" >&2
  exit 1
}

[[ -f "$TELEMETRY" ]] || fail "telemetry file missing: $TELEMETRY"
[[ -f "$THRESHOLDS" ]] || fail "thresholds file missing: $THRESHOLDS"

QUIT_REASON=$(jq -r '.meta.quit_reason // "missing"' "$TELEMETRY")
TICKS=$(jq -r '.meta.ticks // 0' "$TELEMETRY")
MIN_TICKS=$(jq -r '.tier1_stability.min_ticks // 0' "$THRESHOLDS")
ALLOWED=$(jq -r '.tier1_stability.allowed_quit_reasons // [] | .[]' "$THRESHOLDS")

OK=0
for reason in $ALLOWED; do
  [[ "$QUIT_REASON" == "$reason" ]] && OK=1
done
[[ $OK -eq 1 ]] || fail "tier1: quit_reason '$QUIT_REASON' not in allowed set [$(echo $ALLOWED | tr ' ' ',')]"
[[ "$TICKS" -ge "$MIN_TICKS" ]] || fail "tier1: ticks $TICKS < min_ticks $MIN_TICKS"

BAND_COUNT=$(jq -r '.tier2_balance.bands | length' "$THRESHOLDS")
jq -n --arg verdict "GO" --argjson bands "$BAND_COUNT" \
  '{verdict: $verdict, failures: [], tier2_bands_evaluated: $bands}' > "$GATE_OUT"
echo "[GATE] GO (tier1 pass; $BAND_COUNT tier-2 bands defined)"
exit 0
