class_name Targeting
extends RefCounted

## Range + target-selection math (pure static functions over primitives — no
## UnitState/BattleModel imports, so this file is GUT-testable standing alone
## and BattleModel wires it in at Phase 4 integration).
##
## Facing convention (must match UnitState.Facing, td-phase-2-3.md D10):
## RIGHT=0, DOWN=1, LEFT=2, UP=3. range_offsets are authored facing RIGHT
## (+x); rotate_offset maps them to the unit's facing.
##
## Selection is fully deterministic (no RNG in the model): candidates in
## range -> class filter -> max progress_units -> tie broken by lowest id.
## Candidate shape (built by the caller from EnemyState):
## {id: int, cell: Vector2i, progress_units: int, aerial: bool}

enum Filter { STANDARD, ANTI_AIR_PRIORITY, GROUND_ONLY }

const FACING_RIGHT := 0
const FACING_DOWN := 1
const FACING_LEFT := 2
const FACING_UP := 3


static func rotate_offset(offset: Vector2i, facing: int) -> Vector2i:
	match facing:
		FACING_DOWN:
			return Vector2i(-offset.y, offset.x)
		FACING_LEFT:
			return Vector2i(-offset.x, -offset.y)
		FACING_UP:
			return Vector2i(offset.y, -offset.x)
		_:
			return offset


## Absolute cells covered by a range pattern at origin with facing.
## Returned as a Dictionary set (cell -> true) for O(1) membership.
static func range_cells(origin: Vector2i, offsets: Array[Vector2i], facing: int) -> Dictionary:
	var cells: Dictionary = {}
	for offset: Vector2i in offsets:
		cells[origin + rotate_offset(offset, facing)] = true
	return cells


## Deterministic target selection. Returns the chosen candidate's id, or -1.
static func select(
	candidates: Array[Dictionary],
	origin: Vector2i,
	offsets: Array[Vector2i],
	facing: int,
	filter: Filter,
) -> int:
	var cells := range_cells(origin, offsets, facing)
	var in_range: Array[Dictionary] = []
	for c: Dictionary in candidates:
		if cells.has(c["cell"]):
			in_range.append(c)
	match filter:
		Filter.ANTI_AIR_PRIORITY:
			var aerial_only: Array[Dictionary] = in_range.filter(
				func(c: Dictionary) -> bool: return bool(c["aerial"])
			)
			if not aerial_only.is_empty():
				in_range = aerial_only
		Filter.GROUND_ONLY:
			in_range = in_range.filter(func(c: Dictionary) -> bool: return not bool(c["aerial"]))
	var best_id := -1
	var best_progress := -1
	for c: Dictionary in in_range:
		var progress := int(c["progress_units"])
		var cid := int(c["id"])
		if progress > best_progress or (progress == best_progress and cid < best_id):
			best_progress = progress
			best_id = cid
	return best_id


## Cells of a dim x dim square centered on a cell (dim odd: 3 -> 3x3, 5 -> 5x5).
static func splash_cells(center: Vector2i, dim: int) -> Dictionary:
	var cells: Dictionary = {}
	@warning_ignore("integer_division")
	var r := dim / 2
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			cells[center + Vector2i(dx, dy)] = true
	return cells
