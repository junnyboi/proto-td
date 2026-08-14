extends GutTest

const GRUNT_PATH := "res://assets/sprites/grunt_anim_walk_se.png"
const GRUNT_ID := &"grunt_anim_walk_se"


func before_each() -> void:
	Art._reset_manifests_for_test()


func after_each() -> void:
	Art._reset_manifests_for_test()


func test_direct_png_loader_builds_the_complete_source_texture() -> void:
	var texture := Art._load_source_png(GRUNT_PATH)
	assert_not_null(texture)
	assert_eq(texture.get_size(), Vector2(6400.0, 256.0))


func test_direct_png_loader_rejects_missing_and_non_png_sources() -> void:
	assert_null(Art._load_source_png("res://assets/sprites/not_present.png"))
	assert_null(Art._load_source_png("res://project.godot"))


func test_manifest_atlas_still_returns_one_exact_frame_region() -> void:
	var texture := Art.texture(GRUNT_ID, 7)
	assert_true(texture is AtlasTexture)
	assert_eq(texture.get_size(), Vector2(256.0, 256.0))
	assert_eq((texture as AtlasTexture).region, Rect2(1792.0, 0.0, 256.0, 256.0))


func test_stale_null_cache_entry_is_discarded_and_retried() -> void:
	var cache_key := "%s/%d" % [GRUNT_ID, 0]
	Art._cache[cache_key] = null
	var texture := Art.texture(GRUNT_ID, 0)
	assert_not_null(texture)
	assert_true(Art._cache.get(cache_key) is Texture2D)


func test_missing_manifest_entry_never_creates_a_null_cache_record() -> void:
	assert_null(Art.texture(&"missing_texture_contract", 0))
	assert_false(Art._cache.has("missing_texture_contract/0"))


func test_experimental_manifest_is_visible_without_shadowing_base() -> void:
	var id := &"experimental_salvage_heavy_attack_ne"
	assert_eq(Art.frame_count(id), 8)
	assert_not_null(Art.texture(id, 7))
	assert_not_null(Art.texture(GRUNT_ID, 7))
