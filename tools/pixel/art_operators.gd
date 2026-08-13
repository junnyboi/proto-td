extends RefCounted

## Hand-authored operator battle sprites (Lane A). One 32x32 idle + attack
## drawing per class; the generator derives idle bob, attack recoil, and the
## deploy crouch, recolors per operator (accent family + hair), and applies
## the outline pass. Role chars, shared across every drawing:
##   .  transparent          o  ink line (VOID)
##   S/s skin light/shadow   H/h hair light/shadow
##   A/a/b accent light/mid/dark (class family, per-operator)
##   M/m/n armor light/mid/dark (steel)
##   W/w blade/white light/soft
##   G  gold trim            E  eye ink
## Light source: top-left. 2-tone shading, big readable masses.

const Palette := preload("res://tools/pixel/palette.gd")
const Pix := preload("res://tools/pixel/pix.gd")

const SIZE := Vector2i(32, 32)
const HEAD_BAND := 13  # crouch squash keeps rows above this

# --- GUARD: sword duelist, blade raised at the viewer's right --------------

const GUARD_IDLE: Array[String] = [
	"",
	"",
	"",
	"",
	"..........H...H",
	".........HHH.HHH.hh......Ww",
	".........HHHHHHHHHhh.....Ww",
	"........HHHHHHHHHHhhh....Ww",
	"........HhSSHHSSSShhh....Ww",
	"........hSSSSSSSSSSh.....Ww",
	"........hSEESSSEESSh.....Ww",
	"........hSSSSsSSSSSh.....Ww",
	".........SSSsSSSSSs......Ww",
	".........SSssssSSs.......Ww",
	"..........SSSSSSs........Ww",
	"........nnSSSSSSnn..MMm..Ww",
	".......MMnnnnnnnnMM.Mmm..Ww",
	"......MMmaaAAAAaamm..mmGGGGGG",
	"......Mmm.aAAAAa.mm.....SSSS",
	"......mm..aAAAAa..m.....SSSs",
	"......mm..aaAAaa..m......gg",
	"......SS..nGGGGn",
	"..........abbbba",
	"..........aaaaba",
	"..........baaab",
	".........nnn.nnn",
	".........nn...nn",
	".........mm...mm",
	".........Mm...Mm",
	"........MMm...MMm",
	"........nnn...nnn",
	"",
]

const GUARD_ATTACK: Array[String] = [
	"",
	"",
	"",
	"",
	"...........H...H",
	"..........HHH.HHH.hh",
	"..........HHHHHHHHHhh",
	".........HHHHHHHHHHhhh",
	".........HhSSHHSSSShhh",
	".........hSSSSSSSSSSh",
	".........hSEESSSEESSh",
	".........hSSSSsSSSSSh",
	"..........SSSsSSSSSs",
	"..........SSssssSSs....G",
	"...........SSSSSSs.mm..GWWWWWWW",
	".........nnSSSSSSnnMmmSSggwwwww",
	"........MMnnnnnnnnMM.mSSgg",
	".......MMmaaAAAAaamm...SSS.",
	".......Mmm.aAAAAa.mm",
	".......mm..aAAAAa..m",
	".......mm..aaAAaa..m",
	".......SS..nGGGGn",
	"...........abbbba",
	"...........aaaaba",
	"..........baaaab",
	".........nnn..nnn",
	".........nn....nn",
	".........mm....mm",
	".........Mm....Mm",
	"........MMm....MMm",
	"........nnn....nnn",
	"",
]

# --- VANGUARD: spear + banner pennant, light leather armor ------------------

const VANGUARD_IDLE: Array[String] = [
	"",
	"",
	"",
	".........................M",
	"..........H...H..........MAAAAA",
	".........HHH.HHH.hh......gAAA",
	".........HHHHHHHHHhh.....gA",
	"........HHHHHHHHHHhhh....g",
	"........HaAAAAAAAAAah....g",
	"........hSSSSSSSSSSh.....g",
	"........hSEESSSEESSh.....g",
	"........hSSSSsSSSSSh.....g",
	".........SSSsSSSSSs......g",
	".........SSssssSSs.......g",
	"..........SSSSSSs........g",
	"........LLSSSSSSLL..MMm..g",
	".......MLLllllllLLM.MmmSSS",
	"......MLlaaAAaallLm...SSsg",
	"......Ll..aAAAAa..l......g",
	"......ll..aaAAaa..l......g",
	"......SS..nGGGGn.........g",
	"..........abbbba.........g",
	"..........aaaaba",
	"..........baaab",
	"..........bnnnb",
	".........nnn.nnn",
	".........nn...nn",
	".........ll...ll",
	".........Ll...Ll",
	"........LLl...LLl",
	"........nnn...nnn",
	"",
]

