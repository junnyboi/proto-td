extends RefCounted

## Tiles (Lane A): 32x32, rendered at 2x = the 64 px grid. Tiles must stay
## quiet under units (graphics proposal §5) — texture is low-contrast
## speckle + flagstone grooves from a deterministic integer hash (no RNG,
## byte-identical regeneration). Glyph tiles (spawn arrow, base gate) draw
## over the ground texture.

const Palette := preload("res://tools/pixel/palette.gd")
const Pix := preload("res://tools/pixel/pix.gd")

const SIZE := Vector2i(32, 32)

const SPAWN_GLYPH: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"......dd",
	"......ddd",
	"......dddd",
	"..ddddRRddd",
	"..dRRRRRRddd",
	"..dRRRRRRRddd",
	"..dRRRRRRRRddd",
	"..dRRRRRRRRRddd",
	"..dRRRRRRRRRRddd",
	"..dRRRRRRRRRddd",
	"..dRRRRRRRRddd",
	"..dRRRRRRRddd",
	"..dRRRRRRddd",
	"..ddddRRddd",
	"......dddd",
	"......ddd",
	"......dd",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
]

const BASE_GLYPH: Array[String] = [
	"",
	"..MM....................MM",
	"..MMM..................MMM",
	"..MMnn....nnnnnn....nnMMM",
	"..MMnBBnnnBBBBBBnnnBBnMMM",
	"..MMnBBBBBBBBBBBBBBBBnMMM",
	"..MMnBBBBbbbbbbbbBBBBnMMM",
	"..MMnBBbbccccccccbbBBnMMM",
	"..MMnBBbccccCCccccbBBnMMM",
	"..MMnBbccccCCCCccccbBnMMM",
	"..MMnBbcccCCCCCCcccbBnMMM",
	"..MMnBbcccCCCCCCcccbBnMMM",
	"..MMnBbccccCCCCccccbBnMMM",
	"..MMnBBbccccCCccccbBBnMMM",
	"..MMnBBbbccccccccbbBBnMMM",
	"..MMnBBBBbbbbbbbbBBBBnMMM",
	"..MMnBBBBBBBBBBBBBBBBnMMM",
	"..MMnBBnnnBBBBBBnnnBBnMMM",
	"..MMnn....nnnnnn....nnMMM",
	"..MMM..................MM",
	"..MM....................MM",
]


static func _hash(x: int, y: int, salt: int) -> int:
	var n := x * 374761393 + y * 668265263 + salt * 1274126177
	n = (n ^ (n >> 13)) * 1103515245
	return absi(n ^ (n >> 16))


## Speckled stone fill with 16 px flagstone grooves (offset per row band).
static func _stone(base: Color, dark: Color, light: Color, salt: int) -> Image:
	var img := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var c := base
			var groove_x := 31 if (y / 16) % 2 == 0 else 15
			if y % 16 == 15 or x == groove_x:
				c = dark
			else:
				var h := _hash(x, y, salt) % 100
				if h < 7:
					c = dark
				elif h < 11:
					c = light
			img.set_pixel(x, y, c)
	return img


## v2 fidelity pass: deployable ground is mossy flagstone (cool, sparse
## DEEP_GREEN/GREEN tufts over the slate) so the warm dirt ROAD — the cells
## enemies actually walk — reads as a different material at a glance. Both
## stay low-contrast under units (quiet-tiles rule).
static func ground() -> Image:
	var img := _stone(Palette.SLATE, Palette.DUSK, Palette.GRAY, 1)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var h := _hash(x, y, 7) % 100
			if h < 4:
				img.set_pixel(x, y, Palette.DEEP_GREEN)
			elif h == 4 and y % 16 != 15:
				img.set_pixel(x, y, Palette.GREEN)
	return img


## The enemy lane: warm packed dirt with pebbles and soft ruts — the one
## warm surface on the field, so "where they walk" needs no legend.
static func road() -> Image:
	var img := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var c := Palette.BROWN
			var h := _hash(x, y, 8) % 100
			if y % 16 == 15:
				c = Palette.UMBER
			elif h < 8:
				c = Palette.UMBER
			elif h < 13:
				c = Palette.BRONZE
			elif h < 15:
				c = Palette.SKIN_SHADOW
			img.set_pixel(x, y, c)
	return img


static func elevated() -> Image:
	var img := _stone(Palette.STEEL, Palette.GRAY, Palette.PALE, 2)
	# raised slab: warm top-left light, hard drop edge bottom
	for x: int in SIZE.x:
		img.set_pixel(x, 0, Palette.PALE)
		img.set_pixel(x, SIZE.y - 2, Palette.GRAY)
		img.set_pixel(x, SIZE.y - 1, Palette.DUSK)
	for y: int in SIZE.y - 1:
		img.set_pixel(0, y, Palette.PALE)
		img.set_pixel(SIZE.x - 1, y, Palette.GRAY)
	return img


static func blocked() -> Image:
	var img := _stone(Palette.DUSK, Palette.VOID, Palette.SLATE, 3)
	for i: int in 4:
		var p := Vector2i(6 + i * 6, 6 + (i % 2) * 16)
		for q: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			img.set_pixel(p.x + q.x + 2, p.y + q.y + 2, Palette.VOID)
	return img


static func void_tile() -> Image:
	var img := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var h := _hash(x, y, 4) % 100
			img.set_pixel(x, y, Palette.VOID if h < 96 else Palette.INK)
	return img


static func spawn() -> Image:
	# spawn and base sit ON the lane — they draw over road, not ground
	var img := road()
	var glyph := Pix.from_rows(
		SPAWN_GLYPH, {"R": Palette.CRIMSON, "d": Palette.WINE}, SIZE
	)
	Pix.blend(img, glyph, Vector2i(8, 0))
	return img


static func base() -> Image:
	var img := road()
	var glyph := Pix.from_rows(
		BASE_GLYPH,
		{
			"n": Palette.NAVY,
			"B": Palette.BLUE,
			"b": Palette.NAVY,
			"c": Palette.SKY,
			"C": Palette.CYAN,
			"M": Palette.STEEL,
		},
		SIZE
	)
	Pix.blend(img, glyph, Vector2i(3, 5))
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
	}
