class_name StageArtTheme
extends Resource

## Presentation-only stage art contract. This resource is never read by the
## model, save, hash, or replay lanes; the disposable view consumes it to map
## stage roles to manifest IDs and typed decorative anchors.

const REQUIRED_THEME_STAGE_IDS: Array[StringName] = [&"s1", &"s2", &"s3"]
const S1_APPROVAL_TOKEN: StringName = &"AUI-DESIGN-D-REVISION-2"
const S1_APPROVAL_MANIFEST_SHA256 := (
	"8a0be78a84f0c45f66ac16d5eef5bdb08fc83f212040d5ce696bf42617fa83e6"
)
const ACT2_SEMANTIC_APPROVAL_TOKEN: StringName = &"ACT-II-S2-S3-H0"
const ACT2_CADENCE_E: StringName = &"world.pressure.cadence_e"
const ACT2_CADENCE_S: StringName = &"world.pressure.cadence_s"
const ACT2_CADENCE_E_TO_S: StringName = &"world.pressure.cadence_e_s"
const ACT2_CADENCE_S_TO_E: StringName = &"world.pressure.cadence_s_e"
const ACT2_SURFACE_MODULATE := Color(1.15, 1.15, 1.15, 1.0)

const S2_ELEVATED_CELLS: Array[Vector2i] = [Vector2i(3, 1), Vector2i(3, 3)]
const S2_CADENCE_CELLS: Array[Vector2i] = [
	Vector2i(2, 2), Vector2i(4, 2), Vector2i(6, 2), Vector2i(8, 2),
]
const S3_ELEVATED_CELLS: Array[Vector2i] = [Vector2i(2, 3)]
const S3_BLOCKED_CELLS: Array[Vector2i] = [Vector2i(5, 2), Vector2i(5, 3)]
const S3_CADENCE_CELLS: Array[Vector2i] = [
	Vector2i(2, 2), Vector2i(4, 2), Vector2i(4, 4), Vector2i(7, 4),
]

@export var stage_id: StringName = &""
@export var theme_id: StringName = &""
@export var approval_token: StringName = &""
@export var approval_manifest_sha256: String = ""
@export var human_final_art: bool = false

@export var ground_id: StringName = &""
@export var ground_variant_ids: Array[StringName] = []
@export var route_id: StringName = &""
@export var elevated_id: StringName = &""
@export var elevated_cells: Array[Vector2i] = []
@export var elevated_variant_ids: Array[StringName] = []
@export var blocked_cells: Array[Vector2i] = []
@export var blocked_variant_ids: Array[StringName] = []
@export var cadence_variant_ids: Array[StringName] = []
@export var cadence_cells: Array[Vector2i] = []
@export var cadence_ids: Array[StringName] = []
@export var backdrop_id: StringName = &""
@export var backdrop_variant_ids: Array[StringName] = []
@export var backdrop_panorama_id: StringName = &""
@export var surface_modulate: Color = Color.WHITE

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


static func expects_theme(stage: StageDef) -> bool:
	return stage != null and stage.id in REQUIRED_THEME_STAGE_IDS


static func resolve_for(stage: StageDef, resolver: Callable = Callable()) -> Dictionary:
	var required := expects_theme(stage)
	if stage == null:
		return {"required": false, "theme": null, "error": ""}
	if not required:
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
			"error": "required stage art theme failed to load: %s" % path,
		}
	var errors := theme.validation_errors(stage)
	for id: StringName in theme.required_manifest_ids():
		if Art.texture(id) == null or Art.size(id) == Vector2i.ZERO:
			errors.append("manifest asset missing or unsized: %s" % id)
	if not errors.is_empty():
		return {
			"required": true,
			"theme": null,
			"error": "required stage art theme is invalid: %s" % "; ".join(errors),
		}
	return {"required": true, "theme": theme, "error": ""}


static func load_for(stage: StageDef) -> StageArtTheme:
	var result := resolve_for(stage)
	var error := String(result["error"])
	if not error.is_empty():
		push_error("stage_art_theme: %s" % error)
	return result["theme"] as StageArtTheme


func applies_to(stage: StageDef) -> bool:
	return stage != null and stage.id == stage_id


