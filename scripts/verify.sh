#!/bin/bash
# The single verification entrypoint (continuous-testing design, Layer 3).
#   verify.sh              R2 import -> stage lint -> R3 GUT -> R4a scenarios headless
#   verify.sh --full       + R4b scenarios windowed w/ shots -> R5 bots -> R6 gate
#   verify.sh --scenario=X R2 -> R4 for one scenario (inner-loop iteration)
#   verify.sh --scenario=X --windowed   ... + the windowed lane for that scenario
# Stops at the first red rung, prints its native error text, exit = rung
# result. Writes artifacts/verify.json: one line per rung.
set -u
GODOT="${GODOT:-$HOME/bin/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p artifacts

FULL=0
ONLY=""
WINDOWED=0
for arg in "$@"; do
  case "$arg" in
    --full) FULL=1 ;;
    --scenario=*) ONLY="${arg#--scenario=}" ;;
    --windowed) WINDOWED=1 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done
if [[ $WINDOWED -eq 1 && -z "$ONLY" ]]; then
  echo "--windowed requires --scenario=X (the full windowed lane is --full)" >&2
  exit 2
fi

# Quiet windows (PAINPOINTS Phase 13): windowed rungs on a human's machine
# must never steal keyboard/mouse focus. override.cfg applies the no_focus
# flag at window CREATION (a runtime flag is too late — the steal already
# happened); it exists only while harness windows run, so human playtests
# keep normal focus. The trap removes it on every exit path.
QUIET=0
quiet_windows() {
  if [[ $QUIET -eq 0 ]]; then
    printf '[display]\nwindow/size/no_focus=true\n' > override.cfg
    QUIET=1
  fi
}
cleanup_quiet() { [[ $QUIET -eq 1 ]] && rm -f override.cfg; }
trap cleanup_quiet EXIT

