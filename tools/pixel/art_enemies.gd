extends RefCounted

## Hand-authored enemy battle sprites (Lane A). Silhouette-first: each type
## must be identifiable at 1x with color stripped (assets_floor checklist).
## Walk frame B is a bob derivation; charmed variants are always derived
## (pix.charmed_variant), never hand-made. Role chars per drawing legend.

const Palette := preload("res://tools/pixel/palette.gd")
const Pix := preload("res://tools/pixel/pix.gd")

const SIZE := Vector2i(32, 32)

# --- GRUNT: round hunched creeper, coral, stubby feet -----------------------
# B body, d body shadow, D deep shadow, W eye white, E pupil, T teeth,
# N horn, m maw

const GRUNT: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"........N........N",
	"........NN......NN",
	".........BBBBBBBB",
	".......BBBBBBBBBBBB",
	"......BBBBBBBBBBBBBB",
	".....BBBWWEBBBBWWEBBd",
	".....BBBWWEBBBBWWEBBd",
	".....BBBBBBBBBBBBBBdd",
	"....BBBBBBBBBBBBBBBdd",
	"....BBmmmmmmmmmmmmddd",
	"....BdmTmTmTmTmTmmddd",
	"....BdmmmmmmmmmmmmdDd",
	"....BddBBBBBBBBBdddDD",
	".....dddddddddddddDD",
	"......ddddddddddDDD",
	"......oooooooooooo",
	".....DDDD.....DDDD",
	".....DDDD.....DDDD",
	"",
]

const GRUNT_LEGEND := {
	"B": Palette.CORAL,
	"d": Palette.CRIMSON,
	"D": Palette.WINE,
	"W": Palette.PALE,
	"E": Palette.VOID,
	"T": Palette.PALE,
	"m": Palette.WINE,
	"o": Palette.VOID,
	"N": Palette.PALE_GOLD,
}

# --- RUNNER: lean imp mid-sprint, swept back, speed dashes ------------------

const RUNNER: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"..................NN",
	"...............NNBBBB",
	"..............BBBBBBBBB",
	".............BBBWWEBBBBd",
	"....ww.......BBBWWEBBBdd",
	"...www....dBBBBBBBBBBdd",
	"........ddBBBBBBBBBdd",
	"....ww.dddBBBBBBBdd",
	"...www..ddBBBBBBBd",
	".........dBBBBBBdd",
	".........dBBBdddd",
	"........ddBBBd",
	".......ddd.dBBd",
	"......ddd...dBBdd",
	".....ddd.....dBBdd",
	".....dd.......ddDDd",
	".....DDd.......DDDd",
	"......DD........DDD",
	"",
]

const RUNNER_LEGEND := {
	"B": Palette.GOLD,
	"d": Palette.BRONZE,
	"D": Palette.UMBER,
	"W": Palette.PALE,
	"E": Palette.VOID,
	"N": Palette.PALE_GOLD,
	"w": Palette.PALE,
}

# --- HEAVY: wide armored brute, steel banded shoulders ----------------------

const HEAVY: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"............nnnnnn",
	"...........nnmmmmnn",
	"...........nmEEmmEEmn",
	"...........nmEEmmEEmn",
	"...........nnmmmmmmnn",
	"......MMMMMMmmmmmmmmMMMMMM",
	"....MMMMMMMMMMMMMMMMMMMMMMMM",
	"...MMmmmmmmmMMMMMMMMmmmmmmmMM",
	"...MMMM.mmBBBBBBBBBBBBmm.MMMM",
	"...dddd.BBBBBBBBBBBBBBBB.dddd",
	"...dddd.BBdBBBBBBBBBBdBB.dddd",
	"...nddd.BBdBBBBBBBBBBdBB.dddn",
	"....nn..BddBBBBBBBBBBddB..nn",
	"........BBmmmmmmmmmmmmBB",
	"........ddnnGGnnnnGGnndd",
	"........dddddddddddddddd",
	".........dddddddddddddd",
	"..........ddd....ddd",
	"..........DDd....DDd",
	".........DDDd....DDDd",
	".........nnnn....nnnn",
	"",
]

const HEAVY_LEGEND := {
	"B": Palette.CRIMSON,
	"d": Palette.WINE,
	"D": Palette.VOID,
	"M": Palette.STEEL,
	"m": Palette.SLATE,
	"n": Palette.DUSK,
	"E": Palette.CORAL,
	"G": Palette.GOLD,
}

# --- DRONE: 24x24 aerial pod, rotor frames alternate X / + ------------------

const DRONE_A: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"..ww..............ww",
	"...ww............ww",
	"....ww..........ww",
	".....wwww....wwww",
	".......wwnnnnww",
	".........nttn",
	"........nttttn",
	".......nttCCttn",
	".......ntCWWCtn",
	".......ntCWWCtn",
	".......nttCCttn",
	"........nttttn",
	".........nttn",
	"..........nn",
	".........t..t",
	"........tt..tt",
	"",
]

const DRONE_B: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"..........ww",
	"..wwwwwwwnnnnwwwwwww",
	".........nttn",
	"........nttttn",
	".......nttCCttn",
	".......ntCWWCtn",
	".......ntCWWCtn",
	".......nttCCttn",
	"........nttttn",
	".........nttn",
	"..........nn",
	".........t..t",
	"........tt..tt",
	"",
]

