extends GutTest


func test_model_facing_maps_to_four_independent_directions() -> void:
	assert_eq(OperatorAnimator.direction_for_facing(UnitState.Facing.RIGHT), &"se")
	assert_eq(OperatorAnimator.direction_for_facing(UnitState.Facing.DOWN), &"sw")
	assert_eq(OperatorAnimator.direction_for_facing(UnitState.Facing.LEFT), &"nw")
	assert_eq(OperatorAnimator.direction_for_facing(UnitState.Facing.UP), &"ne")


func test_idle_loops_twenty_four_frames_at_twelve_fps() -> void:
	assert_eq(OperatorAnimator.idle_frame(0.0), 0)
	assert_eq(OperatorAnimator.idle_frame(1.0 / 12.0), 1)
	assert_eq(OperatorAnimator.idle_frame(23.0 / 12.0), 23)
	assert_eq(OperatorAnimator.idle_frame(24.0 / 12.0), 0)


func test_attack_age_mapping_is_twelve_fps_on_thirty_hz_ticks() -> void:
	var expected: Array[int] = [
		0, 0, 0, 1, 1, 2, 2, 2, 3, 3, 4, 4, 4, 5, 5, 6, 6,
		6, 7, 7, 8, 8, 8, 9, 9, 10, 10, 10, 11, 11, 12, 12, 12,
	]
	assert_eq(OperatorAnimator.attack_window_ticks(13, 12.0), 34)
	assert_eq(OperatorAnimator.attack_frame(0, 13, 12.0), 0)
	for age: int in range(1, 34):
		assert_true(OperatorAnimator.attack_active(age, 13, 12.0), "age=%d" % age)
		assert_eq(OperatorAnimator.attack_frame(age, 13, 12.0), expected[age - 1], "age=%d" % age)
	assert_false(OperatorAnimator.attack_active(34, 13, 12.0))


func test_selection_reads_but_does_not_mutate_unit_state() -> void:
	var unit := UnitState.new()
	unit.id = 17
	unit.op_id = &"vanguard_2"
	unit.facing = UnitState.Facing.LEFT
	unit.last_attack_tick = 41
	unit.hp = 9
	unit.sp = 3
	var animation := OperatorVisualCatalog.get_animation(unit.op_id)
	assert_not_null(animation)
	var before := [unit.id, unit.op_id, unit.facing, unit.last_attack_tick, unit.hp, unit.sp]
	var selected := OperatorAnimator.selection(unit, 42, 3.0, animation)
	assert_eq(selected[&"state"], &"attack")
	assert_eq(selected[&"direction"], &"nw")
	assert_eq(selected[&"frame"], 0)
	assert_eq(selected[&"logical_id"], &"op_anim_vanguard_2_attack_nw")
	assert_eq([unit.id, unit.op_id, unit.facing, unit.last_attack_tick, unit.hp, unit.sp], before)


func test_admitted_texture_projection_sets_metadata_without_flipping() -> void:
	Art._reset_manifests_for_test()
	var unit := UnitState.new()
	unit.op_id = &"defender_1"
	unit.facing = UnitState.Facing.DOWN
	var animation := OperatorVisualCatalog.get_animation(unit.op_id)
	var sprite := TextureRect.new()
	assert_true(OperatorAnimator.apply(unit, 0, 0.0, sprite, animation))
	assert_not_null(sprite.texture)
	assert_false(sprite.flip_h)
	assert_eq(sprite.get_meta(&"operator_animation_state"), &"idle")
	assert_eq(sprite.get_meta(&"operator_animation_direction"), &"sw")
	assert_eq(sprite.get_meta(&"operator_animation_frame"), 0)
	sprite.free()
	Art._reset_manifests_for_test()


func test_catalog_boundary_preserves_legacy_fallback_for_blocked_classes() -> void:
	for admitted: StringName in [&"caster_1", &"caster_2", &"defender_2", &"sniper_1", &"sniper_2"]:
		assert_not_null(OperatorVisualCatalog.get_animation(admitted), String(admitted))
	assert_null(OperatorVisualCatalog.get_animation(&"vanguard_1"))
	assert_null(OperatorVisualCatalog.get_animation(&"guard_1"))
	assert_null(OperatorVisualCatalog.get_animation(&"guard_2"))
	assert_null(OperatorVisualCatalog.get_animation(&"unknown"))


func test_runtime_body_sizes_preserve_pinned_relative_heights() -> void:
	var defender := OperatorVisualCatalog.get_animation(&"defender_1")
	var banner_guard := OperatorVisualCatalog.get_animation(&"vanguard_2")
	assert_lt(OperatorAnimator.body_size(defender).y, OperatorAnimator.body_size(banner_guard).y)
	var caster := OperatorVisualCatalog.get_animation(&"caster_1")
	assert_eq(caster.normalized_subject_height_px, 158)
	assert_almost_eq(OperatorAnimator.body_size(caster).y, 192.0 * 64.0 / 158.0, 0.0001)
