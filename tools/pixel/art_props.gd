extends RefCounted

## Traps + spell-bar icons (Lane A). Trap sprites are cell glyphs rendered
## over the tile (armed spike plate / sprung frame / tar pit blob); icons
## are 24x24 chips for the spell bar. The sprung flash overlay itself stays
## the juice layer's (P9) — these are the persistent looks.

const Palette := preload("res://tools/pixel/palette.gd")
const Pix := preload("res://tools/pixel/pix.gd")

const TRAP_SIZE := Vector2i(32, 32)
const ICON_SIZE := Vector2i(24, 24)

# amber pressure plate, four armed spike studs
const SPIKE_ARMED: Array[String] = [
	"",
	"",
	"",
	"",
	"....nnnnnnnnnnnnnnnnnnnn",
	"...nGGGGGGGGGGGGGGGGGGGGn",
	"...nGgggggggggggggggggggn",
	"...nGg.WW.....WW......ggn",
	"...nGg.ww.....ww......ggn",
	"...nGgmmmm...mmmm...gggn",
	"...nGgnnnn...nnnn...gggn",
	"...nGgg..............ggn",
	"...nGgg..WW.....WW...ggn",
	"...nGgg..ww.....ww...ggn",
	"...nGg..mmmm...mmmm..ggn",
	"...nGg..nnnn...nnnn..ggn",
	"...nGgggggggggggggggggggn",
	"...nGgggggggggggggggggggn",
	"....nnnnnnnnnnnnnnnnnnnn",
	"",
	"",
]

# sprung: blades out, plate darkened
const SPIKE_SPRUNG: Array[String] = [
	"",
	"......W......W......W",
	"......W......W......W",
	"......WW.....WW.....WW",
	"....nnWWnnnnnWWnnnnnWWnn",
	"...ngwWWwgggwWWwgggwWWwgn",
	"...ngwWWwgggwWWwgggwWWwgn",
	"...ngwwwwgggwwwwgggwwwwgn",
	"...ngggggggggggggggggggn",
	"...ngg.WW.....WW......ggn",
	"...ngg.WW.....WW......ggn",
	"...ngg.ww.....ww......ggn",
	"...nggmmmm...mmmm....ggn",
	"...ngggggggggggggggggggn",
	"...ngggggggggggggggggggn",
	"...ngggggggggggggggggggn",
	"...ngggggggggggggggggggn",
	"...ngggggggggggggggggggn",
	"....nnnnnnnnnnnnnnnnnnnn",
	"",
	"",
]

const SPIKE_LEGEND := {
	"G": Palette.GOLD,
	"g": Palette.BRONZE,
	"W": Palette.WHITE,
	"w": Palette.PALE,
	"m": Palette.STEEL,
	"n": Palette.VOID,
}

# viscous tar blob, irregular edge, plum sheen
const TAR_PIT: Array[String] = [
	"",
	"......ttttttttttttt",
	"....tttTTTTTTTTTTTtttt",
	"...ttTTTTTTTTTTTTTTTttt",
	"..ttTTTTppTTTTTTTTTTTtt",
	"..tTTTTppppTTTTTTTTTTTtt",
	".ttTTTTppTTTTTTTTppTTTtt",
	".tTTTTTTTTTTTTTTppppTTTtt",
	".tTTTTTTTTTTTTTTTppTTTTtt",
	".tTTTTTTTTTTTTTTTTTTTTTtt",
	".tTTTTTTppTTTTTTTTTTTTTtt",
	".ttTTTTppppTTTTTTppTTTTtt",
	".ttTTTTTppTTTTTTppppTTTtt",
	"..tTTTTTTTTTTTTTTppTTTtt",
	"..ttTTTTTTTTTTTTTTTTTttt",
	"...ttTTTTTTTTTTTTTTTttt",
	"....tttTTTTTTTTTTTtttt",
	"......ttttttttttttt",
	"",
	"",
]

const TAR_LEGEND := {
	"T": Palette.VOID,
	"t": Palette.INK,
	"p": Palette.PLUM,
}

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
		&"trap_spike_armed":
		Pix.outline(Pix.from_rows(SPIKE_ARMED, SPIKE_LEGEND, TRAP_SIZE)),
		&"trap_spike_sprung":
		Pix.outline(Pix.from_rows(SPIKE_SPRUNG, SPIKE_LEGEND, TRAP_SIZE)),
		&"trap_tar": Pix.from_rows(TAR_PIT, TAR_LEGEND, TRAP_SIZE),
		&"icon_bolt": Pix.from_rows(BOLT_ICON, ICON_LEGEND, ICON_SIZE),
		&"icon_charm": Pix.from_rows(CHARM_ICON, ICON_LEGEND, ICON_SIZE),
	}
