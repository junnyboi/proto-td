"""The Unblinking ("drone") — arcane construct: a broken hanging lantern cage
imprisoning a single enormous lidless eye of teal flame.

Key art 128x224: hovering bank into a dive — cage tilted 30 deg, torn chain
links swinging back, three flame tongues streaming behind like a comet tail,
the eye rotated upright inside the cage to glare at the viewer.
Iso 64x64: chibi lantern hovering over a detached VOID ground shadow.

Run from repo root:  python3 tools/artgen/gen_drone.py
"""
import sys, math, json

sys.path.insert(0, 'tools/artgen')
import painter
from painter import Canvas, save, lint

OUT = 'docs/art/reference'
ITERATIONS = 7  # bumped each render-review cycle


# --- helpers -----------------------------------------------------------------

def make_R(theta, cx, cy, s=1.0):
    """Local->world: scale, rotate by theta (screen coords, y down), translate."""
    si, co = math.sin(theta), math.cos(theta)

    def R(pts):
        one = isinstance(pts, tuple)
        if one:
            pts = [pts]
        out = [(cx + (x * co - y * si) * s, cy + (x * si + y * co) * s)
               for (x, y) in pts]
        return out[0] if one else out
    return R


def arc(c, R, lcx, lcy, r, a0, a1, color, w, steps=28):
    """Broken-loop arc in local coords, angles in degrees (0=right, CCW)."""
    pts = []
    for i in range(steps + 1):
        a = math.radians(a0 + (a1 - a0) * i / steps)
        pts.append((lcx + r * math.cos(a), lcy - r * math.sin(a)))
    c.curve(R(pts), color, w)


def punch(c, cx, cy, rx, ry):
    """Erase an ellipse (for chain-link holes over empty sky)."""
    for y in range(int(cy - ry), int(cy + ry) + 1):
        for x in range(int(cx - rx), int(cx + rx) + 1):
            dx, dy = (x - cx) / rx, (y - cy) / ry
            if dx * dx + dy * dy <= 1.0 and 0 <= x < c.w and 0 <= y < c.h:
                c.px[y][x] = None


def chain_link(c, cx, cy, rx, ry):
    c.ellipse(cx, cy, rx, ry, 'SLATE')
    c.ellipse(cx + rx * 0.25, cy + ry * 0.25, rx * 0.8, ry * 0.8, 'DUSK')
    c.ellipse(cx, cy, rx * 0.78, ry * 0.78, 'SLATE')
    punch(c, cx, cy, max(1.0, rx - 2.0), max(1.0, ry - 2.0))


def flame(c, base, offs, w0, shadow=True):
    """Filled flame tongue: tapered polygon with a pointed tip; optional NAVY
    shadow copy shifted bottom-right (top-left key light)."""
    pts = [(base[0] + ox, base[1] + oy) for (ox, oy) in offs]
    n = len(pts)
    left, right = [], []
    for i in range(n - 1):
        dx = pts[min(i + 1, n - 1)][0] - pts[max(i - 1, 0)][0]
        dy = pts[min(i + 1, n - 1)][1] - pts[max(i - 1, 0)][1]
        ln = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / ln, dx / ln
        w = w0 * (1.0 - i / (n - 1)) ** 0.8 / 2.0
        left.append((pts[i][0] + nx * w, pts[i][1] + ny * w))
        right.append((pts[i][0] - nx * w, pts[i][1] - ny * w))
    shape = left + [pts[-1]] + right[::-1]
    if shadow:
        c.poly([(x + 1, y + 1) for (x, y) in shape], 'NAVY')
    c.poly(shape, 'TEAL')


# --- key art (128x224) ---------------------------------------------------------

