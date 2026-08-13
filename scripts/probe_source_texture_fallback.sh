#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
export GODOT_SILENCE_ROOT_WARNING=1
GODOT="${GODOT:-$HOME/bin/godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROBE_SCRIPT="res://tools/probes/source_texture_fallback.gd"
IMPORT_FILE="assets/sprites/grunt_anim_walk_se.png.import"

cd "$ROOT"
[[ -x "$GODOT" ]] || { echo "[source-texture-fallback] Godot missing: $GODOT" >&2; exit 2; }
[[ -z "$(git status --short)" ]] || {
  echo '[source-texture-fallback] source tree must be clean' >&2
  exit 2
}
current_commit="$(git rev-parse HEAD)"

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/protos-source-texture.XXXXXX")"
probe_tree="$tmp_root/current"
cleanup() {
  git -C "$ROOT" worktree remove --force "$probe_tree" >/dev/null 2>&1 || true
  rm -rf "$tmp_root"
}
trap cleanup EXIT

git worktree add --detach "$probe_tree" "$current_commit" >/dev/null
timeout 240s "$GODOT" --headless --path "$probe_tree" --import \
  >"$tmp_root/import.log" 2>&1
cache_rel="$({
  sed -n 's/^path="res:\/\/\(.*grunt_anim_walk_se.*\.ctex\)"$/\1/p' \
    "$probe_tree/$IMPORT_FILE"
} | head -1)"
[[ -n "$cache_rel" ]] || {
  echo '[source-texture-fallback] tracked import record has no ctex path' >&2
  exit 1
}
cache_path="$probe_tree/$cache_rel"
[[ -s "$cache_path" ]] || {
  echo "[source-texture-fallback] import did not create $cache_rel" >&2
  exit 1
}
rm -f "$cache_path"
[[ ! -e "$cache_path" ]] || exit 1

set +e
timeout 120s "$GODOT" --headless --path "$probe_tree" -s "$PROBE_SCRIPT" \
  >"$tmp_root/probe.log" 2>&1
probe_rc=$?
set -e
cat "$tmp_root/probe.log"
[[ $probe_rc -eq 0 ]] || exit "$probe_rc"
[[ ! -e "$cache_path" ]] || {
  echo '[source-texture-fallback] runtime silently regenerated the removed ctex' >&2
  exit 1
}
if grep -Eq 'Unable to open file: .*grunt_anim_walk_se|Failed loading resource: .*grunt_anim_walk_se|\[SOURCE-TEXTURE-FALLBACK\] FAIL' "$tmp_root/probe.log"; then
  echo '[source-texture-fallback] forbidden load failure detected' >&2
  exit 1
fi
grep -q '^\[SOURCE-TEXTURE-FALLBACK\] PASS frame=(256.0, 256.0) atlas=(6400.0, 256.0)$' \
  "$tmp_root/probe.log"
printf '[source-texture-fallback] PASS commit=%s cache_removed=%s\n' \
  "$current_commit" "$cache_rel"
