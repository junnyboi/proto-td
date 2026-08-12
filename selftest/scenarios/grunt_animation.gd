extends RefCounted

## TD-015 runtime prototype. A real BattleView renders all five basic enemy
## definitions with the generated grunt family while mini_boss remains the
## control. The view is tick-frozen after spawn; only render-time animation and
## explicitly authored test presentation facts change.

const FRAME_SIZE := 256
const BASIC_IDS: Array[StringName] = [
	&"grunt",
	&"runner",
	&"heavy",
	&"drone",
	&"spellcaster",
]
const GALLERY_DIRECTIONS: Array[StringName] = [&"se", &"sw", &"nw", &"ne", &"se"]


func run(h: SelfTestHarness) -> void:
	h.max_frames = 1200
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	var stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	var gallery_paths: Array[PackedVector2Array] = [
		PackedVector2Array(
			[
				Vector2(2, 2),
				Vector2(3, 2),
				Vector2(4, 2),
				Vector2(5, 2),
				Vector2(6, 2),
				Vector2(6, 3),
				Vector2(6, 4),
				Vector2(5, 4),
				Vector2(4, 4),
				Vector2(3, 4),
				Vector2(2, 4),
				Vector2(2, 3),
				Vector2(2, 2),
				Vector2(3, 2),
			]
		)
	]
	stage.paths = gallery_paths
	var waves: Array[Dictionary] = []
	for enemy_id: StringName in BASIC_IDS + [&"mini_boss"]:
		waves.append({"tick": 0, "enemy_id": enemy_id, "path_idx": 0})
	stage.waves = waves
	stage.wave_starts = PackedInt32Array([0])
	stage.leak_limit = 99
	game.set("pending_stage", stage)
	await h.frames(10)
	var model := game.get("current_battle") as BattleModel
	h.check("battle model exists", model != null)
	if model == null:
		return
	h.expect_done()
	var view := game.get("content") as Node2D
	while model.enemies.size() < 6 and model.tick < 10:
		await h.physics_frames(1)
	h.check(
		"six gallery enemies spawned", model.enemies.size() == 6, "count=%d" % model.enemies.size()
	)
	if model.enemies.size() != 6:
		return
	view.set("ticks_per_frame_scale", 0.0)

	_check_atlases(h)
	_position_gallery(model)
	await h.physics_frames(2)
	var juice_cfg := view.get("cfg") as JuiceConfig
	await h.frames(juice_cfg.wave_banner_frames + 2)
	_check_gallery_nodes(h, view, model)
	await h.shot("grunt_walk_four_directions")

	# The render clock advances walk frames while the model remains frozen.
	var grunt := model.enemies[0]
	var grunt_body := _enemy_body(view, grunt.id)
	var grunt_sprite := grunt_body.get_node("Sprite") as TextureRect
	var start_frame := _atlas_frame(grunt_sprite.texture)
	var start_tick := model.tick
	await h.frames(6)
	var advanced_frame := _atlas_frame(grunt_sprite.texture)
	(
		h
		. check(
			"walk atlas advances on the render clock",
			advanced_frame != start_frame,
			"start=%d advanced=%d" % [start_frame, advanced_frame],
		)
	)
	h.check(
		"walk animation never advances the model", model.tick == start_tick, "tick=%d" % model.tick
	)
	view.set("_enemy_anim_seconds", 23.0 / 12.0)
	view.call("_project")
	h.check("walk reaches its final motion frame", _atlas_frame(grunt_sprite.texture) == 23)
	view.set("_enemy_anim_seconds", 24.0 / 12.0)
	view.call("_project")
	(
		h
		. check(
			"walk runtime loops from frame 23 to frame 0",
			_atlas_frame(grunt_sprite.texture) == 0,
			"frame=%d" % _atlas_frame(grunt_sprite.texture),
		)
	)

	# Direction change at the first corner: SE -> SW. At the midpoint both
	# layers are visible with complementary alpha; six render frames later the
	# old layer is gone.
	grunt.progress_units = 4 * Pathing.PROGRESS_SCALE
	await h.physics_frames(1)
	await h.frames(3)
	_check_mid_blend(h, view, grunt.id, &"grunt_anim_walk_sw")
	await h.shot("grunt_direction_blend_mid")
	await h.frames(5)
	_check_settled(h, view, grunt.id, &"grunt_anim_walk_sw")

	# Existing hashed atk_counter drives a complete attack sheet. No test-only
	# view seam and no new model field are introduced.
	grunt.blocked_by = 999
	grunt.atk_counter = grunt.atk_interval_ticks - 1
	await h.physics_frames(1)
	await h.frames(7)
	(
		h
		. check(
			"attack state selected from combat counter",
			(view.get("_enemy_anim_keys") as Dictionary).get(grunt.id) == &"grunt_anim_attack_sw",
		)
	)
	grunt.atk_counter = 15
	await h.physics_frames(1)
	await h.frames(1)
	(
		h
		. check(
			"attack reaches its midpoint frame",
			_atlas_frame(grunt_sprite.texture) == 12,
			(
				"frame=%d counter=%d interval=%d"
				% [
					_atlas_frame(grunt_sprite.texture),
					grunt.atk_counter,
					grunt.atk_interval_ticks,
				]
			),
		)
	)
	await h.shot("grunt_attack_mid")

	# Charm reverses the same path tangent and swaps to the derived ally-blue
	# NW atlas; the same six-frame blend contract applies.
	grunt.blocked_by = -1
	grunt.atk_counter = 0
	grunt.progress_units = 0
	grunt.faction = EnemyState.Faction.CHARMED
	await h.physics_frames(1)
	await h.frames(3)
	_check_mid_blend(h, view, grunt.id, &"grunt_anim_walk_nw_charmed")
	await h.shot("grunt_charmed_reverse_blend")
	await h.frames(5)
	_check_settled(h, view, grunt.id, &"grunt_anim_walk_nw_charmed")
	await h.shot("grunt_charmed_reverse_settled")
	h.done()


