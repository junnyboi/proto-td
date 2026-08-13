extends GutTest

var s2: StageDef
var s3: StageDef
var s2_theme: StageArtTheme
var s3_theme: StageArtTheme

func before_all() -> void:
	s2 = load("res://data/stages/s2.tres") as StageDef
	s3 = load("res://data/stages/s3.tres") as StageDef
	s2_theme = load("res://data/presentation/s2_world_theme.tres") as StageArtTheme
	s3_theme = load("res://data/presentation/s3_world_theme.tres") as StageArtTheme

func test_battle_view_preflights_once_before_catalogs_and_model_creation() -> void:
	var file := FileAccess.open("res://scripts/view/battle_view.gd", FileAccess.READ)
	assert_not_null(file)
	if file == null:
		return
	var source := file.get_as_text()
	var preload_pos := source.find('const StageArtThemeType := preload("res://data/presentation/stage_art_theme.gd")')
	var enemy_animator_pos := source.find('const EnemyAnimator := preload("res://scripts/view/enemy_animator.gd")')
	var ready_pos := source.find("func _ready() -> void:")
	var resolve_pos := source.find("StageArtThemeType.resolve_for(stage)", ready_pos)
	var catalog_pos := source.find('_load_catalog("res://data/operators"', ready_pos)
	var create_pos := source.find("BattleModel.create(", ready_pos)
	var build_pos := source.find("build_stage_with_theme(_grid_root, stage, _stage_theme)", ready_pos)
	assert_gte(preload_pos, 0)
	assert_gte(enemy_animator_pos, 0)
	assert_gt(resolve_pos, ready_pos)
	assert_gt(catalog_pos, resolve_pos)
	assert_gt(create_pos, resolve_pos)
	assert_gt(build_pos, create_pos)
	assert_eq(source.count("StageArtThemeType.resolve_for(stage)"), 1)
	assert_string_contains(source, 'push_error("battle_view: stage art preflight failed: %s" % theme_error)')


func test_real_act2_themes_render_exact_runtime_inventories() -> void:
	_check_stage(s2, s2_theme, 59)
	_check_stage(s3, s3_theme, 68)

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
			assert_not_null(root.get_node_or_null("Tile_%d_%d" % [x, y]))
	root.free()

func _check_overlay(root: Node2D, cell: Vector2i, id: StringName) -> void:
	var overlay := root.get_node_or_null("Cadence_%d_%d" % [cell.x, cell.y]) as TextureRect
	assert_not_null(overlay)
	if overlay != null:
		assert_eq(overlay.texture, Art.texture(id))
		assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_eq(overlay.z_index, IsoProjection.tile_z(cell) + 1)

func _check_endpoints(root: Node2D, stage: StageDef, theme: StageArtTheme) -> void:
	for spec: Array in [["SpawnLandmark", theme.spawn_cell, theme.spawn_landmark_id, theme.spawn_pivot, theme.spawn_offset], ["CoreLandmark", theme.core_cell, theme.core_landmark_id, theme.core_pivot, theme.core_offset]]:
		var node := root.get_node_or_null(spec[0]) as TextureRect
		assert_not_null(node)
		if node != null:
			assert_eq(node.texture, Art.texture(spec[2]))
			assert_eq(node.mouse_filter, Control.MOUSE_FILTER_IGNORE)
			var center := IsoProjection.face_center(spec[1], stage.tile_at(spec[1]) == StageDef.Tile.ELEVATED)
			assert_eq(node.position, center - Vector2(spec[3]) * IsoGridBuilder.SPRITE_SCALE + Vector2(spec[4]) * IsoGridBuilder.SPRITE_SCALE)

func _check_texture(root: Node2D, node_name: String, id: StringName) -> void:
	var node := root.get_node_or_null(node_name) as TextureRect
	assert_not_null(node)
	if node != null:
		assert_eq(node.texture, Art.texture(id))
		assert_eq(node.mouse_filter, Control.MOUSE_FILTER_IGNORE)
