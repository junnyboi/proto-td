"""vanguard_2 — Juna Farrow, banner-vanguard of the company standard.

Key art: full-sprint vault over a fallen pillar, caught mid-air — leading
knee tucked high, trailing leg kicked back, the standard gripped in both
hands low across her hip like a lance so the gold-fringed green banner
streams horizontally behind her. Blond ponytail whipped high the other
way, head up, huge grin, eyes locked ahead of the frame.

Iso: chibi mid-stride, standard shouldered at a diagonal, banner block
trailing behind and above; ponytail and banner cross as paired diagonals.

Run from repo root: python3 tools/artgen/gen_vanguard_2.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- ponytail: blond whip streaming back-left, a second banner ---
    c.line(77, 33, 66, 28, "GOLD", 8)
    c.line(66, 28, 54, 24, "GOLD", 7)
    c.line(54, 24, 42, 22, "GOLD", 6)
    c.line(42, 22, 30, 24, "GOLD", 5)
    c.line(30, 24, 22, 29, "GOLD", 4)
    c.poly([(25, 28), (10, 39), (20, 25), (25, 22)], "GOLD")     # main tip
    c.poly([(32, 24), (24, 35), (30, 23)], "GOLD")               # flick
    c.poly([(48, 26), (40, 34), (46, 25)], "GOLD")               # loose strand
    # pale-gold crest along the top-lit edge
    c.line(64, 24, 52, 20, "PALE_GOLD", 2)
    c.line(52, 20, 42, 19, "PALE_GOLD", 2)
    c.line(34, 21, 26, 25, "PALE_GOLD", 1)
    # bronze underside away from the light
    c.line(70, 31, 58, 27, "BRONZE", 1)
    c.line(50, 26, 40, 25, "BRONZE", 1)
    c.line(28, 27, 23, 30, "BRONZE", 1)
    # tie band at the root, back of the head
    c.rect(74, 29, 78, 34, "BROWN")
    c.put(74, 30, "BRONZE")

    # --- fallen pillar (she is clearing it) ---
    c.rect(18, 164, 100, 192, "SLATE")
    c.ellipse(102, 178, 7, 13, "STEEL")                    # broken end cap
    c.ellipse(102, 178, 4, 9, "SLATE")
    c.ellipse(102, 178, 2, 5, "DUSK")
    c.line(18, 166, 96, 166, "STEEL", 2)                   # top-lit edge
    c.line(18, 190, 98, 190, "DUSK", 2)                    # underside shadow
    c.line(18, 175, 96, 175, "DUSK", 1)                    # fluting grooves
    c.line(18, 183, 96, 183, "DUSK", 1)
    c.curve([(44, 164), (48, 174), (44, 184)], "VOID", 1)  # crack
    c.curve([(70, 192), (74, 182)], "VOID", 1)
    c.rect(8, 186, 18, 193, "SLATE")                       # broken chunk
    c.line(9, 186, 16, 186, "STEEL", 1)
    # dust arcs kicked up behind her trailing boot
    c.curve([(28, 154), (38, 149), (48, 147)], "STEEL", 1)
    c.curve([(24, 160), (34, 156)], "GRAY", 1)
    c.put(20, 150, "GRAY"); c.put(52, 144, "STEEL")

    # --- banner: long green field streaming horizontally behind her ---
    c.poly([
        (54, 94), (30, 83), (16, 80), (2, 84),             # attach + top edge
        (0, 105),                                          # swallow tail 1
        (13, 99), (11, 111),                               # swallow tail 2
        (25, 102), (23, 112),                              # swallow tail 3
        (36, 103), (45, 100),
    ], "GREEN")
    # deep-green fold bands falling from the crests
    c.poly([(36, 88), (42, 91), (40, 100), (33, 100)], "DEEP_GREEN")
    c.poly([(15, 86), (19, 88), (17, 98), (11, 96)], "DEEP_GREEN")
    c.poly([(46, 92), (54, 94), (45, 100), (44, 95)], "DEEP_GREEN")
    # lime lit crest along the top edge
    c.curve([(28, 83), (16, 81), (4, 84)], "LIME", 1)
    # gold sunburst sigil: disc + eight clean rays
    c.ellipse(24, 92, 4, 4, "GOLD")
    c.ellipse(24, 92, 1, 1, "PALE_GOLD")
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        c.put(24 + dx * 6, 92 + dy * 6, "GOLD")
        c.put(24 + dx * 7, 92 + dy * 7, "GOLD")
    for dx, dy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        c.put(24 + dx * 4, 92 + dy * 4, "GOLD")
        c.put(24 + dx * 5, 92 + dy * 5, "GOLD")
    # gold fringe beads on the fly edge
    for x, y in ((1, 107), (0, 96), (11, 113), (23, 114), (36, 105), (1, 85)):
        c.put(x, y, "GOLD")

    # --- the standard's pole: lance-low diagonal across her hip ---
    c.line(28, 82, 120, 124, "BROWN", 3)
    c.line(29, 80, 119, 122, "BRONZE", 1)                  # brass-lit edge
    c.rect(24, 78, 29, 84, "BRONZE")                       # butt cap
    c.put(25, 79, "PALE_GOLD")
    # spear tip: steel leaf blade past the collar
    c.rect(116, 120, 121, 126, "BRONZE")                   # collar fitting
    c.poly([(120, 119), (127, 124), (126, 131), (118, 127)], "STEEL")
    c.line(126, 126, 122, 128, "SLATE", 1)                 # shadow side
    c.put(121, 122, "PALE"); c.put(123, 124, "PALE")       # glint

    # --- trailing leg: kicked back and up, boot toe pointing back ---
    c.line(70, 101, 56, 113, "DUSK", 7)                    # thigh
    c.line(56, 113, 46, 124, "DUSK", 5)                    # shin
    c.line(67, 98, 56, 108, "SLATE", 1)                    # top-lit seam
    c.poly([(34, 126), (48, 120), (53, 130), (39, 138)], "BROWN")   # boot
    c.poly([(34, 126), (39, 129), (36, 137), (34, 134)], "UMBER")   # heel shade
    c.line(37, 136, 51, 129, "UMBER", 1)                   # sole
    c.put(43, 126, "BRONZE")                               # scuff
    # speed dashes trailing the kicked boot
    c.line(22, 124, 29, 123, "STEEL", 1)
    c.line(18, 132, 26, 131, "GRAY", 1)

    # --- far arm (her right): down to the pole's rear grip ---
    c.line(78, 67, 70, 82, "STEEL", 4)
    c.line(70, 82, 67, 94, "STEEL", 3)
    c.line(72, 83, 69, 92, "SLATE", 1)                     # underside
    c.put(76, 73, "SLATE")                                 # scale dot
    c.rect(64, 92, 70, 96, "BROWN")                        # fingerless glove
    c.ellipse(67, 99, 3, 2, "SKIN")                        # fingers on pole
    c.put(65, 98, "SKIN_LIGHT")

    # --- torso: leaf-green tabard, leaning into the vault ---
    c.poly([(77, 63), (93, 67), (89, 86), (83, 102), (67, 100), (70, 80)], "GREEN")
    c.poly([(91, 72), (89, 86), (83, 100), (81, 100), (86, 85)], "DEEP_GREEN")
    c.line(78, 65, 91, 69, "LIME", 1)                      # lit collar edge
    c.line(70, 84, 86, 86, "DEEP_GREEN", 1)                # cloth fold
    # steel scale shirt at the collar and below the tabard hem
    c.rect(80, 61, 91, 65, "STEEL")
    c.put(83, 63, "SLATE"); c.put(87, 63, "SLATE")
    c.rect(68, 100, 83, 105, "STEEL")
    for x in range(69, 83, 4):
        c.put(x, 103, "SLATE")
    # belt
    c.line(68, 96, 83, 98, "BROWN", 2)
    c.put(75, 97, "BRONZE")                                # buckle

    # --- near arm (her left): drops behind the raised thigh to the grip ---
    c.line(91, 70, 90, 88, "STEEL", 5)
    c.line(90, 88, 80, 106, "STEEL", 4)
    c.line(92, 89, 83, 103, "SLATE", 1)                    # underside
    c.put(90, 77, "SLATE")                                 # scale dot
    c.line(87, 72, 87, 86, "VOID", 1)                      # seam vs tabard
    c.ellipse(91, 69, 3, 3, "GREEN")                       # tabard shoulder cap

    # --- leading leg: knee tucked high, shin folded under (over forearm) ---
    c.line(82, 100, 98, 83, "DUSK", 8)                     # thigh driving up
    c.line(98, 83, 97, 96, "DUSK", 5)                      # shin tucked down
    c.line(86, 95, 97, 84, "SLATE", 1)                     # top-lit seam
    c.line(84, 103, 96, 92, "VOID", 1)                     # thigh underside seam
    c.ellipse(100, 82, 3, 3, "STEEL")                      # knee guard on joint
    c.put(99, 80, "PALE")                                  # guard glint
    c.line(97, 85, 102, 85, "BRONZE", 1)                   # guard strap
    c.put(102, 83, "SLATE")                                # scuffed edge
    c.poly([(93, 96), (103, 96), (107, 102), (101, 107), (93, 104)], "BROWN")
    c.line(93, 96, 103, 96, "VOID", 1)                     # boot cuff seam
    c.poly([(93, 97), (97, 99), (95, 105), (93, 102)], "UMBER")
    c.line(96, 106, 106, 102, "UMBER", 1)                  # sole
    c.put(102, 99, "BRONZE")                               # scuff

    # --- her left fist re-emerging below the thigh, on the pole ---
    c.rect(74, 102, 80, 107, "BROWN")                      # fingerless glove
    c.ellipse(77, 109, 3, 3, "SKIN")                       # fist on pole
    c.put(75, 107, "SKIN_LIGHT")

    # --- neck + head (head up, facing right) ---
    c.rect(84, 58, 90, 65, "SKIN")
    c.line(89, 59, 89, 64, "SKIN_SHADOW", 1)
    c.ellipse(88, 51, 10, 11, "SKIN_LIGHT")                # face
    c.line(83, 60, 93, 60, "SKIN", 1)                      # jaw shade

    # --- front hair: blond bangs with pointed tufts ---
    c.ellipse(87, 38, 12, 8, "GOLD")                       # crown
    c.poly([(76, 36), (80, 30), (82, 46), (77, 48)], "GOLD")     # left lock
    c.poly([(95, 32), (100, 37), (99, 50), (94, 44)], "GOLD")    # right lock
    c.line(98, 39, 98, 48, "BRONZE", 1)                    # lock inner shade
    c.poly([(78, 37), (85, 32), (83, 42), (80, 41)], "GOLD")     # tuft 1
    c.poly([(85, 32), (91, 32), (89, 42), (86, 41)], "GOLD")     # tuft 2
    c.poly([(91, 32), (96, 34), (94, 43), (92, 40)], "GOLD")     # tuft 3
    c.line(93, 35, 93, 40, "BRONZE", 1)
    c.curve([(78, 33), (86, 29), (94, 30)], "PALE_GOLD", 2)      # crest light
    # flyaway strand whipped forward by the sprint
    c.curve([(95, 28), (100, 24), (103, 23)], "GOLD", 1)
    c.put(104, 23, "BRONZE")

    # --- face: big green anime eyes locked ahead, huge grin ---
    c.line(80, 42, 84, 41, "BRONZE", 1)                    # raised brows
    c.line(90, 41, 94, 42, "BRONZE", 1)
    # left eye (x79..86)
    c.rect(80, 44, 85, 50, "PALE")
    c.line(79, 43, 86, 43, "VOID", 1)
    c.put(79, 44, "VOID"); c.put(86, 44, "VOID")           # lash corners
    c.rect(81, 45, 84, 50, "GREEN")                        # iris
    c.line(81, 45, 84, 45, "DEEP_GREEN", 1)                # iris top shade
    c.rect(82, 47, 83, 48, "VOID")                         # pupil
    c.put(81, 46, "PALE_GOLD")                             # catchlight
    c.put(80, 50, "SKIN_LIGHT"); c.put(85, 50, "SKIN_LIGHT")
    c.line(80, 51, 85, 51, "SKIN_SHADOW", 1)               # lower lid
    # right eye (x88..95)
    c.rect(89, 44, 94, 50, "PALE")
    c.line(88, 43, 95, 43, "VOID", 1)
    c.put(88, 44, "VOID"); c.put(95, 44, "VOID")
    c.rect(90, 45, 93, 50, "GREEN")
    c.line(90, 45, 93, 45, "DEEP_GREEN", 1)
    c.rect(91, 47, 92, 48, "VOID")
    c.put(90, 46, "PALE_GOLD")
    c.put(89, 50, "SKIN_LIGHT"); c.put(94, 50, "SKIN_LIGHT")
    c.line(89, 51, 94, 51, "SKIN_SHADOW", 1)
    # tiny nose
    c.put(88, 52, "SKIN_SHADOW")
    # huge laughing grin: wide, corners pulled up, bright teeth row
    c.put(81, 51, "VOID"); c.put(95, 51, "VOID")           # corners pulled up
    c.put(82, 52, "VOID"); c.put(94, 52, "VOID")
    c.line(83, 53, 93, 53, "VOID", 1)                      # upper lip
    c.line(83, 54, 93, 54, "PALE", 1)                      # teeth
    c.line(84, 55, 92, 55, "WINE", 1)                      # open mouth
    # freckles
    for x, y in ((79, 52), (81, 53), (93, 52), (95, 53)):
        c.put(x, y, "ROSE")

    # --- cool rim light on the trailing back edge ---
    c.line(69, 86, 69, 96, "PALE", 1)

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- banner block: trailing behind and above, top-left ---
    c.poly([(17, 7), (3, 3), (5, 12), (1, 21), (16, 18)], "GREEN")
    c.line(15, 8, 15, 17, "DEEP_GREEN", 1)                 # shade near pole
    c.line(5, 4, 12, 5, "LIME", 1)                         # lit top edge
    c.ellipse(9, 12, 1, 1, "GOLD")                         # 3px sunburst dot
    c.put(9, 11, "PALE_GOLD")
    for x, y in ((3, 4), (4, 11), (2, 20), (8, 19)):       # fringe
        c.put(x, y, "GOLD")

    # --- pole: shouldered diagonal, steel tip up-left ---
    c.line(44, 52, 15, 11, "BROWN", 2)
    c.line(45, 51, 16, 10, "BRONZE", 1)
    c.poly([(14, 9), (12, 2), (17, 6)], "STEEL")           # spear tip
    c.put(13, 4, "PALE")

    # --- legs mid-stride, pivot (32,60) ---
    c.rect(33, 50, 37, 55, "DUSK")                         # front leg
    c.rect(26, 48, 30, 53, "DUSK")                         # back leg (lifted)
    c.put(35, 50, "STEEL"); c.put(28, 48, "STEEL")         # knee guards
    c.rect(33, 56, 38, 59, "BROWN")                        # front boot
    c.rect(24, 53, 29, 56, "BROWN")                        # back boot
    c.line(33, 59, 38, 59, "UMBER", 1)
    c.line(24, 56, 29, 56, "UMBER", 1)

    # --- torso: green tabard over steel band, belt ---
    c.rect(26, 34, 38, 46, "GREEN")
    c.rect(36, 36, 38, 46, "DEEP_GREEN")                   # shade right
    c.line(27, 34, 34, 34, "LIME", 1)                      # lit shoulder
    c.rect(26, 35, 38, 37, "STEEL")                        # scale collar band
    c.put(29, 36, "SLATE"); c.put(33, 36, "SLATE")
    c.line(26, 44, 38, 44, "BROWN", 1)                     # belt
    c.put(32, 44, "BRONZE")                                # buckle
    c.rect(26, 45, 38, 46, "STEEL")                        # scale hem

    # --- arms: near hand grips pole, far arm swings ---
    c.line(27, 38, 22, 43, "STEEL", 2)                     # far arm swing
    c.ellipse(21, 45, 1, 1, "SKIN")
    c.line(37, 38, 41, 44, "STEEL", 2)                     # near arm to pole
    c.rect(40, 44, 42, 46, "BROWN")                        # glove
    c.put(41, 47, "SKIN")                                  # fingers

    # --- head: big blond crown, ponytail whipping down-right ---
    c.ellipse(32, 22, 9, 8, "SKIN_LIGHT")                  # face
    c.ellipse(32, 16, 10, 7, "GOLD")                       # hair crown
    c.poly([(22, 16), (25, 24), (22, 28), (20, 21)], "GOLD")   # left lock
    c.poly([(42, 16), (44, 22), (42, 28), (39, 23)], "GOLD")   # right lock
    c.curve([(25, 12), (31, 9), (38, 11)], "PALE_GOLD", 1)     # crest light
    c.curve([(41, 20), (42, 15)], "BRONZE", 1)                 # right shade
    # ponytail: slim whip down-right, crossing the pole's diagonal
    c.line(42, 14, 49, 19, "GOLD", 3)
    c.line(49, 19, 53, 26, "GOLD", 2)
    c.poly([(52, 24), (56, 33), (50, 27)], "GOLD")             # pointed tip
    c.put(48, 16, "PALE_GOLD"); c.put(51, 20, "PALE_GOLD")
    c.line(50, 22, 53, 27, "BRONZE", 1)                        # underside
    c.rect(40, 13, 42, 16, "BROWN")                            # tie

    # --- chibi face: green eyes, 2px grin ---
    c.rect(27, 21, 28, 23, "VOID")                         # left eye
    c.put(27, 21, "GREEN")
    c.put(27, 20, "PALE")
    c.rect(35, 21, 36, 23, "VOID")                         # right eye
    c.put(35, 21, "GREEN")
    c.put(35, 20, "PALE")
    c.line(29, 27, 33, 27, "SKIN_SHADOW", 1)               # grin
    c.put(34, 26, "SKIN_SHADOW")                           # hitched corner
    c.put(25, 25, "ROSE"); c.put(38, 25, "ROSE")           # blush

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
    save(key, os.path.join(out, "vanguard_2_key.png"), 1)
    save(key, os.path.join(out, "vanguard_2_key@3x.png"), 3)
    save(iso, os.path.join(out, "vanguard_2_iso.png"), 1)
    save(iso, os.path.join(out, "vanguard_2_iso@4x.png"), 4)
    print("vanguard_2: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
