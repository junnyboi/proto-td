extends RefCounted

## TD32 — the fixed 32-color battle palette (Lane A). Sweetie-16 core (the
## colors every existing UI/juice constant already uses, so the art and the
## chrome read as one game) extended with hue-shifted ramp steps: shadows
## drift cooler, highlights warmer — straight-value ramps are the signature
## of programmer art (graphics proposal §4 L7). Deviation from the parent
## plan's DB32 pin is numbered in the Lane A commit report.

# --- Sweetie-16 core -------------------------------------------------------
const INK := Color("1a1c2c")
const PLUM := Color("5d275d")
const CRIMSON := Color("b13e53")
const CORAL := Color("ef7d57")
const GOLD := Color("ffcd75")
const LIME := Color("a7f070")
const GREEN := Color("38b764")
const TEAL := Color("257179")
const NAVY := Color("29366f")
const BLUE := Color("3b5dc9")
const SKY := Color("41a6f6")  # == battle_view/juice CHARMED_COLOR — probed
const CYAN := Color("73eff7")
const WHITE := Color("f4f4f4")
const STEEL := Color("94b0c2")
const SLATE := Color("566c86")
const DUSK := Color("333c57")

# --- ramp extensions (16) --------------------------------------------------
const VOID := Color("0f0f1b")  # outline ink, deepest shadow
const PALE := Color("c7d6e8")  # steel highlight
const GRAY := Color("6e7a94")  # mid gray-blue
const DEEP_GREEN := Color("1a5f43")
const WINE := Color("7a2436")
const PALE_GOLD := Color("ffe9b0")
const BRONZE := Color("a3702b")
const BROWN := Color("6b4a34")
const UMBER := Color("3a2a24")
const SKIN_SHADOW := Color("8a4836")
const SKIN := Color("c77b58")
const SKIN_LIGHT := Color("e8b796")
const SKIN_PALE := Color("f6dcbf")
const ORCHID := Color("c964cf")
const MAGENTA := Color("94216a")
const ROSE := Color("e39aac")

const ALL: Array[Color] = [
	INK, PLUM, CRIMSON, CORAL, GOLD, LIME, GREEN, TEAL,
	NAVY, BLUE, SKY, CYAN, WHITE, STEEL, SLATE, DUSK,
	VOID, PALE, GRAY, DEEP_GREEN, WINE, PALE_GOLD, BRONZE, BROWN,
	UMBER, SKIN_SHADOW, SKIN, SKIN_LIGHT, SKIN_PALE, ORCHID, MAGENTA, ROSE,
]

## Class color grammar (graphics proposal §4 L8): one DB-subset family per
## class; every operator accent and future skill VFX inherits its family.
## Order: [dark, base, light].
const CLASS_FAMILIES := {
	OperatorDef.OpClass.VANGUARD: [DEEP_GREEN, GREEN, LIME],
	OperatorDef.OpClass.GUARD: [WINE, CRIMSON, CORAL],
	OperatorDef.OpClass.DEFENDER: [NAVY, TEAL, CYAN],
	OperatorDef.OpClass.SNIPER: [BRONZE, GOLD, PALE_GOLD],
	OperatorDef.OpClass.CASTER: [PLUM, ORCHID, ROSE],
}

## Charmed derivation targets (parent §6.2): ally-blue ramp by luminance
## bucket, mid bucket == the probed CHARMED_COLOR.
const CHARM_RAMP: Array[Color] = [NAVY, BLUE, SKY, CYAN]
const CHARM_OUTLINE := CYAN
const CHARM_HEART := ROSE


static func nearest_charm(color: Color) -> Color:
	var lum := color.get_luminance()
	if lum < 0.18:
		return CHARM_RAMP[0]
	if lum < 0.38:
		return CHARM_RAMP[1]
	if lum < 0.62:
		return CHARM_RAMP[2]
	return CHARM_RAMP[3]
