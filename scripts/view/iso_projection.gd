class_name IsoProjection
extends RefCounted

## Pure 2:1 dimetric projection (td-phase-12 pinned parameters). All
## functions are static and operate in GRID-LOCAL space: cell (0,0)'s top
## diamond corner sits at the local origin and the view adds
## _grid_root.position. A cell's diamond top face in screen space is exactly
## its unit square in cell space, so one map serves cell centers
## (p = cell + (0.5, 0.5)) and continuous interpolated enemy positions.
## Elevation is view-only: ELEVATED faces draw ELEV_LIFT_PX higher; the
## model never sees any of this (architecture rule 1).

const TILE_W := 64.0
const TILE_H := 32.0
const ELEV_LIFT_PX := 16.0
## Sprite bottom-center sits this far below its cell's face center.
const FEET_OFFSET := 6.0


## Continuous cell space -> grid-local screen point.
static func project(p: Vector2) -> Vector2:
	return Vector2((p.x - p.y) * TILE_W * 0.5, (p.x + p.y) * TILE_H * 0.5)


## Grid-local screen point -> continuous flat cell space (exact algebraic
## inverse of project; ignores elevation).
static func unproject(local: Vector2) -> Vector2:
	var u := local.x / (TILE_W * 0.5)
	var v := local.y / (TILE_H * 0.5)
	return Vector2((u + v) * 0.5, (v - u) * 0.5)


## Elevation-aware picking (td-phase-12 closed form). A point on a lifted
## face inverts to p' = p_flat - (0.5, 0.5), and lifted faces tile flat cell
## space disjointly, so the unique lifted-face owner is
## floor(p' + (0.5, 0.5)). Wall-band clicks fall through to the naive cell
## (pinned; D3 reserved). Corner tie (found by the round-trip GUT property):
## a lifted diamond's TOP corner coincides exactly with the face center of
## its NW flat neighbor — the tie breaks to the flat cell so
## cell_at(cell_center(c)) == c holds for EVERY cell.
static func pick(local: Vector2, is_lifted: Callable) -> Vector2i:
	var p := unproject(local)
	# grid-scale division roundoff can push seam-generated lattice points
	# (face centers, corners) off by an ulp — floor() then jumps a whole
	# cell. Snap to the half-cell lattice within 1e-4 before flooring.
	var snapped := (p * 2.0).round() * 0.5
	if absf(p.x - snapped.x) < 0.0001 and absf(p.y - snapped.y) < 0.0001:
		p = snapped
	var p_lift := p + Vector2(0.5, 0.5)
	var lifted_cell := Vector2i(p_lift.floor())
	var exact_corner := (
		p_lift.x == float(lifted_cell.x) and p_lift.y == float(lifted_cell.y)
	)
	if not exact_corner and bool(is_lifted.call(lifted_cell)):
		return lifted_cell
	return Vector2i(p.floor())


static func face_center(cell: Vector2i, lifted: bool = false) -> Vector2:
	var center := project(Vector2(cell) + Vector2(0.5, 0.5))
	if lifted:
		center.y -= ELEV_LIFT_PX
	return center


## An origin-centered face diamond (top, right, bottom, left) at the given
## uniform scale — one shape serves every screen-space footprint overlay
## (hover cursor, valid-cell highlights, spell footprint = scale * span).
static func face_polygon(scale: float = 1.0) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -TILE_H * 0.5 * scale),
		Vector2(TILE_W * 0.5 * scale, 0.0),
		Vector2(0.0, TILE_H * 0.5 * scale),
		Vector2(-TILE_W * 0.5 * scale, 0.0),
	])


## The four projected corners of a cell's top face (top, right, bottom,
## left), for diamond footprint overlays and tile polys.
static func cell_polygon(cell: Vector2i, lifted: bool = false) -> PackedVector2Array:
	var lift := -ELEV_LIFT_PX if lifted else 0.0
	var off := Vector2(0.0, lift)
	var c := Vector2(cell)
	return PackedVector2Array([
		project(c) + off,
		project(c + Vector2(1.0, 0.0)) + off,
		project(c + Vector2(1.0, 1.0)) + off,
		project(c + Vector2(0.0, 1.0)) + off,
	])


## Painter's depth over continuous cell space.
static func depth(p: Vector2) -> int:
	return int(floorf(p.x) + floorf(p.y))


