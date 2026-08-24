#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT:-$HOME/.local/bin/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/artifacts/td-obs"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/protos-td-obs.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
cd "$ROOT"
mkdir -p "$OUT"
rm -rf "$OUT"/*

fail() {
  echo "[td-obs] FAIL: $*" >&2
  exit 1
}

run() {
  local budget="$1"
  shift
  timeout --foreground "${budget}s" "$@"
}

[[ -x "$GODOT" ]] || fail "Godot executable not found: $GODOT"
command -v gdlint >/dev/null || fail "gdlint not found"
command -v jq >/dev/null || fail "jq not found"

production=(
  autoloads/playtest_runner.gd
  playtests/bots/bot_base.gd
  playtests/bots/bot_campaign.gd
  playtests/bots/stage_bot_base.gd
  playtests/bots/action_trace.gd
  playtests/bots/bot_stage_06_conditional.gd
  playtests/bots/bot_stage_06_conditional_no_charm.gd
  playtests/bots/conditional_policy.gd
  playtests/bots/policy_bot_driver.gd
  playtests/bots/policy_stage_06.gd
  sim/battle_observation.gd
  sim/battle_observation_telemetry.gd
)
tests=(
  test/test_battle_observation.gd
  test/test_bot_action_trace.gd
  test/test_conditional_policy.gd
  test/test_observation_telemetry.gd
  test/test_policy_bot_driver.gd
)
all_gd=("${production[@]}" "${tests[@]}")
for path in "${all_gd[@]}"; do
  [[ -f "$path" ]] || fail "missing TD-OBS file: $path"
  [[ -f "$path.uid" ]] || fail "missing UID file: $path.uid"
done

run 120 "$GODOT" --headless --path . --import >"$OUT/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script' "$OUT/import.log"; then
  fail "import reported script errors (see $OUT/import.log)"
fi
gdlint "${all_gd[@]}" >"$OUT/gdlint.log" 2>&1

gut_args=()
for path in "${tests[@]}" test/test_battle_model.gd test/test_hash_paranoia.gd; do
  gut_args+=("-gtest=res://$path")
done
run 120 "$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd \
  "${gut_args[@]}" -gexit >"$OUT/gut.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Nothing was run|Errors[[:space:]]+[1-9][0-9]*' "$OUT/gut.log"; then
  fail "GUT reported framework, parser, or discovery errors (see $OUT/gut.log)"
fi
test_count="$(grep -E '^Tests[[:space:]]+[0-9]+$' "$OUT/gut.log" | tail -1 | awk '{print $2}')"
assert_count="$(grep -E '^Asserts[[:space:]]+[0-9]+$' "$OUT/gut.log" | tail -1 | awk '{print $2}')"
[[ -n "$test_count" && "$test_count" -gt 0 ]] || fail "GUT reported zero tests"
[[ -n "$assert_count" && "$assert_count" -gt 0 ]] || fail "GUT reported zero assertions"

run 40 scripts/replay_check.sh --out=artifacts/td-obs/replay >"$OUT/replay.log" 2>&1
jq -e '.status == "PASS" and .sentinel == "REPLAY_CHECK_OK" and .identical == true' \
  "$OUT/replay/summary.json" >/dev/null || fail "replay proof failed"

run_playtest() {
  local bot="$1"
  local ticks="$2"
  local destination="$3"
  rm -f artifacts/telemetry.json
  run 45 scripts/playtest.sh "$bot" --ticks "$ticks" >"$destination.log" 2>&1
  [[ -s artifacts/telemetry.json ]] || fail "$bot produced no telemetry"
  cp artifacts/telemetry.json "$destination.json"
}

run_playtest bot_stage_06 1800 "$OUT/baseline-full"
run_playtest bot_stage_06_no_charm 1800 "$OUT/baseline-no-charm"
grep -F '[STAGE-BOT] s6 CLEAR leaked=2 stars=2 tick=1319' "$OUT/baseline-full.log" >/dev/null \
  || fail "scripted S6 full baseline drifted"
grep -F '[STAGE-BOT] s6 DEFEAT leaked=4 stars=0 tick=1267' "$OUT/baseline-no-charm.log" >/dev/null \
  || fail "scripted S6 no-Charm baseline drifted"
jq -e '.meta.quit_reason == "bot_done" and .meta.stop_reason == "terminal_clear"' \
  "$OUT/baseline-full.json" >/dev/null || fail "scripted S6 full stop metadata drifted"
jq -e '.meta.quit_reason == "bot_done" and .meta.stop_reason == "terminal_defeat"' \
  "$OUT/baseline-no-charm.json" >/dev/null || fail "scripted S6 no-Charm stop metadata drifted"

normalize_telemetry() {
  jq -S 'del(.meta.wall_ms, .meta.engine)' "$1" >"$2"
}

for run_index in 1 2; do
  run_playtest bot_stage_06_conditional 1800 "$OUT/conditional-full-$run_index"
  normalize_telemetry "$OUT/conditional-full-$run_index.json" \
    "$OUT/conditional-full-$run_index.normalized.json"
done
cmp -s "$OUT/conditional-full-1.normalized.json" "$OUT/conditional-full-2.normalized.json" \
  || fail "conditional full telemetry differs across independent processes"

for run_index in 1 2; do
  run_playtest bot_stage_06_conditional_no_charm 1800 "$OUT/conditional-no-charm-$run_index"
  normalize_telemetry "$OUT/conditional-no-charm-$run_index.json" \
    "$OUT/conditional-no-charm-$run_index.normalized.json"
done
cmp -s "$OUT/conditional-no-charm-1.normalized.json" \
  "$OUT/conditional-no-charm-2.normalized.json" \
  || fail "conditional no-Charm telemetry differs across independent processes"

full="$OUT/conditional-full-1.normalized.json"
no_charm="$OUT/conditional-no-charm-1.normalized.json"
summary_filter='def hex16: type == "string" and test("^[0-9a-f]{16}$");
def hex64: type == "string" and test("^[0-9a-f]{64}$");
.meta.quit_reason == "bot_done"
and .meta.bot_summary.command_count <= 256
and .meta.bot_summary.rejected_hashes_equal == true
and (.meta.bot_summary.model_hash | hex16)
and (.meta.bot_summary.observation_sequence_sha256 | hex64)
and (.meta.bot_summary.trace_sha256 | hex64)'
jq -e "$summary_filter
  and .meta.stop_reason == \"terminal_clear\"
  and .meta.bot_summary.stop_reason == \"terminal_clear\"
  and .meta.bot_summary.result == \"clear\"
  and .meta.bot_summary.leaked == 1
  and .meta.bot_summary.capabilities == [\"charm\",\"deploy\",\"skill\",\"trap\"]" \
  "$full" >/dev/null || fail "conditional full contract failed"
jq -e "$summary_filter
  and .meta.stop_reason == \"terminal_defeat\"
  and .meta.bot_summary.stop_reason == \"terminal_defeat\"
  and .meta.bot_summary.result == \"defeat\"
  and .meta.bot_summary.leaked == 4
  and .meta.bot_summary.capabilities == [\"deploy\",\"skill\",\"trap\"]" \
  "$no_charm" >/dev/null || fail "conditional no-Charm contract failed"
jq -e -n --slurpfile full "$full" --slurpfile cut "$no_charm" '
  ($full[0].meta.bot_summary.capabilities - ["charm"])
    == $cut[0].meta.bot_summary.capabilities
  and ($cut[0].meta.bot_summary.capabilities - $full[0].meta.bot_summary.capabilities) == []
' >/dev/null || fail "capability arrays differ by more than charm"

probe() {
  local name="$1"
  local expected_code="$2"
  local expected_reason="$3"
  local bot="$4"
  local ticks="$5"
  rm -f artifacts/telemetry.json
  set +e
  run 30 "$GODOT" --headless --fixed-fps 60 --path . -- \
    "--playtest=$bot" --seed=42 "--max-ticks=$ticks" >"$OUT/probe-$name.log" 2>&1
  local code=$?
  set -e
  [[ "$code" -eq "$expected_code" ]] \
    || fail "$name probe exit $code, expected $expected_code"
  [[ -s artifacts/telemetry.json ]] || fail "$name probe produced no telemetry"
  cp artifacts/telemetry.json "$OUT/probe-$name.json"
  jq -e --arg reason "$expected_reason" '.meta.stop_reason == $reason' \
    "$OUT/probe-$name.json" >/dev/null || fail "$name probe stop_reason drifted"
  printf '%s' "$code" >"$TMP/$name.exit"
}

probe duration 0 duration_reached bot_idle 2
probe missing 4 bot_load_failed bot_td_obs_missing 2
probe watchdog 3 watchdog_max_ticks bot_stage_06_conditional 1

allowed_paths=(
  FEATURES.json
  autoloads/playtest_runner.gd
  playtests/bots/action_trace.gd
  playtests/bots/action_trace.gd.uid
  playtests/bots/bot_base.gd
  playtests/bots/bot_campaign.gd
  playtests/bots/bot_stage_06_conditional.gd
  playtests/bots/bot_stage_06_conditional.gd.uid
  playtests/bots/bot_stage_06_conditional_no_charm.gd
  playtests/bots/bot_stage_06_conditional_no_charm.gd.uid
  playtests/bots/conditional_policy.gd
  playtests/bots/conditional_policy.gd.uid
  playtests/bots/policy_bot_driver.gd
  playtests/bots/policy_bot_driver.gd.uid
  playtests/bots/policy_stage_06.gd
  playtests/bots/policy_stage_06.gd.uid
  playtests/bots/stage_bot_base.gd
  scripts/td_obs_check.sh
  sim/battle_observation.gd
  sim/battle_observation.gd.uid
  sim/battle_observation_telemetry.gd
  sim/battle_observation_telemetry.gd.uid
  test/test_battle_observation.gd
  test/test_battle_observation.gd.uid
  test/test_bot_action_trace.gd
  test/test_bot_action_trace.gd.uid
  test/test_conditional_policy.gd
  test/test_conditional_policy.gd.uid
  test/test_observation_telemetry.gd
  test/test_observation_telemetry.gd.uid
  test/test_policy_bot_driver.gd
  test/test_policy_bot_driver.gd.uid
)
printf '%s\n' "${allowed_paths[@]}" | sort -u >"$TMP/allowed"
git status --porcelain=v1 --untracked-files=all | sed -E 's/^.. //' | sort -u >"$TMP/actual"
if ! comm -23 "$TMP/actual" "$TMP/allowed" >"$TMP/unowned"; then
  fail "could not compare owned paths"
fi
[[ ! -s "$TMP/unowned" ]] || fail "unowned source changes: $(tr '\n' ' ' <"$TMP/unowned")"

full_sha="$(sha256sum "$OUT/conditional-full-1.normalized.json" | awk '{print $1}')"
no_charm_sha="$(sha256sum "$OUT/conditional-no-charm-1.normalized.json" | awk '{print $1}')"
replay_sha="$(jq -r '.sha256' "$OUT/replay/summary.json")"
jq -n \
  --arg sentinel TD_OBS_CHECK_PASS \
  --arg status PASS \
  --argjson tests "$test_count" \
  --argjson assertions "$assert_count" \
  --arg replay_sha256 "$replay_sha" \
  --arg full_sha256 "$full_sha" \
  --arg no_charm_sha256 "$no_charm_sha" \
  --slurpfile full "$full" \
  --slurpfile no_charm "$no_charm" \
  --argjson duration_exit "$(cat "$TMP/duration.exit")" \
  --argjson missing_exit "$(cat "$TMP/missing.exit")" \
  --argjson watchdog_exit "$(cat "$TMP/watchdog.exit")" \
  '{sentinel:$sentinel,status:$status,tests:$tests,assertions:$assertions,
    replay_sha256:$replay_sha256,
    baseline:{full:{result:"clear",leaked:2,tick:1319},no_charm:{result:"defeat",leaked:4,tick:1267}},
    conditional:{
      full:{result:$full[0].meta.bot_summary.result,leaked:$full[0].meta.bot_summary.leaked,
        terminal_tick:$full[0].meta.bot_summary.terminal_tick,
        model_hash:$full[0].meta.bot_summary.model_hash,
        observation_sequence_sha256:$full[0].meta.bot_summary.observation_sequence_sha256,
        trace_sha256:$full[0].meta.bot_summary.trace_sha256,
        normalized_sha256:$full_sha256},
      no_charm:{result:$no_charm[0].meta.bot_summary.result,leaked:$no_charm[0].meta.bot_summary.leaked,
        terminal_tick:$no_charm[0].meta.bot_summary.terminal_tick,
        model_hash:$no_charm[0].meta.bot_summary.model_hash,
        observation_sequence_sha256:$no_charm[0].meta.bot_summary.observation_sequence_sha256,
        trace_sha256:$no_charm[0].meta.bot_summary.trace_sha256,
        normalized_sha256:$no_charm_sha256}},
    stop_probes:{duration_reached:$duration_exit,bot_load_failed:$missing_exit,
      watchdog_max_ticks:$watchdog_exit}}' >"$OUT/summary.json"

echo "[td-obs] PASS tests=$test_count assertions=$assert_count full_sha=$full_sha no_charm_sha=$no_charm_sha"
exit 0
