#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-artifacts/replay-v2}"
REPLAY_SHA="fef34b5901cdc5d6eb00cc98e101d2a8bd71516392ea760de2f529b0fb697531"
TICKET_HASH="a4dd3dd15efe297c1dd8bff779cd45b09cb3e62023ecffe44ae256a21612f736"
TERMINAL_HASH="14b6302bf57674e7"
OUTCOME_SHA="ab3f5b6a49a8e9624d06c71e755f99bb7e7d0c5959975bf536568db02a30efaa"
OUTCOME_HASH="185140c95ce217d3bbdf8ef1df720e935f3b9c29990832c3cdacba1fbda7a189"

scripts/replay_check.sh \
  --fixtures=res://playtests/replays/v2 \
  --out="$OUT_DIR" \
  --hash-every=100 \
  --max-ticks=2400 \
  --trusted-ticket-hash="$TICKET_HASH"

jq -e \
  --arg replay_sha "$REPLAY_SHA" \
  --arg ticket_hash "$TICKET_HASH" \
  --arg terminal_hash "$TERMINAL_HASH" \
  --arg outcome_sha "$OUTCOME_SHA" \
  --arg outcome_hash "$OUTCOME_HASH" '
  .status == "PASS"
  and .sentinel == "REPLAY_RUN_OK"
  and .accepted_actions == 3
  and .rejected_actions == 1
  and (.runs | length) == 1
  and .runs[0].replay_version == 2
  and .runs[0].canonical_replay_sha256 == $replay_sha
  and .runs[0].ticket_hash == $ticket_hash
  and .runs[0].terminal.hash == $terminal_hash
  and .runs[0].terminal.result == "clear"
  and .runs[0].terminal.reason == "clear"
  and .runs[0].terminal.tick == 1202
  and .runs[0].terminal.stars == 2
  and .runs[0].terminal.killed == 4
  and .runs[0].terminal.leaked == 2
  and .runs[0].outcome_sha256 == $outcome_sha
  and .runs[0].outcome.outcome_hash == $outcome_hash
  and .runs[0].outcome.ticket_hash == $ticket_hash
  and .runs[0].outcome.terminal_tick == .runs[0].terminal.tick
  and ([.runs[0].outcome.rows[].operator_def_id] == ["recruit","recruit","recruit"])
  and ([.runs[0].outcome.rows[].battle_id] | unique | length) == 3
  and ([.runs[0].outcome.rows[].hero_id] | unique | length) == 3
  and ([.runs[0].outcome.rows[].deployments] == [1,1,1])
  and ([.runs[0].outcome.rows[] | select(.fell)] | length) == 2
  and ([.runs[0].action_results[] | select(.accepted == false) | .state_hash_before == .state_hash_after] | all)
' "$OUT_DIR/run-1.json" >/dev/null

run_sha="$(sha256sum "$OUT_DIR/run-1.json" | cut -d' ' -f1)"
jq -n \
  --arg run_sha "$run_sha" \
  --arg replay_sha "$REPLAY_SHA" \
  --arg ticket_hash "$TICKET_HASH" \
  --arg terminal_hash "$TERMINAL_HASH" \
  --arg outcome_hash "$OUTCOME_HASH" \
  '{
    verdict:"pass",
    status:"PASS",
    sentinel:"REPLAY_V2_CHECK_OK",
    identical:true,
    run_sha256:$run_sha,
    replay_sha256:$replay_sha,
    ticket_hash:$ticket_hash,
    terminal_hash:$terminal_hash,
    outcome_hash:$outcome_hash,
    accepted_actions:3,
    rejected_actions:1,
    identities:3,
    falls:2
  }' > "$OUT_DIR/summary.json"

echo "[replay-v2-check] PASS sha256=$run_sha"
