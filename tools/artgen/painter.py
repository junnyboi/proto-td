"""Deterministic pixel-illustration painter — the shared art lane for the
"Torchlight & Steel" reference set. Dependency-free (stdlib zlib/struct).

Every generator script in this directory imports this module, paints with the
TD32 palette (probe colors are a hard lint), and saves through save()/lint()
so palette membership, hard alpha, and canvas size are enforced mechanically.

Run any generator from the repo root:  python3 tools/artgen/gen_<id>.py
"""
import zlib, struct, os, math

# --- TD32 (mirrors tools/pixel/palette.gd; the only legal colors) -----------
PALETTE = {
    "INK": "1a1c2c", "PLUM": "5d275d", "CRIMSON": "b13e53", "CORAL": "ef7d57",
    "GOLD": "ffcd75", "LIME": "a7f070", "GREEN": "38b764", "TEAL": "257179",
    "NAVY": "29366f", "BLUE": "3b5dc9", "SKY": "41a6f6", "CYAN": "73eff7",
    "WHITE": "f4f4f4", "STEEL": "94b0c2", "SLATE": "566c86", "DUSK": "333c57",
    "VOID": "0f0f1b", "PALE": "c7d6e8", "GRAY": "6e7a94", "DEEP_GREEN": "1a5f43",
    "WINE": "7a2436", "PALE_GOLD": "ffe9b0", "BRONZE": "a3702b", "BROWN": "6b4a34",
    "UMBER": "3a2a24", "SKIN_SHADOW": "8a4836", "SKIN": "c77b58",
    "SKIN_LIGHT": "e8b796", "SKIN_PALE": "f6dcbf", "ORCHID": "c964cf",
    "MAGENTA": "94216a", "ROSE": "e39aac",
}
RESERVED = {"WHITE", "SKY"}  # pixel-probe colors — banned in ALL art

# canonical hue-shifted ramps (dark -> light); shade DOWN a ramp, never
# value-scale one color
RAMPS = {
    "fire":   ["VOID", "WINE", "CRIMSON", "CORAL", "GOLD", "PALE_GOLD"],
    "steel":  ["VOID", "DUSK", "SLATE", "STEEL", "PALE"],
    "leaf":   ["VOID", "DEEP_GREEN", "GREEN", "LIME"],
    "storm":  ["VOID", "NAVY", "TEAL", "CYAN"],
    "arcane": ["VOID", "PLUM", "MAGENTA", "ORCHID", "ROSE"],
    "earth":  ["VOID", "UMBER", "BROWN", "BRONZE", "GOLD"],
    "skin":   ["SKIN_SHADOW", "SKIN", "SKIN_LIGHT", "SKIN_PALE"],
}


def rgb(name):
    h = PALETTE[name]
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[None] * w for _ in range(h)]

    # -- primitives (all clip silently) --------------------------------------
    def put(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = c

    def get(self, x, y):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y][x]
        return None

    def ellipse(self, cx, cy, rx, ry, c):
        if rx <= 0 or ry <= 0:
            return
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                dx, dy = (x - cx) / rx, (y - cy) / ry
                if dx * dx + dy * dy <= 1.0:
                    self.put(x, y, c)

    def rect(self, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.put(x, y, c)

    def poly(self, pts, c):
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            xs = []
            for i in range(len(pts)):
                x0, y0 = pts[i]
                x1, y1 = pts[(i + 1) % len(pts)]
                if (y0 <= y < y1) or (y1 <= y < y0):
                    xs.append(x0 + (y - y0) / (y1 - y0) * (x1 - x0))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(round(xs[i])), int(round(xs[i + 1])) + 1):
                    self.put(x, y, c)

    def line(self, x0, y0, x1, y1, c, w=1):
        steps = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(steps + 1):
            t = i / steps
            x, y = x0 + t * (x1 - x0), y0 + t * (y1 - y0)
            r = w / 2.0
            for oy in range(-int(r), int(r) + 1):
                for ox in range(-int(r), int(r) + 1):
                    if ox * ox + oy * oy <= r * r + 0.5:
                        self.put(x + ox, y + oy, c)

    def curve(self, pts, c, w=1):
        """Quadratic-ish polyline through control points."""
        for i in range(len(pts) - 1):
            self.line(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], c, w)

    def blit(self, other, ox, oy):
        for y in range(other.h):
            for x in range(other.w):
                if other.px[y][x] is not None:
                    self.put(ox + x, oy + y, other.px[y][x])

    def flip_x(self):
        for row in self.px:
            row.reverse()

    def replace(self, frm, to, box=None):
        x0, y0, x1, y1 = box or (0, 0, self.w - 1, self.h - 1)
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                if self.get(x, y) == frm:
                    self.put(x, y, to)

    def shade_under(self, region_color, shadow_color, dx=1, dy=1):
        """Cheap cel shadow: pixels of region_color whose (x-dx,y-dy) neighbor
        is empty or different get shadow_color — bottom-right shading for the
        pinned top-left key light."""
        marks = []
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] == region_color:
                    n = self.get(x + dx, y + dy)
                    if n is None or n != region_color:
                        marks.append((x, y))
        for x, y in marks:
            self.px[y][x] = shadow_color

    def outline(self, c="VOID"):
        """Exterior 1px outline around the full silhouette."""
        add = []
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is None:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        n = self.get(x + dx, y + dy)
                        if n is not None and n != c:
                            add.append((x, y))
                            break
        for x, y in add:
            self.px[y][x] = c

    # -- output ---------------------------------------------------------------
    def used_colors(self):
        return {c for row in self.px for c in row if c}


def lint(canvas, expected_w, expected_h):
    """Returns "" when clean, else the violation (mirrors gen_assets lint)."""
    if (canvas.w, canvas.h) != (expected_w, expected_h):
        return f"canvas {canvas.w}x{canvas.h} != {expected_w}x{expected_h}"
    used = canvas.used_colors()
    unknown = used - set(PALETTE)
    if unknown:
        return f"colors outside TD32: {unknown}"
    banned = used & RESERVED
    if banned:
        return f"probe-reserved colors used: {banned}"
    if len(used) < 6:
        return f"only {len(used)} colors — under-rendered"
    opaque = sum(1 for row in canvas.px for c in row if c)
    if opaque < canvas.w * canvas.h * 0.12:
        return f"only {opaque} opaque px — silhouette too thin"
    return ""


def encode_png(canvas, scale=1):
    w, h = canvas.w * scale, canvas.h * scale
    raw = b""
    for y in range(h):
        row = b"\x00"
        for x in range(w):
            c = canvas.px[y // scale][x // scale]
            row += bytes(rgb(c)) if c else b"\x00\x00\x00\x00"
        raw += row
    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9))
            + chunk(b"IEND", b""))


def save(canvas, path, scale=1):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(encode_png(canvas, scale))
    return path
