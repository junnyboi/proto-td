extends GutTest

const ContractLint = preload("res://tools/presentation_qa/contract_lint.gd")
const MANIFEST_PATH := "res://assets/manifest.tres"
const SNAPSHOT_PATH := "res://tools/presentation_qa/legacy_manifest_snapshot.json"
const REGISTRY_PATH := "res://data/presentation/probe_color_owners.tres"
const THEME_PATH := "res://addons/gut/gui/GutSceneTheme.tres"
const BASE_COMMIT := "975261e8e00a20a0b25fe17e7976d743d509c14b"
const BASE_TREE := "cf4b3e1c0d8ae826c668765d994a032acbb8c0ad"


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "%s opens" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _manifest() -> AssetManifest:
	return load(MANIFEST_PATH) as AssetManifest


func test_manifest_v2_preserves_every_legacy_path_frame_size_placeholder_and_png_byte() -> void:
	var manifest := _manifest()
	var snapshot := _json(SNAPSHOT_PATH)
	assert_not_null(manifest)
	if manifest == null:
		return
	assert_eq(manifest.schema_version, 2)
	assert_eq(snapshot.get("base_commit"), BASE_COMMIT)
	assert_eq(snapshot.get("base_tree"), BASE_TREE)
	assert_eq(manifest.validate_contract(), PackedStringArray())
	var expected: Dictionary = snapshot.get("entries", {})
	assert_eq(manifest.entries.size(), expected.size() + 14)
	for healer_id: StringName in [&"witch_doctor_1", &"portrait_witch_doctor_1"]:
		assert_true(manifest.entries.has(healer_id), "%s added through the manifest" % healer_id)
		assert_true(manifest.entries[healer_id][&"placeholder"], "%s remains placeholder" % healer_id)
	for raw_id: Variant in expected:
		var id := StringName(raw_id)
		assert_true(manifest.entries.has(id), "manifest retains %s" % id)
		if not manifest.entries.has(id):
			continue
		var entry: Dictionary = manifest.entries[id]
		var frozen: Dictionary = expected[raw_id]
		assert_eq(entry[&"pattern"], frozen["pattern"], "%s pattern" % id)
		assert_eq(entry[&"frames"], int(frozen["frames"]), "%s frames" % id)
		assert_eq(entry[&"size"], Vector2i(frozen["size"][0], frozen["size"][1]), "%s size" % id)
		assert_eq(entry[&"placeholder"], frozen["placeholder"], "%s placeholder" % id)
		assert_eq(
			entry[&"pivot"],
			AssetManifest.legacy_pivot(id, int(entry[&"frames"])),
			"%s pivot" % id,
		)
		assert_eq(
			entry[&"animations"],
			AssetManifest.legacy_animations(int(entry[&"frames"])),
			"%s animation table" % id,
		)
		for file_index: int in frozen["files"].size():
			var file_row: Dictionary = frozen["files"][file_index]
			var path := String(file_row["path"])
			assert_eq(
				FileAccess.get_sha256(path), file_row["sha256"], "%s legacy PNG bytes" % path
			)
			var tex := Art.texture(id, file_index)
			assert_not_null(tex, "%s resolves" % path)


func test_art_metadata_is_deep_copied_sorted_and_fail_closed() -> void:
	var metadata := Art.metadata(&"caster_1")
	assert_eq(Art.animation_names(&"caster_1"), [&"attack", &"deploy", &"idle"])
	assert_eq(Art.animation_frame_index(&"caster_1", &"attack", 0), 2)
	assert_eq(Art.animation_frame_index(&"caster_1", &"attack", 1), 3)
	assert_eq(Art.animation_frame_index(&"caster_1", &"attack", 2), -1)
	assert_eq(Art.pivot(&"caster_1"), Vector2(0.5, 1.0))
	assert_not_null(Art.animation_texture(&"caster_1", &"deploy", 0))
	metadata[&"frames"] = 999
	metadata[&"animations"][&"idle"][&"start"] = 99
	assert_eq(Art.frame_count(&"caster_1"), 5, "metadata copy cannot mutate manifest")
	assert_eq(Art.animation_frame_index(&"caster_1", &"idle", 0), 0)
	assert_eq(Art.metadata(&"missing"), {})
	assert_eq(Art.pivot(&"missing"), Vector2.ZERO)
	assert_eq(Art.animation_names(&"missing"), [])
	assert_eq(Art.animation_frame_index(&"missing", &"idle", 0), -1)
	assert_null(Art.animation_texture(&"missing", &"idle", 0))
	assert_eq(Art.provenance_sha256(&"missing"), "")