const VANGUARD_ATTACK: Array[String] = [
	"",
	"",
	"",
	"",
	"...........H...H",
	"..........HHH.HHH.hh",
	"..........HHHHHHHHHhh",
	".........HHHHHHHHHHhhh",
	".........HaAAAAAAAAAah",
	".........hSSSSSSSSSSh",
	".........hSEESSSEESSh",
	".........hSSSSsSSSSSh",
	"..........SSSsSSSSSs",
	"..........SSssssSSs",
	"...........SSSSSSs.mm.....AA",
	".........LLSSSSSSLLMmmSSggggggMM",
	"........MLLllllllLLM.SSgg....MM",
	".......MLlaaAAaallLm...SSS",
	".......Ll..aAAAAa..l",
	".......ll..aaAAaa..l",
	".......SS..nGGGGn",
	"...........abbbba",
	"...........aaaaba",
	"..........baaaab",
	"..........bnnnnb",
	".........nnn..nnn",
	".........nn....nn",
	".........ll....ll",
	".........Ll....Ll",
	"........LLl....LLl",
	"........nnn....nnn",
	"",
]

# --- DEFENDER: tower shield + heavy helm, mace at the ready -----------------

const DEFENDER_IDLE: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"..............HHH",
	".............HHHHH",
	"...........MMMMMMMMM",
	"..........MMMMMMMMMMM",
	"..........MmmmmmmmmmM",
	"..........mEEmmmmEEm.",
	"..........mmmmmmmmmm.",
	"..........nmmmmmmmn",
	"...........nSSSSSs",
	"....nnnnnnnnmmmmmmn",
	"...nMMMMMMnnmmmmmmmn",
	"...nMmmmmmnnmmmmmmmn.mm",
	"...nMmaAAmnnmmmmmmmnnmm",
	"...nMmAAAAmnnmmmmmnn.nn",
	"...nMmAAAAmnnmmmmmnn.SS",
	"...nMmaAAmnnmmmmmmnn.nMn",
	"...nMmmmmmnn.mmmmmn..nnn",
	"...nMmmmmmnn.nnnnnn..nn",
	"...nMmmmmmnn.nn.nnn",
	"...nMmmmmmnn.nn..nn",
	"...nMmmmmmnn.mm..mm",
	"...nMmmmmmnn.Mm..Mm",
	"...nmmmmmmnnMMm..MMm",
	"...nnnnnnnnnnnn..nnn",
	"",
]

const DEFENDER_ATTACK: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"..............HHH",
	".............HHHHH",
	"...........MMMMMMMMM",
	"..........MMMMMMMMMMM",
	"..........MmmmmmmmmmM",
	"..........mEEmmmmEEm...nMMn",
	"..........mmmmmmmmmm...nMMn",
	"..........nmmmmmmmn.....nn",
	"...........nSSSSSs......SS",
	"....nnnnnnnnmmmmmmn.....SS",
	"...nMMMMMMnnmmmmmmmn...mm",
	"...nMmmmmmnnmmmmmmmn..mm",
	"...nMmaAAmnnmmmmmmmnnmm",
	"...nMmAAAAmnnmmmmmnn",
	"...nMmAAAAmnnmmmmmnn",
	"...nMmaAAmnnmmmmmmnn",
	"...nMmmmmmnn.mmmmmn",
	"...nMmmmmmnn.nnnnnn",
	"...nMmmmmmnn.nn.nnn",
	"...nMmmmmmnn.nn..nn",
	"...nMmmmmmnn.mm..mm",
	"...nMmmmmmnn.Mm..Mm",
	"...nmmmmmmnnMMm..MMm",
	"...nnnnnnnnnnnn..nnn",
	"",
]

# --- SNIPER: cap + scarf, long rifle ----------------------------------------

const SNIPER_IDLE: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"..........aaaaaaaa",
	".........aaAAAAAAaa",
	"........aaaaaaaaaaaa.hh",
	"........hSSSSSSSSSShhhh",
	"........hSEESSSEESShhh",
	"........hSSSSsSSSSShh",
	".........SSSsSSSSSs",
	".........SSssssSSs",
	"..........SSSSSSs",
	"........aaSSSSSSaa",
	".......aaaaaaaaaaaa",
	"......Laallllllllaal",
	"......Lll.llllll.llL",
	"......ll..llllll..ll",
	"......SS..llllll..SS",
	"....llnnnnnnnnnnnnnnMMMMMMMMMM",
	"...lllnnnnnnnnnnnnnn",
	"....ll....llll",
	"..........llll",
	".........lll.lll",
	".........ll...ll",
	".........ll...ll",
	".........Ll...Ll",
	"........LLl...LLl",
	"........nnn...nnn",
	"",
]

