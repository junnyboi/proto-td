#!/bin/bash
set -euo pipefail

GODOT="${GODOT:-$HOME/bin/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="artifacts/strategic-verbs-v3/summary.json"
for arg in "$@"; do
	case "$arg" in
	--out=*) OUT="${arg#--out=}" ;;
	*) echo "unknown argument: $arg" >&2; exit 2 ;;
	esac
done
if [[ "$OUT" != /* ]]; then OUT="$ROOT/$OUT"; fi
WORK="$(dirname "$OUT")"
mkdir -p "$WORK"
rm -f "$WORK"/run-{1,2}.{log,json} "$WORK"/*.sorted.json

run_once() {
	local ordinal="$1"
	local log="$WORK/run-$ordinal.log"
	local json="$WORK/run-$ordinal.json"
	GODOT_SILENCE_ROOT_WARNING=1 "$GODOT" --headless --path "$ROOT" \
		-s tools/strategic_verbs_v3_runner.gd >"$log" 2>&1
	if grep -Eq 'SCRIPT ERROR|ERROR:|STRATEGIC_VERBS_V3_FAILED' "$log"; then
		cat "$log" >&2
		return 1
	fi
	if [[ "$(grep -c '^STRATEGIC_VERBS_V3_RESULT=' "$log")" -ne 1 ]]; then
		cat "$log" >&2
		return 1
	fi
	sed -n 's/^STRATEGIC_VERBS_V3_RESULT=//p' "$log" >"$json"
	jq -e '
			.save_revision == 5
		and .next_attempt_id == 2
		and .next_resolution_index == 2
			and (.heroes | length) == 6
		and (.tickets | length) == 1
		and (.memorial | length) == 0
		and (.promotion_receipts | length) == 1
			and (.command_receipts | length) == 4
			and ([.command_receipts[].verb] == ["begin_attempt","resolve_attempt","confirm_promotions","recruit_person"])
		and .receipt_texts == .duplicate_receipt_texts
		and .conflict_error == "command_id_conflict"
	' "$json" >/dev/null
}

run_once 1
run_once 2
cmp -s "$WORK/run-1.json" "$WORK/run-2.json"
jq -S -c . "$WORK/run-1.json" >"$WORK/run-1.sorted.json"
jq -S -c . "$ROOT/test/fixtures/p16/strategic_command_vectors_v3.json" \
	>"$WORK/fixture.sorted.json"
cmp -s "$WORK/run-1.sorted.json" "$WORK/fixture.sorted.json"

sha="$(sha256sum "$WORK/run-1.json" | awk '{print $1}')"
jq -n \
	--arg status PASS \
	--arg sha256 "$sha" \
	--arg environment_sha256 "$(jq -r '.environment_sha256' "$WORK/run-1.json")" \
	--arg full_hash "$(jq -r '.final_full_hash' "$WORK/run-1.json")" \
	--arg core_hash "$(jq -r '.final_core_hash' "$WORK/run-1.json")" \
	'{status:$status,processes:2,byte_equal:true,fixture_equal:true,
	  exact_retry_receipts:true,output_sha256:$sha256,
	  environment_sha256:$environment_sha256,final_full_hash:$full_hash,
	  final_core_hash:$core_hash}' >"$OUT"

echo "STRATEGIC_VERBS_V3_OK"