func test_manifest_rejects_wrong_nested_types_ranges_and_mapping() -> void:
	var manifest := AssetManifest.new()
	var valid := {
		"pattern": "res://assets/sprites/icon_bolt.png",
		"frames": 1,
		"size": Vector2i(24, 24),
		"placeholder": false,
		"pivot": Vector2(0.5, 0.5),
		"animations": AssetManifest.legacy_animations(1),
		"provenance_sha256": "a".repeat(64),
	}
	assert_eq(manifest.entry_diagnostics(&"fixture", valid), PackedStringArray())
	var wrong_fps := valid.duplicate(true)
	wrong_fps["animations"][&"default"][&"fps"] = 1
	assert_true(manifest.entry_diagnostics(&"fixture", wrong_fps).size() > 0)
	var extra := valid.duplicate(true)
	extra["unexpected"] = true
	assert_true(manifest.entry_diagnostics(&"fixture", extra).size() > 0)
	var out_of_bounds := valid.duplicate(true)
	out_of_bounds["animations"][&"default"][&"length"] = 2
	assert_true(manifest.entry_diagnostics(&"fixture", out_of_bounds).size() > 0)
	var wrong_pivot := valid.duplicate(true)
	wrong_pivot["pivot"] = Vector2(2.0, 0.5)
	assert_true(manifest.entry_diagnostics(&"fixture", wrong_pivot).size() > 0)
	var wrong_region_type := valid.duplicate(true)
	wrong_region_type["frames"] = 5
	wrong_region_type["animations"] = AssetManifest.legacy_animations(5)
	wrong_region_type["animations"][&"attack"] = 7
	assert_true(
		manifest.entry_diagnostics(&"fixture", wrong_region_type).has(
			"animations.attack: expected Dictionary"
		),
		"wrong nested region Variant fails closed without a typed crash",
	)
	var int64_max: int = 9223372036854775807
	var overflow_start := valid.duplicate(true)
	overflow_start["frames"] = 3
	overflow_start["animations"] = {
		&"overflow": {&"start": int64_max, &"length": 2, &"fps": 1.0, &"loop": false},
	}
	assert_true(
		manifest.entry_diagnostics(&"fixture", overflow_start).has(
			"animations.overflow: region out of bounds"
		),
		"INT64_MAX start cannot wrap into the frame range",
	)
	var overflow_length := valid.duplicate(true)
	overflow_length["frames"] = 3
	overflow_length["animations"] = {
		&"overflow": {&"start": 2, &"length": int64_max, &"fps": 1.0, &"loop": false},
	}
	assert_true(
		manifest.entry_diagnostics(&"fixture", overflow_length).has(
			"animations.overflow: region out of bounds"
		),
		"INT64_MAX length cannot wrap into the frame range",
	)
	var near_max_frames := valid.duplicate(true)
	near_max_frames["frames"] = int64_max
	near_max_frames["animations"] = {
		&"overflow": {
			&"start": int64_max - 1, &"length": 2, &"fps": 1.0, &"loop": false,
		},
	}
	assert_true(
		manifest.entry_diagnostics(&"fixture", near_max_frames).has(
			"animations.overflow: region out of bounds"
		),
		"near-maximum end cannot overflow",
	)
	var overflow_overlap := overflow_start.duplicate(true)
	overflow_overlap["animations"][&"valid"] = {
		&"start": 0, &"length": 1, &"fps": 1.0, &"loop": false,
	}
	var overlap_errors := manifest.entry_diagnostics(&"fixture", overflow_overlap)
	assert_true(overlap_errors.has("animations.overflow: region out of bounds"))
	assert_false(
		overlap_errors.has("animations: non-identical overlap overflow/valid"),
		"invalid maximum region cannot wrap into a false overlap",
	)


