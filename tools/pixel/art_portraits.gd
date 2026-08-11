extends RefCounted

## Portrait busts (Lane A): 32x32 hand-authored, upscaled x4 to the pinned
## 128x128. Character identity per the graphics proposal §5 sheets — four
## independent channels: hair silhouette (the strongest lever), signature
## accent (class family + iris color), class signifier on the shoulder,
## expression keyword (eyes + brows + mouth). Roster spread allocated across
## ten distinct archetypes so the cast never collapses to one face.
## Compositing order: base bust -> features (brows/eyes/nose/mouth) ->
## hair on top -> class signifier -> outline pass.

const Palette := preload("res://tools/pixel/palette.gd")
const Pix := preload("res://tools/pixel/pix.gd")

const SIZE := Vector2i(32, 32)
const UPSCALE := 4

# --- base bust (skin + coat), roles resolved per operator -------------------

const BASE: Array[String] = [
	"",
	"",
	"..........SSSSSSSSSSSS",
	".........SSSSSSSSSSSSSS",
	".........SSSSSSSSSSSSSS",
	"........SSSSSSSSSSSSSSSs",
	"........SSSSSSSSSSSSSSSs",
	"........SSSSSSSSSSSSSSSs",
	"........SSSSSSSSSSSSSSts",
	"........SSSSSSSSSSSSSSts",
	"........SSSSSSSSSSSSSSts",
	"........SSSSSSSSSSSSSSts",
	"........SSSSSSSSSSSSSSts",
	"........sSSSSSSSSSSSSSts",
	".........SSSSSSSSSSSSts",
	".........sSSSSSSSSSSSt",
	"..........sSSSSSSSSSt",
	"...........sSSSSSSSt",
	"............tSSSSSt",
	".............tSSSt",
	".............sSSSs",
	".........b...sSSSs...b",
	"........bab..tsSst..bab",
	".......baaab.tsSst.baaab",
	"......baaaaaatsssttaaaaab",
	".....aaaaaaaaaba.baaaaaaaa",
	"....aaaaaaaaab.....baaaaaaa",
	"....aaaaaaaab..A....baaaaaa",
	"...aaaaaaaaab..AA....baaaaaa",
	"...aaaaaaaab...AA.....baaaaa",
	"..aaaaaaaaab..AA......baaaaaa",
	"..aaaaaaaaab..AA......baaaaaa",
	"..aaaaaaaab...AA.......baaaaa",
]

# --- eyes (5 wide, 4 tall; drawn at left-eye position, mirrored right) ------
# chars: o lash/pupil ink, W sclera white, I iris light, i iris dark

const EYES := {
	"open": ["ooooo", "WIioW", "WIioW", ".ooo."],
	"lidded": ["ooooo", "ooooo", "WIioW", ".ooo."],
	"soft": [".....", ".....", "ooooo", "o...o"],
	"sharp": [".oooo", "ooooo", "WIioW", ".ooo."],
	"stern": ["ooooo", "IIioW", "IIioW", ".ooo."],
	"closed": [".....", ".....", "ooooo", "....."],
}

# --- brows (5 wide, 2 tall; left side, mirrored unless asym) ----------------

const BROWS := {
	"flat": [".....", "ooooo"],
	"raised": ["ooooo", "....."],
	"angled": ["...oo", ".ooo."],
	"gentle": ["....o", ".oooo"],
}

# --- mouths (6 wide, 2 tall at x13,y15) --------------------------------------

const MOUTHS := {
	"smile": ["o....o", ".oooo."],
	"grin": [".oooo.", "oWWWWo", ".oooo."],
	"smirk": ["....oo", "..ooo."],
	"firm": ["......", "oooooo"],
	"soft": ["......", "..ooo."],
	"frown": [".oooo.", "o....o"],
}

# --- hair maps (H light, h dark, G shine), composited over everything -------

