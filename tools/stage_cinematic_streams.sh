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

stage archive-caster-landscape 18894020 5eeeba0bd6a7fce74c80e07d5c23cb0e54007a9287a2878c8a6bf2042efa8cd0
stage archive-caster-portrait 9298910 5ac6f14efa7fc96782ad2978ac2f2d2103f5957416006333faabc0af27e0a5ec
stage lunaris-vessel-landscape 8846078 fb09e9d067bd1458bbc3d6a0b575281d248df8ea75b6c33e0bf2111209a8fb97
stage lunaris-vessel-portrait 8498953 87221b5164f157267963acf1bb7504b6220f66bd1fdb6e6c588d94a845c39c32
stage reliquary-duelist-landscape 7485451 186a0f063b900877513261e0ab2b7aefb0609de9d422f69ea65cd5e8d76a1e55
stage reliquary-duelist-portrait 8496742 09430cb2de8bdeb7c1d6c8db60a838a572f1c518aa2e474c04dbc4ffaea1a2f5

printf 'Staged 6 verified cinematic streams in %s\n' "$OUT"