func test_all_six_resource_contracts_reject_defaults_and_roundtrip_valid_values() -> void:
	var resources: Array[Resource] = [
		StagePresentationDef.new(), EnvironmentTheme.new(), UiMaterialTier.new(),
		TacticalCueConfig.new(), CharacterVisualDef.new(), ProbeColorOwnerRegistry.new(),
	]
	for resource: Resource in resources:
		assert_true(
			resource.validate_contract().size() > 0,
			"%s defaults fail closed" % resource.get_class(),
		)
		resource.schema_version = 0
		assert_true(
			resource.validate_contract().size() > 0, "%s rejects v0" % resource.get_class()
		)
		resource.schema_version = 2
		assert_true(
			resource.validate_contract().size() > 0, "%s rejects v2" % resource.get_class()
		)

	var valid: Array[Resource] = [_stage(), _environment(), _material(), _cues(), _character()]
	for index: int in valid.size():
		var resource := valid[index]
		var before := _exported_values(resource)
		assert_eq(
			resource.validate_contract(),
			PackedStringArray(),
			"%s is valid" % resource.get_script().resource_path,
		)
		var path := "user://aui00_contract_roundtrip_%d.tres" % index
		assert_eq(ResourceSaver.save(resource, path), OK)
		var reloaded := load(path)
		assert_not_null(reloaded)
		if reloaded != null:
			assert_eq(
				reloaded.validate_contract(),
				PackedStringArray(),
				"%s survives roundtrip" % path,
			)
			assert_eq(_exported_values(reloaded), before, "%s exported values" % path)

	var registry := load(REGISTRY_PATH) as ProbeColorOwnerRegistry
	assert_not_null(registry)
	if registry != null:
		assert_eq(registry.entries.size(), 13)
		assert_eq(registry.entries, ProbeColorOwnerRegistry.expected_entries())
		assert_eq(registry.validate_contract(), PackedStringArray())
		var registry_path := "user://aui00_contract_roundtrip_registry.tres"
		assert_eq(ResourceSaver.save(registry, registry_path), OK)
		var reloaded_registry := load(registry_path) as ProbeColorOwnerRegistry
		assert_not_null(reloaded_registry)
		if reloaded_registry != null:
			assert_eq(reloaded_registry.entries, registry.entries)


