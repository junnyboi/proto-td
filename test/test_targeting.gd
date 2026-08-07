extends GutTest

## Phase 4 targeting math (td-phase-4-5.md §3.2 G1-G4 core). Pure-function
## tests over constructed candidates; battle integration cases (aerial
## bypass, composition proof) land with the BattleModel wiring.

const SNIPER_OFFSETS_XS: Array[int] = [1, 2, 3, 4]
const OFFSETS_YS: Array[int] = [-1, 0, 1]


func _forward_pattern(xs: Array[int]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x: int in xs:
		for y: int in OFFSETS_YS:
			out.append(Vector2i(x, y))
	return out


func _candidate(id: int, cell: Vector2i, progress: int, aerial: bool = false) -> Dictionary:
	return {"id": id, "cell": cell, "progress_units": progress, "aerial": aerial}


func test_rotation_table() -> void:
	var o := Vector2i(2, -1)
	assert_eq(Targeting.rotate_offset(o, Targeting.FACING_RIGHT), Vector2i(2, -1), "RIGHT identity")
	assert_eq(Targeting.rotate_offset(o, Targeting.FACING_DOWN), Vector2i(1, 2), "DOWN (-y,x)")
	assert_eq(Targeting.rotate_offset(o, Targeting.FACING_LEFT), Vector2i(-2, 1), "LEFT (-x,-y)")
	assert_eq(Targeting.rotate_offset(o, Targeting.FACING_UP), Vector2i(-1, -2), "UP (y,-x)")
	# four rotations compose to identity for every pattern cell
	for offset: Vector2i in _forward_pattern(SNIPER_OFFSETS_XS):
		var once := Targeting.rotate_offset(offset, Targeting.FACING_DOWN)
		var twice := Targeting.rotate_offset(once, Targeting.FACING_DOWN)
		assert_eq(twice, Targeting.rotate_offset(offset, Targeting.FACING_LEFT),
			"DOWN twice == LEFT for %s" % offset)


func test_range_cells_rotated() -> void:
	var origin := Vector2i(5, 3)
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 1)]
	var right := Targeting.range_cells(origin, offsets, Targeting.FACING_RIGHT)
	assert_true(right.has(Vector2i(6, 3)) and right.has(Vector2i(7, 4)), "RIGHT cells")
	var up := Targeting.range_cells(origin, offsets, Targeting.FACING_UP)
	assert_true(up.has(Vector2i(5, 2)) and up.has(Vector2i(6, 1)), "UP cells")
	assert_eq(right.size(), 2, "no duplicate cells")


func test_selection_max_progress_then_lowest_id() -> void:
	var offsets := _forward_pattern([1, 2, 3])
	var origin := Vector2i(0, 0)
	var candidates: Array[Dictionary] = [
		_candidate(7, Vector2i(1, 0), 500),
		_candidate(3, Vector2i(2, 0), 900),
		_candidate(5, Vector2i(3, 1), 900),
		_candidate(1, Vector2i(9, 0), 9999),
	]
	var chosen := Targeting.select(
		candidates, origin, offsets, Targeting.FACING_RIGHT, Targeting.Filter.STANDARD
	)
	assert_eq(chosen, 3, "max progress wins; tie at 900 broken by lower id; out-of-range ignored")
	assert_eq(
		Targeting.select([], origin, offsets, Targeting.FACING_RIGHT, Targeting.Filter.STANDARD),
		-1,
		"no candidates -> -1",
	)


func test_range_edge_cells_in_and_out() -> void:
	var offsets := _forward_pattern(SNIPER_OFFSETS_XS)
	var origin := Vector2i(0, 0)
	var edge_in := _candidate(1, Vector2i(4, 1), 100)
	var edge_out := _candidate(2, Vector2i(5, 0), 100)
	var behind := _candidate(3, Vector2i(-1, 0), 100)
	var candidates: Array[Dictionary] = [edge_in, edge_out, behind]
	assert_eq(
		Targeting.select(
			candidates, origin, offsets, Targeting.FACING_RIGHT, Targeting.Filter.STANDARD
		),
		1,
		"corner cell (4,1) is in; (5,0) and behind are out",
	)


func test_sniper_prefers_aerial_over_further_ground() -> void:
	var offsets := _forward_pattern([1, 2, 3])
	var candidates: Array[Dictionary] = [
		_candidate(1, Vector2i(1, 0), 5000, false),
		_candidate(2, Vector2i(3, 0), 100, true),
	]
	var chosen := Targeting.select(
		candidates, Vector2i.ZERO, offsets, Targeting.FACING_RIGHT,
		Targeting.Filter.ANTI_AIR_PRIORITY
	)
	assert_eq(chosen, 2, "aerial preferred even at far lower progress")
	var ground_only: Array[Dictionary] = [_candidate(1, Vector2i(1, 0), 5000, false)]
	assert_eq(
		Targeting.select(
			ground_only, Vector2i.ZERO, offsets, Targeting.FACING_RIGHT,
			Targeting.Filter.ANTI_AIR_PRIORITY
		),
		1,
		"falls back to ground when no aerial in range",
	)


func test_caster_excludes_aerial_entirely() -> void:
	var offsets := _forward_pattern([1, 2, 3])
	var candidates: Array[Dictionary] = [
		_candidate(1, Vector2i(1, 0), 9000, true),
		_candidate(2, Vector2i(2, 0), 100, false),
	]
	var chosen := Targeting.select(
		candidates, Vector2i.ZERO, offsets, Targeting.FACING_RIGHT, Targeting.Filter.GROUND_ONLY
	)
	assert_eq(chosen, 2, "aerial never chosen by GROUND_ONLY")
	var air_only: Array[Dictionary] = [_candidate(1, Vector2i(1, 0), 9000, true)]
	assert_eq(
		Targeting.select(
			air_only, Vector2i.ZERO, offsets, Targeting.FACING_RIGHT, Targeting.Filter.GROUND_ONLY
		),
		-1,
		"aerial-only field -> no target for a caster",
	)


func test_splash_cells_exactness() -> void:
	var c3 := Targeting.splash_cells(Vector2i(4, 4), 3)
	assert_eq(c3.size(), 9, "3x3 = 9 cells")
	assert_true(c3.has(Vector2i(3, 3)) and c3.has(Vector2i(5, 5)), "corners in")
	assert_false(c3.has(Vector2i(2, 4)) or c3.has(Vector2i(4, 6)), "just outside is out")
	var c5 := Targeting.splash_cells(Vector2i(4, 4), 5)
	assert_eq(c5.size(), 25, "5x5 = 25 cells (SPLASH_RADIUS_PLUS)")
	assert_true(c5.has(Vector2i(2, 4)) and c5.has(Vector2i(6, 6)), "5x5 reaches radius 2")
