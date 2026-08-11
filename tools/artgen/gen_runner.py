"""runner — Snik, kobold sprinter.

Key art: full-tilt sprint caught mid-leap over a broken flagstone — body
horizontal and low on a rising diagonal, both legs kicked back, whip-thin
tail streaming straight behind (bronze ring), rusty dagger in a reverse
grip at the hip, free claw raking the air ahead. Ragged crimson hood
whipped back off one long notched ear, mouth open in a needle-toothed
cackle, wide coral eye gleaming with panicked glee.

Enemy color discipline: cool SLATE/DUSK hide with a GRAY belly — the one
hostile warm accent is the ragged WINE/CRIMSON hood plus CORAL eye glint
(bronze dagger + umber strap stay as small prop-material contrast).

Iso: chibi mid-sprint stride facing lane-right — crimson hood over a long
slate snout, daylight between the stride legs, tail counter-curve with
bronze ring, rusty bronze dagger arm extended ahead. Smallest silhouette
in the enemy roster.

Run from repo root: python3 tools/artgen/gen_runner.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- broken flagstone below the leap: two tilted halves + rubble ---
    c.poly([(18, 182), (60, 172), (66, 188), (24, 200)], "SLATE")   # left half
    c.poly([(24, 200), (66, 188), (66, 196), (24, 207)], "DUSK")    # side face
    c.line(20, 184, 58, 175, "STEEL", 1)                            # lit top edge
    c.line(48, 178, 54, 186, "DUSK", 1)                             # surface crack
    c.put(34, 186, "GRAY"); c.put(42, 182, "GRAY"); c.put(28, 192, "GRAY")
    c.poly([(72, 180), (108, 184), (104, 200), (68, 196)], "SLATE") # right half
    c.poly([(68, 196), (104, 200), (103, 205), (68, 201)], "DUSK")
    c.line(74, 182, 106, 186, "STEEL", 1)
    c.put(86, 190, "GRAY"); c.put(96, 194, "GRAY")
    # rubble in the break gap
    c.rect(64, 194, 68, 197, "GRAY")
    c.put(62, 200, "SLATE"); c.put(71, 202, "SLATE"); c.put(66, 190, "STEEL")

    # --- motion dust behind the take-off (kept clear of the feet) ---
    c.line(8, 132, 14, 130, "STEEL", 1)
    c.line(4, 148, 10, 146, "STEEL", 1)
    c.put(18, 118, "PALE"); c.put(6, 140, "PALE"); c.put(10, 164, "STEEL")

    # --- tail: whip-thin, streaming straight behind ABOVE the legs ---
    c.line(52, 121, 30, 125, "SLATE", 2)
    c.line(30, 125, 14, 128, "SLATE", 1)
    c.put(12, 128, "DUSK"); c.put(10, 129, "DUSK")                  # tip
    c.rect(18, 126, 19, 129, "BRONZE")                              # tail ring bulge
    c.put(18, 126, "GOLD")                                          # ring glint

    # --- far leg (shadow side, DUSK) kicked back, below the near leg ---
    c.line(54, 126, 44, 141, "DUSK", 4)
    c.line(44, 141, 33, 153, "DUSK", 3)
    c.poly([(32, 150), (22, 155), (20, 160), (30, 159)], "DUSK")    # bare far foot
    c.line(21, 154, 18, 152, "PALE", 1)                             # far claws
    c.put(18, 157, "PALE"); c.put(19, 160, "PALE")

    # --- torso: horizontal and low, cool slate hide ---
    c.poly([(78, 90), (88, 100), (84, 112), (66, 126), (52, 132),
            (46, 124), (58, 106), (70, 94)], "SLATE")
    c.poly([(84, 108), (68, 122), (56, 128), (52, 125), (66, 116),
            (80, 104)], "GRAY")                                     # pale gray belly
    c.line(54, 129, 68, 124, "DUSK", 1)                             # belly underline
    c.line(70, 122, 82, 111, "DUSK", 1)
    c.put(70, 98, "STEEL"); c.put(62, 106, "STEEL")                 # scale glints
    c.put(74, 96, "STEEL")

    # --- scrap-leather harness: umber strap + bronze buckle bits ---
    c.line(80, 98, 56, 122, "UMBER", 3)
    c.line(82, 100, 58, 124, "VOID", 1)                             # strap edge
    c.rect(67, 110, 69, 112, "BRONZE")                              # buckle
    c.put(67, 110, "PALE_GOLD")
    c.put(74, 104, "BRONZE")                                        # rivet

    # --- near leg (lit side) kicked back, clearly separated from far leg ---
    c.line(58, 118, 47, 131, "SLATE", 5)
    c.line(47, 131, 35, 141, "SLATE", 4)
    c.poly([(34, 137), (24, 141), (22, 146), (32, 146)], "SLATE")   # bare near foot
    c.line(38, 140, 46, 133, "DUSK", 1)                             # shin underside
    c.line(56, 118, 48, 128, "STEEL", 1)                            # lit thigh edge
    c.line(58, 116, 48, 128, "VOID", 1)                             # hip crease
    c.line(23, 140, 20, 138, "PALE", 1)                             # near claws
    c.line(22, 143, 18, 143, "PALE", 1)
    c.put(21, 146, "PALE")

    # --- near arm: raking the air ahead, clear below the jaw ---
    c.line(82, 100, 94, 114, "SLATE", 5)
    c.line(94, 114, 107, 119, "SLATE", 4)
    c.line(92, 117, 103, 122, "DUSK", 1)                            # underside
    c.ellipse(110, 119, 3, 3, "SLATE")                              # hand
    c.line(113, 116, 117, 112, "PALE", 1)                           # claw 1
    c.line(114, 119, 119, 118, "PALE", 1)                           # claw 2
    c.line(113, 122, 117, 125, "PALE", 1)                           # claw 3

    # --- neck + head base ---
    c.line(78, 94, 86, 86, "SLATE", 5)
    c.ellipse(91, 80, 11, 10, "SLATE")

    # --- ragged crimson hood over the cranium (face stays open) ---
    c.poly([(103, 68), (96, 60), (84, 57), (74, 60), (66, 66),
            (70, 72), (60, 74), (68, 80), (64, 90), (74, 88),
            (78, 96), (84, 94), (90, 92), (96, 84), (100, 76)], "CRIMSON")
    c.poly([(60, 86), (74, 86), (76, 94), (58, 94)], "CRIMSON")     # drape fill
    c.curve([(101, 70), (99, 74)], "WINE", 2)                       # rim shadow
    c.put(90, 87, "WINE"); c.put(88, 89, "WINE")                    # rim, below eye
    c.poly([(70, 74), (66, 84), (74, 84)], "WINE")                  # fold depth
    c.curve([(72, 62), (82, 58), (94, 62)], "CORAL", 2)             # lit crest
    c.put(67, 67, "CORAL"); c.put(61, 74, "CORAL")                  # tatter tips
    # hood cloth streaming off the shoulder, stretched by the wind
    c.poly([(76, 92), (60, 88), (46, 92), (58, 97), (70, 99), (80, 97)], "CRIMSON")
    c.poly([(62, 93), (50, 93), (60, 96)], "WINE")

    # --- one long notched ear streaming back through a hood hole ---
    c.poly([(77, 59), (68, 51), (58, 46), (46, 42), (52, 49),
            (62, 54), (70, 60), (76, 66)], "SLATE")
    for x, y in ((60, 46), (61, 46), (60, 47), (61, 47), (62, 47)):
        c.px[y][x] = None                                           # notch bite
    c.line(70, 58, 56, 49, "DUSK", 1)                               # inner ear
    c.line(73, 55, 68, 51, "STEEL", 1)                              # lit top edge
    c.put(76, 60, "WINE"); c.put(75, 63, "WINE")                    # torn hole rim

    # --- wind streaks trailing the sprint ---
    c.line(38, 64, 48, 62, "STEEL", 1)
    c.line(30, 78, 41, 76, "STEEL", 1)
    c.put(34, 70, "PALE")

    # --- snout: scaly slate hide, open needle-toothed cackle ---
    c.poly([(98, 77), (116, 84), (117, 89), (99, 90)], "SLATE")     # upper jaw
    c.line(99, 78, 114, 84, "STEEL", 1)                             # lit snout top
    c.put(112, 86, "VOID")                                          # nostril
    c.poly([(99, 90), (116, 89), (111, 99), (100, 96)], "WINE")     # open mouth
    c.put(104, 93, "CORAL"); c.put(105, 94, "CORAL")                # tongue glint
    c.poly([(98, 94), (110, 99), (108, 102), (96, 97)], "SLATE")    # lower jaw
    c.line(98, 99, 106, 102, "DUSK", 1)                             # jaw underside
    for x in (102, 105, 108, 111):                                  # upper teeth
        c.put(x, 91, "PALE")
    for x, y in ((101, 96), (104, 97), (107, 98)):                  # lower teeth
        c.put(x, y, "PALE")

    # --- wide coral eye, hostile glint (after hood so it stays on top) ---
    c.ellipse(95, 78, 5, 5, "VOID")                                 # eye rim
    c.ellipse(95, 78, 4, 4, "CORAL")                                # iris
    c.line(94, 75, 97, 76, "WINE", 1)                               # iris top shade
    c.rect(96, 78, 97, 79, "VOID")                                  # pupil, ahead
    c.put(92, 75, "PALE_GOLD"); c.put(93, 75, "PALE_GOLD")          # catchlight
    c.put(92, 76, "PALE_GOLD")
    c.put(94, 81, "GOLD")                                           # fire glint
    c.curve([(89, 71), (95, 70), (100, 73)], "VOID", 1)             # raised brow

    # --- dagger arm: drawn LAST so nothing buries it ---------------------
    # upper arm + forearm dropping from the far shoulder to the hip
    c.line(78, 101, 71, 112, "DUSK", 4)
    c.line(71, 112, 66, 120, "DUSK", 3)
    c.line(80, 103, 73, 113, "VOID", 1)                             # arm/torso split
    # crossguard first (fist overlaps its top), VOID-split from the belly
    c.line(56, 130, 66, 134, "VOID", 1)                             # guard shadow
    c.line(57, 128, 66, 132, "UMBER", 2)                            # crossguard
    c.put(56, 129, "BRONZE")                                        # guard tip glint
    # clenched fist at the hip, reverse grip
    c.ellipse(64, 124, 4, 4, "VOID")                                # fist rim
    c.ellipse(64, 124, 3, 3, "SLATE")                               # gripping fist
    c.put(62, 122, "STEEL")                                         # knuckle glint
    c.put(69, 116, "VOID"); c.put(70, 117, "VOID")                  # pommel split
    c.rect(67, 118, 68, 120, "BROWN")                               # wrapped grip
    c.put(67, 119, "UMBER")                                         # wrap line
    c.put(69, 117, "BRONZE")                                        # pommel cap
    # bronze blade pointing back-down into open air
    c.line(59, 133, 52, 146, "BRONZE", 3)
    c.line(52, 146, 49, 153, "BRONZE", 2)
    c.put(48, 155, "BRONZE"); c.put(47, 156, "BRONZE")              # tip
    c.put(57, 134, "GOLD"); c.put(55, 139, "GOLD")                  # worn lit glints
    c.put(52, 145, "GOLD")
    c.put(59, 135, "UMBER"); c.put(57, 139, "UMBER")                # rust pitting
    c.put(55, 143, "UMBER"); c.put(52, 148, "UMBER")
    c.put(50, 152, "UMBER")

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- tail counter-curve: sweeps down then whips back up behind him ---
    c.curve([(27, 37), (20, 41), (14, 39), (10, 32)], "SLATE", 2)
    c.put(9, 30, "DUSK"); c.put(8, 29, "DUSK")                      # tip
    c.rect(13, 37, 14, 40, "BRONZE")                                # tail ring bulge
    c.put(13, 37, "GOLD")                                           # ring glint

    # --- back leg (far, DUSK) trailing airborne — clear gap to front leg ---
    c.line(29, 44, 23, 51, "DUSK", 3)
    c.rect(17, 51, 23, 53, "DUSK")                                  # back foot, lifted
    c.put(16, 51, "PALE"); c.put(16, 53, "PALE")                    # bare claws

    # --- front leg (near, SLATE) reaching into the stride, planting ---
    c.line(33, 44, 39, 52, "SLATE", 3)
    c.line(39, 52, 42, 57, "SLATE", 3)
    c.rect(41, 58, 47, 60, "SLATE")                                 # front foot down
    c.put(48, 58, "PALE"); c.put(48, 60, "PALE")                    # bare claws
    c.line(34, 44, 38, 50, "STEEL", 1)                              # lit thigh edge

    # --- torso leaned hard forward, pale gray belly toward the lane ---
    c.poly([(26, 42), (28, 33), (36, 30), (41, 36), (37, 45), (29, 46)], "SLATE")
    c.poly([(38, 36), (41, 38), (37, 45), (33, 44)], "GRAY")        # belly
    c.line(28, 34, 26, 41, "DUSK", 1)                               # back shadow
    c.line(30, 32, 35, 31, "STEEL", 1)                              # lit shoulder
    c.line(28, 42, 36, 34, "UMBER", 2)                              # harness strap
    c.put(32, 38, "BRONZE")                                         # buckle
    c.put(32, 38, "PALE_GOLD")                                      # buckle glint

    # --- free arm (far, DUSK) swinging back for balance ---
    c.line(29, 34, 23, 39, "DUSK", 2)
    c.put(21, 40, "PALE"); c.put(20, 41, "PALE")                    # claws

    # --- dagger arm extended ahead, rusty bronze blade angled down ---
    c.line(37, 36, 44, 40, "SLATE", 3)                              # arm thrust out
    c.rect(44, 39, 47, 42, "SLATE")                                 # fist
    c.put(44, 39, "STEEL")                                          # knuckle glint
    c.rect(47, 43, 50, 43, "UMBER")                                 # crossguard
    c.put(46, 42, "BRONZE")                                         # pommel cap
    c.line(49, 45, 54, 52, "BRONZE", 2)                             # bronze blade
    c.put(55, 53, "BRONZE"); c.put(55, 54, "BRONZE")                # tip
    c.put(49, 45, "GOLD"); c.put(51, 48, "GOLD")                    # worn lit edge
    c.put(51, 47, "UMBER"); c.put(53, 51, "UMBER")                  # rust pitting

    # --- head: big crimson hood, slate snout thrust into stride direction ---
    c.ellipse(33, 21, 10, 9, "CRIMSON")                             # hood dome
    c.poly([(24, 26), (20, 33), (27, 30)], "CRIMSON")               # ragged hem
    c.poly([(29, 29), (26, 36), (33, 32)], "WINE")                  # hem underlayer
    c.curve([(41, 18), (43, 24), (40, 29)], "WINE", 2)              # rim shadow
    c.curve([(26, 15), (32, 13), (38, 15)], "CORAL", 1)             # lit crest
    c.put(23, 27, "CORAL"); c.put(20, 33, "CORAL")                  # tatter tips
    # long slate snout, open needle-toothed jaw pointing lane-right
    c.poly([(40, 20), (56, 24), (56, 27), (40, 28)], "SLATE")       # upper snout
    c.line(41, 21, 54, 24, "STEEL", 1)                              # lit snout top
    c.put(54, 25, "VOID")                                           # nostril
    c.poly([(42, 28), (55, 27), (50, 33), (42, 31)], "WINE")        # open mouth
    for x, y in ((45, 28), (48, 29), (51, 28)):                     # needle teeth
        c.put(x, y, "PALE")
    c.poly([(41, 31), (49, 33), (46, 36), (40, 34)], "SLATE")       # lower jaw
    c.line(41, 35, 45, 36, "DUSK", 1)                               # jaw underside
    # wide coral eye under the hood brim
    c.rect(36, 20, 39, 23, "VOID")                                  # eye rim
    c.rect(37, 21, 38, 22, "CORAL")                                 # iris glint
    c.put(38, 22, "VOID")                                           # pupil, ahead
    c.put(37, 21, "PALE_GOLD")                                      # catchlight

    # --- long notched ear streaming back out of the hood ---
    c.poly([(30, 13), (22, 8), (14, 4), (19, 11), (27, 16)], "SLATE")
    for x, y in ((21, 8), (22, 8), (22, 9)):
        c.px[y][x] = None                                           # notch bite
    c.line(26, 13, 19, 9, "DUSK", 1)                                # inner ear
    c.put(29, 14, "WINE")                                           # torn hood rim

    # --- dust puffs behind the stride (above the foot line) ---
    c.put(10, 52, "GRAY"); c.put(7, 47, "STEEL"); c.put(5, 53, "GRAY")
    c.put(16, 55, "GRAY")

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
    save(key, os.path.join(out, "runner_key.png"), 1)
    save(key, os.path.join(out, "runner_key@3x.png"), 3)
    save(iso, os.path.join(out, "runner_iso.png"), 1)
    save(iso, os.path.join(out, "runner_iso@4x.png"), 4)
    print("runner: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