const HAIR := {
	# copper practical crop + headband (stoic veteran)
	&"vanguard_1":
	[
		"",
		"..........hHHHHHHHhh",
		".........HHHHHHHHHHhh",
		"........HHHGGHHHHHHhhh",
		"........HHHHHHHHHHHhhh",
		"........aaaaaaaaaaaaaa",
		"........AAAAAAAAAAAAaa",
		"........hh..........hh",
	],
	# blond high ponytail, side sweep (bright rookie)
	&"vanguard_2":
	[
		"...............HHHH",
		"..........hHHHHHHHHHh",
		".........HHHHGGHHHHHHh.HHh",
		"........HHHHHHHHHHHHHh.HHh",
		"........HHHHHHHHHHHHhh..HHh",
		"........HHhhHHHHHHhhh...hHh",
		"........Hh..hhhhhh.......HHh",
		"........hh...............hHh",
		"..........................hh",
	],
	# wild white spikes (cocky swordsman)
	&"guard_1":
	[
		"........H....HH....H",
		".......HHH..HHHH..HHH",
		"......HHHHHHHHHHHHHHhh",
		"........HHHHHHHHHHhhh",
		".......HHHHHHHHHHHHhh",
		"........HHhhHHHHhhhh",
		"........Hh..hhhh..hh",
		"........h",
	],
	# long dark curtain + straight fringe (elegant duelist)
	&"guard_2":
	[
		"",
		"..........hHHHHHHHhh",
		".........HHHHHHHHHHHh",
		"........HHHHGGHHHHHHHh",
		"........HHHHHHHHHHHHHhh",
		"........HHHhhhhhhhHHHhh",
		"........HHh.......hHHhh",
		"........HHh.......hHHhh",
		"........HHh.......hHHhh",
		"........HHh.......hHhhh",
		"........HHh.......hHhhh",
		"........HHh.......hhhhh",
		"........Hhh.......hhhh",
		"........Hhh.......hhhh",
		"........hhh.......hhh",
		"........hh.........hh",
	],
	# steel buzz + full beard (gentle giant)
	&"defender_1":
	[
		"",
		"..........hHHHHHHhh",
		".........HHHHHHHHHHh",
		"........hHHHHHHHHHHhh",
		"........hhHHHHHHHHhhh",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		".........HH.......HH",
		".........HHh.....hHH",
		"..........HHhhhhhHH",
		"...........HHHHHHH",
		"............HHHHH",
	],
	# gold braid crown + side swoop (proud knight)
	&"defender_2":
	[
		"",
		"..........HHHHHHHH",
		".........HGGHHHHGGHh",
		"........HHHHHHHHHHHHh",
		"........hHHhhhhhhHHhh",
		"........hHh......hHHhh",
		"........hh........hHHh",
		"...................hHh",
		"....................hh",
	],
	# dark slick-back + low tail (cool marksman)
	&"sniper_1":
	[
		"",
		"..........hHHHHHHhh",
		".........HHHHHHHHHHh",
		"........hHHHHHHHHHHhh",
		"........hhHHHHHHHHhhh",
		"........hh..........hh",
		".....................hh",
		".....................hh",
		"....................hh",
	],
	# white long + hawk fringe over one eye (sharp hawk-eye)
	&"sniper_2":
	[
		"",
		"..........hHHHHHHHhh",
		".........HHHHHHHHHHHh",
		"........HHHHHHGGHHHHHh",
		"........HHHHHHHHHHHHHh",
		"........HHhhHHHHHHHHHh",
		"........Hh..hHHHHHhhhh",
		"........hh...hHHHh..hh",
		"..............hHHh",
		"...............hHh",
		"...............hhh",
		"................hh",
	],
	# coral big wavy masses + ahoge (warm ember witch)
	&"caster_1":
	[
		"...............HH",
		"..............H",
		"..........hHHHHHHHhh",
		".........HHHHHHHHHHHh",
		"........HHHGGHHHHHHHHh",
		"......hHHHHHHHHHHHHHHHh",
		"......HHHhhHHHHHHhhHHHHh",
		"......HHh..hhhhhh..hHHHh",
		"......HHh...........hHHh",
		"......hHHh..........HHhh",
		".......hHHh........hHHh",
		"........hhHH......HHhh",
		"..........hh......hh",
	],
	# cyan short asymmetric undercut (aloof storm sage)
	&"caster_2":
	[
		"",
		"..........hHHHHHHHh",
		".........HHHHHHHHHHh",
		"........HHHHHHGGHHHHh",
		"........hhHHHHHHHHHHh",
		"..........hhhHHHHHHhh",
		"..............hhHHh",
		"................hhh",
	],
}

