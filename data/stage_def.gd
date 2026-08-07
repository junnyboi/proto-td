class_name StageDef
extends Resource

## Stage layout + schedule (all balance is data — architecture rule 4).
## grid_rows: one string per row, one char per tile (hand-authorable):
##   . VOID   G GROUND   E ELEVATED   S SPAWN   B BASE   X BLOCKED
## paths: flat Vector2 lists (converted to cells via path_cells());
## waves: {tick, enemy_id, path_idx}. Full schema from Phase 1; reward and
## squad_size activate in later phases.

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
@export var leak_limit: int = 0
@export var squad_size: int = 0
@export var reward: Dictionary = {}
@export var intro_hint: String = ""


func grid_size() -> Vector2i:
	if grid_rows.is_empty():
		return Vector2i.ZERO
	return Vector2i(grid_rows[0].length(), grid_rows.size())


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
