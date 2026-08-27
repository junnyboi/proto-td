#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-${ROOT}/build/web/content-packs}"
mkdir -p "$OUT"
find "$OUT" -maxdepth 1 -type f \( -name '*.zip' -o -name 'manifest.tsv' \) -delete

manifest="$OUT/manifest.tsv"
printf 'key\tfile\tbytes\tsha256\tresources\n' > "$manifest"

stage_pack() {
  local key="$1"
  local expected_count="$2"
  shift 2
  local target="$OUT/${key}.zip"
  local -a files=("$@")
  if [[ "${#files[@]}" -ne "$expected_count" ]]; then
    printf 'Expected %d resources for %s, found %d\n' "$expected_count" "$key" "${#files[@]}" >&2
    exit 1
  fi
  (
    cd "$ROOT"
    zip -q -0 -X "$target" "${files[@]}"
  )
  local bytes sha
  bytes="$(stat -c %s "$target")"
  sha="$(sha256sum "$target" | cut -d' ' -f1)"
  printf '%s\t%s\t%s\t%s\t%s\n' "$key" "$(basename "$target")" "$bytes" "$sha" "$expected_count" >> "$manifest"
}

mapfile -t enemy_files < <(cd "$ROOT" && find assets/enemy-variants -maxdepth 1 -type f -name '*.webp' -printf '%p\n' | sort)
stage_pack enemy-variants 24 "${enemy_files[@]}"

classes=(
  banner_guard defender gunner immovable mage_apprentice shock_trooper
  sniper sorcerer sword_saint swordmaster witch_doctor
)
for class_id in "${classes[@]}"; do
  mapfile -t class_files < <(
    cd "$ROOT" && find "assets/sprites/operators/animated/${class_id}" -mindepth 2 -maxdepth 2 -type f -name '*.webp' -printf '%p\n' | sort
  )
  key="operator-${class_id//_/-}"
  stage_pack "$key" 16 "${class_files[@]}"
done

[[ "$(tail -n +2 "$manifest" | wc -l)" -eq 12 ]]
printf 'Staged 12 verified Web content packs in %s\n' "$OUT"
