"""caster_2 — Severin Thal, storm scholar. Still point of the storm.

Key art: mid-stride slouch, one hand pocketed, the other raised shoulder-high
with two fingers out — a big teal-to-cyan storm orb hangs over the fingertips,
spitting 1px cyan arcs while it detonates a massive bolt off-frame top-right.
Plum robe cut by bold teal lightning panels and a steel mantle over the
shoulders; an asymmetric slit bares the striding lead leg. Cyan undercut and
robe blasted sideways; iron-clasped tome fanning pages by his hip.

Iso: chibi mid-stride, two fingers raised toward the big teal-to-cyan orb
floating clear of the glove; steel mantle, teal front panel, slit baring the
lead boot; tome a steel slab at the hip.

Run from repo root: python3 tools/artgen/gen_caster_2.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- legs FIRST: lead leg strides viewer-right, bared by the robe slit ---
    c.poly([(60, 114), (74, 114), (80, 144), (68, 146)], "DUSK")     # thigh
    c.line(64, 120, 69, 140, "SLATE", 1)                # thigh glint (key light)
    c.poly([(69, 144), (81, 142), (88, 192), (77, 194)], "DUSK")     # shin/boot shaft
    c.line(80, 148, 86, 188, "VOID", 1)                 # shade seam right
    c.line(72, 150, 74, 164, "SLATE", 1)                # shin glint
    c.line(70, 144, 80, 142, "STEEL", 1)                # steel knee rim
    c.line(72, 168, 84, 166, "STEEL", 1)                # steel boot cuff
    c.line(74, 172, 77, 188, "SLATE", 1)                # boot shaft glint
    c.poly([(78, 192), (89, 190), (96, 200), (94, 206), (78, 206)], "DUSK")  # foot
    c.line(79, 205, 93, 205, "VOID", 1)                 # sole
    c.put(81, 196, "SLATE")
    # trailing leg: toe tucked under the hem, mid-stride
    c.poly([(46, 190), (56, 190), (58, 202), (45, 202)], "DUSK")
    c.line(46, 201, 57, 201, "VOID", 1)
    c.put(48, 193, "SLATE")

    # --- lower robe: plum sweep blasted viewer-left, slit torn open right ---
    c.poly([
        (46, 112), (74, 112),                          # waist
        (77, 120), (70, 127),                          # slit opens at the hip
        (62, 140), (56, 156), (52, 172), (49, 188),    # slit edge sweeping left
        (44, 181), (34, 188), (24, 178),               # hem jags leftward
        (12, 184), (4, 174), (14, 166),                # streamer 1
        (5, 156), (18, 152), (12, 141), (24, 138),     # streamer 2
        (30, 124), (40, 114),
    ], "PLUM")
    # navy shadow: inside the slit edge + inside the wind streamers
    c.poly([(70, 118), (73, 122), (64, 138), (58, 154), (54, 170), (50, 186),
            (47, 186), (50, 168), (54, 150), (60, 132)], "NAVY")
    c.poly([(44, 150), (52, 148), (46, 180), (40, 172)], "NAVY")
    c.poly([(14, 166), (24, 160), (18, 176), (10, 176)], "NAVY")
    # magenta lit fold-tops (top-left key light)
    c.line(48, 116, 40, 140, "MAGENTA", 1)
    c.line(36, 132, 22, 144, "MAGENTA", 1)
    c.line(30, 150, 14, 158, "MAGENTA", 1)
    # crisp slit boundary so the bared leg reads against the robe
    c.curve([(77, 120), (70, 127), (62, 140), (56, 156), (52, 172), (49, 188)], "VOID", 1)
    # BOLD teal lightning panel zig-zagging down the slit edge, cyan at the zags
    c.curve([(73, 118), (67, 126), (70, 131), (60, 142), (63, 147),
             (54, 158), (57, 163), (50, 174), (52, 179), (47, 186)], "TEAL", 2)
    for x, y in ((70, 131), (63, 147), (57, 163), (52, 179)):
        c.put(x, y, "CYAN")
    # teal lightning-trim along the hem, cyan flickers at the tips
    c.curve([(49, 188), (44, 181), (34, 188), (24, 178), (12, 184), (4, 174)], "TEAL", 2)
    for x, y in ((4, 174), (24, 178), (44, 181)):
        c.put(x, y, "CYAN")
    c.put(5, 156, "CYAN"); c.put(12, 141, "CYAN")       # streamer tips crackle

    # --- torso: plum robe with a waist, slouched, right shoulder eased up ---
    c.poly([(48, 66), (74, 64), (78, 88), (74, 104), (72, 114), (48, 114), (46, 96), (46, 78)], "PLUM")
    c.poly([(74, 66), (78, 88), (74, 106), (71, 106), (73, 86)], "NAVY")   # right shade
    c.line(50, 70, 48, 96, "MAGENTA", 1)                # lit left edge
    # central lightning panel: bold teal zig-zag below the mantle, cyan tip
    c.curve([(61, 88), (58, 95), (63, 101), (60, 108)], "TEAL", 2)
    c.put(60, 108, "CYAN")
    # dusk sash with steel clasp, void underline so it reads on plum
    c.line(47, 110, 73, 110, "DUSK", 2)
    c.line(48, 112, 72, 112, "VOID", 1)
    c.put(60, 110, "STEEL")

    # --- pocketed arm (viewer-left): full sleeve hangs outside the torso ---
    c.poly([(50, 68), (44, 72), (40, 84), (39, 98), (42, 106), (48, 106), (49, 96), (46, 86), (49, 74)], "PLUM")
    c.curve([(50, 72), (47, 84), (49, 98), (48, 104)], "NAVY", 2)   # seam vs torso
    c.line(41, 78, 39, 92, "MAGENTA", 1)                # lit outer edge
    c.line(40, 102, 47, 104, "DUSK", 2)                 # pocket flap, hand buried
    c.put(41, 100, "TEAL")                              # pocket trim tick

    # --- steel mantle draped over both shoulders (breaks the robe read) ---
    c.poly([(46, 61), (76, 59), (81, 68), (76, 79), (62, 87), (48, 81), (42, 71)], "STEEL")
    c.line(47, 62, 43, 70, "PALE", 1)                   # lit left edge
    c.line(48, 61, 74, 60, "PALE", 1)                   # lit top edge
    c.poly([(76, 62), (81, 68), (76, 79), (66, 85), (74, 70)], "SLATE")     # right shade
    c.curve([(43, 71), (49, 80), (62, 86), (75, 78), (80, 68)], "DUSK", 1)  # hem edge
    c.put(62, 87, "TEAL")                               # clasp tick at the point

    # --- high collar + neck ---
    c.rect(56, 56, 64, 62, "SKIN")
    c.line(63, 57, 63, 61, "SKIN_SHADOW", 1)
    c.poly([(52, 58), (70, 58), (72, 68), (50, 68)], "PLUM")
    c.line(52, 58, 70, 58, "NAVY", 1)                   # collar inner rim
    c.put(54, 59, "TEAL"); c.put(68, 59, "TEAL")        # collar trim ticks

    # --- head: pale scholar, slight jaw ---
    c.ellipse(60, 44, 10, 11, "SKIN_LIGHT")
    c.line(56, 54, 65, 54, "SKIN", 1)                   # chin shade
    c.line(69, 46, 68, 51, "SKIN", 1)                   # jaw right shade
    # exposed ear on the buzzed side
    c.rect(69, 42, 72, 47, "SKIN")
    c.put(70, 44, "SKIN_SHADOW")

    # --- hair: severe asymmetric undercut, long sweep blasted viewer-left ---
    # skull cap (kept tight so the head never puffs)
    c.ellipse(60, 30, 11, 7, "CYAN")
    # buzzed side (viewer-right): teal crop hugging the skull tight
    c.poly([(63, 24), (69, 26), (72, 30), (73, 39), (69, 40), (65, 31), (62, 27)], "TEAL")
    c.line(72, 34, 72, 39, "NAVY", 1)                   # buzz shadow at the ear
    # hard NAVY part line — the diagonal silhouette break
    c.line(63, 24, 60, 31, "NAVY", 1)
    # main cyan wedge: streams hard left AT HEAD LEVEL, tips level or dipping
    c.poly([
        (60, 24), (48, 26), (34, 31), (20, 36),
        (6, 41), (1, 47), (13, 45),                     # tip 1 (level)
        (8, 55), (22, 49),                              # tip 2 (dipping)
        (32, 45), (42, 40), (52, 34), (58, 29),
    ], "CYAN")
    # fringe: solid diagonal wedge over the left half of the forehead
    c.poly([(65, 25), (56, 27), (48, 33), (44, 40), (44, 42), (49, 42), (55, 37), (61, 31)], "CYAN")
    c.line(45, 41, 53, 36, "TEAL", 1)                   # fringe under-edge
    c.line(54, 35, 59, 31, "TEAL", 1)
    # teal undersides + navy motion strands inside the sweep
    c.poly([(52, 33), (40, 39), (28, 44), (20, 48), (30, 42), (42, 36), (54, 30)], "TEAL")
    c.line(9, 45, 17, 43, "TEAL", 1)                    # tip 1 underside
    c.line(12, 52, 19, 48, "TEAL", 1)                   # tip 2 underside
    c.curve([(56, 27), (42, 32), (26, 38), (12, 42)], "NAVY", 1)   # strand 1
    c.curve([(50, 35), (36, 41), (24, 46)], "NAVY", 1)             # strand 2
    # static crackle in the blasted tips
    c.put(0, 44, "CYAN"); c.put(5, 53, "CYAN")

    # --- face: half-lidded disdain, cyan irises ---
    # flat unimpressed brows
    c.line(52, 39, 58, 39, "NAVY", 1)
    c.line(64, 39, 70, 39, "NAVY", 1)
    # left eye — heavy straight lid, iris cut by it
    c.line(51, 42, 58, 42, "VOID", 1)                   # lid line
    c.rect(52, 43, 57, 46, "PALE")                      # sclera
    c.rect(53, 43, 55, 46, "CYAN")                      # iris (top cut by lid)
    c.line(53, 43, 55, 43, "TEAL", 1)                   # lid shadow on iris
    c.rect(54, 44, 54, 45, "VOID")                      # pupil
    c.put(53, 44, "PALE")                               # catchlight
    c.line(52, 47, 57, 47, "SKIN_SHADOW", 1)            # lower lid
    # right eye
    c.line(63, 42, 70, 42, "VOID", 1)
    c.rect(64, 43, 69, 46, "PALE")
    c.rect(65, 43, 67, 46, "CYAN")
    c.line(65, 43, 67, 43, "TEAL", 1)
    c.rect(66, 44, 66, 45, "VOID")
    c.put(65, 44, "PALE")
    c.line(64, 47, 69, 47, "SKIN_SHADOW", 1)
    # tiny nose, flat mouth
    c.put(60, 50, "SKIN_SHADOW")
    c.line(57, 54, 61, 54, "VOID", 1)

    # --- gesture arm (viewer-right): sleeve emerges under the steel mantle ---
    c.line(78, 74, 89, 80, "PLUM", 6)                   # upper arm, relaxed drop
    c.line(79, 71, 87, 76, "MAGENTA", 1)                # lit top edge
    c.line(89, 80, 94, 67, "PLUM", 5)                   # forearm angled up
    c.line(86, 82, 92, 83, "NAVY", 2)                   # elbow underside
    # wide bell cuff falling off the wrist
    c.poly([(88, 56), (99, 53), (101, 66), (89, 70)], "PLUM")
    c.poly([(96, 55), (101, 66), (96, 68)], "NAVY")     # cuff underside
    c.line(89, 58, 98, 55, "TEAL", 1)                   # jagged cuff trim
    c.put(93, 56, "CYAN"); c.put(99, 54, "CYAN")        # trim flicker
    # dusk glove, two long fingers noting a page number
    c.ellipse(99, 55, 3, 3, "DUSK")
    c.put(97, 53, "SLATE")                              # knuckle glint
    c.line(99, 52, 100, 47, "DUSK", 2)                  # finger 1
    c.line(102, 53, 104, 49, "DUSK", 2)                 # finger 2
    c.put(100, 47, "SLATE"); c.put(104, 49, "SLATE")    # fingertip glints

    # --- THE BOLT first: massive, off-frame top-right, teal sheath + cyan core ---
    c.curve([(111, 29), (119, 23), (113, 18), (123, 10), (118, 5), (126, -2)], "TEAL", 7)
    c.curve([(111, 29), (119, 23), (113, 18), (123, 10), (118, 5), (126, -2)], "CYAN", 4)
    c.curve([(119, 23), (127, 26)], "CYAN", 2)          # fork right
    c.curve([(113, 18), (106, 12)], "CYAN", 2)          # fork left
    c.put(104, 9, "CYAN")

    # --- the orb ON TOP: big teal-to-cyan focus the bolt erupts from ---
    c.ellipse(105, 33, 8, 8, "TEAL")                    # storm shell
    c.ellipse(104, 32, 6, 6, "CYAN")                    # glowing body
    c.ellipse(102, 30, 2, 2, "PALE")                    # hot core (key light)
    c.put(108, 36, "NAVY"); c.put(106, 38, "NAVY")      # core turbulence
    c.curve([(99, 39), (105, 41), (111, 38)], "TEAL", 1)    # shell shade lower rim
    # 1px cyan lightning arcs jumping off the shell
    c.curve([(96, 28), (92, 24), (94, 19)], "CYAN", 1)
    c.curve([(113, 37), (118, 40), (117, 45)], "CYAN", 1)
    c.curve([(103, 42), (101, 46)], "CYAN", 1)          # arc down to the fingers
    c.curve([(97, 36), (93, 39)], "CYAN", 1)
    # detonation flash sparks
    for x, y in ((90, 28), (94, 43), (103, 48), (116, 46), (119, 31), (98, 18)):
        c.put(x, y, "CYAN")

    # --- tome: iron-clasped, floating open by the hip, one page mid-turn ---
    # dark cover slab with a visible border on every side
    c.poly([(8, 110), (23, 104), (39, 106), (40, 113), (25, 112), (10, 118)], "DUSK")
    c.line(10, 117, 24, 112, "VOID", 1)                 # cover bottom weight
    # open page block: shallow V meeting at the spine, inset in the cover
    c.poly([(11, 109), (22, 105), (23, 109), (13, 114)], "PALE")    # left page
    c.poly([(24, 105), (36, 107), (37, 110), (25, 109)], "PALE")    # right page
    c.line(23, 104, 23, 110, "SLATE", 1)                # spine gutter
    c.put(15, 111, "STEEL"); c.put(31, 108, "STEEL")    # text-line hints
    # iron clasps on the exposed cover border
    c.put(9, 111, "STEEL"); c.put(39, 107, "STEEL")
    # ONE page standing mid-turn above the spine, whipped by the wind
    c.poly([(21, 103), (19, 97), (23, 94), (24, 100)], "PALE")
    c.put(20, 96, "STEEL")                              # its curl shadow
    c.put(15, 92, "PALE"); c.put(13, 89, "PALE")        # loose scrap flying

    # --- cool steel rim light on the trailing right edge ---
    c.line(77, 90, 76, 110, "STEEL", 1)

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- legs first: trailing boot under the hem, lead leg bared by the slit ---
    c.rect(26, 55, 29, 59, "DUSK")                      # trailing boot
    c.line(26, 59, 29, 59, "VOID", 1)
    c.rect(34, 44, 38, 55, "DUSK")                      # lead shin, mid-stride
    c.rect(34, 56, 41, 59, "DUSK")                      # lead foot stepping out
    c.line(34, 59, 41, 59, "VOID", 1)
    c.put(35, 47, "SLATE"); c.put(35, 52, "SLATE")      # shaft glints
    c.put(35, 44, "STEEL")                              # knee rim

    # --- plum robe, slit torn open viewer-right so the lead leg reads ---
    c.poly([(26, 31), (38, 31), (40, 38), (35, 44), (31, 50), (29, 55), (23, 55)], "PLUM")
    c.curve([(39, 34), (39, 38), (34, 44), (30, 50), (29, 54)], "NAVY", 1)   # slit shade
    # bold teal lightning panel down the front, cyan flickers
    c.curve([(30, 33), (28, 38), (32, 43), (29, 48), (31, 53)], "TEAL", 2)
    c.put(32, 43, "CYAN"); c.put(31, 53, "CYAN")
    c.line(24, 54, 28, 54, "TEAL", 1)                   # hem trim
    # sash
    c.line(25, 41, 36, 41, "DUSK", 1)
    c.put(31, 41, "STEEL")

    # --- pocketed arm (viewer-left): seam only ---
    c.line(26, 34, 25, 43, "NAVY", 1)

    # --- steel mantle over the shoulders ---
    c.poly([(24, 30), (40, 30), (41, 35), (32, 38), (23, 35)], "STEEL")
    c.line(25, 30, 33, 30, "PALE", 1)                   # lit top-left
    c.line(40, 31, 40, 34, "SLATE", 1)                  # right shade
    c.curve([(23, 35), (32, 38), (41, 35)], "DUSK", 1)  # hem edge

    # --- gesture arm (viewer-right): two fingers up toward the orb ---
    c.line(39, 36, 44, 31, "PLUM", 2)
    c.put(46, 30, "DUSK"); c.put(47, 30, "DUSK")        # glove
    c.put(46, 29, "DUSK"); c.put(46, 28, "DUSK")        # finger 1
    c.put(48, 29, "DUSK"); c.put(48, 28, "DUSK")        # finger 2

    # --- head: chibi, hard diagonal cyan wedge over teal buzz ---
    c.ellipse(32, 21, 8, 7, "SKIN_LIGHT")
    # buzzed right side
    c.poly([(37, 10), (41, 13), (42, 19), (39, 15)], "TEAL")
    # cyan sweep: crown flying left with a pointed tip, kept above the brows
    c.ellipse(31, 13, 8, 5, "CYAN")
    c.poly([(37, 9), (28, 7), (19, 9), (12, 13), (19, 14), (15, 17), (23, 16), (31, 13)], "CYAN")
    c.poly([(27, 14), (20, 16), (15, 17), (23, 15)], "TEAL")    # underside shade
    c.line(37, 9, 34, 12, "NAVY", 1)                    # hard part line
    c.line(24, 16, 22, 17, "CYAN", 1)                   # fringe tip, above brow

    # --- face: half-lidded, bored ---
    c.line(25, 19, 28, 19, "VOID", 1)                   # left lid
    c.rect(26, 20, 27, 21, "VOID")
    c.put(26, 20, "CYAN")
    c.line(34, 19, 37, 19, "VOID", 1)                   # right lid
    c.rect(35, 20, 36, 21, "VOID")
    c.put(35, 20, "CYAN")
    c.line(30, 25, 33, 25, "SKIN_SHADOW", 1)            # flat mouth

    # --- the storm orb: big teal-to-cyan focus floating clear of the hand ---
    c.ellipse(51, 21, 4, 4, "TEAL")                     # shell
    c.ellipse(51, 21, 3, 3, "CYAN")                     # glowing body
    c.put(49, 19, "PALE"); c.put(50, 20, "PALE")        # hot glint (key light)
    c.put(53, 23, "NAVY")                               # turbulence fleck
    # 1px lightning arcs — short zigzags jumping off the shell
    c.line(54, 17, 56, 15, "CYAN", 1); c.put(55, 13, "CYAN")
    c.line(47, 25, 45, 27, "CYAN", 1); c.put(43, 26, "CYAN")
    c.put(56, 22, "CYAN")                               # side spark
    c.put(49, 27, "CYAN")                               # spark at the fingertips

    # --- tome: steel slab floating at the hip, lane side ---
    c.rect(45, 40, 49, 42, "SLATE")
    c.line(45, 40, 49, 40, "STEEL", 1)
    c.put(47, 39, "PALE")                               # page tick

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
    save(key, os.path.join(out, "caster_2_key.png"), 1)
    save(key, os.path.join(out, "caster_2_key@3x.png"), 3)
    save(iso, os.path.join(out, "caster_2_iso.png"), 1)
    save(iso, os.path.join(out, "caster_2_iso@4x.png"), 4)
    print("caster_2: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
