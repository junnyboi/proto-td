class_name StageDef
extends Resource

## Stage layout + schedule (all balance is data — architecture rule 4).
## grid_rows: one string per row, one char per tile (hand-authorable):
##   . VOID   G GROUND   E ELEVATED   S SPAWN   B BASE   X BLOCKED
## paths: flat Vector2 lists (converted to cells via path_cells());
## squad_size activate in later phases.
## wave_starts: wave-window boundary ticks for ONCE_PER_WAVE spells
## non-empty must be strictly ascending and start at 0 (stage_lint).
## Music routing is presentation metadata: act selects the catalog pair;
## boss_wave_index -1 means BGM for the whole battle, otherwise the view
## hard-switches to the paired boss cue at that wave window.

enum Tile { VOID, GROUND, ELEVATED, SPAWN, BASE, BLOCKED }

const TILE_CHARS := {
	".": Tile.VOID,
	"G": Tile.GROUND,
	"E": Tile.ELEVATED,
	"S": Tile.SPAWN,
	"B": Tile.BASE,
	"X": Tile.BLOCKED,
}

@export var id: StringName = &""
@export var title: String = ""
@export var grid_rows: PackedStringArray = []
@export var paths: Array[PackedVector2Array] = []
@export var waves: Array[Dictionary] = []
@export var wave_starts: PackedInt32Array = []
@export_range(1, 3) var music_act: int = 1
@export var music_boss_wave_index: int = -1
@export var leak_limit: int = 0
@export var squad_size: int = 0
@export var recovery_roster: Array[StringName] = []
# first clear ({kind: operator|trap|spell, id}); campaign_index -1 = not a
# campaign stage (campaign order = ascending index, never scan order);
# requires = unlockable ids this stage's lesson depends on (lint-enforced
# teach-before-use)
@export var rewards: Array[Dictionary] = []
@export var campaign_index: int = -1
@export var requires: Array[StringName] = []
@export var intro_hint: String = ""


func grid_size() -> Vector2i:
	if grid_rows.is_empty():
		return Vector2i.ZERO
	return Vector2i(grid_rows[0].length(), grid_rows.size())


## Portrait battles snapshot one clockwise-rotated stage copy at startup. The
## source resource remains the landscape authoring contract; all non-spatial
## metadata (waves, unlocks, music, roster, rewards) is preserved by duplicate.
func copy_for_viewport(viewport_size: Vector2) -> StageDef:
	return clockwise_rotated_copy() if viewport_size.y > viewport_size.x else self


func clockwise_rotated_copy() -> StageDef:
	var source_size := grid_size()
	var rotated := duplicate(true) as StageDef
	if source_size == Vector2i.ZERO:
		return rotated
	var rotated_rows := PackedStringArray()
	for destination_y: int in source_size.x:
		var row := ""
		for destination_x: int in source_size.y:
			var source_cell := Vector2i(destination_y, source_size.y - 1 - destination_x)
			row += grid_rows[source_cell.y][source_cell.x]
		rotated_rows.append(row)
	rotated.grid_rows = rotated_rows
	var rotated_paths: Array[PackedVector2Array] = []
	for source_path: PackedVector2Array in paths:
		var rotated_path := PackedVector2Array()
		for point: Vector2 in source_path:
			rotated_path.append(Vector2(rotate_cell_clockwise(Vector2i(point), source_size)))
		rotated_paths.append(rotated_path)
	rotated.paths = rotated_paths
	return rotated


static func rotate_cell_clockwise(cell: Vector2i, source_size: Vector2i) -> Vector2i:
	return Vector2i(source_size.y - 1 - cell.y, cell.x)


func tile_at(cell: Vector2i) -> Tile:
	if cell.y < 0 or cell.y >= grid_rows.size():
		return Tile.VOID
	var row := grid_rows[cell.y]
	if cell.x < 0 or cell.x >= row.length():
		return Tile.VOID
	return TILE_CHARS.get(row[cell.x], Tile.VOID)


func is_enemy_walkable(cell: Vector2i) -> bool:
	return tile_at(cell) in [Tile.GROUND, Tile.SPAWN, Tile.BASE]


func path_cells(idx: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if idx < 0 or idx >= paths.size():
		return out
	for v: Vector2 in paths[idx]:
		out.append(Vector2i(v))
	return out


func operator_cell_in_domain(operator_def: OperatorDef, cell: Vector2i) -> bool:
	if operator_def.placement == OperatorDef.Placement.GROUND:
		return tile_at(cell) == Tile.GROUND
	return tile_at(cell) == Tile.ELEVATED


func trap_cell_in_domain(cell: Vector2i) -> bool:
	if tile_at(cell) != Tile.GROUND:
		return false
	for path_index: int in paths.size():
		if path_cells(path_index).has(cell):
			return true
	return false


func spell_target_in_domain(spell_def: SpellDef, target: Variant) -> bool:
	if spell_def.target_kind == SpellDef.TargetKind.CELL:
		if typeof(target) != TYPE_VECTOR2I:
			return false
		var cell: Vector2i = target
		var size := grid_size()
		return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y
	return typeof(target) == TYPE_INT and int(target) >= 0
