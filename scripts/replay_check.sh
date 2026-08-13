#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT:-$HOME/bin/godot}"
FIXTURES="res://playtests/replays/v1"
OUT_DIR="artifacts/replay"
HASH_EVERY=100
MAX_TICKS=6000

for arg in "$@"; do
  case "$arg" in
    --fixtures=*) FIXTURES="${arg#*=}" ;;
    --out=*) OUT_DIR="${arg#*=}" ;;
    --hash-every=*) HASH_EVERY="${arg#*=}" ;;
    --max-ticks=*) MAX_TICKS="${arg#*=}" ;;
    *) echo "[replay-check] unknown argument: $arg" >&2; exit 2 ;;
  esac
done

if [[ "${P16_REPLAY_INNER:-0}" != 1 ]]; then
  run_token="$(date +%s%N)-$$"
  status=0
  P16_REPLAY_INNER=1 P16_REPLAY_RUN_TOKEN="$run_token" \
    timeout 30s "$0" "$@" || status=$?
  if [[ "$status" -eq 124 ]]; then
    mkdir -p "$OUT_DIR"
    jq -n --arg run_token "$run_token" \
      '{verdict:"fail",status:"FAIL",sentinel:"REPLAY_CHECK_FAILED",run_token:$run_token,identical:false,error_code:"replay_watchdog_timeout"}' \
      > "$OUT_DIR/summary.json"
    echo '[replay-check] FAIL: 30s watchdog timeout' >&2
  elif [[ "$status" -ne 0 && ! -s "$OUT_DIR/summary.json" ]]; then
    mkdir -p "$OUT_DIR"
    jq -n --arg run_token "$run_token" --argjson exit_code "$status" \
      '{verdict:"fail",status:"FAIL",sentinel:"REPLAY_CHECK_FAILED",run_token:$run_token,identical:false,error_code:"replay_child_failed",exit_code:$exit_code}' \
      > "$OUT_DIR/summary.json"
  fi
  exit "$status"
fi

mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR/run-1.json" "$OUT_DIR/run-2.json" \
  "$OUT_DIR/diff.txt" "$OUT_DIR/summary.json"

run_one() {
  local output="$1"
  timeout 12s "$GODOT" --headless --path . \
    -s tools/replay_runner.gd -- \
    "--fixtures=$FIXTURES" "--out=$output" \
    "--hash-every=$HASH_EVERY" "--max-ticks=$MAX_TICKS"
}

if ! run_one "$OUT_DIR/run-1.json"; then
  jq -n --arg run_token "$P16_REPLAY_RUN_TOKEN" \
    '{verdict:"fail",status:"FAIL",sentinel:"REPLAY_CHECK_FAILED",run_token:$run_token,identical:false,error_code:"replay_process_1_failed"}' \
    > "$OUT_DIR/summary.json"
  exit 1
fi
if ! run_one "$OUT_DIR/run-2.json"; then
  jq -n --arg run_token "$P16_REPLAY_RUN_TOKEN" \
    '{verdict:"fail",status:"FAIL",sentinel:"REPLAY_CHECK_FAILED",run_token:$run_token,identical:false,error_code:"replay_process_2_failed"}' \
    > "$OUT_DIR/summary.json"
  exit 1
fi

if ! cmp -s "$OUT_DIR/run-1.json" "$OUT_DIR/run-2.json"; then
  diff -u "$OUT_DIR/run-1.json" "$OUT_DIR/run-2.json" > "$OUT_DIR/diff.txt" || true
  jq -n --arg run_token "$P16_REPLAY_RUN_TOKEN" --arg diagnostic "$OUT_DIR/diff.txt" \
    '{verdict:"fail",status:"FAIL",sentinel:"REPLAY_CHECK_FAILED",run_token:$run_token,identical:false,error_code:"cross_process_mismatch",diagnostic:$diagnostic}' > "$OUT_DIR/summary.json"
  echo "[replay-check] FAIL: process outputs differ" >&2
  exit 1
fi

jq -e '
  .status == "PASS"
  and .sentinel == "REPLAY_RUN_OK"
  and (.runs | length > 0)
  and (.accepted_actions > 0)
  and (.rejected_actions > 0)
  and ([.runs[].action_results[] | .accepted == .expected_accepted] | all)
  and ([.runs[].action_results[] | select(.accepted == false) | .state_hash_before == .state_hash_after] | all)
	and ([.runs[] | has("canonical_replay") and has("canonical_replay_sha256")] | all)
	and ([.runs[] | .terminal.reason | IN("clear","leak_defeat","base_defeat","resign")] | all)
	and ([.runs[] | .telemetry | has("counters") and has("series_last") and has("events")] | all)
	and .campaign_contract == {
		checksum:"bcd36b9349ba086ba543d1ca189af2c40beeb3f6c5ec573a67755596386ba10f",
		save_sha256:"c04a0ba033f38f170148c76dd18a4e9c7f814689df2eb39457d3c69730cb8ed1",
		full_strategic_hash:"e293b40478a9771c",
		strategic_body_hash_before:"39725890ee4a6a1a",
		strategic_body_hash_after:"4942c92d813313ac"
	}
' "$OUT_DIR/run-1.json" >/dev/null || {
  jq -n --arg run_token "$P16_REPLAY_RUN_TOKEN" \
    '{verdict:"fail",status:"FAIL",sentinel:"REPLAY_CHECK_FAILED",run_token:$run_token,identical:true,error_code:"incomplete_or_mismatched_replay"}' \
    > "$OUT_DIR/summary.json"
  echo '[replay-check] FAIL: incomplete, mismatched, or vacuous proof channel' >&2
  exit 1
}

digest="$(sha256sum "$OUT_DIR/run-1.json" | cut -d' ' -f1)"
runs="$(jq '.runs | length' "$OUT_DIR/run-1.json")"
jq -n --arg run_token "$P16_REPLAY_RUN_TOKEN" --arg digest "$digest" --argjson runs "$runs" \
  --argjson accepted_actions "$(jq '.accepted_actions' "$OUT_DIR/run-1.json")" \
  --argjson rejected_actions "$(jq '.rejected_actions' "$OUT_DIR/run-1.json")" \
  '{verdict:"pass",status:"PASS",sentinel:"REPLAY_CHECK_OK",run_token:$run_token,identical:true,sha256:$digest,runs:$runs,accepted_actions:$accepted_actions,rejected_actions:$rejected_actions}' \
  > "$OUT_DIR/summary.json"
echo "[replay-check] PASS runs=$runs sha256=$digest"
