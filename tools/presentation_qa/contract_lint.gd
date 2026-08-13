extends SceneTree

const REGISTRY_PATH := "res://data/presentation/probe_color_owners.tres"
const MANIFEST_PATH := "res://assets/manifest.tres"
const RESERVED := ["f4f4f4", "41a6f6"]

var _errors := PackedStringArray()


func _initialize() -> void:
	var manifest := load(MANIFEST_PATH) as AssetManifest
	var registry := load(REGISTRY_PATH) as ProbeColorOwnerRegistry
	if manifest == null:
		_fail("manifest: failed to load")
	if registry == null:
		_fail("registry: failed to load")
	if manifest != null:
		for detail: String in manifest.validate_contract():
			_fail("manifest.%s" % detail)
	if registry != null:
		for detail: String in registry.validate_contract():
			_fail("registry.%s" % detail)
	if manifest != null and registry != null:
		_validate_registry(manifest, registry)
		_validate_provenance(manifest)
	_validate_presentation_boundary()
	if _errors.is_empty():
		print("AUI00_CONTRACT_LINT_OK")
		quit(0)
		return
	for detail: String in _errors:
		push_error("[presentation_contract] %s" % detail)
	quit(1)


func _validate_registry(manifest: AssetManifest, registry: ProbeColorOwnerRegistry) -> void:
	var expected := ProbeColorOwnerRegistry.expected_entries()
	if registry.entries != expected:
		_fail("registry: production rows do not match exact frozen owner-tuple table")
	var asset_owners: Dictionary = {}
	var runtime_owners: Dictionary = {}
	for row: Dictionary in registry.entries:
		var color := String(row.get(&"color_html", ""))
		var owner_id: StringName = row.get(&"owner_id", &"")
		if row.get(&"owner_kind", &"") == &"asset":
			asset_owners["%s|%s" % [owner_id, color]] = row
			_validate_asset_owner(manifest, row)
		else:
			var source := String(row.get(&"source_path", ""))
			var symbol := String(row.get(&"symbol", &""))
			runtime_owners["%s|%s|%s" % [source, symbol, color]] = true
			_validate_runtime_owner(source, symbol, color)
	for raw_id: Variant in manifest.entries:
		var id: StringName = raw_id
		var entry: Dictionary = manifest.entries[id]
		for color: String in RESERVED:
			if (
				entry_any_frame_contains_color(entry, color)
				and not asset_owners.has("%s|%s" % [id, color])
			):
				_fail("probe: unregistered asset color %s in %s" % [color, id])
	_validate_runtime_literals(runtime_owners)


func _validate_asset_owner(manifest: AssetManifest, row: Dictionary) -> void:
	var id: StringName = row[&"owner_id"]
	if not manifest.entries.has(id):
		_fail("probe: unknown asset owner %s" % id)
		return
	var entry: Dictionary = manifest.entries[id]
	if String(entry.get(&"pattern", "")) != String(row[&"source_path"]):
		_fail("probe: pattern mismatch for %s" % id)
	var color := String(row[&"color_html"])
	if not entry_all_frames_contain_color(entry, color):
		_fail("probe: positive color %s absent from at least one %s frame" % [color, id])
	if bool(row[&"differential_required"]):
		var negative: StringName = row[&"negative_owner_id"]
		if not manifest.entries.has(negative):
			_fail("probe: missing negative owner %s" % negative)
		elif entry_any_frame_contains_color(manifest.entries[negative], color):
			_fail("probe: negative owner %s contains %s" % [negative, color])


func _validate_runtime_owner(source: String, symbol: String, color: String) -> void:
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null:
		_fail("probe: missing runtime source %s" % source)
		return
	var needle := 'const %s := Color("%s")' % [symbol, color]
	if not file.get_as_text().contains(needle):
		_fail("probe: missing exact runtime owner %s in %s" % [symbol, source])


func _validate_runtime_literals(runtime_owners: Dictionary) -> void:
	for path: String in _gd_files_under("res://scripts"):
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var lines := file.get_as_text().split("\n")
		for line: String in lines:
			for color: String in RESERVED:
				if not line.contains('Color("%s")' % color):
					continue
				var symbol := _constant_symbol(line)
				if symbol.is_empty() or not runtime_owners.has("%s|%s|%s" % [path, symbol, color]):
					_fail("probe: unregistered runtime literal %s at %s" % [color, path])


