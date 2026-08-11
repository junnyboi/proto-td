"""spellcaster — Vesper, hooded human cultist.

Key art: mid-cast lunge-step — front foot slid forward viewer-left, wine
robes flaring back-right, bone wand thrust out two-handed with a spinning
ORCHID sigil ring blooming off its tip, ROSE sparks trailing. Hooded head
tilted down; only the serene faintly-smiling mouth is lit from below by her
own spell-light, two faint orchid eye-glows in the hood shadow.

Iso: chibi walking stride, pointed hood (tallest sharpest head in the wave),
wand forward at waist height with a 3-4px orchid sigil dot ahead of the tip
— the single saturated element that marks "ranged" at a glance.

Run from repo root: python3 tools/artgen/gen_spellcaster.py
"""
import sys, os, math
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


def sigil_ring(c: Canvas, cx, cy, rx, ry, rot) -> None:
    """Spinning arcane hoop: 2px orchid ring, magenta on the far (lower-right)
    arc, rose glints on the near (upper-left) arc, rune ticks riding the rim."""
    for rr in (0.0, 1.0):
        steps = 160
        for i in range(steps):
            a = 2 * math.pi * i / steps
            x = (rx - rr) * math.cos(a)
            y = (ry - rr) * math.sin(a)
            xr = x * math.cos(rot) - y * math.sin(rot)
            yr = x * math.sin(rot) + y * math.cos(rot)
            col = "ORCHID"
            if xr + yr > (rx + ry) * 0.38:
                col = "MAGENTA"          # far arc, away from its own light
            elif xr + yr < -(rx + ry) * 0.46:
                col = "ROSE"             # near glint
            c.put(cx + xr, cy + yr, col)
    # rune ticks sitting on the rim (the "spinning" tell)
    for a_deg in (30, 150, 265):
        a = math.radians(a_deg)
        x, y = rx * math.cos(a), ry * math.sin(a)
        xr = x * math.cos(rot) - y * math.sin(rot)
        yr = x * math.sin(rot) + y * math.cos(rot)
        c.put(cx + xr, cy + yr, "ROSE")
        c.put(cx + xr * 1.12, cy + yr * 1.12, "ROSE")


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- back leg: extended behind in the lunge, toe planted back-right ---
    c.line(88, 160, 100, 190, "DUSK", 4)
    c.poly([(96, 188), (105, 188), (117, 196), (115, 203), (98, 202)], "UMBER")
    c.line(98, 189, 108, 191, "BROWN", 1)            # top-lit leather
    c.line(100, 202, 115, 202, "VOID", 1)            # sole
    c.put(111, 195, "BRONZE")                        # scuff

    # --- skirt: wine robe swept hard back-right by the lunge; the hem is a
    #     rising diagonal — bared knee at front-left, trailing tatters right ---
    c.poly([
        (56, 108), (80, 108),                        # waist
        (98, 124), (112, 148), (120, 172), (124, 194),
        (115, 184), (110, 199), (101, 186), (95, 198),  # tatter zigzag
        (87, 182), (79, 190), (72, 170), (64, 176),     # rising toward the left
        (58, 156), (52, 146), (50, 126),
    ], "WINE")
    # plum lining flashes where the hem flips
    c.poly([(115, 184), (124, 194), (120, 195), (110, 188)], "PLUM")
    c.poly([(87, 182), (95, 198), (91, 199), (81, 187)], "PLUM")
    c.poly([(64, 176), (72, 170), (73, 177), (68, 181)], "PLUM")
    c.poly([(50, 126), (52, 146), (58, 156), (61, 148), (55, 132)], "PLUM")
    # void creases streaming along the sweep; crimson lit folds top-left
    c.curve([(66, 110), (74, 138), (82, 168)], "VOID", 1)
    c.curve([(60, 110), (58, 128), (58, 148)], "VOID", 1)
    c.curve([(84, 116), (98, 142), (108, 172)], "VOID", 1)
    c.curve([(74, 112), (88, 140), (98, 168)], "VOID", 1)
    c.curve([(57, 110), (53, 128), (52, 142)], "CRIMSON", 1)
    c.curve([(68, 110), (72, 128)], "CRIMSON", 1)
    c.curve([(90, 120), (104, 142), (113, 164)], "CRIMSON", 1)  # lit swept edge
    # magenta trim runes stitched along the hem diagonal
    for x, y in ((67, 172), (75, 184), (83, 180), (91, 192), (99, 184),
                 (107, 193), (115, 180), (120, 186), (61, 162)):
        c.put(x, y, "MAGENTA")
        c.put(x + 1, y - 1, "MAGENTA")

    # --- front leg: bared by the risen hem — bent knee, boot slid forward ---
    c.line(57, 144, 50, 160, "DUSK", 4)              # thigh
    c.line(50, 160, 42, 176, "DUSK", 3)              # shin
    c.line(55, 146, 48, 160, "SLATE", 1)             # key-lit edge
    c.line(47, 162, 41, 174, "SLATE", 1)
    c.poly([(25, 182), (39, 177), (44, 182), (43, 187), (34, 189), (27, 188)],
           "UMBER")                                  # boot, toe pointed left
    c.line(30, 180, 39, 178, "BROWN", 1)
    c.line(28, 188, 42, 187, "VOID", 1)              # sole
    c.put(41, 188, "VOID"); c.put(42, 188, "VOID")   # heel notch
    c.put(30, 184, "BRONZE")                         # scuff

    # --- torso: wine bodice leaning hard into the lunge (diagonal axis) ---
    c.poly([(44, 60), (70, 56), (78, 80), (80, 108), (58, 108), (46, 82)], "WINE")
    c.poly([(72, 60), (78, 80), (80, 108), (76, 108), (74, 82)], "PLUM")  # shade
    c.line(78, 88, 79, 104, "VOID", 1)               # deep fold at the shade edge
    c.line(46, 62, 44, 80, "CRIMSON", 1)             # lit left edge
    c.line(52, 86, 70, 83, "VOID", 1)                # under-chest fold

    # --- rope belt + umber pouch ---
    c.line(58, 106, 80, 106, "BROWN", 2)
    c.put(63, 106, "BRONZE"); c.put(64, 107, "BRONZE")   # knot
    c.curve([(63, 108), (61, 116), (63, 122)], "BROWN", 1)  # dangling cord end
    c.rect(79, 112, 87, 122, "UMBER")
    c.rect(79, 112, 87, 115, "BROWN")                # flap
    c.put(83, 117, "BRONZE")                         # clasp

    # --- far arm (her left): sleeve sweeping down-left to the grip ---
    c.line(66, 64, 58, 76, "WINE", 6)
    c.line(58, 76, 54, 84, "WINE", 5)
    c.line(62, 70, 56, 82, "VOID", 1)                # separates sleeve from torso
    c.line(51, 84, 57, 87, "PLUM", 2)                # cuff opening lining
    c.put(50, 86, "WINE"); c.put(53, 88, "WINE")     # tatter ticks

    # --- bone wand: knobbed pale stave, bronze ferrule at the grip end ---
    c.line(58, 82, 30, 108, "PALE", 3)
    c.line(56, 85, 31, 108, "STEEL", 1)              # bone shadow edge
    c.ellipse(41, 99, 2, 2, "PALE"); c.put(40, 98, "PALE"); c.put(42, 100, "STEEL")
    c.ellipse(35, 104, 2, 2, "PALE"); c.put(36, 105, "STEEL")   # knuckle knobs
    c.line(59, 82, 61, 84, "BRONZE", 2)              # ferrule cap
    c.put(60, 82, "BROWN")                           # ferrule shade

    # --- far hand gripping the stave (VOID-edged so it pops off the bone) ---
    c.poly([(51, 85), (55, 85), (56, 88), (52, 89)], "SKIN_LIGHT")
    c.put(51, 85, "SKIN_PALE"); c.put(52, 85, "SKIN_PALE")
    c.put(55, 88, "SKIN"); c.put(56, 88, "SKIN")
    c.line(50, 84, 55, 84, "VOID", 1)                # knuckle line
    c.put(51, 89, "VOID"); c.put(52, 90, "VOID")     # grip shadow

    # --- near arm (her right): thrust straight along the wand line ---
    c.line(48, 64, 42, 78, "WINE", 5)
    c.line(42, 78, 43, 86, "WINE", 5)
    c.line(49, 70, 46, 82, "VOID", 1)                # carve the arm off the torso
    c.line(45, 66, 41, 78, "CRIMSON", 1)             # lit upper edge
    c.line(40, 87, 45, 89, "PLUM", 2)                # cuff opening lining
    c.put(38, 88, "WINE"); c.put(42, 90, "WINE")     # tatter ticks
    c.line(41, 84, 45, 86, "MAGENTA", 1)             # cuff rune trim

    # --- near hand on the stave, underlit by the sigil ---
    c.poly([(44, 90), (48, 90), (49, 94), (45, 95)], "SKIN_LIGHT")
    c.put(45, 94, "SKIN_PALE"); c.put(46, 94, "SKIN_PALE"); c.put(45, 95, "SKIN_PALE")
    c.put(48, 90, "SKIN"); c.put(49, 93, "SKIN")
    c.line(44, 89, 48, 89, "VOID", 1)                # knuckle line
    c.put(44, 96, "ROSE")                            # sigil light on the knuckle

    # --- the sigil ring blooming off the wand tip, facing the viewer ---
    sigil_ring(c, 26, 116, 13, 11, -0.35)
    # hub glow where the wand tip meets the ring
    c.put(30, 108, "ROSE"); c.put(29, 108, "ORCHID")
    c.put(31, 109, "ORCHID"); c.put(28, 110, "ORCHID"); c.put(30, 110, "ORCHID")

    # --- rose sparks trailing off the cast ---
    for x, y in ((12, 98), (40, 96), (46, 114), (20, 138), (36, 134),
                 (6, 118), (48, 104), (16, 144)):
        c.put(x, y, "ROSE")
    for x, y in ((9, 106), (43, 92), (28, 140), (44, 122)):
        c.put(x, y, "ORCHID")
    # sigil glow spilling onto the robe edge facing the ring
    c.put(51, 132, "ROSE"); c.put(53, 148, "ROSE"); c.put(49, 118, "ROSE")

    # --- shoulder mantle: tattered cowl cape over the shoulders ---
    c.poly([(44, 57), (72, 53), (77, 65), (70, 71), (63, 66), (56, 71),
            (49, 66), (44, 70), (39, 61)], "WINE")
    c.poly([(72, 55), (77, 65), (70, 71), (69, 63)], "PLUM")   # shade right
    c.line(46, 59, 42, 64, "CRIMSON", 1)
    for x, y in ((46, 66), (55, 69), (62, 64), (68, 68)):
        c.put(x, y, "MAGENTA")                       # rune stitch on mantle hem

    # --- hood: dome tilted down-left + long peak trailing up-back-right ---
    c.ellipse(59, 38, 13, 13, "WINE")
    c.poly([(63, 28), (75, 16), (89, 8), (97, 6), (89, 18), (77, 28),
            (69, 36)], "WINE")
    c.poly([(83, 14), (97, 6), (89, 18), (81, 22)], "PLUM")   # peak underside
    c.curve([(48, 32), (54, 26), (62, 25)], "CRIMSON", 2)      # key-lit crest
    c.curve([(89, 9), (95, 7)], "PALE", 1)                     # cool rim on peak
    c.poly([(69, 36), (72, 30), (72, 46), (69, 48)], "PLUM")   # dome shade right

    # --- face window: shadow, glowing eyes, underlit mouth ---
    c.ellipse(56, 44, 8, 9, "VOID")
    # plum rim of the hood opening (leading edge, catches spell light)
    c.curve([(50, 37), (48, 44), (50, 50), (54, 54)], "PLUM", 1)
    c.put(49, 39, "MAGENTA"); c.put(48, 47, "MAGENTA")         # rim runes
    # chin + mouth lit from below-left by the sigil
    c.poly([(54, 49), (62, 49), (59, 55), (55, 55)], "SKIN_LIGHT")
    c.put(54, 49, "VOID"); c.put(62, 49, "VOID")    # round the jaw corners
    c.line(55, 54, 58, 54, "SKIN_PALE", 1)          # under-glow on the chin tip
    c.line(56, 52, 59, 52, "SKIN_SHADOW", 1)        # serene faint smile
    c.put(60, 51, "SKIN_SHADOW")                    # upturned corner
    c.put(55, 55, "ROSE")                           # spell-light kiss
    # one ink strand escaping across the chin
    c.curve([(53, 47), (52, 50), (53, 53)], "INK", 1)
    c.put(62, 49, "INK")
    # orchid eye-glows in the shadow, rose-hot centers
    c.put(52, 42, "ORCHID"); c.put(53, 42, "ROSE"); c.put(54, 42, "ORCHID")
    c.put(59, 41, "ORCHID"); c.put(60, 41, "ROSE"); c.put(61, 41, "ORCHID")
    c.put(53, 43, "PLUM"); c.put(60, 42, "PLUM")     # glow falloff

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- back boot mid-step ---
    c.rect(34, 52, 38, 57, "UMBER")

    # --- wine robe mass, tattered hem ---
    c.poly([(24, 26), (40, 26), (44, 44), (46, 53), (18, 53), (20, 42)], "WINE")
    c.poly([(40, 30), (41, 26), (44, 44), (46, 53), (41, 53)], "PLUM")  # shade edge
    c.line(22, 30, 19, 44, "CRIMSON", 1)             # lit left edge
    # tatter ticks below the hem line
    for x in (21, 27, 33, 39, 44):
        c.put(x, 54, "WINE"); c.put(x, 55, "PLUM")
    # magenta hem runes
    for x, y in ((23, 52), (29, 52), (35, 52), (41, 52)):
        c.put(x, y, "MAGENTA")
    # rope belt
    c.line(21, 39, 43, 39, "BROWN", 1)
    c.put(30, 39, "BRONZE")

    # --- front boot slid forward ---
    c.rect(24, 55, 29, 59, "UMBER")
    c.line(24, 55, 29, 55, "BROWN", 1)

    # --- sleeve + hand holding the wand forward at waist height ---
    c.line(25, 33, 20, 37, "WINE", 3)
    c.put(19, 39, "PLUM"); c.put(21, 40, "PLUM")     # tattered cuff
    c.ellipse(18, 38, 1, 1, "SKIN_LIGHT")

    # --- bone wand: pale 2px line held level, knobbed, bronze ferrule ---
    c.line(20, 37, 11, 37, "PALE", 2)
    c.line(12, 38, 18, 38, "STEEL", 1)               # round bone underside
    c.put(11, 36, "PALE"); c.put(10, 37, "PALE")     # knobbed tip
    c.put(15, 36, "PALE"); c.put(15, 38, "STEEL")    # mid knuckle
    c.put(20, 37, "BRONZE"); c.put(20, 38, "BRONZE")
    # sigil dot floating ahead of the tip (1px gap) — the ranged tell
    c.put(6, 36, "ORCHID"); c.put(7, 36, "ORCHID")
    c.put(6, 37, "ORCHID"); c.put(7, 37, "ROSE")
    c.put(5, 36, "MAGENTA"); c.put(7, 35, "MAGENTA")

    # --- shoulder mantle ---
    c.poly([(24, 25), (40, 25), (42, 30), (22, 30)], "WINE")

    # --- hooded head: dome + sharp trailing peak (tallest in the wave) ---
    c.ellipse(32, 18, 9, 8, "WINE")
    c.poly([(33, 12), (40, 2), (42, 6), (37, 15)], "WINE")     # peak
    c.put(41, 3, "PALE")                              # cool rim on the peak tip
    c.poly([(38, 12), (40, 16), (39, 23), (36, 25)], "PLUM")   # dome shade right
    c.curve([(26, 11), (31, 10), (35, 11)], "CRIMSON", 1)      # key-lit crest

    # --- face window in shadow ---
    c.ellipse(29, 20, 5, 5, "VOID")
    c.put(25, 16, "PLUM"); c.put(24, 20, "PLUM")     # rim hint
    c.rect(27, 23, 30, 23, "SKIN_PALE")              # underlit chin
    c.put(28, 24, "SKIN_PALE"); c.put(29, 24, "SKIN_SHADOW")   # smile shadow
    c.put(26, 22, "INK")                             # escaped strand
    # eye-glows: 2px wide, rose-hot inner pixel — must read at 1x
    c.put(26, 18, "ORCHID"); c.put(27, 18, "ROSE")
    c.put(30, 18, "ROSE"); c.put(31, 18, "ORCHID")

    c.outline("VOID")
    return c


# ------------------------------------------------------------------ main ---
def main() -> None:
    out = os.path.join("docs", "art", "reference")
    key = paint_key()
    iso = paint_iso()
    lk = lint(key, 128, 224)
    li = lint(iso, 64, 64)
    assert lk == "", f"key art lint: {lk}"
    assert li == "", f"iso lint: {li}"
    save(key, os.path.join(out, "spellcaster_key.png"), 1)
    save(key, os.path.join(out, "spellcaster_key@3x.png"), 3)
    save(iso, os.path.join(out, "spellcaster_iso.png"), 1)
    save(iso, os.path.join(out, "spellcaster_iso@4x.png"), 4)
    print("spellcaster: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
