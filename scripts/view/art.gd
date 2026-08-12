class_name Art
extends RefCounted

## Manifest-resolved texture access for all view/UI code (parent plan §6.6:
## scene code never hardcodes asset paths). Returns null for unknown ids so
## callers can keep their rect fallback — a missing asset degrades to the
## placeholder look instead of crashing a battle.

static var _manifest: AssetManifest = null
static var _cache: Dictionary = {}


static func _entry(id: StringName) -> Dictionary:
	if _manifest == null:
		_manifest = load("res://assets/manifest.tres") as AssetManifest
	if _manifest == null:
		return {}
	var entry: Variant = _manifest.entries.get(id)
	return entry if entry is Dictionary else {}


static func frame_count(id: StringName) -> int:
	return int(_entry(id).get("frames", 0))


static func fps(id: StringName) -> float:
	return float(_entry(id).get("fps", 0.0))


## Native pixel size from the manifest (P12.1: tiles are no longer a
## uniform canvas). Vector2i.ZERO for unknown ids or entries without a
## size, so callers can keep their fallback sizing.
static func size(id: StringName) -> Vector2i:
	var stored: Variant = _entry(id).get("size", Vector2i.ZERO)
	if stored is Vector2i:
		return stored
	return Vector2i.ZERO


static func texture(id: StringName, frame := 0) -> Texture2D:
	var key := "%s/%d" % [id, frame]
	if _cache.has(key):
		return _cache[key]
	var entry := _entry(id)
	if entry.is_empty():
		return null
	var frames := int(entry.get("frames", 0))
	if frame < 0 or frame >= frames:
		return null
	var pattern: String = entry["pattern"]
	var frame_size: Variant = entry.get("frame_size")
	var tex: Texture2D = null
	if frame_size is Vector2i:
		var atlas_source := load(pattern) as Texture2D
		if atlas_source != null:
			var atlas := AtlasTexture.new()
			atlas.atlas = atlas_source
			atlas.region = Rect2i(frame * frame_size.x, 0, frame_size.x, frame_size.y)
			atlas.filter_clip = true
			tex = atlas
	else:
		var path := pattern % frame if frames > 1 else pattern
		tex = load(path) as Texture2D
	_cache[key] = tex
	return tex