func test_reserved_stage_domains_and_malformed_nested_resources_fail_closed() -> void:
	var stage := _stage()
	stage.prop_mask_id = &"invented"
	assert_true(stage.validate_contract().has("prop_mask_id: reserved_in_schema_v1"))
	stage.prop_mask_id = &""
	stage.landmark_scene_paths.append("res://missing.tscn")
	assert_true(stage.validate_contract().size() > 0)
	var environment := _environment()
	environment.tile_asset_ids[&"extra"] = &"tile_ground"
	assert_true(environment.validate_contract().size() > 0)
	environment = _environment()
	environment.tile_asset_ids[&"ground"] = "tile_ground"
	assert_true(environment.validate_contract().size() > 0)
	var material := _material()
	material.type_variations[&"extra"] = &"Panel"
	assert_true(material.validate_contract().size() > 0)
	material = _material()
	material.type_variations[&"hud_panel"] = "Panel"
	assert_true(material.validate_contract().size() > 0)
	var cues := _cues()
	cues.cues[&"legal"][&"motion"] = &"spin"
	assert_true(cues.validate_contract().size() > 0)
	cues = _cues()
	cues.cues[&"legal"][&"color"] = "not a Color"
	assert_true(cues.validate_contract().size() > 0)
	var invalid_components: Array[float] = [NAN, INF, -INF, -0.001, 1.001]
	for channel: StringName in [&"r", &"g", &"b", &"a"]:
		for invalid_component: float in invalid_components:
			cues = _cues()
			var malformed_color := Color(0.5, 0.5, 0.5, 1.0)
			match channel:
				&"r": malformed_color.r = invalid_component
				&"g": malformed_color.g = invalid_component
				&"b": malformed_color.b = invalid_component
				&"a": malformed_color.a = invalid_component
			cues.cues[&"legal"][&"color"] = malformed_color
			assert_true(
				cues.validate_contract().size() > 0,
				"malformed cue color %s component rejects" % channel,
			)
	cues = _cues()
	cues.ambient_suppression = NAN
	assert_true(cues.validate_contract().size() > 0)
	var character := _character()
	character.animation_aliases[&"unknown"] = &"walk"
	assert_true(character.validate_contract().size() > 0)
	character = _character()
	character.contour_px = NAN
	assert_true(character.validate_contract().size() > 0)
	var registry := load(REGISTRY_PATH).duplicate(true) as ProbeColorOwnerRegistry
	registry.entries[0]["unexpected"] = true
	assert_true(registry.validate_contract().size() > 0)
	registry = load(REGISTRY_PATH).duplicate(true) as ProbeColorOwnerRegistry
	registry.entries[0]["semantic"] = &"attack_tracer"
	assert_true(registry.validate_contract().size() > 0, "wrong allowed semantic rejects")
	registry = load(REGISTRY_PATH).duplicate(true) as ProbeColorOwnerRegistry
	registry.entries[0]["status"] = &"legacy_exception"
	assert_true(registry.validate_contract().size() > 0, "wrong allowed status rejects")
	registry = load(REGISTRY_PATH).duplicate(true) as ProbeColorOwnerRegistry
	registry.entries[0]["owner_id"] = &"arbitrary.valid_type"
	assert_true(registry.validate_contract().size() > 0, "wrong owner rejects")
	registry = load(REGISTRY_PATH).duplicate(true) as ProbeColorOwnerRegistry
	registry.entries[7]["negative_owner_id"] = &"heavy"
	assert_true(registry.validate_contract().size() > 0, "wrong negative pair rejects")
	registry = load(REGISTRY_PATH).duplicate(true) as ProbeColorOwnerRegistry
	var first: Dictionary = registry.entries[0]
	registry.entries[0] = registry.entries[1]
	registry.entries[1] = first
	assert_true(registry.validate_contract().size() > 0, "wrong row order rejects")


func test_probe_asset_owners_require_every_positive_frame_and_exact_negative_pairs() -> void:
	var manifest := _manifest()
	assert_not_null(manifest)
	if manifest == null:
		return
	for row: Dictionary in ProbeColorOwnerRegistry.EXPECTED_ENTRIES:
		if row["owner_kind"] != &"asset":
			continue
		var entry: Dictionary = manifest.entries[row["owner_id"]]
		assert_true(
			ContractLint.entry_all_frames_contain_color(entry, row["color_html"]),
			"%s owns signal in every expanded frame" % row["owner_id"],
		)
		if row["differential_required"]:
			assert_false(
				ContractLint.entry_any_frame_contains_color(
					manifest.entries[row["negative_owner_id"]], row["color_html"]
				),
				"%s is the exact signal-negative pair" % row["negative_owner_id"],
			)
	var positive := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	positive.fill(Color.TRANSPARENT)
	positive.set_pixel(0, 0, Color("41a6f6"))
	var negative := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	negative.fill(Color.TRANSPARENT)
	assert_eq(positive.save_png("user://aui00_positive_0.png"), OK)
	assert_eq(negative.save_png("user://aui00_positive_1.png"), OK)
	var partial_entry := {
		"pattern": "user://aui00_positive_%d.png",
		"frames": 2,
	}
	assert_true(ContractLint.entry_any_frame_contains_color(partial_entry, "41a6f6"))
	assert_false(
		ContractLint.entry_all_frames_contain_color(partial_entry, "41a6f6"),
		"one positive frame cannot prove a multi-frame owner",
	)


