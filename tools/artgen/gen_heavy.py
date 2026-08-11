"""heavy — Korvag, ogre wrecking-maul heavy of the Iron Levy.

Key art: full overhead charge-swing caught at the apex — both hands hauling
the anvil-sized wrecking maul up and behind his head, back arched, forward
leg planted and cracking the flagstone under it. Face is a menacing scowl:
heavy VOID brow shadow, small GOLD-lit eyes glinting under the shelf,
downturned mouth with a tusked underbite (two bone PALE_GOLD lower tusks).
Slab armor plates lift and separate with the motion, gray-green hide
flexing in the gaps; the chest slab is battle-worn — DUSK dent pocks,
rivet rows, one diagonal WINE-dried gash.

Iso: chibi but oversized — the widest silhouette in the common roster.
Maul over one shoulder, SLATE plate mass split by DUSK seams, gray-green
hide at the joints, same scowl kit (VOID brow shadow, GOLD eye glints,
bone tusks) and a WINE gash on the plate. Reads as "the slow big one".

Run from repo root: python3 tools/artgen/gen_heavy.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from painter import Canvas, lint, save


# ---------------------------------------------------------------- key art ---
def paint_key() -> Canvas:
    c = Canvas(128, 224)

    # --- THE MAUL, deepest layer: anvil-sized head top-left, haft down-right
    c.line(38, 24, 106, 56, "UMBER", 6)                  # tree-trunk haft
    c.line(40, 21, 104, 51, "BROWN", 2)                  # key-lit top edge
    c.ellipse(107, 57, 4, 3, "BRONZE")                   # butt cap
    c.put(105, 55, "GOLD")
    # iron head — one huge dark block, rotated with the swing
    c.poly([(10, 4), (50, 13), (44, 44), (4, 35)], "DUSK")
    c.poly([(15, 9), (45, 16), (41, 38), (10, 31)], "SLATE")     # front face
    c.line(13, 7, 47, 15, "STEEL", 2)                    # worn top edge
    c.line(8, 32, 42, 40, "VOID", 1)                     # underside seam
    c.line(16, 14, 14, 28, "DUSK", 1)                    # old face scar
    c.put(20, 12, "PALE"); c.put(21, 12, "PALE")         # torch glint
    # bronze band binding head to haft
    c.poly([(43, 22), (52, 25), (49, 41), (40, 37)], "BRONZE")
    c.line(44, 24, 42, 35, "GOLD", 1)
    c.line(50, 27, 48, 39, "UMBER", 1)
    # swing-apex motion dashes off the block
    c.line(4, 44, 12, 46, "PALE", 1)
    c.line(2, 24, 2, 32, "STEEL", 1)
    c.line(22, 50, 30, 53, "STEEL", 1)

    # --- far (right) arm hauling up: behind the torso, fist on the haft ---
    c.line(90, 82, 103, 63, "GRAY", 8)                   # upper arm
    c.line(94, 85, 105, 68, "DEEP_GREEN", 4)             # its shadow side
    c.line(103, 63, 95, 52, "GRAY", 7)                   # forearm
    c.line(105, 66, 101, 61, "DEEP_GREEN", 3)            # forearm shadow edge
    c.ellipse(93, 50, 6, 5, "GRAY")                      # far fist ON the haft
    c.poly([(90, 52), (98, 51), (97, 55), (91, 55)], "DEEP_GREEN")
    c.line(90, 47, 94, 46, "GREEN", 1)                   # knuckle light
    c.line(97, 55, 104, 62, "VOID", 1)                   # fist/forearm break
    # far pauldron slab lifting with the swing
    c.poly([(82, 70), (104, 74), (102, 90), (82, 86)], "SLATE")
    c.line(84, 72, 102, 76, "STEEL", 1)
    c.line(83, 84, 101, 88, "DUSK", 1)
    c.put(87, 76, "DUSK"); c.put(97, 79, "DUSK")         # rivets

    # --- rear leg: driving off the ball of the foot, heel up ---
    c.line(82, 140, 98, 168, "GRAY", 12)                 # thigh (hide)
    c.line(88, 146, 100, 166, "DEEP_GREEN", 4)           # shadow core
    c.line(98, 168, 104, 190, "GRAY", 9)                 # calf
    c.line(102, 172, 106, 186, "DEEP_GREEN", 3)
    # strapped shin plate
    c.poly([(94, 168), (106, 172), (104, 190), (94, 186)], "SLATE")
    c.line(95, 170, 104, 174, "STEEL", 1)
    c.line(96, 182, 104, 186, "DUSK", 1)
    # foot pushing off, toes down
    c.poly([(96, 188), (112, 194), (114, 202), (98, 200)], "BROWN")
    c.line(98, 190, 110, 196, "UMBER", 1)
    c.put(112, 200, "UMBER")

    # --- torso: arched back, massive slab-armored barrel ---
    # hide base beneath the plates
    c.poly([(42, 78), (94, 72), (102, 102), (94, 140), (50, 146), (36, 108)],
           "GRAY")
    c.poly([(94, 84), (102, 102), (96, 132), (90, 134)], "DEEP_GREEN")
    # chest slab (upper plate, lifting up-left with the arch)
    c.poly([(40, 76), (92, 70), (96, 94), (42, 102)], "SLATE")
    c.line(42, 78, 90, 72, "STEEL", 2)                   # worn top edge
    c.line(42, 100, 94, 92, "DUSK", 2)                   # plate bottom seam
    c.poly([(86, 72), (92, 70), (96, 94), (88, 96)], "DUSK")     # rt shade
    c.put(45, 82, "DUSK"); c.put(85, 76, "DUSK")         # rivets
    c.put(46, 96, "DUSK"); c.put(88, 88, "DUSK")
    # battle-worn plate detail: rivet row under the top edge
    c.put(52, 80, "DUSK"); c.put(60, 79, "DUSK"); c.put(68, 78, "DUSK")
    c.put(76, 77, "DUSK")
    # hammer-dent pocks scattered on the slab face
    c.put(58, 84, "DUSK"); c.put(59, 85, "DUSK")
    c.put(70, 87, "DUSK"); c.put(71, 87, "DUSK")
    c.put(63, 91, "DUSK"); c.put(78, 82, "DUSK")
    # one diagonal WINE-dried gash across the plate
    c.line(50, 98, 80, 77, "WINE", 2)
    c.line(52, 99, 81, 79, "DUSK", 1)                    # shadow lip below
    # hide gap between chest slab and belly plate — plates lifted apart
    c.line(44, 106, 94, 98, "DEEP_GREEN", 4)
    c.line(44, 104, 66, 101, "GRAY", 2)
    c.put(46, 103, "GREEN"); c.put(47, 103, "GREEN")     # flexing highlight
    c.line(43, 102, 93, 94, "VOID", 1)                   # crisp plate lift line
    # belly plate (lower slab)
    c.poly([(40, 110), (96, 102), (98, 128), (90, 142), (50, 144), (38, 130)],
           "SLATE")
    c.line(42, 112, 94, 104, "STEEL", 1)
    c.line(40, 128, 92, 122, "DUSK", 2)                  # seam
    c.put(48, 118, "DUSK"); c.put(86, 112, "DUSK")       # rivets
    c.put(50, 136, "DUSK"); c.put(82, 132, "DUSK")
    c.poly([(88, 106), (98, 128), (90, 142), (80, 140)], "DUSK")  # rt shadow
    c.line(41, 109, 95, 101, "VOID", 1)                  # plate top break
    # leather cinch straps
    c.line(52, 74, 46, 102, "BROWN", 3)                  # shoulder cinch
    c.line(51, 78, 47, 98, "UMBER", 1)
    c.line(40, 134, 92, 128, "BROWN", 3)                 # waist belt
    c.line(41, 137, 91, 131, "UMBER", 1)
    c.rect(62, 128, 68, 134, "BRONZE")                   # buckle
    c.put(63, 129, "GOLD"); c.put(64, 129, "GOLD")
    # hip shadow separating torso from the legs
    c.poly([(58, 142), (80, 140), (78, 154), (62, 154)], "DEEP_GREEN")
    c.line(50, 144, 90, 141, "VOID", 1)

    # --- front leg: planted forward, cracking the flagstone ---
    c.line(54, 142, 44, 170, "GRAY", 13)                 # thigh (hide)
    c.line(59, 148, 51, 168, "DEEP_GREEN", 4)            # shadow side
    c.put(47, 144, "GREEN"); c.put(46, 148, "GREEN")     # lit edge
    # strapped knee + shin plates
    c.ellipse(43, 174, 7, 6, "SLATE")
    c.put(40, 171, "STEEL"); c.put(41, 171, "STEEL")
    c.line(42, 180, 40, 196, "SLATE", 9)
    c.line(38, 180, 37, 194, "STEEL", 1)
    c.line(46, 184, 44, 196, "DUSK", 2)
    c.line(40, 187, 45, 186, "BROWN", 2)                 # shin strap
    # massive foot slamming down
    c.poly([(28, 196), (52, 196), (54, 206), (26, 206)], "BROWN")
    c.line(28, 197, 52, 197, "BRONZE", 1)
    c.line(27, 204, 53, 205, "UMBER", 1)
    # cracked flagstone: slab edges + cracks radiating from the plant
    c.line(8, 210, 46, 212, "GRAY", 2)                   # slab edge left
    c.line(58, 211, 96, 208, "GRAY", 2)                  # slab edge right
    c.line(24, 207, 12, 216, "DUSK", 1)                  # cracks
    c.line(34, 208, 30, 220, "DUSK", 1)
    c.line(48, 208, 56, 218, "DUSK", 1)
    c.line(56, 207, 68, 213, "DUSK", 1)
    c.put(20, 205, "SLATE"); c.put(59, 204, "SLATE")     # kicked chips
    c.put(16, 203, "GRAY"); c.put(64, 202, "GRAY")

    # --- near (left) arm: hauled up BEHIND the head, fist on the haft ---
    # forearm rides high, leaving a clear gap of sky over the skull
    c.line(46, 86, 37, 54, "GRAY", 9)                    # upper arm (hide)
    c.line(50, 84, 43, 62, "DEEP_GREEN", 3)              # inner shadow
    c.line(41, 74, 40, 66, "GREEN", 1)                   # lit edge
    c.line(36, 50, 68, 34, "GRAY", 7)                    # forearm up-right
    c.line(40, 53, 54, 46, "DEEP_GREEN", 2)              # underside shadow
    c.line(46, 42, 52, 39, "GREEN", 1)                   # lit top edge
    c.line(46, 48, 51, 45, "BROWN", 3)                   # forearm strap
    c.ellipse(72, 36, 6, 5, "GRAY")                      # near fist ON the haft
    c.poly([(68, 38), (77, 37), (76, 41), (69, 42)], "DEEP_GREEN")
    c.line(68, 32, 74, 31, "GREEN", 1)                   # knuckle light
    c.line(70, 34, 70, 39, "DEEP_GREEN", 1)              # finger grooves
    c.line(73, 34, 73, 39, "DEEP_GREEN", 1)
    c.line(66, 42, 77, 42, "VOID", 1)                    # fist underside break

    # --- head: granite-browed ogre skull, tilted back in the bellow ---
    # neck sunk between the shoulders
    c.poly([(56, 68), (74, 66), (76, 78), (56, 80)], "GRAY")
    c.line(58, 76, 74, 74, "DEEP_GREEN", 2)              # jaw drop shadow
    c.ellipse(63, 56, 11, 13, "GRAY")                    # skull
    c.poly([(73, 51), (75, 54), (74, 62), (72, 62)], "DEEP_GREEN")  # rim shade
    # crisp skull contour where the forearm passes behind
    c.curve([(52, 52), (54, 46), (59, 43), (63, 43)], "VOID", 1)
    # topknot stub — leaning left into the sky gap between forearm and skull
    c.poly([(58, 46), (64, 44), (57, 31), (51, 34)], "BROWN")
    c.line(51, 34, 57, 46, "VOID", 1)                    # left edge
    c.line(59, 33, 63, 43, "UMBER", 1)                   # right shade
    c.line(52, 33, 57, 31, "VOID", 1)                    # tip edge
    c.rect(57, 41, 62, 42, "BRONZE")                     # ring at the base
    c.put(58, 41, "GOLD")
    c.put(54, 34, "BRONZE")
    # granite brow ridge — heavy shelf; DUSK crease, angry brow ticks
    c.poly([(51, 52), (76, 50), (76, 56), (51, 58)], "GRAY")
    c.line(52, 57, 75, 55, "DUSK", 1)                    # crease under shelf
    c.put(63, 53, "DUSK"); c.put(63, 54, "DUSK")         # furrow
    c.line(54, 55, 59, 56, "VOID", 1)                    # angry brow, near
    c.line(72, 54, 68, 55, "VOID", 1)                    # angry brow, far
    # ear on the near side
    c.poly([(51, 60), (47, 57), (48, 67), (52, 66)], "GRAY")
    c.put(49, 62, "DEEP_GREEN")

    # --- face: menacing scowl — brow shadow, GOLD eye glints, underbite ---
    # heavy VOID shadow cast by the brow shelf; ragged bottom edge so it
    # reads as shadow, not a blindfold
    c.poly([(52, 58), (76, 56), (76, 61), (66, 62), (63, 65), (60, 62),
            (52, 64)], "VOID")
    # small GOLD-lit eyes glinting inside the shadow
    c.rect(56, 60, 58, 61, "GOLD")
    c.put(56, 60, "PALE_GOLD")
    c.rect(67, 59, 69, 60, "GOLD")
    c.put(67, 59, "PALE_GOLD")
    # cheekbones catching the torchlight under the shadow
    c.put(55, 65, "GREEN"); c.put(70, 63, "GREEN")
    # broad flat nose
    c.line(61, 66, 64, 65, "DUSK", 1)
    # SCOWL: mouth shut, corners pulled hard down
    c.line(57, 74, 62, 71, "VOID", 2)                    # near half rises
    c.line(62, 71, 68, 73, "VOID", 2)                    # far half drops
    c.put(56, 75, "VOID"); c.put(56, 76, "VOID")         # corner drops
    c.put(69, 74, "VOID"); c.put(69, 75, "VOID")
    c.line(58, 77, 67, 76, "DUSK", 1)                    # under-lip shade
    c.line(59, 79, 66, 78, "DEEP_GREEN", 1)              # jutting-jaw crease
    # tusked underbite — two bone PALE_GOLD lower tusks past the corners
    c.poly([(53, 77), (57, 78), (56, 68), (52, 70)], "PALE_GOLD")  # left
    c.line(55, 75, 54, 70, "GOLD", 1)                    # tusk core shade
    c.put(54, 68, "PALE_GOLD")                           # sharpened tip
    c.poly([(69, 76), (73, 77), (73, 67), (69, 69)], "PALE_GOLD")  # right
    c.line(71, 74, 71, 69, "GOLD", 1)
    c.put(71, 67, "PALE_GOLD")

    # near pauldron slab, lifted off the shoulder
    c.poly([(36, 74), (58, 70), (60, 86), (38, 92)], "SLATE")
    c.line(38, 76, 56, 72, "STEEL", 2)
    c.line(39, 89, 58, 84, "DUSK", 1)
    c.put(42, 80, "DUSK"); c.put(53, 76, "DUSK")         # rivets
    c.line(40, 92, 46, 96, "VOID", 1)                    # underplate break

    c.outline("VOID")
    return c


# ------------------------------------------------------------- iso sprite ---
def paint_iso() -> Canvas:
    c = Canvas(64, 64)

    # --- maul head block over the right shoulder (lane side), deepest ---
    c.poly([(42, 2), (62, 7), (60, 22), (40, 17)], "DUSK")
    c.poly([(45, 5), (59, 9), (58, 19), (44, 15)], "SLATE")
    c.line(44, 4, 60, 8, "STEEL", 1)
    c.put(49, 19, "BRONZE"); c.put(50, 19, "BRONZE")     # band at the neck
    c.put(46, 7, "PALE")                                 # torch glint

    # --- feet at the pivot (32, 60): heavy trudge stride ---
    c.rect(18, 53, 28, 59, "BROWN")                      # left foot forward
    c.line(19, 54, 27, 54, "BRONZE", 1)
    c.line(19, 58, 27, 58, "UMBER", 1)
    c.rect(36, 54, 46, 59, "BROWN")                      # right foot trailing
    c.line(37, 55, 45, 55, "BRONZE", 1)
    c.line(37, 58, 45, 58, "UMBER", 1)

    # --- body: the widest slab mass in the roster ---
    # hide showing at the hips under the plates
    c.poly([(12, 44), (52, 44), (50, 54), (14, 54)], "GRAY")
    c.line(16, 52, 48, 52, "DEEP_GREEN", 2)
    c.put(14, 46, "GREEN"); c.put(15, 46, "GREEN")
    # gray-green hide arms at the joints (outside the plate edges)
    c.ellipse(6, 32, 4, 7, "GRAY")                       # left arm
    c.put(5, 35, "DEEP_GREEN"); c.put(6, 36, "DEEP_GREEN")
    c.put(4, 28, "GREEN")
    c.ellipse(58, 32, 4, 7, "GRAY")                      # right arm
    c.rect(57, 34, 60, 38, "DEEP_GREEN")
    # main plate slab — split by DUSK seams
    c.poly([(8, 24), (56, 24), (60, 46), (4, 46)], "SLATE")
    c.line(9, 26, 7, 44, "STEEL", 1)                     # key-light edge
    c.line(9, 25, 54, 25, "STEEL", 1)                    # worn top edge
    c.line(6, 34, 58, 34, "DUSK", 1)                     # horizontal seam
    c.line(38, 25, 39, 45, "DUSK", 1)                    # vertical seam
    c.line(5, 44, 59, 44, "DUSK", 1)                     # bottom seam
    c.poly([(54, 26), (56, 24), (60, 46), (54, 45)], "DUSK")     # rt shade
    c.put(13, 28, "DUSK"); c.put(34, 28, "DUSK"); c.put(50, 29, "DUSK")
    c.put(13, 39, "DUSK"); c.put(34, 39, "DUSK"); c.put(50, 40, "DUSK")
    # waist strap + buckle
    c.line(5, 41, 58, 41, "BROWN", 2)
    c.rect(30, 40, 33, 43, "BRONZE")
    c.put(31, 41, "GOLD")
    # battle-worn plate: dent pocks + diagonal WINE-dried gash
    c.put(20, 31, "DUSK"); c.put(27, 29, "DUSK")
    c.put(24, 42, "DUSK"); c.put(44, 37, "DUSK")
    c.line(15, 41, 29, 27, "WINE", 1)                    # dried gash
    c.put(16, 42, "DUSK"); c.put(28, 28, "DUSK")         # gash ends chipped
    # haft slung across the chest up to the block, fist gripping it
    c.line(45, 37, 51, 16, "UMBER", 4)
    c.line(43, 34, 48, 20, "BROWN", 1)
    c.ellipse(45, 36, 5, 4, "GRAY")                      # fist wrapping the haft
    c.line(42, 39, 48, 39, "DEEP_GREEN", 1)              # fist underside
    c.put(41, 33, "GREEN"); c.put(42, 33, "GREEN")       # knuckle light
    c.line(42, 41, 48, 41, "VOID", 1)                    # fist/plate break

    # --- head: big bald granite dome with tusks, its own mass ---
    c.ellipse(28, 13, 12, 10, "GRAY")
    c.poly([(37, 8), (40, 12), (39, 19), (35, 21)], "DEEP_GREEN")  # rt shade
    c.put(22, 5, "GREEN"); c.put(23, 5, "GREEN")         # lit scalp tick
    # topknot stub
    c.rect(26, 1, 30, 3, "BROWN")
    c.put(27, 2, "BRONZE")
    # granite brow shelf
    c.rect(19, 10, 37, 11, "GRAY")
    c.put(28, 11, "DEEP_GREEN")                          # furrow
    # heavy VOID brow shadow — the whole eye zone sunk in dark
    c.rect(20, 12, 36, 14, "VOID")
    c.put(20, 15, "DEEP_GREEN"); c.put(28, 15, "DEEP_GREEN")  # ragged edge
    c.put(36, 15, "DEEP_GREEN")
    # small GOLD eye glints inside the shadow
    c.rect(23, 13, 24, 14, "GOLD")
    c.put(23, 13, "PALE_GOLD")
    c.rect(32, 13, 33, 14, "GOLD")
    c.put(32, 13, "PALE_GOLD")
    # scowl mouth — corners pulled down
    c.rect(26, 18, 30, 18, "VOID")
    c.put(26, 19, "VOID"); c.put(30, 19, "VOID")         # corner drops
    c.line(27, 20, 29, 20, "DEEP_GREEN", 1)              # jutting-jaw shade
    # tusked underbite — bone PALE_GOLD lower tusks flanking the mouth
    c.rect(24, 17, 25, 20, "PALE_GOLD")                  # left tusk
    c.put(25, 20, "GOLD")
    c.rect(31, 17, 32, 20, "PALE_GOLD")                  # right tusk
    c.put(31, 20, "GOLD")

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
    save(key, os.path.join(out, "heavy_key.png"), 1)
    save(key, os.path.join(out, "heavy_key@3x.png"), 3)
    save(iso, os.path.join(out, "heavy_iso.png"), 1)
    save(iso, os.path.join(out, "heavy_iso@4x.png"), 4)
    print("heavy: lint clean, 4 PNGs saved")


if __name__ == "__main__":
    main()
