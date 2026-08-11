extends RefCounted

## Tiles (Lane A, P12.1 iso): 32x16 native 2:1 diamond top faces, rendered
## at 2x = the 64x32 screen diamond; tile_elevated is 32x24 (16 px face +
## 8 px cliff walls). Pixels outside the diamond stay transparent. Tiles
## must stay quiet under units (graphics proposal §5) — texture is
## low-contrast speckle + iso-axis flagstone seams from the deterministic
## integer hash (no RNG, byte-identical regeneration). The v2 material
## split is kept: cool mossy flagstone GROUND vs the one warm surface,
## packed-dirt ROAD. Glyph tiles (spawn arrow, base gate) draw over the
## road face. Probe reservation: exact WHITE and SKY never appear in tiles
## (the old base glyph's SKY step is re-laid as CYAN/PALE).

const Palette := preload("res://tools/pixel/palette.gd")
const Pix := preload("res://tools/pixel/pix.gd")

const SIZE := Vector2i(32, 16)
const WALL_H := 8
const ELEVATED_SIZE := Vector2i(32, 24)

const SPAWN_GLYPH: Array[String] = [
	"....dd",
	"....dRdd",
	"ddddRRRdd",
	"dRRRRRRRRdd",
	"ddddRRRdd",
	"....dRdd",
	"....dd",
]

const BASE_GLYPH: Array[String] = [
	".....nn",
	"...nnBBnn",
	".nnBBccBBnn",
	"nBBccCCccBBn",
	".nnBBccBBnn",
	"...nnBBnn",
	".....nn",
]


static func size_of(tile_id: StringName) -> Vector2i:
	return ELEVATED_SIZE if tile_id == &"tile_elevated" else SIZE


static func _hash(x: int, y: int, salt: int) -> int:
	var n := x * 374761393 + y * 668265263 + salt * 1274126177
	n = (n ^ (n >> 13)) * 1103515245
	return absi(n ^ (n >> 16))


## Iso-axis sub-cell coordinates of a face pixel, scaled to [0, 1024)
## inside the diamond: u runs along one diamond axis, v along the other.
## Integer-exact; seam bands laid on these follow the diamond's own edges.
static func _iso_uv(x: int, y: int) -> Vector2i:
	var xx := 2 * x + 1 - SIZE.x
	var yy := 2 * y + 1
	return Vector2i(xx * SIZE.y + yy * SIZE.x, yy * SIZE.x - xx * SIZE.y)


## Paint a 32x16 diamond face: `paint` is called for every inside pixel
## with (x, y, iso uv) and returns its Color; corners outside the diamond
## stay transparent.
static func _face(paint: Callable) -> Image:
	var img := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	var mask := Pix.iso_diamond_mask(SIZE.x, SIZE.y)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if mask[y * SIZE.x + x] == 1:
				var c: Color = paint.call(x, y, _iso_uv(x, y))
				img.set_pixel(x, y, c)
	return img


## 1 px light rim on the top-face edge (inside pixels with a missing
## 4-neighbor) — the elevated slab's highlight per the P12 pin.
static func _rim(img: Image, color: Color) -> void:
	var mask := Pix.iso_diamond_mask(SIZE.x, SIZE.y)
	var offsets: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if mask[y * SIZE.x + x] == 0:
				continue
			for offset: Vector2i in offsets:
				var p := Vector2i(x, y) + offset
				var outside := p.x < 0 or p.y < 0 or p.x >= SIZE.x or p.y >= SIZE.y
				if outside or mask[p.y * SIZE.x + p.x] == 0:
					img.set_pixel(x, y, color)
					break


## Deployable ground: cool mossy flagstone — slate with iso-seam grooves
## and sparse DEEP_GREEN/GREEN tufts, so the warm dirt ROAD reads as a
## different material at a glance (the v2 legibility win, kept).
static func ground() -> Image:
	return _face(
		func(x: int, y: int, uv: Vector2i) -> Color:
			var seam := uv.x % 512 < 64 or uv.y % 512 < 64
			var m := _hash(x, y, 7) % 100
			if m < 4:
				return Palette.DEEP_GREEN
			if m == 4 and not seam:
				return Palette.GREEN
			if seam:
				return Palette.DUSK
			var h := _hash(x, y, 1) % 100
			if h < 7:
				return Palette.DUSK
			if h < 11:
				return Palette.GRAY
			return Palette.SLATE
	)


