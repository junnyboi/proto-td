"""defender_2 — Sigrid Valebright, wall of the vale.

Key art: braced shield-slam, low and wide — kite shield just driven point-first
into cracked flagstones, left arm locked behind it, BOTH knees bent fencer-wide,
hips dropped. Warhammer cocked back over the right shoulder mid-backswing
(elbow bent, fist by the ear, head behind her), storm-teal tabard snapping
forward, gold crown-braid coiled around her head — a scalloped woven torus that
IS the hair silhouette — chin lifted, proud half-smile.

Iso: chibi behind a big flat NAVY kite shield (lane side) carrying a readable
CYAN gate-and-wave sigil, hammer resting up over the far shoulder, segmented
gold braid ring breaking the head silhouette.

Run from repo root: python3 tools/artgen/gen_defender_2.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- flagstone platform: lit GRAY top plane + DUSK front face ---
    # (drawn FIRST so boots and the shield tip sit ON it, never under it)
    c.rect(4, 185, 124, 191, "GRAY")                        # lit top surface
    c.rect(4, 192, 124, 206, "DUSK")                        # front face
    c.line(4, 192, 124, 192, "VOID", 1)                     # lip
    c.line(96, 185, 96, 191, "VOID", 1)                     # slab seams (top)
    c.line(74, 186, 74, 191, "VOID", 1)
    c.line(96, 193, 96, 205, "VOID", 1)                     # seams (face)
    c.line(84, 198, 84, 205, "VOID", 1)
    c.line(14, 194, 14, 205, "VOID", 1)

    # --- cloak: navy, snapping forward-left ABOVE the shield top ---
    c.poly([(68, 84), (52, 80), (36, 80), (22, 86), (12, 98),
            (26, 96), (44, 90), (58, 88)], "NAVY")
    c.poly([(32, 86), (20, 92), (14, 97), (28, 94)], "DUSK")
    c.curve([(52, 82), (36, 84), (24, 89)], "TEAL", 1)      # lit fold crest
    c.curve([(64, 83), (50, 80), (36, 80)], "STEEL", 1)     # lit top edge

    # --- far (viewer-left) leg: knee thrust out, shin raked back — a
    # --- readable V bend in the corridor between shield and tabard ---
    c.line(68, 124, 58, 148, "SLATE", 6)                    # thigh drops steep
    c.line(67, 122, 59, 144, "STEEL", 2)                    # lit top plane
    c.line(64, 128, 60, 148, "DUSK", 1)                     # under shade
    c.ellipse(58, 150, 4, 4, "STEEL")                       # knee cop (bent!)
    c.put(56, 148, "PALE"); c.put(57, 149, "PALE")
    c.put(61, 153, "DUSK")
    c.line(57, 152, 47, 171, "SLATE", 5)                    # shin rakes back-left
    c.line(59, 154, 49, 172, "DUSK", 1)                     # shadow side
    c.line(55, 153, 46, 169, "STEEL", 1)                    # lit shin edge
    # boot: heel high right, toe mass driving LEFT behind the shield
    c.poly([(40, 172), (52, 172), (56, 177), (55, 183), (30, 183),
            (30, 179), (38, 175)], "SLATE")
    c.line(38, 174, 50, 173, "STEEL", 1)                    # top edge light
    c.put(38, 179, "STEEL"); c.put(39, 178, "STEEL")        # instep glint
    c.line(53, 175, 55, 182, "DUSK", 1)                     # heel shade
    c.line(31, 182, 55, 182, "DUSK", 1)
    c.line(30, 183, 55, 183, "VOID", 1)                     # sole
    c.rect(31, 185, 56, 186, "SLATE")                       # contact shadow

    # --- near (viewer-right) leg: knee bent wide, foot planted flat ---
    c.line(88, 126, 108, 148, "SLATE", 8)                   # thigh out-down
    c.line(90, 124, 106, 143, "STEEL", 3)                   # lit top plane
    c.line(94, 132, 108, 151, "DUSK", 1)
    c.ellipse(111, 150, 5, 4, "STEEL")                      # knee cop (bent!)
    c.put(108, 148, "PALE"); c.put(109, 147, "PALE")
    c.put(114, 153, "DUSK")
    c.line(112, 153, 116, 171, "SLATE", 5)                  # shin drops back
    c.line(110, 154, 113, 169, "STEEL", 1)
    # boot: ankle, arch, toe mass pointing RIGHT out of the stance
    c.poly([(104, 173), (119, 172), (124, 176), (125, 181), (123, 184),
            (104, 184)], "SLATE")
    c.line(106, 173, 118, 172, "STEEL", 1)                  # top edge light
    c.line(119, 175, 123, 179, "STEEL", 1)                  # toe cap
    c.put(121, 177, "PALE")                                 # toe glint
    c.line(105, 182, 123, 182, "DUSK", 1)
    c.line(104, 183, 123, 183, "VOID", 1)                   # sole
    c.rect(105, 185, 124, 186, "SLATE")                     # contact shadow

    # --- hips / faulds: dropped LOW and wide between the bent knees ---
    c.poly([(60, 116), (94, 118), (98, 132), (56, 130)], "SLATE")
    c.line(61, 118, 93, 119, "STEEL", 1)
    c.line(58, 128, 96, 130, "DUSK", 2)

    # --- warhammer: cocked back over the right shoulder, mid-backswing ---
    c.line(98, 86, 121, 44, "UMBER", 3)                     # haft angled back
    c.line(100, 84, 122, 45, "BROWN", 1)                    # lit edge
    c.line(111, 61, 115, 59, "BRONZE", 1)                   # grip wrap
    # bronze-gold head held BEHIND her head height, not overhead
    c.poly([(104, 36), (124, 32), (125, 44), (106, 48)], "BRONZE")
    c.poly([(104, 36), (113, 34), (111, 45), (105, 46)], "GOLD")   # lit face
    c.line(105, 37, 112, 35, "PALE_GOLD", 1)                # top-left glint
    c.poly([(118, 33), (124, 32), (125, 44), (119, 45)], "UMBER")  # butt shade
    c.line(106, 47, 124, 44, "UMBER", 1)

    # --- her right arm: bent elbow, fist cocked by the ear ---
    c.line(87, 92, 103, 87, "SLATE", 5)                     # upper arm back
    c.line(88, 90, 102, 86, "STEEL", 2)
    c.ellipse(105, 86, 3, 3, "STEEL")                       # elbow couter
    c.put(103, 84, "PALE"); c.put(104, 85, "PALE")
    c.line(106, 83, 110, 70, "SLATE", 4)                    # forearm up-back
    c.line(104, 82, 108, 71, "STEEL", 1)
    c.ellipse(110, 66, 3, 3, "SKIN")                        # fist on haft
    c.line(108, 68, 112, 68, "SKIN_SHADOW", 1)
    c.line(109, 68, 112, 62, "UMBER", 1)                    # haft through fist
    c.put(108, 64, "SKIN_LIGHT"); c.put(107, 65, "SKIN_LIGHT")  # knuckles

    # --- torso: breastplate leaning forward-left into the slam ---
    c.poly([(62, 86), (86, 84), (92, 104), (90, 120), (64, 118), (58, 102)],
           "SLATE")
    c.poly([(62, 86), (74, 85), (70, 104), (60, 102)], "STEEL")  # key-lit plane
    c.line(63, 87, 73, 86, "PALE")                          # collar edge light
    c.line(87, 88, 91, 104, "DUSK", 2)                      # shadow side
    c.line(64, 100, 88, 100, "DUSK", 1)                     # plate seam
    # pauldrons (right one pulled back with the backswing)
    c.ellipse(62, 88, 6, 5, "STEEL")
    c.ellipse(61, 87, 3, 2, "PALE")
    c.ellipse(88, 88, 6, 5, "SLATE")
    c.line(90, 84, 93, 88, "DUSK", 1)
    c.put(85, 85, "STEEL")

    # --- tabard: storm-teal, tip whipped forward-left by the slam ---
    c.poly([(70, 94), (83, 94), (87, 120), (83, 144), (69, 138), (67, 112)],
           "TEAL")
    c.poly([(83, 106), (87, 120), (83, 142), (77, 138), (82, 120)], "NAVY")
    c.poly([(54, 130), (67, 122), (69, 134), (58, 142), (48, 136)], "TEAL")
    c.poly([(58, 132), (64, 127), (60, 138), (54, 136)], "NAVY")  # tip fold
    c.line(70, 95, 82, 95, "GOLD", 1)                       # chest trim
    c.curve([(48, 136), (58, 142), (69, 134), (83, 144)], "GOLD", 1)  # hem
    c.line(76, 98, 75, 114, "CYAN", 1)                      # sigil thread

    # --- belt ---
    c.line(62, 116, 92, 117, "UMBER", 2)
    c.put(77, 116, "GOLD"); c.put(78, 116, "PALE_GOLD")     # buckle

    # --- her left arm: locked behind the shield (drawn, then covered) ---
    c.line(64, 92, 52, 106, "SLATE", 5)
    c.line(52, 106, 44, 116, "DUSK", 4)

    # --- neck: lit column, shadow only under the jaw + right edge ---
    c.rect(69, 81, 75, 87, "SKIN_LIGHT")
    c.rect(70, 81, 75, 83, "SKIN_SHADOW")                   # cast jaw shadow
    c.line(74, 84, 74, 87, "SKIN", 1)                       # form shade right
    c.put(75, 84, "SKIN"); c.put(75, 85, "SKIN")

    # --- head ---
    c.ellipse(72, 70, 10, 11, "SKIN_LIGHT")                 # face
    c.line(66, 80, 76, 80, "SKIN", 1)                       # jaw shade

    # --- gold hair: skull cap + THE coiled crown-braid silhouette ---
    c.ellipse(72, 62, 10, 9, "GOLD")                        # skull cap
    c.curve([(79, 56), (82, 62), (82, 68)], "BRONZE", 2)    # cap shade right
    c.poly([(60, 60), (64, 66), (62, 75), (58, 67)], "GOLD")      # left lock
    c.line(60, 66, 60, 72, "BRONZE", 1)
    c.poly([(83, 60), (86, 66), (85, 75), (81, 66)], "GOLD")      # right lock
    c.line(84, 66, 84, 73, "BRONZE", 1)
    c.curve([(68, 55), (66, 60), (64, 64)], "BRONZE", 1)    # strand lines
    c.curve([(76, 55), (78, 60), (80, 64)], "BRONZE", 1)
    # coiled braid: thick torus ring WIDER and HIGHER than the skull...
    c.curve([(58, 63), (60, 55), (65, 49), (71, 46), (77, 46), (83, 50),
             (87, 56), (88, 63)], "GOLD", 6)
    # ...built from woven segments whose bumps scallop the silhouette
    for bx, by in ((56, 62), (58, 53), (64, 47), (71, 44), (78, 44),
                   (84, 48), (88, 54), (90, 61)):
        c.ellipse(bx, by, 3, 3, "GOLD")
    # per-segment lit crowns (top-left key light)
    c.ellipse(57, 52, 1.5, 1.5, "PALE_GOLD")
    c.ellipse(63, 46, 1.5, 1.5, "PALE_GOLD")
    c.ellipse(70, 43, 1.5, 1.5, "PALE_GOLD")
    c.put(55, 61, "PALE_GOLD"); c.put(77, 43, "PALE_GOLD")
    # shadow-side segments turn bronze
    c.ellipse(85, 49, 1.5, 1.5, "BRONZE")
    c.ellipse(89, 55, 1.5, 1.5, "BRONZE")
    c.ellipse(91, 62, 1.5, 1.5, "BRONZE")
    # woven seams: full-width bronze cuts BETWEEN segments
    c.line(56, 58, 60, 57, "BRONZE", 1)
    c.line(60, 50, 63, 51, "BRONZE", 1)
    c.line(66, 45, 68, 48, "BRONZE", 1)
    c.line(74, 43, 74, 47, "BRONZE", 1)
    c.line(80, 45, 81, 48, "BRONZE", 1)
    c.line(85, 51, 83, 53, "BRONZE", 1)
    c.line(89, 58, 86, 59, "BRONZE", 1)
    # inner seam separating the braid ring from the skull cap
    c.curve([(60, 63), (62, 56), (67, 51), (73, 49), (79, 50), (84, 54),
             (87, 60)], "BRONZE", 1)
    # bangs parted off the forehead, below the ring
    c.poly([(63, 61), (70, 59), (68, 66), (64, 66)], "GOLD")
    c.poly([(72, 59), (80, 61), (79, 66), (74, 66)], "GOLD")
    c.line(78, 62, 79, 65, "BRONZE", 1)
    c.put(66, 61, "PALE_GOLD"); c.put(67, 60, "PALE_GOLD")

    # --- face: proud half-smile, big cyan anime eyes ---
    c.line(64, 64, 69, 63, "BRONZE", 2)                     # brows (confident)
    c.line(75, 63, 80, 64, "BRONZE", 2)
    # left eye (x64..71)
    c.rect(65, 66, 70, 71, "PALE")
    c.line(64, 65, 71, 65, "VOID", 1)                       # lash line
    c.put(64, 66, "VOID"); c.put(71, 66, "VOID")
    c.rect(66, 67, 69, 71, "CYAN")                          # iris
    c.line(66, 67, 69, 67, "NAVY", 1)                       # iris top shade
    c.rect(67, 69, 68, 70, "VOID")                          # pupil
    c.put(66, 68, "PALE")                                   # catchlight
    c.line(65, 72, 70, 72, "SKIN_SHADOW", 1)                # lower lid
    # right eye (x75..82)
    c.rect(76, 66, 81, 71, "PALE")
    c.line(75, 65, 82, 65, "VOID", 1)
    c.put(75, 66, "VOID"); c.put(82, 66, "VOID")
    c.rect(77, 67, 80, 71, "CYAN")
    c.line(77, 67, 80, 67, "NAVY", 1)
    c.rect(78, 69, 79, 70, "VOID")
    c.put(77, 68, "PALE")
    c.line(76, 72, 81, 72, "SKIN_SHADOW", 1)
    # tiny nose + short proud half-smile, right corner hitched up
    c.put(73, 74, "SKIN_SHADOW")
    c.line(70, 77, 74, 77, "VOID", 1)
    c.put(75, 76, "VOID")                                   # hitched corner
    c.put(67, 74, "ROSE"); c.put(68, 74, "ROSE")            # cheek color
    c.put(80, 74, "ROSE"); c.put(81, 74, "ROSE")

    # --- kite shield: slammed point-first, front-most ---
    c.poly([(14, 100), (54, 92), (56, 116), (50, 152), (34, 190), (18, 152),
            (12, 120)], "STEEL")                            # rim
    c.poly([(18, 103), (50, 96), (52, 116), (46, 148), (34, 182), (22, 148),
            (16, 120)], "NAVY")                             # field
    c.poly([(44, 98), (50, 96), (52, 116), (46, 148), (34, 182), (34, 170),
            (42, 142), (46, 118)], "DUSK")                  # field shade right
    c.line(15, 101, 53, 93, "PALE", 1)                      # top edge light
    c.line(14, 102, 14, 122, "PALE", 1)
    # gate-and-wave sigil, CYAN, faint glow
    c.curve([(26, 126), (26, 116), (34, 112), (42, 116), (42, 126)],
            "CYAN", 1)                                      # gate arch
    c.line(26, 126, 26, 132, "CYAN", 1)                     # posts
    c.line(42, 126, 42, 132, "CYAN", 1)
    c.line(31, 118, 31, 126, "CYAN", 1)                     # portcullis bars
    c.line(37, 118, 37, 126, "CYAN", 1)
    c.curve([(24, 140), (30, 136), (36, 140), (42, 136)], "CYAN", 1)  # wave
    c.curve([(26, 146), (32, 142), (38, 146)], "TEAL", 1)   # wave echo
    c.put(34, 110, "PALE"); c.put(24, 124, "TEAL"); c.put(44, 124, "TEAL")
    # boss rivets
    for x, y in ((20, 106), (48, 100), (18, 134), (48, 134)):
        c.put(x, y, "STEEL")

    # --- impact FX: upheaved slabs + forked cracks around the buried tip ---
    c.poly([(16, 183), (30, 182), (28, 189), (14, 190)], "GRAY")   # left slab
    c.line(17, 183, 29, 182, "STEEL", 1)                    # lifted edge light
    c.poly([(65, 184), (76, 184), (74, 190), (64, 189)], "GRAY")   # right slab
    c.line(66, 184, 75, 184, "STEEL", 1)
    # cracks: 2px cores at the tip forking into 1px tails
    c.line(34, 190, 24, 187, "VOID", 2)                     # across left slab
    c.line(24, 187, 12, 188, "VOID", 1)
    c.line(34, 190, 44, 188, "VOID", 1)                     # under far boot
    c.line(44, 188, 56, 189, "VOID", 1)
    c.line(34, 192, 30, 198, "VOID", 2)                     # down the face
    c.line(30, 198, 33, 205, "VOID", 1)
    c.line(34, 192, 40, 198, "VOID", 2)
    c.line(40, 198, 37, 204, "VOID", 1)
    c.line(32, 192, 24, 197, "VOID", 1)
    c.line(24, 197, 21, 203, "VOID", 1)
    c.line(24, 197, 18, 199, "VOID", 1)                     # hairline branch
    c.line(36, 192, 46, 200, "VOID", 1)
    c.line(46, 200, 51, 205, "VOID", 1)
    # stone chips kicked up left of the shield edge
    c.put(22, 176, "GRAY"); c.put(23, 176, "GRAY")
    c.put(27, 172, "GRAY")
    c.put(18, 181, "GRAY"); c.put(19, 180, "GRAY")

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- hammer resting up over the far (right) shoulder ---
    c.line(40, 38, 51, 15, "UMBER", 2)
    c.line(41, 36, 50, 17, "BROWN", 1)
    c.rect(46, 7, 57, 15, "BRONZE")                         # head
    c.rect(46, 7, 51, 11, "GOLD")                           # lit face
    c.line(47, 8, 50, 8, "PALE_GOLD", 1)
    c.line(55, 8, 56, 14, "UMBER", 1)                       # butt shade
    c.line(47, 14, 56, 14, "UMBER", 1)

    # --- boots at the pivot (32, 60) ---
    c.rect(27, 52, 31, 59, "DUSK")
    c.rect(34, 52, 38, 59, "DUSK")
    c.line(27, 59, 38, 59, "VOID", 1)
    c.put(28, 53, "SLATE"); c.put(35, 53, "SLATE")

    # --- steel body mass ---
    c.rect(26, 32, 40, 52, "SLATE")
    c.rect(26, 32, 31, 42, "STEEL")                         # key-lit plane
    c.rect(38, 34, 40, 52, "DUSK")                          # shadow edge
    # teal tabard stripe down the front
    c.rect(31, 34, 35, 51, "TEAL")
    c.line(35, 36, 35, 50, "NAVY", 1)
    c.put(33, 51, "GOLD")                                   # hem trim glint
    c.line(27, 42, 39, 42, "UMBER", 1)                      # belt
    c.put(33, 42, "GOLD")
    # right arm up to the haft
    c.line(39, 36, 44, 30, "SLATE", 2)
    c.ellipse(45, 29, 1, 1, "SKIN")

    # --- head ---
    c.ellipse(33, 21, 8, 7, "SKIN_LIGHT")                   # face
    c.ellipse(33, 17, 7, 4, "GOLD")                         # skull cap (flat)
    c.line(38, 15, 39, 19, "BRONZE", 1)                     # cap shade right
    # crown-braid: flat segmented ring sitting ON the skull, wider than it
    c.curve([(24, 16), (27, 12), (33, 10), (39, 12), (42, 16)], "GOLD", 4)
    for bx, by in ((23, 15), (26, 11), (33, 9), (40, 11), (43, 15)):
        c.ellipse(bx, by, 2.5, 2.5, "GOLD")                 # woven bumps
    c.ellipse(25, 10, 1, 1, "PALE_GOLD")                    # lit crowns
    c.put(31, 8, "PALE_GOLD"); c.put(32, 8, "PALE_GOLD")
    c.put(22, 14, "PALE_GOLD")
    c.line(43, 14, 44, 16, "BRONZE", 1)                     # shadow-side bump
    c.put(41, 10, "BRONZE"); c.put(42, 11, "BRONZE")
    # woven seams between bumps
    c.line(23, 13, 25, 11, "BRONZE", 1)
    c.line(29, 11, 30, 9, "BRONZE", 1)
    c.line(36, 9, 37, 11, "BRONZE", 1)
    c.line(41, 13, 43, 15, "BRONZE", 1)
    # deep inner seam so the ring reads as a coil, not a hat
    c.curve([(25, 17), (28, 13), (33, 11), (38, 13), (41, 17)], "BROWN", 1)

    # --- chibi face (nothing above the lash line — no stray pixels) ---
    c.rect(29, 20, 30, 22, "VOID")                          # left eye
    c.put(30, 21, "CYAN")                                   # iris inside
    c.rect(36, 20, 37, 22, "VOID")                          # right eye
    c.put(36, 21, "CYAN")
    c.line(31, 25, 34, 25, "SKIN_SHADOW", 1)                # calm half-smile
    c.put(35, 24, "SKIN_SHADOW")
    c.put(27, 23, "ROSE"); c.put(38, 23, "ROSE")

    # --- kite shield: big flat NAVY slab toward the lane (front-most) ---
    c.poly([(4, 24), (28, 21), (30, 38), (22, 54), (15, 59), (6, 44)],
           "STEEL")                                         # rim
    c.poly([(7, 26), (26, 24), (27, 38), (20, 51), (15, 55), (9, 43)],
           "NAVY")                                          # field
    c.poly([(23, 24), (26, 24), (27, 38), (20, 51), (19, 43)], "DUSK")
    c.line(5, 25, 27, 22, "PALE", 1)                        # top edge light
    c.line(5, 26, 6, 34, "PALE", 1)
    # gate-and-wave sigil, CYAN — readable arch + bar + wave, not a dot
    c.curve([(11, 35), (11, 31), (15, 28), (19, 31), (19, 35)], "CYAN", 1)
    c.line(11, 35, 11, 38, "CYAN", 1)                       # posts
    c.line(19, 35, 19, 38, "CYAN", 1)
    c.line(15, 31, 15, 36, "CYAN", 1)                       # portcullis bar
    c.curve([(10, 42), (13, 40), (16, 42), (19, 40)], "CYAN", 1)   # wave
    c.put(15, 26, "TEAL"); c.put(9, 33, "TEAL")             # faint glow
    c.put(21, 33, "TEAL")
    # left arm gripping behind the shield edge
    c.line(27, 36, 29, 38, "SLATE", 2)

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
    save(key, os.path.join(out, "defender_2_key.png"), 1)
    save(key, os.path.join(out, "defender_2_key@3x.png"), 3)
    save(iso, os.path.join(out, "defender_2_iso.png"), 1)
    save(iso, os.path.join(out, "defender_2_iso@4x.png"), 4)
    print("defender_2: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
