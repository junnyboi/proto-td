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
WEB_TEMPLATE_SOURCE="$HOME/.local/share/godot/export_templates/4.7.1.stable/web_nothreads_release.zip"
WEB_TEMPLATE_SHA256="b7b7d7da29fc6cc2f4934fdd26cc571a40e7af57f716ea3eb7e18da720dae28a"
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
VERIFY_USER_ROOT=""
quiet_windows() {
  if [[ $QUIET -eq 0 ]]; then
    printf '[display]\nwindow/size/no_focus=true\n' > override.cfg
    QUIET=1
  fi
}
cleanup_quiet() { [[ $QUIET -eq 1 ]] && rm -f override.cfg; }
cleanup_verify() {
	cleanup_quiet
	if [[ -n "$VERIFY_USER_ROOT" ]]; then
		chmod -R u+w "$VERIFY_USER_ROOT" 2>/dev/null || true
		rm -rf "$VERIFY_USER_ROOT"
	fi
	git -C "$ROOT" worktree prune >/dev/null 2>&1 || true
}
trap cleanup_verify EXIT
VERIFY_USER_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/prototype-td-verify.XXXXXX")"

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
res://test/test_hero_state.gd 3/3 passed.
res://test/test_roster_state.gd 5/5 passed.
res://test/test_campaign_state_p16.gd 11/11 passed.
res://test/test_campaign_runtime_cutover.gd 9/9 passed.
res://test/test_campaign_v3_recruitment.gd 4/4 passed.
res://test/test_game_campaign_compat.gd 3/3 passed.
res://test/test_campaign_commands.gd 12/12 passed.
res://test/test_campaign_resolution.gd 10/10 passed.
res://test/test_campaign_save_store.gd 22/22 passed.
EOF
}
P16_GATE_TAIL=$'res://test/test_replay_codec.gd\n5/5 passed.\nres://test/test_hero_state.gd\n3/3 passed.\nres://test/test_roster_state.gd\n5/5 passed.\nres://test/test_campaign_state_p16.gd\n11/11 passed.\nres://test/test_campaign_runtime_cutover.gd\n9/9 passed.\nres://test/test_campaign_v3_recruitment.gd\n4/4 passed.\nres://test/test_game_campaign_compat.gd\n3/3 passed.\nres://test/test_campaign_commands.gd\n12/12 passed.\nres://test/test_campaign_resolution.gd\n10/10 passed.\nres://test/test_campaign_save_store.gd\n22/22 passed.'
P16_GATE_GOOD=$'res://test/test_p16_contract_fixtures.gd\n15/15 passed.\n'"$P16_GATE_TAIL"
P16_GATE_BAD=$'res://test/test_dp_economy.gd\n15/15 passed.\n'"$P16_GATE_TAIL"
P16_GATE_INJECTED=$'res://test/test_p16_contract_fixtures.gd\nWARNING: 15/15 passed.\n15/15 passed.\n14/15 passed.\n'"$P16_GATE_TAIL"
P16_GATE_CSI=$'res://test/test_p16_contract_fixtures.gd\n15/15 passed.\n\e[2K14/15 passed.\n'"$P16_GATE_TAIL"
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
property_suite_gate() {
	local text="$1" segment="$2" clean expected actual
	clean=$(awk '{ gsub(/\033\[[0-?]*[ -\/]*[@-~]/, ""); print }' <<< "$text")
	[[ "$(grep -Ec '^[0-9]+/[0-9]+ passed\.$' <<< "$clean")" -eq 1 ]] || return 1
	[[ "$(grep -Fxc '2/2 passed.' <<< "$clean")" -eq 1 ]] || return 1
	case "$segment" in
		subsets)
			expected=$'    P16_RECOVERY_SUBSETS=296\n    P16_RECOVERY_ACCEPTS=812'
			;;
		first) expected='    P16_ROSTER_SEGMENT=0:512' ;;
		second) expected='    P16_ROSTER_SEGMENT=512:768' ;;
		third) expected='    P16_ROSTER_SEGMENT=768:896' ;;
		fourth)
			expected=$'    P16_ROSTER_LIMIT_CYCLES=1019\n    P16_ROSTER_LIMIT_RENAMES=1024\n    P16_ROSTER_SEGMENT=896:1019'
			;;
		*) return 1 ;;
	esac
	actual=$(grep -E '^    P16_' <<< "$clean" || true)
	[[ "$actual" == "$expected" ]]
}
PROPERTY_GATE_SUBSETS=$'2/2 passed.\n    P16_RECOVERY_SUBSETS=296\n    P16_RECOVERY_ACCEPTS=812'
PROPERTY_GATE_FIRST=$'2/2 passed.\n    P16_ROSTER_SEGMENT=0:512'
PROPERTY_GATE_SECOND=$'2/2 passed.\n    P16_ROSTER_SEGMENT=512:768'
PROPERTY_GATE_THIRD=$'2/2 passed.\n    P16_ROSTER_SEGMENT=768:896'
PROPERTY_GATE_FOURTH=$'2/2 passed.\n    P16_ROSTER_LIMIT_CYCLES=1019\n    P16_ROSTER_LIMIT_RENAMES=1024\n    P16_ROSTER_SEGMENT=896:1019'
property_suite_gate "$PROPERTY_GATE_SUBSETS" subsets || exit 2
property_suite_gate "$PROPERTY_GATE_FIRST" first || exit 2
property_suite_gate "$PROPERTY_GATE_SECOND" second || exit 2
property_suite_gate "$PROPERTY_GATE_THIRD" third || exit 2
property_suite_gate "$PROPERTY_GATE_FOURTH" fourth || exit 2
if property_suite_gate "$PROPERTY_GATE_FOURTH"$'\n    P16_ROSTER_LIMIT_RENAMES=1024' fourth; then
	echo '[verify] P16 property gate accepted a duplicate sentinel' >&2
	exit 2