func test_generator_inventory_uses_explicit_string_lexical_order() -> void:
	var file := FileAccess.open("res://tools/gen_assets.gd", FileAccess.READ)
	assert_not_null(file)
	if file == null:
		return
	var source := file.get_as_text()
	assert_true(source.contains("ids.sort_custom"))
	assert_true(source.contains("String(a) < String(b)"))
	assert_false(source.contains("\tids.sort()\n"))


func test_provenance_is_canonical_truthful_complete_and_manifest_bound() -> void:
	var manifest := _manifest()
	assert_not_null(manifest)
	if manifest == null:
		return
	for raw_id: Variant in manifest.entries:
		var id := String(raw_id)
		var path := "res://assets/provenance/%s.provenance.json" % id
		var file := FileAccess.open(path, FileAccess.READ)
		assert_not_null(file, "%s exists" % path)
		if file == null:
			continue
		var text := file.get_as_text()
		assert_eq(text.count("\n"), 1, "%s compact with terminal newline" % id)
		assert_false(text.contains(": "), "%s has no insignificant whitespace" % id)
		var document: Dictionary = JSON.parse_string(text)
		assert_eq(document.keys().size(), 10)
		assert_eq(document["logical_id"], id)
		assert_eq(document["migration"]["baseline_commit"], BASE_COMMIT)
		assert_eq(document["migration"]["baseline_tree"], BASE_TREE)
		if id.begins_with("world.s1."):
			assert_eq(document["source_type"], "ai_assisted_deterministic_normalization")
			assert_eq(document["generation"]["model"], "gpt-image-2")
			assert_eq(document["acceptance"]["state"], "human_final_accepted")
			assert_eq(document["acceptance"]["human_accepter"], "Poseidon")
			assert_eq(
				document["acceptance"]["accepting_commit"],
				"60b69a6004a9c843851d9f6c9aee84c88389cb1f",
			)
		else:
			assert_eq(document["acceptance"]["state"], "unknown_per_current_byte")
			assert_null(document["acceptance"]["human_accepter"])
			assert_null(document["acceptance"]["accepting_commit"])
		assert_eq(FileAccess.get_sha256(path), Art.provenance_sha256(StringName(id)))
		var actual_sources: Array[String] = []
		for source: Dictionary in document["source_files"]:
			actual_sources.append(source["path"])
			assert_eq(
				FileAccess.get_sha256(source["path"]),
				source["sha256"],
				"%s source digest" % id,
			)
		actual_sources.sort()
		assert_eq(actual_sources, _expected_sources(id), "%s exact source closure" % id)
	assert_true(manifest.entries.has(&"tile_backdrop"), "post-218 asset covered")
	var caster := _json("res://assets/provenance/portrait_caster_1.provenance.json")
	assert_eq(
		caster["acceptance"]["state"],
		"unknown_per_current_byte",
		"later portrait bytes not mislabeled",
	)


func test_presentation_contract_sources_never_reference_simulation() -> void:
	var dir := DirAccess.open("res://data/presentation")
	assert_not_null(dir)
	if dir == null:
		return
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".gd"):
			continue
		var file := FileAccess.open("res://data/presentation/%s" % file_name, FileAccess.READ)
		assert_not_null(file)
		if file != null:
			assert_false(file.get_as_text().contains("sim/"), "%s has no sim import" % file_name)


func _stage() -> StagePresentationDef:
	var value := StagePresentationDef.new()
	value.stage_id = &"s1"
	value.environment_theme_id = &"environment.default"
	value.ui_material_tier_id = &"ui.default"
	value.landmark_scene_paths = ["res://scenes/title.tscn"]
	return value


func _environment() -> EnvironmentTheme:
	var value := EnvironmentTheme.new()
	value.theme_id = &"environment.default"
	value.tile_asset_ids = {
		&"void": &"tile_void", &"ground": &"tile_ground", &"road": &"tile_road",
		&"elevated": &"tile_elevated", &"spawn": &"tile_spawn", &"base": &"tile_base",
		&"blocked": &"tile_blocked", &"backdrop": &"tile_backdrop",
	}
	value.backdrop_asset_id = &"tile_backdrop"
	return value


