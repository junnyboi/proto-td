extends RefCounted

## Pixel-canvas helpers for the Lane A asset generator. Pure, deterministic
## image ops over hand-authored ASCII pixel maps — same input rows, byte-
## identical PNG out (the v1 generator discipline). All helpers are static;
## the generator preloads this script (no class_name — tool scripts avoid
## the import-order race, G4).

const Palette := preload("res://tools/pixel/palette.gd")


## Compile ASCII rows into an Image. legend maps single chars -> Color;
## '.' is transparent. Unknown chars compile to magenta and push an error
## so a typo is visible in the sheet, never silent.
static func from_rows(rows: Array[String], legend: Dictionary, size := Vector2i.ZERO) -> Image:
	var height := rows.size()
	var width := 0
	for row: String in rows:
		width = maxi(width, row.length())
	if size != Vector2i.ZERO:
		width = size.x
		height = size.y
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y: int in mini(rows.size(), height):
		var row := rows[y]
		for x: int in mini(row.length(), width):
			var ch := row[x]
			if ch == ".":
				continue
			if legend.has(ch):
				img.set_pixel(x, y, legend[ch])
			else:
				push_error("pix.from_rows: unknown char '%s' at %d,%d" % [ch, x, y])
				img.set_pixel(x, y, Color.MAGENTA)
	return img


## Expand a 1 px outline around the silhouette: every transparent pixel
## 4-adjacent to an opaque pixel becomes `color` (the pinned outline pass).
static func outline(img: Image, color: Color = Palette.VOID) -> Image:
	var out := img.duplicate() as Image
	var size := img.get_size()
	for y: int in size.y:
		for x: int in size.x:
			if img.get_pixel(x, y).a > 0.0:
				continue
			var edge := false
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p := Vector2i(x, y) + offset
				if p.x < 0 or p.y < 0 or p.x >= size.x or p.y >= size.y:
					continue
				if img.get_pixel(p.x, p.y).a > 0.0:
					edge = true
					break
			if edge:
				out.set_pixel(x, y, color)
	return out


## Exact-color remap; keys are Color.to_html(false) strings (RGBA8-safe).
static func recolor(img: Image, map: Dictionary) -> Image:
	var out := img.duplicate() as Image
	var size := img.get_size()
	for y: int in size.y:
		for x: int in size.x:
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var key := c.to_html(false)
			if map.has(key):
				out.set_pixel(x, y, map[key])
	return out


## Charmed variant (parent §6.2, always derived): every body color mapped to
## the ally-blue ramp by luminance, outline recolored cyan, heart pixels
## stamped above the head. The mid ramp step is the probed CHARMED_COLOR.
static func charmed_variant(img: Image) -> Image:
	var out := img.duplicate() as Image
	var size := img.get_size()
	var outline_key := Palette.VOID.to_html(false)
	var top := size.y
	var left := size.x
	var right := 0
	for y: int in size.y:
		for x: int in size.x:
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			top = mini(top, y)
			left = mini(left, x)
			right = maxi(right, x)
			if c.to_html(false) == outline_key:
				out.set_pixel(x, y, Palette.CHARM_OUTLINE)
			else:
				out.set_pixel(x, y, Palette.nearest_charm(c))
	var mid := (left + right) / 2
	for offset: Vector2i in [Vector2i(-4, -2), Vector2i(3, -3)]:
		_stamp_heart(out, Vector2i(mid + offset.x, maxi(top + offset.y, 1)))
	return out


static func _stamp_heart(img: Image, at: Vector2i) -> void:
	for p: Vector2i in [Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]:
		var q := at + p
		if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
			img.set_pixel(q.x, q.y, Palette.CHARM_HEART)


static func mirror_x(img: Image) -> Image:
	var out := img.duplicate() as Image
	out.flip_x()
	return out


static func shifted(img: Image, by: Vector2i) -> Image:
	var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	out.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), by)
	return out


static func upscale(img: Image, factor: int) -> Image:
	var out := img.duplicate() as Image
	out.resize(img.get_width() * factor, img.get_height() * factor, Image.INTERPOLATE_NEAREST)
	return out


static func blend(dst: Image, src: Image, at: Vector2i) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), at)


## Squash toward the baseline for the deploy-crouch frame: drops `rows`
## interior rows just under the head band and re-anchors on the bottom.
static func crouch(img: Image, rows: int, head_band: int) -> Image:
	var size := img.get_size()
	var out := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y: int in size.y:
		var src_y := y
		if y >= size.y - rows:
			continue
		if y > head_band:
			src_y = y + rows if y + rows < size.y else size.y - 1
		for x: int in size.x:
			var c := img.get_pixel(x, src_y)
			if c.a > 0.0:
				out.set_pixel(x, y + rows, c)
	return out


## Generator-side lint (graphics proposal §6, v1 subset): every opaque pixel
## in the allowed set, alpha strictly 0/255, canvas exact. Returns "" or the
## first violation — the generator aborts on any non-empty result.
static func lint(img: Image, expected: Vector2i, allowed: Array[Color]) -> String:
	if img.get_size() != expected:
		return "canvas %s != expected %s" % [img.get_size(), expected]
	var allowed_keys: Dictionary = {}
	for c: Color in allowed:
		allowed_keys[c.to_html(false)] = true
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a != 0.0 and c.a < 1.0:
				return "soft alpha %.2f at %d,%d" % [c.a, x, y]
			if c.a == 1.0 and not allowed_keys.has(c.to_html(false)):
				return "off-palette #%s at %d,%d" % [c.to_html(false), x, y]
	return ""
