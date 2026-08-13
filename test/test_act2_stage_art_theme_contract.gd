extends GutTest

const SHARED_IDS: Array[StringName] = [
	&"world.pressure.ground_calm",
	&"world.pressure.ground_runoff",
	&"world.pressure.route_plate",
	&"world.pressure.cadence_e",
	&"world.pressure.cadence_s",
	&"world.pressure.cadence_e_s",
	&"world.pressure.cadence_s_e",
]


func _stage(id: StringName) -> StageDef:
	var stage := StageDef.new()
	stage.id = id
	if id == &"s2":
		stage.grid_rows = PackedStringArray([
			"GGGGGGGGGG", "GGGEGGGGGG", "SGGGGGGGGB", "GGGEGGGGGG", "GGGGGGGGGG",
		])
		stage.paths = [PackedVector2Array([
			Vector2(0, 2), Vector2(1, 2), Vector2(2, 2), Vector2(3, 2), Vector2(4, 2),
			Vector2(5, 2), Vector2(6, 2), Vector2(7, 2), Vector2(8, 2), Vector2(9, 2),
		])]
	else:
		stage.grid_rows = PackedStringArray([
			"GGGGGGGGGG", "GGGGGGGGGG", "SGGGGXGGGG", "GGEGGXGGGG", "GGGGGGGGGB",
			"GGGGGGGGGG",
		])
		stage.paths = [PackedVector2Array([
			Vector2(0, 2), Vector2(1, 2), Vector2(2, 2), Vector2(3, 2), Vector2(4, 2),
			Vector2(4, 3), Vector2(4, 4), Vector2(5, 4), Vector2(6, 4), Vector2(7, 4),
			Vector2(8, 4), Vector2(9, 4),
		])]
	return stage


func _base_theme(id: StringName) -> StageArtTheme:
	var theme := StageArtTheme.new()
	theme.stage_id = id
	theme.theme_id = &"world.act2.pressure_descent"
	theme.approval_token = StageArtTheme.ACT2_SEMANTIC_APPROVAL_TOKEN
	theme.human_final_art = false
	theme.ground_id = SHARED_IDS[0]
	theme.ground_variant_ids = [SHARED_IDS[1]]
	theme.route_id = SHARED_IDS[2]
	theme.cadence_variant_ids = [SHARED_IDS[3], SHARED_IDS[4], SHARED_IDS[5], SHARED_IDS[6]]
	theme.spawn_pivot = Vector2i(16, 30)
	theme.core_pivot = Vector2i(16, 30)
	return theme


func _s2_theme() -> StageArtTheme:
	var theme := _base_theme(&"s2")
	theme.elevated_cells = StageArtTheme.S2_ELEVATED_CELLS.duplicate()
	theme.elevated_variant_ids = [
		&"world.s2.elevated_manometer", &"world.s2.elevated_relief",
	]
	theme.cadence_cells = StageArtTheme.S2_CADENCE_CELLS.duplicate()
	theme.cadence_ids = [
		StageArtTheme.ACT2_CADENCE_E, StageArtTheme.ACT2_CADENCE_E,
		StageArtTheme.ACT2_CADENCE_E, StageArtTheme.ACT2_CADENCE_E,
	]
	theme.spawn_landmark_id = &"world.s2.spawn_louver"
	theme.spawn_cell = Vector2i(0, 2)
	theme.core_landmark_id = &"world.s2.core_receiver"
	theme.core_cell = Vector2i(9, 2)
	theme.backdrop_panorama_id = &"world.s2.backdrop_panorama"
	return theme


