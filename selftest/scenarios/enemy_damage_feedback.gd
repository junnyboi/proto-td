extends RefCounted

## TD-034: a nonlethal Bolt hit proves the white/red/restore sequence, HP-bar
## isolation, eight-tick movement/animation pause, blend pause, and T+8 resume;
## a lethal follow-up proves the flash completes before projection cleanup.

const HEAVY_PROGRESS := 3 * Pathing.PROGRESS_SCALE


func run(h: SelfTestHarness) -> void:
	h.max_frames = 1200
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	var stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	var waves: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 100_000, "enemy_id": &"heavy", "path_idx": 0},
	]
	stage.waves = waves
	stage.leak_limit = 99
	game.set("pending_stage", stage)
	await h.frames(10)
	var model := game.get("current_battle") as BattleModel
	h.check("battle model exists", model != null)
	if model == null:
		return
	h.expect_done()
	var view := game.get("content") as Node2D
	while model.enemies.is_empty() and model.tick < 10:
		await h.physics_frames(1)
	h.check("Heavy spawned", model.enemies.size() == 1)
	if model.enemies.is_empty():
		return
	var heavy := model.enemies[0]
	heavy.progress_units = HEAVY_PROGRESS
	view.set("ticks_per_frame_scale", 0.0)
	await h.physics_frames(2)
	var cfg := view.get("cfg") as JuiceConfig
	await h.frames(cfg.wave_banner_frames + 2)
	var body := (view.get("_enemy_rects") as Dictionary).get(heavy.id) as ColorRect
	h.check("Heavy body projected", body != null)
	if body == null:
		return
	var sprite := body.get_node("Sprite") as TextureRect
	var blend := body.get_node("BlendSprite") as TextureRect
	var hp_fill := body.get_node("HpBarBg/HpBarFill") as ColorRect
	var hp_color := hp_fill.color
	var start_progress := heavy.progress_units
	var start_frame := _atlas_frame(sprite.texture)
	var start_tick := model.tick
	var probe := _screen_rect(body)
	var baseline := await h.shot_grab("enemy_damage_baseline")
	var baseline_white := _color_count(baseline, probe, cfg.damage_flash_white)
	var baseline_red := _color_count(baseline, probe, cfg.damage_flash_red)

	(view.get("_enemy_blend_frames") as Dictionary)[heavy.id] = EnemyAnimator.BLEND_FRAMES
	var cell := Pathing.cell_of(model.path_for(heavy.path_idx), heavy.progress_units)
	h.check("nonlethal Bolt accepted", model.apply_action([&"cast", &"bolt", cell]))
	h.check("damage record stamps current tick", heavy.last_damage_tick == start_tick)
	(
		h
		. check(
			"stagger lasts exactly eight ticks",
			heavy.damage_stagger_until_tick == start_tick + model.config.damage_stagger_ticks,
		)
	)
	await h.frames(1)
	h.check("white phase applied", _flash_color(sprite) == cfg.damage_flash_white)
	h.check("white applies to blend layer", _flash_color(blend) == cfg.damage_flash_white)
	h.check("HP bar color is not flashed", hp_fill.color == hp_color)
	var white_shot := await h.shot_grab("enemy_damage_flash_white")
	h.check_pixels(
		"white flash adds visible body pixels",
		white_shot,
		func(image: Image) -> bool:
			return _color_count(image, probe, cfg.damage_flash_white) > baseline_white + 20,
	)

	await h.frames(3)
	h.check("red phase applied", _flash_color(sprite).is_equal_approx(cfg.damage_flash_red))
	h.check("red applies to blend layer", _flash_color(blend).is_equal_approx(cfg.damage_flash_red))
	var red_shot := await h.shot_grab("enemy_damage_flash_red")
	h.check_pixels(
		"red flash adds visible body pixels",
		red_shot,
		func(image: Image) -> bool:
			return _color_count(image, probe, cfg.damage_flash_red) > baseline_red + 20,
	)

	await h.frames(cfg.damage_flash_frames + 2)
	h.check("flash restores neutral strength", is_zero_approx(_flash_strength(sprite)))
	h.check(
		"animation frame paused while render time advances",
		_atlas_frame(sprite.texture) == start_frame
	)
	(
		h
		. check(
			"direction blend countdown paused",
			(
				int((view.get("_enemy_blend_frames") as Dictionary).get(heavy.id, -1))
				== EnemyAnimator.BLEND_FRAMES
			),
		)
	)
	var restored := await h.shot_grab("enemy_damage_flash_restored")
	h.check_pixels(
		"restored body no longer carries flash colors",
		restored,
		func(image: Image) -> bool:
			return (
				_color_count(image, probe, cfg.damage_flash_white) <= baseline_white + 5
				and _color_count(image, probe, cfg.damage_flash_red) <= baseline_red + 5
			),
	)

	for _i: int in model.config.damage_stagger_ticks:
		model.step()
		await h.physics_frames(1)
		h.check("movement remains frozen through T+7", heavy.progress_units == start_progress)
	h.check(
		"model reaches the exact resume boundary", model.tick == heavy.damage_stagger_until_tick
	)
	model.step()
	await h.physics_frames(1)
	h.check("movement resumes on entry tick T+8", heavy.progress_units > start_progress)
	await h.frames(10)
	h.check("animation resumes after stagger", _atlas_frame(sprite.texture) != start_frame)
	(
		h
		. check(
			"direction blend resumes after stagger",
			(
				int((view.get("_enemy_blend_frames") as Dictionary).get(heavy.id, 0))
				< EnemyAnimator.BLEND_FRAMES
			),
		)
	)
	await h.shot("enemy_damage_resumed")

	# Killing blows complete the same body flash before projection cleanup.
	model.call("_damage_enemy", heavy, 999)
	await h.physics_frames(1)
	await h.frames(1)
	(
		h
		. check(
			"lethal hit body retained for flash",
			(view.get("_enemy_rects") as Dictionary).has(heavy.id),
		)
	)
	h.check("lethal hit starts white", _flash_color(sprite) == cfg.damage_flash_white)
	await h.frames(3)
	h.check("lethal hit reaches red", _flash_color(sprite).is_equal_approx(cfg.damage_flash_red))
	await h.shot("enemy_damage_lethal_flash")
	await h.frames(cfg.damage_flash_frames + 2)
	await h.physics_frames(2)
	(
		h
		. check(
			"lethal hit body removed after flash",
			not (view.get("_enemy_rects") as Dictionary).has(heavy.id),
		)
	)
	h.done()


func _atlas_frame(texture: Texture2D) -> int:
	var atlas := texture as AtlasTexture
	if atlas == null:
		return -1
	return int(atlas.region.position.x / 256.0)


func _screen_rect(body: ColorRect) -> Rect2i:
	var rect := body.get_global_rect()
	return Rect2i(Vector2i(rect.position), Vector2i(rect.size))


func _flash_material(layer: TextureRect) -> ShaderMaterial:
	return layer.material as ShaderMaterial


func _flash_color(layer: TextureRect) -> Color:
	return _flash_material(layer).get_shader_parameter("flash_color") as Color


func _flash_strength(layer: TextureRect) -> float:
	return float(_flash_material(layer).get_shader_parameter("flash_strength"))


func _color_count(image: Image, rect: Rect2i, color: Color) -> int:
	if image == null:
		return 0
	return SelfTestProbes.color_in_rect(image, rect, color, 0.08)
