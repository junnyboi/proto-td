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


## Native pixel size from the manifest (P12.1: tiles are no longer a
## uniform canvas). Vector2i.ZERO for unknown ids or entries without a
## size, so callers can keep their fallback sizing.
static func size(id: StringName) -> Vector2i:
	var stored: Variant = _entry(id).get("size", Vector2i.ZERO)
	if stored is Vector2i:
		return stored
	return Vector2i.ZERO


static func metadata(id: StringName) -> Dictionary:
	return _entry(id).duplicate(true)


static func pivot(id: StringName) -> Vector2:
	var stored: Variant = _entry(id).get("pivot", Vector2.ZERO)
	return stored if stored is Vector2 else Vector2.ZERO


static func animation_names(id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var stored: Variant = _entry(id).get("animations", {})
	if stored is not Dictionary:
		return result
	for raw_name: Variant in stored:
		if typeof(raw_name) == TYPE_STRING_NAME:
			result.append(raw_name)
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result


static func animation_frame_index(
	id: StringName, animation: StringName, local_frame: int
) -> int:
	if local_frame < 0:
		return -1
	var stored: Variant = _entry(id).get("animations", {})
	if stored is not Dictionary or not stored.has(animation):
		return -1
	var raw_region: Variant = stored[animation]
	if raw_region is not Dictionary:
		return -1
	var length := int(raw_region.get("length", 0))
	if local_frame >= length:
		return -1
	return int(raw_region.get("start", -1)) + local_frame


static func animation_texture(
	id: StringName, animation: StringName, local_frame: int
) -> Texture2D:
	var frame := animation_frame_index(id, animation, local_frame)
	return texture(id, frame) if frame >= 0 else null


static func provenance_sha256(id: StringName) -> String:
	var stored: Variant = _entry(id).get("provenance_sha256", "")
	return stored if stored is String else ""


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
