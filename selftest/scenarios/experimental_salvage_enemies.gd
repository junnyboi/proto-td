extends RefCounted

## TD-030 experimental-salvage runtime and readability gate. A real BattleView
## renders all six enemy definitions through the view-only EnemyAnimator while
## model ticks stay frozen. Grunt retains its existing walk/charmed family and
## uses salvage only for attacks; every other enemy uses salvage walk + attack.

const FRAME_SIZE := 256
const RUNTIME_BODY_PX := 48.0
const ENEMY_IDS: Array[StringName] = [
	&"grunt",
	&"runner",
	&"heavy",
	&"drone",
	&"spellcaster",
	&"mini_boss",
]
const GALLERY_DIRECTIONS: Array[StringName] = [&"se", &"se", &"sw", &"nw", &"nw", &"ne"]


func run(h: SelfTestHarness) -> void:
	h.max_frames = 1500
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	var stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	stage.paths = [
		PackedVector2Array(
			[
				Vector2(1, 1),
				Vector2(2, 1),
				Vector2(3, 1),
				Vector2(4, 1),
				Vector2(5, 1),
				Vector2(6, 1),
				Vector2(6, 2),
				Vector2(6, 3),
				Vector2(5, 3),
				Vector2(4, 3),
				Vector2(3, 3),
				Vector2(2, 3),
				Vector2(1, 3),
				Vector2(1, 2),
				Vector2(1, 1),
				Vector2(2, 1),
			]
		)
	]
	var waves: Array[Dictionary] = []
	for enemy_id: StringName in ENEMY_IDS:
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
	while model.enemies.size() < ENEMY_IDS.size() and model.tick < 10:
		await h.physics_frames(1)
	(
		h
		. check(
			"six experimental gallery enemies spawned",
			model.enemies.size() == ENEMY_IDS.size(),
			"count=%d" % model.enemies.size(),
		)
	)
	if model.enemies.size() != ENEMY_IDS.size():
		return
	view.set("ticks_per_frame_scale", 0.0)

	_check_atlases(h)
	_position_gallery(model)
	await h.physics_frames(2)
	var juice_cfg := view.get("cfg") as JuiceConfig
	await h.frames(juice_cfg.wave_banner_frames + 2)
	_check_walk_gallery(h, view, model)
	await h.shot("experimental_salvage_walk_gallery")

	# Salvage walking advances on render time while authoritative model time is frozen.
	var runner := model.enemies[1]
	var runner_body := _enemy_body(view, runner.id)
	var runner_sprite := runner_body.get_node("Sprite") as TextureRect
	var start_frame := _atlas_frame(runner_sprite.texture)
	var start_tick := model.tick
	await h.frames(10)
	var advanced_frame := _atlas_frame(runner_sprite.texture)
	(
		h
		. check(
			"experimental walk advances on render time",
			advanced_frame != start_frame,
			"start=%d advanced=%d" % [start_frame, advanced_frame],
		)
	)
	h.check("experimental walk never advances the model", model.tick == start_tick)

	# A real path corner selects a new namespaced direction and cross-fades it.
	runner.progress_units = 5 * Pathing.PROGRESS_SCALE
	await h.physics_frames(1)
	await h.frames(3)
	var runner_sw := EnemyAnimator.experimental_animation_id(&"runner", &"walk", &"sw")
	_check_mid_blend(h, view, runner.id, runner_sw)
	await h.shot("experimental_salvage_direction_blend")
	await h.frames(5)
	_check_settled(h, view, runner.id, runner_sw)

	# Existing combat counters drive all six complete eight-frame attack sheets.
	for enemy: EnemyState in model.enemies:
		enemy.blocked_by = 999
		enemy.atk_counter = enemy.atk_interval_ticks / 2
	await h.physics_frames(1)
	await h.frames(7)
	_check_attack_gallery(h, view, model)
	await h.shot("experimental_salvage_attack_gallery")

	# The missing Grunt walk/charmed salvage states fail over to the previously
	# integrated atlas family rather than inventing a palette transformation.
	var grunt := model.enemies[0]
	grunt.blocked_by = -1
	grunt.atk_counter = 0
	grunt.progress_units = 12 * Pathing.PROGRESS_SCALE
	grunt.faction = EnemyState.Faction.CHARMED
	await h.physics_frames(1)
	await h.frames(7)
	var expected_charmed := EnemyAnimator.animation_id(
		&"walk",
		EnemyAnimator.direction_for_path(
			model.path_for(grunt.path_idx), grunt.progress_units, true
		),
		true
	)
	_check_settled(h, view, grunt.id, expected_charmed)
	(
		h
		. check(
			"Grunt charmed fallback stays outside experimental namespace",
			not EnemyAnimator.is_experimental_id(expected_charmed),
			"key=%s" % expected_charmed,
		)
	)
	await h.shot("experimental_salvage_grunt_charmed_fallback")
	h.done()