func _check_atlases(h: SelfTestHarness) -> void:
	var bad := 0
	for state: StringName in [&"walk", &"attack"]:
		for direction: StringName in [&"se", &"sw", &"ne", &"nw"]:
			for charmed: bool in [false, true]:
				var id := EnemyAnimator.animation_id(state, direction, charmed)
				var first := Art.texture(id, 0) as AtlasTexture
				var closure := Art.texture(id, 24) as AtlasTexture
				var valid := (
					Art.frame_count(id) == 25
					and Art.size(id) == Vector2i(FRAME_SIZE, FRAME_SIZE)
					and is_equal_approx(Art.fps(id), 12.0)
					and first != null
					and closure != null
					and first.region.size == Vector2(FRAME_SIZE, FRAME_SIZE)
					and closure.region.position.x == 24 * FRAME_SIZE
					and first.filter_clip
					and closure.filter_clip
				)
				if not valid:
					bad += 1
	h.check("sixteen grunt animation atlases resolve", bad == 0, "bad=%d" % bad)


func _position_gallery(model: BattleModel) -> void:
	var segment_indices := PackedInt32Array([0, 4, 6, 11, 2, 8])
	for index: int in model.enemies.size():
		model.enemies[index].progress_units = segment_indices[index] * Pathing.PROGRESS_SCALE


func _check_gallery_nodes(h: SelfTestHarness, view: Node2D, model: BattleModel) -> void:
	var keys := view.get("_enemy_anim_keys") as Dictionary
	for index: int in BASIC_IDS.size():
		var enemy := model.enemies[index]
		var body := _enemy_body(view, enemy.id)
		var expected := EnemyAnimator.animation_id(&"walk", GALLERY_DIRECTIONS[index])
		h.check(
			"%s uses generated body" % BASIC_IDS[index],
			body != null and body.size == Vector2.ONE * 64.0
		)
		if body == null:
			continue
		var sprite := body.get_node_or_null("Sprite") as TextureRect
		var blend := body.get_node_or_null("BlendSprite") as TextureRect
		h.check("%s has two animation layers" % BASIC_IDS[index], sprite != null and blend != null)
		if sprite == null or blend == null:
			continue
		h.check(
			"%s constrains source texture to its body" % BASIC_IDS[index],
			(
				sprite.expand_mode == TextureRect.EXPAND_IGNORE_SIZE
				and blend.expand_mode == TextureRect.EXPAND_IGNORE_SIZE
				and sprite.size == body.size
				and blend.size == body.size
			)
		)
		h.check(
			"%s faces %s" % [BASIC_IDS[index], GALLERY_DIRECTIONS[index]],
			keys.get(enemy.id) == expected,
			"key=%s" % keys.get(enemy.id)
		)
	var boss := _enemy_body(view, model.enemies[5].id)
	h.check(
		"mini-boss keeps its original body size", boss != null and boss.size == Vector2.ONE * 96.0
	)
	h.check(
		"mini-boss has no grunt blend layer",
		boss != null and boss.get_node_or_null("BlendSprite") == null
	)


func _check_mid_blend(
	h: SelfTestHarness, view: Node2D, enemy_id: int, expected: StringName
) -> void:
	var body := _enemy_body(view, enemy_id)
	var sprite := body.get_node("Sprite") as TextureRect
	var blend := body.get_node("BlendSprite") as TextureRect
	var key: StringName = (view.get("_enemy_anim_keys") as Dictionary).get(enemy_id)
	var alpha_sum := sprite.modulate.a + blend.modulate.a
	h.check("transition selects %s" % expected, key == expected, "key=%s" % key)
	h.check(
		"transition keeps both layers visible",
		blend.visible and sprite.modulate.a > 0.0 and blend.modulate.a > 0.0,
		"new=%.3f old=%.3f" % [sprite.modulate.a, blend.modulate.a]
	)
	h.check("blend alpha is complementary", is_equal_approx(alpha_sum, 1.0), "sum=%.3f" % alpha_sum)


func _check_settled(h: SelfTestHarness, view: Node2D, enemy_id: int, expected: StringName) -> void:
	var body := _enemy_body(view, enemy_id)
	var sprite := body.get_node("Sprite") as TextureRect
	var blend := body.get_node("BlendSprite") as TextureRect
	var key: StringName = (view.get("_enemy_anim_keys") as Dictionary).get(enemy_id)
	h.check("settled key is %s" % expected, key == expected, "key=%s" % key)
	h.check("blend layer settles away", not blend.visible and blend.texture == null)
	h.check(
		"new layer settles opaque",
		is_equal_approx(sprite.modulate.a, 1.0),
		"alpha=%.3f" % sprite.modulate.a
	)


func _enemy_body(view: Node2D, enemy_id: int) -> ColorRect:
	return (view.get("_enemy_rects") as Dictionary).get(enemy_id) as ColorRect


func _atlas_frame(texture: Texture2D) -> int:
	var atlas := texture as AtlasTexture
	if atlas == null:
		return -1
	return int(atlas.region.position.x / FRAME_SIZE)