func _s3_theme() -> StageArtTheme:
	var theme := _base_theme(&"s3")
	theme.elevated_cells = StageArtTheme.S3_ELEVATED_CELLS.duplicate()
	theme.elevated_variant_ids = [&"world.s3.elevated_assay"]
	theme.blocked_cells = StageArtTheme.S3_BLOCKED_CELLS.duplicate()
	theme.blocked_variant_ids = [
		&"world.s3.blocked_regulator", &"world.s3.blocked_pressure_jaw",
	]
	theme.cadence_cells = StageArtTheme.S3_CADENCE_CELLS.duplicate()
	theme.cadence_ids = [
		StageArtTheme.ACT2_CADENCE_E, StageArtTheme.ACT2_CADENCE_E_TO_S,
		StageArtTheme.ACT2_CADENCE_S_TO_E, StageArtTheme.ACT2_CADENCE_E,
	]
	theme.spawn_landmark_id = &"world.s3.spawn_rain_sluice"
	theme.spawn_cell = Vector2i(0, 2)
	theme.core_landmark_id = &"world.s3.core_pressure_keeper"
	theme.core_cell = Vector2i(9, 4)
	theme.backdrop_panorama_id = &"world.s3.backdrop_panorama"
	return theme


func test_s1_public_contract_is_unchanged() -> void:
	var s1 := load("res://data/stages/s1.tres") as StageDef
	var theme := load("res://data/presentation/s1_world_theme.tres") as StageArtTheme
	assert_eq(StageArtTheme.REQUIRED_THEME_STAGE_IDS, [&"s1"])
	assert_eq(theme.validation_errors(s1), PackedStringArray())
	assert_eq(theme.required_manifest_ids(), [
		&"world.s1.ground", &"world.s1.route", &"world.s1.elevated", &"world.s1.backdrop",
		&"world.s1.backdrop_panorama", &"world.s1.route_notch", &"world.s1.spawn_landmark",
		&"world.s1.core_landmark", &"world.s1.rain_measure", &"world.s1.backdrop_ridge",
		&"world.s1.backdrop_peak", &"world.s1.backdrop_mist",
	])
	assert_eq(theme.tile_id(StageDef.Tile.GROUND, true), &"world.s1.route")


func test_act2_profiles_are_valid_without_hash_or_h1_final_art() -> void:
	var s2 := _s2_theme()
	var s3 := _s3_theme()
	s2.approval_manifest_sha256 = "not-an-approval-gate"
	s3.approval_manifest_sha256 = ""
	assert_false(s2.human_final_art)
	assert_false(s3.human_final_art)
	assert_eq(s2.validation_errors(_stage(&"s2")), PackedStringArray())
	assert_eq(s3.validation_errors(_stage(&"s3")), PackedStringArray())


func test_exact_unique_nonempty_required_id_sets() -> void:
	var s2_expected := SHARED_IDS.duplicate()
	s2_expected.append_array([
		&"world.s2.elevated_manometer", &"world.s2.elevated_relief",
		&"world.s2.spawn_louver", &"world.s2.core_receiver", &"world.s2.backdrop_panorama",
	])
	var s3_expected := SHARED_IDS.duplicate()
	s3_expected.append_array([
		&"world.s3.elevated_assay", &"world.s3.blocked_regulator",
		&"world.s3.blocked_pressure_jaw", &"world.s3.spawn_rain_sluice",
		&"world.s3.core_pressure_keeper", &"world.s3.backdrop_panorama",
	])
	assert_eq(_s2_theme().required_manifest_ids().size(), 12)
	assert_eq(_s3_theme().required_manifest_ids().size(), 13)
	for id: StringName in s2_expected:
		assert_has(_s2_theme().required_manifest_ids(), id)
	for id: StringName in s3_expected:
		assert_has(_s3_theme().required_manifest_ids(), id)