func _check_atlases(h: SelfTestHarness) -> void:
	var bad := 0
	var count := 0
	for enemy_id: StringName in ENEMY_IDS:
		var states: Array = [&"attack"] if enemy_id == &"grunt" else [&"walk", &"attack"]
		for state: StringName in states:
			for direction: StringName in [&"se", &"sw", &"ne", &"nw"]:
				count += 1
				var id := EnemyAnimator.experimental_animation_id(enemy_id, state, direction)
				var first := Art.texture(id, 0) as AtlasTexture
				var last := Art.texture(id, 7) as AtlasTexture
				var metadata := Art.metadata(id)
				var valid: bool = (
					Art.frame_count(id) == 8
					and Art.size(id) == Vector2i(FRAME_SIZE, FRAME_SIZE)
					and is_equal_approx(Art.fps(id), 8.0)
					and bool(metadata.get(&"experimental", false))
					and bool(metadata.get(&"placeholder", false))
					and metadata.get(&"namespace") == &"experimental_salvage"
					and first != null
					and last != null
					and first.region.size == Vector2(FRAME_SIZE, FRAME_SIZE)
					and last.region.position.x == 7 * FRAME_SIZE
					and first.filter_clip
					and last.filter_clip
				)
				if not valid:
					bad += 1
	h.check(
		"exactly 44 salvage atlases resolve",
		count == 44 and bad == 0,
		"count=%d bad=%d" % [count, bad]
	)
	h.check("Grunt walk fallback remains available", Art.frame_count(&"grunt_anim_walk_se") == 25)


func _position_gallery(model: BattleModel) -> void:
	var segment_indices := PackedInt32Array([0, 3, 5, 7, 10, 13])
	for index: int in model.enemies.size():
		model.enemies[index].progress_units = segment_indices[index] * Pathing.PROGRESS_SCALE


func _check_walk_gallery(h: SelfTestHarness, view: Node2D, model: BattleModel) -> void:
	var keys := view.get("_enemy_anim_keys") as Dictionary
	for index: int in ENEMY_IDS.size():
		var enemy := model.enemies[index]
		var body := _enemy_body(view, enemy.id)
		var expected := (
			EnemyAnimator.animation_id(&"walk", GALLERY_DIRECTIONS[index])
			if enemy.def_id == &"grunt"
			else EnemyAnimator.experimental_animation_id(
				enemy.def_id, &"walk", GALLERY_DIRECTIONS[index]
			)
		)
		(
			h
			. check(
				"%s uses the readable directional body" % ENEMY_IDS[index],
				body != null and body.size.is_equal_approx(Vector2.ONE * RUNTIME_BODY_PX),
				"size=%s expected=%s"
				% [body.size if body != null else Vector2.ZERO, Vector2.ONE * RUNTIME_BODY_PX],
			)
		)
		if body == null:
			continue
		var sprite := body.get_node_or_null("Sprite") as TextureRect
		var blend := body.get_node_or_null("BlendSprite") as TextureRect
		h.check("%s has two animation layers" % ENEMY_IDS[index], sprite != null and blend != null)
		(
			h
			. check(
				"%s faces %s" % [ENEMY_IDS[index], GALLERY_DIRECTIONS[index]],
				keys.get(enemy.id) == expected,
				"key=%s expected=%s" % [keys.get(enemy.id), expected],
			)
		)
	(
		h
		. check(
			"Mini Boss remains the tallest authored silhouette",
			_alpha_height_for(&"mini_boss", &"walk") > _alpha_height_for(&"heavy", &"walk"),
		)
	)
	(
		h
		. check(
			"Heavy remains taller than the short enemy band",
			_alpha_height_for(&"heavy", &"walk") > _alpha_height_for(&"runner", &"walk"),
		)
	)


