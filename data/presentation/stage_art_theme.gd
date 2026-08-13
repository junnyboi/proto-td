class_name StageArtTheme
extends Resource

## Presentation-only shared Act I world-art contract for S1-S3. Gameplay,
## campaign, save, replay, and music lanes never read this resource.

const REQUIRED_THEME_STAGE_IDS: Array[StringName] = [&"s1", &"s2", &"s3"]
const APPROVAL_TOKEN: StringName = &"ACT-I-S1-S3-SYNTHESIS-V1"
const SHARED_THEME_ID: StringName = &"world.act1.alpine_shared"
const SHARED_ENDPOINT_PIVOT := Vector2i(32, 16)
const SHARED_IDS: Array[StringName] = [
	&"world.act1.ground",
	&"world.act1.route",
	&"world.act1.raised",
	&"world.act1.blocked",
	&"world.act1.spawn",
	&"world.act1.core",
	&"world.act1.panorama",
]
const TOPOLOGY := {
	&"s1":
	{
		"size": Vector2i(8, 5),
		"elevated": [Vector2i(3, 1), Vector2i(3, 3)],
		"blocked": [],
		"spawn": Vector2i(0, 2),
		"core": Vector2i(7, 2)
	},
	&"s2":
	{
		"size": Vector2i(10, 5),
		"elevated": [Vector2i(3, 1), Vector2i(3, 3)],
		"blocked": [],
		"spawn": Vector2i(0, 2),
		"core": Vector2i(9, 2)
	},
	&"s3":
	{
		"size": Vector2i(10, 6),
		"elevated": [Vector2i(2, 3)],
		"blocked": [Vector2i(5, 2), Vector2i(5, 3)],
		"spawn": Vector2i(0, 2),
		"core": Vector2i(9, 4)
	},
}

@export var stage_id: StringName = &""
@export var theme_id: StringName = &""
@export var approval_token: StringName = &""
@export var approval_manifest_sha256: String = ""
@export var human_final_art: bool = false
@export var ground_id: StringName = &""
@export var route_id: StringName = &""
@export var elevated_id: StringName = &""
@export var blocked_id: StringName = &""
@export var elevated_cells: Array[Vector2i] = []
@export var elevated_variant_ids: Array[StringName] = []
@export var blocked_cells: Array[Vector2i] = []
@export var blocked_variant_ids: Array[StringName] = []
@export var backdrop_panorama_id: StringName = &""
@export var surface_modulate: Color = Color.WHITE
@export var spawn_landmark_id: StringName = &""
@export var spawn_cell: Vector2i = Vector2i(-1, -1)
@export var spawn_pivot: Vector2i = Vector2i.ZERO
@export var spawn_offset: Vector2i = Vector2i.ZERO
@export var core_landmark_id: StringName = &""
@export var core_cell: Vector2i = Vector2i(-1, -1)
@export var core_pivot: Vector2i = Vector2i.ZERO
@export var core_offset: Vector2i = Vector2i.ZERO


static func expects_theme(stage: StageDef) -> bool:
	return stage != null and stage.id in REQUIRED_THEME_STAGE_IDS


static func resolve_for(stage: StageDef, resolver: Callable = Callable()) -> Dictionary:
	if stage == null or not expects_theme(stage):
		return {"required": false, "theme": null, "error": ""}
	var path := "res://data/presentation/%s_world_theme.tres" % stage.id
	var theme: StageArtTheme = null
	if resolver.is_valid():
		theme = resolver.call(path) as StageArtTheme
	elif ResourceLoader.exists(path):
		theme = load(path) as StageArtTheme
	if theme == null:
		return {
			"required": true,
			"theme": null,
			"error": "required stage art theme failed to load: %s" % path
		}
	var errors := theme.validation_errors(stage)
	for id: StringName in theme.required_manifest_ids():
		if Art.texture(id) == null or Art.size(id) == Vector2i.ZERO:
			errors.append("manifest asset missing or unsized: %s" % id)
	if not errors.is_empty():
		return {
			"required": true,
			"theme": null,
			"error": "required stage art theme is invalid: %s" % "; ".join(errors)
		}
	return {"required": true, "theme": theme, "error": ""}


static func load_for(stage: StageDef) -> StageArtTheme:
	var result := resolve_for(stage)
	if not String(result["error"]).is_empty():
		push_error("stage_art_theme: %s" % result["error"])
	return result["theme"] as StageArtTheme


func applies_to(stage: StageDef) -> bool:
	return stage != null and stage.id == stage_id


