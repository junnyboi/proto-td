#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-${ROOT}/build/web/cinematics}"
mkdir -p "$OUT"

manifest="$OUT/manifest.tsv"
printf 'key\tfile\tbytes\tsha256\n' > "$manifest"

stage() {
  local key="$1"
  local bytes="$2"
  local sha="$3"
  local source="$ROOT/assets/cinematics/gacha/video/${key}.ogv"
  local target="$OUT/${key}.ogv"
  test -f "$source"
  test "$(stat -c %s "$source")" = "$bytes"
  test "$(sha256sum "$source" | cut -d' ' -f1)" = "$sha"
  cp "$source" "$target"
  printf '%s\t%s\t%s\t%s\n' "$key" "$(basename "$target")" "$bytes" "$sha" >> "$manifest"
}

stage archive-caster-landscape 778793 bcb3251e11269027b49a332487964db64fb8e6fe83358c2bb1b78317558c55af
stage archive-caster-portrait 2452205 dd09537610bb5bc0ed7fd2ed6715e4d6b870dce521075b1defe77c6bc6ee0c0f
stage lunaris-vessel-landscape 1257821 38361f28ba7c40e8e95c5aa59919028b0d181d97bd6b7f58f01fd7a31deb59cd
stage lunaris-vessel-portrait 2502584 cd806d989623cbce1180df154efe892aaf8c2b047cee07906ec330f55c6fb6bb
stage reliquary-duelist-landscape 1395676 cfa5bdab1002b428347e4d2d46cd0517acfc876a3460693d7330c8abb0e90151
stage reliquary-duelist-portrait 2090359 ed78d0f92c19dc253a47454e13bb411fed64514f768c3db2157e5deb15b9026c

printf 'Staged 6 verified cinematic streams in %s\n' "$OUT"
