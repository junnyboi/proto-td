"""guard_2 — Vessaryn Thal, dark-elf blade-dancer.

Key art: low killing pirouette — coiled on the ball of one pointed foot, the
other leg swept out at full extension an inch off the floor, torso wound
tight. One blade reversed-grip flat along her forearm, the other arm arced
overhead with the second blade horizontal; both edges trace thin wine-red
afterimage circles. Ink-black hime cut fanned by the spin; she looks back
over her shoulder at the viewer, glacially calm.

Iso: chibi cross-blade stance — one blade low-forward, one raised behind,
weight on the front foot, hime-cut helmet silhouette with square sidelocks.

Run from repo root: python3 tools/artgen/gen_guard_2.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- afterimage arcs traced by the high blade (broken, motion-dashed) ---
    c.curve([(114, 68), (106, 46), (92, 34)], "WINE", 1)
    c.curve([(58, 30), (40, 38), (30, 54), (26, 72)], "WINE", 1)
    c.put(108, 52, "CRIMSON"); c.put(98, 38, "CRIMSON")
    c.put(46, 34, "CRIMSON"); c.put(28, 62, "CRIMSON")
    c.put(89, 32, "CRIMSON"); c.put(86, 31, "CORAL")      # arc tail fade

    # --- back hair: three pointed banners fanned viewer-left by the spin ---
    c.poly([(60, 64), (44, 68), (30, 78), (22, 94), (32, 92), (44, 82),
            (54, 74)], "VOID")                            # upper banner
    c.poly([(56, 72), (40, 88), (30, 106), (24, 122), (34, 116), (44, 100),
            (52, 86)], "VOID")                            # mid banner
    c.poly([(60, 82), (54, 100), (52, 118), (50, 132), (56, 120), (61, 104),
            (63, 90)], "VOID")                            # low banner, hugs torso
    c.poly([(58, 66), (48, 72), (44, 84), (52, 82), (58, 74)], "VOID")  # root web
    # dusk sheen where the top-left key light rakes each banner's top edge
    c.curve([(52, 66), (40, 71), (30, 80)], "DUSK", 1)
    c.curve([(50, 78), (40, 90), (33, 102)], "DUSK", 1)
    c.curve([(58, 86), (54, 102), (52, 116)], "DUSK", 1)
    c.put(26, 90, "DUSK"); c.put(28, 114, "DUSK"); c.put(51, 126, "DUSK")
    # a short fan on the trailing right side, clear of the sidelock
    c.poly([(80, 64), (90, 70), (96, 84), (88, 82), (82, 72)], "VOID")
    c.put(88, 72, "DUSK"); c.put(91, 78, "DUSK")

    # --- swept leg: one straight full extension, an inch off the floor ---
    c.line(60, 150, 34, 164, "CRIMSON", 5)                # thigh body tone
    c.line(34, 164, 14, 174, "CRIMSON", 4)                # shin
    c.poly([(13, 171), (17, 177), (7, 181), (3, 180)], "CRIMSON")  # pointed foot
    c.line(59, 147, 36, 160, "CORAL", 2)                  # lit top panel
    c.line(37, 166, 16, 176, "WINE", 2)                   # underside shadow
    c.line(36, 167, 18, 176, "VOID", 1)                   # core shadow line
    c.line(49, 151, 52, 159, "BROWN", 2)                  # thigh strap
    c.put(52, 158, "UMBER"); c.put(51, 154, "UMBER")

    # --- pivot leg: deep fold — thigh horizontal, shin down to a pointed toe ---
    c.line(68, 148, 88, 152, "CRIMSON", 6)                # thigh, horizontal
    c.line(88, 152, 80, 190, "CRIMSON", 4)                # shin folded down
    c.poly([(76, 188), (83, 190), (79, 199), (74, 206), (72, 199)], "CRIMSON")
    c.line(70, 145, 88, 149, "CORAL", 2)                  # lit top panel
    c.line(69, 151, 87, 154, "WINE", 1)                   # thigh underside shadow
    c.line(88, 158, 81, 186, "WINE", 2)                   # calf shadow side
    c.line(89, 158, 82, 186, "VOID", 1)                   # core shadow line
    c.poly([(74, 198), (78, 196), (74, 205)], "WINE")     # shadowed foot tip
    c.rect(80, 147, 82, 154, "BROWN")                     # thigh strap
    c.line(82, 148, 82, 153, "UMBER", 1)

    # --- torso: crimson bodysuit wound tight, 3-tone fire ramp ---
    c.poly([(58, 102), (80, 100), (82, 114), (76, 128), (74, 138), (62, 138),
            (56, 118)], "CRIMSON")                        # body tone
    c.poly([(74, 102), (80, 100), (82, 114), (76, 126), (73, 126),
            (76, 112)], "WINE")                           # shadowed right flank
    c.poly([(58, 102), (69, 101), (67, 111), (59, 113)], "CORAL")  # lit chest panel
    c.line(62, 115, 72, 114, "WINE", 1)                   # under-bust shade
    c.line(59, 122, 64, 125, "WINE", 1)                   # twist fold
    c.line(70, 128, 74, 126, "WINE", 1)                   # twist fold
    c.rect(62, 134, 74, 138, "WINE")                      # waist-wrap shadow
    c.curve([(68, 103), (66, 118), (65, 131)], "GOLD", 1) # gold piping
    c.line(59, 133, 75, 132, "GOLD", 1)                   # waist cord
    c.curve([(73, 133), (77, 141), (74, 149)], "GOLD", 1) # cord tassel
    # articulated leather shoulder caps
    c.ellipse(59, 104, 3, 3, "BROWN"); c.line(57, 106, 62, 106, "UMBER", 1)
    c.ellipse(79, 102, 3, 3, "BROWN"); c.line(77, 104, 82, 104, "UMBER", 1)
    # hips, low and compact, split crease between the working legs
    c.poly([(60, 138), (74, 138), (76, 150), (58, 150)], "CRIMSON")
    c.line(60, 139, 70, 139, "CORAL", 1)                  # hip top light
    c.poly([(70, 140), (74, 139), (76, 150), (69, 150)], "WINE")  # shadowed hip
    c.line(60, 149, 75, 149, "WINE", 1)
    c.line(66, 141, 67, 148, "VOID", 1)

    # --- left arm: reversed-grip blade tucked flat along the forearm ---
    c.line(58, 107, 52, 124, "SKIN_PALE", 4)              # bare upper arm
    c.line(55, 110, 52, 121, "SKIN_LIGHT", 1)             # arm shade
    c.line(52, 124, 45, 138, "CRIMSON", 4)                # crimson bracer
    c.line(53, 127, 46, 139, "WINE", 1)                   # bracer shadow edge
    c.line(50, 124, 44, 136, "CORAL", 1)                  # lit top edge
    c.line(46, 132, 50, 130, "GOLD", 1)                   # bracer piping
    c.ellipse(45, 141, 2, 2, "SKIN_PALE")                 # fist
    c.put(44, 140, "SKIN_LIGHT")
    # the reversed blade: curved, tapered, flat along the forearm's outer edge
    c.curve([(41, 146), (43, 132), (48, 118)], "STEEL", 2)
    c.curve([(39, 145), (41, 131), (46, 117)], "PALE", 1)
    c.put(49, 114, "STEEL"); c.put(48, 113, "PALE")       # tip taper
    c.put(50, 111, "PALE")
    c.ellipse(44, 150, 1, 1, "GOLD")                      # ring pommel below fist
    c.put(44, 150, "VOID")

    # --- neck + head, turned back over the shoulder ---
    c.rect(64, 92, 70, 100, "SKIN_PALE")
    c.line(69, 93, 69, 99, "SKIN_LIGHT", 1)
    c.ellipse(67, 82, 10, 11, "SKIN_PALE")                # face, warm pale
    c.line(59, 90, 67, 92, "SKIN_LIGHT", 1)               # jaw shade

    # --- the near ear: a long dark-elf point breaking the hair line ---
    c.poly([(76, 81), (89, 76), (77, 87)], "SKIN_PALE")
    c.line(79, 84, 87, 78, "SKIN_LIGHT", 1)
    c.put(78, 85, "GOLD")                                 # THE gold ear stud

    # --- hime cut: crown, straight blunt bangs, square sidelocks ---
    c.ellipse(67, 69, 12, 8, "VOID")                      # crown
    c.curve([(58, 64), (66, 61), (74, 63)], "DUSK", 2)    # crown sheen
    c.rect(56, 66, 78, 74, "VOID")                        # blunt bangs, straight
    c.put(62, 75, "VOID"); c.put(68, 75, "VOID"); c.put(74, 75, "VOID")
    c.put(59, 69, "DUSK"); c.put(63, 68, "DUSK"); c.put(60, 70, "DUSK")
    c.rect(53, 67, 57, 96, "VOID")                        # left sidelock
    c.line(53, 71, 53, 92, "DUSK", 1)                     # lit outer edge
    c.rect(77, 67, 81, 96, "VOID")                        # right sidelock
    c.put(78, 69, "DUSK"); c.put(78, 74, "DUSK")

    # --- face: calm and resolute, warm coral-gold anime eyes ---
    c.line(59, 77, 64, 77, "VOID", 1)                     # level brows
    c.line(69, 77, 75, 77, "VOID", 1)
    # far eye (viewer-left, slightly narrower in 3/4)
    c.rect(60, 79, 64, 84, "PALE")
    c.line(59, 78, 65, 78, "VOID", 1)
    c.rect(61, 79, 63, 84, "CORAL")
    c.line(61, 84, 63, 84, "GOLD", 1)                     # warm iris glow
    c.rect(62, 81, 62, 82, "VOID")
    c.put(61, 80, "PALE_GOLD")                            # catchlight
    c.line(60, 85, 64, 85, "SKIN_LIGHT", 1)
    # near eye (viewer-right)
    c.rect(68, 79, 74, 84, "PALE")
    c.line(67, 78, 75, 78, "VOID", 1)
    c.rect(69, 79, 73, 84, "CORAL")
    c.line(69, 84, 73, 84, "GOLD", 1)                     # warm iris glow
    c.rect(71, 81, 72, 82, "VOID")
    c.put(69, 80, "PALE_GOLD"); c.put(70, 80, "PALE_GOLD")  # catchlight
    c.line(68, 85, 74, 85, "SKIN_LIGHT", 1)
    # tiny nose, faint knowing smile, the rose warm note
    c.put(66, 87, "SKIN_LIGHT")
    c.line(63, 90, 66, 90, "VOID", 1)
    c.put(67, 89, "VOID")                                 # upturned corner
    c.put(64, 91, "ROSE"); c.put(65, 91, "ROSE"); c.put(66, 91, "ROSE")
    c.put(61, 86, "ROSE"); c.put(73, 86, "ROSE")          # faint cheek warmth

    # --- right arm arced overhead with the horizontal blade ---
    c.line(79, 104, 91, 91, "SKIN_PALE", 4)               # bare upper arm
    c.line(89, 92, 93, 88, "SKIN_LIGHT", 1)
    c.line(91, 91, 100, 58, "CRIMSON", 4)                 # crimson bracer
    c.line(93, 90, 101, 60, "WINE", 1)                    # shadowed right edge
    c.line(89, 89, 98, 60, "CORAL", 1)                    # lit left edge
    c.line(96, 64, 100, 64, "GOLD", 1)                    # bracer piping
    # the horizontal blade, single-edged, gentle curve; grip in the hand
    c.curve([(44, 58), (62, 51), (82, 47), (98, 48)], "STEEL", 2)
    c.curve([(46, 56), (64, 49), (84, 45)], "PALE", 1)
    c.put(41, 59, "PALE"); c.put(39, 60, "PALE")          # tip taper
    c.line(99, 49, 107, 53, "BROWN", 2)                   # grip wrap
    c.ellipse(101, 51, 3, 3, "SKIN_PALE")                 # hand ON the grip
    c.put(99, 50, "SKIN_LIGHT")
    c.ellipse(110, 55, 2, 2, "GOLD")                      # ring pommel
    c.put(110, 55, "VOID")

    # --- low afterimage arcs traced by the swept leg (broken dashes) ---
    c.curve([(14, 192), (36, 203), (62, 208)], "WINE", 1)
    c.curve([(88, 204), (108, 194)], "WINE", 1)
    c.put(24, 198, "CRIMSON"); c.put(50, 206, "CRIMSON")
    c.put(98, 200, "CRIMSON")
    c.put(66, 208, "CRIMSON"); c.put(70, 207, "CORAL")    # arc tail fade

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- raised blade behind (viewer-left, high): thick clean crescent ---
    c.curve([(18, 25), (14, 18), (13, 12), (15, 6)], "STEEL", 2)
    c.curve([(16, 24), (12, 17), (11, 12), (13, 7)], "PALE", 1)   # back edge
    c.put(13, 15, "PALE_GOLD"); c.put(14, 9, "PALE_GOLD")         # edge highlight
    c.put(15, 6, "PALE_GOLD")                             # tip glint

    # --- legs: chunky, weight on the front foot ---
    c.line(29, 44, 27, 52, "CRIMSON", 4)                  # back leg
    c.rect(24, 52, 29, 56, "CRIMSON")                     # back foot
    c.rect(24, 55, 29, 56, "WINE")                        # foot shadow
    c.line(28, 46, 27, 51, "WINE", 1)                     # back leg in shadow
    c.line(35, 44, 35, 54, "CRIMSON", 4)                  # front leg (weight)
    c.rect(32, 54, 39, 58, "CRIMSON")                     # front foot
    c.rect(32, 57, 39, 58, "WINE")                        # foot shadow
    c.line(34, 45, 34, 53, "CORAL", 1)                    # lit thigh front

    # --- torso: crimson mass, 3-tone ramp + the gold waist cord ---
    c.rect(25, 32, 39, 45, "CRIMSON")
    c.rect(37, 33, 39, 45, "WINE")                        # shade right
    c.rect(25, 43, 39, 45, "WINE")                        # skirt shadow
    c.rect(27, 33, 31, 37, "CORAL")                       # lit chest panel
    c.line(25, 42, 39, 42, "GOLD", 1)                     # waist cord

    # --- arms: chunky bare warm-pale arms with distinct hands ---
    c.line(26, 35, 22, 29, "SKIN_PALE", 3)                # left arm raised back
    c.rect(19, 26, 22, 28, "SKIN_PALE")                   # left hand
    c.put(18, 26, "GOLD")                                 # ring pommel below grip
    c.line(24, 32, 22, 30, "SKIN_LIGHT", 1)               # arm shade
    c.line(39, 36, 42, 39, "SKIN_PALE", 3)                # right arm low forward
    c.rect(41, 39, 44, 41, "SKIN_PALE")                   # right hand
    c.put(43, 41, "SKIN_LIGHT")                           # hand shade
    # low-forward blade: thick single slash, tip flicked up
    c.curve([(45, 41), (50, 43), (55, 42), (59, 38)], "STEEL", 2)
    c.curve([(46, 40), (51, 42), (55, 41), (58, 37)], "PALE", 1)  # back edge
    c.put(50, 44, "PALE_GOLD"); c.put(55, 43, "PALE_GOLD")        # edge highlight
    c.put(59, 38, "PALE_GOLD")                            # tip glint
    c.put(44, 40, "GOLD")                                 # ring pommel

    # --- head: hime-cut helmet silhouette ---
    c.ellipse(32, 21, 8, 7, "SKIN_PALE")                  # face, warm pale
    c.curve([(27, 26), (32, 27), (37, 26)], "SKIN_LIGHT", 1)      # jaw shade
    c.ellipse(32, 14, 10, 8, "VOID")                      # hair crown
    c.rect(23, 12, 41, 17, "VOID")                        # blunt bangs
    c.rect(21, 12, 24, 27, "VOID")                        # left square sidelock
    c.rect(40, 12, 43, 27, "VOID")                        # right square sidelock
    c.curve([(26, 9), (32, 7), (38, 9)], "DUSK", 1)       # crown sheen
    c.line(22, 14, 22, 24, "DUSK", 1)                     # lit sidelock edge
    # 2px ear points breaking the hair outline
    c.put(19, 19, "SKIN_PALE"); c.put(18, 18, "SKIN_PALE")
    c.put(45, 19, "SKIN_PALE"); c.put(46, 18, "SKIN_PALE")
    c.put(45, 20, "GOLD")                                 # THE single stud pixel

    # --- chibi face: calm warm coral-gold eyes ---
    c.rect(27, 20, 28, 22, "VOID")
    c.put(27, 20, "CORAL"); c.put(27, 21, "GOLD")
    c.put(28, 19, "PALE_GOLD")                            # catchlight
    c.rect(36, 20, 37, 22, "VOID")
    c.put(36, 20, "CORAL"); c.put(36, 21, "GOLD")
    c.put(37, 19, "PALE_GOLD")                            # catchlight
    c.put(31, 25, "ROSE"); c.put(32, 25, "ROSE")          # small warm smile
    c.put(31, 23, "SKIN_LIGHT")                           # nose hint

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
    save(key, os.path.join(out, "guard_2_key.png"), 1)
    save(key, os.path.join(out, "guard_2_key@3x.png"), 3)
    save(iso, os.path.join(out, "guard_2_iso.png"), 1)
    save(iso, os.path.join(out, "guard_2_iso@4x.png"), 4)
    print("guard_2: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
