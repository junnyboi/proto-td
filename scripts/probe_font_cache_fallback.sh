#!/usr/bin/env bash
set -euo pipefail

GODOT="${1:-${GODOT:-$HOME/bin/godot}}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/protos-font-cache.XXXXXX")"
PROJECT="$WORK_ROOT/project"
LOG="$WORK_ROOT/font-cache.log"
FONT_REL="assets/fonts/ProtosSansSC-Subset.otf"
IMPORT_REL="$FONT_REL.import"
THEME_REL="scripts/ui/components/aetheria_theme.gd"

cleanup() {
  rm -rf "$WORK_ROOT"
}
trap cleanup EXIT

for relative in "$FONT_REL" "$IMPORT_REL" "$THEME_REL"; do
  test -s "$ROOT/$relative" || {
    echo "[font-cache] RED missing source: $relative" >&2
    exit 2
  }
done

mkdir -p "$PROJECT/assets/fonts" "$PROJECT/scripts/ui/components"
ln -s "$ROOT/$FONT_REL" "$PROJECT/$FONT_REL"
ln -s "$ROOT/$IMPORT_REL" "$PROJECT/$IMPORT_REL"
ln -s "$ROOT/$THEME_REL" "$PROJECT/$THEME_REL"
cat > "$PROJECT/project.godot" <<'EOF'
config_version=5

[application]
config/name="Protos Font Cache Probe"
config/features=PackedStringArray("4.7")

[debug]
gdscript/warnings/untyped_declaration=2
EOF
cat > "$PROJECT/probe.gd" <<'EOF'
extends SceneTree

const ThemeType := preload("res://scripts/ui/components/aetheria_theme.gd")


func _initialize() -> void:
	var theme := ThemeType.new() as Theme
	var composite := theme.default_font as FontVariation
	if composite == null or composite.fallbacks.size() != 1:
		quit(10)
		return
	var fallback := composite.fallbacks[0] as FontFile
	if fallback == null or fallback.resource_name != "ProtosSansSC-Subset":
		quit(11)
		return
	if not fallback.has_char("中".unicode_at(0)):
		quit(12)
		return
	print("PROTOS_FONT_CACHE_FALLBACK_PASS")
	quit(0)
EOF

test ! -e "$PROJECT/.godot"
set +e
timeout 60 "$GODOT" --headless --path "$PROJECT" -s "$PROJECT/probe.gd" > "$LOG" 2>&1
code=$?
set -e

if [[ $code -ne 0 ]]; then
  echo "[font-cache] RED engine exit=$code" >&2
  cat "$LOG" >&2
  exit "$code"
fi
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Cannot open file.*fontdata|Failed loading resource' "$LOG"; then
  echo '[font-cache] RED parser or stale import-cache failure' >&2
  grep -En 'SCRIPT ERROR:|Parse Error:|Cannot open file.*fontdata|Failed loading resource' "$LOG" >&2
  exit 1
fi
test "$(grep -Fxc 'PROTOS_FONT_CACHE_FALLBACK_PASS' "$LOG")" -eq 1 || {
  echo '[font-cache] RED missing or duplicate success sentinel' >&2
  cat "$LOG" >&2
  exit 1
}
test ! -e "$PROJECT/.godot/imported/ProtosSansSC-Subset.otf-c34327c32551c831328847eccf90c999.fontdata" || {
  echo '[font-cache] RED probe unexpectedly generated the imported cache artifact' >&2
  exit 1
}

echo '[font-cache] ALL GREEN source_font=1 missing_fontdata=1 zh_glyph=1'
