extends GutTest

const MANIFEST_PATH := "res://data/presentation/s1_slice_fixture_manifest.tres"
const VANGUARD_PROVENANCE := "res://assets/provenance/aui20_fixture_vanguard_1.provenance.json"
const GRUNT_PROVENANCE := "res://assets/provenance/aui20_fixture_grunt.provenance.json"


func _manifest() -> S1SliceFixtureManifest:
	return load(MANIFEST_PATH) as S1SliceFixtureManifest


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "%s opens" % path)
	if file == null:
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	return value if value is Dictionary else {}


func test_approved_atlases_are_exact_and_contract_geometry_is_loadable() -> void:
	var manifest := _manifest()
	assert_not_null(manifest)
	if manifest == null:
		return
	assert_eq(manifest.validate_contract(), PackedStringArray())
	assert_eq(
		manifest.fixture_contract_sha256,
		"bd0f253b561a530905eb862dd1640ca53f940c9700fd4087a8592f018174f97f",
	)
	assert_true(manifest.files_match_hashes())
	assert_eq(
		S1SliceFixtureManifest.hash_file(manifest.entry_path(&"operator")),
		"ab72a790deb56d6899fb0d40ec32e725ff8688f80e1542102f8c081c2209e85c",
	)
	assert_eq(
		S1SliceFixtureManifest.hash_file(manifest.entry_path(&"enemy")),
		"be7095a1a58a33bd70ef5ad8c913255a4bcc57a1a3ce5d2f5411d8f0a6e747ba",
	)
	for kind: StringName in S1SliceFixtureManifest.KINDS:
		var atlas := manifest.atlas_texture(kind)
		assert_not_null(atlas, "%s atlas imports" % kind)
		if atlas != null:
			assert_eq(Vector2i(atlas.get_size()), S1SliceFixtureManifest.ATLAS_SIZE)
		assert_true(manifest.foot_rows_match(kind), "%s bottom-center foot row" % kind)
		assert_false(manifest.atlas_has_reserved_color(kind), "%s reserved colors absent" % kind)
		for state: StringName in S1SliceFixtureManifest.STATES:
			for frame: int in S1SliceFixtureManifest.FRAME_COUNT:
				var texture := manifest.frame_texture(kind, state, frame)
				assert_not_null(texture, "%s %s frame %d" % [kind, state, frame])
				if texture != null:
					assert_eq(Vector2i(texture.get_size()), S1SliceFixtureManifest.CELL_SIZE)
	assert_eq(S1SliceFixtureManifest.RUNTIME_CANVAS_PX, 144.0)
	assert_eq(S1SliceFixtureManifest.DISPLAY_PX, 72.0)
	assert_eq(S1SliceFixtureManifest.REST_FPS, 5.5)
	assert_eq(S1SliceFixtureManifest.ATTACK_FPS, 8.0)


func test_truthful_provenance_sidecars_match_exact_final_files() -> void:
	var manifest := _manifest()
	for specification: Array in [
		[&"operator", VANGUARD_PROVENANCE],
		[&"enemy", GRUNT_PROVENANCE],
	]:
		var kind: StringName = specification[0]
		var provenance := _json(specification[1])
		assert_eq(provenance.get("schema_version"), 1)
		var files: Array = provenance.get("final_files", [])
		assert_eq(files.size(), 1)
		if files.size() != 1:
			continue
		var final_file: Dictionary = files[0]
		assert_eq(final_file.get("path"), manifest.entry_path(kind))
		assert_eq(final_file.get("sha256"), manifest.entry_sha256(kind))
		var file := FileAccess.open(manifest.entry_path(kind), FileAccess.READ)
		assert_not_null(file)
		if file != null:
			assert_eq(int(final_file.get("bytes", -1)), file.get_length())
		var acceptance: Dictionary = provenance.get("acceptance", {})
		assert_eq(acceptance.get("human_accepter"), "Poseidon")
		assert_eq(acceptance.get("fixture_contract_sha256"), manifest.fixture_contract_sha256)


func test_s1_only_exact_selectors_and_every_incumbent_fallback_fail_closed() -> void:
	var manifest := _manifest()
	var s1 := load("res://data/stages/s1.tres") as StageDef
	var non_s1 := load("res://data/stages/s2.tres") as StageDef
	assert_true(manifest.selects_operator(s1, &"vanguard_1"))
	assert_false(manifest.selects_operator(s1, &"guard_1"))
	assert_false(manifest.selects_operator(non_s1, &"vanguard_1"))

	var grunt := EnemyState.new()
	grunt.def_id = &"grunt"
	assert_true(manifest.selects_enemy(s1, grunt))
	grunt.faction = EnemyState.Faction.CHARMED
	assert_false(manifest.selects_enemy(s1, grunt), "charmed grunt keeps EnemyAnimator")
	grunt.faction = EnemyState.Faction.ENEMY
	grunt.aerial = true
	assert_false(manifest.selects_enemy(s1, grunt), "nonordinary grunt keeps EnemyAnimator")
	grunt.aerial = false
	grunt.def_id = &"runner"
	assert_false(manifest.selects_enemy(s1, grunt), "non-grunt basic keeps EnemyAnimator")
	grunt.def_id = &"mini_boss"
	assert_false(manifest.selects_enemy(s1, grunt), "nonbasic keeps incumbent art")
	grunt.def_id = &"grunt"
	assert_false(manifest.selects_enemy(non_s1, grunt), "non-S1 keeps EnemyAnimator")

	var corrupt := manifest.duplicate(true) as S1SliceFixtureManifest
	var operator_entry: Dictionary = corrupt.entries[&"operator"].duplicate(true)
	operator_entry[&"path"] = "res://assets/sprites/missing_aui20_fixture.png"
	corrupt.entries[&"operator"] = operator_entry
	assert_true(corrupt.validate_contract().size() > 0)
	assert_false(corrupt.selects_operator(s1, &"vanguard_1"))
	assert_null(corrupt.frame_texture(&"operator", &"rest_movement", 0))


func test_frame_cadence_uses_two_rows_without_touching_incumbent_art_ids() -> void:
	var manifest := _manifest()
	assert_eq(manifest.frame_index(&"rest_movement", 0.0), 0)
	assert_eq(manifest.frame_index(&"rest_movement", 1.0 / 5.5), 1)
	assert_eq(manifest.frame_index(&"attack_skill", 0.0), 0)
	assert_eq(manifest.frame_index(&"attack_skill", 0.125), 1)
	assert_not_null(Art.texture(&"vanguard_1", 0), "incumbent operator art remains loadable")
	assert_not_null(
		Art.texture(&"grunt_anim_walk_se", 0), "incumbent grunt animator art remains loadable"
	)
