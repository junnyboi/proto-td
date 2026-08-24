#!/bin/bash
set -euo pipefail

GODOT="${GODOT:-}"
if [[ -z "$GODOT" ]]; then
	if command -v godot >/dev/null 2>&1; then
		GODOT="$(command -v godot)"
	elif command -v godot4 >/dev/null 2>&1; then
		GODOT="$(command -v godot4)"
	elif [[ -x "$HOME/.local/bin/godot" ]]; then
		GODOT="$HOME/.local/bin/godot"
	else
		echo '[cold-boot] RED Godot executable not found (set GODOT or add godot to PATH)' >&2
		exit 127
	fi
fi
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUDGET_SECONDS="${COLD_BOOT_BUDGET_SECONDS:-180}"
SOURCE_CACHE="$ROOT/.godot/global_script_class_cache.cfg"
if [[ -n "${MGS_RUNG_ROOT:-}" ]]; then
	WORK_ROOT="$MGS_RUNG_ROOT/cold-boot"
	rm -rf "$WORK_ROOT"
	mkdir -p "$WORK_ROOT"
else
	WORK_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/protos-cold-boot.XXXXXX")"
fi
PROJECT="$WORK_ROOT/project"
LOG="${COLD_BOOT_LOG:-$WORK_ROOT/cold-boot.log}"
TIMEOUT_MARKER="$WORK_ROOT/timed-out"
mkdir -p "$PROJECT" "$(dirname "$LOG")"

cleanup() {
  rm -rf "$WORK_ROOT"
}
trap cleanup EXIT

# This gate runs after the normal import and then simulates the reported stale
# machine: all established class registrations remain, but MusicCatalog is
# absent when the Music autoload parses. No source or generated cache is edited.
test -f "$SOURCE_CACHE" || {
  echo '[cold-boot] RED source cache missing; run Godot import first' >&2
  exit 2
}
while IFS= read -r -d '' entry; do
  name="$(basename "$entry")"
  case "$name" in
    .git|.godot|artifacts|override.cfg|.DS_Store) continue ;;
  esac
  ln -s "$entry" "$PROJECT/$name"
done < <(find "$ROOT" -mindepth 1 -maxdepth 1 -print0)
cp -a "$ROOT/.godot" "$PROJECT/.godot"
CACHE="$PROJECT/.godot/global_script_class_cache.cfg"
test "$(grep -c '"class": &"MusicCatalog"' "$CACHE")" -eq 1
perl -0pi -e 's/\}, \{\n"base": &"Resource",\n"class": &"MusicCatalog",\n"icon": "",\n"is_abstract": false,\n"is_tool": false,\n"language": &"GDScript",\n"path": "res:\/\/assets\/music\/music_catalog\.gd"\n\}, \{/\}, \{/s' "$CACHE"
test "$(grep -c '"class": &"MusicCatalog"' "$CACHE" || true)" -eq 0
test "$(grep -c '"class": &"BattleModel"' "$CACHE")" -eq 1

set +e
"$GODOT" --headless --verbose --path "$PROJECT" --quit-after 2 > "$LOG" 2>&1 &
godot_pid=$!
(
  sleep "$BUDGET_SECONDS"
  if kill -0 "$godot_pid" 2>/dev/null; then
    : > "$TIMEOUT_MARKER"
    kill -TERM "$godot_pid" 2>/dev/null || true
    sleep 2
    kill -KILL "$godot_pid" 2>/dev/null || true
  fi
) &
watchdog_pid=$!
wait "$godot_pid"
code=$?
kill "$watchdog_pid" 2>/dev/null || true
wait "$watchdog_pid" 2>/dev/null || true
set -e

if [[ -f "$TIMEOUT_MARKER" ]]; then
  echo "[cold-boot] RED watchdog after ${BUDGET_SECONDS}s" >&2
  cat "$LOG" >&2
  exit 124
fi
if [[ $code -ne 0 ]]; then
  echo "[cold-boot] RED engine exit=$code" >&2
  cat "$LOG" >&2
  exit "$code"
fi
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script|Failed to instantiate an autoload|Could not find type' "$LOG"; then
  echo "[cold-boot] RED fatal parser/autoload text (Godot may still exit 0)" >&2
  grep -En 'SCRIPT ERROR:|Parse Error:|Failed to load script|Failed to instantiate an autoload|Could not find type' "$LOG" >&2
  exit 1
fi
grep -Fq 'Loading resource: res://autoloads/music.gd' "$LOG" || {
	echo '[cold-boot] RED missing Music autoload load proof' >&2
	exit 1
}
grep -Fq 'Loading resource: res://scenes/title.tscn' "$LOG" || {
  echo '[cold-boot] RED missing main-scene load proof' >&2
  exit 1
}

echo "[cold-boot] ALL GREEN music_autoload=1 main_scene=1 music_catalog_registry_entry=0"