fi
if property_suite_gate "${PROPERTY_GATE_FOURTH/1019/1018}" fourth; then
	echo '[verify] P16 property gate accepted a wrong cycle count' >&2
	exit 2
fi
property_suite_gate $'\e[4m'"$PROPERTY_GATE_SUBSETS"$'\e[0m' subsets || {
	echo '[verify] P16 property gate rejected valid ANSI-decorated output' >&2
	exit 2
}
if property_suite_gate "$PROPERTY_GATE_FIRST"$'\n\e[2K1/2 passed.' first; then
	echo '[verify] P16 property gate accepted a CSI-prefixed extra summary' >&2
	exit 2
fi
run_rung() { # rung_name artifact_hint timeout_s cmd...
	local rung="$1" artifact="$2" budget="$3"
	shift 3
	local t0 t1 out code user_key user_root
	user_key=$(tr -c 'A-Za-z0-9_.-' '_' <<< "$rung")
	user_root="$VERIFY_USER_ROOT/$user_key"
	rm -rf "$user_root"
	mkdir -p "$user_root/data/godot" "$user_root/config" "$user_root/cache" "$user_root/work"
	if [[ "$rung" == "R3.7-filesystem-web" ]]; then
		local template_dir template_copy
		template_dir="$user_root/data/godot/export_templates/4.7.1.stable"
		template_copy="$template_dir/web_nothreads_release.zip"
		if ! printf '%s  %s\n' "$WEB_TEMPLATE_SHA256" "$WEB_TEMPLATE_SOURCE" \
			| sha256sum -c - >/dev/null 2>&1; then
			echo "[verify] missing or invalid pinned Web export template" >&2
			finish 2
		fi
		mkdir -p "$template_dir"
		install -m 0444 "$WEB_TEMPLATE_SOURCE" "$template_copy"
		if ! printf '%s  %s\n' "$WEB_TEMPLATE_SHA256" "$template_copy" \
			| sha256sum -c - >/dev/null 2>&1; then
			echo "[verify] isolated Web export template copy failed verification" >&2
			finish 2
		fi
		chmod 0555 "$user_root/data/godot/export_templates" "$template_dir"
	fi
	t0=$(date +%s)
	out=$(timeout "$budget" env \
		XDG_DATA_HOME="$user_root/data" XDG_CONFIG_HOME="$user_root/config" \
		XDG_CACHE_HOME="$user_root/cache" MGS_RUNG_ROOT="$user_root/work" \
		"$@" 2>&1)
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
	if [[ "$rung" == R3.1-p16-properties-* && $code -eq 0 ]]; then
			local property_segment="${rung##*-}"
			if ! property_suite_gate "$out" "$property_segment"; then
			code=1
			out+=$'\n[verify] P16 property count or exact sentinel missing/duplicated'
		fi
	fi
	if [[ "$rung" =~ ^R4[ab]-strategic_verbs$ && $code -eq 0 ]]; then
		local clean sentinel_count
		clean=$(awk '{ gsub(/\033\[[0-?]*[ -\/]*[@-~]/, ""); print }' <<< "$out")
		sentinel_count=$(grep -Fxc 'STRATEGIC_VERBS_COMPLETED' <<< "$clean")
		if [[ "$sentinel_count" -ne 1 ]]; then
			code=1
			out+=$'\n[verify] strategic_verbs sentinel missing or duplicated'
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

# R2.1: tracked font source must compile without its disposable .fontdata cache.
run_rung "R2.1-font-cold-cache" "" 60 scripts/probe_font_cache_fallback.sh "$GODOT"

# R2.5: stage data lint (exists from Phase 1 on)
if [[ -f tools/stage_lint.gd ]]; then
  run_rung "R2.5-stage-lint" "" 60 "$GODOT" --headless --path . -s tools/stage_lint.gd
fi

# R3: GUT unit tests
if [[ -z "$ONLY" ]]; then
		GUT_ARGS=()
		while read -r test_path; do
			[[ "$test_path" == "test/test_campaign_recovery_property.gd" ]] && continue
			GUT_ARGS+=("-gtest=res://$test_path")
		done < <(find test -type f -name 'test_*.gd' | sort)
		run_rung "R3-gut" "" 300 "$GODOT" --headless -d \
		  -s addons/gut/gut_cmdln.gd "${GUT_ARGS[@]}" -gexit
			for property_segment in subsets first second third fourth; do
				run_rung "R3.1-p16-properties-$property_segment" "" 300 env \
				  P16_PROPERTY_SEGMENT="$property_segment" "$GODOT" --headless -d \
				  -s addons/gut/gut_cmdln.gd \
				  -gtest=res://test/test_campaign_recovery_property.gd -gexit
			done
	run_rung "R3.5-replay" "artifacts/replay/summary.json" 35 scripts/replay_check.sh
	run_rung "R3.5-replay-v2" "artifacts/replay-v2/summary.json" 35 \
	  scripts/replay_v2_check.sh artifacts/replay-v2
		run_rung "R3.5-model-roster" "artifacts/model-roster/summary.json" 35 \
		  scripts/model_roster_check.sh
		run_rung "R3.5-strategic-verbs" "artifacts/strategic-verbs/summary.json" 35 \
		  scripts/strategic_verbs_check.sh
		run_rung "R3.5-strategic-verbs-v3" "artifacts/strategic-verbs-v3/summary.json" 35 \
		  scripts/strategic_verbs_v3_check.sh
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
[[ -f selftest/scenarios/model_roster_probe.gd ]] || {
	echo '[verify] required model_roster_probe scenario missing' >&2
	finish 1
}
[[ -f selftest/scenarios/strategic_verbs.gd ]] || {
	echo '[verify] required strategic_verbs scenario missing' >&2
	finish 1
}
for f in selftest/scenarios/*.gd; do
  [[ -e "$f" ]] || continue
  name="$(basename "$f" .gd)"
  [[ "$name" == wip_* ]] && continue
  if [[ -n "$ONLY" && "$name" != "$ONLY" ]]; then continue; fi
	SCENARIOS+=("$name")
done
strategic_count=0
for s in "${SCENARIOS[@]}"; do
	[[ "$s" == "strategic_verbs" ]] && strategic_count=$((strategic_count + 1))
done
if [[ -z "$ONLY" && "$strategic_count" -ne 1 ]]; then
	echo '[verify] strategic_verbs scenario discovery count is not exactly one' >&2
	finish 1
fi
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
	run_rung "R3.8-stale-class-registry" "" 480 scripts/probe_stale_class_registry.sh
	run_rung "R3.9-music-cold-boot" "" 240 scripts/cold_boot_check.sh
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