const SNIPER_ATTACK: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"..........aaaaaaaa",
	".........aaAAAAAAaa",
	"........aaaaaaaaaaaa.hh",
	"........hSSSSSSSSSShhhh",
	"........hSEESSSEESShhh",
	"........hSSSSsSSSSShh...........",
	".....llnnSSSsSSSSSnnnnnnnMMMMMWW",
	".....lllnnnnnnnnnnnnnnnnn....WWW",
	"......SSa.SSSSSSs.SS.........WW",
	"........aaSSSSSSaa",
	".......aaaaaaaaaaaa",
	"......Laallllllllaal",
	"......Lll.llllll.llL",
	"......ll..llllll..ll",
	"..........llllll",
	"..........llllll",
	"..........llll",
	"..........llll",
	".........lll.lll",
	".........ll...ll",
	".........ll...ll",
	".........Ll...Ll",
	"........LLl...LLl",
	"........nnn...nnn",
	"",
]

# --- CASTER: pointed hat, robe, staff with orb -------------------------------

const CASTER_IDLE: Array[String] = [
	"",
	"",
	"",
	"",
	"..............aa.......CC",
	".............aaaa.....COOC",
	"............aaAaaa....COOC",
	"...........aaAAaaaa....CC",
	".........aaaaAAaaaaaa..gg",
	"......aaaaaaaaaaaaaaaaaagg",
	".......hhHSSSSSSSSHhh..gg",
	".......hhSEESSSEESShh..gg",
	"........hSSSSsSSSSSh...gg",
	".........SSSsSSSSSs....gg",
	".........SSssssSSs.....gg",
	"..........SSSSSSs......gg",
	"........aaSSSSSSaa..aaSSS",
	".......aaaaaaaaaaaa.aaSSs",
	"......aaabaaaaaabaaaaa.gg",
	"......aab.aaaaaa.baa...gg",
	"......ab..aaaaaa..ba...gg",
	"......SS..aaaaaa..SS...gg",
	"..........aaaaaa.......gg",
	".........baaaaaab......gg",
	".........baaaaaab",
	"........bbaaaaaabb",
	"........baaaaaaaab",
	"........baaWaaWaab",
	".......bbaWaaaaWabb",
	".......bbbbbbbbbbbb",
	".........nn....nn",
	"",
]

const CASTER_ATTACK: Array[String] = [
	"",
	"",
	".......................WCCW",
	"......................CCCCCC",
	".............aa......CCOOOOCC",
	"............aaaa.....COOOOOOC",
	"...........aaAaaa....COOOOOOC",
	"..........aaAAaaaa...CCOOOOCC",
	".........aaaaAAaaaaaa.CCCCCC",
	"......aaaaaaaaaaaaaaaa.WggW",
	"......hhHSSSSSSSSHhh...gg",
	"......hhSEESSSEESShh...gg",
	".......hSSSSsSSSSSh....gg",
	"........SSSsSSSSSs.....gg",
	"........SSssssSSs......gg",
	".........SSSSSSs.......gg",
	".......aaSSSSSSaa...aaSSS",
	"......aaaaaaaaaaaa..aaSSs",
	".....aaabaaaaaabaaaaaa.gg",
	".....aab.aaaaaa.baa....gg",
	".....ab..aaaaaa..ba....gg",
	".....SS..aaaaaa..SS....gg",
	".........aaaaaa........gg",
	"........baaaaaab.......gg",
	"........baaaaaab",
	".......bbaaaaaabb",
	".......baaaaaaaab",
	".......baaWaaWaab",
	"......bbaWaaaaWabb",
	"......bbbbbbbbbbbb",
	"........nn....nn",
	"",
]

# --- shared per-class registry ---------------------------------------------

const CLASS_ART := {
	OperatorDef.OpClass.VANGUARD: {"idle": VANGUARD_IDLE, "attack": VANGUARD_ATTACK},
	OperatorDef.OpClass.GUARD: {"idle": GUARD_IDLE, "attack": GUARD_ATTACK},
	OperatorDef.OpClass.DEFENDER: {"idle": DEFENDER_IDLE, "attack": DEFENDER_ATTACK},
	OperatorDef.OpClass.SNIPER: {"idle": SNIPER_IDLE, "attack": SNIPER_ATTACK},
	OperatorDef.OpClass.CASTER: {"idle": CASTER_IDLE, "attack": CASTER_ATTACK},
	OperatorDef.OpClass.HEALER: {"idle": CASTER_IDLE, "attack": CASTER_ATTACK},
}