## The enemy lane: warm packed dirt with pebbles and a soft rut — the one
## warm surface on the field, so "where they walk" needs no legend.
static func road() -> Image:
	return _face(
		func(x: int, y: int, uv: Vector2i) -> Color:
			if uv.y % 512 < 64:
				return Palette.UMBER
			var h := _hash(x, y, 8) % 100
			if h < 8:
				return Palette.UMBER
			if h < 13:
				return Palette.BRONZE
			if h < 15:
				return Palette.SKIN_SHADOW
			return Palette.BROWN
	)


## Raised slab: cool stone face with a 1 px PALE rim on the top-face edge,
## extruded 8 px into cliff walls — left SLATE, right DUSK (two ramp steps
## darker than the STEEL face, right one step darker than left).
static func elevated() -> Image:
	var face := _face(
		func(x: int, y: int, uv: Vector2i) -> Color:
			if uv.x % 512 < 64 or uv.y % 512 < 64:
				return Palette.GRAY
			var h := _hash(x, y, 2) % 100
			if h < 7:
				return Palette.GRAY
			if h < 11:
				return Palette.PALE
			return Palette.STEEL
	)
	_rim(face, Palette.PALE)
	return Pix.iso_extrude(face, WALL_H, Palette.SLATE, Palette.DUSK)


static func blocked() -> Image:
	var img := _face(
		func(x: int, y: int, uv: Vector2i) -> Color:
			if uv.x % 512 < 64 or uv.y % 512 < 64:
				return Palette.VOID
			var h := _hash(x, y, 3) % 100
			if h < 7:
				return Palette.VOID
			if h < 11:
				return Palette.SLATE
			return Palette.DUSK
	)
	# rubble pocks; fixed positions, all inside the diamond
	var pocks: Array[Vector2i] = [
		Vector2i(16, 4), Vector2i(10, 6), Vector2i(20, 9), Vector2i(13, 10)
	]
	for p: Vector2i in pocks:
		for q: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			img.set_pixel(p.x + q.x, p.y + q.y, Palette.VOID)
	return img


static func void_tile() -> Image:
	return _face(
		func(x: int, y: int, _uv: Vector2i) -> Color:
			return Palette.VOID if _hash(x, y, 4) % 100 < 96 else Palette.INK
	)


## Out-of-bounds filler ring: darker, low-contrast void-water — short INK
## ripple dashes + a rare moss fleck, so the ring reads as backdrop, never
## as a playable tile.
static func backdrop() -> Image:
	return _face(
		func(x: int, y: int, _uv: Vector2i) -> Color:
			if _hash(x / 4, y, 9) % 100 < 10:
				return Palette.INK
			if _hash(x, y, 10) % 100 > 97:
				return Palette.DEEP_GREEN
			return Palette.VOID
	)


static func spawn() -> Image:
	# spawn and base sit ON the lane — glyphs re-laid on the road diamond
	var img := road()
	var glyph := Pix.from_rows(SPAWN_GLYPH, {"R": Palette.CRIMSON, "d": Palette.WINE})
	Pix.blend(img, glyph, Vector2i(10, 4))
	return img


static func base() -> Image:
	var img := road()
	var glyph := Pix.from_rows(
		BASE_GLYPH,
		{"n": Palette.NAVY, "B": Palette.BLUE, "c": Palette.CYAN, "C": Palette.PALE}
	)
	Pix.blend(img, glyph, Vector2i(10, 4))
	return img


static func build() -> Dictionary:
	return {
		&"tile_ground": ground(),
		&"tile_road": road(),
		&"tile_elevated": elevated(),
		&"tile_blocked": blocked(),
		&"tile_void": void_tile(),
		&"tile_spawn": spawn(),
		&"tile_base": base(),
		&"tile_backdrop": backdrop(),
	}
