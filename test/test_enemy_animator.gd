extends GutTest


func test_basic_enemy_scope_excludes_mini_boss() -> void:
	for id: StringName in [&"grunt", &"runner", &"heavy", &"drone", &"spellcaster"]:
		assert_true(EnemyAnimator.uses_grunt(id), String(id))
	assert_false(EnemyAnimator.uses_grunt(&"mini_boss"))


func test_directional_scope_includes_the_complete_enemy_roster() -> void:
	for id: StringName in [&"grunt", &"runner", &"heavy", &"drone", &"spellcaster", &"mini_boss"]:
		assert_true(EnemyAnimator.uses_directional_animation(id), String(id))
	assert_false(EnemyAnimator.uses_directional_animation(&"unknown"))


func test_experimental_state_policy_preserves_grunt_walk_fallback() -> void:
	assert_false(EnemyAnimator.uses_experimental_state(&"grunt", &"walk"))
	assert_true(EnemyAnimator.uses_experimental_state(&"grunt", &"attack"))
	for id: StringName in [&"runner", &"heavy", &"drone", &"spellcaster", &"mini_boss"]:
		assert_true(EnemyAnimator.uses_experimental_state(id, &"walk"), String(id))
		assert_true(EnemyAnimator.uses_experimental_state(id, &"attack"), String(id))


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
	assert_eq(EnemyAnimator.attack_frame(29, 30, 8), 0)
	assert_eq(EnemyAnimator.attack_frame(15, 30, 8), 3)
	assert_eq(EnemyAnimator.attack_frame(0, 30, 8), 7)


func test_logical_ids_cover_state_direction_and_charm() -> void:
	assert_eq(EnemyAnimator.animation_id(&"walk", &"se"), &"grunt_anim_walk_se")
	assert_eq(
		EnemyAnimator.animation_id(&"attack", &"nw", true),
		&"grunt_anim_attack_nw_charmed",
	)
	assert_eq(
		EnemyAnimator.experimental_animation_id(&"mini_boss", &"attack", &"sw"),
		&"experimental_salvage_mini_boss_attack_sw",
	)
	assert_true(EnemyAnimator.is_experimental_id(&"experimental_salvage_runner_walk_ne"))
	assert_false(EnemyAnimator.is_experimental_id(&"grunt_anim_walk_ne"))


func test_experimental_walk_uses_all_eight_frames() -> void:
	var enemy := EnemyState.new()
	enemy.id = 0
	var id := &"experimental_salvage_runner_walk_se"
	assert_eq(EnemyAnimator.frame_for(enemy, id, 0.0), 0)
	assert_eq(EnemyAnimator.frame_for(enemy, id, 7.0 / 8.0), 7)
	assert_eq(EnemyAnimator.frame_for(enemy, id, 1.0), 0)


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


func test_damage_flash_is_white_then_red_then_neutral_on_both_layers() -> void:
	var white := Color("ffffff")
	var red := Color("ff3b30")
	assert_eq(EnemyAnimator.damage_flash_color(6, 6, white, red), white)
	assert_eq(EnemyAnimator.damage_flash_color(4, 6, white, red), white)
	assert_eq(EnemyAnimator.damage_flash_color(3, 6, white, red), red)
	assert_eq(EnemyAnimator.damage_flash_color(1, 6, white, red), red)
	assert_eq(EnemyAnimator.damage_flash_color(0, 6, white, red), Color.WHITE)

	var body := ColorRect.new()
	var sprite := EnemyAnimator._texture_rect("Sprite", null, Vector2.ONE * 32.0)
	var blend := EnemyAnimator._texture_rect("BlendSprite", null, Vector2.ONE * 32.0)
	blend.modulate.a = 0.4
	body.add_child(sprite)
	body.add_child(blend)
	EnemyAnimator.apply_damage_flash(body, 6, 6, white, red)
	for layer: TextureRect in [sprite, blend]:
		var material := layer.material as ShaderMaterial
		assert_not_null(material)
		assert_eq(material.get_shader_parameter("flash_color"), white)
		assert_eq(material.get_shader_parameter("flash_strength"), 1.0)
	assert_almost_eq(blend.modulate.a, 0.4, 0.0001, "flash preserves blend alpha")
	EnemyAnimator.apply_damage_flash(body, 3, 6, white, red)
	assert_eq((sprite.material as ShaderMaterial).get_shader_parameter("flash_color"), red)
	EnemyAnimator.apply_damage_flash(body, 0, 6, white, red)
	assert_eq((sprite.material as ShaderMaterial).get_shader_parameter("flash_strength"), 0.0)
	body.free()


func test_damage_before_first_projection_still_flashes_once_registered() -> void:
	var enemy := EnemyState.new()
	enemy.id = 0
	enemy.alive = true
	enemy.last_damage_tick = 5
	var model := BattleModel.new()
	model.tick = 5
	model.enemies = [enemy]
	var body := ColorRect.new()
	var sprite := EnemyAnimator._texture_rect("Sprite", null, Vector2.ONE * 32.0)
	body.add_child(sprite)
	var rects := {0: body}
	var cfg := load("res://data/juice_config.tres") as JuiceConfig
	var feedback := EnemyDamageFeedback.new()
	feedback.register(enemy)
	feedback.process(0.0, model, rects, cfg)
	assert_eq((sprite.material as ShaderMaterial).get_shader_parameter("flash_strength"), 1.0)
	body.free()
