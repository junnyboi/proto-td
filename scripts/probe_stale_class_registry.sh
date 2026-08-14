#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
GODOT="${GODOT:-$HOME/bin/godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OLD_CACHE_COMMIT="${OLD_CACHE_COMMIT:-7babf28}"
CAMPAIGN_CACHE_COMMIT="${CAMPAIGN_CACHE_COMMIT:-7025ceaf5120f8863ebbfc7c4ef776b6bbe226ee}"
UI_PROBE_SCRIPT="res://tools/probes/stale_class_registry_boot.gd"
PROMOTION_PROBE_SCRIPT="res://tools/probes/promotion_cache_boot.gd"
NEW_UI_CLASSES='MusicCatalog|StageArtTheme|StageNarrative(Def|Catalog)|UiCopy|UiMaterialTier|Aetheria(Button|Label|LocaleSelector|Panel|ScreenShell|Theme)'
FATAL_PATTERN='SCRIPT ERROR: Parse Error|Failed to load script|Failed loading resource|Could not preload resource file|Could not find type|Identifier .* not declared|Identifier not found'

cd "$ROOT"
[[ -x "$GODOT" ]] || { echo "[stale-class-registry] Godot missing: $GODOT" >&2; exit 2; }
[[ -z "$(git status --short)" ]] || {
	echo '[stale-class-registry] source tree must be clean' >&2
	exit 2
}
current_commit="$(git rev-parse HEAD)"

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/protos-stale-class-registry.XXXXXX")"
old_tree="$tmp_root/old"
campaign_cache_tree="$tmp_root/campaign-cache"
current_tree="$tmp_root/current"
cleanup() {
	git -C "$ROOT" worktree remove --force "$old_tree" >/dev/null 2>&1 || true
	git -C "$ROOT" worktree remove --force "$campaign_cache_tree" >/dev/null 2>&1 || true
	git -C "$ROOT" worktree remove --force "$current_tree" >/dev/null 2>&1 || true
	rm -rf "$tmp_root"
}
trap cleanup EXIT

git worktree add --detach "$old_tree" "$OLD_CACHE_COMMIT" >/dev/null
timeout 240s "$GODOT" --headless --path "$old_tree" --import >"$tmp_root/old-import.log" 2>&1
old_cache="$old_tree/.godot/global_script_class_cache.cfg"
[[ -s "$old_cache" ]] || { echo '[stale-class-registry] old UI cache missing' >&2; exit 1; }
if grep -Eq "$NEW_UI_CLASSES" "$old_cache"; then
	echo '[stale-class-registry] old UI cache unexpectedly knows new runtime classes' >&2
	exit 1
fi

git worktree add --detach "$campaign_cache_tree" "$CAMPAIGN_CACHE_COMMIT" >/dev/null
timeout 240s "$GODOT" --headless --path "$campaign_cache_tree" --import \
	>"$tmp_root/campaign-cache-import.log" 2>&1
campaign_cache="$campaign_cache_tree/.godot/global_script_class_cache.cfg"
[[ -s "$campaign_cache" ]] || {
	echo '[stale-class-registry] pre-progression campaign cache missing' >&2
	exit 1
}
for class_name in CampaignCodec CampaignHash CanonicalJson; do
	grep -q "$class_name" "$campaign_cache"
done
if grep -q 'CampaignProgression' "$campaign_cache"; then
	echo '[stale-class-registry] pre-progression cache knows CampaignProgression' >&2
	exit 1
fi

git worktree add --detach "$current_tree" "$current_commit" >/dev/null
timeout 240s "$GODOT" --headless --path "$current_tree" --import \
	>"$tmp_root/current-import.log" 2>&1
current_cache="$current_tree/.godot/global_script_class_cache.cfg"
[[ -s "$current_cache" ]] || { echo '[stale-class-registry] current cache missing' >&2; exit 1; }
for class_name in \
	MusicCatalog StageArtTheme StageNarrativeDef StageNarrativeCatalog \
	UiCopy UiMaterialTier \
	AetheriaButton AetheriaLabel AetheriaLocaleSelector \
	AetheriaPanel AetheriaScreenShell AetheriaTheme \
	CampaignProgression TrainingScreen
do
	grep -q "$class_name" "$current_cache"
done
font_import="$current_tree/assets/fonts/ProtosSansSC-Subset.otf.import"
font_cache_path="$(awk -F'"' '/^path=/{print $2; exit}' "$font_import")"
[[ "$font_cache_path" == res://.godot/imported/ProtosSansSC-Subset*.fontdata ]] || {
	echo "[stale-class-registry] unsafe font cache path: $font_cache_path" >&2
	exit 1
}
rm -f "$current_tree/${font_cache_path#res://}"
[[ ! -e "$current_tree/${font_cache_path#res://}" ]] || {
	echo '[stale-class-registry] generated font cache was not removed' >&2
	exit 1
}

cp "$old_cache" "$current_cache"
set +e
timeout 120s "$GODOT" --headless --fixed-fps 60 --path "$current_tree" -s "$UI_PROBE_SCRIPT" \
	>"$tmp_root/ui-boot.log" 2>&1
ui_rc=$?
set -e
cat "$tmp_root/ui-boot.log"
[[ $ui_rc -eq 0 ]] || exit "$ui_rc"
if grep -Eq "$FATAL_PATTERN" "$tmp_root/ui-boot.log"; then
	echo '[stale-class-registry] forbidden legacy UI cache error detected' >&2
	exit 1
fi
grep -q '^\[STALE-CLASS-REGISTRY\] PASS ' "$tmp_root/ui-boot.log"
grep -q 'title=ready staging=ready s1_squad=ready s1_results=ready s1=ready s2_children=55 s3_children=64 s2_backdrops=0 s3_backdrops=0' \
	"$tmp_root/ui-boot.log"

cp "$campaign_cache" "$current_cache"
set +e
timeout 120s "$GODOT" --headless --fixed-fps 60 --path "$current_tree" \
	-s "$PROMOTION_PROBE_SCRIPT" >"$tmp_root/promotion-boot.log" 2>&1
promotion_rc=$?
set -e
cat "$tmp_root/promotion-boot.log"
[[ $promotion_rc -eq 0 ]] || exit "$promotion_rc"
if grep -Eq "$FATAL_PATTERN" "$tmp_root/promotion-boot.log"; then
	echo '[stale-class-registry] forbidden promotion cache error detected' >&2
	exit 1
fi
grep -q '^\[PROMOTION-CACHE-BOOT\] PASS training=ready promotion=ready$' \
	"$tmp_root/promotion-boot.log"

printf '[stale-class-registry] PASS ui-cache=%s campaign-cache=%s current=%s fontdata=absent\n' \
	"$OLD_CACHE_COMMIT" "$CAMPAIGN_CACHE_COMMIT" "$current_commit"
