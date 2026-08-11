"""caster_1 — Maribel Cindervein, hornblood fire-witch.

Key art: full-skirt casting twirl at its peak — pivot on one boot toe, other
foot kicked up behind, orchid skirt + coral hair fanning in a spiral, staff
swept in a wide arc trailing an ember ribbon, free hand cupping a fireball
by her grinning, underlit face. Ahoge whips against the spin.

Iso: chibi mid-cast, staff planted diagonally with the ember cage held high
on the lane side, free hand raised with a fire spark, orchid bell skirt.

Run from repo root: python3 tools/artgen/gen_caster_1.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- back hair: wavy fan sweeping viewer-left with pointed tips ---
    c.poly([
        (62, 24), (50, 25), (40, 31), (30, 40),          # crown -> out
        (24, 50), (30, 58), (18, 68), (26, 78),          # wave in/out
        (12, 92), (22, 100), (10, 116), (24, 114),       # deeper waves
        (16, 132), (30, 122), (26, 140), (38, 124),      # two flying tips
        (40, 106), (46, 86), (50, 66), (54, 48), (58, 34),
    ], "CORAL")
    # crimson shade along the inner/right edge (away from key light)
    c.poly([(56, 36), (60, 30), (58, 52), (52, 72), (48, 92), (44, 112),
            (38, 122), (40, 104), (44, 84), (50, 62)], "CRIMSON")
    c.poly([(24, 78), (30, 88), (24, 100), (18, 90)], "CRIMSON")
    # gold crests where the wave tops catch the top-left key light
    c.curve([(46, 28), (36, 34), (28, 42)], "GOLD", 2)
    c.curve([(26, 52), (20, 62), (24, 72)], "GOLD", 1)
    c.curve([(14, 90), (14, 102), (14, 112)], "GOLD", 1)
    c.put(18, 128, "GOLD")
    # filler locks hugging the shoulder/torso so no gap opens inside
    c.poly([(50, 44), (58, 34), (56, 70), (46, 92), (42, 78), (48, 58)], "CRIMSON")

    # --- pivot leg: on the boot toe, bottom-center ---
    c.line(64, 152, 66, 184, "SKIN", 4)
    c.line(62, 154, 63, 180, "SKIN_LIGHT", 1)
    c.poly([(60, 182), (72, 182), (74, 196), (70, 206), (63, 206), (58, 194)], "BROWN")
    c.line(63, 205, 70, 205, "UMBER", 1)
    c.line(60, 184, 72, 184, "UMBER", 1)                 # boot cuff
    c.put(62, 190, "BRONZE")                             # scuff

    # --- skirt: orchid bell spiralling, trailing wide to viewer-right ---
    c.poly([
        (50, 100), (74, 98),                             # twisted waist
        (94, 118), (108, 142), (112, 158), (100, 154),   # trailing flare
        (94, 168), (82, 158), (74, 174), (62, 162),
        (52, 172), (42, 158), (32, 164), (28, 146), (36, 118),
    ], "ORCHID")
    # plum depths bottom-right of each fold
    c.poly([(88, 118), (104, 140), (110, 156), (100, 152), (94, 166), (86, 156)], "PLUM")
    c.poly([(62, 156), (66, 140), (72, 150), (72, 164)], "PLUM")
    # magenta mid-folds radiating from the waist twist
    c.poly([(58, 100), (64, 100), (56, 168), (48, 156)], "MAGENTA")
    c.poly([(72, 100), (78, 104), (84, 156), (76, 148)], "MAGENTA")
    c.poly([(44, 108), (48, 112), (36, 160), (32, 148)], "MAGENTA")
    # wine underskirt flashing in the hem gaps (small slivers)
    c.poly([(44, 160), (52, 172), (48, 173), (40, 162)], "WINE")
    c.poly([(64, 164), (74, 174), (70, 175), (60, 166)], "WINE")
    c.poly([(84, 160), (94, 168), (90, 169), (80, 162)], "WINE")
    # gold hem trim following the swirl
    c.curve([(112, 158), (100, 154), (94, 168), (82, 158), (74, 174),
             (62, 162), (52, 172), (42, 158), (32, 164), (28, 146)], "GOLD", 1)

    # --- kicked-up back foot emerging from under the hem, viewer-left ---
    c.line(38, 152, 30, 159, "SKIN", 3)                  # calf angled down-left
    c.line(36, 150, 31, 155, "SKIN_LIGHT", 1)
    c.poly([(18, 153), (31, 157), (29, 168), (15, 163)], "BROWN")
    c.poly([(18, 153), (22, 155), (20, 166), (15, 163)], "UMBER")  # heel shade
    c.line(16, 163, 27, 167, "UMBER", 1)                 # sole
    c.put(26, 159, "BRONZE")                             # scuff

    # --- torso: orchid bodice with a twist (right shoulder raised) ---
    c.poly([(52, 68), (72, 62), (78, 82), (74, 100), (50, 100), (48, 84)], "ORCHID")
    c.poly([(74, 64), (78, 82), (74, 100), (72, 100), (74, 82)], "PLUM")  # edge shade
    c.line(52, 82, 72, 80, "MAGENTA", 1)                 # under-bust fold
    c.line(54, 67, 70, 63, "GOLD", 1)                    # collar trim
    c.line(50, 99, 74, 99, "GOLD", 2)                    # belt
    c.put(62, 99, "PALE_GOLD")                           # buckle glint

    # --- staff: swept arc crossing in front of the skirt ---
    c.line(14, 140, 110, 74, "UMBER", 3)
    c.line(15, 137, 108, 72, "BROWN", 1)                 # top-lit edge
    c.ellipse(44, 119, 2, 3, "UMBER"); c.put(43, 118, "BROWN")   # gnarl
    c.ellipse(80, 95, 2, 2, "UMBER"); c.put(79, 94, "BROWN")     # gnarl
    # bronze cage at the tip, live ember inside
    c.ellipse(114, 70, 6, 7, "BRONZE")
    c.ellipse(114, 70, 4, 5, "UMBER")
    c.line(110, 65, 110, 75, "BRONZE", 1)
    c.line(118, 65, 118, 75, "BRONZE", 1)
    c.ellipse(114, 70, 3, 4, "CORAL")
    c.ellipse(114, 70, 2, 3, "GOLD")
    c.ellipse(114, 70, 1, 1, "PALE_GOLD")
    c.put(114, 68, "PALE_GOLD")
    # her left arm crossing the body to grip the staff low
    c.line(52, 72, 42, 96, "ORCHID", 4)
    c.line(42, 96, 38, 112, "PLUM", 3)
    c.line(36, 106, 42, 108, "GOLD", 1)                  # cuff trim
    c.ellipse(37, 116, 3, 3, "SKIN")                     # gripping fist
    c.put(36, 115, "SKIN_LIGHT")

    # --- ember ribbon trailing off the staff tip, curling round the skirt ---
    c.curve([(110, 80), (100, 100), (86, 120), (70, 136), (52, 146)], "CRIMSON", 2)
    c.curve([(106, 84), (96, 102), (82, 120), (66, 134)], "CORAL", 1)
    c.curve([(98, 96), (88, 112), (76, 124)], "GOLD", 1)
    for x, y in ((104, 90), (92, 108), (78, 128), (60, 142), (46, 150), (112, 96)):
        c.put(x, y, "PALE_GOLD")                         # drifting sparks

    # --- neck + head ---
    c.rect(60, 58, 66, 64, "SKIN")
    c.line(65, 59, 65, 63, "SKIN_SHADOW", 1)
    c.ellipse(62, 45, 11, 12, "SKIN_LIGHT")              # round face
    c.line(58, 56, 66, 56, "SKIN", 1)                    # soft chin shade

    # --- front hair: bangs with pointed tufts over the forehead ---
    c.ellipse(62, 31, 13, 9, "CORAL")                    # crown
    c.poly([(49, 32), (55, 27), (57, 42), (51, 46)], "CORAL")    # left lock
    c.poly([(69, 28), (75, 32), (75, 48), (70, 42)], "CORAL")    # right lock
    c.line(74, 34, 74, 46, "CRIMSON", 1)                 # lock inner shade
    c.poly([(51, 33), (58, 29), (56, 38), (53, 37)], "CORAL")    # tuft 1
    c.poly([(58, 28), (65, 28), (62, 37), (59, 36)], "CORAL")    # tuft 2
    c.poly([(65, 28), (71, 30), (68, 38), (66, 35)], "CORAL")    # tuft 3
    c.line(68, 31, 67, 35, "CRIMSON", 1)                 # tuft 3 inner shade
    c.curve([(51, 29), (58, 25), (66, 25)], "GOLD", 2)           # crest light
    # ahoge whipping right, against the spin — a thin open tick
    c.curve([(63, 21), (67, 14), (73, 12)], "CORAL", 1)
    c.put(74, 12, "CRIMSON")

    # --- horns: tapered gold crescents sweeping back off the hairline ---
    c.poly([(53, 31), (48, 28), (44, 23), (43, 19),
            (46, 20), (49, 26), (52, 29)], "GOLD")       # left horn
    c.put(52, 31, "BRONZE"); c.put(53, 30, "BRONZE")     # root
    c.put(43, 19, "PALE_GOLD"); c.put(44, 20, "PALE_GOLD")
    c.poly([(71, 30), (76, 27), (80, 22), (81, 18),
            (78, 19), (75, 25), (72, 28)], "GOLD")       # right horn
    c.put(72, 30, "BRONZE"); c.put(71, 29, "BRONZE")
    c.put(81, 18, "PALE_GOLD"); c.put(80, 19, "PALE_GOLD")

    # --- face: big amber anime eyes, crooked open grin, freckles ---
    # raised excited brows
    c.line(53, 38, 58, 37, "CRIMSON", 1)
    c.line(66, 37, 71, 38, "CRIMSON", 1)
    # left eye (x52..60) — wide amber iris, rounded corners
    c.rect(53, 42, 59, 48, "PALE")                       # sclera
    c.line(52, 41, 60, 41, "VOID", 1)                    # lash line
    c.put(52, 42, "VOID"); c.put(60, 42, "VOID")         # lash corner drops
    c.rect(54, 43, 58, 48, "GOLD")                       # amber iris
    c.line(54, 43, 58, 43, "CRIMSON", 1)                 # iris top shade
    c.rect(56, 45, 57, 46, "VOID")                       # pupil
    c.put(54, 44, "PALE_GOLD"); c.put(55, 44, "PALE_GOLD")   # catchlight
    c.line(54, 48, 58, 48, "CORAL", 1)                   # fire underlight in iris
    c.put(53, 48, "SKIN_LIGHT"); c.put(59, 48, "SKIN_LIGHT") # round bottom
    c.line(53, 49, 59, 49, "SKIN_SHADOW", 1)             # lower lid
    # right eye (x64..72)
    c.rect(65, 42, 71, 48, "PALE")
    c.line(64, 41, 72, 41, "VOID", 1)
    c.put(64, 42, "VOID"); c.put(72, 42, "VOID")
    c.rect(66, 43, 70, 48, "GOLD")
    c.line(66, 43, 70, 43, "CRIMSON", 1)
    c.rect(67, 45, 68, 46, "VOID")
    c.put(66, 44, "PALE_GOLD"); c.put(67, 44, "PALE_GOLD")
    c.line(66, 48, 70, 48, "CORAL", 1)
    c.put(65, 48, "SKIN_LIGHT"); c.put(71, 48, "SKIN_LIGHT")
    c.line(65, 49, 71, 49, "SKIN_SHADOW", 1)
    # tiny nose
    c.put(62, 51, "SKIN_SHADOW")
    # crooked open grin — clean curve, right corner hitched, one fang
    c.line(57, 53, 63, 53, "VOID", 1)
    c.put(64, 52, "VOID"); c.put(65, 51, "VOID")
    c.rect(58, 54, 62, 55, "WINE")                       # open mouth
    c.put(59, 54, "PALE")                                # fang
    # freckles + blush
    for x, y in ((53, 50), (55, 51), (52, 52), (69, 50), (71, 51), (70, 52)):
        c.put(x, y, "ROSE")

    # --- her right arm: bent up, hand cupping the fireball by her face ---
    c.line(72, 66, 80, 61, "ORCHID", 4)
    c.line(80, 63, 84, 61, "ORCHID", 3)
    c.line(82, 65, 85, 64, "PLUM", 1)                    # sleeve underside
    c.line(81, 62, 84, 62, "GOLD", 1)                    # cuff trim
    c.ellipse(86, 60, 3, 2, "SKIN")                      # cupping hand
    c.put(84, 59, "SKIN_LIGHT"); c.put(88, 59, "SKIN_LIGHT")
    # the just-bloomed fireball, close to her grin
    c.ellipse(87, 51, 6, 7, "CORAL")
    c.ellipse(87, 52, 4, 5, "GOLD")
    c.ellipse(87, 53, 2, 3, "PALE_GOLD")
    c.put(84, 43, "CORAL"); c.put(89, 42, "GOLD"); c.put(86, 41, "GOLD")
    c.put(91, 45, "CORAL")
    # fire underlight kissing the near cheek and chin
    c.line(72, 50, 73, 54, "SKIN_PALE", 1)
    c.line(64, 57, 70, 55, "SKIN_PALE", 1)
    c.put(74, 48, "PALE_GOLD")

    # --- cool rim light (PALE) on the trailing right edge ---
    c.line(78, 84, 77, 96, "PALE", 1)

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- staff planted diagonally, ember cage high on the lane side ---
    c.line(42, 58, 50, 14, "UMBER", 2)
    c.line(43, 56, 50, 16, "BROWN", 1)
    c.ellipse(50, 10, 4, 4, "BRONZE")             # cage
    c.ellipse(50, 10, 3, 3, "CORAL")
    c.ellipse(50, 10, 1, 1, "PALE_GOLD")          # THE ember rally pixel
    c.put(50, 8, "GOLD"); c.put(49, 9, "GOLD")

    # --- boots at the pivot (32, 60) ---
    c.rect(27, 56, 31, 59, "BROWN")
    c.rect(33, 56, 37, 59, "BROWN")
    c.line(27, 59, 37, 59, "UMBER", 1)

    # --- orchid bell skirt (the only orchid mass on the board) ---
    c.poly([(26, 38), (38, 38), (44, 54), (20, 54)], "ORCHID")
    c.poly([(36, 40), (38, 38), (44, 54), (36, 54)], "PLUM")   # shade right
    c.line(30, 40, 28, 53, "MAGENTA", 1)                       # fold
    c.line(20, 54, 44, 54, "GOLD", 1)                          # hem trim

    # --- torso ---
    c.rect(27, 32, 37, 39, "ORCHID")
    c.rect(35, 32, 37, 39, "PLUM")
    c.line(27, 38, 37, 38, "GOLD", 1)             # belt

    # --- arms: right to staff, left raised with a fire spark ---
    c.line(37, 34, 43, 36, "ORCHID", 2)
    c.ellipse(44, 36, 1, 1, "SKIN")
    c.line(27, 34, 19, 28, "ORCHID", 2)
    c.ellipse(17, 27, 1, 1, "SKIN")
    # flame spark: coral teardrop with gold heart
    c.put(14, 25, "CORAL"); c.put(15, 25, "CORAL")
    c.put(14, 24, "CORAL"); c.put(15, 24, "GOLD")
    c.put(14, 23, "GOLD"); c.put(15, 23, "CORAL")
    c.put(14, 22, "PALE_GOLD"); c.put(15, 21, "CORAL")
    c.put(13, 20, "CORAL")

    # --- head: big coral hair blob, gold horns breaking the outline ---
    c.ellipse(31, 20, 9, 8, "SKIN_LIGHT")         # face base
    c.ellipse(31, 14, 10, 7, "CORAL")             # hair crown
    c.poly([(21, 14), (24, 22), (21, 27), (19, 20)], "CORAL")   # left lock
    c.poly([(41, 14), (43, 20), (41, 27), (38, 22)], "CORAL")   # right lock
    # shade hugging the right edge of the hair mass (not across the crown)
    c.curve([(40, 20), (41, 16), (40, 12)], "CRIMSON", 1)
    c.curve([(40, 24), (42, 20)], "CRIMSON", 1)
    c.curve([(24, 10), (29, 8), (34, 9)], "GOLD", 1)            # crest light
    # ahoge — 2px tick whipping sideways
    c.line(33, 7, 36, 4, "CORAL", 1)
    c.put(37, 4, "CRIMSON")
    # horns: angled nubs breaking the hair silhouette sideways
    c.put(23, 12, "BRONZE"); c.put(22, 11, "GOLD"); c.put(21, 11, "GOLD")
    c.put(21, 10, "GOLD"); c.put(20, 9, "GOLD"); c.put(19, 8, "PALE_GOLD")
    c.put(39, 12, "BRONZE"); c.put(40, 11, "GOLD"); c.put(41, 11, "GOLD")
    c.put(41, 10, "GOLD"); c.put(42, 9, "GOLD"); c.put(43, 8, "PALE_GOLD")

    # --- chibi face ---
    c.rect(26, 19, 27, 21, "VOID")                # left eye
    c.put(26, 19, "GOLD")
    c.put(26, 18, "PALE")
    c.rect(34, 19, 35, 21, "VOID")                # right eye
    c.put(34, 19, "GOLD")
    c.put(34, 18, "PALE")
    c.put(31, 23, "SKIN")                         # nose hint
    c.line(29, 25, 33, 25, "SKIN_SHADOW", 1)      # grin
    c.put(34, 24, "SKIN_SHADOW")                  # crooked corner
    c.put(24, 23, "ROSE"); c.put(37, 23, "ROSE")  # blush

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
    save(key, os.path.join(out, "caster_1_key.png"), 1)
    save(key, os.path.join(out, "caster_1_key@3x.png"), 3)
    save(iso, os.path.join(out, "caster_1_iso.png"), 1)
    save(iso, os.path.join(out, "caster_1_iso@4x.png"), 4)
    print("caster_1: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
