extends RefCounted

const PIPELINE_VERSION := "1.0.0"
const PINNED_GODOT_VERSION := "4.7.2-stable (official)"
const PixelOps = preload("res://tools/art_pipeline/character_vfx/godot/pixel_ops.gd")
const SpecContract = preload("res://tools/art_pipeline/character_vfx/godot/spec_contract.gd")

static var _publish_sequence := 0
static var _preflight_sequence := 0
static var _remove_fault_after := -1
static var _remove_operations := 0


static func _failure(detail: String) -> Dictionary:
	return {"ok": false, "detail": detail}


static func check_backend_version(version_info: Dictionary) -> Dictionary:
	var actual := String(version_info.get("string", "missing"))
	var exact: bool = (
		version_info.get("major") == 4
		and version_info.get("minor") == 7
		and version_info.get("patch") == 2
		and version_info.get("status") == "stable"
		and version_info.get("build") == "official"
		and actual == PINNED_GODOT_VERSION
	)
	if not exact:
		return _failure(
			"backend.version expected=%s actual=%s" % [PINNED_GODOT_VERSION, actual]
		)
	return {"ok": true}


static func _require_backend_version() -> Dictionary:
	return check_backend_version(Engine.get_version_info())


static func _canonical_json(value: Variant) -> String:
	return JSON.stringify(value, "", true, true) + "\n"


static func _sha256_bytes(value: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value)
	return context.finish().hex_encode()


static func _sha256_text(value: String) -> String:
	return _sha256_bytes(value.to_utf8_buffer())


