"""vanguard_1 — Garrick Vael, human veteran spear-vanguard.

Key art: planted guard stance at the mouth of a torchlit hall — wide low
base, front knee bent, rear leg driving. Steel-tipped boar spear held in
both fists across the body, butt slammed into cracked flagstone by his
rear boot, leaf blade leveled high toward the dark. Steel greaves and
bracers over a leaf-green gambeson. Bronze practical crop over a knotted
green headband, old scar through the brow, stoic closed-mouth veteran set.

Iso: chibi 2.5-head planted guard — spear near-vertical beside him, butt
grounded by the boot, steel leaf tip flying clear above his shoulder.

Run from repo root: python3 tools/artgen/gen_vanguard_1.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # cracked flagstone where the spear butt slammed home
    c.rect(94, 199, 104, 202, "DUSK")
    c.line(95, 199, 103, 199, "GRAY", 1)
    c.line(92, 201, 88, 205, "DUSK", 1)
    c.line(106, 201, 110, 205, "DUSK", 1)
    c.put(90, 198, "GRAY"); c.put(108, 199, "GRAY")         # flying chips

    # --- rear leg: leaf-green gambeson thigh + steel greave (2-3 tone) ---
    c.poly([(54, 120), (66, 124), (82, 150), (70, 156)], "GREEN")
    c.poly([(62, 125), (66, 124), (82, 150), (75, 153)], "DEEP_GREEN")
    c.line(56, 122, 76, 148, "LIME", 1)                     # lit top edge
    c.line(68, 132, 74, 145, "DEEP_GREEN", 1)               # quilt seam
    c.poly([(72, 154), (82, 152), (92, 182), (82, 186)], "STEEL")   # greave
    c.poly([(80, 154), (82, 152), (92, 182), (87, 184)], "SLATE")   # shade face
    c.line(75, 157, 84, 180, "PALE", 1)                     # lit flute
    c.line(78, 166, 87, 164, "SLATE", 1)                    # plate ridge
    c.ellipse(76, 153, 4, 4, "STEEL")                       # knee cop
    c.put(74, 151, "PALE"); c.put(78, 155, "SLATE")
    c.poly([(84, 186), (96, 184), (103, 193), (103, 201), (85, 201)], "BROWN")  # boot
    c.line(86, 201, 102, 201, "UMBER", 1)                   # sole
    c.poly([(95, 186), (103, 193), (103, 200), (95, 195)], "UMBER")  # boot shade
    c.put(90, 193, "BRONZE")                                # scuff

    # --- front leg: knee bent into the guard, shin greave near-vertical ---
    c.poly([(36, 116), (50, 122), (32, 150), (18, 142)], "GREEN")   # thigh
    c.poly([(44, 124), (50, 122), (36, 148), (30, 149)], "DEEP_GREEN")
    c.line(34, 118, 20, 140, "LIME", 1)                     # lit top edge
    c.line(30, 128, 26, 140, "DEEP_GREEN", 1)               # quilt seam
    c.poly([(19, 148), (29, 150), (28, 184), (17, 184)], "STEEL")   # greave
    c.poly([(26, 152), (29, 150), (28, 184), (24, 184)], "SLATE")   # shade face
    c.line(20, 153, 19, 182, "PALE", 1)                     # lit flute
    c.line(19, 162, 27, 161, "SLATE", 1)                    # plate ridge
    c.line(19, 172, 26, 171, "SLATE", 1)
    c.ellipse(25, 147, 4, 4, "STEEL")                       # knee cop
    c.put(23, 145, "PALE"); c.put(27, 149, "SLATE")
    c.poly([(6, 190), (24, 186), (30, 192), (29, 201), (8, 201)], "BROWN")  # boot
    c.line(8, 201, 28, 201, "UMBER", 1)                     # sole
    c.poly([(22, 188), (30, 192), (29, 200), (22, 197)], "UMBER")    # boot shade
    c.line(7, 192, 12, 191, "BRONZE", 1)                    # torch kiss on toe
    c.put(11, 196, "BRONZE")                                # scuff

    # --- tabard flap: deep-green with lime trim, swinging with the stance ---
    c.poly([(44, 124), (60, 126), (54, 152), (38, 148)], "DEEP_GREEN")
    c.poly([(54, 127), (60, 126), (54, 151), (48, 149)], "VOID")     # fold shade
    c.line(39, 147, 53, 151, "LIME", 1)                     # trim
    c.line(46, 126, 42, 146, "GREEN", 1)                    # lit fold

    # --- torso: boiled-leather cuirass leaning into the guard ---
    c.poly([(34, 94), (58, 88), (66, 120), (56, 128), (40, 128)], "BROWN")
    c.poly([(54, 92), (58, 88), (66, 120), (58, 126)], "UMBER")      # right shade
    c.line(40, 102, 60, 96, "UMBER", 1)                     # chest plate seam
    c.line(42, 114, 63, 108, "UMBER", 1)                    # lower plate seam
    c.line(36, 98, 40, 126, "BRONZE", 1)                    # lit left edge
    c.put(46, 106, "BRONZE"); c.put(52, 118, "BRONZE")      # rivets
    c.put(44, 120, "UMBER"); c.put(50, 98, "UMBER")         # field-mend nicks
    c.line(50, 104, 52, 108, "UMBER", 1)                    # old gash mend
    c.line(40, 126, 56, 128, "UMBER", 2)                    # belt
    c.rect(46, 125, 49, 128, "BRONZE")                      # buckle
    c.put(47, 126, "GOLD")                                  # buckle glint

    # --- boar spear: planted guard — butt in the stone, leaf tip high ---
    c.line(98, 198, 16, 50, "UMBER", 3)                     # shaft
    c.line(98, 197, 16, 49, "BROWN", 1)                     # top-lit edge
    c.line(98, 199, 17, 51, "VOID", 1)                      # under-edge pops it
    c.ellipse(99, 199, 2, 2, "BRONZE")                      # butt cap
    c.put(98, 197, "GOLD")                                  # butt-cap glint
    # cross-lug wings just below the blade socket
    c.line(17, 61, 25, 57, "STEEL", 2)
    c.put(17, 60, "PALE")
    # steel leaf blade, tapering to the high point
    c.poly([(6, 28), (13, 32), (21, 52), (12, 54)], "STEEL")
    c.poly([(14, 34), (21, 52), (16, 53)], "SLATE")         # shaded face
    c.line(13, 34, 17, 50, "DUSK", 1)                       # center ridge
    c.line(7, 29, 13, 45, "PALE", 1)                        # honed edge
    c.put(6, 28, "PALE"); c.put(7, 29, "PALE"); c.put(7, 30, "PALE")  # point
    c.line(9, 42, 12, 50, "GOLD", 1)                        # torch kiss

    # --- lead arm (his right): green sleeve, steel bracer, fist mid-shaft ---
    c.line(40, 97, 35, 105, "GREEN", 5)                     # sleeve
    c.line(38, 96, 33, 103, "LIME", 1)                      # lit edge
    c.line(42, 100, 37, 107, "DEEP_GREEN", 1)               # shade edge
    c.line(35, 105, 42, 105, "STEEL", 4)                    # bracer
    c.line(35, 103, 41, 103, "PALE", 1)                     # bracer lit rim
    c.line(36, 107, 42, 107, "SLATE", 1)                    # bracer shade
    c.ellipse(46, 104, 3, 3, "SKIN")                        # gripping fist
    c.put(45, 102, "SKIN_LIGHT")
    c.line(44, 106, 48, 106, "SKIN_SHADOW", 1)

    # --- rear arm (his left): drives the butt down, fist low on the shaft ---
    c.line(60, 97, 65, 114, "GREEN", 5)                     # sleeve
    c.line(58, 98, 63, 112, "LIME", 1)                      # lit edge
    c.line(62, 101, 67, 114, "DEEP_GREEN", 1)               # shade edge
    c.line(65, 114, 67, 136, "STEEL", 4)                    # bracer forearm
    c.line(63, 116, 65, 134, "PALE", 1)                     # bracer lit rim
    c.line(67, 118, 69, 134, "SLATE", 1)                    # bracer shade
    c.line(62, 100, 64, 112, "VOID", 1)                     # arm/torso separation
    c.line(63, 137, 63, 143, "VOID", 1)                     # fist/thigh separation
    c.ellipse(67, 140, 4, 3, "SKIN")                        # gripping fist
    c.put(65, 138, "SKIN_LIGHT"); c.put(66, 138, "SKIN_LIGHT")
    c.line(65, 142, 70, 142, "SKIN_SHADOW", 1)
    # battered steel pauldron capping the shoulder
    c.ellipse(61, 93, 6, 5, "STEEL")
    c.poly([(63, 90), (67, 93), (65, 98), (59, 98)], "SLATE")        # shade
    c.line(57, 90, 62, 89, "PALE", 1)                       # top-lit rim
    c.put(62, 94, "DUSK"); c.put(59, 95, "DUSK")            # dents
    c.line(64, 96, 66, 97, "DUSK", 1)                       # old gouge

    # --- neck + head (5.5-head scale) ---
    c.rect(43, 82, 50, 90, "SKIN")
    c.line(49, 83, 49, 89, "SKIN_SHADOW", 1)
    c.ellipse(46, 74, 9, 10, "SKIN_LIGHT")                  # face x37-55 y64-84
    c.line(41, 82, 51, 82, "SKIN", 1)                       # jaw shade

    # --- bronze practical crop, umber-shadowed (copper, not blond) ---
    c.ellipse(46, 63, 10, 5, "BRONZE")                      # crop mass
    c.poly([(38, 61), (42, 57), (47, 56), (52, 58), (54, 61), (38, 61)], "BRONZE")  # hairline fill
    c.poly([(37, 62), (40, 55), (43, 62)], "BRONZE")        # tuft 1
    c.poly([(43, 58), (47, 54), (49, 61)], "BRONZE")        # tuft 2
    c.poly([(50, 56), (54, 58), (53, 62)], "BRONZE")        # tuft 3
    c.poly([(53, 59), (56, 61), (55, 64)], "BROWN")         # right tuft in shade
    c.poly([(50, 61), (56, 60), (56, 65), (50, 65)], "BROWN")        # right shade
    c.line(53, 62, 56, 64, "UMBER", 1)                      # deep shade seam
    c.put(44, 58, "UMBER"); c.put(48, 58, "UMBER")          # tuft separations
    c.put(41, 57, "BROWN"); c.put(46, 56, "BROWN")          # strand shadow ticks
    # sideburn
    c.line(38, 67, 38, 71, "BRONZE", 1)
    c.put(38, 71, "UMBER")

    # --- knotted leaf-green headband ---
    c.rect(38, 65, 55, 67, "GREEN")
    c.line(38, 67, 55, 67, "DEEP_GREEN", 1)                 # band shade
    c.line(38, 65, 48, 65, "LIME", 1)                       # lit top-left
    c.rect(55, 64, 57, 68, "DEEP_GREEN")                    # knot
    c.curve([(58, 63), (61, 60), (63, 58)], "GREEN", 1)     # tail up
    c.curve([(58, 67), (61, 69), (63, 72)], "DEEP_GREEN", 1)  # tail down
    c.put(63, 71, "GREEN")

    # --- face: stoic veteran set, scarred brow, green anime eyes ---
    # level determined brows
    c.line(39, 69, 43, 70, "BROWN", 1)
    c.line(49, 70, 53, 69, "BROWN", 1)
    # old white scar seam through the left brow
    c.put(40, 68, "PALE"); c.put(41, 69, "PALE")
    c.put(41, 71, "PALE"); c.put(42, 73, "SKIN_PALE")
    # left eye (x39..45)
    c.rect(40, 72, 44, 76, "PALE")
    c.line(39, 71, 45, 71, "VOID", 1)                       # lash line
    c.put(39, 72, "VOID"); c.put(45, 72, "VOID")
    c.rect(41, 73, 43, 76, "GREEN")                         # iris
    c.line(41, 73, 43, 73, "DEEP_GREEN", 1)                 # iris top shade
    c.put(42, 74, "VOID"); c.put(42, 75, "VOID")            # pupil
    c.put(41, 74, "PALE_GOLD")                              # catchlight
    c.line(41, 76, 43, 76, "LIME", 1)                       # torch underlight
    c.put(40, 76, "SKIN_LIGHT"); c.put(44, 76, "SKIN_LIGHT")
    c.line(40, 77, 44, 77, "SKIN_SHADOW", 1)                # lower lid
    # right eye (x47..53)
    c.rect(48, 72, 52, 76, "PALE")
    c.line(47, 71, 53, 71, "VOID", 1)
    c.put(47, 72, "VOID"); c.put(53, 72, "VOID")
    c.rect(49, 73, 51, 76, "GREEN")
    c.line(49, 73, 51, 73, "DEEP_GREEN", 1)
    c.put(50, 74, "VOID"); c.put(50, 75, "VOID")
    c.put(49, 74, "PALE_GOLD")
    c.line(49, 76, 51, 76, "LIME", 1)
    c.put(48, 76, "SKIN_LIGHT"); c.put(52, 76, "SKIN_LIGHT")
    c.line(48, 77, 52, 77, "SKIN_SHADOW", 1)
    # tiny nose
    c.put(46, 78, "SKIN_SHADOW")
    # stoic mouth — closed, level, a veteran's set jaw
    c.line(43, 80, 49, 80, "VOID", 1)
    c.line(44, 81, 48, 81, "SKIN_SHADOW", 1)                # underlip
    # torch underlight from below-left, hard on the scarred brow side
    c.line(38, 74, 39, 79, "SKIN_PALE", 1)                  # left jaw kiss
    c.put(39, 73, "SKIN_PALE")                              # cheekbone
    c.put(37, 70, "PALE_GOLD")                              # brow rim
    c.line(42, 83, 47, 83, "SKIN_PALE", 1)                  # chin underlight

    # --- cool rim light on the trailing right edge ---
    c.line(81, 150, 82, 154, "PALE", 1)                     # rear thigh edge
    c.line(90, 174, 91, 180, "PALE", 1)                     # greave edge

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- boar spear: planted guard — near-vertical beside him, tip high ---
    c.line(15, 56, 20, 16, "UMBER", 2)
    c.line(14, 55, 19, 16, "BROWN", 1)                      # lit edge
    c.ellipse(15, 57, 2, 1, "BRONZE")                       # butt cap
    c.put(12, 58, "DUSK"); c.put(18, 58, "DUSK")            # ground chips
    # steel leaf blade at the top, clear of the silhouette
    c.poly([(21, 2), (17, 8), (20, 15), (24, 8)], "STEEL")
    c.line(19, 4, 18, 9, "PALE", 1)
    c.put(21, 2, "PALE"); c.put(20, 3, "PALE")              # point
    c.put(22, 9, "SLATE"); c.put(21, 12, "SLATE")           # shaded face
    c.line(16, 16, 23, 16, "STEEL", 2)                      # cross-lug

    # --- legs: steel greaves over the gambeson, boots on pivot (32,60) ---
    c.rect(24, 50, 28, 56, "STEEL")                         # front greave
    c.rect(35, 50, 39, 56, "STEEL")                         # rear greave
    c.line(28, 50, 28, 56, "SLATE", 1)                      # shade columns
    c.line(39, 50, 39, 56, "SLATE", 1)
    c.put(24, 51, "PALE"); c.put(24, 52, "PALE")            # lit flutes
    c.put(35, 51, "PALE")
    c.line(24, 53, 27, 53, "SLATE", 1)                      # plate ridges
    c.line(35, 53, 38, 53, "SLATE", 1)
    c.rect(22, 57, 29, 59, "UMBER")                         # boots
    c.rect(34, 57, 41, 59, "UMBER")
    c.line(22, 57, 29, 57, "BROWN", 1)
    c.line(34, 57, 41, 57, "BROWN", 1)

    # --- boiled-leather torso: one BROWN mass with UMBER shadow ---
    c.poly([(24, 36), (40, 36), (42, 50), (22, 50)], "BROWN")
    c.poly([(36, 37), (40, 36), (42, 50), (37, 50)], "UMBER")        # right shade
    c.line(24, 38, 24, 48, "BRONZE", 1)                     # lit edge
    c.line(23, 48, 41, 48, "UMBER", 1)                      # belt
    c.put(30, 48, "BRONZE")                                 # buckle
    # tiny deep-green tabard tail
    c.rect(28, 50, 33, 54, "DEEP_GREEN")
    c.line(28, 54, 33, 54, "LIME", 1)

    # --- arms: green sleeves + steel bracers; right fist grips the shaft ---
    c.line(25, 39, 19, 41, "GREEN", 3)                      # spear arm
    c.put(19, 40, "STEEL"); c.put(20, 41, "STEEL")          # bracer
    c.ellipse(17, 42, 2, 2, "SKIN")                         # fist on shaft
    c.line(39, 40, 41, 45, "GREEN", 3)                      # rear arm at side
    c.put(40, 44, "STEEL"); c.put(41, 45, "STEEL")          # bracer
    c.ellipse(41, 47, 2, 2, "SKIN")                         # rested fist
    c.ellipse(40, 38, 3, 2, "STEEL")                        # pauldron
    c.put(42, 39, "SLATE")

    # --- head: bronze crop block + 1px green headband ---
    c.ellipse(30, 26, 9, 8, "SKIN_LIGHT")                   # face
    c.ellipse(30, 19, 10, 5, "BRONZE")                      # bronze crop
    c.poly([(21, 19), (24, 13), (27, 19)], "BRONZE")        # tufts
    c.poly([(27, 14), (31, 11), (33, 18)], "BRONZE")
    c.poly([(34, 13), (38, 16), (36, 20)], "BROWN")         # right tuft in shade
    c.line(36, 16, 38, 18, "UMBER", 1)                      # tuft shade
    c.line(37, 18, 40, 21, "UMBER", 1)                      # right shade
    c.put(28, 13, "BROWN"); c.put(31, 14, "BROWN")          # tuft separations
    # headband: 1px green band with a knot tail
    c.line(22, 22, 38, 22, "GREEN", 1)
    c.put(25, 22, "LIME"); c.put(26, 22, "LIME")
    c.put(39, 22, "DEEP_GREEN"); c.put(40, 23, "DEEP_GREEN")  # knot
    c.put(41, 21, "GREEN")                                  # tail tick

    # --- chibi face: green-eyed stoic set ---
    c.rect(25, 25, 26, 27, "VOID")                          # left eye
    c.put(25, 25, "GREEN")
    c.put(25, 24, "PALE")
    c.rect(33, 25, 34, 27, "VOID")                          # right eye
    c.put(33, 25, "GREEN")
    c.put(33, 24, "PALE")
    c.put(24, 24, "BROWN"); c.put(35, 24, "BROWN")          # brow ticks
    c.put(24, 26, "SKIN_PALE")                              # scar hint
    c.line(29, 30, 32, 30, "VOID", 1)                       # stoic closed mouth
    c.put(29, 31, "SKIN_SHADOW")                            # underlip

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
    save(key, os.path.join(out, "vanguard_1_key.png"), 1)
    save(key, os.path.join(out, "vanguard_1_key@3x.png"), 3)
    save(iso, os.path.join(out, "vanguard_1_iso.png"), 1)
    save(iso, os.path.join(out, "vanguard_1_iso@4x.png"), 4)
    print("vanguard_1: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