# --- class signifiers, 8x8, stamped on the left shoulder --------------------

const SIGNIFIERS := {
	OperatorDef.OpClass.VANGUARD:
	["..g.....", "..gAAA..", "..gAA...", "..gA....", "..g.....", "..g.....", "..g.....", ""],
	OperatorDef.OpClass.GUARD:
	["......W.", ".....W..", "....W...", ".G.W....", "..GW....", "..WG....", ".W..G...", ""],
	OperatorDef.OpClass.DEFENDER:
	[".MMMMMM.", ".MwwwwM.", ".MwAAwM.", ".MwAAwM.", ".MwwwwM.", "..MwwM..", "...MM...", ""],
	OperatorDef.OpClass.SNIPER:
	["...oo...", ".o.oo.o.", "..o..o..", "oo.WW.oo", "oo.WW.oo", "..o..o..", ".o.oo.o.", "...oo..."],
	OperatorDef.OpClass.CASTER:
	["...ww...", "..wCCw..", ".wCCCCw.", ".wCCCCw.", "..wCCw..", "...ww...", ".w....w.", ""],
}

## Per-operator identity sheets: expression keyword -> feature picks.
## blush (v2 fidelity pass) warms the younger/softer archetypes.
const SHEETS := {
	&"vanguard_1": {"eyes": "lidded", "brows": "flat", "mouth": "firm"},
	&"vanguard_2": {"eyes": "open", "brows": "raised", "mouth": "grin", "blush": true},
	&"guard_1": {"eyes": "sharp", "brows": "raised", "mouth": "smirk"},
	&"guard_2": {"eyes": "soft", "brows": "gentle", "mouth": "smile", "blush": true},
	&"defender_1": {"eyes": "soft", "brows": "gentle", "mouth": "soft"},
	&"defender_2": {"eyes": "stern", "brows": "angled", "mouth": "firm"},
	&"sniper_1": {"eyes": "lidded", "brows": "flat", "mouth": "soft"},
	&"sniper_2": {"eyes": "sharp", "brows": "angled", "mouth": "frown"},
	&"caster_1": {"eyes": "open", "brows": "raised", "mouth": "smile", "blush": true},
	&"caster_2": {"eyes": "lidded", "brows": "flat", "mouth": "firm"},
}

const GLINT_EYES: Array[String] = ["open", "sharp", "stern"]
const LEFT_CHEEK_AT := Vector2i(9, 13)
const RIGHT_CHEEK_AT := Vector2i(20, 13)

const LEFT_EYE_AT := Vector2i(9, 9)
const RIGHT_EYE_AT := Vector2i(17, 9)
const LEFT_BROW_AT := Vector2i(9, 8)
const RIGHT_BROW_AT := Vector2i(18, 8)
const NOSE_AT := Vector2i(15, 13)
const MOUTH_AT := Vector2i(13, 15)
const SIGNIFIER_AT := Vector2i(3, 24)