def draw_key():
    c = Canvas(128, 224)
    th = math.radians(-30)          # top of the cage leans left: dive to lower-left
    R = make_R(th, 50, 142, 1.2)

    # 1) comet tail — three tongues sharing ONE sweep behind the dive (up-right),
    # bases spread along the bottom rim, roots overlapping; painted first
    b1, b2, b3 = R((1, 35)), R((0, 38)), R((9, 28))
    flame(c, b2, [(0, 0), (9, -8), (17, -20), (24, -36), (30, -56), (35, -80),
                  (38, -106), (38, -126)], 12)
    flame(c, b1, [(0, 0), (9, -4), (20, -11), (31, -22), (41, -38), (48, -56)], 7)
    flame(c, b3, [(0, 0), (8, 0), (17, -2), (26, -7)], 5)
    # drifting teal motes along the tail
    for mx, my in [(101, 40), (110, 60), (116, 82), (104, 22), (96, 100)]:
        c.rect(mx, my, mx, my, 'TEAL')

    # 2) lantern silhouette back-to-front (DUSK iron)
    c.poly(R([(-8, -50), (8, -50), (16, -38), (-16, -38)]), 'DUSK')        # crown
    c.poly(R([(-21, -38), (21, -38), (21, -33), (-21, -33)]), 'DUSK')      # shoulder rim
    c.poly(R([(-19, -33), (19, -33), (16, 26), (-16, 26)]), 'DUSK')        # body
    c.poly(R([(-19, 26), (19, 26), (19, 31), (-19, 31)]), 'DUSK')          # bottom rim
    c.poly(R([(-6, 31), (6, 31), (0, 42)]), 'DUSK')                        # finial
    kx, ky = R((0, -53))
    c.ellipse(kx, ky, 4, 4, 'DUSK')                                        # top knob
    # interior VOID linework: separate the iron from the flame passing behind
    c.line(*R((19, -33)), *R((16, 26)), 'VOID', 1)      # body right edge
    c.line(*R((19, 26)), *R((19, 31)), 'VOID', 1)       # bottom rim right edge
    c.line(*R((-19, 31)), *R((19, 31)), 'VOID', 1)      # bottom rim lower edge
    c.line(*R((8, -50)), *R((16, -38)), 'VOID', 1)      # crown right edge

    # 3) glass panel = caged flame (kept bright — glow is the identity)
    c.poly(R([(-16, -31), (16, -31), (13, 24), (-13, 24)]), 'TEAL')
    c.poly(R([(-14, 18), (14, 18), (13, 24), (-13, 24)]), 'NAVY')          # flame roots
    c.poly(R([(-9, 18), (-6, 13), (-3, 18)]), 'NAVY')                      # root flicker
    c.poly(R([(4, 18), (7, 14), (10, 18)]), 'NAVY')
    c.poly(R([(-16, -31), (-11, -31), (-16, -26)]), 'NAVY')                # top corners
    c.poly(R([(16, -31), (11, -31), (16, -26)]), 'NAVY')

    # 4) cage ribs over the flame (hexagonal read) — BEFORE the eye: it stares past them
    c.line(*R((-11, -31)), *R((-11, 24)), 'DUSK', 2)
    c.line(*R((11, -31)), *R((11, 24)), 'DUSK', 2)

    # 5) THE EYE — upright in world space, glaring straight out of the tilted cage
    ex, ey = R((0, -4))
    c.ellipse(ex, ey, 15, 16, 'NAVY')       # thin flame-root rim
    c.ellipse(ex, ey, 13.6, 14.6, 'TEAL')   # flame ball
    c.ellipse(ex, ey, 11.5, 12.5, 'CYAN')   # iris ring (the only cyan)
    c.ellipse(ex, ey, 8, 9, 'TEAL')         # inner flame
    c.ellipse(ex, ey, 2.2, 9.5, 'VOID')     # hostile slit pupil
    c.rect(ex - 4, ey - 5, ex - 3, ey - 4, 'CYAN')   # catchlight on the inner flame

    # 6) worn SLATE edges (top-left key light) + STEEL glints
    c.line(*R((-8, -50)), *R((-16, -38)), 'SLATE', 1)
    c.line(*R((-21, -37)), *R((10, -37)), 'SLATE', 1)
    c.line(*R((-19, -33)), *R((-16, 25)), 'SLATE', 1)
    c.line(*R((-19, 27)), *R((0, 27)), 'SLATE', 1)
    c.line(*R((-6, -50)), *R((3, -50)), 'STEEL', 1)
    c.rect(kx - 2, ky - 3, kx, ky - 2, 'STEEL')

    # 7) broken hanging loop (sits on the knob) + torn links swinging back (up-right)
    arc(c, R, 0, -59, 6, 75, 380, 'DUSK', 2)     # gap at upper-right = the tear
    arc(c, R, 0, -59, 6, 120, 240, 'SLATE', 1)   # worn lit edge
    gx, gy = R((4, -64))
    chain_link(c, gx + 6, gy - 4, 3.4, 4.8)
    chain_link(c, gx + 14, gy - 9, 4.8, 3.4)

    c.outline('VOID')
    return c


