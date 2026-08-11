extends RefCounted

## Traps + spell-bar icons (Lane A). Trap sprites are 32x16 iso ground
## props (P12.3): drawn on the 2:1 diamond footprint with transparent
## corners, rendered at 2x over the tile face. The sprung flash overlay
## itself stays the juice layer's (P9) — these are the persistent looks,
## so exact WHITE / SKY never appear here (probe reservation). Icons are
## 24x24 chips for the spell bar, unchanged from v1.

const Palette := preload("res://tools/pixel/palette.gd")
const Pix := preload("res://tools/pixel/pix.gd")

const TRAP_SIZE := Vector2i(32, 16)
const ICON_SIZE := Vector2i(24, 24)

# spike plate: amber diamond inset 1 v-unit from the footprint edge
const PLATE_SIZE := Vector2i(24, 12)
const PLATE_AT := Vector2i(4, 2)

# tar pool: near-full diamond, inset half a v-unit
const POOL_SIZE := Vector2i(28, 14)
const POOL_AT := Vector2i(2, 1)

## Left pixel of each 2 px stud hole, one per plate corner (N/W/E/S) —
## the "laid along the diamond" read.
const SPIKE_STUDS: Array[Vector2i] = [
	Vector2i(15, 4), Vector2i(9, 8), Vector2i(21, 8), Vector2i(15, 11),
]

## Fixed sheen dashes (x, y, length): subtle plum glints on the black pool.
const TAR_SHEEN: Array[Vector3i] = [
	Vector3i(10, 4, 3), Vector3i(17, 5, 2), Vector3i(7, 8, 3),
	Vector3i(20, 9, 2), Vector3i(13, 11, 2),
]

## Fixed rim spurs just outside the pool — the irregular puddle edge.
const TAR_SPURS: Array[Vector2i] = [
	Vector2i(19, 2), Vector2i(4, 6), Vector2i(27, 9), Vector2i(14, 14),
]

# --- 24x24 spell icons: dark chip + glyph -----------------------------------

const BOLT_ICON: Array[String] = [
	"..nnnnnnnnnnnnnnnnnnnn",
	".nmmmmmmmmmmmmmmmmmmmmn",
	".nm..................mn",
	".nm..........GG......mn",
	".nm.........GGG......mn",
	".nm........GGG.......mn",
	".nm.......GGG........mn",
	".nm......GGGGGGG.....mn",
	".nm.....GGGGGGG......mn",
	".nm........WWG.......mn",
	".nm.......WWG........mn",
	".nm......WWG.........mn",
	".nm.....WWW..........mn",
	".nm....WWW...........mn",
	".nm....WW............mn",
	".nm...W..............mn",
	".nm..................mn",
	".nmmmmmmmmmmmmmmmmmmmmn",
	"..nnnnnnnnnnnnnnnnnnnn",
	"",
	"",
]

const CHARM_ICON: Array[String] = [
	"..nnnnnnnnnnnnnnnnnnnn",
	".nmmmmmmmmmmmmmmmmmmmmn",
	".nm..................mn",
	".nm...RRRR....RRRR...mn",
	".nm..RRRRRR..RRRRRR..mn",
	".nm..RRWRRRRRRRRRRR..mn",
	".nm..RWWRRRRRRRRRRR..mn",
	".nm..RRRRRRRRRRRRRR..mn",
	".nm...RRRRRRRRRRRR...mn",
	".nm....RRRRRRRRRR....mn",
	".nm.....RRRRRRRR.....mn",
	".nm......RRRRRR......mn",
	".nm.......RRRR.......mn",
	".nm........RR........mn",
	".nm..................mn",
	".nm....CC......CC....mn",
	".nm...................n",
	".nmmmmmmmmmmmmmmmmmmmmn",
	"..nnnnnnnnnnnnnnnnnnnn",
	"",
	"",
]

const ICON_LEGEND := {
	"n": Palette.VOID,
	"m": Palette.DUSK,
	"G": Palette.GOLD,
	"W": Palette.WHITE,
	"R": Palette.ROSE,
	"C": Palette.CYAN,
}


