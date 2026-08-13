extends GutTest


func test_basic_enemy_scope_excludes_mini_boss() -> void:
	for id: StringName in [&"grunt", &"runner", &"heavy", &"drone", &"spellcaster"]:
		assert_true(EnemyAnimator.uses_grunt(id), String(id))
	assert_false(EnemyAnimator.uses_grunt(&"mini_boss"))


func test_grid_tangents_map_to_isometric_directions() -> void:
	assert_eq(EnemyAnimator.direction_from_tangent(Vector2i(1, 0)), &"se")
	assert_eq(EnemyAnimator.direction_from_tangent(Vector2i(0, 1)), &"sw")
	assert_eq(EnemyAnimator.direction_from_tangent(Vector2i(-1, 0)), &"nw")
	assert_eq(EnemyAnimator.direction_from_tangent(Vector2i(0, -1)), &"ne")


func test_charmed_reversal_uses_opposite_direction() -> void:
	assert_eq(EnemyAnimator.direction_from_tangent(Vector2i(1, 0), true), &"nw")
	assert_eq(EnemyAnimator.direction_from_tangent(Vector2i(0, 1), true), &"ne")


func test_corner_path_changes_direction_at_the_segment_boundary() -> void:
	var path: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(2, 1),
	]
	assert_eq(EnemyAnimator.direction_for_path(path, 999_999), &"se")
	assert_eq(EnemyAnimator.direction_for_path(path, 1_000_000), &"sw")
	assert_eq(EnemyAnimator.direction_for_path(path, 2_000_000), &"se")
	for progress: int in [1_000_000, 2_000_000]:
		var current := Pathing.position_of(path, progress)
		var next_reverse := Pathing.position_of(path, progress - 1)
		var displacement := next_reverse - current
		var authoritative_tangent := Vector2i(
			int(signf(displacement.x)), int(signf(displacement.y))
		)
		assert_eq(
			EnemyAnimator.direction_for_path(path, progress, true),
			EnemyAnimator.direction_from_tangent(authoritative_tangent),
			"reverse progress=%d displacement=%s" % [progress, displacement],
		)


func test_walk_uses_twenty_four_motion_frames_and_loops_at_twelve_fps() -> void:
	assert_eq(EnemyAnimator.walk_frame(0.0), 0)
	assert_eq(EnemyAnimator.walk_frame(1.0 / 12.0), 1)
	assert_eq(EnemyAnimator.walk_frame(23.0 / 12.0), 23)
	assert_eq(EnemyAnimator.walk_frame(24.0 / 12.0), 0)
	assert_eq(EnemyAnimator.walk_frame(0.0, 12.0, 25, 7), 7)


func test_attack_counter_spans_the_complete_animation() -> void:
	assert_eq(EnemyAnimator.attack_frame(29, 30), 0)
	assert_eq(EnemyAnimator.attack_frame(15, 30), 12)
	assert_eq(EnemyAnimator.attack_frame(0, 30), 24)
	assert_eq(EnemyAnimator.attack_frame(47, 48), 0)
	assert_eq(EnemyAnimator.attack_frame(0, 48), 24)


func test_logical_ids_cover_state_direction_and_charm() -> void:
	assert_eq(EnemyAnimator.animation_id(&"walk", &"se"), &"grunt_anim_walk_se")
	assert_eq(
		EnemyAnimator.animation_id(&"attack", &"nw", true),
		&"grunt_anim_attack_nw_charmed",
	)


func test_only_faction_palette_changes_bypass_cross_fade() -> void:
	assert_true(
		EnemyAnimator.faction_palette_changed(&"grunt_anim_walk_se", &"grunt_anim_walk_nw_charmed")
	)
	assert_true(
		EnemyAnimator.faction_palette_changed(
			&"grunt_anim_attack_ne_charmed", &"grunt_anim_walk_sw"
		)
	)
	assert_false(
		EnemyAnimator.faction_palette_changed(&"grunt_anim_walk_se", &"grunt_anim_walk_sw")
	)
	assert_false(
		EnemyAnimator.faction_palette_changed(
			&"grunt_anim_walk_ne_charmed", &"grunt_anim_attack_ne_charmed"
		)
	)


func test_blend_weights_are_complementary_and_settle_in_six_frames() -> void:
	assert_eq(EnemyAnimator.blend_alpha(6), Vector2(1.0, 0.0))
	assert_eq(EnemyAnimator.blend_alpha(3), Vector2(0.5, 0.5))
	assert_eq(EnemyAnimator.blend_alpha(0), Vector2(0.0, 1.0))
	for left: int in range(7):
		var weights := EnemyAnimator.blend_alpha(left)
		assert_almost_eq(weights.x + weights.y, 1.0, 0.0001)