static func _write_text(path: String, value: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _failure("write failed name=%s error=%d" % [path.get_file(), FileAccess.get_open_error()])
	file.store_string(value)
	file.close()
	return {"ok": true}


static func _source_hashes(spec: Dictionary, sources: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index: int in range(sources.size()):
		result.append({
			"path": String((spec["frames"] as Array)[index]["path"]),
			"sha256": FileAccess.get_sha256(sources[index]),
		})
	return result


static func _normalized_atlas(spec: Dictionary, sources: Array[String]) -> Dictionary:
	var palette: Array[PackedInt32Array] = []
	for value: Variant in spec["palette"]:
		palette.append(PixelOps.parse_hex(String(value)))
	var normalization := spec["normalization"] as Dictionary
	var resize: Variant = normalization["resize"]
	var cells: Array[Dictionary] = []
	var anchors: Array[Dictionary] = []
	for index: int in range(sources.size()):
		var image := Image.load_from_file(sources[index])
		if image == null or image.is_empty():
			return _failure("source decode failed frame=%d" % index)
		if resize != null:
			var resize_values := resize as Array
			image = PixelOps.resize_nearest(
				image, int(resize_values[0]), int(resize_values[1])
			)
		image = PixelOps.key_and_threshold(
			image,
			PixelOps.parse_hex(String(normalization["background_key"])),
			int(normalization["alpha_threshold"])
		)
		image = PixelOps.palette_map(image, palette)
		image = PixelOps.remove_small_components(
			image, int(normalization["minimum_component_size"])
		)
		var anchored := PixelOps.anchor_in_cell(
			image,
			Vector2i(int(spec["atlas"]["cell_width"]), int(spec["atlas"]["cell_height"])),
			int(normalization["anchor_x"]),
			int(normalization["anchor_foot_y"])
		)
		if anchored.has("error"):
			return _failure(String(anchored["error"]))
		var frame := (spec["frames"] as Array)[index] as Dictionary
		cells.append({
			"row": int(frame["row"]),
			"column": int(frame["column"]),
			"image": anchored["image"],
		})
		anchors.append(anchored["anchor"])
	return {"ok": true, "atlas": PixelOps.composite_atlas(cells), "anchors": anchors}


static func _add_check(
	checks: Array[Dictionary], name: String, ok: bool, detail: String
) -> Dictionary:
	checks.append({"name": name, "ok": ok, "detail": detail})
	if not ok:
		return _failure("%s: %s" % [name, detail])
	return {"ok": true}


static func _hex_rgb(red: int, green: int, blue: int) -> String:
	return "#%02X%02X%02X" % [red, green, blue]


static func _inspect_atlas(atlas: Image, spec: Dictionary) -> Dictionary:
	var image := atlas.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	var checks: Array[Dictionary] = []
	var check := _add_check(
		checks,
		"atlas_dimensions",
		image.get_size() == Vector2i(768, 384),
		"measured=%dx%d expected=768x384" % [image.get_width(), image.get_height()]
	)
	if not check["ok"]:
		return check
	var palette: Dictionary = {}
	for value: Variant in spec["palette"]:
		var rgb := PixelOps.parse_hex(String(value))
		palette["%d,%d,%d" % [rgb[0], rgb[1], rgb[2]]] = true
	var reserved: Dictionary = {}
	for value: Variant in spec["reserved_colors"]:
		var rgb := PixelOps.parse_hex(String(value))
		reserved["%d,%d,%d" % [rgb[0], rgb[1], rgb[2]]] = true
	var data := image.get_data()
	var soft_alpha: Array[String] = []
	var palette_violations: Array[String] = []
	var reserved_violations: Array[String] = []
	var opaque_palette: Dictionary = {}
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var offset := (y * image.get_width() + x) * 4
			var alpha := int(data[offset + 3])
			if alpha != 0 and alpha != 255 and soft_alpha.size() < 5:
				soft_alpha.append("%d,%d,%d" % [x, y, alpha])
			if alpha == 255:
				var key := "%d,%d,%d" % [data[offset], data[offset + 1], data[offset + 2]]
				opaque_palette[key] = true
				if not palette.has(key) and palette_violations.size() < 5:
					palette_violations.append("%d,%d,%s" % [x, y, key])
				if reserved.has(key) and reserved_violations.size() < 5:
					reserved_violations.append("%d,%d,%s" % [x, y, key])
	for entry: Array in [
		["binary_alpha", soft_alpha, "invalid_samples=%s" % [soft_alpha]],
		["palette_membership", palette_violations, "invalid_samples=%s" % [palette_violations]],
		["reserved_colors", reserved_violations, "invalid_samples=%s" % [reserved_violations]],
	]:
		check = _add_check(checks, entry[0], (entry[1] as Array).is_empty(), entry[2])
		if not check["ok"]:
			return check
	var cells: Array[Dictionary] = []
	for row: int in range(2):
		for column: int in range(4):
			var cell := image.get_region(Rect2i(column * 192, row * 192, 192, 192))
			var bounds := PixelOps.opaque_bounds(cell)
			var label := "cell_%d_%d" % [row, column]
			check = _add_check(
				checks, "%s_non_empty" % label, bool(bounds["valid"]), "bounds=%s" % bounds
			)
			if not check["ok"]:
				return check
			var center_x := PixelOps.integer_midpoint(
				int(bounds["left"]), int(bounds["right"])
			)
			var cell_data := cell.get_data()
			var border_count := 0
			var opaque_count := 0
			for y: int in range(192):
				for x: int in range(192):
					if cell_data[(y * 192 + x) * 4 + 3] == 255:
						opaque_count += 1
						if x == 0 or x == 191 or y == 0 or y == 191:
							border_count += 1
			check = _add_check(
				checks, "%s_border" % label, border_count == 0,
				"opaque_border_pixels=%d" % border_count
			)
			if not check["ok"]:
				return check
			check = _add_check(
				checks, "%s_foot" % label,
				int(bounds["bottom"]) >= 179 and int(bounds["bottom"]) <= 181,
				"measured=%d expected=179..181" % int(bounds["bottom"])
			)
			if not check["ok"]:
				return check
			check = _add_check(
				checks, "%s_center" % label, center_x == 96,
				"measured=%d expected=96" % center_x
			)
			if not check["ok"]:
				return check
			cells.append({
				"row": row,
				"column": column,
				"opaque_pixels": opaque_count,
				"bounds": [bounds["left"], bounds["top"], bounds["right"], bounds["bottom"]],
				"center_x": center_x,
				"foot_row": bounds["bottom"],
			})
	check = _add_check(
		checks, "cell_inventory", cells.size() == 8, "measured=%d expected=8" % cells.size()
	)
	if not check["ok"]:
		return check
	var palette_hex: Array[String] = []
	for key: String in opaque_palette:
		var parts := key.split(",")
		palette_hex.append(_hex_rgb(parts[0].to_int(), parts[1].to_int(), parts[2].to_int()))
	palette_hex.sort()
	return {"ok": true, "checks": checks, "measurements": {
		"cells": cells, "opaque_palette": palette_hex
	}}


static func _inspect_contact(contact: Image, atlas: Image) -> Dictionary:
	var image := contact.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	var checks: Array[Dictionary] = []
	var check := _add_check(
		checks,
		"contact_dimensions",
		image.get_size() == Vector2i(1536, 256),
		"measured=%dx%d expected=1536x256" % [image.get_width(), image.get_height()]
	)
	if not check["ok"]:
		return check
	var expected := PixelOps.build_contact_sheet(atlas)
	var mismatch := image.get_data() != expected.get_data()
	check = _add_check(
		checks, "contact_exact_raster", not mismatch, "decoded_rgba_equal=%s" % (not mismatch)
	)
	if not check["ok"]:
		return check
	var samples := {
		"light": image.get_pixel(0, 0).to_rgba32(),
		"dark": image.get_pixel(512, 0).to_rgba32(),
		"grayscale": image.get_pixel(1024, 0).to_rgba32(),
	}
	var backgrounds := {
		"light": _rgba32_to_array(samples["light"]),
		"dark": _rgba32_to_array(samples["dark"]),
		"grayscale": _rgba32_to_array(samples["grayscale"]),
	}
	for entry: Array in [
		["contact_light_background", "light", [232, 223, 207, 255]],
		["contact_dark_background", "dark", [27, 34, 48, 255]],
		["contact_grayscale_background", "grayscale", [128, 128, 128, 255]],
	]:
		check = _add_check(
			checks, entry[0], backgrounds[entry[1]] == entry[2],
			"measured=%s" % [backgrounds[entry[1]]]
		)
		if not check["ok"]:
			return check
	return {"ok": true, "checks": checks, "measurements": {"backgrounds": backgrounds}}


static func _rgba32_to_array(value: int) -> Array[int]:
	return [
		(value >> 24) & 255,
		(value >> 16) & 255,
		(value >> 8) & 255,
		value & 255,
	]


static func _normalized_atlas_contract() -> Dictionary:
	return {
		"width": 768,
		"height": 384,
		"columns": 4,
		"rows": 2,
		"cell_width": 192,
		"cell_height": 192,
		"pivot": [0.5, 0.94],
		"foot_row": 180,
	}


static func _normalized_animations() -> Array[Dictionary]:
	return [
		{"name": "rest_movement", "row": 0, "frames": 4, "fps": 5.5, "loop": true},
		{"name": "attack_skill", "row": 1, "frames": 4, "fps": 8, "loop": true},
	]


static func _run_identity(spec: Dictionary, source_hashes: Array[Dictionary]) -> String:
	return _sha256_text(_canonical_json({
		"backend": "godot",
		"backend_version": Engine.get_version_info()["string"],
		"pipeline_version": PIPELINE_VERSION,
		"source_hashes": source_hashes,
		"spec": spec,
	}))


static func _metadata(
	spec: Dictionary,
	spec_path: String,
	source_hashes: Array[Dictionary],
	atlas: Image,
	atlas_path: String,
	contact: Image,
	contact_path: String
) -> Dictionary:
	return {
		"schema_version": 1,
		"asset_id": spec["asset_id"],
		"asset_class": spec["asset_class"],
		"state": spec["state"],
		"status": "STAGED_RUNTIME_UNBOUND",
		"backend": {
			"name": "godot",
			"godot": Engine.get_version_info()["string"],
			"pipeline": PIPELINE_VERSION,
		},
		"run_identity": _run_identity(spec, source_hashes),
		"spec_sha256": FileAccess.get_sha256(spec_path),
		"source_hashes": source_hashes,
		"atlas": _normalized_atlas_contract().merged({
			"file": spec["outputs"]["atlas"],
			"file_sha256": FileAccess.get_sha256(atlas_path),
			"rgba_sha256": _sha256_bytes(atlas.get_data()),
		}),
		"contact": {
			"width": 1536,
			"height": 256,
			"file": spec["outputs"]["contact"],
			"file_sha256": FileAccess.get_sha256(contact_path),
			"rgba_sha256": _sha256_bytes(contact.get_data()),
		},
		"animations": _normalized_animations(),
		"palette": spec["palette"],
		"reserved_colors": spec["reserved_colors"],
		"provenance": spec["provenance"],
		"human_final_art": "UNSET_HUMAN_ONLY",
		"runtime_binding": "UNBOUND_AGENT_F_SEAM",
	}


static func _report(
	spec: Dictionary,
	anchors: Array[Dictionary],
	atlas_qa: Dictionary,
	contact_qa: Dictionary
) -> Dictionary:
	var checks := (atlas_qa["checks"] as Array).duplicate()
	checks.append_array(contact_qa["checks"])
	return {
		"schema_version": 1,
		"asset_id": spec["asset_id"],
		"status": "PASS",
		"checks_executed": checks.size(),
		"checks": checks,
		"measurements": {
			"anchors": anchors,
			"atlas": atlas_qa["measurements"],
			"contact": contact_qa["measurements"],
		},
	}


static func _strict_equal(left: Variant, right: Variant) -> bool:
	if typeof(left) != typeof(right):
		return false
	if typeof(right) == TYPE_DICTIONARY:
		var left_dictionary := left as Dictionary
		var right_dictionary := right as Dictionary
		if left_dictionary.size() != right_dictionary.size():
			return false
		for key: Variant in right_dictionary:
			if not left_dictionary.has(key) or not _strict_equal(
				left_dictionary[key], right_dictionary[key]
			):
				return false
		return true
	if typeof(right) == TYPE_ARRAY:
		var left_array := left as Array
		var right_array := right as Array
		if left_array.size() != right_array.size():
			return false
		for index: int in range(right_array.size()):
			if not _strict_equal(left_array[index], right_array[index]):
				return false
		return true
	return left == right


static func _load_canonical_json(path: String, label: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return _failure("packet.%s invalid-json" % label)
	return {"ok": true, "value": parser.data}


static func _packet_entries(packet_dir: String) -> Dictionary:
	var directory := DirAccess.open(packet_dir)
	if directory == null:
		return _failure("packet expected=directory")
	var names: Array[String] = []
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		if name != "." and name != "..":
			if directory.current_is_dir() or directory.is_link(name):
				return _failure("packet.inventory non-regular-or-symlink=%s" % name)
			names.append(name)
		name = directory.get_next()
	directory.list_dir_end()
	names.sort()
	return {"ok": true, "names": names}


static func validate_packet(
	packet_dir: String, spec_path: String, input_root: String
) -> Dictionary:
	var version_check := _require_backend_version()
	if not version_check["ok"]:
		return version_check
	var contract := SpecContract.load_and_validate(spec_path, input_root)
	if not contract["ok"]:
		return contract
	var spec := contract["spec"] as Dictionary
	var sources := contract["sources"] as Array[String]
	var expected_names: Array[String] = []
	for key: String in ["atlas", "metadata", "qa", "contact"]:
		expected_names.append(String(spec["outputs"][key]))
	expected_names.sort()
	var entries := _packet_entries(packet_dir)
	if not entries["ok"]:
		return entries
	if entries["names"] != expected_names:
		return _failure("packet.inventory expected=%s actual=%s" % [expected_names, entries["names"]])
	var atlas_path := packet_dir.path_join(String(spec["outputs"]["atlas"]))
	var contact_path := packet_dir.path_join(String(spec["outputs"]["contact"]))
	var atlas := Image.load_from_file(atlas_path)
	var contact := Image.load_from_file(contact_path)
	if atlas == null or atlas.is_empty() or contact == null or contact.is_empty():
		return _failure("packet image decode failed")
	atlas.convert(Image.FORMAT_RGBA8)
	contact.convert(Image.FORMAT_RGBA8)
	var atlas_qa := _inspect_atlas(atlas, spec)
	if not atlas_qa["ok"]:
		return atlas_qa
	var contact_qa := _inspect_contact(contact, atlas)
	if not contact_qa["ok"]:
		return contact_qa
	var expected_raster := _normalized_atlas(spec, sources)
	if not expected_raster["ok"]:
		return expected_raster
	var expected_atlas := expected_raster["atlas"] as Image
	var expected_contact := PixelOps.build_contact_sheet(expected_atlas)
	if atlas.get_data() != expected_atlas.get_data():
		return _failure("packet.atlas.rgba differs-from-recomputed-contract")
	if contact.get_data() != expected_contact.get_data():
		return _failure("packet.contact.rgba differs-from-recomputed-contract")
	if FileAccess.get_file_as_bytes(atlas_path) != expected_atlas.save_png_to_buffer():
		return _failure("packet.atlas.png canonical-bytes mismatch")
	if FileAccess.get_file_as_bytes(contact_path) != expected_contact.save_png_to_buffer():
		return _failure("packet.contact.png canonical-bytes mismatch")
	var metadata_path := packet_dir.path_join(String(spec["outputs"]["metadata"]))
	var report_path := packet_dir.path_join(String(spec["outputs"]["qa"]))
	var metadata_result := _load_canonical_json(metadata_path, "metadata")
	if not metadata_result["ok"]:
		return metadata_result
	var report_result := _load_canonical_json(report_path, "report")
	if not report_result["ok"]:
		return report_result
	var hashes := _source_hashes(spec, sources)
	var expected_metadata := _metadata(
		spec, spec_path, hashes, atlas, atlas_path, contact, contact_path
	)
	var expected_report := _report(
		spec, expected_raster["anchors"], atlas_qa, contact_qa
	)
	if FileAccess.get_file_as_string(metadata_path) != _canonical_json(expected_metadata):
		return _failure("packet.metadata canonical-bytes mismatch")
	if FileAccess.get_file_as_string(report_path) != _canonical_json(expected_report):
		return _failure("packet.report canonical-bytes mismatch")
	if int(expected_report["checks_executed"]) <= 0:
		return _failure("packet.checks_executed measured=0 expected=>0")
	return {"ok": true, "checks_executed": expected_report["checks_executed"]}


static func prepare_packet(
	spec_path: String, input_root: String, candidate_dir: String
) -> Dictionary:
	var version_check := _require_backend_version()
	if not version_check["ok"]:
		return version_check
	if DirAccess.dir_exists_absolute(candidate_dir) or FileAccess.file_exists(candidate_dir):
		return _failure("candidate expected=absent")
	var contract := SpecContract.load_and_validate(spec_path, input_root)
	if not contract["ok"]:
		return contract
	var spec := contract["spec"] as Dictionary
	var sources := contract["sources"] as Array[String]
	if DirAccess.make_dir_recursive_absolute(candidate_dir) != OK:
		return _failure("candidate create failed")
	var raster := _normalized_atlas(spec, sources)
	if not raster["ok"]:
		return raster
	var atlas := raster["atlas"] as Image
	var contact := PixelOps.build_contact_sheet(atlas)
	var atlas_path := candidate_dir.path_join(String(spec["outputs"]["atlas"]))
	var contact_path := candidate_dir.path_join(String(spec["outputs"]["contact"]))
	if atlas.save_png(atlas_path) != OK or contact.save_png(contact_path) != OK:
		return _failure("packet PNG write failed")
	var atlas_qa := _inspect_atlas(atlas, spec)
	if not atlas_qa["ok"]:
		return atlas_qa
	var contact_qa := _inspect_contact(contact, atlas)
	if not contact_qa["ok"]:
		return contact_qa
	var hashes := _source_hashes(spec, sources)
	var metadata := _metadata(spec, spec_path, hashes, atlas, atlas_path, contact, contact_path)
	var report := _report(spec, raster["anchors"], atlas_qa, contact_qa)
	var write_result := _write_text(
		candidate_dir.path_join(String(spec["outputs"]["metadata"])), _canonical_json(metadata)
	)
	if not write_result["ok"]:
		return write_result
	write_result = _write_text(
		candidate_dir.path_join(String(spec["outputs"]["qa"])), _canonical_json(report)
	)
	if not write_result["ok"]:
		return write_result
	var validation := validate_packet(candidate_dir, spec_path, input_root)
	if not validation["ok"]:
		return validation
	return {"ok": true, "run_identity": metadata["run_identity"]}


static func _is_link(path: String) -> bool:
	var parent := DirAccess.open(path.get_base_dir())
	return parent != null and parent.is_link(path.get_file())


static func _preflight_removable_tree(path: String) -> Error:
	if _is_link(path) or FileAccess.file_exists(path):
		return OK
	if not DirAccess.dir_exists_absolute(path):
		return OK
	var directory := DirAccess.open(path)
	if directory == null:
		return ERR_CANT_OPEN
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		if name != "." and name != ".." and not directory.is_link(name):
			var child := path.path_join(name)
			if directory.current_is_dir():
				var error := _preflight_removable_tree(child)
				if error != OK:
					directory.list_dir_end()
					return error
		name = directory.get_next()
	directory.list_dir_end()
	var probe := "%s/.aui34-remove-probe.%d.%d" % [
		path, OS.get_process_id(), _preflight_sequence
	]
	_preflight_sequence += 1
	while FileAccess.file_exists(probe) or DirAccess.dir_exists_absolute(probe):
		probe = "%s/.aui34-remove-probe.%d.%d" % [
			path, OS.get_process_id(), _preflight_sequence
		]
		_preflight_sequence += 1
	var probe_file := FileAccess.open(probe, FileAccess.WRITE)
	if probe_file == null:
		return FileAccess.get_open_error()
	probe_file.close()
	var probe_cleanup := DirAccess.remove_absolute(probe)
	if probe_cleanup != OK:
		return probe_cleanup
	return OK


static func _read_link(path: String) -> Dictionary:
	var parent := DirAccess.open(path.get_base_dir())
	if parent == null or not parent.is_link(path.get_file()):
		return _failure("cleanup.salvage link expected name=%s" % path.get_file())
	return {"ok": true, "target": parent.read_link(path.get_file())}


static func _read_file_base64(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure(
			"cleanup.salvage read failed name=%s error=%d"
			% [path.get_file(), FileAccess.get_open_error()]
		)
	var bytes := file.get_buffer(file.get_length())
	file.close()
	return {"ok": true, "data_base64": Marshalls.raw_to_base64(bytes)}


static func _append_salvage_entries(
	root: String, current: String, entries: Array[Dictionary]
) -> Dictionary:
	var directory := DirAccess.open(current)
	if directory == null:
		return _failure("cleanup.salvage open failed name=%s" % current.get_file())
	var names: Array[String] = []
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		if name != "." and name != "..":
			names.append(name)
		name = directory.get_next()
	directory.list_dir_end()
	names.sort()
	for child_name: String in names:
		var child := current.path_join(child_name)
		var relative := child.trim_prefix(root.rstrip("/") + "/")
		if directory.is_link(child_name):
			var link := _read_link(child)
			if not link["ok"]:
				return link
			entries.append({"path": relative, "type": "symlink", "target": link["target"]})
		elif directory.dir_exists(child_name):
			entries.append({"path": relative, "type": "directory"})
			var nested := _append_salvage_entries(root, child, entries)
			if not nested["ok"]:
				return nested
		elif directory.file_exists(child_name):
			var file_payload := _read_file_base64(child)
			if not file_payload["ok"]:
				return file_payload
			entries.append({
				"path": relative,
				"type": "file",
				"data_base64": file_payload["data_base64"],
			})
		else:
			return _failure("cleanup.salvage unsupported-entry name=%s" % child_name)
	return {"ok": true}


static func _salvage_entry_before(left: Dictionary, right: Dictionary) -> bool:
	return String(left["path"]) < String(right["path"])


static func _salvage_payload(root: String) -> Dictionary:
	var entries: Array[Dictionary] = []
	if _is_link(root):
		var link := _read_link(root)
		if not link["ok"]:
			return link
		entries.append({"path": ".", "type": "symlink", "target": link["target"]})
	elif FileAccess.file_exists(root):
		var file_payload := _read_file_base64(root)
		if not file_payload["ok"]:
			return file_payload
		entries.append({
			"path": ".",
			"type": "file",
			"data_base64": file_payload["data_base64"],
		})
	elif DirAccess.dir_exists_absolute(root):
		var appended := _append_salvage_entries(root, root, entries)
		if not appended["ok"]:
			return appended
		entries.sort_custom(_salvage_entry_before)
	else:
		return _failure("cleanup.salvage root missing name=%s" % root.get_file())
	return {"ok": true, "payload": {"schema_version": 1, "entries": entries}}


static func _write_salvage(root: String, salvage: String) -> Dictionary:
	var payload_result := _salvage_payload(root)
	if not payload_result["ok"]:
		return payload_result
	var payload := payload_result["payload"] as Dictionary
	var temporary := "%s.candidate.%d.%d" % [
		salvage, OS.get_process_id(), _publish_sequence
	]
	_publish_sequence += 1
	if (
		FileAccess.file_exists(temporary)
		or DirAccess.dir_exists_absolute(temporary)
		or FileAccess.file_exists(salvage)
		or DirAccess.dir_exists_absolute(salvage)
	):
		return _failure("cleanup.salvage expected=absent actual=exists")
	var encoded := _canonical_json(payload)
	var written := _write_text(temporary, encoded)
	if not written["ok"]:
		return written
	var renamed := DirAccess.rename_absolute(temporary, salvage)
	if renamed != OK:
		DirAccess.remove_absolute(temporary)
		return _failure("cleanup.salvage rename failed error=%d" % renamed)
	if FileAccess.get_file_as_bytes(salvage) != encoded.to_utf8_buffer():
		return _failure("cleanup.salvage verification-failed")
	return {"ok": true}


static func _remove_entry(path: String) -> Error:
	if _remove_fault_after >= 0 and _remove_operations >= _remove_fault_after:
		return ERR_BUSY
	var error := DirAccess.remove_absolute(path)
	if error == OK:
		_remove_operations += 1
	return error


static func _remove_tree(path: String) -> Error:
	if _is_link(path):
		return _remove_entry(path)
	if FileAccess.file_exists(path):
		return _remove_entry(path)
	if not DirAccess.dir_exists_absolute(path):
		return OK
	var directory := DirAccess.open(path)
	if directory == null:
		return ERR_CANT_OPEN
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		if name != "." and name != "..":
			var child := path.path_join(name)
			var error: Error
			if directory.is_link(name):
				error = _remove_entry(child)
			elif directory.current_is_dir():
				error = _remove_tree(child)
			else:
				error = _remove_entry(child)
			if error != OK:
				directory.list_dir_end()
				return error
		name = directory.get_next()
	directory.list_dir_end()
	return _remove_entry(path)


static func _publish(candidate: String, output: String, clean: bool) -> Dictionary:
	if not DirAccess.dir_exists_absolute(output):
		var direct_error := DirAccess.rename_absolute(candidate, output)
		if direct_error != OK:
			return _failure("publication rename failed error=%d" % direct_error)
		return {"ok": true}
	if not clean:
		return _failure("output expected=absent-or-clean actual=exists")
	var backup := "%s.rollback.%d.%d" % [output, OS.get_process_id(), _publish_sequence]
	_publish_sequence += 1
	while DirAccess.dir_exists_absolute(backup):
		backup = "%s.rollback.%d.%d" % [output, OS.get_process_id(), _publish_sequence]
		_publish_sequence += 1
	var move_old := DirAccess.rename_absolute(output, backup)
	if move_old != OK:
		return _failure("publication backup failed error=%d" % move_old)
	var move_new := DirAccess.rename_absolute(candidate, output)
	if move_new != OK:
		var rollback := DirAccess.rename_absolute(backup, output)
		if rollback != OK:
			return _failure("publication cutover-and-rollback failed backup=%s" % backup.get_file())
		return _failure("publication cutover failed error=%d" % move_new)
	var salvage := "%s.salvage.json" % backup
	var salvage_result := _write_salvage(backup, salvage)
	if not salvage_result["ok"]:
		return _failure(
			"publication committed but backup salvage failed; accepted packet preserved"
		)
	var cleanup_error := _preflight_removable_tree(backup)
	if cleanup_error != OK:
		return _failure(
			"publication committed but backup cleanup failed preflight error=%d; "
			+ "complete rollback retained as %s" % [cleanup_error, salvage.get_file()]
		)
	cleanup_error = _remove_tree(backup)
	if cleanup_error != OK:
		return _failure(
			"publication committed but backup cleanup failed error=%d; "
			+ "complete rollback retained as %s" % [cleanup_error, salvage.get_file()]
		)
	var salvage_cleanup := DirAccess.remove_absolute(salvage)
	if salvage_cleanup != OK:
		return _failure(
			"publication committed but salvage cleanup failed error=%d; "
			+ "complete rollback retained as %s" % [salvage_cleanup, salvage.get_file()]
		)
	return {"ok": true}


static func publish_with_fault_for_test(
	candidate: String, output: String, clean: bool, fault_after: int
) -> Dictionary:
	_remove_fault_after = fault_after
	_remove_operations = 0
	var result := _publish(candidate, output, clean)
	_remove_fault_after = -1
	_remove_operations = 0
	return result


static func build_packet(
	spec_path: String, input_root: String, output: String, clean: bool
) -> Dictionary:
	var version_check := _require_backend_version()
	if not version_check["ok"]:
		return version_check
	if DirAccess.dir_exists_absolute(output) and not clean:
		return _failure("output expected=absent-or-clean actual=exists")
	var candidate := "%s.candidate.%d" % [output, OS.get_process_id()]
	var cleanup_error := _remove_tree(candidate)
	if cleanup_error != OK:
		return _failure("candidate pre-clean failed error=%d" % cleanup_error)
	var prepared := prepare_packet(spec_path, input_root, candidate)
	if not prepared["ok"]:
		cleanup_error = _remove_tree(candidate)
		if cleanup_error != OK:
			return _failure("candidate failure cleanup failed error=%d" % cleanup_error)
		return prepared
	var published := _publish(candidate, output, clean)
	if not published["ok"]:
		cleanup_error = _remove_tree(candidate)
		if cleanup_error != OK:
			return _failure("candidate publish cleanup failed error=%d" % cleanup_error)
		return published
	return prepared
