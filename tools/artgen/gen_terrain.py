"""terrain — TERRAIN STYLE PLATE for the torchlit dungeon board.

2:1 isometric tiles: flat top faces are 64x32 diamonds; elevated tiles are
64x48 with a 16px wall; structural tiles (spawn arch, base camp, pillar,
backdrop wall) rise above the floor diamond on taller canvases and are
bottom-aligned when composited.

Legibility law: the road lane is the ONLY broad warm surface on the floor
plane (earth ramp UMBER/BROWN/BRONZE/GOLD) so it reads as a warm river
through the cool steel-ramp moss stone at a glance.

Output: one plate PNG — top row the 8 individual tiles, below a 4x4 iso
collage staged like a board (spawn -> road lane -> base, elevated cluster,
void chasm, blockers, backdrop wall corner).

Run from repo root: python3 tools/artgen/gen_terrain.py
"""
import sys, os, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
import painter
from painter import Canvas, save

REF = os.path.join(os.path.dirname(__file__), "..", "..", "docs", "art", "reference")


# ------------------------------------------------------------- iso helpers ---
def dspan(y):
    """Inclusive x span of the 64x32 diamond top face at row y (0..31)."""
    d = y if y < 16 else 31 - y
    return 30 - 2 * d, 33 + 2 * d


def fill_diamond(c, y0, col):
    for y in range(32):
        x0, x1 = dspan(y)
        for x in range(x0, x1 + 1):
            c.put(x, y0 + y, col)


def in_dia(x, y):
    if 0 <= y < 32:
        x0, x1 = dspan(y)
        return x0 <= x <= x1
    return False


def dia_bottom(x):
    """Lowest diamond row (0-based) present in column x."""
    for y in range(31, -1, -1):
        x0, x1 = dspan(y)
        if x0 <= x <= x1:
            return y
    return 16


def edge_depth(x, y):
    """~0 at the diamond edge, growing toward the center (diamond metric)."""
    return 16.0 - (abs(x - 31.5) / 2.0 + abs(y - 15.5))