func _material() -> UiMaterialTier:
	var value := UiMaterialTier.new()
	value.tier_id = &"ui.default"
	value.theme_path = THEME_PATH
	for role: StringName in UiMaterialTier.REQUIRED_ROLES:
		value.type_variations[role] = StringName("Aui%s" % String(role).to_pascal_case())
	return value


func _cues() -> TacticalCueConfig:
	var value := TacticalCueConfig.new()
	value.config_id = &"cue.default"
	for state: StringName in TacticalCueConfig.STATES:
		value.cues[state] = {
			&"color": Color("c7d6e8"),
			&"geometry": &"solid_diamond",
			&"pattern": &"solid",
			&"icon_asset_id": &"",
			&"label_key": StringName("ui.aetheria.cue.%s" % state),
			&"english_fallback": "Test %s" % state,
			&"motion": &"none",
		}
	return value


func _character() -> CharacterVisualDef:
	var value := CharacterVisualDef.new()
	value.visual_id = &"visual.caster_1"
	value.sprite_asset_id = &"caster_1"
	value.portrait_asset_id = &"portrait_caster_1"
	value.animation_aliases = {&"idle": &"idle", &"attack": &"attack", &"deploy": &"deploy"}
	value.provenance_sha256 = "a".repeat(64)
	return value


func _expected_sources(id: String) -> Array[String]:
	if id.begins_with("world.s1."):
		var world_sources: Array[String] = [
			"res://art-src/world/s1/gpt-image-2-source-ledger.json",
			"res://art-src/world/s1/s1-derived-palette.json",
			"res://art-src/world/s1/s1-world-asset-contract.json",
			"res://art-src/world/s1/s1-world-gpt-image-2-prompts.md",
			"res://docs/media/AUI-10R-REVISION-2-HUMAN-APPROVAL.json",
			"res://docs/media/AUI-DESIGN-D-REVISION-CORE-C-BACKDROP-B.json",
			"res://docs/media/AUI-DESIGN-D-approved-manifest.json",
			"res://tools/art_pipeline/world/generate_s1_revision_v2.py",
			"res://tools/art_pipeline/world/normalize_s1_world.py",
		]
		if id == "world.s1.backdrop_panorama":
			world_sources.append("res://art-src/world/s1/s1-alpine-escarpment-source.png")
			world_sources.append("res://tools/art_pipeline/world/prepare_s1_revision_source.py")
		world_sources.sort()
		return world_sources
	var result: Array[String] = [
		"res://assets/asset_manifest.gd",
		"res://tools/gen_assets.gd",
		"res://tools/pixel/palette.gd",
		"res://tools/pixel/pix.gd",
	]
	if id.begins_with("tile_"):
		result.append("res://tools/pixel/art_tiles.gd")
	elif id.begins_with("portrait_"):
		var op := id.trim_prefix("portrait_")
		result.append_array([
			"res://data/operator_def.gd", "res://data/operators/%s.tres" % op,
			"res://tools/pixel/art_operators.gd", "res://tools/pixel/art_portraits.gd",
		])
	elif id.begins_with("trap_") or id.begins_with("icon_"):
		result.append("res://tools/pixel/art_props.gd")
	elif id in [
		"caster_1", "caster_2", "defender_1", "defender_2", "guard_1", "guard_2",
		"sniper_1", "sniper_2", "vanguard_1", "vanguard_2", "witch_doctor_1",
	]:
		result.append_array([
			"res://data/operator_def.gd", "res://data/operators/%s.tres" % id,
			"res://tools/pixel/art_operators.gd",
		])
	else:
		var enemy := id.trim_suffix("_charmed")
		result.append_array([
			"res://data/enemies/%s.tres" % enemy, "res://data/enemy_def.gd",
			"res://tools/pixel/art_enemies.gd",
		])
	result.sort()
	return result


func _exported_values(resource: Resource) -> Dictionary:
	var result: Dictionary = {}
	for property: Dictionary in resource.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var name := StringName(property["name"])
			result[name] = resource.get(name)
	return result
