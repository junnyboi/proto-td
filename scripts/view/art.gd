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


static func texture(id: StringName, frame := 0) -> Texture2D:
	var key := "%s/%d" % [id, frame]
	if _cache.has(key):
		return _cache[key]
	var entry := _entry(id)
	if entry.is_empty():
		return null
	var pattern: String = entry["pattern"]
	var path := pattern % frame if int(entry["frames"]) > 1 else pattern
	var tex := load(path) as Texture2D
	_cache[key] = tex
	return tex
