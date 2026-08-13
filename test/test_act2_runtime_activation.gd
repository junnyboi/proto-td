extends GutTest

const BATTLE_VIEW_SCRIPT := preload("res://scripts/view/battle_view.gd")

var s2: StageDef
var s3: StageDef
var s2_theme: StageArtTheme
var s3_theme: StageArtTheme

var _saved_pending_stage: StageDef = null
var _saved_current_battle: BattleModel = null
var _saved_content: Node = null
var _test_view: Node = null


func before_all() -> void:
	s2 = load("res://data/stages/s2.tres") as StageDef
	s3 = load("res://data/stages/s3.tres") as StageDef
	s2_theme = load("res://data/presentation/s2_world_theme.tres") as StageArtTheme
	s3_theme = load("res://data/presentation/s3_world_theme.tres") as StageArtTheme


func before_each() -> void:
	_saved_pending_stage = Game.pending_stage
	_saved_current_battle = Game.current_battle
	_saved_content = Game.content
	Game.pending_stage = null
	Game.current_battle = null
	Game.content = null
	_test_view = null


func after_each() -> void:
	if _test_view != null and is_instance_valid(_test_view):
		_test_view.free()
	Game.pending_stage = _saved_pending_stage
	Game.current_battle = _saved_current_battle
	Game.content = _saved_content


func test_missing_required_theme_aborts_before_model_or_projection_and_is_rejected() -> void:
	Game.pending_stage = s2
	var factory_calls := {"count": 0}
	var view: Node = BATTLE_VIEW_SCRIPT.new()
	_test_view = view
	view.set("theme_resolver", func(_stage: Resource) -> Dictionary:
		return {"theme": null, "required": true, "error": "forced missing theme"}
	)
	view.set("model_factory", func(
		_stage: Variant,
		_squad: Variant,
		_seed: Variant,
		_config: Variant,
		_enemy_defs: Variant,
		_op_defs: Variant,
		_trap_defs: Variant,
		_spell_defs: Variant
	) -> Variant:
		factory_calls["count"] += 1
		return null
	)
	add_child(view)
	assert_push_error("battle_view: stage art preflight failed: forced missing theme")

	assert_eq(factory_calls["count"], 0)
	assert_null(view.get("model"))
	assert_false(bool(view.get("startup_succeeded")))
	assert_null(Game.current_battle)
	for child_name: String in [
		"GridRoot", "JuiceLayer", "BattleHud", "DeployBar", "SpellBar", "BattleControls"
	]:
		assert_null(view.get_node_or_null(child_name), "startup failure omits %s" % child_name)

	assert_false(bool(Game.call("_accept_content_candidate", view, true)))
	assert_null(Game.content)
	assert_null(Game.current_battle)
	assert_null(Game.pending_stage)


func test_valid_s2_candidate_publishes_only_after_complete_projection() -> void:
	Game.pending_stage = s2
	var view: Node = BATTLE_VIEW_SCRIPT.new()
	_test_view = view
	add_child(view)

	assert_true(bool(view.get("startup_succeeded")))
	assert_not_null(view.get("model"))
	assert_eq(Game.current_battle, view.get("model"))
	var grid := view.get_node_or_null("GridRoot")
	assert_not_null(grid)
	if grid != null:
		assert_eq(grid.get_child_count(), 59)
	for child_name: String in ["JuiceLayer", "BattleHud", "DeployBar", "SpellBar", "BattleControls"]:
		assert_not_null(view.get_node_or_null(child_name), "startup creates %s" % child_name)
	assert_null(Game.content)
	assert_true(bool(Game.call("_accept_content_candidate", view, true)))
	assert_eq(Game.content, view)
	assert_eq(Game.current_battle, view.get("model"))


func test_battle_view_preflight_remains_before_catalogs_and_factory() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/view/battle_view.gd")
	assert_false(source.is_empty())
	var ready_pos := source.find("func _ready() -> void:")
	var resolve_pos := source.find("theme_resolver.call(stage)", ready_pos)
	var catalog_pos := source.find('_load_catalog("res://data/operators"', ready_pos)
	var create_pos := source.find("model_factory.call(", ready_pos)
	assert_gte(
		source.find(
			'const StageArtThemeType := preload("res://data/presentation/stage_art_theme.gd")'
		),
		0,
	)
	assert_gte(
		source.find(
			'const EnemyAnimator := preload("res://scripts/view/enemy_animator.gd")'
		),
		0,
	)
	assert_gt(resolve_pos, ready_pos)
	assert_gt(catalog_pos, resolve_pos)
	assert_gt(create_pos, catalog_pos)
	assert_false(source.contains("Game.content = self"))


func test_real_act2_themes_render_exact_runtime_inventories() -> void:
	_check_stage(s2, s2_theme, 59)
	_check_stage(s3, s3_theme, 68)


func test_act2_surface_modulation_is_pinned_and_fail_closed() -> void:
	for spec: Array in [[s2, s2_theme], [s3, s3_theme]]:
		var stage: StageDef = spec[0]
		var theme: StageArtTheme = spec[1]
		assert_eq(theme.surface_modulate, StageArtTheme.ACT2_SURFACE_MODULATE)
		var root := _build(stage, theme)
		for child: Node in root.get_children():
			if child.name.begins_with("Tile_") and child is CanvasItem:
				assert_eq(
					(child as CanvasItem).self_modulate,
					StageArtTheme.ACT2_SURFACE_MODULATE,
					"%s has exact surface modulation" % child.name,
				)
		root.free()

	var invalid := s2_theme.duplicate(true) as StageArtTheme
	invalid.surface_modulate = Color.WHITE
	assert_true(
		invalid.validation_errors(s2).has(
			"Act II surface modulation does not match the measured H1 calibration"
		)
	)