RESULTS="[]"
record() { # rung status seconds artifact
  RESULTS=$(jq -c --arg r "$1" --arg s "$2" --argjson t "$3" --arg a "$4" \
    '. + [{rung: $r, status: $s, seconds: $t, artifact: $a}]' <<< "$RESULTS")
}
finish() { # exit_code
  echo "$RESULTS" | jq '.' > artifacts/verify.json
  exit "$1"
}
p16_suite_gate() {
	local text="$1" path expected summary
	while read -r path expected; do
		summary=$(awk -v suite="$path" '
			{
				clean=$0
				gsub(/\033\[[0-?]*[ -\/]*[@-~]/, "", clean)
			}
			clean == suite { active=1; next }
			active && clean ~ /^res:\/\/test\/[^[:space:]]+\.gd$/ { exit }
			active && clean ~ /^[0-9]+\/[0-9]+ passed\.$/ {
				count += 1
				value=clean
			}
			END {
				if (count == 1) print value
				else print "__INVALID_SUMMARY_COUNT__"
			}
		' <<< "$text")
		[[ "$summary" == "$expected" ]] || return 1
	done <<'EOF'
res://test/test_p16_contract_fixtures.gd 15/15 passed.
res://test/test_replay_codec.gd 5/5 passed.
EOF
}
P16_GATE_GOOD=$'res://test/test_p16_contract_fixtures.gd\n15/15 passed.\nres://test/test_replay_codec.gd\n5/5 passed.'
P16_GATE_BAD=$'res://test/test_dp_economy.gd\n15/15 passed.\nres://test/test_replay_codec.gd\n5/5 passed.'
P16_GATE_INJECTED=$'res://test/test_p16_contract_fixtures.gd\nWARNING: 15/15 passed.\n15/15 passed.\n14/15 passed.\nres://test/test_replay_codec.gd\n5/5 passed.\n4/5 passed.'
P16_GATE_CSI=$'res://test/test_p16_contract_fixtures.gd\n15/15 passed.\n\e[2K14/15 passed.\nres://test/test_replay_codec.gd\n5/5 passed.'
p16_suite_gate "$P16_GATE_GOOD" || { echo '[verify] P16 suite gate self-test false red' >&2; exit 2; }
if p16_suite_gate "$P16_GATE_BAD"; then
	echo '[verify] P16 suite gate self-test accepted an unrelated count' >&2
	exit 2
fi
if p16_suite_gate "$P16_GATE_INJECTED"; then
	echo '[verify] P16 suite gate self-test accepted injected or duplicate summaries' >&2
	exit 2
fi
if p16_suite_gate "$P16_GATE_CSI"; then
	echo '[verify] P16 suite gate self-test accepted a CSI-prefixed wrong summary' >&2
	exit 2
fi
run_rung() { # rung_name artifact_hint timeout_s cmd...
  local rung="$1" artifact="$2" budget="$3"
  shift 3
  local t0 t1 out code
  t0=$(date +%s)
  out=$(timeout "$budget" "$@" 2>&1)
  code=$?
  t1=$(date +%s)
  if [[ "$rung" == "R3-gut" && $code -eq 0 ]]; then
    local tests
    tests=$(grep -Eo 'Tests[[:space:]]+[0-9]+' <<< "$out" | tail -1 | awk '{print $2}')
    if [[ -z "$tests" || "$tests" -eq 0 ]]; then
      code=1
      out+=$'\n[verify] GUT reported zero tests or no parseable test count'
    fi
    if grep -Eq 'SCRIPT ERROR:|Nothing was run|Errors[[:space:]]+[1-9][0-9]*' <<< "$out"; then
      code=1
      out+=$'\n[verify] GUT reported framework, parser, or discovery errors'
    fi
    if ! p16_suite_gate "$out"; then
      code=1
      out+=$'\n[verify] required P16 suite-specific exact count missing'
    fi
  fi
  if [[ $code -ne 0 ]]; then
    echo "==== $rung FAILED (exit $code) ===="
    echo "$out"
    record "$rung" "fail" $((t1 - t0)) "$artifact"
    finish $code
  fi
  record "$rung" "pass" $((t1 - t0)) "$artifact"
  echo "[verify] $rung pass ($((t1 - t0))s)"
}

# R2: import + project sanity
run_rung "R2-import" "" 120 "$GODOT" --headless --path . --import

# R2.5: stage data lint (exists from Phase 1 on)
if [[ -f tools/stage_lint.gd ]]; then
  run_rung "R2.5-stage-lint" "" 60 "$GODOT" --headless --path . -s tools/stage_lint.gd
fi

# R3: GUT unit tests
if [[ -z "$ONLY" ]]; then
  run_rung "R3-gut" "" 300 "$GODOT" --headless -d -s addons/gut/gut_cmdln.gd \
    -gdir=res://test -ginclude_subdirs -gexit
  run_rung "R3.5-replay" "artifacts/replay/summary.json" 35 scripts/replay_check.sh
  run_rung "R3.6-filesystem-native" "artifacts/filesystem/native.json" 35 \
    scripts/probe_filesystem.sh "$GODOT" --out=artifacts/filesystem/native.json
  run_rung "R3.7-filesystem-web" "artifacts/filesystem/web/result.json" 360 \
    scripts/probe_filesystem.sh "$GODOT" --web --out=artifacts/filesystem/web
fi

# R4: scenarios. Headless lane always; windowed lane with --full.
scenario_cmd() { # lane scenario
  local lane="$1" s="$2"
  if [[ "$lane" == "headless" ]]; then
    run_rung "R4a-$s" "artifacts/$s/report.json" 120 \
      "$GODOT" --headless --fixed-fps 60 --path . -s selftest/harness.gd -- \
      --scenario="$s" --seed=42 --shots="res://artifacts/$s"
  else
    run_rung "R4b-$s" "artifacts/$s/report.json" 120 \
      "$GODOT" --path . --resolution 1280x720 -s selftest/harness.gd -- \
      --scenario="$s" --seed=42 --shots="res://artifacts/$s"
  fi
}

SCENARIOS=()
[[ -f selftest/scenarios/p16_contract_probe.gd ]] || {
  echo '[verify] required p16_contract_probe scenario missing' >&2
  finish 1
}
for f in selftest/scenarios/*.gd; do
  [[ -e "$f" ]] || continue
  name="$(basename "$f" .gd)"
  [[ "$name" == wip_* ]] && continue
  if [[ -n "$ONLY" && "$name" != "$ONLY" ]]; then continue; fi
  SCENARIOS+=("$name")
done
for s in "${SCENARIOS[@]}"; do
  scenario_cmd headless "$s"
done
if [[ $WINDOWED -eq 1 ]]; then
  quiet_windows
  for s in "${SCENARIOS[@]}"; do
    scenario_cmd windowed "$s"
  done
fi

if [[ $FULL -eq 1 ]]; then
  quiet_windows
  for s in "${SCENARIOS[@]}"; do
    scenario_cmd windowed "$s"
  done
  # R5: all bots, headless lane
  for f in playtests/bots/bot_*.gd; do
    name="$(basename "$f" .gd)"
    [[ "$name" == "bot_base" ]] && continue
    run_rung "R5-$name" "artifacts/telemetry.json" 600 scripts/playtest.sh "$name" --ticks 3600
    # R6: quality gate over this bot's telemetry
    run_rung "R6-gate-$name" "artifacts/gate.json" 30 scripts/quality_gate.sh
  done
fi

echo "[verify] ALL GREEN"
finish 0
