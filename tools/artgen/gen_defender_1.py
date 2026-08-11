"""defender_1 — Odgar Hallanchor, dwarf shield-anchor.

Key art: impact brace at the exact frame something huge hits the shield —
squat dwarf side-on facing viewer-left, shoulder and cheek pressed into the
inner face of the angled storm-teal tower shield, front knee sunk, rear leg
driven long behind with the sabaton plowing a skid of sparks and gravel.
Cyan lantern emblem catching torchlight; flanged mace held low and relaxed
behind the shield; behind the rim, a calm gentle smile.

Iso: chibi planted behind the tower shield (lane side = right), shield the
single biggest shape, beard braid spilling over the rim with one gold clasp,
steel skullcap glint, eyes-over-the-rim.

Run from repo root: python3 tools/artgen/gen_defender_1.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- far (right) arm + mace, drawn first (deepest layer) ---
    c.line(80, 106, 92, 128, "DUSK", 6)                  # upper arm in shadow
    c.line(92, 128, 89, 146, "DUSK", 5)                  # forearm hanging
    c.ellipse(88, 150, 4, 3, "SLATE")                    # relaxed gauntlet
    c.put(86, 148, "STEEL")
    # mace hanging loose into the clear gap between the legs
    c.line(86, 153, 79, 170, "UMBER", 2)                 # haft
    c.line(85, 154, 79, 166, "BROWN", 1)
    # flanged mace head — chunky, clearly its own silhouette
    c.ellipse(77, 179, 6, 7, "DUSK")
    c.poly([(77, 171), (80, 176), (77, 180), (74, 176)], "STEEL")   # top flange
    c.poly([(70, 176), (75, 178), (71, 183), (69, 179)], "SLATE")   # left
    c.poly([(84, 176), (79, 178), (83, 183), (85, 179)], "SLATE")   # right
    c.poly([(77, 179), (80, 182), (77, 187), (74, 182)], "SLATE")   # bottom
    c.put(76, 174, "PALE"); c.put(72, 177, "STEEL")

    # --- rear leg: stumpy and powerful, driven out long behind ---
    c.line(78, 148, 102, 164, "SLATE", 10)               # thigh
    c.line(102, 164, 116, 184, "SLATE", 7)               # shin
    c.line(75, 143, 100, 159, "STEEL", 2)                # top-lit cuisse
    c.line(102, 161, 115, 180, "STEEL", 1)
    c.line(83, 153, 104, 170, "DUSK", 3)                 # underside shadow
    c.ellipse(102, 164, 5, 5, "STEEL")                   # poleyn
    c.ellipse(103, 165, 3, 3, "SLATE")
    c.put(100, 161, "PALE")
    # sabaton plowing in, toes digging
    c.poly([(108, 180), (123, 186), (127, 194), (121, 199), (106, 193)], "SLATE")
    c.line(110, 183, 121, 189, "STEEL", 1)
    c.line(109, 192, 123, 197, "DUSK", 2)
    c.put(112, 190, "DEEP_GREEN"); c.put(117, 192, "DEEP_GREEN")  # moss scuff
    # gravel skid kicked up behind the toes
    for x, y in ((118, 202), (122, 199), (125, 203), (114, 204), (127, 198)):
        c.put(x, y, "GRAY")
    for x, y in ((120, 203), (124, 200), (116, 203), (126, 205)):
        c.put(x, y, "DUSK")
    # sparks off the plow point — bright 2px flints
    c.put(124, 184, "GOLD"); c.put(125, 183, "PALE_GOLD")
    c.put(121, 179, "GOLD"); c.put(122, 178, "PALE_GOLD")
    c.put(126, 190, "GOLD"); c.put(127, 189, "PALE_GOLD")
    c.put(118, 176, "GOLD")

    # --- torso: wide slab of plate, leaning hard left into the shield ---
    c.poly([(44, 98), (82, 92), (90, 114), (88, 150), (60, 154), (44, 126)],
           "SLATE")
    c.line(47, 100, 81, 94, "STEEL", 2)                  # top-lit breastplate
    c.line(48, 128, 88, 124, "STEEL", 1)                 # plate seam
    c.poly([(78, 120), (90, 114), (88, 150), (70, 152)], "DUSK")  # rt shadow
    c.line(60, 152, 88, 148, "GRAY", 2)                  # chain skirt
    c.put(64, 152, "DUSK"); c.put(72, 151, "DUSK"); c.put(80, 150, "DUSK")

    # --- front leg: knee sunk deep, braced under the shield ---
    c.line(58, 150, 50, 170, "SLATE", 9)                 # thigh folding
    c.ellipse(49, 172, 6, 5, "STEEL")                    # poleyn
    c.ellipse(50, 173, 4, 3, "SLATE")
    c.put(46, 170, "PALE")
    c.line(48, 177, 46, 192, "SLATE", 7)                 # shin
    c.line(44, 178, 43, 190, "DUSK", 2)
    c.poly([(35, 190), (52, 190), (55, 198), (37, 200)], "SLATE")  # sabaton
    c.line(38, 198, 53, 197, "DUSK", 1)
    c.line(37, 191, 51, 191, "STEEL", 1)
    c.put(42, 195, "DEEP_GREEN")                         # moss scuff

    # --- left arm: braced forward into the shield grip ---
    c.line(50, 106, 44, 116, "SLATE", 5)
    c.ellipse(42, 120, 4, 3, "STEEL")                    # gauntlet on grip
    c.put(40, 118, "PALE")
    # pauldron rammed against the shield (shield will overlap it)
    c.ellipse(52, 102, 10, 8, "STEEL")
    c.ellipse(55, 105, 7, 6, "SLATE")
    c.curve([(45, 98), (51, 95), (58, 96)], "PALE", 1)   # key-light glint

    # --- head: big dwarf skull, cheek pushed against the shield rim ---
    c.ellipse(62, 80, 12, 13, "SKIN")
    c.ellipse(59, 78, 9, 10, "SKIN_LIGHT")               # lit toward key light
    c.line(71, 74, 73, 88, "SKIN_SHADOW", 1)             # far cheek shade
    c.put(70, 90, "SKIN_SHADOW")                         # weathered crease

    # --- face: calm and kind, big storm-teal anime eyes ---
    # bushy brows just under the cap rim
    c.line(52, 78, 58, 77, "BROWN", 2)
    c.line(64, 77, 70, 78, "BROWN", 2)
    # near (left) eye
    c.rect(53, 81, 59, 86, "PALE")
    c.line(52, 80, 60, 80, "VOID", 1)                    # lash line
    c.put(52, 81, "VOID"); c.put(60, 81, "VOID")         # lash corners
    c.rect(54, 82, 58, 86, "TEAL")                       # iris
    c.put(54, 82, "CYAN"); c.put(55, 82, "CYAN")         # iris light
    c.rect(56, 84, 57, 85, "VOID")                       # pupil
    c.put(54, 83, "PALE_GOLD"); c.put(55, 83, "PALE_GOLD")   # catchlight
    c.put(53, 86, "SKIN_LIGHT"); c.put(59, 86, "SKIN_LIGHT")
    c.line(53, 87, 59, 87, "SKIN_SHADOW", 1)             # soft lower lid
    # far (right) eye — narrower with the 3/4 turn
    c.rect(64, 81, 69, 86, "PALE")
    c.line(63, 80, 70, 80, "VOID", 1)
    c.put(63, 81, "VOID"); c.put(70, 81, "VOID")
    c.rect(65, 82, 68, 86, "TEAL")
    c.put(65, 82, "CYAN")
    c.rect(66, 84, 67, 85, "VOID")
    c.put(65, 83, "PALE_GOLD")
    c.put(64, 86, "SKIN_LIGHT"); c.put(69, 86, "SKIN_LIGHT")
    c.line(64, 87, 69, 87, "SKIN_SHADOW", 1)
    c.put(52, 88, "ROSE"); c.put(69, 88, "ROSE")         # warm cheeks

    # --- steel skullcap with dented rim, low over the brows ---
    c.ellipse(62, 69, 13, 7, "STEEL")
    c.poly([(49, 71), (75, 68), (76, 75), (48, 78)], "STEEL")    # rim band
    c.line(49, 77, 75, 74, "SLATE", 1)                   # rim underside
    c.curve([(53, 65), (60, 63), (68, 64)], "PALE", 2)   # dome glint
    c.put(72, 69, "DUSK"); c.put(73, 70, "DUSK"); c.put(72, 71, "SLATE")  # dent
    c.line(48, 77, 51, 78, "DUSK", 1)                    # dinged edge

    # --- THE BEARD: one great chestnut braid, half his silhouette ---
    # sideburns joining cap rim to beard
    c.poly([(50, 78), (53, 78), (52, 92), (48, 88)], "BROWN")
    c.poly([(71, 78), (74, 78), (76, 92), (71, 90)], "BROWN")
    # jaw fringe + braid mass, wavy edges with side tufts (mouth zone open)
    c.poly([(50, 90), (54, 96), (56, 106), (50, 110),                # left tuft
            (52, 118), (48, 126), (54, 132),                         # wave
            (54, 142), (60, 152), (64, 158), (72, 158), (78, 150),   # braid tip
            (82, 142), (80, 132), (86, 126), (80, 118),              # wave
            (84, 110), (78, 104), (80, 94), (76, 90),                # right tuft
            (72, 93), (66, 95), (60, 95), (56, 92)], "BROWN")
    # umber depths bottom-right of the mass
    c.poly([(74, 106), (82, 112), (80, 126), (78, 142), (72, 152),
            (70, 138), (74, 120)], "UMBER")
    c.curve([(78, 98), (80, 106)], "UMBER", 1)
    # braid chevrons — crossing ridges marching down
    for i, y in enumerate((108, 118, 128, 138)):
        xm = 66 + (i % 2)
        c.curve([(xm - 8, y), (xm, y + 4), (xm + 8, y)], "UMBER", 1)
        c.curve([(xm - 7, y - 2), (xm, y + 2)], "BRONZE", 1)     # lit ridge
    # bronze lights on the key-light side
    c.curve([(53, 98), (52, 110), (54, 124)], "BRONZE", 1)
    c.curve([(56, 136), (60, 148)], "BRONZE", 1)
    # open chin patch carved over the beard so the mouth owns its space
    c.ellipse(61, 98, 5, 4, "SKIN")
    c.line(58, 95, 64, 95, "SKIN_LIGHT", 1)
    # calm gentle smile
    c.curve([(57, 98), (61, 100), (65, 98)], "VOID", 1)
    c.put(66, 97, "VOID")                                # upturned corner
    c.put(60, 101, "SKIN_SHADOW"); c.put(62, 101, "SKIN_SHADOW")  # lower lip
    # moustache: full walrus swoops, ends turned cheerfully up
    c.curve([(60, 93), (56, 95), (52, 93)], "BROWN", 2)
    c.curve([(63, 93), (67, 95), (71, 93)], "BROWN", 2)
    c.put(52, 92, "BRONZE"); c.put(71, 92, "BRONZE")
    c.put(55, 93, "BRONZE"); c.put(68, 93, "BRONZE")
    # big friendly dwarf nose — pops light against the SKIN face
    c.ellipse(61, 90, 3, 2, "SKIN_LIGHT")
    c.put(59, 88, "SKIN_PALE"); c.put(60, 88, "SKIN_PALE")
    c.curve([(58, 92), (61, 93), (64, 92)], "SKIN_SHADOW", 1)    # under-curve
    c.put(65, 91, "SKIN_SHADOW")
    # gold clasp cinching the braid
    c.rect(62, 152, 72, 157, "GOLD")
    c.line(62, 157, 72, 157, "BRONZE", 1)
    c.put(64, 153, "PALE_GOLD"); c.put(65, 153, "PALE_GOLD")
    # braid tuft flaring below the clasp
    c.poly([(62, 158), (72, 158), (74, 166), (67, 170), (60, 166)], "BROWN")
    c.put(70, 164, "UMBER"); c.put(64, 161, "BRONZE")

    # --- THE SHIELD: door-sized tower slab, top tilted back into him,
    #     overlapping the pauldron (he is pressed against the inner face) ---
    c.poly([(28, 62), (56, 70), (32, 200), (6, 192)], "NAVY")
    c.poly([(32, 67), (52, 74), (29, 194), (11, 188)], "TEAL")   # enamel face
    # navy wear along the lower-right of the face (thin — face reads TEAL)
    c.poly([(44, 122), (48, 124), (30, 192), (26, 188)], "NAVY")
    c.line(38, 88, 36, 102, "NAVY", 1)                   # old scratch
    # cyan glints where the torchlight rakes the rim
    c.curve([(30, 64), (43, 67), (55, 71)], "CYAN", 1)
    c.line(31, 70, 28, 88, "CYAN", 1)
    # boss rivets down both borders
    for x, y in ((27, 84), (23, 112), (19, 140), (15, 168)):
        c.put(x, y, "STEEL"); c.put(x + 1, y + 1, "DUSK")
    for x, y in ((52, 84), (48, 112), (44, 140), (40, 168)):
        c.put(x, y, "STEEL"); c.put(x + 1, y + 1, "DUSK")
    # --- cyan lantern emblem, upper third, catching torchlight ---
    ex, ey = 34, 104
    c.put(ex, ey - 10, "CYAN")                           # hanging ring
    c.line(ex - 4, ey - 8, ex + 4, ey - 8, "CYAN", 1)    # cap
    c.line(ex - 3, ey - 7, ex + 3, ey - 7, "CYAN", 1)
    c.poly([(ex - 5, ey - 5), (ex + 5, ey - 5), (ex + 4, ey + 6),
            (ex - 4, ey + 6)], "CYAN")                   # body
    c.rect(ex - 2, ey - 3, ex + 2, ey + 3, "NAVY")       # glass cutout
    c.put(ex, ey, "CYAN"); c.put(ex, ey - 1, "PALE_GOLD")    # flame + torch kiss
    c.line(ex - 3, ey + 7, ex + 3, ey + 7, "CYAN", 1)    # foot
    # impact: three short shock dashes off the upper-left face
    c.line(4, 76, 9, 78, "PALE", 1)
    c.line(3, 92, 8, 92, "STEEL", 1)
    c.line(5, 108, 10, 106, "PALE", 1)

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- boots at the pivot (32, 60), peeking out lane-back ---
    c.rect(18, 54, 24, 59, "DUSK")
    c.line(19, 55, 23, 55, "SLATE", 1)
    c.put(20, 58, "DEEP_GREEN")                          # moss scuff

    # --- body: slate plate slab, 1px steel highlights ---
    c.poly([(13, 28), (33, 28), (35, 55), (12, 54)], "SLATE")
    c.line(14, 30, 14, 52, "STEEL", 1)                   # key-light edge
    c.line(13, 44, 34, 44, "DUSK", 1)                    # waist shadow
    c.line(15, 50, 33, 51, "GRAY", 1)                    # chain skirt

    # --- head: skin, then steel skullcap ---
    c.ellipse(22, 17, 9, 8, "SKIN")
    c.ellipse(20, 16, 7, 6, "SKIN_LIGHT")
    c.ellipse(22, 11, 9, 4, "STEEL")                     # skullcap dome
    c.line(14, 13, 30, 13, "STEEL", 1)                   # rim band
    c.line(14, 14, 30, 14, "SLATE", 1)                   # rim underside
    c.curve([(17, 9), (22, 8), (27, 9)], "PALE", 1)      # THE glint
    c.put(29, 12, "DUSK")                                # dent

    # --- face: big kind eyes under bushy brows ---
    c.line(15, 15, 18, 15, "BROWN", 1)                   # brows
    c.line(23, 15, 26, 15, "BROWN", 1)
    c.rect(15, 17, 17, 20, "VOID")                       # left eye
    c.put(15, 17, "TEAL"); c.put(16, 17, "TEAL")
    c.put(15, 16, "PALE")                                # catchlight
    c.rect(23, 17, 25, 20, "VOID")                       # right eye
    c.put(23, 17, "TEAL"); c.put(24, 17, "TEAL")
    c.put(23, 16, "PALE")
    c.put(20, 21, "SKIN_SHADOW")                         # nose

    # --- THE SHIELD: single biggest shape, lane side (right) ---
    c.poly([(28, 14), (54, 20), (53, 57), (27, 55)], "NAVY")
    c.poly([(30, 17), (52, 22), (51, 55), (29, 53)], "TEAL")     # enamel
    c.poly([(48, 44), (51, 46), (51, 55), (45, 54)], "NAVY")     # thin shade
    c.line(29, 15, 52, 20, "CYAN", 1)                    # rim glint
    # cyan lantern emblem, catching torchlight
    c.put(41, 29, "CYAN")                                # ring
    c.line(39, 30, 43, 30, "CYAN", 1)                    # cap
    c.rect(38, 31, 44, 38, "CYAN")                       # body
    c.rect(40, 33, 42, 36, "NAVY")                       # glass
    c.put(41, 35, "CYAN"); c.put(41, 34, "PALE_GOLD")    # flame + torch kiss
    c.line(39, 39, 43, 39, "CYAN", 1)                    # foot

    # --- beard braid spilling over and IN FRONT of the shield rim ---
    c.poly([(14, 22), (30, 22), (34, 28), (33, 38), (28, 46),
            (20, 44), (13, 32)], "BROWN")
    c.curve([(30, 28), (32, 34), (30, 40)], "UMBER", 1)  # shade right
    c.curve([(16, 25), (15, 31), (18, 38)], "BRONZE", 1) # lit left
    c.line(19, 29, 27, 29, "UMBER", 1)                   # braid crossings
    c.line(19, 35, 27, 35, "UMBER", 1)
    c.curve([(20, 26), (24, 26)], "BRONZE", 1)
    c.rect(21, 42, 26, 45, "GOLD")                       # THE clasp
    c.put(22, 42, "PALE_GOLD"); c.put(23, 42, "PALE_GOLD")
    c.line(21, 45, 26, 45, "BRONZE", 1)
    c.rect(22, 46, 25, 49, "BROWN")                      # tuft below
    c.put(25, 48, "UMBER")

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
    save(key, os.path.join(out, "defender_1_key.png"), 1)
    save(key, os.path.join(out, "defender_1_key@3x.png"), 3)
    save(iso, os.path.join(out, "defender_1_iso.png"), 1)
    save(iso, os.path.join(out, "defender_1_iso@4x.png"), 4)
    print("defender_1: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
