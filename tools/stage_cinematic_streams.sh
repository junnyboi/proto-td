#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-${ROOT}/build/web/cinematics}"
mkdir -p "$OUT"

manifest="$OUT/manifest.tsv"
printf 'key\tfile\tbytes\tsha256\n' > "$manifest"

file_size() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    stat -f %z "$1"
  else
    stat -c %s "$1"
  fi
}

file_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

stage() {
  local key="$1"
  local bytes="$2"
  local sha="$3"
  local source="$ROOT/assets/cinematics/gacha/video/${key}.ogv"
  local target="$OUT/${key}.ogv"
  test -f "$source"
  test "$(file_size "$source")" = "$bytes"
  test "$(file_sha256 "$source")" = "$sha"
  cp "$source" "$target"
  printf '%s\t%s\t%s\t%s\n' "$key" "$(basename "$target")" "$bytes" "$sha" >> "$manifest"
}

stage archive-caster-landscape 39223400 94331bef149513a790fcfc2c8fc0440cbb413504d9185311672ef9c53a86653f
stage archive-caster-portrait 19959147 2289a2737bb354949fa19cbfae9c0f4cdfdf997ec08eff3024a65007e0b6fbf4
stage lunaris-vessel-landscape 16638104 906011683d0abb8446db648b74ec13b79aea3e9c6234e8cae8fd2a4b1ae1db99
stage lunaris-vessel-portrait 23555321 32c6cab0847a8f9c1e5dbcde199ee57dbb301fba86135e505b482d7dade189f2
stage reliquary-duelist-landscape 29259884 b843467f29774c8679751ab274b2aa0a7d7a75293a0a1f7c4eade6fcc57c97fc
stage reliquary-duelist-portrait 27129072 2d2041a1be6c50b7e003ada11fa9da4a1f97114aa12d4f3d389abf54d80384cc

printf 'Staged 6 verified cinematic streams in %s\n' "$OUT"