func tile_id(tile: StageDef.Tile, is_route: bool) -> StringName:
	if tile == StageDef.Tile.ELEVATED:
		return elevated_id
	if tile == StageDef.Tile.BLOCKED:
		return blocked_id
	if is_route:
		return route_id
	if tile == StageDef.Tile.GROUND:
		return ground_id
	return &""


func tile_id_at(cell: Vector2i, tile: StageDef.Tile, is_route: bool) -> StringName:
	if tile == StageDef.Tile.ELEVATED:
		var index := elevated_cells.find(cell)
		return elevated_variant_ids[index] if index >= 0 else elevated_id
	if tile == StageDef.Tile.BLOCKED:
		var index := blocked_cells.find(cell)
		return blocked_variant_ids[index] if index >= 0 else blocked_id
	return tile_id(tile, is_route)


func resolve_cell(cell: Vector2i, tile: StageDef.Tile, is_route: bool) -> Dictionary:
	return {"tile_id": tile_id_at(cell, tile, is_route), "cadence_id": &""}


func required_manifest_ids() -> Array[StringName]:
	return SHARED_IDS.duplicate()


func validation_errors(stage: StageDef) -> PackedStringArray:
	var errors := PackedStringArray()
	if not applies_to(stage):
		errors.append("theme stage_id does not match stage")
	if stage_id not in REQUIRED_THEME_STAGE_IDS:
		errors.append("theme stage_id is not in the required S1-S3 inventory")
	if theme_id != SHARED_THEME_ID:
		errors.append("theme_id is not the shared Act I alpine family")
	if approval_token != APPROVAL_TOKEN:
		errors.append("approval token is not the approved Act I S1-S3 synthesis direction")
	if not approval_manifest_sha256.is_empty():
		errors.append("approval manifest hash must remain empty until final owner verdict")
	if human_final_art:
		errors.append("shared Act I runtime candidate must not claim human-final art")
	if surface_modulate != Color.WHITE:
		errors.append("shared Act I surface modulation must be Color.WHITE")
	if spawn_pivot != SHARED_ENDPOINT_PIVOT or core_pivot != SHARED_ENDPOINT_PIVOT:
		errors.append("shared Act I endpoint pivots do not match 64x32 native overlays")
	var actual_ids: Array[StringName] = [
		ground_id,
		route_id,
		elevated_id,
		blocked_id,
		spawn_landmark_id,
		core_landmark_id,
		backdrop_panorama_id
	]
	if actual_ids != SHARED_IDS:
		errors.append("logical role IDs do not match the shared Act I inventory")
	if elevated_cells.size() != elevated_variant_ids.size():
		errors.append("elevated cells and IDs must have matching lengths")
	if blocked_cells.size() != blocked_variant_ids.size():
		errors.append("blocked cells and IDs must have matching lengths")
	for id: StringName in elevated_variant_ids:
		if id != elevated_id:
			errors.append("elevated variant is not the shared raised role: %s" % id)
	for id: StringName in blocked_variant_ids:
		if id != blocked_id:
			errors.append("blocked variant is not the shared blocked role: %s" % id)
	if not TOPOLOGY.has(stage_id):
		return errors
	var expected: Dictionary = TOPOLOGY[stage_id]
	if elevated_cells != Array(expected["elevated"]):
		errors.append("elevated cells do not match the approved topology")
	if blocked_cells != Array(expected["blocked"]):
		errors.append("blocked cells do not match the approved topology")
	if spawn_cell != expected["spawn"]:
		errors.append("spawn endpoint does not match the approved topology")
	if core_cell != expected["core"]:
		errors.append("core endpoint does not match the approved topology")
	if stage != null:
		if stage.grid_size() != expected["size"]:
			errors.append("stage grid size does not match the approved topology")
		if stage.tile_at(spawn_cell) != StageDef.Tile.SPAWN:
			errors.append("spawn overlay cell is not SPAWN")
		if stage.tile_at(core_cell) != StageDef.Tile.BASE:
			errors.append("core overlay cell is not BASE")
		for cell: Vector2i in elevated_cells:
			if stage.tile_at(cell) != StageDef.Tile.ELEVATED:
				errors.append("approved elevated cell is not ELEVATED: %s" % cell)
		for cell: Vector2i in blocked_cells:
			if stage.tile_at(cell) != StageDef.Tile.BLOCKED:
				errors.append("approved blocked cell is not BLOCKED: %s" % cell)
	return errors