## Legacy role resolver retained unchanged for S1 and existing renderer callers.
func tile_id(tile: StageDef.Tile, is_route: bool) -> StringName:
	if tile == StageDef.Tile.ELEVATED:
		return elevated_id
	if is_route:
		return route_id
	if tile == StageDef.Tile.GROUND:
		return ground_id
	return &""


## Resolves topology-bearing variants before generic role fallbacks.
func tile_id_at(cell: Vector2i, tile: StageDef.Tile, is_route: bool) -> StringName:
	var resolved: StringName = &""
	if tile == StageDef.Tile.ELEVATED:
		var elevated_index := elevated_cells.find(cell)
		if elevated_index >= 0 and elevated_index < elevated_variant_ids.size():
			resolved = elevated_variant_ids[elevated_index]
		else:
			resolved = elevated_id
	elif tile == StageDef.Tile.BLOCKED:
		var blocked_index := blocked_cells.find(cell)
		if blocked_index >= 0 and blocked_index < blocked_variant_ids.size():
			resolved = blocked_variant_ids[blocked_index]
	elif is_route:
		resolved = route_id
	elif tile == StageDef.Tile.GROUND:
		resolved = ground_id_at(cell)
	return resolved


## Stable cell-local breakup: base ground followed by its shared variants.
func ground_id_at(cell: Vector2i) -> StringName:
	var ids: Array[StringName] = [ground_id]
	ids.append_array(ground_variant_ids)
	if ids.size() == 1:
		return ground_id
	return ids[posmod(cell.x + cell.y * 3, ids.size())]


func cadence_id_at(cell: Vector2i) -> StringName:
	var index := cadence_cells.find(cell)
	if index < 0 or index >= cadence_ids.size():
		return &""
	return cadence_ids[index]


func resolve_cell(cell: Vector2i, tile: StageDef.Tile, is_route: bool) -> Dictionary:
	return {
		"tile_id": tile_id_at(cell, tile, is_route),
		"cadence_id": cadence_id_at(cell) if is_route else &"",
	}


func required_manifest_ids() -> Array[StringName]:
	var candidates: Array[StringName] = [
		ground_id, route_id, elevated_id, backdrop_id, backdrop_panorama_id,
		route_notch_id, spawn_landmark_id, core_landmark_id, rain_measure_id,
	]
	candidates.append_array(ground_variant_ids)
	candidates.append_array(elevated_variant_ids)
	candidates.append_array(blocked_variant_ids)
	candidates.append_array(cadence_variant_ids)
	candidates.append_array(backdrop_variant_ids)
	var ids: Array[StringName] = []
	for id: StringName in candidates:
		if id != &"" and id not in ids:
			ids.append(id)
	return ids


func validation_errors(stage: StageDef) -> PackedStringArray:
	if stage_id == &"s1":
		return _s1_validation_errors(stage)
	if stage_id in [&"s2", &"s3"]:
		return _act2_validation_errors(stage)
	var errors := PackedStringArray()
	if not applies_to(stage):
		errors.append("theme stage_id does not match stage")
	if theme_id == &"":
		errors.append("theme_id is empty")
	return errors


## Keep incumbent S1 strings and checks exact; new fields are dormant for S1.
func _s1_validation_errors(stage: StageDef) -> PackedStringArray:
	var errors := PackedStringArray()
	if not applies_to(stage):
		errors.append("theme stage_id does not match stage")
	if theme_id == &"":
		errors.append("theme_id is empty")
	if approval_token != S1_APPROVAL_TOKEN:
		errors.append("approval token is not the approved S1 revision")
	if approval_manifest_sha256 != S1_APPROVAL_MANIFEST_SHA256:
		errors.append("approval manifest SHA-256 is not the approved S1 revision receipt")
	for id: StringName in _s1_manifest_id_candidates():
		if id == &"":
			errors.append("required manifest id is empty")
	if backdrop_variant_ids.size() != 3:
		errors.append("S1 requires exactly three additional backdrop variants")
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


func _s1_manifest_id_candidates() -> Array[StringName]:
	var ids: Array[StringName] = [
		ground_id, route_id, elevated_id, backdrop_id, backdrop_panorama_id,
		route_notch_id, spawn_landmark_id, core_landmark_id, rain_measure_id,
	]
	ids.append_array(backdrop_variant_ids)
	return ids


