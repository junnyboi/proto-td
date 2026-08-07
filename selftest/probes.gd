class_name SelfTestProbes
extends RefCounted

## Stateless pixel probes for scenario checks (Phase 9). Kept out of
## SelfTestHarness so the harness API stays within the lint's
## public-method budget; probe rects come from live node rects /
## cell_center, never hardcoded pixels.


## Count of pixels in rect within per-channel tolerance of color.
static func color_in_rect(img: Image, rect: Rect2i, color: Color, tolerance := 0.05) -> int:
	var n := 0
	var x0 := maxi(rect.position.x, 0)
	var y0 := maxi(rect.position.y, 0)
	var x1 := mini(rect.end.x, img.get_width())
	var y1 := mini(rect.end.y, img.get_height())
	for y: int in range(y0, y1):
		for x: int in range(x0, x1):
			var c := img.get_pixel(x, y)
			var close := (
				absf(c.r - color.r) <= tolerance
				and absf(c.g - color.g) <= tolerance
				and absf(c.b - color.b) <= tolerance
			)
			if close:
				n += 1
	return n