func _validate_provenance(manifest: AssetManifest) -> void:
	for raw_id: Variant in manifest.entries:
		var id: StringName = raw_id
		var entry: Dictionary = manifest.entries[id]
		var sidecar := "res://assets/provenance/%s.provenance.json" % id
		if not FileAccess.file_exists(sidecar):
			_fail("provenance: missing %s" % sidecar)
			continue
		if FileAccess.get_sha256(sidecar) != String(entry.get(&"provenance_sha256", "")):
			_fail("provenance: digest mismatch %s" % id)


func _validate_presentation_boundary() -> void:
	for path: String in _gd_files_under("res://data/presentation"):
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var text := file.get_as_text()
		if text.contains("res://sim/") or text.contains("sim/"):
			_fail("boundary: presentation script references sim: %s" % path)
	for path: String in [
		"res://tools/presentation_qa/provenance_schema_v1.json",
		"res://data/presentation/probe_color_owners.tres",
	]:
		if not FileAccess.file_exists(path):
			_fail("contract: missing %s" % path)


static func entry_all_frames_contain_color(entry: Dictionary, color_html: String) -> bool:
	if _is_atlas_entry(entry):
		var image := _atlas_image(entry)
		var frame_size: Vector2i = entry.get(&"size", Vector2i.ZERO)
		if image == null or frame_size == Vector2i.ZERO:
			return false
		for index: int in int(entry.get(&"frames", 0)):
			if not _image_region_contains_color(
				image, Rect2i(index * frame_size.x, 0, frame_size.x, frame_size.y), color_html
			):
				return false
		return true
	var paths := _entry_frame_paths(entry)
	if paths.is_empty():
		return false
	for path: String in paths:
		if not _image_contains_color(path, color_html):
			return false
	return true


static func entry_any_frame_contains_color(entry: Dictionary, color_html: String) -> bool:
	if _is_atlas_entry(entry):
		var image := _atlas_image(entry)
		var frame_size: Vector2i = entry.get(&"size", Vector2i.ZERO)
		if image == null or frame_size == Vector2i.ZERO:
			return false
		for index: int in int(entry.get(&"frames", 0)):
			if _image_region_contains_color(
				image, Rect2i(index * frame_size.x, 0, frame_size.x, frame_size.y), color_html
			):
				return true
		return false
	for path: String in _entry_frame_paths(entry):
		if _image_contains_color(path, color_html):
			return true
	return false


static func _entry_frame_paths(entry: Dictionary) -> Array[String]:
	var paths: Array[String] = []
	var pattern := String(entry.get(&"pattern", ""))
	var frames := int(entry.get(&"frames", 0))
	if frames > 1 and not pattern.contains("%d"):
		paths.append(pattern)
		return paths
	for index: int in frames:
		paths.append(pattern % index if frames > 1 else pattern)
	return paths


static func _image_contains_color(path: String, color_html: String) -> bool:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return false
	return _image_region_contains_color(image, Rect2i(Vector2i.ZERO, image.get_size()), color_html)


static func _is_atlas_entry(entry: Dictionary) -> bool:
	return int(entry.get(&"frames", 0)) > 1 and not String(entry.get(&"pattern", "")).contains("%d")


static func _atlas_image(entry: Dictionary) -> Image:
	var image := Image.load_from_file(
		ProjectSettings.globalize_path(String(entry.get(&"pattern", "")))
	)
	if image == null or image.is_empty():
		return null
	var frame_size: Vector2i = entry.get(&"size", Vector2i.ZERO)
	if image.get_size() != Vector2i(frame_size.x * int(entry.get(&"frames", 0)), frame_size.y):
		return null
	return image


static func _image_region_contains_color(image: Image, region: Rect2i, color_html: String) -> bool:
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			if image.get_pixel(x, y).to_html(false) == color_html:
				return true
	return false


func _gd_files_under(root: String) -> Array[String]:
	var result: Array[String] = []
	_scan_gd(root, result)
	result.sort()
	return result


func _scan_gd(path: String, result: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if name != "." and name != "..":
			var child := path.path_join(name)
			if dir.current_is_dir():
				_scan_gd(child, result)
			elif name.ends_with(".gd"):
				result.append(child)
		name = dir.get_next()
	dir.list_dir_end()


func _constant_symbol(line: String) -> String:
	var stripped := line.strip_edges()
	if not stripped.begins_with("const ") or not stripped.contains(" :="):
		return ""
	return stripped.trim_prefix("const ").split(" :=", false, 1)[0]


func _fail(detail: String) -> void:
	_errors.append(detail)
