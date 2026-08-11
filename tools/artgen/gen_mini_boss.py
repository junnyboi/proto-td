"""mini_boss — The Warden, undead death knight (mini-boss).

Key art: the lord's advance — towering fluted full plate mid-stride toward
the viewer, unhurried. Greatsword dragged point-down behind him, carving a
glowing CRIMSON scratch and kicking GOLD sparks. Off-hand gauntlet clenched
at his side, wine cloak torn sideways in an unfelt wind, anvil-crowned helm
lowered so the CORAL/GOLD ember visor-slit glares up from under the brow.
No face, no skin: VOID abyss at every joint where a body should be.

Iso: chibi 3 heads, tallest cloaked silhouette on lanes, feet pivot at
(32, 60). Sword dragged point-down behind with a 1px CRIMSON scratch-glow
trail on the tile — his unique lane tell.

Run from repo root: python3 tools/artgen/gen_mini_boss.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- THE CLOAK: wine mass streaming sideways viewer-left, deepest layer ---
    c.poly([(46, 56), (76, 56), (70, 84), (62, 112),     # behind the torso
            (54, 138), (44, 166),                        # inner hem, clear of
            (38, 182), (34, 162),                        # the stride gap
            (28, 176), (24, 152),                        # shred
            (16, 168), (13, 142),                        # shred streaming left
            (8, 148), (7, 120), (14, 90), (28, 68)], "WINE")
    # ink folds pulled toward the lower-left wind
    c.curve([(50, 70), (36, 106), (24, 142)], "INK", 2)
    c.curve([(58, 76), (46, 118), (36, 156)], "INK", 2)
    c.curve([(30, 80), (17, 116), (11, 140)], "INK", 1)
    # shredded VOID-dark ends
    c.poly([(42, 168), (38, 182), (34, 164), (39, 156)], "VOID")
    c.poly([(31, 160), (28, 176), (24, 154), (28, 146)], "VOID")
    c.poly([(19, 152), (16, 168), (13, 144), (17, 138)], "VOID")
    c.poly([(11, 136), (8, 148), (7, 124), (10, 120)], "VOID")

    # --- THE GREATSWORD blade: dragged point-down behind, strong diagonal ---
    # (drawn before the trailing leg so the drag reads behind him)
    c.poly([(95, 132), (102, 130), (121, 199), (117, 203)], "STEEL")
    c.line(97, 136, 118, 201, "SLATE", 2)                # shadow half
    c.line(101, 133, 120, 198, "PALE", 1)                # key-lit edge
    # CRIMSON ember fuller running the length
    c.line(99, 136, 119, 200, "CRIMSON", 1)
    c.put(101, 144, "CORAL"); c.put(106, 160, "CORAL")
    c.put(111, 176, "CORAL"); c.put(116, 192, "CORAL")
    c.put(108, 168, "GOLD")                              # hottest pixel

    # --- trailing (viewer-right) leg: extended back, heel up, pushing off ---
    c.line(68, 124, 78, 146, "SLATE", 9)                 # cuisse
    c.line(65, 124, 74, 142, "STEEL", 2)
    c.rect(74, 144, 82, 148, "VOID")                     # knee abyss
    c.ellipse(79, 148, 5, 4, "SLATE")                    # poleyn
    c.put(76, 145, "STEEL")
    c.line(83, 154, 93, 178, "SLATE", 7)                 # greave, driven back
    c.line(86, 156, 95, 176, "DUSK", 3)
    c.line(80, 154, 89, 176, "STEEL", 1)
    c.rect(88, 178, 96, 181, "VOID")                     # ankle abyss
    # sabaton on its toe — pointed wedge digging into the stone
    c.poly([(88, 180), (98, 184), (104, 194), (94, 194), (86, 188)], "SLATE")
    c.line(90, 182, 100, 189, "STEEL", 1)
    c.line(90, 190, 101, 193, "DUSK", 2)

    # --- forward (viewer-left) leg: striding out toward the viewer ---
    c.line(58, 124, 44, 156, "SLATE", 10)                # cuisse
    c.line(53, 122, 41, 152, "STEEL", 2)                 # lit ridge
    c.line(62, 128, 49, 156, "DUSK", 3)
    c.rect(38, 154, 48, 158, "VOID")                     # knee abyss
    c.ellipse(43, 158, 6, 5, "STEEL")                    # poleyn fan
    c.ellipse(44, 159, 4, 3, "SLATE")
    c.put(40, 155, "PALE")
    c.line(40, 164, 36, 188, "SLATE", 8)                 # greave, fluted
    c.line(36, 164, 33, 186, "STEEL", 2)
    c.line(44, 166, 40, 188, "DUSK", 2)
    # big sabaton planted toward the viewer (foreshortened, wide)
    c.poly([(24, 188), (46, 188), (49, 198), (30, 204), (21, 197)], "SLATE")
    c.line(26, 189, 45, 189, "STEEL", 1)
    c.line(24, 199, 46, 196, "DUSK", 2)
    c.line(28, 192, 40, 192, "STEEL", 1)                 # toe plate seam

    # --- torso: fluted breastplate tapering to the waist ---
    c.poly([(44, 60), (78, 60), (82, 88), (74, 118), (52, 118), (42, 90)],
           "SLATE")
    # fluting: alternating lit ridges / dark grooves fanning down
    c.line(50, 64, 52, 112, "STEEL", 2)
    c.line(57, 64, 59, 114, "DUSK", 1)
    c.line(63, 63, 63, 114, "STEEL", 1)
    c.line(69, 64, 68, 114, "DUSK", 1)
    c.line(75, 66, 72, 112, "DUSK", 2)                   # off-light side
    c.poly([(74, 80), (82, 88), (74, 118), (68, 114)], "DUSK")  # rt mass shade
    c.curve([(46, 62), (62, 60), (76, 62)], "PALE", 1)   # collar glint
    # waist joint abyss + short faulds (thighs must stay visible)
    c.rect(50, 118, 74, 122, "VOID")
    c.poly([(46, 122), (78, 122), (81, 130), (74, 136), (50, 136), (43, 130)],
           "SLATE")
    c.line(46, 126, 78, 126, "DUSK", 1)                  # plate seam
    c.line(45, 131, 79, 131, "DUSK", 1)
    c.line(47, 124, 77, 124, "STEEL", 1)
    c.line(45, 133, 56, 135, "STEEL", 1)

    # --- off-hand (viewer-left) arm: slowly clenching at his side ---
    # VOID separation so the arm never melts into the cloak behind it
    c.line(35, 76, 27, 96, "VOID", 2)
    c.line(27, 98, 24, 118, "VOID", 2)
    c.line(40, 74, 33, 94, "SLATE", 7)                   # rerebrace
    c.line(37, 74, 31, 92, "STEEL", 2)
    c.rect(29, 94, 38, 98, "VOID")                       # elbow abyss
    c.line(32, 100, 30, 118, "SLATE", 6)                 # vambrace
    c.line(29, 102, 28, 116, "STEEL", 1)
    # clenched gauntlet — knuckle plates curling
    c.ellipse(30, 124, 5, 6, "STEEL")
    c.ellipse(31, 126, 4, 4, "SLATE")
    c.line(27, 121, 33, 120, "PALE", 1)
    c.put(28, 126, "DUSK"); c.put(30, 127, "DUSK"); c.put(32, 126, "DUSK")

    # --- sword arm (viewer-right): straight down to the low grip ---
    c.line(82, 74, 89, 96, "SLATE", 7)
    c.rect(85, 94, 93, 98, "VOID")                       # elbow abyss
    c.line(89, 100, 93, 114, "DUSK", 6)                  # vambrace in shadow
    c.line(86, 100, 90, 112, "SLATE", 2)

    # --- hilt assembly: pommel -> fist on grip -> crossguard -> blade root ---
    c.ellipse(91, 104, 3, 3, "DUSK"); c.put(90, 103, "STEEL")   # pommel
    c.line(92, 107, 95, 112, "DUSK", 3)                  # grip above the fist
    # fist wrapping the grip — VOID seam so it never melts into the vambrace
    c.line(90, 112, 99, 112, "VOID", 1)
    c.ellipse(95, 116, 5, 4, "SLATE")
    c.line(92, 113, 98, 113, "STEEL", 1)                 # knuckle-plate rim
    c.put(91, 115, "STEEL")
    c.put(93, 118, "DUSK"); c.put(96, 118, "DUSK")       # curled fingers
    c.line(96, 121, 97, 125, "DUSK", 2)                  # grip below the fist
    # cathedral crossguard, one clean bar perpendicular to the blade axis
    c.poly([(86, 127), (108, 122), (110, 126), (88, 131)], "DUSK")
    c.line(88, 127, 107, 123, "SLATE", 1)
    c.put(87, 128, "STEEL"); c.put(108, 124, "STEEL")    # guard tips

    # --- pauldrons: huge layered plates, lit left / shadowed right ---
    c.ellipse(42, 66, 13, 10, "SLATE")
    c.ellipse(40, 64, 11, 8, "STEEL")
    c.ellipse(42, 67, 9, 6, "SLATE")
    c.curve([(31, 60), (40, 56), (50, 58)], "PALE", 1)   # key-light rake
    c.line(33, 72, 49, 74, "DUSK", 1)                    # under-rim
    c.ellipse(82, 66, 12, 10, "SLATE")
    c.ellipse(84, 68, 9, 7, "DUSK")
    c.curve([(74, 58), (82, 57), (90, 60)], "STEEL", 1)  # dim rim light
    c.line(76, 74, 90, 74, "VOID", 1)

    # --- neck abyss: nothing between gorget and helm ---
    c.rect(52, 52, 70, 58, "VOID")

    # --- THE HELM: anvil-crowned, lowered, visor glaring up ---
    # anvil crown slab, wider than the skull block
    c.poly([(40, 22), (80, 22), (78, 32), (42, 32)], "SLATE")
    c.line(41, 23, 79, 23, "STEEL", 2)                   # lit top
    c.put(42, 22, "PALE"); c.put(43, 22, "PALE")
    c.line(42, 31, 78, 31, "DUSK", 1)                    # underside
    # skull block, tilted forward (head lowered)
    c.poly([(44, 32), (76, 32), (74, 54), (48, 54)], "SLATE")
    c.line(46, 34, 46, 50, "STEEL", 2)                   # lit left cheek
    c.poly([(68, 34), (76, 32), (74, 54), (66, 52)], "DUSK")    # rt shadow
    # brow shadow over the slit — the glare comes from under it
    c.rect(46, 36, 73, 39, "DUSK")
    c.line(46, 36, 73, 36, "VOID", 1)
    # THE VISOR SLIT: coral ember flaring to gold at its core
    c.rect(47, 40, 71, 42, "VOID")
    c.rect(48, 40, 70, 41, "CORAL")
    c.rect(54, 40, 64, 41, "GOLD")
    c.put(58, 40, "PALE_GOLD"); c.put(59, 40, "PALE_GOLD")
    c.line(48, 42, 70, 42, "CRIMSON", 1)                 # ember falloff
    # chin plate seam
    c.line(48, 48, 73, 47, "DUSK", 1)
    c.line(49, 53, 73, 52, "VOID", 1)

    # --- ember system: drifting sparks off the visor ---
    c.put(76, 38, "CORAL"); c.put(80, 34, "GOLD"); c.put(84, 30, "CRIMSON")
    c.put(44, 44, "CORAL"); c.put(41, 40, "CRIMSON")

    # --- the scratch: CRIMSON gouge carved into the flagstones behind ---
    c.curve([(118, 203), (122, 205), (127, 208)], "CRIMSON", 2)
    c.line(123, 209, 127, 211, "CRIMSON", 1)             # second gouge line
    c.put(120, 202, "CORAL"); c.put(123, 204, "CORAL"); c.put(126, 206, "CORAL")
    c.put(119, 201, "GOLD")
    # gold sparks kicked up off the drag point
    c.put(115, 196, "GOLD"); c.put(116, 195, "PALE_GOLD")
    c.put(123, 199, "GOLD"); c.put(126, 202, "PALE_GOLD")
    c.put(112, 190, "CRIMSON"); c.put(125, 195, "GOLD")
    c.put(121, 192, "PALE_GOLD")

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- cloak: solid wine wedge on viewer-left, breaking the biped line ---
    c.poly([(20, 21), (26, 23), (24, 38),
            (23, 50), (20, 56), (18, 46),                # shred
            (14, 52), (12, 40),                          # shred
            (10, 34), (13, 26)], "WINE")
    c.curve([(17, 30), (14, 42)], "INK", 2)
    c.curve([(22, 32), (21, 44)], "INK", 1)
    c.poly([(22, 48), (20, 56), (18, 46)], "VOID")       # shredded tips
    c.poly([(15, 46), (14, 52), (12, 42)], "VOID")

    # --- legs mid-stride: forward left planted, trailing right toe-down ---
    c.line(29, 45, 27, 53, "SLATE", 5)                   # forward greave
    c.line(27, 45, 26, 52, "STEEL", 1)
    c.poly([(23, 54), (32, 54), (33, 59), (24, 59)], "SLATE")   # sabaton
    c.line(24, 55, 32, 55, "STEEL", 1)
    c.line(25, 58, 32, 58, "DUSK", 1)
    c.line(36, 45, 39, 50, "DUSK", 4)                    # trailing greave
    c.poly([(37, 50), (44, 52), (43, 56), (36, 54)], "DUSK")    # toe down
    c.put(38, 51, "SLATE")

    # --- torso: plate slab with fluting ---
    c.poly([(22, 24), (42, 24), (43, 40), (40, 47), (25, 47), (21, 38)],
           "SLATE")
    c.line(24, 26, 24, 44, "STEEL", 2)                   # key-lit edge
    c.line(30, 25, 30, 45, "DUSK", 1)                    # flute groove
    c.line(35, 25, 35, 45, "STEEL", 1)
    c.poly([(39, 26), (42, 24), (43, 40), (39, 44)], "DUSK")    # rt shade
    c.line(23, 40, 42, 40, "VOID", 1)                    # waist abyss seam
    c.line(23, 42, 41, 42, "DUSK", 1)                    # fauld seam

    # --- off-hand clenched gauntlet ---
    c.ellipse(20, 34, 3, 4, "STEEL")
    c.put(19, 32, "PALE"); c.put(20, 36, "DUSK")

    # --- sword arm + THE GREATSWORD dragged behind (viewer-right) ---
    c.rect(44, 27, 46, 30, "DUSK")                       # grip, pommel up
    c.put(45, 26, "STEEL")                               # pommel
    c.ellipse(45, 32, 3, 3, "SLATE")                     # fist on grip
    c.put(43, 30, "STEEL")                               # knuckle light
    c.line(41, 36, 51, 34, "DUSK", 2)                    # crossguard below fist
    c.put(41, 36, "STEEL"); c.put(51, 34, "STEEL")
    c.poly([(45, 37), (49, 36), (57, 55), (53, 57)], "STEEL")   # blade
    c.line(48, 38, 55, 55, "SLATE", 1)
    c.line(47, 38, 54, 55, "CRIMSON", 1)                 # ember fuller
    c.put(49, 44, "CORAL"); c.put(52, 51, "CORAL")
    # 1px CRIMSON scratch-glow trail on the tile — the lane tell
    c.line(56, 58, 62, 60, "CRIMSON", 1)
    c.put(57, 57, "CORAL"); c.put(60, 58, "GOLD")
    c.put(55, 54, "GOLD")                                # kicked spark

    # --- pauldrons ---
    c.ellipse(23, 23, 6, 4, "STEEL")
    c.ellipse(24, 24, 4, 3, "SLATE")
    c.put(19, 21, "PALE")
    c.ellipse(41, 23, 6, 4, "SLATE")
    c.ellipse(42, 24, 4, 3, "DUSK")

    # --- neck abyss ---
    c.rect(28, 20, 36, 23, "VOID")

    # --- THE HELM: anvil crown + skull block, visor slit the face ---
    c.poly([(20, 4), (44, 4), (43, 9), (21, 9)], "SLATE")       # anvil slab
    c.line(21, 5, 43, 5, "STEEL", 1)
    c.put(22, 4, "PALE")
    c.line(22, 8, 42, 8, "DUSK", 1)
    c.poly([(23, 9), (41, 9), (40, 21), (24, 21)], "SLATE")     # skull block
    c.line(25, 10, 25, 19, "STEEL", 1)
    c.poly([(37, 10), (41, 9), (40, 21), (37, 20)], "DUSK")
    c.rect(25, 12, 39, 13, "DUSK")                       # brow shadow
    # THE 2px visor slit
    c.rect(25, 14, 39, 15, "CORAL")
    c.rect(29, 14, 35, 15, "GOLD")
    c.put(32, 14, "PALE_GOLD")
    c.line(26, 16, 38, 16, "CRIMSON", 1)                 # ember falloff
    c.line(26, 19, 38, 19, "DUSK", 1)                    # chin seam
    # one drifting spark
    c.put(42, 12, "CORAL")

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
    save(key, os.path.join(out, "mini_boss_key.png"), 1)
    save(key, os.path.join(out, "mini_boss_key@3x.png"), 3)
    save(iso, os.path.join(out, "mini_boss_iso.png"), 1)
    save(iso, os.path.join(out, "mini_boss_iso@4x.png"), 4)
    print("mini_boss: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
