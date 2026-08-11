"""guard_1 — Dagr Vosk, silver-haired cleaver guard.

Key art: airborne falling cleave — caught at the top-turn of a leap, body
corkscrewed, both hands hauling the huge single-edged greatsword through a
downward diagonal that trails a crimson-to-gold ember arc across the frame.
Scuffed leather coat and crimson sash flared wide by the spin, knees tucked,
fanged grin, one eye squinted.

Iso: chibi standing with the oversized cleaver resting across one shoulder,
tip well past his silhouette; PALE spiky hair mass, crimson sash band.

Run from repo root: python3 tools/artgen/gen_guard_1.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- ember arc: painted on an overlay and merged UNDER the figure
    #     after outline(), so the trail reads as light, not outlined sticks ---
    fx = Canvas(128, 224)
    fx.line(116, 14, 112, 30, "CRIMSON", 2)
    fx.line(106, 48, 98, 66, "CRIMSON", 2)
    fx.line(88, 84, 76, 100, "CRIMSON", 2)
    fx.line(62, 114, 50, 126, "CRIMSON", 2)
    fx.line(40, 132, 30, 140, "CRIMSON", 2)
    fx.line(113, 20, 108, 36, "CORAL", 1)
    fx.line(101, 54, 93, 70, "CORAL", 1)
    fx.line(83, 88, 72, 102, "CORAL", 1)
    fx.line(57, 116, 47, 126, "CORAL", 1)
    fx.line(110, 26, 106, 38, "GOLD", 1)
    fx.line(96, 60, 90, 72, "GOLD", 1)
    fx.line(78, 92, 68, 104, "GOLD", 1)
    for x, y in ((119, 30), (112, 52), (102, 80), (88, 104), (70, 124),
                 (52, 140), (120, 8), (96, 58), (80, 116), (38, 148)):
        fx.put(x, y, "PALE_GOLD")                      # drifting sparks

    # --- small coat collar-flip trailing behind the plated shoulder ---
    c.poly([(82, 76), (92, 70), (98, 62), (90, 64), (84, 70)], "BROWN")
    c.poly([(90, 68), (96, 63), (91, 65)], "UMBER")
    # --- coat flap flung out viewer-left, horizontal with the spin ---
    c.poly([(60, 84), (48, 84), (36, 80), (24, 82), (30, 88), (20, 92),
            (32, 96), (44, 96), (56, 96)], "BROWN")
    c.poly([(36, 88), (26, 90), (32, 94), (42, 94)], "UMBER")
    c.poly([(38, 86), (28, 84), (34, 90), (42, 92)], "CRIMSON")  # lining

    # --- legs: swept back-right by the spin, knees bent, airborne ---
    # far leg (viewer-right): trailing high behind
    c.line(78, 106, 90, 122, "DUSK", 6)                # thigh back-right
    c.line(90, 122, 102, 127, "DUSK", 6)               # shin kicked back
    c.poly([(100, 120), (112, 124), (114, 134), (104, 136), (98, 130)],
           "UMBER")                                    # trailing boot
    c.line(102, 134, 112, 133, "VOID", 1)              # sole
    # near leg: knee dropped under him, shin folded
    c.line(70, 108, 62, 130, "SLATE", 7)               # thigh
    c.line(62, 130, 76, 142, "DUSK", 6)                # shin folded back
    c.poly([(74, 138), (88, 142), (90, 154), (78, 156), (70, 148)], "BROWN")
    c.poly([(82, 142), (90, 146), (90, 154), (82, 154)], "UMBER")  # boot shade
    c.line(74, 154, 88, 154, "VOID", 1)                # sole
    c.put(76, 146, "BRONZE")                           # scuff

    # --- torso: leather coat body, corkscrewed, leaning into the cut ---
    c.poly([(62, 66), (84, 64), (88, 84), (82, 106), (66, 110), (58, 86)],
           "BROWN")
    c.poly([(82, 68), (88, 84), (82, 106), (78, 104), (82, 84)], "UMBER")
    # open coat: dark shirt + crimson lining slivers
    c.poly([(68, 68), (78, 66), (76, 94), (68, 96)], "DUSK")
    c.line(67, 70, 66, 96, "CRIMSON", 1)               # lining flash left
    c.line(79, 68, 77, 93, "CRIMSON", 1)               # lining flash right
    c.line(71, 78, 74, 78, "SLATE", 1)                 # shirt fold light

    # --- crimson sash: knotted at the hip, tail whipping up-right ---
    c.poly([(62, 102), (80, 100), (82, 108), (64, 110)], "CRIMSON")  # wrap
    c.ellipse(66, 106, 3, 3, "WINE")                   # knot
    c.put(65, 105, "CRIMSON")
    # tail streaming up-right with the spin, forked tips
    c.poly([(80, 102), (92, 100), (104, 92), (114, 80), (107, 82),
            (112, 68), (102, 78), (92, 88), (82, 96)], "CRIMSON")
    c.poly([(104, 84), (112, 72), (106, 76), (108, 66), (100, 78)], "WINE")
    c.curve([(84, 98), (94, 94), (104, 86)], "CORAL", 1)  # lit top edge

    # --- both arms hauled down-left to the grip at hip height ---
    # far arm: coat sleeve from the plated shoulder
    c.line(63, 72, 55, 80, "BROWN", 5)
    c.line(55, 80, 49, 86, "BROWN", 4)
    c.line(61, 72, 51, 82, "BRONZE", 1)                # sleeve top light
    # near arm: bare + bandaged, crossing the body to the grip
    c.line(80, 68, 66, 78, "SKIN", 5)
    c.line(66, 78, 54, 87, "SKIN", 4)
    c.line(78, 66, 56, 83, "SKIN_LIGHT", 1)            # top-lit edge
    c.line(70, 74, 72, 79, "GRAY", 2)                  # bandage wraps
    c.line(62, 80, 64, 85, "GRAY", 2)
    c.line(57, 84, 58, 88, "GRAY", 2)
    c.put(71, 80, "SLATE"); c.put(63, 86, "SLATE")     # wrap shadows

    # --- the cleaver: swung PAST the body, blade down-left, follow-through ---
    # wine grip showing only ABOVE the fists, pommel at its end
    c.line(51, 84, 55, 77, "WINE", 3)
    c.put(52, 82, "CRIMSON")                           # wrap light
    c.ellipse(56, 75, 2, 2, "BRONZE")                  # pommel
    c.put(55, 74, "GOLD")
    # two clean fists stacked on the grip
    c.ellipse(46, 92, 3, 3, "SKIN_SHADOW")             # far hand
    c.ellipse(49, 87, 3, 3, "SKIN")                    # near hand
    c.put(48, 85, "SKIN_LIGHT"); c.put(47, 86, "SKIN_LIGHT")  # knuckles
    # small crossguard bar across the ricasso
    c.poly([(37, 92), (49, 99), (47, 103), (35, 96)], "BRONZE")
    c.line(38, 94, 46, 99, "GOLD", 1)
    # blade slab: strong down-left diagonal, cutting edge leading left,
    # slant-clipped cleaver tip
    c.poly([(39, 95), (47, 101), (20, 140), (2, 146), (8, 136)], "STEEL")
    c.line(46, 101, 20, 139, "SLATE", 2)               # spine shade band
    c.line(38, 95, 9, 134, "PALE", 1)                  # leading edge highlight
    c.line(19, 140, 3, 145, "PALE", 1)                 # clipped tip edge
    # nicks bitten out of the edge
    c.put(30, 106, "SLATE"); c.put(31, 107, "SLATE")
    c.put(20, 120, "SLATE"); c.put(21, 121, "SLATE")
    # fuller groove glint
    c.line(34, 106, 18, 128, "PALE", 1)
    # asymmetric steel shoulder plate on the coat-arm shoulder
    c.poly([(58, 66), (65, 62), (70, 66), (67, 72), (60, 72)], "STEEL")
    c.line(61, 70, 66, 71, "SLATE", 1)                 # plate underside
    c.line(60, 64, 65, 63, "PALE", 1)                  # plate rim light
    c.put(63, 67, "DUSK")                              # plate rivet

    # --- neck + head: looking down-left along the cut ---
    c.rect(69, 56, 73, 61, "SKIN_LIGHT")               # slim neck
    c.line(73, 56, 73, 61, "SKIN_SHADOW", 1)
    c.line(69, 56, 69, 60, "SKIN", 1)
    c.ellipse(70, 44, 10, 11, "SKIN_LIGHT")            # face
    c.line(65, 54, 74, 54, "SKIN", 1)                  # soft jaw shade

    # --- silver-white hair: wild spikes blown back up-right ---
    c.ellipse(72, 34, 12, 8, "PALE")                   # crown
    # back spikes streaming up-right (against motion)
    c.poly([(80, 28), (92, 20), (100, 18), (90, 28), (84, 32)], "PALE")
    c.poly([(82, 34), (96, 28), (104, 28), (92, 36), (86, 38)], "STEEL")
    c.poly([(76, 26), (84, 16), (88, 12), (84, 24), (80, 29)], "PALE")
    # top spikes
    c.poly([(62, 28), (64, 18), (68, 24), (66, 30)], "PALE")
    c.poly([(68, 25), (72, 14), (75, 23), (71, 29)], "PALE")
    c.poly([(74, 25), (80, 17), (81, 25), (76, 29)], "STEEL")
    # bangs over the brow, jagged
    c.poly([(60, 34), (64, 30), (66, 40), (61, 42)], "PALE")
    c.poly([(65, 31), (70, 29), (69, 41), (66, 39)], "PALE")
    c.poly([(70, 29), (76, 31), (74, 40), (71, 38)], "STEEL")
    c.poly([(76, 32), (81, 35), (79, 42), (76, 40)], "STEEL")
    # steel shadows in the mass (right/under, cool)
    c.curve([(82, 32), (86, 36), (84, 40)], "STEEL", 1)
    c.line(80, 26, 84, 24, "STEEL", 1)
    c.put(94, 22, "STEEL"); c.put(98, 19, "STEEL")

    # --- face: fanged grin, one eye squinted, crimson irises ---
    # fierce brows
    c.line(61, 40, 66, 39, "SLATE", 1)
    c.line(72, 39, 77, 41, "SLATE", 1)
    # wide eye (viewer-left): big anime eye, crimson iris, catchlight —
    # no VOID side walls so it doesn't read as a goggle box
    c.rect(61, 43, 67, 48, "PALE")
    c.line(60, 42, 68, 42, "VOID", 1)                  # lash line
    c.put(59, 43, "VOID")                              # outer lash wing only
    c.rect(63, 43, 66, 48, "CRIMSON")                  # iris off the left wall
    c.line(63, 43, 66, 43, "WINE", 1)                  # iris top shade
    c.line(63, 48, 66, 48, "CORAL", 1)                 # iris bottom glow
    c.rect(64, 45, 65, 46, "VOID")                     # pupil
    c.put(63, 44, "PALE_GOLD")                         # catchlight
    c.put(66, 47, "PALE_GOLD")                         # lower catchlight
    c.line(61, 49, 67, 49, "SKIN_SHADOW", 1)           # lower lid
    # squinted eye (viewer-right): a hard bent slit
    c.line(72, 44, 77, 45, "VOID", 1)
    c.line(72, 46, 76, 47, "SKIN_SHADOW", 1)
    c.put(78, 44, "VOID")
    # nose
    c.put(68, 49, "SKIN_SHADOW")
    # wide fanged grin, hitched — moved up so the chin stays skin
    c.line(62, 51, 72, 51, "VOID", 1)
    c.put(61, 50, "VOID"); c.put(73, 50, "VOID")
    c.rect(63, 52, 70, 53, "WINE")                     # open mouth
    c.put(64, 52, "PALE"); c.put(69, 52, "PALE")       # fangs
    c.line(64, 54, 70, 54, "SKIN_SHADOW", 1)           # under-lip
    # ember light on the near cheek (arc passes close)
    c.put(76, 49, "SKIN_PALE"); c.put(77, 51, "SKIN_PALE")

    # --- cool rim light on trailing edges ---
    c.line(88, 86, 86, 100, "PALE", 1)
    c.line(106, 76, 108, 84, "CORAL", 1)               # sash catching embers
    # wake ticks off the boots go on the overlay (unoutlined light)
    fx.line(96, 132, 90, 138, "PALE", 1)
    fx.line(104, 142, 100, 147, "STEEL", 1)

    c.outline("VOID")
    # merge the ember overlay UNDER the outlined figure
    for y in range(c.h):
        for x in range(c.w):
            if c.px[y][x] is None and fx.px[y][x] is not None:
                c.px[y][x] = fx.px[y][x]
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- cleaver resting across the right shoulder, tip well past the
    #     silhouette (clear of the hair spikes) ---
    c.poly([(42, 31), (47, 27), (61, 10), (57, 6), (44, 23), (40, 28)],
           "STEEL")
    c.line(41, 29, 58, 8, "SLATE", 1)                  # spine shade
    c.line(46, 28, 60, 11, "PALE", 1)                  # 1px edge highlight
    c.put(53, 17, "SLATE")                             # nick
    c.line(41, 31, 43, 33, "BRONZE", 2)                # tiny guard
    c.line(43, 34, 44, 37, "WINE", 2)                  # wine-wrapped grip

    # --- boots at the pivot (32, 60) ---
    c.rect(26, 54, 30, 59, "UMBER")
    c.rect(34, 54, 38, 59, "UMBER")
    c.line(26, 59, 38, 59, "VOID", 1)
    c.put(27, 55, "BROWN"); c.put(35, 55, "BROWN")     # toe light

    # --- legs ---
    c.rect(27, 48, 30, 53, "DUSK")
    c.rect(34, 48, 37, 53, "DUSK")

    # --- brown coat torso with crimson lining sliver ---
    c.poly([(24, 34), (40, 34), (42, 48), (22, 48)], "BROWN")
    c.poly([(37, 34), (40, 34), (42, 48), (38, 48)], "UMBER")  # shade right
    c.line(29, 35, 29, 43, "CRIMSON", 1)               # lining sliver
    c.line(30, 35, 30, 43, "DUSK", 1)                  # open shirt
    # crimson sash band at the waist
    c.rect(23, 44, 41, 46, "CRIMSON")
    c.put(26, 45, "WINE"); c.rect(26, 46, 28, 49, "CRIMSON")  # knot tail

    # --- arms: bare bandaged arm up to the grip, coat sleeve at his side ---
    c.line(39, 36, 43, 37, "SKIN", 2)                  # bare sword arm up
    c.put(41, 36, "GRAY"); c.put(42, 38, "GRAY")       # bandage wraps
    c.ellipse(45, 37, 2, 2, "SKIN")                    # fist on the grip
    c.put(44, 36, "SKIN_LIGHT"); c.put(45, 35, "SKIN_LIGHT")
    c.line(23, 37, 21, 43, "BROWN", 2)                 # coat sleeve
    c.ellipse(21, 45, 1, 1, "SKIN")

    # --- head: the PALE spiky hair mass is the biggest light block ---
    c.ellipse(31, 22, 9, 8, "SKIN_LIGHT")              # face base
    c.ellipse(31, 15, 10, 7, "PALE")                   # hair crown
    # spikes breaking the silhouette
    c.poly([(22, 14), (18, 8), (24, 11)], "PALE")
    c.poly([(26, 11), (25, 4), (30, 9)], "PALE")
    c.poly([(31, 9), (34, 2), (36, 9)], "PALE")
    c.poly([(37, 10), (42, 5), (40, 12)], "STEEL")
    c.poly([(40, 14), (46, 12), (41, 18)], "STEEL")
    c.poly([(21, 16), (24, 22), (21, 26), (19, 21)], "PALE")   # sideburn lock
    c.poly([(41, 16), (43, 21), (41, 26), (38, 22)], "STEEL")
    # steel shading right side of the crown
    c.curve([(39, 13), (40, 17), (39, 20)], "STEEL", 1)
    c.line(35, 10, 38, 12, "STEEL", 1)

    # --- chibi face: one wide eye, one squint, fang grin ---
    c.rect(26, 21, 27, 23, "VOID")                     # wide eye
    c.put(26, 21, "CRIMSON")
    c.put(26, 20, "PALE")
    c.line(34, 22, 36, 22, "VOID", 1)                  # squinted eye
    c.put(31, 25, "SKIN")                              # nose hint
    c.line(28, 27, 33, 27, "VOID", 1)                  # asymmetric grin
    c.put(34, 26, "VOID")                              # hitched corner
    c.put(29, 28, "PALE")                              # fang

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
    save(key, os.path.join(out, "guard_1_key.png"), 1)
    save(key, os.path.join(out, "guard_1_key@3x.png"), 3)
    save(iso, os.path.join(out, "guard_1_iso.png"), 1)
    save(iso, os.path.join(out, "guard_1_iso@4x.png"), 4)
    print("guard_1: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
