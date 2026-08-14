#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT:-$HOME/bin/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${TD_MITIGATION_OUT:-$ROOT/artifacts/td-mitigation}"
FIXTURE="$ROOT/test/fixtures/mitigation_legacy_v1.json"
OBS_FIXTURE="$ROOT/test/fixtures/targeting_compat_v1.json"
cd "$ROOT"
mkdir -p "$OUT"
rm -rf "$OUT"/*

fail() {
  echo "[td-mitigation] FAIL: $*" >&2
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
[[ -s "$FIXTURE" ]] || fail "frozen mitigation fixture is missing"
[[ -s "$OBS_FIXTURE" ]] || fail "frozen TD-OBS fixture is missing"

production=(
  sim/damage_rules.gd
  sim/combat_content_binding.gd
  sim/campaign_context_validator.gd
  data/operator_def.gd
  data/enemy_def.gd
  data/spell_def.gd
  data/trap_def.gd
  sim/unit_state.gd
  sim/enemy_state.gd
  sim/trap_state.gd
  sim/spell_book.gd
  sim/battle_model.gd
  sim/battle_hash.gd
  sim/battle_snapshot.gd
  sim/campaign_state.gd
  sim/campaign_codec.gd
  sim/campaign_hash.gd
  sim/campaign_save_upgrade.gd
  sim/campaign_migration.gd
)
tests=(
  test/test_damage_rules.gd
  test/test_mitigation_paths.gd
  test/test_mitigation_persistence.gd
  test/test_hash_paranoia.gd
  test/test_damage_stagger.gd
  test/test_combat.gd
  test/test_composition.gd
  test/test_spells.gd
  test/test_traps.gd
  test/test_charm.gd
  test/test_battle_observation.gd
  test/test_replay_codec.gd
  test/test_campaign_state_p16.gd
  test/test_campaign_save_store.gd
  test/test_campaign_progression.gd
  test/test_campaign_state.gd
  test/test_campaign_resolution.gd
  test/test_campaign_commands.gd
  test/test_game_campaign_compat.gd
  test/test_mage_promotion_contract.gd
  test/test_p16_contract_fixtures.gd
  test/test_witch_doctor.gd
  test/test_target_policy_catalog.gd
  test/test_presentation_contracts.gd
)
scenario="selftest/scenarios/mitigation_counter.gd"
probe="test/support/mitigation_legacy_probe.gd"
all_gd=("${production[@]}" "${tests[@]}" "$scenario" "$probe")
for path in "${all_gd[@]}"; do
  [[ -f "$path" ]] || fail "missing TD-MITIGATION file: $path"
  [[ -f "$path.uid" ]] || fail "missing UID file: $path.uid"
done
for path in \
  data/enemies/test_high_def.tres \
  data/enemies/test_high_res.tres \
  data/stages/test_mitigation.tres; do
  [[ -s "$path" ]] || fail "missing mitigation fixture resource: $path"
done

# Only the pure resolution seam may translate raw damage into HP loss. Enemy
# and unit writes stay at their two established model-owned mutation seams.
mapfile -t hp_writes < <(rg -n '\.hp\s*-=' sim -g '*.gd')
[[ "${#hp_writes[@]}" -eq 2 ]] \
  || fail "expected exactly two model-owned HP subtraction seams"
printf '%s\n' "${hp_writes[@]}" >"$OUT/hp-write-audit.log"
grep -F 'sim/enemy_damage.gd:' "$OUT/hp-write-audit.log" >/dev/null \
  || fail "enemy damage seam is missing"
grep -F 'sim/battle_model.gd:' "$OUT/hp-write-audit.log" >/dev/null \
  || fail "unit damage seam is missing"
rg -n 'DamageRulesScript\.resolve\(' sim/battle_model.gd >"$OUT/damage-route-audit.log"
[[ "$(wc -l <"$OUT/damage-route-audit.log")" -eq 2 ]] \
  || fail "battle damage is not routed through both mitigation seams"

run 180 "$GODOT" --headless --path . --import >"$OUT/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script|Could not resolve' "$OUT/import.log"; then
  fail "import reported script errors"
fi
gdlint "${all_gd[@]}" >"$OUT/gdlint.log" 2>&1

gut_args=()
for path in "${tests[@]}"; do
  gut_args+=("-gtest=res://$path")
done
run 360 "$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd \
  -gconfig= "${gut_args[@]}" -gexit -gdisable_colors >"$OUT/gut.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Nothing was run|Errors[[:space:]]+[1-9][0-9]*' "$OUT/gut.log"; then
  fail "GUT reported framework, parser, or discovery errors"
fi
test_count="$(grep -E '^Tests[[:space:]]+[0-9]+$' "$OUT/gut.log" | tail -1 | awk '{print $2}')"
assert_count="$(grep -E '^Asserts[[:space:]]+[0-9]+$' "$OUT/gut.log" | tail -1 | awk '{print $2}')"
[[ -n "$test_count" && "$test_count" -ge 120 ]] \
  || fail "GUT reported fewer than 120 tests"
[[ -n "$assert_count" && "$assert_count" -ge 500000 ]] \
  || fail "GUT reported fewer than 500000 assertions"

run 120 "$GODOT" --headless --path . -s "$probe" -- "$OUT/legacy-a.json" \
  >"$OUT/legacy-a.log" 2>&1
run 120 "$GODOT" --headless --path . -s "$probe" -- "$OUT/legacy-b.json" \
  >"$OUT/legacy-b.log" 2>&1
cmp "$FIXTURE" "$OUT/legacy-a.json" \
  || fail "legacy damage outputs or hashes drifted"
cmp "$OUT/legacy-a.json" "$OUT/legacy-b.json" \
  || fail "cross-process legacy damage proof diverged"

rm -rf "$OUT/scenario"
mkdir -p "$OUT/scenario"
run 90 "$GODOT" --headless --fixed-fps 60 --path . -s selftest/harness.gd -- \
  --scenario=mitigation_counter --seed=42 \
  --shots="res://${OUT#"$ROOT/"}/scenario" >"$OUT/scenario.log" 2>&1
[[ -s "$OUT/scenario/report.json" ]] || fail "scenario report is missing"
jq -e '.result == "pass" and (.checks | length) == 6 and all(.checks[]; .ok)' \
  "$OUT/scenario/report.json" >/dev/null || fail "mitigation_counter failed"

rm -f artifacts/telemetry.json
run 90 scripts/playtest.sh bot_stage_06_conditional --ticks 1800 \
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
' "$OBS_FIXTURE" >/dev/null || fail "frozen TD-OBS compatibility oracle drifted"

run 90 scripts/replay_check.sh --out="${OUT#"$ROOT/"}/replay" >"$OUT/replay.log" 2>&1
[[ -s "$OUT/replay/summary.json" ]] || fail "replay summary is missing"
jq -e '.status == "PASS" and .sentinel == "REPLAY_CHECK_OK" and .identical == true' \
  "$OUT/replay/summary.json" >/dev/null || fail "replay proof failed"

fixture_sha="$(sha256sum "$FIXTURE" | awk '{print $1}')"
scenario_sha="$(sha256sum "$OUT/scenario/report.json" | awk '{print $1}')"
replay_sha="$(jq -r '.sha256' "$OUT/replay/summary.json")"
binding_sha="$(jq -r '.rows[0].model_hash' "$FIXTURE")"
jq -n \
  --arg sentinel TD_MITIGATION_CHECK_PASS \
  --arg status PASS \
  --argjson tests "$test_count" \
  --argjson assertions "$assert_count" \
  --arg fixture_sha256 "$fixture_sha" \
  --arg scenario_sha256 "$scenario_sha" \
  --arg replay_sha256 "$replay_sha" \
  --arg legacy_operator_hash "$binding_sha" \
  --slurpfile scenario "$OUT/scenario/report.json" \
  --slurpfile actual "$OUT/conditional.json" \
  '{sentinel:$sentinel,status:$status,tests:$tests,assertions:$assertions,
    fixture_sha256:$fixture_sha256,scenario_sha256:$scenario_sha256,
    replay_sha256:$replay_sha256,legacy_operator_hash:$legacy_operator_hash,
    counter_checks:$scenario[0].checks,
    td_obs:{model_hash:$actual[0].meta.bot_summary.model_hash,
      observation_sequence_sha256:$actual[0].meta.bot_summary.observation_sequence_sha256,
      trace_sha256:$actual[0].meta.bot_summary.trace_sha256}}' >"$OUT/summary.json"

echo "[td-mitigation] PASS tests=$test_count assertions=$assert_count fixture=$fixture_sha"
exit 0
