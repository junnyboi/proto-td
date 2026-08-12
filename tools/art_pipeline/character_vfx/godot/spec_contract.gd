extends RefCounted

const JsonLexical = preload("res://tools/art_pipeline/character_vfx/godot/json_lexical.gd")
const CONCEPT_HASHES: Array[String] = [
	"f3c338ec52a394e3e02a92bad65ca00e881fd340673ee6c120dec09c86b3b883",
	"db59ac74296fe4cbf6c78a3011bf78cdfd1c7814c576c7f22e8d02853d7135c9",
	"f512c5022533c53c4a84bcfd036a513d13ee5ec2667cba15283dff21fd373ea8",
	"d6db376800af86f300f6fa8ea7c62865ce4c8bb05dadd9dbe9d470776fa22ee9",
	"64039ab91598423982031948fefc30b5f9b2d93b803d51617cb88fcea2aa8dd3",
	"0a13437c7284fac6fbaf9e67be8223443bbdb3e47158a46325d007d691d17667",
]


static func _failure(detail: String) -> Dictionary:
	return {"ok": false, "detail": detail}


static func _sorted_keys(value: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key: Variant in value.keys():
		if typeof(key) != TYPE_STRING:
			return []
		result.append(String(key))
	result.sort()
	return result


static func _exact_keys(value: Dictionary, expected: Array, label: String) -> Dictionary:
	var wanted: Array[String] = []
	for key: Variant in expected:
		if typeof(key) != TYPE_STRING:
			return _failure("%s expected-key-type=string" % label)
		wanted.append(String(key))
	wanted.sort()
	var actual := _sorted_keys(value)
	if actual != wanted:
		return _failure("%s.keys expected=%s actual=%s" % [label, wanted, actual])
	return {"ok": true}


static func _is_integer_number(value: Variant) -> bool:
	return (
		typeof(value) == TYPE_FLOAT
		and is_finite(float(value))
		and float(value) == floor(float(value))
	)


static func _integer(value: Variant, expected: int, label: String) -> Dictionary:
	if not _is_integer_number(value) or int(value) != expected:
		return _failure("%s expected=%d actual=%s" % [label, expected, value])
	return {"ok": true}


static func _relative_path(value: Variant, label: String) -> Dictionary:
	if typeof(value) != TYPE_STRING:
		return _failure("%s expected=string" % label)
	var path := String(value)
	if (
		path.is_empty()
		or 0 in path.to_utf8_buffer()
		or "\\" in path
		or ":" in path
		or path.begins_with("/")
	):
		return _failure("%s forbidden-path value=%s" % [label, path])
	var parts := path.split("/", true)
	if parts.is_empty():
		return _failure("%s expected=relative-path" % label)
	for part: String in parts:
		if part.is_empty() or part == "." or part == "..":
			return _failure("%s path-escape value=%s" % [label, path])
	return {"ok": true, "value": path}


static func _canonical_path(absolute_path: String) -> Dictionary:
	if not absolute_path.is_absolute_path():
		return _failure("canonical path expected=absolute")
	var pending: Array[String] = []
	for part: String in absolute_path.split("/", false):
		pending.append(part)
	var resolved: Array[String] = []
	var seen_links: Dictionary = {}
	var hops := 0
	while not pending.is_empty():
		var part: String = pending.pop_front()
		if part.is_empty() or part == ".":
			continue
		if part == "..":
			if resolved.is_empty():
				return _failure("canonical path escaped filesystem root")
			resolved.pop_back()
			continue
		var parent := "/" + "/".join(resolved)
		var directory := DirAccess.open(parent)
		if directory == null:
			return _failure("canonical path parent unavailable")
		if directory.is_link(part):
			var link_path := parent.path_join(part)
			if seen_links.has(link_path) or hops >= 64:
				return _failure("canonical path symlink loop")
			seen_links[link_path] = true
			hops += 1
			var target := directory.read_link(part)
			var target_parts: Array[String] = []
			for target_part: String in target.split("/", false):
				target_parts.append(target_part)
			if target.is_absolute_path():
				resolved.clear()
			target_parts.append_array(pending)
			pending = target_parts
			continue
		if not directory.dir_exists(part) and not directory.file_exists(part):
			return _failure("canonical path component missing")
		if not pending.is_empty() and not directory.dir_exists(part):
			return _failure("canonical path intermediate expected=directory")
		resolved.append(part)
	return {"ok": true, "path": "/" + "/".join(resolved)}


static func _resolve_source(root: String, relative: String, label: String) -> Dictionary:
	var root_result := _canonical_path(ProjectSettings.globalize_path(root))
	if not root_result["ok"]:
		return _failure("input_root canonicalization failed")
	var canonical_root := String(root_result["path"])
	if not DirAccess.dir_exists_absolute(canonical_root):
		return _failure("input_root expected=directory")
	var candidate_result := _canonical_path(
		ProjectSettings.globalize_path(root).path_join(relative)
	)
	if not candidate_result["ok"]:
		return _failure("%s %s" % [label, candidate_result["detail"]])
	var candidate := String(candidate_result["path"])
	if candidate == canonical_root or not candidate.begins_with(canonical_root + "/"):
		return _failure("%s path-escape value=%s" % [label, relative])
	if not FileAccess.file_exists(candidate):
		return _failure("%s expected=file value=%s" % [label, relative])
	if DirAccess.dir_exists_absolute(candidate):
		return _failure("%s expected=regular-file value=%s" % [label, relative])
	return {"ok": true, "path": candidate}


static func _hex_color(value: Variant, label: String) -> Dictionary:
	if typeof(value) != TYPE_STRING:
		return _failure("%s expected=#RRGGBB-uppercase" % label)
	var text := String(value)
	if text.length() != 7 or not text.begins_with("#"):
		return _failure("%s expected=#RRGGBB-uppercase" % label)
	for character: String in text.substr(1):
		if character not in "0123456789ABCDEF":
			return _failure("%s expected=#RRGGBB-uppercase" % label)
	return {"ok": true}


static func _sha_or_null(value: Variant, label: String) -> Dictionary:
	if value == null:
		return {"ok": true}
	if typeof(value) != TYPE_STRING or String(value).length() != 64:
		return _failure("%s expected=null-or-sha256" % label)
	for character: String in String(value):
		if character not in "0123456789abcdef":
			return _failure("%s expected=null-or-sha256" % label)
	return {"ok": true}


static func _validate_atlas(atlas: Variant) -> Dictionary:
	if typeof(atlas) != TYPE_DICTIONARY:
		return _failure("atlas expected=object")
	var value := atlas as Dictionary
	var keys := [
		"width", "height", "columns", "rows", "cell_width", "cell_height", "pivot", "foot_row"
	]
	var key_check := _exact_keys(value, keys, "atlas")
	if not key_check["ok"]:
		return key_check
	var pinned := {
		"width": 768,
		"height": 384,
		"columns": 4,
		"rows": 2,
		"cell_width": 192,
		"cell_height": 192,
		"foot_row": 180,
	}
	for key: String in pinned:
		var check := _integer(value[key], pinned[key], "atlas.%s" % key)
		if not check["ok"]:
			return check
	if typeof(value["pivot"]) != TYPE_ARRAY or (value["pivot"] as Array).size() != 2:
		return _failure("atlas.pivot expected=[0.5,0.94]")
	var pivot := value["pivot"] as Array
	if typeof(pivot[0]) != TYPE_FLOAT or typeof(pivot[1]) != TYPE_FLOAT:
		return _failure("atlas.pivot expected=float-pair")
	if float(pivot[0]) != 0.5 or float(pivot[1]) != 0.94:
		return _failure("atlas.pivot expected=[0.5,0.94]")
	return {"ok": true}


static func _validate_frames(frames: Variant, input_root: String) -> Dictionary:
	if typeof(frames) != TYPE_ARRAY or (frames as Array).size() != 8:
		return _failure("frames.count expected=8")
	var sources: Array[String] = []
	var cells: Dictionary = {}
	for index: int in range(8):
		var frame_value: Variant = (frames as Array)[index]
		if typeof(frame_value) != TYPE_DICTIONARY:
			return _failure("frames[%d] expected=object" % index)
		var frame := frame_value as Dictionary
		var key_check := _exact_keys(frame, ["path", "row", "column"], "frames[%d]" % index)
		if not key_check["ok"]:
			return key_check
		if not _is_integer_number(frame["row"]) or not _is_integer_number(frame["column"]):
			return _failure("frames[%d].cell expected=integers" % index)
		var row := int(frame["row"])
		var column := int(frame["column"])
		if row < 0 or row >= 2 or column < 0 or column >= 4:
			return _failure("frames[%d].cell expected=row0..1,col0..3" % index)
		var cell_key := "%d,%d" % [row, column]
		if cells.has(cell_key):
			return _failure("frames[%d].cell duplicate=%s" % [index, cell_key])
		cells[cell_key] = true
		var path_check := _relative_path(frame["path"], "frames[%d].path" % index)
		if not path_check["ok"]:
			return path_check
		var source_check := _resolve_source(
			input_root, path_check["value"], "frames[%d].path" % index
		)
		if not source_check["ok"]:
			return source_check
		sources.append(source_check["path"])
	return {"ok": true, "sources": sources}


static func _validate_animations(animations: Variant) -> Dictionary:
	if typeof(animations) != TYPE_ARRAY or (animations as Array).size() != 2:
		return _failure("animations expected=two-rows")
	var expected := [
		{"name": "rest_movement", "row": 0, "frames": 4, "fps": 5.5, "loop": true},
		{"name": "attack_skill", "row": 1, "frames": 4, "fps": 8, "loop": true},
	]
	for index: int in range(2):
		var item_value: Variant = (animations as Array)[index]
		if typeof(item_value) != TYPE_DICTIONARY:
			return _failure("animations[%d] expected=object" % index)
		var item := item_value as Dictionary
		var key_check := _exact_keys(
			item, ["name", "row", "frames", "fps", "loop"], "animations[%d]" % index
		)
		if not key_check["ok"]:
			return key_check
		if typeof(item["name"]) != TYPE_STRING or String(item["name"]) != expected[index]["name"]:
			return _failure("animations[%d].name mismatch" % index)
		for key: String in ["row", "frames"]:
			var number_check := _integer(
				item[key], expected[index][key], "animations[%d].%s" % [index, key]
			)
			if not number_check["ok"]:
				return number_check
		if typeof(item["fps"]) != TYPE_FLOAT or float(item["fps"]) != float(expected[index]["fps"]):
			return _failure("animations[%d].fps mismatch" % index)
		if typeof(item["loop"]) != TYPE_BOOL or not bool(item["loop"]):
			return _failure("animations[%d].loop expected=true" % index)
	return {"ok": true}


static func _validate_palette(spec: Dictionary) -> Dictionary:
	if typeof(spec["palette"]) != TYPE_ARRAY or (spec["palette"] as Array).is_empty():
		return _failure("palette expected=non-empty-array")
	var seen: Dictionary = {}
	for index: int in range((spec["palette"] as Array).size()):
		var color: Variant = (spec["palette"] as Array)[index]
		var check := _hex_color(color, "palette[%d]" % index)
		if not check["ok"]:
			return check
		if seen.has(color):
			return _failure("palette expected=unique")
		seen[color] = true
	if spec["reserved_colors"] != ["#F4F4F4", "#41A6F6"]:
		return _failure("reserved_colors mismatch")
	for color: Variant in spec["palette"]:
		if color in spec["reserved_colors"]:
			return _failure("palette reserved-collision=%s" % color)
	return {"ok": true}


static func _validate_normalization(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return _failure("normalization expected=object")
	var normalization := value as Dictionary
	var key_check := _exact_keys(
		normalization,
		[
			"background_key", "alpha_threshold", "minimum_component_size", "anchor_x",
			"anchor_foot_y", "resize"
		],
		"normalization"
	)
	if not key_check["ok"]:
		return key_check
	var color_check := _hex_color(normalization["background_key"], "normalization.background_key")
	if not color_check["ok"]:
		return color_check
	for pair: Array in [["alpha_threshold", 26], ["anchor_x", 96], ["anchor_foot_y", 180]]:
		var check := _integer(normalization[pair[0]], pair[1], "normalization.%s" % pair[0])
		if not check["ok"]:
			return check
	if not _is_integer_number(normalization["minimum_component_size"]):
		return _failure("normalization.minimum_component_size expected=integer")
	if int(normalization["minimum_component_size"]) < 0:
		return _failure("normalization.minimum_component_size expected=>=0")
	if typeof(normalization["resize"]) != TYPE_ARRAY:
		return _failure("normalization.resize expected=[positive-int,positive-int]")
	var resize := normalization["resize"] as Array
	if resize.size() != 2:
		return _failure("normalization.resize expected=two-values")
	for index: int in range(2):
		if not _is_integer_number(resize[index]) or int(resize[index]) <= 0:
			return _failure("normalization.resize expected=positive-integers")
	return {"ok": true}


static func _validate_outputs(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return _failure("outputs expected=object")
	var outputs := value as Dictionary
	var key_check := _exact_keys(outputs, ["atlas", "metadata", "qa", "contact"], "outputs")
	if not key_check["ok"]:
		return key_check
	var suffixes := {
		"atlas": ".png", "metadata": ".asset.json", "qa": ".qa.json", "contact": ".contact.png"
	}
	var seen: Dictionary = {}
	for key: String in suffixes:
		var path_check := _relative_path(outputs[key], "outputs.%s" % key)
		if not path_check["ok"]:
			return path_check
		var name := String(path_check["value"])
		if "/" in name or not name.ends_with(suffixes[key]) or seen.has(name):
			return _failure("outputs.%s invalid-or-duplicate" % key)
		seen[name] = true
	return {"ok": true}


static func _validate_provenance(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return _failure("provenance expected=object")
	var provenance := value as Dictionary
	var key_check := _exact_keys(
		provenance,
		[
			"tool", "model", "prompt_sha256", "reference_sha256", "seed",
			"approved_concept_sha256", "human_approval"
		],
		"provenance"
	)
	if not key_check["ok"]:
		return key_check
	for key: String in ["tool", "model", "human_approval"]:
		if typeof(provenance[key]) != TYPE_STRING or String(provenance[key]).is_empty():
			return _failure("provenance.%s expected=non-empty-string" % key)
	for key: String in ["prompt_sha256", "reference_sha256"]:
		var check := _sha_or_null(provenance[key], "provenance.%s" % key)
		if not check["ok"]:
			return check
	if provenance["seed"] != null and not _is_integer_number(provenance["seed"]):
		return _failure("provenance.seed expected=null-or-integer")
	if typeof(provenance["approved_concept_sha256"]) != TYPE_ARRAY:
		return _failure("provenance.approved_concept_sha256 expected=array")
	var hashes := provenance["approved_concept_sha256"] as Array
	if hashes.size() != CONCEPT_HASHES.size():
		return _failure("provenance.approved_concept_sha256 count mismatch")
	for index: int in range(CONCEPT_HASHES.size()):
		if hashes[index] != CONCEPT_HASHES[index]:
			return _failure("provenance.approved_concept_sha256 differs from Round 5")
	if provenance["human_approval"] != "CONCEPT_APPROVED_RUNTIME_UNBOUND":
		return _failure("provenance.human_approval mismatch")
	return {"ok": true}


static func _validate_lexical(types: Dictionary) -> Dictionary:
	var expected: Dictionary = {
		"/schema_version": "integer",
		"/atlas/width": "integer",
		"/atlas/height": "integer",
		"/atlas/columns": "integer",
		"/atlas/rows": "integer",
		"/atlas/cell_width": "integer",
		"/atlas/cell_height": "integer",
		"/atlas/pivot/0": "number",
		"/atlas/pivot/1": "number",
		"/atlas/foot_row": "integer",
		"/animations/0/row": "integer",
		"/animations/0/frames": "integer",
		"/animations/0/fps": "number",
		"/animations/1/row": "integer",
		"/animations/1/frames": "integer",
		"/animations/1/fps": "integer",
		"/normalization/alpha_threshold": "integer",
		"/normalization/minimum_component_size": "integer",
		"/normalization/anchor_x": "integer",
		"/normalization/anchor_foot_y": "integer",
		"/normalization/resize/0": "integer",
		"/normalization/resize/1": "integer",
	}
	for index: int in range(8):
		expected["/frames/%d/row" % index] = "integer"
		expected["/frames/%d/column" % index] = "integer"
	for path: String in expected:
		var actual_type := String(types.get(path, "missing"))
		if actual_type == "missing":
			continue
		if actual_type != expected[path]:
			return _failure(
				"spec lexical-type path=%s expected=%s actual=%s"
				% [path, expected[path], actual_type]
			)
	var seed_type := String(types.get("/provenance/seed", "missing"))
	if seed_type not in ["null", "integer"]:
		return _failure("spec lexical-type path=/provenance/seed expected=null-or-integer")
	return {"ok": true}


static func load_and_validate(spec_path: String, input_root: String) -> Dictionary:
	if not FileAccess.file_exists(spec_path):
		return _failure("spec expected=file")
	var text := FileAccess.get_file_as_string(spec_path)
	var lexical := JsonLexical.new().analyze(text)
	if not lexical["ok"]:
		return _failure("spec lexical-invalid detail=%s" % lexical["detail"])
	if not (lexical["duplicates"] as Array).is_empty():
		return _failure("spec duplicate-key paths=%s" % [lexical["duplicates"]])
	if not (lexical["nul_escapes"] as Array).is_empty():
		return _failure("spec NUL-escape paths=%s" % [lexical["nul_escapes"]])
	var lexical_check := _validate_lexical(lexical["types"])
	if not lexical_check["ok"]:
		return lexical_check
	var parser := JSON.new()
	var error := parser.parse(text)
	if error != OK:
		return _failure("spec invalid-json line=%d" % parser.get_error_line())
	if typeof(parser.data) != TYPE_DICTIONARY:
		return _failure("spec expected=object")
	var spec := parser.data as Dictionary
	var top_keys := [
		"schema_version", "asset_id", "asset_class", "state", "frames", "atlas",
		"animations", "palette", "normalization", "reserved_colors", "outputs", "provenance"
	]
	var key_check := _exact_keys(spec, top_keys, "spec")
	if not key_check["ok"]:
		return key_check
	var version_check := _integer(spec["schema_version"], 1, "schema_version")
	if not version_check["ok"]:
		return version_check
	for key: String in ["asset_id", "asset_class", "state"]:
		if typeof(spec[key]) != TYPE_STRING or String(spec[key]).is_empty():
			return _failure("%s expected=non-empty-string" % key)
	if spec["asset_class"] != "character_vfx":
		return _failure("asset_class expected=character_vfx")
	for check: Dictionary in [
		_validate_atlas(spec["atlas"]),
		_validate_animations(spec["animations"]),
		_validate_palette(spec),
		_validate_normalization(spec["normalization"]),
		_validate_outputs(spec["outputs"]),
		_validate_provenance(spec["provenance"]),
	]:
		if not check["ok"]:
			return check
	var frame_check := _validate_frames(spec["frames"], input_root)
	if not frame_check["ok"]:
		return frame_check
	return {"ok": true, "spec": spec, "sources": frame_check["sources"]}
