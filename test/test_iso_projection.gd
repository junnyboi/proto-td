extends GutTest

## td-phase-12 §Paper exactness constants — derived on paper BEFORE code.
## All values are grid-local (origin = cell (0,0)'s top diamond corner; the
## view adds _grid_root.position). Identity for lifted faces: a point on the
## lifted face of cell c inverts to p' = p_flat - (0.5, 0.5), so
## floor(p' + (0.5, 0.5)) names c uniquely.

const STAGE_PATHS := [
	"res://data/stages/s1.tres",
	"res://data/stages/s2.tres",
	"res://data/stages/s3.tres",
	"res://data/stages/s4.tres",
	"res://data/stages/s5.tres",
	"res://data/stages/s6.tres",
	"res://data/stages/s7.tres",
	"res://data/stages/s8.tres",
]


func _never_lifted(_cell: Vector2i) -> bool:
	return false


func test_face_center_constants() -> void:
	assert_eq(IsoProjection.face_center(Vector2i(0, 0)), Vector2(0.0, 16.0))
	assert_eq(IsoProjection.face_center(Vector2i(2, 1)), Vector2(32.0, 64.0))
	# ELEVATED face center lifts by 16
	assert_eq(IsoProjection.face_center(Vector2i(2, 1), true), Vector2(32.0, 48.0))


func test_unproject_is_exact_inverse() -> void:
	for p: Vector2 in [Vector2(0.5, 0.5), Vector2(2.5, 1.5), Vector2(11.25, 5.75)]:
		var back := IsoProjection.unproject(IsoProjection.project(p))
		assert_almost_eq(back.x, p.x, 0.0001)
		assert_almost_eq(back.y, p.y, 0.0001)


func test_round_trip_every_cell_of_every_stage() -> void:
	for stage_path: String in STAGE_PATHS:
		var stage := load(stage_path) as StageDef
		assert_not_null(stage, stage_path)
		var size := stage.grid_size()
		for y: int in size.y:
			for x: int in size.x:
				var cell := Vector2i(x, y)
				var lifted := stage.tile_at(cell) == StageDef.Tile.ELEVATED
				var is_lifted := func(c: Vector2i) -> bool:
					return stage.tile_at(c) == StageDef.Tile.ELEVATED
				var picked := IsoProjection.pick(
					IsoProjection.face_center(cell, lifted), is_lifted
				)
				assert_eq(picked, cell, "%s cell %s" % [stage_path, cell])


## The four naive quadrants of an ELEVATED (2,1) lifted face all resolve to
## (2,1) — the naive floor spans FOUR cells (plan-lint finding 1's fix).
func test_elevated_pick_all_four_quadrants() -> void:
	var elev := Vector2i(2, 1)
	var is_lifted := func(c: Vector2i) -> bool:
		return c == elev
	var quadrant_points := [
		Vector2(32.0, 40.0),  # p_flat (2.25, 1.25), naive floor (1, 0)
		Vector2(48.0, 48.0),  # p_flat (2.75, 1.25), naive floor (2, 0)
		Vector2(16.0, 48.0),  # p_flat (2.25, 1.75), naive floor (1, 1)
		Vector2(32.0, 56.0),  # p_flat (2.75, 1.75), naive floor (2, 1)
	]
	for pt: Vector2 in quadrant_points:
		assert_eq(IsoProjection.pick(pt, is_lifted), elev, "point %s" % pt)


## GROUND control: the same interior point resolves to the naive cell when
## nothing is lifted (plan-lint finding 2's corrected constant).
func test_ground_control_resolves_naive() -> void:
	assert_eq(IsoProjection.pick(Vector2(32.0, 40.0), _never_lifted), Vector2i(1, 0))


## Corner tie (found by the round-trip property in this suite): the face
## center of a FLAT cell is exactly the top corner of its SE neighbor's
## lifted diamond. With the neighbor ELEVATED, the tie must break to the
## flat cell — cell_at(cell_center(c)) == c is the seam contract.
func test_flat_center_beats_se_lifted_corner() -> void:
	var flat := Vector2i(2, 0)
	var elev := flat + Vector2i(1, 1)
	var is_lifted := func(c: Vector2i) -> bool:
		return c == elev
	var picked := IsoProjection.pick(IsoProjection.face_center(flat), is_lifted)
	assert_eq(picked, flat)


## Wall-band picking (pinned behavior; D3 reserved). The cliff walls of an
## ELEVATED cell occupy (most of) that cell's own FLAT footprint, so naive
## fall-through resolves wall clicks to the elevated cell itself — the
## desirable read ("clicking the cliff selects the high ground"). Points
## below the wall resolve to the south-east neighbor.
func test_wall_band_picking() -> void:
	var elev := Vector2i(2, 1)
	var is_lifted := func(c: Vector2i) -> bool:
		return c == elev
	# (56, 60) is inside the right wall quad of (2,1): u=1.75, v=3.75 ->
	# p'=(2.75, 1.0); lifted candidate floor((3.25, 1.5))=(3,1) != elev ->
	# naive floor((2.75, 1.0)) = (2,1): the elevated cell.
	assert_eq(IsoProjection.pick(Vector2(56.0, 60.0), is_lifted), Vector2i(2, 1))
	# (48, 74) is below the wall: u=1.5, v=4.625 -> p'=(3.0625, 1.5625);
	# lifted candidate (3,2) != elev -> naive (3,1): the SE neighbor.
	assert_eq(IsoProjection.pick(Vector2(48.0, 74.0), is_lifted), Vector2i(3, 1))


func test_depth_monotone_along_both_diagonals() -> void:
	for i: int in 5:
		var along_x := IsoProjection.depth(Vector2(0.5 + i, 0.5))
		var along_x_next := IsoProjection.depth(Vector2(1.5 + i, 0.5))
		assert_true(along_x_next > along_x, "x diagonal at %d" % i)
		var along_y := IsoProjection.depth(Vector2(0.5, 0.5 + i))
		var along_y_next := IsoProjection.depth(Vector2(0.5, 1.5 + i))
		assert_true(along_y_next > along_y, "y diagonal at %d" % i)


func test_entity_draws_above_its_own_tile() -> void:
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(3, 2), Vector2i(11, 5)]:
		var center := Vector2(cell) + Vector2(0.5, 0.5)
		assert_eq(IsoProjection.entity_z(center), IsoProjection.tile_z(cell) + 1)


func test_z_bands_stay_inside_grid_band() -> void:
	# max stage is 12x6 -> max tile z = 2*(11+5) = 32, max entity z = 33 < 40
	assert_true(IsoProjection.tile_z(Vector2i(11, 5)) <= 40)
	assert_true(IsoProjection.entity_z(Vector2(11.5, 5.5)) <= 40)


func test_origin_centers_diamond_bbox() -> void:
	# 12x6 stage in 1280x720: horizontal span = (12+6)*32 = 576; the
	# diamond's left-most x is origin.x - 6*32, right-most origin.x + 12*32.
	var origin := IsoProjection.origin_for(Vector2i(12, 6), Vector2(1280.0, 720.0))
	var left := origin.x - 6.0 * 32.0
	var right := origin.x + 12.0 * 32.0
	assert_almost_eq((left + right) * 0.5, 640.0, 0.0001)
	# vertical content box: top = origin.y - 16 - 64, bottom = origin.y +
	# 18*16 + 8 -> centered on 360
	var top := origin.y - 80.0
	var bottom := origin.y + 288.0 + 8.0
	assert_almost_eq((top + bottom) * 0.5, 360.0, 0.0001)
