#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT:-$HOME/bin/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${TD_TARGET_OUT:-$ROOT/artifacts/td-target}"
FIXTURE="$ROOT/test/fixtures/targeting_compat_v1.json"
cd "$ROOT"
mkdir -p "$OUT"
rm -rf "$OUT"/*

fail() {
  echo "[td-target] FAIL: $*" >&2
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
[[ -s "$FIXTURE" ]] || fail "frozen compatibility fixture is missing"

production=(
  data/target_policy_def.gd
  data/operator_def.gd
  data/enemy_def.gd
  sim/targeting.gd
  sim/target_decision_projection.gd
  sim/unit_state.gd
  sim/enemy_state.gd
  sim/battle_model.gd
)
tests=(
  test/test_targeting.gd
  test/test_target_policy_catalog.gd
  test/test_targeting_compatibility.gd
  test/test_composition.gd
  test/test_battle_observation.gd
  test/test_hash_paranoia.gd
  test/test_recruit_balance_probe.gd
  test/test_presentation_contracts.gd
)
scenario="selftest/scenarios/target_policy_compat.gd"
all_gd=("${production[@]}" "${tests[@]}" "$scenario")
for path in "${all_gd[@]}"; do
  [[ -f "$path" ]] || fail "missing TD-TARGET file: $path"
  [[ -f "$path.uid" ]] || fail "missing UID file: $path.uid"
done

policy_count="$(find data/target_policies -maxdepth 1 -type f -name '*.tres' | wc -l)"
[[ "$policy_count" -eq 6 ]] || fail "expected six target policies, found $policy_count"
operator_count="$(find data/operators -maxdepth 1 -type f -name '*.tres' | wc -l)"
enemy_count="$(find data/enemies -maxdepth 1 -type f -name '*.tres' | wc -l)"
operator_assignments="$(grep -l '^target_policy = ' data/operators/*.tres | wc -l)"
enemy_assignments="$(grep -l '^target_policy = ' data/enemies/*.tres | wc -l)"
[[ "$operator_assignments" -eq "$operator_count" ]] \
  || fail "not every operator has an explicit target policy"
[[ "$enemy_assignments" -eq "$enemy_count" ]] \
  || fail "not every enemy has an explicit target policy"
grep -F 'target_policy = ExtResource("2_policy")' \
  test/fixtures/operators/recruit_probe.tres >/dev/null \
  || fail "Recruit compatibility fixture has no explicit target policy"
if rg -n 'Targeting\.select|Targeting\.Filter' sim/battle_model.gd sim/targeting.gd >"$OUT/legacy-paths.log"; then
  fail "legacy class/filter target dispatch remains"
fi

run 120 "$GODOT" --headless --path . --import >"$OUT/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script' "$OUT/import.log"; then
  fail "import reported script errors"
fi
gdlint "${all_gd[@]}" >"$OUT/gdlint.log" 2>&1

gut_args=()
for path in "${tests[@]}"; do
  gut_args+=("-gtest=res://$path")
done
run 180 "$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd \
  -gconfig= "${gut_args[@]}" -gexit -gdisable_colors >"$OUT/gut.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Nothing was run|Errors[[:space:]]+[1-9][0-9]*' "$OUT/gut.log"; then
  fail "GUT reported framework, parser, or discovery errors"
fi
test_count="$(grep -E '^Tests[[:space:]]+[0-9]+$' "$OUT/gut.log" | tail -1 | awk '{print $2}')"
assert_count="$(grep -E '^Asserts[[:space:]]+[0-9]+$' "$OUT/gut.log" | tail -1 | awk '{print $2}')"
[[ -n "$test_count" && "$test_count" -ge 47 ]] \
  || fail "GUT reported fewer than 47 tests"
[[ -n "$assert_count" && "$assert_count" -ge 8688 ]] \
  || fail "GUT reported fewer than 8688 assertions"

rm -rf "$OUT/scenario"
mkdir -p "$OUT/scenario"
run 60 "$GODOT" --headless --fixed-fps 60 --path . -s selftest/harness.gd -- \
  --scenario=target_policy_compat --seed=42 \
  --shots="res://${OUT#"$ROOT/"}/scenario" >"$OUT/scenario.log" 2>&1
[[ -s "$OUT/scenario/report.json" ]] || fail "scenario report is missing"
jq -e '.result == "pass" and (.checks | length) == 6 and all(.checks[]; .ok)' \
  "$OUT/scenario/report.json" >/dev/null || fail "target_policy_compat failed"

rm -f artifacts/telemetry.json
run 60 scripts/playtest.sh bot_stage_06_conditional --ticks 1800 \
  >"$OUT/conditional.log" 2>&1
[[ -s artifacts/telemetry.json ]] || fail "conditional bot produced no telemetry"
cp artifacts/telemetry.json "$OUT/conditional.json"
jq -e --slurpfile actual "$OUT/conditional.json" '
  .observation_baseline as $expected
  | $actual[0].meta.bot_summary as $got
  | $actual[0].meta.stop_reason == "terminal_clear"
    and $got.result == $expected.result
    and $got.leaked == $expected.leaked
    and $got.terminal_tick == $expected.terminal_tick
    and $got.model_hash == $expected.model_hash
    and $got.observation_sequence_sha256 == $expected.observation_sequence_sha256
    and $got.trace_sha256 == $expected.trace_sha256
' "$FIXTURE" >/dev/null || fail "frozen TD-OBS compatibility oracle drifted"

run 60 scripts/replay_check.sh --out="${OUT#"$ROOT/"}/replay" >"$OUT/replay.log" 2>&1
[[ -s "$OUT/replay/summary.json" ]] || fail "replay summary is missing"
jq -e '.status == "PASS" and .sentinel == "REPLAY_CHECK_OK" and .identical == true' \
  "$OUT/replay/summary.json" >/dev/null || fail "replay proof failed"

fixture_sha="$(sha256sum "$FIXTURE" | awk '{print $1}')"
scenario_sha="$(sha256sum "$OUT/scenario/report.json" | awk '{print $1}')"
replay_sha="$(jq -r '.sha256' "$OUT/replay/summary.json")"
jq -n \
  --arg sentinel TD_TARGET_CHECK_PASS \
  --arg status PASS \
  --argjson tests "$test_count" \
  --argjson assertions "$assert_count" \
  --argjson policies "$policy_count" \
  --argjson operators "$operator_count" \
  --argjson enemies "$enemy_count" \
  --arg fixture_sha256 "$fixture_sha" \
  --arg scenario_sha256 "$scenario_sha" \
  --arg replay_sha256 "$replay_sha" \
  --slurpfile fixture "$FIXTURE" \
  --slurpfile actual "$OUT/conditional.json" \
  '{sentinel:$sentinel,status:$status,tests:$tests,assertions:$assertions,
    catalog:{policies:$policies,operators_with_explicit_policy:$operators,
      enemies_with_explicit_policy:$enemies},
    fixture_sha256:$fixture_sha256,scenario_sha256:$scenario_sha256,
    replay_sha256:$replay_sha256,
    compatibility:{expected:$fixture[0].observation_baseline,
      actual:{result:$actual[0].meta.bot_summary.result,
        leaked:$actual[0].meta.bot_summary.leaked,
        terminal_tick:$actual[0].meta.bot_summary.terminal_tick,
        model_hash:$actual[0].meta.bot_summary.model_hash,
        observation_sequence_sha256:$actual[0].meta.bot_summary.observation_sequence_sha256,
        trace_sha256:$actual[0].meta.bot_summary.trace_sha256}}}' >"$OUT/summary.json"

echo "[td-target] PASS tests=$test_count assertions=$assert_count fixture=$fixture_sha"
exit 0
