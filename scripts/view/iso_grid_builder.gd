class_name IsoGridBuilder
extends RefCounted

## Builds proto-td's static terrain through the custom, textured isometric
## renderer transplanted from proto-isometric. BattleView continues to own
## projection, input, dynamic entities, and relayout.

const StageArtThemeType := preload("res://data/presentation/stage_art_theme.gd")
const ProtoIsometricTerrainScript := preload("res://scripts/view/proto_isometric_terrain.gd")


static func build_stage(
	grid_root: Node2D,
	stage: StageDef,
	theme_resolver: Callable = Callable(),
	report_error: bool = true,
) -> bool:
	var result := StageArtThemeType.resolve_for(stage, theme_resolver)
	var error := String(result["error"])
	if not error.is_empty():
		if report_error:
			push_error("iso_grid_builder: %s" % error)
		return false
	return build_stage_with_theme(
		grid_root,
		stage,
		result["theme"] as StageArtThemeType,
		report_error,
	)


## Presentation-only seam for callers that already completed theme preflight.
static func build_stage_with_theme(
	grid_root: Node2D,
	stage: StageDef,
	theme: StageArtThemeType,
	report_error: bool = true,
) -> bool:
	var errors := PackedStringArray()
	if grid_root == null:
		errors.append("grid root is null")
	if stage == null:
		errors.append("stage is null")
	elif StageArtThemeType.expects_theme(stage) and theme == null:
		errors.append("required stage art theme was not provided for %s" % stage.id)
	if stage != null and theme != null:
		errors.append_array(theme.validation_errors(stage))
	for path: String in ProtoIsometricTerrainScript.required_texture_paths():
		if not ResourceLoader.exists(path):
			errors.append("proto-isometric terrain asset missing: %s" % path)
	if not errors.is_empty():
		if report_error:
			push_error("iso_grid_builder: invalid isometric terrain setup: %s" % "; ".join(errors))
		return false

	var terrain := ProtoIsometricTerrainScript.new() as Node2D
	terrain.name = "ProtoIsometricTerrain"
	if not bool(terrain.call("configure", stage)):
		if report_error:
			push_error("iso_grid_builder: proto-isometric terrain configuration failed")
		terrain.queue_free()
		return false
	grid_root.add_child(terrain)
	if theme != null:
		_add_endpoint_landmarks(grid_root, stage, theme)
	return true


static func _add_endpoint_landmarks(
	grid_root: Node2D,
	stage: StageDef,
	theme: StageArtThemeType,
) -> void:
	_add_landmark(
		grid_root,
		stage,
		theme.spawn_cell,
		theme.spawn_landmark_id,
		theme.spawn_pivot,
		theme.spawn_offset,
		"SpawnLandmark",
	)
	_add_landmark(
		grid_root,
		stage,
		theme.core_cell,
		theme.core_landmark_id,
		theme.core_pivot,
		theme.core_offset,
		"CoreLandmark",
	)


static func _add_landmark(
	grid_root: Node2D,
	stage: StageDef,
	cell: Vector2i,
	art_id: StringName,
	pivot: Vector2i,
	offset: Vector2i,
	node_name: String,
) -> void:
	var texture := Art.texture(art_id)
	if texture == null:
		return
	var art_size := Art.size(art_id)
	if art_size == Vector2i.ZERO:
		art_size = Vector2i(texture.get_width(), texture.get_height())
	var center := IsoProjection.face_center(
		cell,
		stage.tile_at(cell) == StageDef.Tile.ELEVATED,
	)
	var sprite := TextureRect.new()
	sprite.name = node_name
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = texture
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.size = Vector2(art_size)
	sprite.position = center - Vector2(pivot) + Vector2(offset)
	sprite.z_index = IsoProjection.tile_z(cell) + 1
	grid_root.add_child(sprite)
