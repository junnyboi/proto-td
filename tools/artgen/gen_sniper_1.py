"""sniper_1 — Rennick Thorne, human bolt-for-hire.

Key art: combat slide into a kneeling brace — one knee skidding through
dungeon grit, long umber duster flaring behind him in a diagonal, heavy
steel-limbed windlass crossbow already leveled and locked against his
cheek, off-hand finishing the crank. A spent bolt spins in the air.
Eyes flat, professional, utterly unhurried inside a fast body.

Iso: chibi kneeling on one knee, crossbow leveled horizontally toward the
lane — dark slicked head, coat wedge pooling behind the knee, gold-tipped
T-silhouette.

Run from repo root: python3 tools/artgen/gen_sniper_1.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- duster coat: flaring diagonal mass behind him, hem whipping right ---
    c.poly([
        (54, 100), (78, 98),                       # shoulders
        (90, 112), (102, 130), (112, 150),         # billow out
        (120, 172), (112, 168), (116, 190),        # jagged trailing hem
        (104, 180), (106, 194), (96, 182),
        (92, 190), (86, 172), (80, 180),
        (74, 164), (66, 148), (58, 130), (52, 114),
    ], "UMBER")
    # fold shadows: vertical VOID streaks inside the folds, not a blob
    c.poly([(98, 134), (106, 154), (112, 176), (106, 168), (108, 190),
            (100, 172), (94, 150)], "VOID")
    c.poly([(76, 152), (82, 172), (76, 180), (70, 158)], "VOID")
    c.line(86, 130, 92, 158, "VOID", 1)
    # BROWN crests where the top edges catch the top-left light
    c.curve([(80, 102), (92, 116), (102, 134)], "BROWN", 2)
    c.curve([(104, 140), (112, 158)], "BROWN", 1)
    c.curve([(62, 122), (68, 144)], "BROWN", 1)
    # cool rim light on the trailing back edge
    c.curve([(116, 158), (120, 174), (116, 188)], "PALE", 1)

    # --- rear leg: thigh dropping back, knee ON the grit, shin trailing flat ---
    c.poly([(60, 142), (70, 144), (74, 186), (62, 188)], "BROWN")    # thigh down-back
    c.poly([(68, 144), (70, 144), (74, 186), (71, 187)], "UMBER")    # shade edge
    # lit hem edge on the coat, then a thin cast shadow above the knee pad
    c.curve([(76, 170), (84, 176), (90, 182)], "BROWN", 1)
    c.poly([(58, 181), (84, 183), (84, 186), (58, 186)], "VOID")
    c.poly([(60, 186), (82, 184), (84, 198), (58, 200)], "BROWN")    # knee pad on grit
    c.line(60, 187, 82, 185, "UMBER", 1)                             # pad seam
    c.put(70, 192, "BRONZE"); c.put(71, 192, "BRONZE")               # pad stud
    c.line(60, 199, 83, 198, "UMBER", 1)
    c.line(84, 186, 85, 199, "VOID", 1)                              # knee/shin split
    c.poly([(86, 188), (104, 190), (104, 199), (86, 199)], "BROWN")  # shin flat behind
    c.line(88, 197, 102, 198, "UMBER", 1)                            # underside
    c.line(88, 189, 101, 191, "BRONZE", 1)                           # greave strap
    c.poly([(104, 184), (112, 186), (114, 200), (104, 199)], "BROWN")# trailing boot up
    c.line(105, 199, 113, 199, "VOID", 1)                            # sole edge
    c.put(105, 187, "BRONZE")                                        # heel buckle
    c.line(114, 190, 114, 198, "PALE", 1)                            # boot rim light
    # skid grit + motion streaks (he slides toward viewer-left)
    c.line(86, 204, 100, 204, "GRAY", 1)
    c.line(64, 203, 76, 203, "GRAY", 1)
    c.line(96, 208, 110, 208, "GRAY", 1)
    c.put(54, 202, "STEEL"); c.put(80, 207, "STEEL"); c.put(114, 205, "GRAY")

    # --- front leg: deep kneel — thigh thrust forward, shin vertical, boot planted ---
    c.poly([(54, 138), (62, 148), (36, 160), (26, 148)], "BROWN")    # thigh wedge
    c.line(40, 158, 58, 148, "UMBER", 1)                             # under-thigh shade
    c.poly([(26, 148), (38, 158), (36, 190), (22, 190)], "UMBER")    # shin down
    c.line(26, 154, 24, 186, "BROWN", 1)                             # lit shin edge
    c.poly([(12, 188), (36, 188), (38, 202), (20, 204), (8, 196)], "BROWN")   # boot
    c.line(12, 201, 37, 200, "VOID", 1)                              # sole
    c.line(24, 188, 36, 188, "BRONZE", 1)                            # boot cuff
    # thigh quiver riding on top of the front thigh: gold-fletched bolts
    c.poly([(36, 144), (52, 150), (48, 162), (32, 156)], "UMBER")    # pouch body
    c.poly([(36, 144), (52, 150), (51, 154), (35, 148)], "BROWN")    # lit flap
    c.put(38, 146, "GOLD"); c.put(39, 147, "GOLD")                   # fletch tips
    c.put(43, 148, "GOLD"); c.put(44, 149, "GOLD")                   # peeking out
    c.put(48, 150, "GOLD"); c.put(49, 151, "GOLD")
    c.put(41, 158, "BRONZE")                                         # strap stud

    # --- torso: boiled-leather jerkin, compressed, leaning into the aim ---
    c.poly([(52, 94), (76, 94), (78, 116), (70, 144), (56, 144), (48, 116)], "BROWN")
    c.poly([(73, 94), (78, 116), (70, 144), (66, 144), (72, 116)], "UMBER")  # shade
    c.line(52, 104, 70, 102, "UMBER", 1)                             # plate seam
    c.line(52, 118, 68, 117, "UMBER", 1)
    # belt with bronze buckle + gold tally rings
    c.line(54, 138, 68, 137, "UMBER", 2)
    c.put(60, 137, "BRONZE"); c.put(61, 137, "BRONZE")
    c.put(56, 138, "GOLD"); c.put(64, 138, "GOLD"); c.put(67, 137, "GOLD")
    # bandolier strap
    c.line(54, 98, 70, 126, "UMBER", 2)
    c.put(58, 105, "BRONZE"); c.put(64, 116, "BRONZE")

    # --- crossbow: heavy steel-limbed windlass, dead level, cheek-locked ---
    # thick dark-wood stock, horizontal at cheek height
    c.poly([(24, 84), (78, 86), (78, 96), (24, 92)], "UMBER")
    c.line(28, 87, 74, 89, "BROWN", 2)                               # lit wood flank
    c.poly([(76, 84), (84, 86), (84, 104), (74, 100)], "BROWN")      # shoulder butt
    c.line(83, 88, 83, 102, "UMBER", 1)
    # bronze rail along the top
    c.line(24, 83, 72, 85, "BRONZE", 1)
    # heavy steel recurve limbs mounted at the front block
    c.rect(26, 82, 34, 96, "DUSK")                                   # mount block
    c.put(30, 84, "SLATE"); c.put(30, 92, "SLATE")                   # bolt heads
    c.curve([(30, 82), (23, 74), (19, 62)], "SLATE", 3)              # upper limb
    c.curve([(30, 96), (23, 104), (19, 116)], "SLATE", 3)            # lower limb
    c.curve([(29, 80), (23, 72), (20, 63)], "STEEL", 1)              # lit edges
    c.curve([(29, 98), (23, 105), (20, 115)], "STEEL", 1)
    c.put(19, 61, "PALE"); c.put(19, 117, "PALE")                    # tip glints
    # string drawn back to the nut (windlass mid-span)
    c.line(19, 62, 62, 87, "PALE", 1)
    c.line(19, 116, 62, 93, "PALE", 1)
    # loaded bolt on the rail, gold fletching right by his cheek
    c.line(12, 81, 52, 83, "DUSK", 1)
    c.put(9, 81, "STEEL"); c.put(10, 81, "STEEL"); c.put(11, 81, "STEEL")
    c.poly([(52, 79), (58, 77), (58, 85), (52, 84)], "GOLD")         # fletching vane
    c.put(54, 79, "PALE_GOLD")
    # windlass crank wheel at the stock rear underside
    c.ellipse(74, 110, 4, 4, "BRONZE")
    c.ellipse(74, 110, 2, 2, "UMBER")
    c.line(74, 110, 81, 106, "BRONZE", 1)                            # crank arm
    c.put(82, 105, "GOLD")                                           # handle knob

    # --- arms ---
    # far arm: forward along the stock underside to the foregrip
    c.line(56, 100, 44, 96, "UMBER", 5)
    c.line(46, 98, 42, 96, "BROWN", 3)                               # bracer
    c.put(44, 97, "BRONZE")
    c.ellipse(41, 93, 3, 3, "SKIN")                                  # foregrip hand
    c.put(40, 92, "SKIN_LIGHT")
    # near arm: dropping from the shoulder to the crank, mid-turn
    c.line(66, 118, 71, 112, "UMBER", 4)
    c.line(69, 114, 72, 112, "BROWN", 3)                             # bracer
    c.put(70, 113, "BRONZE")
    c.ellipse(74, 113, 3, 2, "SKIN")                                 # crank hand
    c.put(73, 112, "SKIN_LIGHT")

    # --- neck + head dropped onto the stock, cheek-lock ---
    c.rect(58, 86, 64, 92, "SKIN")
    c.line(63, 87, 63, 91, "SKIN_SHADOW", 1)
    c.ellipse(60, 75, 10, 11, "SKIN_LIGHT")                          # face
    c.line(55, 84, 64, 85, "SKIN", 1)                                # jaw shade
    c.put(51, 78, "SKIN")                                            # near ear

    # --- hair: INK slicked straight back off the brow, hard skull line ---
    c.poly([(50, 68), (52, 61), (58, 57), (66, 57), (71, 61),        # skull cap
            (72, 70), (70, 76), (66, 72), (60, 65), (54, 66)], "INK")
    c.ellipse(61, 60, 9, 5, "INK")                                   # crown mass
    c.poly([(68, 60), (73, 64), (73, 76), (68, 74)], "INK")          # back of skull
    # slick-back streaks flowing to the nape
    c.curve([(53, 62), (61, 58), (69, 62)], "VOID", 1)
    c.curve([(55, 65), (63, 61), (70, 67)], "VOID", 1)
    # short low tail flicked back by the slide
    c.poly([(72, 72), (82, 69), (86, 74), (74, 78)], "INK")
    c.put(86, 73, "VOID"); c.put(85, 75, "VOID")
    c.put(73, 71, "DUSK")                                            # tail tie glint

    # --- face: flat professional gold eyes, dead calm ---
    # straight low brows sitting close over the eyes
    c.line(52, 70, 57, 70, "VOID", 1)
    c.line(62, 70, 67, 70, "VOID", 1)
    # left eye (viewer left) — heavy lid, gold iris, catchlight
    c.rect(52, 73, 58, 78, "PALE")
    c.line(51, 72, 59, 72, "VOID", 1)                                # lash line
    c.line(52, 73, 58, 73, "VOID", 1)                                # heavy lid
    c.rect(53, 74, 57, 78, "GOLD")                                   # iris
    c.line(53, 74, 57, 74, "BRONZE", 1)                              # iris top shade
    c.rect(54, 75, 55, 77, "VOID")                                   # pupil
    c.put(56, 75, "PALE_GOLD")                                       # catchlight
    c.put(52, 78, "SKIN_LIGHT"); c.put(58, 78, "SKIN_LIGHT")         # round bottom
    c.line(52, 79, 58, 79, "SKIN_SHADOW", 1)                         # lower lid
    # right eye
    c.rect(62, 73, 68, 78, "PALE")
    c.line(61, 72, 69, 72, "VOID", 1)
    c.line(62, 73, 68, 73, "VOID", 1)
    c.rect(63, 74, 67, 78, "GOLD")
    c.line(63, 74, 67, 74, "BRONZE", 1)
    c.rect(64, 75, 65, 77, "VOID")
    c.put(66, 75, "PALE_GOLD")
    c.put(62, 78, "SKIN_LIGHT"); c.put(68, 78, "SKIN_LIGHT")
    c.line(62, 79, 68, 79, "SKIN_SHADOW", 1)
    # nose + flat unimpressed mouth
    c.put(59, 81, "SKIN_SHADOW"); c.put(60, 82, "SKIN_SHADOW")
    c.line(56, 84, 61, 84, "VOID", 1)

    # --- spent bolt spinning in the air beside his head ---
    c.line(92, 54, 100, 48, "BROWN", 2)
    c.put(101, 47, "GOLD"); c.put(102, 46, "GOLD")
    c.put(91, 55, "STEEL")
    c.curve([(90, 46), (95, 42), (101, 41)], "GRAY", 1)              # spin arc
    c.curve([(92, 60), (98, 61), (104, 58)], "GRAY", 1)

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- coat tail pooling behind the kneeling knee (viewer right) ---
    c.poly([(36, 32), (46, 38), (54, 48), (56, 58), (38, 58), (36, 46)], "UMBER")
    c.poly([(50, 46), (56, 58), (46, 58)], "VOID")                   # fold depth
    c.curve([(44, 36), (52, 46)], "BROWN", 1)                        # lit crest

    # --- kneeling legs at the pivot (32, 60) ---
    c.poly([(26, 42), (32, 44), (26, 52), (18, 48)], "BROWN")        # thigh forward
    c.rect(18, 48, 23, 57, "UMBER")                                  # shin down
    c.poly([(12, 54), (24, 54), (25, 59), (14, 59)], "BROWN")        # boot planted
    c.line(13, 59, 25, 59, "VOID", 1)
    c.rect(33, 44, 39, 58, "BROWN")                                  # knee-down leg
    c.rect(37, 44, 39, 58, "UMBER")
    c.poly([(39, 55), (48, 56), (48, 59), (39, 59)], "BROWN")        # trailing foot
    c.line(40, 59, 48, 59, "VOID", 1)                                # sole line

    # --- torso: leather jerkin leaning into the aim ---
    c.poly([(26, 28), (38, 28), (39, 46), (27, 46)], "BROWN")
    c.poly([(35, 28), (38, 28), (39, 46), (35, 46)], "UMBER")        # right shade
    c.line(27, 42, 37, 42, "UMBER", 1)                               # belt
    c.put(30, 42, "GOLD"); c.put(33, 42, "BRONZE")                   # tally + buckle

    # --- crossbow: heavy horizontal T leveled at the lane (left) ---
    c.line(8, 33, 34, 35, "UMBER", 3)                                # stock bar
    c.line(10, 32, 30, 33, "BROWN", 1)                               # lit rail
    c.rect(12, 30, 16, 38, "DUSK")                                   # mount block
    c.curve([(13, 30), (12, 27), (14, 24)], "SLATE", 2)              # upper limb
    c.curve([(13, 38), (12, 41), (14, 44)], "SLATE", 2)              # lower limb
    c.put(12, 26, "STEEL"); c.put(13, 25, "STEEL")                   # lit tips
    c.put(12, 42, "STEEL"); c.put(13, 43, "STEEL")
    c.line(14, 24, 30, 33, "PALE", 1)                                # string top
    c.line(14, 44, 30, 37, "PALE", 1)                                # string bottom
    c.put(4, 33, "STEEL"); c.put(5, 33, "STEEL"); c.put(6, 33, "STEEL")  # bolt head
    c.rect(30, 32, 31, 34, "GOLD")                                   # THE fletching dot
    # arms to the bar
    c.line(26, 33, 22, 34, "UMBER", 2)
    c.ellipse(20, 34, 1, 1, "SKIN")
    c.line(36, 38, 31, 36, "UMBER", 2)
    c.ellipse(30, 37, 1, 1, "SKIN")

    # --- head: dark slicked skull, brow clear, low tail nub ---
    c.ellipse(32, 19, 8, 8, "SKIN_LIGHT")                            # face
    c.poly([(24, 16), (25, 11), (30, 8), (36, 8), (40, 11),          # slick cap
            (41, 17), (38, 14), (32, 12), (26, 14)], "INK")
    c.ellipse(32, 11, 8, 4, "INK")                                   # crown
    c.poly([(39, 12), (42, 15), (42, 22), (38, 18)], "INK")          # back of skull
    c.poly([(42, 18), (49, 20), (44, 24)], "INK")                    # low tail
    c.curve([(27, 10), (32, 8), (37, 10)], "VOID", 1)                # slick streak

    # --- chibi face: flat pro eyes with gold iris ---
    c.line(27, 16, 30, 16, "VOID", 1)                                # brows
    c.line(34, 16, 37, 16, "VOID", 1)
    c.rect(28, 18, 29, 21, "VOID")                                   # left eye
    c.put(28, 19, "GOLD"); c.put(28, 18, "PALE")
    c.rect(35, 18, 36, 21, "VOID")                                   # right eye
    c.put(35, 19, "GOLD"); c.put(35, 18, "PALE")
    c.line(30, 25, 34, 25, "SKIN_SHADOW", 1)                         # flat mouth

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
    save(key, os.path.join(out, "sniper_1_key.png"), 1)
    save(key, os.path.join(out, "sniper_1_key@3x.png"), 3)
    save(iso, os.path.join(out, "sniper_1_iso.png"), 1)
    save(iso, os.path.join(out, "sniper_1_iso@4x.png"), 4)
    print("sniper_1: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