## Per-operator sheets (graphics proposal §5): hair pair + skin tone + accent
## override within the class family. Hair is the cheapest identity lever.
const OPERATOR_SHEETS := {
	&"vanguard_1":
	{
		"hair_light": Palette.BRONZE,
		"hair_dark": Palette.UMBER,
		"skin": Palette.SKIN,
		"skin_shadow": Palette.SKIN_SHADOW,
	},
	&"vanguard_2":
	{
		"hair_light": Palette.GOLD,
		"hair_dark": Palette.BRONZE,
		"skin": Palette.SKIN_LIGHT,
		"skin_shadow": Palette.SKIN,
	},
	&"guard_1":
	{
		"hair_light": Palette.PALE,
		"hair_dark": Palette.STEEL,
		"skin": Palette.SKIN_LIGHT,
		"skin_shadow": Palette.SKIN,
	},
	&"guard_2":
	{
		"hair_light": Palette.UMBER,
		"hair_dark": Palette.VOID,
		"skin": Palette.SKIN,
		"skin_shadow": Palette.SKIN_SHADOW,
	},
	&"defender_1":
	{
		"hair_light": Palette.STEEL,
		"hair_dark": Palette.SLATE,
		"skin": Palette.SKIN,
		"skin_shadow": Palette.SKIN_SHADOW,
	},
	&"defender_2":
	{
		"hair_light": Palette.GOLD,
		"hair_dark": Palette.BRONZE,
		"skin": Palette.SKIN_LIGHT,
		"skin_shadow": Palette.SKIN,
	},
	&"sniper_1":
	{
		"hair_light": Palette.UMBER,
		"hair_dark": Palette.VOID,
		"skin": Palette.SKIN,
		"skin_shadow": Palette.SKIN_SHADOW,
	},
	&"sniper_2":
	{
		"hair_light": Palette.PALE,
		"hair_dark": Palette.STEEL,
		"skin": Palette.SKIN_LIGHT,
		"skin_shadow": Palette.SKIN,
	},
	&"caster_1":
	{
		"hair_light": Palette.CORAL,
		"hair_dark": Palette.CRIMSON,
		"skin": Palette.SKIN_LIGHT,
		"skin_shadow": Palette.SKIN,
	},
	&"caster_2":
	{
		"hair_light": Palette.CYAN,
		"hair_dark": Palette.TEAL,
		"skin": Palette.SKIN,
		"skin_shadow": Palette.SKIN_SHADOW,
	},
	&"witch_doctor_1":
	{
		"hair_light": Palette.LIME,
		"hair_dark": Palette.DEEP_GREEN,
		"skin": Palette.SKIN_PALE,
		"skin_shadow": Palette.SKIN_LIGHT,
	},
}


static func legend_for(op_class: OperatorDef.OpClass, sheet: Dictionary) -> Dictionary:
	var family: Array = Palette.CLASS_FAMILIES[op_class]
	return {
		"o": Palette.VOID,
		"E": Palette.VOID,
		"S": sheet["skin"],
		"s": sheet["skin_shadow"],
		"H": sheet["hair_light"],
		"h": sheet["hair_dark"],
		"A": family[2],
		"a": family[1],
		"b": family[0],
		"M": Palette.PALE,
		"m": Palette.STEEL,
		"n": Palette.DUSK,
		# probe reservation (P14.2): glints use PALE — exact WHITE is the
		# sprung-flash probe color, banned from every sprite class
		"W": Palette.PALE,
		"w": Palette.PALE,
		"G": Palette.GOLD,
		"g": Palette.BRONZE,
		"L": Palette.BROWN,
		"l": Palette.UMBER,
		"C": family[2] if op_class == OperatorDef.OpClass.HEALER else Palette.CYAN,
		"O": family[1] if op_class == OperatorDef.OpClass.HEALER else Palette.ORCHID,
	}


## Frames per operator: [idle_a, idle_b, attack_a, attack_b, crouch].
static func build(op_id: StringName, op_class: OperatorDef.OpClass) -> Array[Image]:
	var art: Dictionary = CLASS_ART[op_class]
	var sheet: Dictionary = OPERATOR_SHEETS[op_id]
	var legend := legend_for(op_class, sheet)
	var idle := Pix.outline(Pix.from_rows(art["idle"], legend, SIZE))
	var attack := Pix.outline(Pix.from_rows(art["attack"], legend, SIZE))
	return [
		idle,
		Pix.shifted(idle, Vector2i(0, 1)),
		attack,
		Pix.shifted(attack, Vector2i(1, 0)),
		Pix.crouch(idle, 3, HEAD_BAND),
	]
