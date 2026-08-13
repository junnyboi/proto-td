extends SceneTree

## Loads a real atlas frame through the production Art seam after the shell half
## removes only that texture's transient imported cache object.
const ArtScript := preload("res://scripts/view/art.gd")
const EXPECTED_SIZE := Vector2(256.0, 256.0)


func _initialize() -> void:
	var texture: Texture2D = ArtScript.texture(&"grunt_anim_walk_se", 0)
	if texture == null:
		_fail("grunt atlas frame is null")
		return
	if texture.get_size() != EXPECTED_SIZE:
		_fail("expected %s frame, got %s" % [EXPECTED_SIZE, texture.get_size()])
		return
	if texture is not AtlasTexture:
		_fail("expected AtlasTexture frame, got %s" % texture.get_class())
		return
	var atlas := texture as AtlasTexture
	if atlas.atlas == null or atlas.atlas.get_size() != Vector2(6400.0, 256.0):
		_fail("source atlas dimensions are unavailable")
		return
	print(
		(
			"[SOURCE-TEXTURE-FALLBACK] PASS frame=%s atlas=%s"
			% [texture.get_size(), atlas.atlas.get_size()]
		)
	)
	quit(0)


func _fail(detail: String) -> void:
	push_error("[SOURCE-TEXTURE-FALLBACK] FAIL: %s" % detail)
	quit(1)
