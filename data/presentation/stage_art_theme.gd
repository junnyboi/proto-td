class_name StageArtTheme
extends Resource

## Presentation-only stage art contract. This resource is never read by the
## model, save, hash, or replay lanes; the disposable view consumes it to map
## stage roles to manifest IDs and typed decorative anchors.

@export var stage_id: StringName = &""
@export var theme_id: StringName = &""
@export var approval_token: StringName = &""
@export var approval_manifest_sha256: String = ""
@export var human_final_art: bool = false

@export var ground_id: StringName = &""
@export var route_id: StringName = &""
@export var elevated_id: StringName = &""
@export var backdrop_id: StringName = &""

@export var route_notch_id: StringName = &""
@export var route_notch_cells: Array[Vector2i] = []

@export var spawn_landmark_id: StringName = &""
@export var spawn_cell: Vector2i = Vector2i(-1, -1)
@export var spawn_pivot: Vector2i = Vector2i.ZERO
@export var spawn_offset: Vector2i = Vector2i.ZERO

@export var core_landmark_id: StringName = &""
@export var core_cell: Vector2i = Vector2i(-1, -1)
@export var core_pivot: Vector2i = Vector2i.ZERO
@export var core_offset: Vector2i = Vector2i.ZERO

@export var rain_measure_id: StringName = &""
@export var rain_measure_placed: bool = false


static func load_for(stage: StageDef) -> StageArtTheme:
	if stage == null:
		return null
	var path := "res://data/presentation/%s_world_theme.tres" % stage.id
	if not ResourceLoader.exists(path):
		return null
	var theme := load(path) as StageArtTheme
	if theme == null:
		push_error("stage_art_theme: resource failed to load: %s" % path)
		return null
	var errors := theme.validation_errors(stage)
	for id: StringName in theme.required_manifest_ids():
		if Art.texture(id) == null or Art.size(id) == Vector2i.ZERO:
			errors.append("manifest asset missing or unsized: %s" % id)
	if not errors.is_empty():
		push_error("stage_art_theme: invalid resource: %s" % "; ".join(errors))
		return null
	return theme


func applies_to(stage: StageDef) -> bool:
	return stage != null and stage.id == stage_id


func tile_id(tile: StageDef.Tile, is_route: bool) -> StringName:
	if tile == StageDef.Tile.ELEVATED:
		return elevated_id
	if is_route:
		return route_id
	if tile == StageDef.Tile.GROUND:
		return ground_id
	return &""


func required_manifest_ids() -> Array[StringName]:
	return [
		ground_id,
		route_id,
		elevated_id,
		backdrop_id,
		route_notch_id,
		spawn_landmark_id,
		core_landmark_id,
		rain_measure_id,
	]


func validation_errors(stage: StageDef) -> PackedStringArray:
	var errors := PackedStringArray()
	if not applies_to(stage):
		errors.append("theme stage_id does not match stage")
	if theme_id == &"":
		errors.append("theme_id is empty")
	if approval_token != &"AUI-DESIGN-D":
		errors.append("approval token is not AUI-DESIGN-D")
	if approval_manifest_sha256.length() != 64:
		errors.append("approval manifest SHA-256 is not 64 hex characters")
	for id: StringName in required_manifest_ids():
		if id == &"":
			errors.append("required manifest id is empty")
	if route_notch_cells.size() != 3:
		errors.append("S1 requires exactly three route-notch cells")
	if rain_measure_placed:
		errors.append("rain measure must remain unplaced until an anchor is validated")
	if stage != null:
		var path_cells: Dictionary = {}
		for cell: Vector2i in stage.path_cells(0):
			path_cells[cell] = true
		for cell: Vector2i in route_notch_cells:
			if not path_cells.has(cell):
				errors.append("route notch is not on path: %s" % cell)
		if stage.tile_at(spawn_cell) != StageDef.Tile.SPAWN:
			errors.append("spawn landmark cell is not SPAWN")
		if stage.tile_at(core_cell) != StageDef.Tile.BASE:
			errors.append("core landmark cell is not BASE")
	return errors
