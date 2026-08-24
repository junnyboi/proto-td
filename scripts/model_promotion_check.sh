#!/bin/bash
set -euo pipefail

GODOT="${GODOT:-$HOME/.local/bin/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="artifacts/model-promotion/summary.json"
for arg in "$@"; do
  case "$arg" in
    --out=*) OUT="${arg#--out=}" ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done
cd "$ROOT"
mkdir -p "$(dirname "$OUT")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

run_one() {
  local choice="$1" name="$2"
  shift 2
  timeout 30 "$GODOT" --headless --path . -s tools/model_promotion_runner.gd -- \
    "--choice=$choice" "$@" >"$TMP/$choice-$name.log" 2>&1
  grep '^MODEL_PROMOTION_RESULT=' "$TMP/$choice-$name.log" >"$TMP/$choice-$name.result"
  [[ "$(wc -l < "$TMP/$choice-$name.result")" -eq 1 ]]
  sed 's/^MODEL_PROMOTION_RESULT=//' "$TMP/$choice-$name.result" >"$TMP/$choice-$name.json"
  jq -e . "$TMP/$choice-$name.json" >/dev/null
}

for choice in witch_doctor sorcerer; do
  run_one "$choice" normal
  run_one "$choice" reversed --reverse-inputs
  cmp -s "$TMP/$choice-normal.json" "$TMP/$choice-reversed.json"
done
[[ "$(sha256sum "$TMP/witch_doctor-normal.json" | awk '{print $1}')" == \
  "55dfada781a57dff9071e70942792932724ed8c759772b8ce19322e67fe22e72" ]]
[[ "$(sha256sum "$TMP/sorcerer-normal.json" | awk '{print $1}')" == \
  "a755b2d043f69ad59ff25fac38d9268c72c9a1bb874e60e02b5038aafc5eafc4" ]]

jq -e '
  .choice == "witch_doctor"
  and .environment_sha256 == "766d1404bfa53e650cc419c49fde338eb20334611b49a19cd095a789f6f525b5"
  and .hero_id == "7179faeace82abbe"
  and .identity_portrait_id == "caster_1"
  and .acquisition_operator_def_id == "caster_1"
  and .first_class_id == "mage_apprentice"
  and .advanced_class_id == "witch_doctor"
  and .operator_def_id == "witch_doctor_1"
  and .xp == 400
  and .save_revision == 2
  and .after_strategic_hash == "ee7a579263278b80"
  and .before_strategic_hash != .after_strategic_hash
  and .receipt.before_strategic_hash == .before_strategic_hash
  and .receipt.after_strategic_hash == .after_strategic_hash
  and (.results | map(.accepted)) == [true,true,false,false]
  and (.results | map(.error_code)) == ["","","command_id_conflict","already_promoted"]
  and .restart_byte_identical
  and .exact_retry_byte_identical
  and .rejects_hash_equal
' "$TMP/witch_doctor-normal.json" >/dev/null

jq -e '
  .choice == "sorcerer"
  and .environment_sha256 == "766d1404bfa53e650cc419c49fde338eb20334611b49a19cd095a789f6f525b5"
  and .hero_id == "7179faeace82abbe"
  and .identity_portrait_id == "caster_1"
  and .acquisition_operator_def_id == "caster_1"
  and .first_class_id == "mage_apprentice"
  and .advanced_class_id == "sorcerer"
  and .operator_def_id == "caster_2"
  and .xp == 400
  and .save_revision == 2
  and .after_strategic_hash == "2fbef2abbf97215a"
  and .before_strategic_hash != .after_strategic_hash
  and .receipt.before_strategic_hash == .before_strategic_hash
  and .receipt.after_strategic_hash == .after_strategic_hash
  and (.results | map(.accepted)) == [true,true,false,false]
  and (.results | map(.error_code)) == ["","","command_id_conflict","already_promoted"]
  and .restart_byte_identical
  and .exact_retry_byte_identical
  and .rejects_hash_equal
' "$TMP/sorcerer-normal.json" >/dev/null

jq -n \
  --arg verdict pass \
  --arg witch_doctor_sha256 "$(sha256sum "$TMP/witch_doctor-normal.json" | awk '{print $1}')" \
  --arg sorcerer_sha256 "$(sha256sum "$TMP/sorcerer-normal.json" | awk '{print $1}')" \
  --slurpfile witch_doctor "$TMP/witch_doctor-normal.json" \
  --slurpfile sorcerer "$TMP/sorcerer-normal.json" \
  '{verdict:$verdict, processes:4, byte_identical_per_choice:true,
    witch_doctor_sha256:$witch_doctor_sha256, sorcerer_sha256:$sorcerer_sha256,
    branches:{witch_doctor:$witch_doctor[0],sorcerer:$sorcerer[0]}}' > "$OUT"

echo "[model-promotion] PASS (2 choices × 2 fresh processes, byte-identical)"