static func build(op_id: StringName, op_class: OperatorDef.OpClass, sheet: Dictionary) -> Image:
	var family: Array = Palette.CLASS_FAMILIES[op_class]
	var skin: Color = sheet["skin"]
	var skin_shadow: Color = sheet["skin_shadow"]
	var base_legend := {
		"S": skin,
		"s": skin_shadow,
		"t": Palette.SKIN_SHADOW if skin_shadow != Palette.SKIN_SHADOW else Palette.UMBER,
		"a": family[1],
		"A": family[2],
		"b": family[0],
	}
	var img := Pix.from_rows(BASE, base_legend, SIZE)
	var picks: Dictionary = SHEETS[op_id]
	var feature_legend := {
		"o": Palette.VOID,
		# probe reservation (P14.2): eye whites/glints use PALE — exact
		# WHITE is the sprung-flash probe color, banned from portraits
		"W": Palette.PALE,
		"I": family[2],
		"i": family[1],
	}
	var brow: Array = BROWS[picks["brows"]]
	var eye: Array = EYES[picks["eyes"]]
	var mouth: Array = MOUTHS[picks["mouth"]]
	_stamp(img, _typed(brow), feature_legend, LEFT_BROW_AT)
	_stamp_mirrored(img, _typed(brow), feature_legend, RIGHT_BROW_AT, 5)
	_stamp(img, _typed(eye), feature_legend, LEFT_EYE_AT)
	_stamp_mirrored(img, _typed(eye), feature_legend, RIGHT_EYE_AT, 5)
	img.set_pixel(NOSE_AT.x, NOSE_AT.y, skin_shadow)
	img.set_pixel(NOSE_AT.x, NOSE_AT.y + 1, skin_shadow)
	_stamp(img, _typed(mouth), feature_legend, MOUTH_AT)
	var hair_legend := {
		"H": sheet["hair_light"],
		"h": sheet["hair_dark"],
		"G": Palette.PALE,
		"a": family[1],
		"A": family[2],
	}
	_stamp(img, _typed(HAIR[op_id]), hair_legend, Vector2i.ZERO)
	var sig_legend := {
		"o": Palette.VOID,
		"W": Palette.PALE,
		"w": Palette.PALE,
		"M": Palette.STEEL,
		"G": Palette.GOLD,
		"g": Palette.BRONZE,
		"A": family[2],
		"C": family[2],
	}
	_stamp(img, _typed(SIGNIFIERS[op_class]), sig_legend, SIGNIFIER_AT)
	# v2 fidelity pass: eye glint (life), optional blush (warmth), and the
	# bust composed onto a class-colored card so it never floats on UI gray
	if GLINT_EYES.has(String(picks["eyes"])):
		img.set_pixel(LEFT_EYE_AT.x + 1, LEFT_EYE_AT.y + 1, Palette.PALE)
		img.set_pixel(RIGHT_EYE_AT.x + 1, RIGHT_EYE_AT.y + 1, Palette.PALE)
	if picks.get("blush", false):
		for at: Vector2i in [LEFT_CHEEK_AT, RIGHT_CHEEK_AT]:
			img.set_pixel(at.x, at.y, Palette.ROSE)
			img.set_pixel(at.x + 1, at.y, Palette.ROSE)
	var card := _card(family)
	Pix.blend(card, Pix.outline(img), Vector2i.ZERO)
	return Pix.upscale(card, UPSCALE)


## Class-colored roster card: dusk field, family diagonal pinstripe, ink
## footer band, hairline frame — quiet enough to keep the face the subject.
static func _card(family: Array) -> Image:
	var img := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var c: Color = Palette.DUSK
			if (x + y) % 8 < 2:
				c = family[0]
			if y >= 28:
				c = Palette.INK
			img.set_pixel(x, y, c)
	for x: int in SIZE.x:
		img.set_pixel(x, 0, Palette.INK)
		img.set_pixel(x, SIZE.y - 1, Palette.VOID)
	for y: int in SIZE.y:
		img.set_pixel(0, y, Palette.INK)
		img.set_pixel(SIZE.x - 1, y, Palette.INK)
	return img


static func _typed(rows: Array) -> Array[String]:
	var out: Array[String] = []
	for row: Variant in rows:
		out.append(String(row))
	return out


static func _stamp(img: Image, rows: Array[String], legend: Dictionary, at: Vector2i) -> void:
	var patch := Pix.from_rows(rows, legend)
	Pix.blend(img, patch, at)


static func _stamp_mirrored(
	img: Image, rows: Array[String], legend: Dictionary, at: Vector2i, width: int
) -> void:
	var patch := Pix.from_rows(rows, legend, Vector2i(width, rows.size()))
	Pix.blend(img, Pix.mirror_x(patch), at)
