extends GutTest

const EXPECTED := {
	&"world.act1.ground": ["ground.png", Vector2i(64, 32)],
	&"world.act1.route": ["route.png", Vector2i(64, 32)],
	&"world.act1.raised": ["raised.png", Vector2i(64, 48)],
	&"world.act1.blocked": ["blocked.png", Vector2i(64, 32)],
	&"world.act1.spawn": ["spawn.png", Vector2i(64, 32)],
	&"world.act1.core": ["core.png", Vector2i(64, 32)],
	&"world.act1.panorama": ["panorama.png", Vector2i(512, 256)],
}
const COUNTS := {&"s1": 45, &"s2": 55, &"s3": 64}

var base: AssetManifest
var supplement: AssetManifest
var stages: Dictionary = {}
var themes: Dictionary = {}


func before_all() -> void:
	base = load("res://assets/manifest.tres") as AssetManifest
	supplement = load("res://assets/act1_shared_manifest.tres") as AssetManifest
	for id: StringName in [&"s1", &"s2", &"s3"]:
		stages[id] = load("res://data/stages/%s.tres" % id) as StageDef
		themes[id] = load("res://data/presentation/%s_world_theme.tres" % id) as StageArtTheme
	Art._reset_manifests_for_test()


func test_supplement_is_valid_disjoint_and_exactly_seven_placeholders() -> void:
	assert_not_null(base)
	assert_not_null(supplement)
	assert_eq(base.validate_contract(), PackedStringArray())
	assert_eq(supplement.validate_contract(), PackedStringArray())
	assert_eq(supplement.entries.size(), 7)
	assert_eq(EXPECTED.size(), 7)
	for id: StringName in supplement.entries:
		assert_true(EXPECTED.has(id), "unexpected supplemental ID %s" % id)
		assert_false(base.entries.has(id), "duplicate across manifest layers: %s" % id)
		assert_true(bool(supplement.entries[id]["placeholder"]), "%s remains placeholder" % id)


func test_runtime_staging_bytes_textures_sizes_and_provenance_bindings() -> void:
	for id: StringName in EXPECTED:
		var filename: String = EXPECTED[id][0]
		var size: Vector2i = EXPECTED[id][1]
		var runtime := "res://assets/world/act1/%s" % filename
		var staging := "res://staging/assets/world/act1/%s" % filename
		var fragment := (
			"res://assets/provenance/fragments/act1/%s.provenance.json"
			% String(id).replace(".", "_")
		)
		var entry: Dictionary = supplement.entries[id]
		assert_eq(entry["pattern"], runtime)
		assert_eq(entry["size"], size)
		assert_eq(
			FileAccess.get_sha256(runtime),
			FileAccess.get_sha256(staging),
			"%s runtime/staging" % id
		)
		assert_eq(
			String(entry["provenance_sha256"]),
			FileAccess.get_sha256(fragment),
			"%s provenance" % id
		)
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fragment))
		assert_eq(data["logical_id"], String(id))
		assert_eq(data["approval"]["token"], "ACT-I-S1-S3-OWNER-TILES-V2")
		assert_false(bool(data["human_final_art"]))
		assert_eq(Art.size(id), size)
		assert_not_null(Art.texture(id))


func test_all_three_themes_share_exact_contract_and_validate() -> void:
	for id: StringName in [&"s1", &"s2", &"s3"]:
		var stage: StageDef = stages[id]
		var theme: StageArtTheme = themes[id]
		assert_eq(theme.validation_errors(stage), PackedStringArray(), "%s validates" % id)
		assert_eq(theme.theme_id, StageArtTheme.SHARED_THEME_ID)
		assert_eq(theme.approval_token, StageArtTheme.APPROVAL_TOKEN)
		assert_false(theme.human_final_art)
		assert_eq(theme.surface_modulate, Color.WHITE)
		assert_eq(theme.required_manifest_ids(), StageArtTheme.SHARED_IDS)
		assert_eq(theme.backdrop_panorama_id, &"world.act1.panorama")
		assert_eq(theme.tile_id(StageDef.Tile.SPAWN, false), &"world.act1.ground")
		assert_eq(theme.tile_id(StageDef.Tile.BASE, false), &"world.act1.ground")
		assert_eq(
			theme.resolve_cell(Vector2i(1, 1), StageDef.Tile.GROUND, false)["cadence_id"], &""
		)


func test_exact_topology_role_textures_zero_cadence_and_node_counts() -> void:
	for id: StringName in [&"s1", &"s2", &"s3"]:
		var stage: StageDef = stages[id]
		var theme: StageArtTheme = themes[id]
		var root := Node2D.new()
		assert_true(IsoGridBuilder.build_stage_with_theme(root, stage, theme, false))
		assert_eq(root.get_child_count(), COUNTS[id], "%s GridRoot count" % id)
		assert_eq(_prefix_count(root, "Cadence_"), 0, "%s cadence count" % id)
		assert_eq(_prefix_count(root, "Backdrop"), 1, "%s panorama count" % id)
		_check_texture(root, "BackdropPanorama", &"world.act1.panorama")
		_check_texture(root, "SpawnLandmark", &"world.act1.spawn")
		_check_texture(root, "CoreLandmark", &"world.act1.core")
		for cell: Vector2i in theme.elevated_cells:
			_check_texture(root, "Tile_%d_%d" % [cell.x, cell.y], &"world.act1.raised")
		for cell: Vector2i in theme.blocked_cells:
			_check_texture(root, "Tile_%d_%d" % [cell.x, cell.y], &"world.act1.blocked")
		root.free()


func test_missing_theme_and_duplicate_manifest_merge_fail_closed() -> void:
	var missing := func(_path: String) -> Resource: return null
	for id: StringName in [&"s1", &"s2", &"s3"]:
		var result := StageArtTheme.resolve_for(stages[id], missing)
		assert_true(bool(result["required"]))
		assert_null(result["theme"])
		assert_string_contains(String(result["error"]), "required stage art theme failed to load")
		var root := Node2D.new()
		assert_false(IsoGridBuilder.build_stage(root, stages[id], missing, false))
		assert_eq(root.get_child_count(), 0)
		root.free()
	var merged := Art.merge_manifest_entries({&"same": {}}, {&"same": {}})
	assert_false(bool(merged[&"ok"]))
	assert_eq(merged[&"entries"], {})
	assert_eq(merged[&"duplicate_id"], &"same")


func _prefix_count(root: Node, prefix: String) -> int:
	var count := 0
	for child: Node in root.get_children():
		if child.name.begins_with(prefix):
			count += 1
	return count


func _check_texture(root: Node, node_name: String, id: StringName) -> void:
	var node := root.get_node_or_null(node_name) as TextureRect
	assert_not_null(node, node_name)
	if node != null:
		assert_eq(node.texture, Art.texture(id), "%s exact texture" % node_name)
		assert_eq(node.mouse_filter, Control.MOUSE_FILTER_IGNORE)