static func build() -> Dictionary:
	return {
		&"trap_spike_armed": spike_plate(false),
		&"trap_spike_sprung": spike_plate(true),
		&"trap_tar": tar(),
		&"icon_bolt": Pix.from_rows(BOLT_ICON, ICON_LEGEND, ICON_SIZE),
		&"icon_charm": Pix.from_rows(CHARM_ICON, ICON_LEGEND, ICON_SIZE),
	}


## Amber pressure plate on the diamond: GOLD face, PALE_GOLD top-left /
## BRONZE bottom-right bevel, VOID stud holes. Sprung keeps the same plate
## and raises a tapered STEEL/PALE blade from every hole.
static func spike_plate(sprung: bool) -> Image:
	var img := Image.create(TRAP_SIZE.x, TRAP_SIZE.y, false, Image.FORMAT_RGBA8)
	var mask := Pix.iso_diamond_mask(PLATE_SIZE.x, PLATE_SIZE.y)
	for y: int in PLATE_SIZE.y:
		for x: int in PLATE_SIZE.x:
			if mask[y * PLATE_SIZE.x + x] == 0:
				continue
			var color := Palette.GOLD
			if not _in_mask(mask, PLATE_SIZE, x + 1, y) or not _in_mask(mask, PLATE_SIZE, x, y + 1):
				color = Palette.BRONZE
			elif not _in_mask(mask, PLATE_SIZE, x - 1, y) or not _in_mask(mask, PLATE_SIZE, x, y - 1):
				color = Palette.PALE_GOLD
			img.set_pixel(PLATE_AT.x + x, PLATE_AT.y + y, color)
	for stud: Vector2i in SPIKE_STUDS:
		for dx: int in 2:
			img.set_pixel(stud.x + dx, stud.y, Palette.VOID)
		if sprung:
			img.set_pixel(stud.x, stud.y - 1, Palette.STEEL)
			img.set_pixel(stud.x, stud.y - 2, Palette.STEEL)
			img.set_pixel(stud.x, stud.y - 3, Palette.PALE)
			img.set_pixel(stud.x + 1, stud.y - 1, Palette.STEEL)
			img.set_pixel(stud.x + 1, stud.y - 2, Palette.PALE)
	return _clip(Pix.outline(img))


## Viscous tar pool: VOID body, INK rim, fixed INK spurs for the irregular
## edge, subtle PLUM sheen dashes.
static func tar() -> Image:
	var img := Image.create(TRAP_SIZE.x, TRAP_SIZE.y, false, Image.FORMAT_RGBA8)
	var mask := Pix.iso_diamond_mask(POOL_SIZE.x, POOL_SIZE.y)
	for y: int in POOL_SIZE.y:
		for x: int in POOL_SIZE.x:
			if mask[y * POOL_SIZE.x + x] == 0:
				continue
			var rim := (
				not _in_mask(mask, POOL_SIZE, x + 1, y)
				or not _in_mask(mask, POOL_SIZE, x - 1, y)
				or not _in_mask(mask, POOL_SIZE, x, y + 1)
				or not _in_mask(mask, POOL_SIZE, x, y - 1)
			)
			img.set_pixel(POOL_AT.x + x, POOL_AT.y + y, Palette.INK if rim else Palette.VOID)
	for dash: Vector3i in TAR_SHEEN:
		for i: int in dash.z:
			img.set_pixel(dash.x + i, dash.y, Palette.PLUM)
	for spur: Vector2i in TAR_SPURS:
		img.set_pixel(spur.x, spur.y, Palette.INK)
	return _clip(img)


static func _in_mask(mask: PackedByteArray, size: Vector2i, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= size.x or y >= size.y:
		return false
	return mask[y * size.x + x] == 1


## Clear anything outside the 2:1 diamond footprint — the P12.3 contract:
## a ground trap's canvas corners stay transparent.
static func _clip(img: Image) -> Image:
	var out := img.duplicate() as Image
	var mask := Pix.iso_diamond_mask(TRAP_SIZE.x, TRAP_SIZE.y)
	for y: int in TRAP_SIZE.y:
		for x: int in TRAP_SIZE.x:
			if mask[y * TRAP_SIZE.x + x] == 0:
				out.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
	return out
