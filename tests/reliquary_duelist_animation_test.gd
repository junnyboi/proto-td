extends SceneTree

const OperatorAnimatorScript := preload("res://scripts/view/operator_animator.gd")
const OperatorVisualCatalogScript := preload("res://data/presentation/operator_visual_catalog.gd")
const UnitStateScript := preload("res://sim/unit_state.gd")

const IDLE_IDS := {
	&"ne": &"op_anim_reliquary_duelist_idle_ne",
	&"nw": &"op_anim_reliquary_duelist_idle_nw",
	&"se": &"op_anim_reliquary_duelist_idle_se",
	&"sw": &"op_anim_reliquary_duelist_idle_sw",
}
const ATTACK_IDS := {
	&"ne": &"op_anim_reliquary_duelist_attack_ne",
	&"nw": &"op_anim_reliquary_duelist_attack_nw",
	&"se": &"op_anim_reliquary_duelist_attack_se",
	&"sw": &"op_anim_reliquary_duelist_attack_sw",
}

var _failures := PackedStringArray()


func _init() -> void:
	_test_premium_identity_routing()
	_test_catalog_contract()
	_test_manifest_and_textures()
	_test_exact_mirrors()
	if _failures.is_empty():
		print("RELIQUARY_DUELIST_ANIMATION_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _test_premium_identity_routing() -> void:
	var premium := UnitStateScript.new()
	premium.op_id = &"guard_2"
	premium.portrait_asset_id = &"portrait_reliquary_duelist"
	_check(
		OperatorVisualCatalogScript.template_for_unit(
			premium.op_id, premium.portrait_asset_id, premium.hero_id, premium.id,
		) == &"reliquary_duelist",
		"Duelist portrait did not resolve to the unique visual template",
	)
	var ordinary := UnitStateScript.new()
	ordinary.op_id = &"guard_2"
	ordinary.portrait_asset_id = &"portrait_guard_2"
	_check(
		OperatorVisualCatalogScript.template_for_unit(
			ordinary.op_id, ordinary.portrait_asset_id, ordinary.hero_id, ordinary.id,
		) == &"guard_2",
		"ordinary guard_2 visual routing changed",
	)


func _test_catalog_contract() -> void:
	var animation := OperatorVisualCatalogScript.get_animation(&"reliquary_duelist")
	_check(animation != null, "Duelist animation definition is missing")
	if animation == null:
		return
	_check(animation.visual_id == &"operator_reliquary_duelist", "visual_id drifted")
	_check(animation.idle_by_direction == IDLE_IDS, "idle direction map drifted")
	_check(animation.attack_by_direction == ATTACK_IDS, "attack direction map drifted")
	_check(animation.idle_frame_count == 24, "idle frame count is not 24")
	_check(animation.attack_frame_count == 13, "attack frame count is not 13")
	_check(is_equal_approx(animation.fps, 12.0), "animation FPS is not 12")
	_check(animation.pivot == Vector2(0.5, 0.94), "animation pivot drifted")
	_check(animation.normalized_subject_height_px == 174, "subject height drifted")
	_check(not animation.placeholder, "Duelist animation is still marked placeholder")
	for error: String in animation.validate_contract():
		_failures.append("animation contract: %s" % error)
	for error: String in OperatorVisualCatalogScript.validate_all():
		_failures.append("visual catalog: %s" % error)


func _test_manifest_and_textures() -> void:
	Art._reset_manifests_for_test()
	for direction: StringName in IDLE_IDS:
		_validate_asset(IDLE_IDS[direction], &"idle", 24, true)
		_validate_asset(ATTACK_IDS[direction], &"attack", 13, false)


func _validate_asset(id: StringName, family: StringName, frames: int, looped: bool) -> void:
	var metadata := Art.metadata(id)
	_check(not metadata.is_empty(), "%s manifest row is missing" % id)
	if metadata.is_empty():
		return
	_check(String(metadata.get("pattern", "")).ends_with(".webp"), "%s is not WebP" % id)
	_check(not bool(metadata.get("placeholder", true)), "%s is marked placeholder" % id)
	_check(Art.frame_count(id) == frames, "%s frame count mismatch" % id)
	_check(Art.size(id) == Vector2i(192, 192), "%s cell mismatch" % id)
	_check(is_equal_approx(Art.fps(id), 12.0), "%s FPS mismatch" % id)
	_check(Art.pivot(id) == Vector2(0.5, 0.94), "%s pivot mismatch" % id)
	_check(Art.animation_names(id) == [family], "%s exposes unsupported actions" % id)
	var region: Dictionary = metadata.get("animations", {}).get(family, {})
	_check(bool(region.get(&"loop", not looped)) == looped, "%s loop flag mismatch" % id)
	_check(Art.texture(id, 0) != null, "%s first frame failed to load" % id)
	_check(Art.texture(id, frames - 1) != null, "%s last frame failed to load" % id)


func _test_exact_mirrors() -> void:
	_compare_mirror("idle_ne.webp", "idle_nw.webp", 24)
	_compare_mirror("idle_se.webp", "idle_sw.webp", 24)
	_compare_mirror("attack_ne.webp", "attack_nw.webp", 13)
	_compare_mirror("attack_se.webp", "attack_sw.webp", 13)
	_check(
		OperatorAnimatorScript.direction_for_facing(UnitStateScript.Facing.RIGHT) == &"se"
		and OperatorAnimatorScript.direction_for_facing(UnitStateScript.Facing.DOWN) == &"sw"
		and OperatorAnimatorScript.direction_for_facing(UnitStateScript.Facing.LEFT) == &"nw"
		and OperatorAnimatorScript.direction_for_facing(UnitStateScript.Facing.UP) == &"ne",
		"operator direction projection drifted",
	)


func _compare_mirror(east_name: String, west_name: String, frame_count: int) -> void:
	var root := "res://assets/sprites/operators/animated/reliquary_duelist/"
	var east := Image.load_from_file(ProjectSettings.globalize_path(root + east_name))
	var west := Image.load_from_file(ProjectSettings.globalize_path(root + west_name))
	_check(east != null and not east.is_empty(), "%s failed to load" % east_name)
	_check(west != null and not west.is_empty(), "%s failed to load" % west_name)
	if east == null or west == null or east.is_empty() or west.is_empty():
		return
	_check(east.get_size() == Vector2i(192 * frame_count, 192), "%s strip size mismatch" % east_name)
	_check(west.get_size() == east.get_size(), "%s strip size mismatch" % west_name)
	for frame: int in frame_count:
		var east_frame := east.get_region(Rect2i(frame * 192, 0, 192, 192))
		east_frame.flip_x()
		var west_frame := west.get_region(Rect2i(frame * 192, 0, 192, 192))
		if east_frame.get_data() != west_frame.get_data():
			_failures.append("mirror mismatch: %s frame %d" % [west_name, frame])
			return


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