# --- iso battle sprite (64x64) --------------------------------------------------

def draw_iso():
    c = Canvas(64, 64)
    # cast shadow FIRST — detached VOID ellipse, pivot (32, 60): the aerial tell
    c.ellipse(32, 60, 8, 2.6, 'VOID')

    th = math.radians(-10)          # gentle hover bank
    R = make_R(th, 31, 28, 1.0)

    # flame tongues below: downward drips with a slight leftward trail — no
    # shadow copies at this scale, they read as a dark skirt
    flame(c, R((-5, 12)), [(0, 0), (-3, 3), (-6, 5)], 2, shadow=False)
    flame(c, R((0, 15)), [(0, 0), (0, 5), (-2, 9)], 4, shadow=False)
    flame(c, R((4, 12)), [(0, 0), (1, 3), (2, 6)], 2, shadow=False)

    # lantern body
    c.poly(R([(-4, -16), (4, -16), (7, -12), (-7, -12)]), 'DUSK')      # crown
    c.poly(R([(-9, -12), (9, -12), (9, -10), (-9, -10)]), 'DUSK')      # shoulder rim
    c.poly(R([(-8, -10), (8, -10), (7, 12), (-7, 12)]), 'DUSK')        # body
    c.poly(R([(-8, 12), (8, 12), (8, 14), (-8, 14)]), 'DUSK')          # bottom rim
    c.poly(R([(-2, 14), (2, 14), (0, 17)]), 'DUSK')                    # finial

    # glowing core — stays bright teal so the cage-over-glow reads at 1x
    c.poly(R([(-6, -8), (6, -8), (5, 10), (-5, 10)]), 'TEAL')
    c.poly(R([(-5, 7), (5, 7), (5, 10), (-5, 10)]), 'NAVY')            # roots

    # ribs over the glow, then the eye stares past them
    c.line(*R((-4, -9)), *R((-4, 11)), 'DUSK', 1)
    c.line(*R((4, -9)), *R((4, 11)), 'DUSK', 1)

    # eye: cyan iris dead center with a 1px slit (upright, world space)
    ex, ey = 31, 28
    c.ellipse(ex, ey, 4.5, 5, 'NAVY')
    c.ellipse(ex, ey, 3.5, 4, 'TEAL')
    c.ellipse(ex, ey, 2.5, 3, 'CYAN')
    c.line(ex, ey - 1, ex, ey + 1, 'VOID', 1)

    # worn edges + glint
    c.line(*R((-4, -16)), *R((-7, -12)), 'SLATE', 1)
    c.line(*R((-9, -11)), *R((4, -11)), 'SLATE', 1)
    c.line(*R((-8, -10)), *R((-7, 11)), 'SLATE', 1)
    kx, ky = R((-8, -11))
    c.put(kx, ky, 'STEEL')

    # broken loop + one torn link trailing, clearly separated from the loop
    arc(c, R, 0, -19, 3, 75, 350, 'DUSK', 1, steps=16)
    lx, ly = R((3, -21))
    chain_link(c, lx + 4, ly - 3, 2.2, 3.0)

    c.outline('VOID')
    return c


# --- render + contract -----------------------------------------------------------

def main():
    key = draw_key()
    iso = draw_iso()
    lk = lint(key, 128, 224)
    li = lint(iso, 64, 64)
    assert lk == "", f"key lint: {lk}"
    assert li == "", f"iso lint: {li}"
    save(key, f'{OUT}/drone_key.png', 1)
    save(key, f'{OUT}/drone_key@3x.png', 3)
    save(iso, f'{OUT}/drone_iso.png', 1)
    save(iso, f'{OUT}/drone_iso@4x.png', 4)
    with open(f'{OUT}/drone.json', 'w') as f:
        json.dump({"generator": "tools/artgen/gen_drone.py",
                   "iterations": ITERATIONS, "lint": "clean",
                   "spec_name": "The Unblinking"}, f, indent=1)
    print("OK — lint clean, 4 PNGs + provenance written")


if __name__ == '__main__':
    main()
