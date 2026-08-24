#!/bin/bash
set -euo pipefail

GODOT="${GODOT:-$HOME/.local/bin/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="artifacts/strategic-verbs/summary.json"
for arg in "$@"; do
	case "$arg" in
		--out=*) OUT="${arg#--out=}" ;;
		*) echo "unknown argument: $arg" >&2; exit 2 ;;
	esac
done
if [[ "$OUT" != /* ]]; then OUT="$ROOT/$OUT"; fi
WORK="$(dirname "$OUT")"
mkdir -p "$WORK"
rm -f "$WORK"/run-{1,2}.{log,json}

run_once() {
	local ordinal="$1" direction="$2"
	local log="$WORK/run-$ordinal.log"
	local json="$WORK/run-$ordinal.json"
	local args=()
	[[ "$direction" == "reverse" ]] && args=(-- --reverse)
	GODOT_SILENCE_ROOT_WARNING=1 "$GODOT" --headless --path "$ROOT" \
		-s tools/strategic_verbs_runner.gd "${args[@]}" >"$log" 2>&1
	if grep -Eq 'SCRIPT ERROR|ERROR:|STRATEGIC_VERBS_FAILED' "$log"; then
		cat "$log" >&2
		return 1
	fi
	if [[ "$(grep -c '^STRATEGIC_VERBS_RESULT=' "$log")" -ne 1 ]]; then
		cat "$log" >&2
		return 1
	fi
	sed -n 's/^STRATEGIC_VERBS_RESULT=//p' "$log" >"$json"
	jq -e . "$json" >/dev/null
	jq -e '
		(.load_matrix | length) == 17
		and ([.load_matrix[].id] | unique | length) == 17
		and (.precedence | length) == 19
		and ([.precedence[].id] | unique | length) == 19
		and ([.load_matrix[] | has("winner") and has("final_layout")] | all)
		and ([.precedence[] | has("events") and has("payload")] | all)
		and .sibling_cas.first.accepted
		and (.sibling_cas.sibling.accepted | not)
		and .sibling_cas.sibling.error_code == "store_integrity_failure"
		and (.sibling_cas.final_layout | length) >= 1
		and .recovery_totals.stage_subsets == [8,16,16,32,32,64,64,64]
		and .recovery_totals.subsets == 296
		and .recovery_totals.accepted_recruits == 812
		and .recovery_totals.roster_cycles == 1019
		and .recovery_totals.renames == 1024
		and .recovery_totals.max_roster == 1024
	' "$json" >/dev/null
}

run_once 1 forward
run_once 2 reverse
cmp -s "$WORK/run-1.json" "$WORK/run-2.json"
jq -S -c . "$WORK/run-1.json" >"$WORK/run-1.sorted.json"
jq -S -c . "$ROOT/test/fixtures/p16/strategic_command_vectors_v1.json" \
	>"$WORK/fixture.sorted.json"
cmp -s "$WORK/run-1.sorted.json" "$WORK/fixture.sorted.json"

sha="$(sha256sum "$WORK/run-1.json" | awk '{print $1}')"
jq -n \
	--arg status PASS \
	--arg sha256 "$sha" \
	--arg environment_sha256 "$(jq -r '.environment_sha256' "$WORK/run-1.json")" \
	--arg final_hash "$(jq -r '.resolution.strategic_hash' "$WORK/run-1.json")" \
		'{status:$status,processes:2,directions:["forward","reverse"],
		  byte_equal:true,fixture_equal:true,
	  output_sha256:$sha256,environment_sha256:$environment_sha256,
	  final_strategic_hash:$final_hash}' >"$OUT"

echo "STRATEGIC_VERBS_OK"
