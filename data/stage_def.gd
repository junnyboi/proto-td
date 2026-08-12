class_name StageDef
extends Resource

## Stage layout + schedule (all balance is data — architecture rule 4).
## grid_rows: one string per row, one char per tile (hand-authorable):
##   . VOID   G GROUND   E ELEVATED   S SPAWN   B BASE   X BLOCKED
## paths: flat Vector2 lists (converted to cells via path_cells());
## waves: {tick, enemy_id, path_idx}. Full schema from Phase 1; reward and
## squad_size activate in later phases.
## wave_starts: wave-window boundary ticks for ONCE_PER_WAVE spells
## (td-phase-6-7.md §2.3). Empty means one window covering the whole battle;
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
# campaign metadata (Phase 10, td-phase-10.md §2.1): rewards granted on
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