def n01(x, y, s=0):
    """Deterministic hash noise in [0,1) — no random module, replay-stable."""
    v = (x * 374761393 + y * 668265263 + s * 2246822519) & 0xFFFFFFFF
    v = ((v ^ (v >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((v ^ (v >> 16)) & 1023) / 1023.0


def quiet_floor(c, y0, s):
    """Shared mossy-flagstone floor field (used by ground/base/blocked)."""
    fill_diamond(c, y0, "SLATE")
    # bottom-right edge falls to shadow, top-left edge catches the key light
    for y in range(32):
        x0, x1 = dspan(y)
        if y >= 16:
            for x in range(x1 - 2, x1 + 1):
                if n01(x, y, s) > 0.30:
                    c.put(x, y0 + y, "DUSK")
            for x in range(x0, x0 + 3):
                if n01(x, y, s + 1) > 0.55:
                    c.put(x, y0 + y, "DUSK")
        else:
            for x in range(x0, x0 + 2):
                if n01(x, y, s + 2) > 0.40:
                    c.put(x, y0 + y, "STEEL")


# ------------------------------------------------------------- tile_ground ---
def paint_ground(s=11):
    c = Canvas(64, 32)
    quiet_floor(c, 0, s)
    # mortar joints splitting the face into 4 big worn slabs (jittered X)
    c.line(16, 8, 48, 24, "DUSK")
    c.line(48, 8, 16, 24, "DUSK")
    # secondary broken joints so the slabs read unequal
    c.line(26, 5, 38, 11, "DUSK")
    c.line(10, 18, 22, 24, "DUSK")
    c.line(42, 20, 52, 15, "DUSK")
    # recessed pits + moss colonizing the cracks
    for y in range(32):
        x0, x1 = dspan(y)
        for x in range(x0, x1 + 1):
            if c.get(x, y) == "DUSK" and edge_depth(x, y) > 2.0:
                r = n01(x, y, s + 3)
                if r > 0.80:
                    c.put(x, y, "VOID")
                elif r > 0.58:
                    c.put(x, y, "DEEP_GREEN")
                if n01(x, y, s + 4) > 0.86:
                    c.put(x + 1, y, "DEEP_GREEN")
    # moss patch in the darkest slab corner + a few bright growth tips
    for x, y in ((14, 19), (16, 20), (15, 21), (37, 13), (30, 22)):
        c.put(x, y, "DEEP_GREEN")
    for x, y in ((15, 20), (37, 12), (46, 22)):
        c.put(x, y, "GREEN")
    # slab top-left edges catching light just past each groove
    for y in range(32):
        for x in range(64):
            if c.get(x, y) == "SLATE" and c.get(x - 1, y - 1) in ("DUSK", "VOID"):
                if n01(x, y, s + 5) > 0.55 and in_dia(x, y):
                    c.put(x, y, "STEEL")
    return c


# --------------------------------------------------------------- tile_road ---
def paint_road(direction="ns", s=22):
    c = Canvas(64, 32)
    fill_diamond(c, 0, "BROWN")
    # golden torch pools washing the packed earth (lit half first)
    for cx, cy, rx, ry in ((26, 11, 12, 6), (44, 19, 7, 4)):
        for y in range(cy - ry, cy + ry + 1):
            for x in range(cx - rx, cx + rx + 1):
                dx, dy = (x - cx) / rx, (y - cy) / ry
                d = dx * dx + dy * dy
                if d <= 1.0 and in_dia(x, y):
                    if d <= 0.34:
                        c.put(x, y, "GOLD")
                    elif d <= 0.72 or n01(x, y, s + 1) > 0.45:
                        c.put(x, y, "BRONZE")
    # cold shadow along the bottom-right edge of the trough
    for y in range(16, 32):
        x0, x1 = dspan(y)
        for x in range(x1 - 3, x1 + 1):
            if n01(x, y, s + 2) > 0.35:
                c.put(x, y, "UMBER")
    # wheel/foot ruts flowing with the path (NS = NE edge -> SW edge)
    c.line(42, 5, 10, 21, "UMBER")
    c.line(54, 11, 22, 27, "UMBER")
    for y in range(32):
        for x in range(64):
            if c.get(x, y) == "UMBER" and n01(x, y, s + 3) > 0.82:
                c.put(x, y, "VOID")
    # kerb of half-buried stones along both verges
    for ky in (3, 8, 13):
        x0, _ = dspan(ky)
        c.rect(x0 + 1, ky, x0 + 4, ky + 1, "SLATE")
        c.put(x0 + 2, ky + 2, "DUSK")
        c.put(x0 + 4, ky + 1, "DUSK")
    for ky in (18, 23, 28):
        _, x1 = dspan(ky)
        c.rect(x1 - 4, ky, x1 - 1, ky + 1, "SLATE")
        c.rect(x1 - 4, ky + 1, x1 - 2, ky + 1, "DUSK")
    # scattered pebbles pressed into the earth
    for x, y in ((34, 24), (20, 16)):
        c.put(x, y, "UMBER")
        c.put(x + 1, y, "BRONZE")
    if direction == "ew":
        c.flip_x()
    return c


# ----------------------------------------------------------- tile_elevated ---
def paint_elevated(s=33):
    c = Canvas(64, 48)
    fill_diamond(c, 0, "STEEL")
    # pale lit rim along the two back edges, slate falloff on the front
    for y in range(32):
        x0, x1 = dspan(y)
        if y < 16:
            for x in range(x0, x0 + 2):
                c.put(x, y, "PALE")
            for x in range(x1 - 1, x1 + 1):
                if n01(x, y, s) > 0.35:
                    c.put(x, y, "PALE")
        else:
            for x in range(x0, x1 + 1):
                if x1 - x < 3 and n01(x, y, s + 1) > 0.30:
                    c.put(x, y, "SLATE")
    # a few worn pale patches where boots polished the deck
    for x, y in ((26, 10), (27, 10), (27, 11), (38, 15), (39, 15), (33, 7)):
        c.put(x, y, "PALE")
    # deck flag joints (kept quieter than ground level)
    c.line(16, 8, 48, 24, "SLATE")
    c.line(48, 8, 16, 24, "SLATE")
    # cliff faces: 16px wall, left face lit slate, right face hard shadow
    for x in range(64):
        yb = dia_bottom(x)
        for k in range(1, 17):
            c.put(x, yb + k, "DUSK" if x < 32 else "VOID")
        c.put(x, yb + 16, "VOID")
    # chisel marks on the exposed slate — sparse deliberate strokes
    for x0, y0 in ((5, 26), (11, 32), (18, 36), (25, 40), (8, 40), (16, 27)):
        c.line(x0, y0, x0 + 2, y0 + 1, "SLATE")
        c.put(x0 + 3, y0 + 2, "VOID")
    for y in range(20, 46):
        for x in range(36, 64):
            if c.get(x, y) == "VOID" and n01(x, y, s + 3) > 0.94:
                c.put(x, y, "DUSK")
    # broken crenellated lip along both front edges: raised merlon teeth
    # with dusk gaps, one tooth sheared off per edge
    for y, i in ((17, 0), (21, 1), (25, 2), (29, 3)):
        x0, _ = dspan(y)
        if i % 2 == 0:                      # merlon block, lit from top-left
            c.rect(x0, y - 3, x0 + 3, y, "STEEL")
            c.put(x0, y - 3, "PALE")
            c.put(x0 + 1, y - 3, "PALE")
            c.rect(x0 + 3, y - 1, x0 + 3, y, "SLATE")
            c.rect(x0 + 4, y, x0 + 5, y + 1, "DUSK")   # gap shadow
        elif i != 3:                        # notch carved to the wall shade
            c.rect(x0 + 1, y, x0 + 4, y + 1, "DUSK")
            c.put(x0 + 2, y, "VOID")
    for y, i in ((17, 0), (21, 1), (25, 2), (29, 3)):
        _, x1 = dspan(y)
        if i % 2 == 1:
            c.rect(x1 - 3, y - 3, x1, y, "STEEL")
            c.put(x1 - 3, y - 3, "PALE")
            c.rect(x1 - 3, y - 1, x1 - 3, y, "SLATE")
            c.rect(x1 - 5, y, x1 - 4, y + 1, "DUSK")   # gap shadow
        elif i != 2:                        # one slot fully broken away
            c.rect(x1 - 4, y, x1 - 1, y + 1, "DUSK")
            c.put(x1 - 2, y, "VOID")
    # bleached lime moss dusting the lit rim — the ranged-ground tell
    for y in (3, 4, 6, 7, 8, 11, 12):
        x0, _ = dspan(y)
        c.put(x0 + 2, y, "LIME")
        if y in (4, 7, 12):
            c.put(x0 + 3, y, "LIME")
    for y in (5, 10, 13):
        x0, _ = dspan(y)
        c.put(x0 + 3, y + 1, "GREEN")
    # one crack running down the lit face
    c.curve([(12, 24), (14, 30), (12, 36), (15, 41)], "VOID", 1)
    return c


# -------------------------------------------------------------- tile_spawn ---
def paint_spawn(s=44):
    c = Canvas(64, 64)
    F = 32
    fill_diamond(c, F, "NAVY")
    # cold dark exhalation spilling from the gate across the back half
    for y in range(32):
        x0, x1 = dspan(y)
        for x in range(x0, x1 + 1):
            if y < 13 and 16 < x < 48 and n01(x, y, s) > 0.18:
                c.put(x, F + y, "VOID")
            elif y < 20 and n01(x, y, s + 1) > 0.80:
                c.put(x, F + y, "VOID")
    # teal floor-mist wisps curling toward the viewer
    for cx, cy in ((22, 18), (34, 22), (44, 16), (28, 26)):
        for t in range(9):
            x = cx + t
            y = cy + (t // 3) - (1 if t % 3 == 2 else 0)
            if in_dia(x, y) and n01(x, y, s + 2) > 0.28:
                c.put(x, F + y, "TEAL")
    for y in range(14, 30):
        x0, x1 = dspan(y)
        for x in range(x0, x1 + 1):
            if n01(x, y, s + 3) > 0.90:
                c.put(x, F + y, "TEAL")
    # cyclopean piers (stacked uneven blocks, lit top-left)
    for bx0, bx1, by0, by1 in ((8, 20, 36, 44), (9, 19, 28, 35), (7, 20, 20, 27),
                               (10, 19, 14, 19)):
        c.rect(bx0, by0, bx1, by1, "DUSK")
        c.line(bx0, by0, bx1, by0, "SLATE")
        c.line(bx0, by0, bx0, by1, "SLATE")
        c.line(bx0, by1, bx1, by1, "VOID")
    for bx0, bx1, by0, by1 in ((43, 55, 36, 44), (44, 56, 28, 35), (43, 56, 20, 27),
                               (44, 54, 14, 19)):
        c.rect(bx0, by0, bx1, by1, "DUSK")
        c.line(bx0, by0, bx1, by0, "SLATE")
        c.line(bx0, by1, bx1, by1, "VOID")
        c.line(bx1, by0, bx1, by1, "VOID")
    # lintel + raised keystone
    c.rect(14, 8, 49, 14, "DUSK")
    c.line(14, 8, 49, 8, "SLATE")
    c.line(14, 14, 49, 14, "VOID")
    for jx in (24, 40):
        c.line(jx, 9, jx, 13, "VOID")
    c.rect(28, 5, 35, 13, "DUSK")
    c.line(28, 5, 35, 5, "SLATE")
    c.line(28, 5, 28, 13, "SLATE")
    # the opening: layered darkness, faint cold light at the threshold
    c.rect(21, 15, 42, 43, "VOID")
    for y in range(39, 44):
        for x in range(21, 43):
            if n01(x, y, s + 4) > 0.55:
                c.put(x, y, "NAVY")
    # corbel steps arching the opening inward
    c.rect(21, 15, 24, 19, "DUSK")
    c.line(21, 15, 24, 15, "SLATE")
    c.put(24, 19, "VOID")
    c.rect(39, 15, 42, 19, "DUSK")
    c.line(39, 15, 42, 15, "SLATE")
    c.put(39, 19, "VOID")
    # portcullis jammed half-raised: cold iron bars with pointed tips
    for bx in (26, 30, 34, 38):
        c.line(bx, 16, bx, 28, "SLATE")
        c.put(bx + 1, 28, "DUSK")
        c.put(bx, 29, "DUSK")                # spear tip
    c.line(25, 18, 39, 18, "SLATE")
    c.line(25, 25, 39, 25, "DUSK")
    # lit stone glints so the gate separates from the darker backdrop wall
    for gx, gy in ((9, 21), (12, 29), (16, 37), (45, 21), (48, 29), (52, 37),
                   (16, 9), (33, 6)):
        c.put(gx, gy, "STEEL")
    # flanking torches guttering against the cold
    for tx in (12, 51):
        c.put(tx, 22, "BRONZE")
        c.put(tx, 21, "BRONZE")
        c.ellipse(tx, 17, 1.4, 2.4, "GOLD")
        c.put(tx, 15, "CORAL")
        c.put(tx, 18, "PALE_GOLD")
        c.put(tx - 1, 20, "CRIMSON")
        for gx, gy in ((tx - 2, 19), (tx + 2, 18), (tx - 1, 14), (tx + 2, 21)):
            c.put(gx, gy, "UMBER")
    # front floor edge falls dark
    for y in range(16, 32):
        x0, x1 = dspan(y)
        for x in (x1 - 1, x1, x0, x0 + 1):
            if n01(x, y, s + 5) > 0.45:
                c.put(x, F + y, "VOID")
    return c


# --------------------------------------------------------------- tile_base ---
def paint_base(s=55):
    c = Canvas(64, 64)
    F = 32
    quiet_floor(c, F, s)
    # arcane glow ring cast on the flags around the crystal
    for a in range(64):
        t = a / 64.0 * 6.28318
        x = int(32 + 13 * _cos(t))
        y = int(15 + 6 * _sin(t))
        if in_dia(x, y) and n01(x, y, s + 1) > 0.35:
            c.put(x, F + y, "PLUM")
    # crystal's occlusion shadow — plum-cool, not a black hole
    for y in range(13, 18):
        for x in range(26, 39):
            dx, dy = (x - 32) / 6.0, (y - 15) / 2.4
            d = dx * dx + dy * dy
            if d <= 1.0 and n01(x, y, s + 2) > 0.30:
                c.put(x, F + y, "PLUM" if d > 0.35 else "DUSK")
    # ring of ward-stones with chalked sigils between them
    stones = ((32, 6), (45, 10), (50, 16), (43, 21), (32, 24), (21, 21),
              (14, 16), (19, 10))
    for i, (sx, sy) in enumerate(stones):
        c.rect(sx - 1, F + sy - 2, sx + 1, F + sy, "GRAY")
        c.put(sx - 1, F + sy - 2, "PALE")
        c.put(sx + 1, F + sy, "DUSK")
        if i % 2 == 0:
            c.put(sx, F + sy - 3, "GRAY")
    for x, y in ((26, 8), (39, 8), (48, 13), (46, 19), (38, 23), (26, 23),
                 (17, 19), (16, 13)):
        if in_dia(x, y):
            c.put(x, F + y, "PALE")
    # camp goods on the earth ramp: crate + sack, left-front
    c.rect(10, F + 12, 17, F + 17, "BROWN")
    c.rect(10, F + 11, 17, F + 12, "BRONZE")
    c.line(10, F + 17, 17, F + 17, "UMBER")
    c.line(13, F + 12, 13, F + 17, "UMBER")
    c.put(11, F + 11, "GOLD")
    c.ellipse(22, F + 20, 3, 2, "BROWN")
    c.put(21, F + 19, "BRONZE")
    c.put(24, F + 21, "UMBER")
    # wine-crimson banner on a rough pole, right-back
    c.line(50, 12, 50, F + 12, "UMBER")
    c.put(50, 11, "BRONZE")
    for y in range(13, 30):
        wjag = 0 if y < 26 else (y - 25)
        for x in range(44 + wjag, 50):
            c.put(x, y, "WINE")
    c.line(44, 13, 44, 24, "CRIMSON")
    c.line(44, 13, 49, 13, "CRIMSON")
    # the ward-crystal: faceted, floating, full arcane ramp
    body = [(32, 8), (38, 18), (32, 34), (26, 18)]
    c.poly(body, "ORCHID")
    c.poly([(32, 8), (38, 18), (32, 22)], "ROSE")          # lit upper-left facet
    c.poly([(32, 22), (38, 18), (32, 34)], "MAGENTA")      # shaded lower-right
    c.line(32, 8, 32, 34, "PLUM")                          # facet seams
    c.line(26, 18, 38, 18, "PLUM")
    c.put(30, 13, "ROSE")
    c.put(29, 15, "ROSE")
    c.put(33, 27, "PLUM")
    # drifting motes
    for x, y in ((22, 14), (41, 12), (25, 27), (40, 24), (32, 3)):
        c.put(x, y, "ORCHID" if (x + y) % 2 else "ROSE")
    return c


def _cos(t):
    import math
    return math.cos(t)


def _sin(t):
    import math
    return math.sin(t)


# ------------------------------------------------------------ tile_blocked ---
def paint_blocked(variant="pillar", s=66):
    if variant == "rubble":
        c = Canvas(64, 44)
        F = 12
        quiet_floor(c, F, s + 9)
        # heap shadow first (hard, bottom-right)
        for y in range(F + 16, F + 26):
            for x in range(34, 56):
                if in_dia(x, y - F) and (x - 30) < (y - F) * 2 and n01(x, y, s) > 0.35:
                    c.put(x, y, "DUSK")
        # tumbled drum chunks + fractured capital slab
        c.ellipse(26, F + 16, 9, 5, "SLATE")
        c.ellipse(37, F + 19, 6, 4, "GRAY")
        c.ellipse(20, F + 20, 5, 3, "DUSK")
        # capital fragment leaning against the heap
        c.poly([(31, F + 11), (41, F + 12), (40, F + 16), (30, F + 14)], "SLATE")
        c.line(31, F + 11, 41, F + 12, "STEEL")
        c.line(30, F + 14, 40, F + 16, "DUSK")
        c.put(42, F + 14, "DUSK")
        c.shade_under("SLATE", "DUSK")
        for x, y in ((20, F + 12), (24, F + 13), (33, F + 15), (28, F + 11)):
            c.put(x, y, "STEEL")
        for x, y in ((22, F + 18), (31, F + 21), (36, F + 16)):
            c.put(x, y, "DEEP_GREEN")
        c.put(23, F + 19, "GREEN")
        return c

    c = Canvas(64, 64)
    F = 32
    quiet_floor(c, F, s)
    # hard cast shadow to the lower right
    c.poly([(38, F + 15), (56, F + 22), (50, F + 27), (32, F + 19)], "DUSK")
    for x, y in ((40, F + 17), (44, F + 19), (37, F + 18)):
        c.put(x, y, "VOID")
    # column body — floor's steel ramp turned vertical
    c.rect(24, 12, 40, F + 13, "SLATE")
    c.rect(24, 12, 26, F + 13, "STEEL")                    # lit left flank
    c.rect(38, 12, 40, F + 13, "DUSK")                     # shaded right flank
    c.ellipse(32, F + 13, 8, 3, "SLATE")
    c.line(25, F + 15, 39, F + 15, "DUSK")
    # drum joints (slight elliptical sag)
    for jy in (22, 34):
        c.curve([(24, jy), (32, jy + 2), (40, jy)], "DUSK", 1)
    # rust-streaked iron band
    c.rect(23, 26, 41, 28, "DUSK")
    c.line(23, 26, 41, 26, "GRAY")
    for rx in (27, 33, 38):
        ln = 3 + int(n01(rx, s, 3) * 3)
        c.line(rx, 29, rx, 29 + ln, "UMBER")
        c.put(rx, 29, "BRONZE")
    # broken capital: wider slab with the right corner sheared off
    c.rect(20, 7, 38, 12, "SLATE")
    c.rect(36, 10, 43, 12, "SLATE")
    c.line(20, 7, 37, 7, "STEEL")
    c.line(20, 7, 20, 12, "STEEL")
    c.line(21, 12, 43, 12, "DUSK")
    c.put(38, 9, "DUSK")                                   # fracture step
    c.put(40, 10, "DUSK")
    c.curve([(30, 14), (31, 20), (29, 26)], "DUSK", 1)     # settling crack
    c.put(30, 17, "VOID")
    return c


# --------------------------------------------------------------- tile_void ---
def paint_void(s=77):
    c = Canvas(64, 32)
    for y in range(32):
        x0, x1 = dspan(y)
        for x in range(x0, x1 + 1):
            j = n01(int(x * 0.5) * 2, int(y * 0.5) * 2, s) * 2.6
            d = edge_depth(x, y)
            if d < 1.9 + j * 0.9:
                col = "SLATE"                              # flagstone rim
            elif d < 3.6 + j * 1.4:
                col = "DUSK"
            elif d < 5.2 + j * 1.6:
                col = "NAVY"
            else:
                col = "VOID"
            c.put(x, y, col)
    # ragged rim: bites broken out of the flagstone lip
    for x, y in ((20, 9), (21, 10), (44, 23), (45, 22), (33, 2), (10, 17)):
        c.put(x, y, "DUSK")
    # lit top-left rim edge
    for y in range(1, 15):
        x0, _ = dspan(y)
        if n01(x0, y, s + 1) > 0.35:
            c.put(x0 + 1, y, "STEEL")
    # snapped iron cramps on the rim
    c.rect(26, 4, 27, 4, "GRAY")
    c.rect(29, 5, 30, 5, "GRAY")                           # snapped pair
    c.rect(48, 17, 49, 17, "GRAY")
    c.rect(14, 20, 15, 20, "GRAY")
    c.put(31, 8, "GRAY")                                   # fallen fragment
    # two faint phosphorescent specks, no visible bottom
    c.put(28, 17, "TEAL")
    c.put(37, 13, "TEAL")
    return c


# ----------------------------------------------------------- tile_backdrop ---
def paint_backdrop(s=88):
    c = Canvas(64, 64)
    fill_diamond(c, 0, "DUSK")
    # top face joints, barely-lit
    c.line(16, 8, 48, 24, "VOID")
    c.line(48, 8, 16, 24, "VOID")
    for y in range(1, 14):
        x0, _ = dspan(y)
        if n01(x0, y, s) > 0.62:
            c.put(x0 + 1, y, "SLATE")
    # wall faces run 1-2 value steps darker than any playable tile
    for x in range(64):
        yb = dia_bottom(x)
        for k in range(1, 33):
            c.put(x, yb + k, "INK" if x < 32 else "VOID")
    # cyclopean courses: staggered mortar on the near face (clipped to wall)
    for cy in (26, 34, 42, 50, 58):
        for x in range(0, 32):
            yb = dia_bottom(x)
            if yb < cy <= yb + 32:
                c.put(x, cy, "VOID")
    for i, jx in enumerate((6, 14, 22, 28)):
        yb = dia_bottom(jx)
        for cy0, cy1 in ((26, 34), (42, 50)) if i % 2 else ((34, 42), (50, 58)):
            for cy in range(max(cy0, yb + 1), min(cy1, yb + 32) + 1):
                c.put(jx, cy, "VOID")
    for x in range(32, 64):
        for y in range(20, 64):
            if c.get(x, y) == "VOID" and n01(x, y, s + 1) > 0.90:
                c.put(x, y, "INK")
    # the iron sconce torch — diegetic source of the top-left key light
    c.put(13, 33, "GRAY")
    c.put(13, 32, "GRAY")
    c.put(12, 34, "GRAY")
    c.ellipse(13, 28, 1.5, 2.6, "GOLD")
    c.put(13, 25, "CORAL")
    c.put(13, 29, "PALE_GOLD")
    c.put(12, 31, "CRIMSON")
    # warm gutter-glow lifting the stones near the flame
    for y in range(22, 42):
        for x in range(4, 24):
            d2 = (x - 13) * (x - 13) + (y - 28) * (y - 28) * 2
            if c.get(x, y) == "INK" and d2 < 90 and n01(x, y, s + 2) > 0.45:
                c.put(x, y, "UMBER" if d2 > 40 else "BRONZE")
            elif c.get(x, y) == "INK" and d2 < 160 and n01(x, y, s + 3) > 0.62:
                c.put(x, y, "DUSK")
    # hanging chain swaying on the far face
    for i, y in enumerate(range(30, 52, 2)):
        c.put(44 + (1 if i % 3 == 1 else 0), y, "GRAY")
    # wine-dark banner, ragged hem
    for y in range(32, 54):
        wjag = 0 if y < 49 else (y - 48)
        for x in range(52 + (wjag if y % 2 else 0), 57 - (wjag if not y % 2 else 0)):
            c.put(x, y, "WINE")
    c.line(52, 32, 56, 32, "GRAY")                         # hanging rod
    for y in range(34, 48, 3):
        c.put(55, y, "VOID")                               # fold shadow
    # stag skull trophy on the near face
    c.rect(25, 36, 27, 38, "STEEL")
    c.put(25, 37, "VOID")
    c.put(27, 37, "VOID")
    c.put(26, 39, "STEEL")
    c.put(24, 35, "GRAY")
    c.put(28, 35, "GRAY")
    c.put(23, 34, "GRAY")
    c.put(29, 34, "GRAY")
    # dead root creeping over the top-right course
    c.curve([(56, 30), (58, 36), (56, 42), (58, 47)], "UMBER", 1)
    return c


# ---------------------------------------------------------------- assembly ---
BUILDERS = {
    "tile_ground": lambda s=0: paint_ground(11 + s),
    "tile_road": lambda s=0: paint_road("ns", 22 + s),
    "tile_elevated": lambda s=0: paint_elevated(33 + s),
    "tile_spawn": lambda s=0: paint_spawn(44 + s),
    "tile_base": lambda s=0: paint_base(55 + s),
    "tile_blocked": lambda s=0: paint_blocked("pillar", 66 + s),
    "tile_rubble": lambda s=0: paint_blocked("rubble", 66 + s),
    "tile_void": lambda s=0: paint_void(77 + s),
    "tile_backdrop": lambda s=0: paint_backdrop(88 + s),
}
ROW = ["tile_ground", "tile_road", "tile_elevated", "tile_spawn", "tile_base",
       "tile_blocked", "tile_void", "tile_backdrop"]

# 4x4 stage: spawn -> warm lane -> base down the middle, elevated cluster
# right, chasm + blockers as fillers, backdrop wall on the far corner.
LAYOUT = {
    # occlusion law: a raised tile covers the front half of the tile at its
    # up-left (x-1,y) and up-right (x,y-1) — so every tile at +x of the lane
    # and of the spawn stays FLAT, and the elevated cluster only overlaps
    # quiet ground at (2,y).
    (0, 0): "tile_backdrop", (1, 0): "tile_spawn", (2, 0): "tile_ground",
    (3, 0): "tile_elevated",
    (0, 1): "tile_ground", (1, 1): "tile_road", (2, 1): "tile_ground",
    (3, 1): "tile_elevated",
    (0, 2): "tile_blocked", (1, 2): "tile_road", (2, 2): "tile_ground",
    (3, 2): "tile_elevated",
    (0, 3): "tile_rubble", (1, 3): "tile_base", (2, 3): "tile_ground",
    (3, 3): "tile_void",
}


def iso_project(x, y):
    """Painter-plane iso math: grid cell -> screen px of the diamond's
    bounding-box top-left, before origin offset."""
    return (x - y) * 32, (x + y) * 16


def build_collage():
    ox, oy = 96, 32                    # origin offset: fits x-y in [-3,3]
    coll = Canvas(256, 164)
    for (x, y) in sorted(LAYOUT, key=lambda p: (p[0] + p[1], p[0])):
        tile = BUILDERS[LAYOUT[(x, y)]](s=(x * 7 + y * 13))
        sx, sy = iso_project(x, y)
        coll.blit(tile, ox + sx, oy + sy + 32 - tile.h)
    return coll


def build_plate():
    tiles = [BUILDERS[t]() for t in ROW]
    lint_report = []
    for tid, t in zip(ROW, tiles):
        v = painter.lint(t, t.w, t.h)
        if v:
            lint_report.append(f"{tid}: {v}")
    coll = build_collage()
    plate = Canvas(548, 244)
    xcur = 4
    for t in tiles:
        plate.blit(t, xcur, 4 + 64 - t.h)
        xcur += 64 + 4
    plate.blit(coll, (548 - coll.w) // 2, 76)
    return plate, lint_report


def main():
    plate, lint_report = build_plate()
    allowed = set(painter.PALETTE) - painter.RESERVED
    stray = plate.used_colors() - allowed
    assert not stray, f"plate palette violation: {stray}"
    assert not lint_report, "per-tile lint: " + "; ".join(lint_report)
    p1 = save(plate, os.path.join(REF, "terrain_plate.png"), 1)
    p3 = save(plate, os.path.join(REF, "terrain_plate@3x.png"), 3)
    print("saved", p1)
    print("saved", p3)
    print("lint: clean (palette ok, per-tile painter.lint ok)")


if __name__ == "__main__":
    main()
