#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
GODOT="${GODOT:-$HOME/bin/godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OLD_CACHE_COMMIT="${OLD_CACHE_COMMIT:-7babf28}"
PROBE_SCRIPT="res://tools/probes/stale_class_registry_boot.gd"
NEW_RUNTIME_CLASSES='MusicCatalog|StageArtTheme|UiCopy|UiMaterialTier|Aetheria(Button|Label|LocaleSelector|Panel|ScreenShell|Theme)'

cd "$ROOT"
[[ -x "$GODOT" ]] || { echo "[stale-class-registry] Godot missing: $GODOT" >&2; exit 2; }
[[ -z "$(git status --short)" ]] || {
  echo '[stale-class-registry] source tree must be clean' >&2
  exit 2
}
current_commit="$(git rev-parse HEAD)"

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/protos-stale-class-registry.XXXXXX")"
old_tree="$tmp_root/old"
current_tree="$tmp_root/current"
cleanup() {
  git -C "$ROOT" worktree remove --force "$old_tree" >/dev/null 2>&1 || true
  git -C "$ROOT" worktree remove --force "$current_tree" >/dev/null 2>&1 || true
  rm -rf "$tmp_root"
}
trap cleanup EXIT

git worktree add --detach "$old_tree" "$OLD_CACHE_COMMIT" >/dev/null
timeout 240s "$GODOT" --headless --path "$old_tree" --import >"$tmp_root/old-import.log" 2>&1
cache="$old_tree/.godot/global_script_class_cache.cfg"
[[ -s "$cache" ]] || { echo '[stale-class-registry] old cache missing' >&2; exit 1; }
if grep -Eq "$NEW_RUNTIME_CLASSES" "$cache"; then
  echo '[stale-class-registry] old cache unexpectedly knows new runtime classes' >&2
  exit 1
fi

git worktree add --detach "$current_tree" "$current_commit" >/dev/null
timeout 240s "$GODOT" --headless --path "$current_tree" --import \
  >"$tmp_root/current-import.log" 2>&1
current_cache="$current_tree/.godot/global_script_class_cache.cfg"
[[ -s "$current_cache" ]] || { echo '[stale-class-registry] current cache missing' >&2; exit 1; }
for class_name in \
  MusicCatalog StageArtTheme UiCopy UiMaterialTier \
  AetheriaButton AetheriaLabel AetheriaLocaleSelector \
  AetheriaPanel AetheriaScreenShell AetheriaTheme
do
  grep -q "$class_name" "$current_cache"
done
cp "$cache" "$current_tree/.godot/global_script_class_cache.cfg"
set +e
timeout 120s "$GODOT" --headless --fixed-fps 60 --path "$current_tree" -s "$PROBE_SCRIPT" \
  >"$tmp_root/current-boot.log" 2>&1
probe_rc=$?
set -e
cat "$tmp_root/current-boot.log"
[[ $probe_rc -eq 0 ]] || exit "$probe_rc"
if grep -Eq 'SCRIPT ERROR: Parse Error|Failed to load script|Could not find type|Identifier .* not declared|Identifier not found' "$tmp_root/current-boot.log"; then
  echo '[stale-class-registry] forbidden registry-dependent parse error detected' >&2
  exit 1
fi
grep -q '^\[STALE-CLASS-REGISTRY\] PASS ' "$tmp_root/current-boot.log"
grep -q 'title=ready s1=ready s2_tiles=50 s2_backdrops=700' "$tmp_root/current-boot.log"
printf '[stale-class-registry] PASS old=%s current=%s\n' "$OLD_CACHE_COMMIT" "$current_commit"