func test_s2_exact_variants_cadence_and_endpoints() -> void:
	var root := _build(s2, s2_theme)
	_check_texture(root, "Tile_3_1", &"world.s2.elevated_manometer")
	_check_texture(root, "Tile_3_3", &"world.s2.elevated_relief")
	for cell: Vector2i in StageArtTheme.S2_CADENCE_CELLS:
		_check_overlay(root, cell, StageArtTheme.ACT2_CADENCE_E)
	_check_endpoints(root, s2, s2_theme)
	root.free()


func test_s3_exact_blockers_elevation_cadence_and_endpoints() -> void:
	var root := _build(s3, s3_theme)
	_check_texture(root, "Tile_2_3", &"world.s3.elevated_assay")
	_check_texture(root, "Tile_5_2", &"world.s3.blocked_regulator")
	_check_texture(root, "Tile_5_3", &"world.s3.blocked_pressure_jaw")
	for cell: Vector2i in StageArtTheme.S3_CADENCE_CELLS:
		_check_overlay(root, cell, s3_theme.cadence_id_at(cell))
	_check_endpoints(root, s3, s3_theme)
	root.free()


func test_missing_and_invalid_required_explicit_themes_fail_with_zero_children() -> void:
	for stage: StageDef in [s2, s3]:
		var missing_root := Node2D.new()
		assert_false(IsoGridBuilder.build_stage_with_theme(missing_root, stage, null, false))
		assert_eq(missing_root.get_child_count(), 0)
		missing_root.free()
	var invalid := s2_theme.duplicate(true) as StageArtTheme
	invalid.stage_id = &"s3"
	var invalid_root := Node2D.new()
	assert_false(IsoGridBuilder.build_stage_with_theme(invalid_root, s2, invalid, false))
	assert_eq(invalid_root.get_child_count(), 0)
	invalid_root.free()


func _build(stage: StageDef, theme: StageArtTheme) -> Node2D:
	var root := Node2D.new()
	assert_true(IsoGridBuilder.build_stage_with_theme(root, stage, theme, false))
	return root


func _check_stage(stage: StageDef, theme: StageArtTheme, expected_count: int) -> void:
	var root := _build(stage, theme)
	assert_eq(root.get_child_count(), expected_count)
	var terrain_count := 0
	var shade_count := 0
	var panorama_count := 0
	var cadence_count := 0
	var backdrop_ring_count := 0
	for child: Node in root.get_children():
		if child.name.begins_with("Tile_"):
			terrain_count += 1
		if child is Polygon2D and not child.name.begins_with("Tile_"):
			shade_count += 1
		if child.name == "BackdropPanorama":
			panorama_count += 1
		if child.name.begins_with("Cadence_"):
			cadence_count += 1
		if child.name.begins_with("Backdrop_"):
			backdrop_ring_count += 1
	assert_eq(terrain_count, stage.grid_size().x * stage.grid_size().y)
	assert_eq(shade_count, 2 if stage.id == &"s2" else 1)
	assert_eq(panorama_count, 1)
	assert_eq(cadence_count, 4)
	assert_eq(backdrop_ring_count, 0)
	var panorama := root.get_node("BackdropPanorama") as TextureRect
	assert_eq(panorama.texture, Art.texture(theme.backdrop_panorama_id))
	assert_eq(panorama.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	for y: int in stage.grid_size().y:
		for x: int in stage.grid_size().x:
			var tile := root.get_node_or_null("Tile_%d_%d" % [x, y]) as CanvasItem
			assert_not_null(tile)
			if tile != null:
				assert_eq(tile.self_modulate, theme.surface_modulate)
	root.free()


func _check_overlay(root: Node2D, cell: Vector2i, id: StringName) -> void:
	var overlay := root.get_node_or_null("Cadence_%d_%d" % [cell.x, cell.y]) as TextureRect
	assert_not_null(overlay)
	if overlay != null:
		assert_eq(overlay.texture, Art.texture(id))
		assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_eq(overlay.z_index, IsoProjection.tile_z(cell) + 1)


func _check_endpoints(root: Node2D, stage: StageDef, theme: StageArtTheme) -> void:
	var specs: Array = [
		[
			"SpawnLandmark", theme.spawn_cell, theme.spawn_landmark_id,
			theme.spawn_pivot, theme.spawn_offset,
		],
		[
			"CoreLandmark", theme.core_cell, theme.core_landmark_id,
			theme.core_pivot, theme.core_offset,
		],
	]
	for spec: Array in specs:
		var node := root.get_node_or_null(spec[0]) as TextureRect
		assert_not_null(node)
		if node != null:
			assert_eq(node.texture, Art.texture(spec[2]))
			assert_eq(node.mouse_filter, Control.MOUSE_FILTER_IGNORE)
			var lifted := stage.tile_at(spec[1]) == StageDef.Tile.ELEVATED
			var center := IsoProjection.face_center(spec[1], lifted)
			var expected := (
				center
				- Vector2(spec[3]) * IsoGridBuilder.SPRITE_SCALE
				+ Vector2(spec[4]) * IsoGridBuilder.SPRITE_SCALE
			)
			assert_eq(node.position, expected)


func _check_texture(root: Node2D, node_name: String, id: StringName) -> void:
	var node := root.get_node_or_null(node_name) as TextureRect
	assert_not_null(node)
	if node != null:
		assert_eq(node.texture, Art.texture(id))
		assert_eq(node.mouse_filter, Control.MOUSE_FILTER_IGNORE)
