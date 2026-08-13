extends RefCounted

## TD-025 fail-closed harness smoke. This intentionally proves only scenario
## discovery, positive checks, the fixed seed, and the completion sentinel.


func run(h: SelfTestHarness) -> void:
	h.max_frames = 180
	h.expect_done()
	await h.frames(1)
	h.check("operator animation smoke seed is pinned", h.seed_value == 42)
	h.check(
		"operator animation smoke viewport is initialized",
		h.root.size == Vector2i(1280, 720),
		"viewport=%s" % h.root.size,
	)
	h.check(
		"operator animation smoke manifest source exists",
		ResourceLoader.exists("res://assets/manifest.tres"),
	)
	h.done()