## Z bands (td-phase-12 pin): grid content 0-40 — tiles at 2*depth,
## entities/traps/tracers at 2*depth + 1; UI overlays 50; juice 60; HUD 70.
static func tile_z(cell: Vector2i) -> int:
	return 2 * (cell.x + cell.y)


static func entity_z(p: Vector2) -> int:
	return 2 * depth(p) + 1


## The stage's diamond content box in grid-local space (pinned): horizontal
## = the diamond's exact span; vertical from -ELEV_LIFT_PX - 64 (sprite
## headroom, top-padded only) to span * TILE_H / 2 + 8.
static func content_box(grid_size: Vector2i) -> Rect2:
	var span := float(grid_size.x + grid_size.y)
	var left := -float(grid_size.y) * TILE_W * 0.5
	var top := -ELEV_LIFT_PX - 64.0
	var width := span * TILE_W * 0.5
	var height := span * TILE_H * 0.5 + 8.0 - top
	return Rect2(left, top, width, height)


## Exact projected terrain bounds. Height-fill intentionally excludes unit
## sprite headroom and UI margins: the human verdict is about the MAP, while
## content_box() remains the larger edge clamp for sprites and effects.
static func terrain_box(grid_size: Vector2i) -> Rect2:
	var span := float(grid_size.x + grid_size.y)
	var left := -float(grid_size.y) * TILE_W * 0.5
	var top := -ELEV_LIFT_PX
	var width := span * TILE_W * 0.5
	var height := span * TILE_H * 0.5 - top
	return Rect2(left, top, width, height)


## Uniform scale whose transformed terrain height equals the live viewport
## height exactly. Width is allowed to overflow and is recovered by panning.
static func height_fill_scale(grid_size: Vector2i, viewport: Vector2) -> float:
	return viewport.y / terrain_box(grid_size).size.y


## Grid-root origin that centers the scaled terrain rectangle in the viewport.
static func terrain_origin_for(grid_size: Vector2i, viewport: Vector2, scale: float) -> Vector2:
	return viewport * 0.5 - terrain_box(grid_size).get_center() * scale


## Screen-space visual-content rectangle after applying a pan offset to the
## terrain-centered root. Kept pure so both the view and GUT share one truth.
static func content_screen_rect(
	grid_size: Vector2i, viewport: Vector2, scale: float, pan: Vector2 = Vector2.ZERO
) -> Rect2:
	var box := content_box(grid_size)
	var origin := terrain_origin_for(grid_size, viewport, scale) + pan
	return Rect2(origin + box.position * scale, box.size * scale)


## Legal pan interval encoded as Rect2(position=min, end=max). An axis whose
## visual content already fits is locked at zero; an overflowing axis can move
## until either content edge meets the corresponding viewport edge exactly.
static func pan_bounds(grid_size: Vector2i, viewport: Vector2, scale: float) -> Rect2:
	var screen := content_screen_rect(grid_size, viewport, scale)
	var min_pan := Vector2.ZERO
	var max_pan := Vector2.ZERO
	if screen.size.x > viewport.x:
		min_pan.x = viewport.x - screen.end.x
		max_pan.x = -screen.position.x
	if screen.size.y > viewport.y:
		min_pan.y = viewport.y - screen.end.y
		max_pan.y = -screen.position.y
	return Rect2(min_pan, max_pan - min_pan)


static func clamp_pan(pan: Vector2, bounds: Rect2) -> Vector2:
	return Vector2(
		clampf(pan.x, bounds.position.x, bounds.end.x),
		clampf(pan.y, bounds.position.y, bounds.end.y),
	)


## Uniform grid scale that fills the available canvas box, snapped DOWN to
## 0.25 steps (uneven pixel-art scaling stays tolerable), clamped [1, 3].
static func fit_scale(grid_size: Vector2i, avail: Vector2) -> float:
	var box := content_box(grid_size)
	var s := minf(avail.x / box.size.x, avail.y / box.size.y)
	return clampf(floorf(s * 4.0) * 0.25, 1.0, 3.0)


## Grid-root position centering the scaled content box in the viewport.
static func origin_for(grid_size: Vector2i, viewport: Vector2, scale: float = 1.0) -> Vector2:
	var box := content_box(grid_size)
	return viewport * 0.5 - box.get_center() * scale
