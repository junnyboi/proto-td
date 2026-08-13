extends GutTest

const HEROES: Array[String] = ["caster_1", "caster_2", "defender_2", "sniper_1", "sniper_2"]
const DIRECTIONS: Array[String] = ["se", "ne", "nw", "sw"]
const SOURCE_PATH := "res://assets/provenance/operators/aetheria-part2-source-manifest.json"
const RUNTIME_PATH := "res://assets/provenance/operators/operator-animation-v1.json"


func test_source_inventory_and_placeholder_set_are_exact() -> void:
	var source := _load_json(SOURCE_PATH)
	assert_eq(source.get("schema_version"), 1)
	var assets: Array = source.get("assets", [])
	assert_eq(assets.size(), 40)
	var placeholders: Array[String] = []
	for raw_row: Variant in assets:
		var row := raw_row as Dictionary
		if bool(row.get("placeholder", false)):
			placeholders.append(
				"%s/%s/%s<-%s"
				% [row["hero"], row["state"], row["direction"], row["placeholder_source_direction"]]
			)
	placeholders.sort()
	assert_eq(placeholders, ["sniper_2/attacking/ne<-se", "sniper_2/attacking/nw<-sw"])


func test_runtime_catalog_preserves_source_hashes_and_pinned_sampling() -> void:
	var source := _load_json(SOURCE_PATH)
	var runtime := _load_json(RUNTIME_PATH)
	var source_by_key: Dictionary = {}
	for raw_row: Variant in source.get("assets", []):
		var row := raw_row as Dictionary
		source_by_key[_key(row["hero"], row["state"], row["direction"])] = row
	var runtime_by_id: Dictionary = {}
	for raw_class: Variant in runtime.get("classes", []):
		var class_row := raw_class as Dictionary
		runtime_by_id[String(class_row.get("template_id", ""))] = class_row
	for hero: String in HEROES:
		assert_true(runtime_by_id.has(hero), hero)
		var class_row := runtime_by_id[hero] as Dictionary
		for state: String in ["idle", "attack"]:
			var source_state := "idle" if state == "idle" else "attacking"
			var expected_frames := PackedInt32Array(
				range(24) if state == "idle" else range(0, 25, 2)
			)
			for direction: String in DIRECTIONS:
				var runtime_row := class_row["families"][state][direction] as Dictionary
				var source_row := source_by_key[_key(hero, source_state, direction)] as Dictionary
				assert_eq(runtime_row["source_sha256"], source_row["sha256"])
				assert_eq(
					PackedInt32Array(runtime_row["selected_source_frames"]),
					expected_frames,
				)
				assert_eq(runtime_row["frame_count"], expected_frames.size())
				assert_eq(runtime_row["placeholder"], source_row["placeholder"])
				assert_eq(
					runtime_row["placeholder_source_direction"],
					source_row["placeholder_source_direction"],
				)


func _key(hero: Variant, state: Variant, direction: Variant) -> String:
	return "%s/%s/%s" % [hero, state, direction]


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert_true(parsed is Dictionary, path)
	return parsed as Dictionary if parsed is Dictionary else {}
