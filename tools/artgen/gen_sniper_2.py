"""sniper_2 — Liriel Vess, elf huntress in moonlight pale.

Key art: aerial twist-shot — kicked backwards off a crumbling ledge, hanging
at the apex, body arced like a drawn bow, torso twisted back toward the
target below-left, recurve longbow at full draw at a high anchor past her
ear. White hair and gold sash stream up toward the ledge she left; hawk
fringe parted over the single gold eye sighting down the arrow. Legs
scissored, toes pointed.

Iso: chibi standing quarter-turn at full draw, bow arm extended toward the
lane, tall pale bow arc with gold tips past her head, back heel lifted.

Run from repo root: python3 tools/artgen/gen_sniper_2.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- crumbling ledge upper-right: the stone she kicked off ---
    c.poly([(102, 0), (127, 0), (127, 30), (114, 26), (106, 16), (103, 8)], "SLATE")
    c.poly([(112, 0), (127, 0), (127, 12), (118, 8)], "GRAY")        # lit top
    c.poly([(110, 18), (120, 24), (127, 30), (127, 22), (116, 16)], "DUSK")
    c.line(109, 6, 114, 18, "DUSK", 1)                                # crack
    # fragments trailing between the ledge and her kicked toe
    c.rect(108, 42, 111, 45, "SLATE"); c.put(111, 45, "DUSK")
    c.rect(116, 58, 118, 60, "SLATE"); c.put(118, 60, "DUSK")
    c.put(104, 54, "GRAY"); c.put(120, 38, "GRAY"); c.put(98, 34, "GRAY")

    # --- streaming hair: palest mass on the board, one flowing banner
    # whipping up-left with the twist, wave tips all flicking upward ---
    c.poly([
        (58, 86), (48, 80), (40, 72), (32, 62), (26, 52), (16, 40),  # outer edge
        (28, 46), (24, 28),                               # deep notch, tip 2
        (38, 38), (40, 22),                               # deep notch, tip 3
        (50, 34), (54, 26),                               # notch, top tip
        (56, 38), (59, 50), (61, 60), (63, 68),           # inner edge to crown
        (60, 76), (56, 82),
    ], "PALE")
    # STEEL shade along the inner/under edge (light is top-left)
    c.poly([(57, 38), (59, 48), (61, 58), (63, 68), (60, 76), (56, 82),
            (52, 76), (55, 64), (54, 50)], "STEEL")
    # each wave tip shaded on its trailing (right/lower) side
    c.line(20, 42, 27, 48, "STEEL", 1)
    c.line(24, 32, 28, 44, "STEEL", 1)
    c.line(39, 26, 39, 36, "STEEL", 1)
    c.line(55, 27, 53, 34, "STEEL", 1)
    # slate parting lines following the flow
    c.curve([(48, 76), (38, 62), (30, 50)], "SLATE", 1)
    c.curve([(56, 72), (48, 58), (42, 44)], "SLATE", 1)
    c.curve([(52, 42), (48, 32)], "SLATE", 1)
    # one thin streamer trailing right so the ear cuts through hair
    c.poly([(74, 72), (80, 64), (88, 52), (93, 42), (86, 56), (78, 68),
            (73, 78)], "PALE")
    c.line(81, 62, 88, 51, "STEEL", 1)

    # --- gold sash: knotted at the hip, a ribbon streaming up past the
    # torso's open side (behind the draw arm, painted later) ---
    c.poly([(82, 130), (88, 124), (96, 112), (98, 100), (103, 88), (101, 76),
            (105, 66), (102, 64), (98, 76), (100, 88), (95, 100), (93, 112),
            (85, 124), (79, 128)], "GOLD")
    c.curve([(86, 122), (94, 111), (96, 101)], "PALE_GOLD", 1)       # lit edge
    c.line(99, 92, 101, 90, "BRONZE", 1)                             # fold
    c.put(104, 62, "GOLD"); c.put(103, 59, "PALE_GOLD")              # flick

    # --- scissored legs, toes pointed ---
    # leg A: kicked back toward the ledge it just left (near horizontal)
    c.line(84, 126, 102, 118, "PALE", 5)                  # thigh
    c.line(102, 118, 116, 108, "PALE", 4)                 # calf
    c.line(86, 122, 102, 115, "STEEL", 1)                 # top-edge crease
    c.poly([(112, 109), (119, 103), (127, 93), (122, 94), (114, 100),
            (108, 105)], "UMBER")                          # tapered pointed boot
    c.put(126, 93, "BROWN"); c.put(125, 94, "BROWN")      # toe light
    c.line(110, 107, 113, 110, "BROWN", 1)                # boot cuff
    # leg B: bent down-back, toe pointed straight down
    c.line(84, 134, 100, 150, "PALE", 5)                  # thigh
    c.line(100, 150, 96, 168, "PALE", 4)                  # calf
    c.line(87, 138, 99, 149, "STEEL", 1)
    c.poly([(92, 166), (101, 166), (102, 178), (97, 184), (92, 174)], "UMBER")
    c.line(93, 167, 100, 167, "BROWN", 1)                 # boot cuff
    c.put(98, 182, "BROWN")                               # toe light

    # --- torso: arched like a drawn bow, PALE_GOLD huntress tunic ---
    c.poly([(56, 102), (74, 96), (84, 104), (90, 116), (88, 126),
            (74, 128), (60, 116)], "PALE_GOLD")
    c.poly([(82, 110), (89, 118), (87, 125), (78, 126), (82, 118)], "GOLD")
    c.line(62, 110, 76, 116, "GOLD", 1)                   # arch fold
    c.line(58, 103, 66, 100, "GOLD", 1)                   # collar seam
    # pelvis in PALE leggings so both thighs attach believably
    c.poly([(74, 126), (88, 124), (92, 134), (86, 140), (76, 136)], "PALE")
    c.line(88, 130, 85, 137, "STEEL", 1)
    # sash knot at the hip
    c.ellipse(79, 130, 3, 3, "BRONZE")
    c.put(78, 128, "GOLD"); c.put(77, 129, "GOLD")

    # --- bow arm: bare huntress arm, leather bracer, grip hand ---
    c.poly([(56, 100), (63, 100), (62, 106), (56, 106)], "PALE_GOLD")  # cap sleeve
    c.line(58, 106, 50, 120, "SKIN_LIGHT", 4)             # bare upper arm
    c.line(56, 106, 49, 118, "SKIN_PALE", 1)              # lit top edge
    c.line(50, 120, 45, 134, "BROWN", 4)                  # bracer
    c.line(48, 123, 45, 131, "UMBER", 1)                  # bracer shade
    c.put(50, 118, "BRONZE"); c.put(48, 126, "BRONZE")    # bracer studs
    c.ellipse(44, 138, 3, 3, "SKIN_LIGHT")                # grip hand
    c.put(42, 136, "SKIN_PALE")

    # --- neck + head: face turned down-left, sighting the arrow ---
    c.line(67, 97, 69, 102, "SKIN_LIGHT", 3)
    c.ellipse(66, 85, 10, 11, "SKIN_PALE")                # face
    c.line(62, 95, 60, 94, "SKIN_LIGHT", 1)               # jaw toward target
    c.line(70, 95, 72, 93, "SKIN_LIGHT", 1)               # jaw shade right

    # --- long pointed elf ear cutting through the hair streamer ---
    c.poly([(73, 80), (86, 69), (91, 63), (82, 70), (74, 77)], "SKIN_PALE")
    c.line(78, 76, 86, 70, "SKIN_LIGHT", 1)               # ear underside
    c.put(91, 63, "SKIN_LIGHT"); c.put(90, 64, "SKIN_LIGHT")   # ear tip
    c.line(76, 80, 84, 73, "SLATE", 1)                    # separate from jaw

    # --- crown + hawk-wing fringe over her left (viewer-right) eye ---
    c.ellipse(66, 71, 10, 6, "PALE")                      # crown, above the brow
    c.poly([(66, 67), (76, 71), (73, 86), (67, 90)], "PALE")   # hawk fringe
    c.line(73, 76, 70, 86, "STEEL", 1)                    # fringe inner shade
    c.put(68, 89, "STEEL")                                # fringe point
    c.curve([(75, 74), (72, 84), (68, 90)], "SLATE", 1)   # fringe edge line
    c.poly([(56, 71), (53, 84), (56, 95), (60, 86)], "PALE")   # left side lock
    c.line(56, 79, 57, 91, "STEEL", 1)
    c.curve([(59, 67), (64, 65), (70, 67)], "PALE", 2)    # crest catches light

    # --- face: the single gold eye, sighting down the arrow ---
    c.line(55, 80, 62, 79, "SLATE", 1)                    # focused brow
    c.rect(56, 83, 64, 89, "PALE")                        # sclera
    c.line(55, 82, 65, 82, "VOID", 1)                     # lash line
    c.put(55, 83, "VOID"); c.put(65, 83, "VOID")          # lash corners
    c.rect(58, 84, 62, 89, "GOLD")                        # big gold iris
    c.line(58, 84, 62, 84, "BRONZE", 1)                   # iris top shade
    c.rect(59, 86, 60, 88, "VOID")                        # pupil aimed low-left
    c.put(58, 85, "PALE_GOLD"); c.put(59, 85, "PALE_GOLD")     # catchlight
    c.line(56, 90, 64, 90, "SKIN_LIGHT", 1)               # lower lid
    c.put(59, 90, "SKIN_LIGHT")                           # nose tick
    c.line(59, 93, 62, 93, "SKIN_SHADOW", 1)              # set, steady mouth

    # --- draw arm: bare, elbow high behind, hand anchored at the cheek ---
    c.poly([(76, 98), (82, 96), (84, 102), (78, 104)], "PALE_GOLD")  # cap sleeve
    c.line(82, 100, 98, 86, "SKIN_LIGHT", 4)              # upper arm to elbow
    c.line(82, 98, 96, 85, "SKIN_PALE", 1)                # lit top edge
    c.line(98, 87, 78, 94, "SKIN_LIGHT", 3)               # forearm to cheek
    c.line(96, 84, 80, 91, "VOID", 1)                     # fold line between them
    c.line(95, 90, 82, 95, "SKIN_SHADOW", 1)              # forearm underside
    c.ellipse(77, 94, 2, 2, "SKIN_LIGHT")                 # anchor hand at cheek
    c.put(76, 93, "SKIN_PALE")
    c.put(75, 95, "VOID")                                 # knuckle vs jaw

    # --- the recurve longbow at full draw (limbs bow toward the target) ---
    c.curve([(18, 116), (22, 122), (27, 130), (36, 135), (44, 138)], "PALE", 2)
    c.curve([(44, 138), (52, 143), (60, 149), (66, 155), (70, 160)], "PALE", 2)
    c.curve([(22, 121), (28, 129), (36, 134)], "STEEL", 1)      # limb shade
    c.curve([(50, 143), (58, 149), (66, 156)], "STEEL", 1)
    # recurve tips flick back, lacquered GOLD
    c.curve([(18, 116), (15, 111), (16, 106)], "GOLD", 2)
    c.curve([(70, 160), (74, 164), (79, 166)], "GOLD", 2)
    c.put(16, 105, "PALE_GOLD"); c.put(80, 165, "PALE_GOLD")
    # bronze riser wrapped in brown grip
    c.line(40, 134, 48, 142, "BRONZE", 3)
    c.line(43, 137, 46, 140, "BROWN", 2)
    # grip hand back on top of the riser
    c.ellipse(44, 138, 2, 2, "SKIN_LIGHT")
    c.put(43, 137, "SKIN_PALE"); c.put(45, 140, "SKIN")
    # arrow: nocked at the cheek, head beyond the riser, flying down-left
    c.line(79, 96, 34, 149, "BROWN", 1)
    c.line(66, 112, 46, 135, "BRONZE", 1)                 # lit shaft edge
    c.poly([(33, 148), (28, 158), (37, 153)], "STEEL")    # arrowhead
    c.put(30, 155, "PALE")
    c.line(82, 99, 79, 95, "GOLD", 1)                     # fletching
    c.line(84, 102, 81, 98, "GOLD", 1)
    # string last: tip -> nock at the anchor hand -> tip
    c.line(17, 115, 76, 93, "STEEL", 1)
    c.line(77, 95, 71, 159, "STEEL", 1)

    # --- cool rim light on the trailing back edge ---
    c.line(91, 122, 90, 130, "PALE", 1)

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- the tall bow arc, extending past her head (behind everything) ---
    c.curve([(14, 6), (11, 16), (10, 28), (11, 40), (15, 52)], "PALE", 2)
    c.curve([(12, 18), (11, 28), (12, 38)], "STEEL", 1)   # limb shade
    c.put(14, 5, "GOLD"); c.put(15, 4, "GOLD"); c.put(15, 3, "PALE_GOLD")
    c.put(16, 53, "GOLD"); c.put(17, 54, "GOLD"); c.put(18, 54, "PALE_GOLD")
    c.line(10, 26, 12, 31, "BRONZE", 2)                   # riser
    # string at full draw: tips -> draw hand by her cheek
    c.line(15, 6, 40, 22, "STEEL", 1)
    c.line(40, 23, 16, 52, "STEEL", 1)
    # arrow: from the draw hand through the riser toward the lane
    c.line(40, 22, 6, 28, "BROWN", 1)
    c.put(5, 28, "STEEL"); c.put(4, 29, "STEEL")          # arrowhead
    c.put(39, 21, "GOLD"); c.put(40, 20, "GOLD")          # fletching

    # --- boots at the pivot (32,60); back heel lifted ---
    c.rect(27, 55, 32, 59, "UMBER")
    c.line(27, 59, 32, 59, "VOID", 1)
    c.rect(34, 53, 39, 57, "UMBER")                        # back foot, heel up
    c.line(35, 57, 39, 56, "VOID", 1)
    c.put(28, 55, "BROWN"); c.put(35, 53, "BROWN")        # boot cuffs

    # --- legs: pale leggings ---
    c.rect(28, 46, 31, 55, "PALE")
    c.rect(33, 46, 37, 53, "PALE")
    c.line(31, 48, 31, 54, "STEEL", 1)
    c.line(36, 48, 36, 52, "STEEL", 1)

    # --- tunic: PALE_GOLD, short skirt flare ---
    c.poly([(27, 34), (38, 34), (40, 47), (26, 47)], "PALE_GOLD")
    c.poly([(37, 36), (38, 34), (40, 47), (36, 47)], "GOLD")   # right shade
    c.rect(28, 44, 29, 46, "GOLD")                        # hip sash knot dot
    c.put(28, 44, "PALE_GOLD"); c.put(30, 45, "BRONZE")

    # --- long back hair falling behind the body, past the waist ---
    c.poly([(34, 8), (42, 13), (45, 24), (44, 42), (40, 44), (41, 28),
            (38, 16)], "PALE")
    c.line(43, 22, 43, 38, "STEEL", 1)

    # --- head: the pale hair mass, brightest thing on the board ---
    c.ellipse(32, 19, 9, 8, "SKIN_PALE")                  # face base
    c.ellipse(32, 13, 10, 7, "PALE")                      # hair crown
    # hawk fringe: diagonal notch swept over her left (viewer-right) eye
    c.poly([(33, 11), (39, 14), (37, 23), (33, 20)], "PALE")
    c.line(37, 16, 36, 22, "STEEL", 1)
    c.put(37, 22, "STEEL")
    # ear tips poking through the hair
    c.put(22, 14, "SKIN_PALE"); c.put(21, 13, "SKIN_LIGHT")
    c.put(43, 12, "SKIN_PALE"); c.put(44, 11, "SKIN_LIGHT")
    c.curve([(25, 9), (30, 7), (36, 8)], "PALE", 1)       # crest
    c.line(40, 10, 42, 14, "STEEL", 1)                    # crown right shade

    # --- arms: bare bow arm extended to the riser, draw hand at cheek ---
    c.line(28, 34, 16, 30, "SKIN_LIGHT", 2)               # bow arm
    c.line(19, 31, 16, 30, "BROWN", 2)                    # bracer
    c.ellipse(13, 29, 1, 1, "SKIN_LIGHT")                 # grip hand
    c.line(37, 32, 40, 26, "SKIN_LIGHT", 2)               # draw arm up
    c.ellipse(40, 23, 2, 1, "SKIN_LIGHT")                 # anchor hand

    # --- chibi face: single visible gold eye (fringe hides the other) ---
    c.line(25, 15, 28, 15, "SLATE", 1)                    # brow
    c.line(25, 17, 28, 17, "VOID", 1)                     # lash line
    c.rect(26, 18, 27, 21, "VOID")                        # eye block
    c.put(26, 18, "PALE_GOLD")                            # catchlight
    c.put(27, 18, "GOLD")                                 # gold iris
    c.put(26, 19, "GOLD"); c.put(27, 19, "GOLD")
    c.put(30, 23, "SKIN_LIGHT")                           # nose hint
    c.line(28, 25, 31, 25, "SKIN_SHADOW", 1)              # steady mouth

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
    save(key, os.path.join(out, "sniper_2_key.png"), 1)
    save(key, os.path.join(out, "sniper_2_key@3x.png"), 3)
    save(iso, os.path.join(out, "sniper_2_iso.png"), 1)
    save(iso, os.path.join(out, "sniper_2_iso@4x.png"), 4)
    print("sniper_2: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
