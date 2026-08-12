extends GutTest

const EXPECTED_ASSET_HASHES := {
	&"world.s1.backdrop": "592b2295edab8ced4958d5e3dff5a09bfd0efef7e2a7bba550591dfaa5f34bb4",
	&"world.s1.core_landmark": "805e7ee2f01ba4e8770f27bbfdccf8ffbbcaff90791b849bbf915b93ecdd111b",
	&"world.s1.elevated": "e25f601d850f8fb5ae5b32b840415dbad31171731579da430a701b00f36ed43d",
	&"world.s1.ground": "1dad2adea323d311f0afb0526a2d9f7195f807055a13842dae07638c1425d7af",
	&"world.s1.rain_measure": "fc8d346c0f129ea912fa216aa9ee53b4c78f32be68ff2cb9a1c771f8a9051dcf",
	&"world.s1.route_notch": "b31be5a9a001c8c9662ce017ed7853f9872313204d4567a6f050dfa1bc12f8ba",
	&"world.s1.route": "c852a1ed7de5b81d4890afa7c2b077f354b57c2d0956ff9f29d1c3890c276ecd",
	&"world.s1.spawn_landmark": "e4172fc2a33d68e063a742b44ae221159762dee74b6a20874395690e73f3a22d",
}
const EXPECTED_ASSET_SIZES := {
	&"world.s1.backdrop": Vector2i(32, 16),
	&"world.s1.core_landmark": Vector2i(32, 32),
	&"world.s1.elevated": Vector2i(32, 24),
	&"world.s1.ground": Vector2i(32, 16),
	&"world.s1.rain_measure": Vector2i(16, 16),
	&"world.s1.route_notch": Vector2i(32, 16),
	&"world.s1.route": Vector2i(32, 16),
	&"world.s1.spawn_landmark": Vector2i(32, 32),
}

var theme: StageArtTheme
var s1: StageDef
var s2: StageDef
var manifest: AssetManifest


func before_all() -> void:
	theme = load("res://data/presentation/s1_world_theme.tres") as StageArtTheme
	s1 = load("res://data/stages/s1.tres") as StageDef
	s2 = load("res://data/stages/s2.tres") as StageDef
	manifest = load("res://assets/manifest.tres") as AssetManifest


func test_theme_is_valid_only_for_s1() -> void:
	assert_not_null(theme)
	assert_true(theme.applies_to(s1))
	assert_false(theme.applies_to(s2))
	assert_eq(theme.validation_errors(s1), PackedStringArray())
	assert_eq(theme.approval_token, &"AUI-DESIGN-D")
	assert_eq(
		theme.approval_manifest_sha256,
		"91cfda9a1c5b199b5c69d42c82d58fbe4a186b270b828180b16ad7c1cb811e51",
	)
	assert_false(theme.human_final_art)


func test_theme_preserves_authoritative_s1_roles() -> void:
	assert_eq(theme.tile_id(StageDef.Tile.GROUND, false), &"world.s1.ground")
	assert_eq(theme.tile_id(StageDef.Tile.GROUND, true), &"world.s1.route")
	assert_eq(theme.tile_id(StageDef.Tile.SPAWN, true), &"world.s1.route")
	assert_eq(theme.tile_id(StageDef.Tile.BASE, true), &"world.s1.route")
	assert_eq(theme.tile_id(StageDef.Tile.ELEVATED, false), &"world.s1.elevated")
	assert_eq(theme.route_notch_cells, [Vector2i(2, 2), Vector2i(4, 2), Vector2i(6, 2)])
	assert_eq(theme.spawn_cell, Vector2i(0, 2))
	assert_eq(theme.core_cell, Vector2i(7, 2))
	assert_false(theme.rain_measure_placed)


func test_all_s1_manifest_entries_are_runtime_backed_but_human_unaccepted() -> void:
	assert_not_null(manifest)
	assert_eq(theme.required_manifest_ids().size(), 8)
	for id: StringName in theme.required_manifest_ids():
		assert_true(manifest.entries.has(id), "missing %s" % id)
		var entry: Dictionary = manifest.entries[id]
		assert_eq(int(entry["frames"]), 1, "%s frame count" % id)
		assert_true(bool(entry["placeholder"]), "%s must remain placeholder until owner review" % id)
		assert_true(String(entry["pattern"]).begins_with("res://assets/world/s1/"), "%s path" % id)
		assert_eq(entry["size"], EXPECTED_ASSET_SIZES[id], "%s manifest size" % id)
		assert_not_null(Art.texture(id), "%s texture" % id)
		assert_eq(Art.size(id), EXPECTED_ASSET_SIZES[id], "%s runtime size" % id)


func test_runtime_asset_bytes_match_the_verified_staged_candidates() -> void:
	for id: StringName in EXPECTED_ASSET_HASHES:
		var entry: Dictionary = manifest.entries[id]
		var path := String(entry["pattern"])
		assert_eq(FileAccess.get_sha256(path), EXPECTED_ASSET_HASHES[id], "%s bytes" % id)


func test_runtime_provenance_covers_every_asset_without_inferring_human_acceptance() -> void:
	for id: StringName in EXPECTED_ASSET_HASHES:
		var sidecar_name := String(id).replace(".", "_") + ".provenance.json"
		var sidecar_path := "res://assets/provenance/world/s1/" + sidecar_name
		assert_true(FileAccess.file_exists(sidecar_path), "%s exists" % sidecar_name)
		var sidecar: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sidecar_path))
		assert_eq(sidecar["logical_id"], String(id), "%s logical id" % id)
		assert_eq(sidecar["final_file"], String(manifest.entries[id]["pattern"]).trim_prefix("res://"))
		assert_eq(sidecar["final_file_sha256"], EXPECTED_ASSET_HASHES[id], "%s final hash" % id)
		assert_eq(sidecar["generator"]["model"], "gpt-image-2", "%s model" % id)
		assert_eq(sidecar["approval_packet"]["token"], "AUI-DESIGN-D", "%s approval" % id)
		assert_false(bool(sidecar["human_acceptance"]["final_art"]), "%s human final" % id)


func test_missing_required_s1_theme_fails_closed_while_s2_stays_generic() -> void:
	var missing_resolver := func(_path: String) -> Resource: return null
	var s1_result := StageArtTheme.resolve_for(s1, missing_resolver)
	assert_true(bool(s1_result["required"]))
	assert_null(s1_result["theme"])
	assert_string_contains(String(s1_result["error"]), "required stage art theme")
	var s1_root := Node2D.new()
	assert_false(IsoGridBuilder.build_stage(s1_root, s1, missing_resolver, false))
	assert_eq(s1_root.get_child_count(), 0, "broken required S1 must not draw generic art")
	s1_root.free()

	var s2_result := StageArtTheme.resolve_for(s2, missing_resolver)
	assert_false(bool(s2_result["required"]))
	assert_null(s2_result["theme"])
	assert_eq(String(s2_result["error"]), "")
	var s2_root := Node2D.new()
	assert_true(IsoGridBuilder.build_stage(s2_root, s2, missing_resolver, false))
	assert_gt(s2_root.get_child_count(), 0, "explicitly unthemed S2 keeps generic art")
	var s2_tile := s2_root.get_node_or_null("Tile_0_0") as TextureRect
	assert_not_null(s2_tile)
	if s2_tile != null:
		assert_eq(s2_tile.texture, Art.texture(&"tile_ground"))
	s2_root.free()