func _check_attack_gallery(h: SelfTestHarness, view: Node2D, model: BattleModel) -> void:
	var keys := view.get("_enemy_anim_keys") as Dictionary
	for enemy: EnemyState in model.enemies:
		var expected := EnemyAnimator.animation_id_for(enemy, model)
		var body := _enemy_body(view, enemy.id)
		var sprite := body.get_node("Sprite") as TextureRect
		var expected_frame := EnemyAnimator.attack_frame(
			enemy.atk_counter, enemy.atk_interval_ticks, 8
		)
		(
			h
			. check(
				"%s selects namespaced attack" % enemy.def_id,
				EnemyAnimator.is_experimental_id(expected) and keys.get(enemy.id) == expected,
				"key=%s expected=%s" % [keys.get(enemy.id), expected],
			)
		)
		(
			h
			. check(
				"%s attack projects counter-derived frame" % enemy.def_id,
				_atlas_frame(sprite.texture) == expected_frame,
				"frame=%d expected=%d" % [_atlas_frame(sprite.texture), expected_frame],
			)
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
	(
		h
		. check(
			"transition keeps both layers visible",
			blend.visible and sprite.modulate.a > 0.0 and blend.modulate.a > 0.0,
			"new=%.3f old=%.3f" % [sprite.modulate.a, blend.modulate.a],
		)
	)
	h.check("blend alpha is complementary", is_equal_approx(alpha_sum, 1.0), "sum=%.3f" % alpha_sum)


func _check_settled(h: SelfTestHarness, view: Node2D, enemy_id: int, expected: StringName) -> void:
	var body := _enemy_body(view, enemy_id)
	var sprite := body.get_node("Sprite") as TextureRect
	var blend := body.get_node("BlendSprite") as TextureRect
	var key: StringName = (view.get("_enemy_anim_keys") as Dictionary).get(enemy_id)
	h.check("settled key is %s" % expected, key == expected, "key=%s" % key)
	h.check("blend layer settles away", not blend.visible and blend.texture == null)
	(
		h
		. check(
			"new layer settles opaque",
			is_equal_approx(sprite.modulate.a, 1.0),
			"alpha=%.3f" % sprite.modulate.a,
		)
	)


func _enemy_body(view: Node2D, enemy_id: int) -> ColorRect:
	return (view.get("_enemy_rects") as Dictionary).get(enemy_id) as ColorRect


func _atlas_frame(texture: Texture2D) -> int:
	var atlas := texture as AtlasTexture
	if atlas == null:
		return -1
	return int(atlas.region.position.x / FRAME_SIZE)


func _alpha_height_for(enemy_id: StringName, state: StringName) -> int:
	var id := EnemyAnimator.experimental_animation_id(enemy_id, state, &"se")
	var image := Art.texture(id, 0).get_image()
	var min_y := image.get_height()
	var max_y := -1
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x, y).a > 0.01:
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	return 0 if max_y < min_y else max_y - min_y + 1
