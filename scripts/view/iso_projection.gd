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


## Grid-root position that centers the stage's diamond content box in the
## viewport. Content box (pinned): horizontal = the diamond's exact span;
## vertical from -ELEV_LIFT_PX - 64 (sprite headroom, top-padded only) to
## span * TILE_H / 2 + 8.
static func origin_for(grid_size: Vector2i, viewport: Vector2) -> Vector2:
	var span := float(grid_size.x + grid_size.y)
	var origin_x := viewport.x * 0.5 - (float(grid_size.x) - float(grid_size.y)) * TILE_W * 0.25
	var top := -ELEV_LIFT_PX - 64.0
	var bottom := span * TILE_H * 0.5 + 8.0
	var origin_y := viewport.y * 0.5 - (top + bottom) * 0.5
	return Vector2(origin_x, origin_y)
