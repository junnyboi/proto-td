"""grunt — Gnarl, goblin spear-grunt.

Key art: charging thrust — plank shield raised to eye level so only his glaring
eyes and two huge bat-wing ears show over the rim (one ear pierced with the
lone GOLD ring), spear couched low under his arm driving forward, back leg
braced against a flagstone, weight fully committed. A fang pokes through the
chipped bite-mark in the shield rim.

Iso: chibi mid-stride walk, shield square toward camera-left (brown half),
goblin green on the right, spear angled up over the shoulder behind.

Run from repo root: python3 tools/artgen/gen_grunt.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- flagstone the back foot braces against (bottom-right) ---
    c.poly([(92, 184), (126, 180), (126, 200), (96, 202)], "SLATE")
    c.poly([(92, 184), (126, 180), (124, 187), (94, 190)], "GRAY")   # lit top
    c.line(96, 201, 125, 199, "DUSK", 1)                             # base shade
    c.line(102, 190, 110, 196, "DUSK", 1)                            # crack

    # --- back braced leg: near-straight, pushing hard off the flagstone ---
    c.poly([(78, 118), (90, 116), (104, 146), (96, 152)], "GREEN")   # thigh
    c.poly([(96, 148), (104, 144), (114, 174), (104, 178)], "GREEN") # shin
    c.line(99, 152, 108, 174, "DEEP_GREEN", 2)                       # shade under
    c.line(94, 122, 104, 146, "LIME", 1)                             # lit edge
    c.line(96, 150, 104, 147, "DEEP_GREEN", 2)                       # knee crease
    c.put(103, 144, "LIME"); c.put(104, 145, "LIME")                 # knee cap
    # wrapped foot braced toes-down against the stone
    c.poly([(102, 174), (116, 172), (122, 184), (110, 190), (100, 184)], "BROWN")
    c.line(104, 178, 117, 177, "UMBER", 1)                           # wrap strap
    c.line(102, 183, 116, 186, "UMBER", 1)
    c.put(106, 175, "BRONZE")                                        # strap knot
    # kicked-up dust at the push-off
    c.put(118, 168, "GRAY"); c.put(124, 176, "GRAY"); c.put(120, 160, "GRAY")

    # --- front leg: deep lunge bend, knee driving ahead of the ankle ---
    c.poly([(66, 118), (78, 120), (58, 148), (48, 142)], "GREEN")    # thigh forward
    c.poly([(48, 142), (58, 146), (58, 184), (48, 184)], "GREEN")    # shin, ankle back
    c.line(57, 152, 55, 180, "DEEP_GREEN", 2)
    c.line(52, 144, 48, 158, "LIME", 1)
    c.line(50, 146, 56, 148, "DEEP_GREEN", 1)                        # knee crease
    c.put(48, 144, "LIME")                                           # knee cap
    # wrapped front foot, tapered toes toward the charge
    c.poly([(34, 186), (58, 182), (62, 191), (48, 195), (34, 192)], "BROWN")
    c.line(38, 187, 56, 186, "UMBER", 1)
    c.line(36, 191, 56, 191, "UMBER", 1)
    c.put(42, 185, "BRONZE")

    # --- loincloth flap whipped back by the charge ---
    c.poly([(74, 118), (88, 116), (102, 128), (96, 140), (84, 130)], "BROWN")
    c.poly([(92, 124), (102, 128), (96, 140), (90, 132)], "UMBER")
    c.line(76, 119, 88, 118, "UMBER", 1)                             # split from belt
    c.line(84, 130, 96, 140, "UMBER", 1)                             # ragged hem shade
    # faint motion streaks trailing the charge
    c.line(106, 128, 111, 126, "GRAY", 1)
    c.line(102, 144, 107, 143, "GRAY", 1)

    # --- torso: hunched low behind the shield, driving left ---
    c.poly([(50, 74), (72, 70), (84, 88), (88, 120), (66, 124), (54, 96)], "BROWN")
    c.poly([(78, 86), (84, 88), (88, 120), (80, 121), (76, 100)], "UMBER")  # shade
    # umber straps + crude stitches
    c.line(58, 82, 82, 102, "UMBER", 2)
    c.line(64, 74, 78, 118, "UMBER", 2)
    for x, y in ((62, 86), (68, 92), (74, 98), (68, 80), (74, 104), (76, 112)):
        c.put(x, y, "BRONZE")
    c.line(64, 122, 88, 119, "UMBER", 2)                             # belt

    # --- salvaged SLATE plate strapped to the trailing shoulder ---
    c.poly([(68, 66), (84, 63), (89, 74), (78, 81), (68, 76)], "SLATE")
    c.line(70, 66, 82, 64, "STEEL", 1)                               # top-lit rim
    c.poly([(82, 70), (89, 74), (80, 79)], "DUSK")                   # underside
    c.put(72, 69, "STEEL"); c.put(84, 73, "DUSK")                    # rivets

    # --- spear: couched low under the arm, driving down-forward ---
    c.line(116, 96, 12, 150, "BROWN", 3)                             # haft
    c.line(116, 95, 14, 148, "BRONZE", 1)                            # top-lit edge
    c.line(70, 122, 34, 141, "UMBER", 1)                             # under shade
    # cord lashing at the socket
    c.line(30, 139, 33, 146, "UMBER", 2)
    c.line(35, 137, 38, 144, "UMBER", 2)
    c.put(31, 139, "BRONZE"); c.put(36, 138, "BRONZE")
    # dull iron leaf head: slim diamond around the haft axis, point down-left
    c.poly([(6, 156), (17, 145), (30, 141), (21, 153)], "SLATE")
    c.line(8, 155, 28, 142, "DUSK", 1)                               # midrib
    c.line(10, 151, 28, 141, "STEEL", 1)                             # lit upper edge
    c.put(6, 156, "STEEL"); c.put(7, 155, "STEEL")                   # glinting point
    # right arm clamping the haft: bare green, fist gripping forward
    c.line(74, 80, 84, 100, "GREEN", 5)                              # upper arm
    c.line(84, 100, 68, 114, "GREEN", 4)                             # forearm to grip
    c.line(74, 84, 82, 98, "DEEP_GREEN", 1)                          # arm/torso split
    c.line(82, 104, 72, 112, "DEEP_GREEN", 1)
    c.line(78, 82, 84, 96, "LIME", 1)
    c.ellipse(66, 117, 4, 3, "GREEN")                                # fist on haft
    c.put(64, 115, "LIME"); c.line(63, 119, 68, 119, "DEEP_GREEN", 1)

    # --- far bat-wing ear: one clean single-point triangle over the skull ---
    c.poly([(52, 40), (68, 28), (88, 18), (76, 33), (64, 41), (58, 45)], "GREEN")
    c.poly([(55, 39), (64, 34), (60, 42)], "DEEP_GREEN")             # inner base
    c.curve([(54, 39), (66, 30), (78, 24)], "LIME", 1)               # lit leading edge

    # --- head: mottled green scalp thrust forward over the rim ---
    c.ellipse(48, 52, 13, 11, "GREEN")
    c.ellipse(44, 47, 7, 5, "LIME")                                  # key-lit crown
    c.poly([(54, 44), (60, 50), (58, 60), (52, 58)], "DEEP_GREEN")   # skull shade
    c.put(40, 42, "DEEP_GREEN"); c.put(52, 41, "DEEP_GREEN")         # mottle spots
    c.put(36, 48, "DEEP_GREEN"); c.put(55, 53, "DEEP_GREEN")

    # --- near bat-wing ear: bigger triangle, two trailing scallops ---
    c.poly([(58, 50), (76, 42), (102, 36), (94, 46), (104, 54), (86, 54),
            (96, 64), (78, 60), (64, 58)], "GREEN")
    c.poly([(62, 52), (74, 48), (70, 56), (64, 56)], "DEEP_GREEN")   # inner concha
    c.line(58, 50, 100, 37, "LIME", 1)                               # lit edge
    # THE gold ear-ring: hanging off the lower membrane
    c.ellipse(69, 61, 2, 2, "GOLD")
    c.put(69, 61, None)                                              # ring hole
    c.put(68, 60, "PALE_GOLD")                                       # glint

    # --- face: furious anime glare just above the rim ---
    # heavy brow ridge (VOID for contrast), inner ends crushed down
    c.line(35, 44, 43, 47, "VOID", 2)
    c.line(51, 47, 58, 44, "VOID", 2)
    c.line(46, 47, 48, 49, "DEEP_GREEN", 1)                          # scowl crease
    c.line(36, 42, 42, 45, "DEEP_GREEN", 1)                          # ridge shadow
    c.line(52, 45, 57, 42, "DEEP_GREEN", 1)
    # left eye (x35..42): sclera, angry lash, gold iris, catchlight
    c.rect(36, 49, 42, 54, "PALE")
    c.line(35, 48, 43, 49, "VOID", 1)                                # lash angled down-in
    c.put(43, 50, "VOID")
    c.rect(37, 50, 41, 54, "GOLD")
    c.line(37, 50, 41, 50, "BRONZE", 1)                              # iris top shade
    c.rect(39, 51, 40, 52, "VOID")                                   # pupil
    c.put(37, 51, "PALE_GOLD")                                       # catchlight
    c.line(36, 55, 42, 55, "DEEP_GREEN", 1)                          # lower lid
    # right eye (x50..57)
    c.rect(50, 49, 56, 54, "PALE")
    c.line(49, 49, 57, 48, "VOID", 1)
    c.put(49, 50, "VOID")
    c.rect(51, 50, 55, 54, "GOLD")
    c.line(51, 50, 55, 50, "BRONZE", 1)
    c.rect(53, 51, 54, 52, "VOID")
    c.put(51, 51, "PALE_GOLD")
    c.line(50, 55, 56, 55, "DEEP_GREEN", 1)

    # --- plank shield: raised to eye level, fronting everything ---
    c.poly([(18, 58), (62, 62), (58, 138), (14, 130)], "BROWN")
    c.poly([(32, 59), (46, 60), (43, 135), (29, 133)], "UMBER")      # middle board
    c.line(32, 59, 29, 133, "VOID", 1)                               # seams
    c.line(46, 60, 43, 135, "VOID", 1)
    c.line(18, 58, 62, 62, "BRONZE", 1)                              # top rim lit
    c.line(18, 58, 14, 130, "BRONZE", 1)                             # left rim lit
    c.line(58, 138, 15, 131, "UMBER", 1)                             # bottom shade
    # chipped bite-mark in the top rim — underbite fangs poke through it
    for x in range(39, 50):
        c.put(x, 59, None); c.put(x, 60, None); c.put(x, 61, None)
    for x in range(41, 48):
        c.put(x, 62, None)
    c.put(43, 63, None); c.put(44, 63, None); c.put(45, 63, None)
    # jaw sliver + upthrust underbite fangs in the notch
    c.rect(40, 60, 48, 62, "DEEP_GREEN")
    c.rect(43, 63, 45, 63, "DEEP_GREEN")
    c.rect(40, 58, 41, 61, "PALE")                                   # fang 1
    c.rect(46, 58, 47, 61, "PALE")                                   # fang 2
    # wood grain + cracks
    c.line(23, 70, 25, 98, "UMBER", 1)
    c.line(52, 74, 50, 106, "BRONZE", 1)
    c.line(37, 66, 36, 86, "BROWN", 1)
    c.line(38, 110, 36, 130, "BROWN", 1)
    c.line(24, 112, 22, 126, "UMBER", 1)
    c.line(54, 118, 57, 132, "VOID", 1)                              # split crack
    # bronze studs pinning the boards
    for x, y in ((23, 64), (56, 68), (20, 120), (52, 128), (39, 64), (35, 130)):
        c.put(x, y, "BRONZE"); c.put(x + 1, y, "BRONZE")
        c.put(x, y + 1, "BRONZE"); c.put(x + 1, y + 1, "UMBER")
        c.put(x, y, "PALE")                                          # glint
    # green fingers hooked over the right rim
    for fx, fy in ((60, 76), (60, 82), (59, 88)):
        c.ellipse(fx, fy, 2, 1, "GREEN")
        c.put(fx - 1, fy - 1, "LIME")

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- spear angled up over the shoulder, behind everything ---
    c.line(40, 48, 58, 14, "BROWN", 2)
    c.line(41, 46, 57, 16, "BRONZE", 1)
    c.poly([(55, 13), (59, 3), (63, 10), (59, 17)], "SLATE")         # iron head
    c.put(58, 6, "STEEL"); c.put(60, 12, "DUSK")
    c.line(55, 16, 57, 19, "UMBER", 1)                               # lashing

    # --- mid-stride feet at pivot (32, 60): wrapped, symmetric stride ---
    c.rect(25, 54, 30, 59, "BROWN")                                  # lead foot
    c.line(25, 56, 30, 56, "UMBER", 1)
    c.rect(34, 52, 39, 57, "BROWN")                                  # trail foot
    c.line(34, 54, 39, 54, "UMBER", 1)
    # bare green shins
    c.rect(26, 48, 29, 53, "GREEN")
    c.rect(35, 46, 38, 51, "GREEN")
    c.put(29, 49, "DEEP_GREEN"); c.put(38, 47, "DEEP_GREEN")

    # --- torso: brown jerkin, slate scrap on the right shoulder ---
    c.rect(26, 34, 40, 47, "BROWN")
    c.rect(37, 34, 40, 47, "UMBER")                                  # shade right
    c.line(28, 36, 38, 44, "UMBER", 1)                               # strap
    c.put(31, 39, "BRONZE"); c.put(34, 41, "BRONZE")                 # stitches
    c.line(26, 46, 40, 46, "UMBER", 1)                               # belt
    c.poly([(36, 32), (43, 31), (44, 37), (38, 38)], "SLATE")        # shoulder scrap
    c.put(38, 32, "STEEL"); c.put(42, 36, "DUSK")
    # spear arm up to the haft
    c.line(40, 38, 45, 44, "GREEN", 2)
    c.put(45, 45, "DEEP_GREEN")

    # --- plank shield square toward camera-left (left half = brown) ---
    c.poly([(11, 26), (27, 28), (27, 54), (11, 52)], "BROWN")
    c.rect(17, 27, 21, 53, "UMBER")                                  # middle board
    c.line(17, 27, 17, 53, "VOID", 1)
    c.line(22, 27, 22, 53, "VOID", 1)
    c.line(11, 26, 27, 28, "BRONZE", 1)                              # lit rim
    c.line(11, 26, 11, 52, "BRONZE", 1)
    # bite-mark chip in the left rim
    c.put(11, 34, None); c.put(11, 35, None); c.put(12, 34, None)
    # studs
    for x, y in ((14, 30), (24, 31), (14, 48), (24, 50)):
        c.put(x, y, "BRONZE"); c.put(x, y - 1, "PALE")

    # --- head: big green skull, two bat-wing ears breaking silhouette ---
    c.ellipse(34, 20, 10, 9, "GREEN")
    c.ellipse(31, 16, 6, 4, "LIME")                                  # lit crown
    c.poly([(40, 14), (44, 22), (41, 27)], "DEEP_GREEN")             # skull shade
    c.put(28, 12, "DEEP_GREEN"); c.put(38, 11, "DEEP_GREEN")         # mottle
    # left ear sweeping up-left over the shield
    c.poly([(26, 16), (16, 8), (8, 6), (12, 12), (8, 16), (16, 16), (22, 20)], "GREEN")
    c.poly([(18, 12), (12, 9), (14, 13), (12, 15), (18, 15)], "DEEP_GREEN")
    c.curve([(24, 14), (16, 8), (10, 6)], "LIME", 1)
    # right ear sweeping up-right, pierced with THE 1px gold ring
    c.poly([(42, 16), (50, 9), (56, 7), (52, 12), (56, 16), (49, 16), (45, 20)], "GREEN")
    c.poly([(48, 12), (53, 9), (51, 13), (53, 15), (48, 15)], "DEEP_GREEN")
    c.curve([(44, 14), (50, 9), (54, 7)], "LIME", 1)
    # THE gold ear-ring hanging off the membrane edge
    c.put(47, 19, "GOLD"); c.put(48, 19, "GOLD")
    c.put(47, 20, "GOLD"); c.put(48, 20, "PALE_GOLD")

    # --- chibi glare face + underbite ---
    c.line(28, 18, 31, 19, "DEEP_GREEN", 1)                          # angry brows
    c.line(37, 19, 40, 18, "DEEP_GREEN", 1)
    c.rect(29, 20, 30, 22, "VOID"); c.put(29, 20, "GOLD")            # left eye
    c.put(29, 19, "PALE")
    c.rect(37, 20, 38, 22, "VOID"); c.put(37, 20, "GOLD")            # right eye
    c.put(37, 19, "PALE")
    c.line(30, 25, 37, 25, "DEEP_GREEN", 2)                          # snarl
    c.put(31, 24, "PALE"); c.put(31, 23, "PALE")                     # underbite fangs
    c.put(36, 24, "PALE"); c.put(36, 23, "PALE")

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
    save(key, os.path.join(out, "grunt_key.png"), 1)
    save(key, os.path.join(out, "grunt_key@3x.png"), 3)
    save(iso, os.path.join(out, "grunt_iso.png"), 1)
    save(iso, os.path.join(out, "grunt_iso@4x.png"), 4)
    print("grunt: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