func test_cell_aware_tile_and_cadence_resolution() -> void:
	var s2 := _s2_theme()
	assert_eq(s2.tile_id_at(Vector2i(3, 1), StageDef.Tile.ELEVATED, false), &"world.s2.elevated_manometer")
	assert_eq(s2.tile_id_at(Vector2i(3, 3), StageDef.Tile.ELEVATED, false), &"world.s2.elevated_relief")
	assert_eq(s2.ground_id_at(Vector2i(0, 0)), &"world.pressure.ground_calm")
	assert_eq(s2.ground_id_at(Vector2i(1, 0)), &"world.pressure.ground_runoff")
	assert_eq(s2.cadence_id_at(Vector2i(4, 2)), StageArtTheme.ACT2_CADENCE_E)
	var s3 := _s3_theme()
	assert_eq(s3.tile_id_at(Vector2i(2, 3), StageDef.Tile.ELEVATED, false), &"world.s3.elevated_assay")
	assert_eq(s3.tile_id_at(Vector2i(5, 2), StageDef.Tile.BLOCKED, false), &"world.s3.blocked_regulator")
	assert_eq(s3.tile_id_at(Vector2i(5, 3), StageDef.Tile.BLOCKED, false), &"world.s3.blocked_pressure_jaw")
	assert_eq(s3.cadence_id_at(Vector2i(4, 2)), StageArtTheme.ACT2_CADENCE_E_TO_S)
	assert_eq(s3.cadence_id_at(Vector2i(4, 4)), StageArtTheme.ACT2_CADENCE_S_TO_E)
	assert_eq(s3.resolve_cell(Vector2i(7, 4), StageDef.Tile.GROUND, true), {
		"tile_id": &"world.pressure.route_plate", "cadence_id": StageArtTheme.ACT2_CADENCE_E,
	})


func test_s2_and_s3_remain_dormant_and_generic() -> void:
	var missing := func(_path: String) -> Resource: return null
	for id: StringName in [&"s2", &"s3"]:
		var stage := _stage(id)
		assert_false(StageArtTheme.expects_theme(stage))
		var result := StageArtTheme.resolve_for(stage, missing)
		assert_false(bool(result["required"]))
		assert_null(result["theme"])
		assert_eq(String(result["error"]), "")


func test_wrong_token_missing_and_duplicate_ids_fail() -> void:
	var stage := _stage(&"s2")
	var wrong_token := _s2_theme()
	wrong_token.approval_token = &"ACT-II-S2-S3-H0-wrong"
	assert_has(wrong_token.validation_errors(stage), "approval token is not the approved Act II semantic contract")
	var missing := _s2_theme()
	missing.ground_id = &""
	assert_has(missing.validation_errors(stage), "required manifest id is empty")
	var duplicate := _s2_theme()
	duplicate.ground_variant_ids = [&"world.pressure.ground_calm"]
	assert_has(duplicate.validation_errors(stage), "required manifest id is duplicated: world.pressure.ground_calm")


func test_mismatched_lengths_and_wrong_semantic_cells_fail() -> void:
	var s2 := _s2_theme()
	s2.elevated_variant_ids.pop_back()
	assert_has(s2.validation_errors(_stage(&"s2")), "elevated cells and IDs must have matching lengths")
	var s3 := _s3_theme()
	s3.blocked_cells = [Vector2i(5, 2)]
	assert_has(s3.validation_errors(_stage(&"s3")), "blocked cells and IDs must have matching lengths")
	assert_has(s3.validation_errors(_stage(&"s3")), "blocked cells do not match the approved topology")
	var wrong_stage := _stage(&"s3")
	wrong_stage.grid_rows[3] = "GGEGGGGGGG"
	assert_has(s3.validation_errors(wrong_stage), "approved blocked cell is not BLOCKED: (5, 3)")


func test_cadence_off_path_endpoint_mismatch_and_wrong_corner_ids_fail() -> void:
	var stage := _stage(&"s3")
	stage.paths[0] = PackedVector2Array([
		Vector2(0, 2), Vector2(1, 2), Vector2(2, 2), Vector2(3, 2), Vector2(4, 2),
		Vector2(4, 3), Vector2(5, 4), Vector2(6, 4), Vector2(7, 4), Vector2(8, 4), Vector2(9, 4),
	])
	assert_has(_s3_theme().validation_errors(stage), "cadence cell is not on path: (4, 4)")
	var endpoint := _s3_theme()
	endpoint.core_cell = Vector2i(9, 2)
	assert_has(endpoint.validation_errors(_stage(&"s3")), "core endpoint does not match the approved topology")
	var corner := _s3_theme()
	corner.cadence_ids[1] = StageArtTheme.ACT2_CADENCE_E
	assert_has(corner.validation_errors(_stage(&"s3")), "S3 requires dedicated E-to-S and S-to-E cadence IDs")
