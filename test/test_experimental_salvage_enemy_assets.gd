extends GutTest

const MANIFEST_PATH := "res://assets/experimental_salvage_manifest.tres"
const PROVENANCE_PATH := "res://assets/experimental_salvage/provenance.json"
const ENEMIES: Array[StringName] = [
	&"grunt",
	&"runner",
	&"heavy",
	&"drone",
	&"spellcaster",
	&"mini_boss",
]
const DIRECTIONS: Array[StringName] = [&"se", &"ne", &"sw", &"nw"]


func before_each() -> void:
	Art._reset_manifests_for_test()


func after_each() -> void:
	Art._reset_manifests_for_test()


func test_inventory_is_exact_namespaced_and_provenance_bound() -> void:
	var manifest := load(MANIFEST_PATH) as AssetManifest
	assert_not_null(manifest)
	if manifest == null:
		return
	assert_eq(manifest.entries.size(), 44)
	var provenance_sha := FileAccess.get_sha256(PROVENANCE_PATH)
	var expected: Dictionary = {}
	for enemy_id: StringName in ENEMIES:
		var states: Array = [&"attack"] if enemy_id == &"grunt" else [&"walk", &"attack"]
		for state: StringName in states:
			for direction: StringName in DIRECTIONS:
				var id := EnemyAnimator.experimental_animation_id(enemy_id, state, direction)
				expected[id] = true
				assert_true(manifest.entries.has(id), String(id))
				var metadata := Art.metadata(id)
				assert_eq(metadata.get(&"namespace"), &"experimental_salvage", String(id))
				assert_true(bool(metadata.get(&"experimental", false)), String(id))
				assert_true(bool(metadata.get(&"placeholder", false)), String(id))
				assert_eq(metadata.get(&"provenance_path"), PROVENANCE_PATH, String(id))
				assert_eq(metadata.get(&"provenance_sha256"), provenance_sha, String(id))
				assert_eq(metadata.get(&"size"), Vector2i(256, 256), String(id))
				assert_eq(metadata.get(&"pivot"), Vector2(0.5, 1.0), String(id))
				assert_eq(Art.frame_count(id), 8, String(id))
				assert_almost_eq(Art.fps(id), 8.0, 0.001, String(id))
				var path := String(metadata.get(&"pattern", ""))
				assert_eq(FileAccess.get_sha256(path), metadata.get(&"sheet_sha256"), String(id))
	assert_eq(expected.size(), 44)
	for raw_id: Variant in manifest.entries:
		assert_true(expected.has(raw_id), String(raw_id))


func test_every_sheet_resolves_complete_clipped_atlas_frames() -> void:
	for id: StringName in _all_ids():
		for frame: int in 8:
			var texture := Art.texture(id, frame) as AtlasTexture
			assert_not_null(texture, "%s frame %d" % [id, frame])
			if texture == null:
				continue
			assert_eq(texture.get_size(), Vector2(256.0, 256.0), String(id))
			assert_eq(texture.region, Rect2(frame * 256, 0, 256, 256), String(id))
			assert_true(texture.filter_clip, String(id))
			assert_gt(_alpha_height(texture.get_image()), 0, "%s frame %d" % [id, frame])


func test_mirrored_directions_are_exact_cellwise_copies() -> void:
	for enemy_id: StringName in ENEMIES:
		var states: Array = [&"attack"] if enemy_id == &"grunt" else [&"walk", &"attack"]
		for state: StringName in states:
			for pair: Array in [[&"se", &"sw"], [&"ne", &"nw"]]:
				var source_id := EnemyAnimator.experimental_animation_id(enemy_id, state, pair[0])
				var mirror_id := EnemyAnimator.experimental_animation_id(enemy_id, state, pair[1])
				for frame: int in 8:
					var expected := _source_frame_image(source_id, frame)
					expected.flip_x()
					var actual := _source_frame_image(mirror_id, frame)
					assert_true(
						actual.get_data() == expected.get_data(),
						"%s frame %d" % [mirror_id, frame],
					)


func test_source_authored_height_order_survives_import() -> void:
	var heights: Dictionary = {}
	for enemy_id: StringName in ENEMIES:
		var state := &"attack" if enemy_id == &"grunt" else &"walk"
		var id := EnemyAnimator.experimental_animation_id(enemy_id, state, &"se")
		heights[enemy_id] = _alpha_height(Art.texture(id, 0).get_image())
	assert_gt(int(heights[&"mini_boss"]), int(heights[&"grunt"]))
	assert_gt(int(heights[&"grunt"]), int(heights[&"heavy"]))
	assert_gt(int(heights[&"heavy"]), int(heights[&"runner"]))
	assert_gt(int(heights[&"heavy"]), int(heights[&"drone"]))
	assert_gt(int(heights[&"heavy"]), int(heights[&"spellcaster"]))


func _all_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for enemy_id: StringName in ENEMIES:
		var states: Array = [&"attack"] if enemy_id == &"grunt" else [&"walk", &"attack"]
		for state: StringName in states:
			for direction: StringName in DIRECTIONS:
				result.append(EnemyAnimator.experimental_animation_id(enemy_id, state, direction))
	return result


func _alpha_height(image: Image) -> int:
	var min_y := image.get_height()
	var max_y := -1
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x, y).a > 0.01:
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	return 0 if max_y < min_y else max_y - min_y + 1


func _source_frame_image(id: StringName, frame: int) -> Image:
	var path := String(Art.metadata(id).get(&"pattern", ""))
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert_false(sheet.is_empty(), path)
	return sheet.get_region(Rect2i(frame * 256, 0, 256, 256))