const DRONE_LEGEND := {
	"C": Palette.CYAN,
	"t": Palette.TEAL,
	"n": Palette.DUSK,
	"W": Palette.PALE,
	"w": Palette.PALE,
}

# --- SPELLCASTER: hooded robe, glowing eyes, floating orb -------------------

const SPELLCASTER: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"..............O",
	".............OOO",
	"............OOOOO",
	"...........OOpppOO",
	"..........Op.....pO",
	"..........O.......O",
	"..........O.EE.EE.O.....WC",
	"..........Op......pO...CCCC",
	"..........OOp....pOO...CCCC",
	".........OOOOppppOOOO...WC",
	".........OpOOOOOOOOpO",
	".........OppOOOOOOppO",
	".........OpOOOOOOOOpO",
	"........OOpOOOOOOOOpOO",
	"........OpOOOOOOOOOOpO",
	"........OpOOOOOOOOOOpO",
	"........OppOOOOOOOOppO",
	".......OOpppOOOOOOpppOO",
	".......OppppppppppppppO",
	".......pppppppppppppppp",
	"",
]

const SPELLCASTER_LEGEND := {
	"O": Palette.ORCHID,
	"p": Palette.PLUM,
	"E": Palette.CYAN,
	"C": Palette.CYAN,
	"W": Palette.PALE,
}

# --- MINI-BOSS: 48x48 horned magenta juggernaut ------------------------------

const MINI_BOSS: Array[String] = [
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"........NN......................NN",
	".......NNNN....................NNNN",
	"......NNnNNN..................NNNnNN",
	"......NN..NNN................NNN..NN",
	".....NN....NNN..............NNN....NN",
	".....NN.....NNN....mmmm....NNN.....NN",
	"............NNN..mmmmmmmm..NNN",
	"............NNNmmmmmmmmmmmmNNN",
	"..............nmmEEmmmmEEmn",
	"..............nmmEEmmmmEEmn",
	"..............nmmmmmmmmmmn",
	"...............nmmmnnmmmn",
	"......MMMMMMMmmnnnnnnnnnnmmMMMMMMM",
	"....MMMMMMMMMMMMMnnnnnnMMMMMMMMMMMMM",
	"...MMMmmmmmmMMMMMMMMMMMMMMMMmmmmmmMMM",
	"...MMmmmmmmmmMMMMMMMMMMMMMMmmmmmmmmMM",
	"...Mmm......mmBBBBBBBBBBBBmm......mmM",
	"...Mmm.....mmBBBBBBBBBBBBBBmm.....mmM",
	"...mm......mBBBBBGGGGBBBBBBBm......mm",
	"...mm......mBBBBGGGGGGBBBBBBm......mm",
	"...SS......mBBBBGGGGGGBBBBBBm......SS",
	"...nn......mBBBBBGGGGBBBBBBBm......nn",
	"..nMMn.....mBBBBBBBBBBBBBBBBm.....nMMn",
	"..nMMn.....mdBBBBBBBBBBBBBBdm.....nMMn",
	"..nnnn.....mddBBBBBBBBBBBBddm.....nnnn",
	"...........mmddddddddddddddmm",
	"............mmmddddddddddmmm",
	"...........nnnnnnnnnnnnnnnnnn",
	"...........nnGGnnnnnnnnnnGGnn",
	"...........nnnnnnnnnnnnnnnnnn",
	"............ddddd....ddddd",
	"............ddddd....ddddd",
	"...........ddddd......ddddd",
	"...........ddddd......ddddd",
	"..........nddddd......nddddd",
	"..........nnddd........nnddd",
	"..........nnnnnn......nnnnnn",
	".........nnnnnnnn....nnnnnnnn",
	"",
]

const MINI_BOSS_LEGEND := {
	"B": Palette.MAGENTA,
	"d": Palette.PLUM,
	"D": Palette.VOID,
	"M": Palette.STEEL,
	"m": Palette.SLATE,
	"n": Palette.DUSK,
	"E": Palette.CORAL,
	"G": Palette.GOLD,
	"N": Palette.PALE_GOLD,
	"S": Palette.SKIN,
}

const ENEMY_ART := {
	&"grunt": {"rows": GRUNT, "legend": GRUNT_LEGEND, "size": SIZE},
	&"runner": {"rows": RUNNER, "legend": RUNNER_LEGEND, "size": SIZE},
	&"heavy": {"rows": HEAVY, "legend": HEAVY_LEGEND, "size": SIZE},
	&"drone": {"rows": DRONE_A, "legend": DRONE_LEGEND, "size": Vector2i(24, 24)},
	&"spellcaster": {"rows": SPELLCASTER, "legend": SPELLCASTER_LEGEND, "size": SIZE},
	&"mini_boss": {"rows": MINI_BOSS, "legend": MINI_BOSS_LEGEND, "size": Vector2i(48, 48)},
}


## Frames per enemy: [walk_a, walk_b]; charmed pair appended for charmables
## by the generator. The drone's frame B is its own rotor drawing (X -> +)
## instead of the generic bob.
static func build(enemy_id: StringName) -> Array[Image]:
	var art: Dictionary = ENEMY_ART[enemy_id]
	var base := Pix.outline(Pix.from_rows(art["rows"], art["legend"], art["size"]))
	if enemy_id == &"drone":
		var rotor_b := Pix.outline(Pix.from_rows(DRONE_B, DRONE_LEGEND, Vector2i(24, 24)))
		return [base, rotor_b]
	return [base, Pix.shifted(base, Vector2i(0, 1))]