func _act2_validation_errors(stage: StageDef) -> PackedStringArray:
	var errors := PackedStringArray()
	if not applies_to(stage):
		errors.append("theme stage_id does not match stage")
	if theme_id == &"":
		errors.append("theme_id is empty")
	if approval_token != ACT2_SEMANTIC_APPROVAL_TOKEN:
		errors.append("approval token is not the approved Act II semantic contract")
	if surface_modulate != ACT2_SURFACE_MODULATE:
		errors.append("Act II surface modulation does not match the measured H1 calibration")

	var seen: Dictionary = {}
	for id: StringName in _act2_manifest_id_candidates():
		if id == &"":
			errors.append("required manifest id is empty")
		elif seen.has(id):
			errors.append("required manifest id is duplicated: %s" % id)
		else:
			seen[id] = true
	if elevated_cells.size() != elevated_variant_ids.size():
		errors.append("elevated cells and IDs must have matching lengths")
	if blocked_cells.size() != blocked_variant_ids.size():
		errors.append("blocked cells and IDs must have matching lengths")
	if cadence_cells.size() != cadence_ids.size():
		errors.append("cadence cells and IDs must have matching lengths")
	for cadence_id: StringName in cadence_ids:
		if cadence_id == &"":
			errors.append("cadence mapping id is empty")
		elif cadence_id not in cadence_variant_ids:
			errors.append("cadence mapping id is not in the cadence inventory: %s" % cadence_id)

	var expected_size := Vector2i(10, 5) if stage_id == &"s2" else Vector2i(10, 6)
	var expected_spawn := Vector2i(0, 2)
	var expected_core := Vector2i(9, 2) if stage_id == &"s2" else Vector2i(9, 4)
	var expected_elevated := S2_ELEVATED_CELLS if stage_id == &"s2" else S3_ELEVATED_CELLS
	var expected_blocked: Array[Vector2i] = []
	if stage_id == &"s3":
		expected_blocked = S3_BLOCKED_CELLS
	var expected_cadence := S2_CADENCE_CELLS if stage_id == &"s2" else S3_CADENCE_CELLS
	if spawn_cell != expected_spawn:
		errors.append("spawn endpoint does not match the approved topology")
	if core_cell != expected_core:
		errors.append("core endpoint does not match the approved topology")
	if elevated_cells != expected_elevated:
		errors.append("elevated cells do not match the approved topology")
	if blocked_cells != expected_blocked:
		errors.append("blocked cells do not match the approved topology")
	if cadence_cells != expected_cadence:
		errors.append("cadence cells do not match the approved topology")
	if stage_id == &"s3" and (
		cadence_id_at(Vector2i(4, 2)) != ACT2_CADENCE_E_TO_S
		or cadence_id_at(Vector2i(4, 4)) != ACT2_CADENCE_S_TO_E
	):
		errors.append("S3 requires dedicated E-to-S and S-to-E cadence IDs")

	if stage != null:
		if stage.grid_size() != expected_size:
			errors.append("stage grid size does not match the approved topology")
		if stage.tile_at(spawn_cell) != StageDef.Tile.SPAWN:
			errors.append("spawn landmark cell is not SPAWN")
		if stage.tile_at(core_cell) != StageDef.Tile.BASE:
			errors.append("core landmark cell is not BASE")
		for cell: Vector2i in expected_elevated:
			if stage.tile_at(cell) != StageDef.Tile.ELEVATED:
				errors.append("approved elevated cell is not ELEVATED: %s" % cell)
		for cell: Vector2i in expected_blocked:
			if stage.tile_at(cell) != StageDef.Tile.BLOCKED:
				errors.append("approved blocked cell is not BLOCKED: %s" % cell)
		var path_cells := stage.path_cells(0)
		for cell: Vector2i in cadence_cells:
			if cell not in path_cells:
				errors.append("cadence cell is not on path: %s" % cell)
	return errors


func _act2_manifest_id_candidates() -> Array[StringName]:
	var ids: Array[StringName] = [
		ground_id, route_id, backdrop_panorama_id, spawn_landmark_id, core_landmark_id,
	]
	ids.append_array(ground_variant_ids)
	ids.append_array(cadence_variant_ids)
	ids.append_array(elevated_variant_ids)
	ids.append_array(blocked_variant_ids)
	return ids
