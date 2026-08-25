extends "res://scripts/view/battle_view.gd"


func _ready() -> void:
	var source_stage := load("res://data/stages/s7.tres") as StageDef
	_stage = source_stage.copy_for_viewport(get_viewport_rect().size)
	_stage_theme = null
	var config := load("res://data/config/game.tres") as GameConfig
	_enemy_defs = _load_enemy_defs(_stage)
	_op_defs = _load_catalog("res://data/operators", "OperatorDef")
	_trap_defs = _load_catalog("res://data/traps", "TrapDef")
	_spell_defs = _load_catalog("res://data/spells", "SpellDef")
	model = BattleModel.create(
		_stage,
		[],
		707,
		config,
		_enemy_defs,
		_op_defs,
		_trap_defs,
		_spell_defs,
	)
	if model == null or not _build_grid(_stage):
		push_error("slow_field_visual_harness: setup failed")
		get_tree().quit(1)
		return
	_build_hud()
	_spell_bar = SpellBar.new()
	_spell_bar.name = "SpellBar"
	_spell_bar.z_index = UI_OVERLAY_Z
	add_child(_spell_bar)
	_spell_bar.setup(model, self, [&"slow_field"])
	ticks_per_frame_scale = 0.0
	# This harness projects deterministic state directly. Do not run the parent
	# BattleView process loop, which now owns production battle-music playback.
	set_process(false)

	var shared := _shared_cells(_stage)
	if shared.is_empty():
		push_error("slow_field_visual_harness: S7 has no shared corridor")
		get_tree().quit(1)
		return
	var center: Vector2i = shared[shared.size() / 2]
	var desired_pan: Vector2 = (
		get_viewport_rect().size * 0.5
		- _map_nav.origin
		- IsoProjection.face_center(center) * _map_nav.scale
	)
	_map_nav.pan = IsoProjection.clamp_pan(desired_pan, _map_nav.bounds)
	_apply_map_transform()
	var enemy_ids: Array[StringName] = [&"grunt", &"heavy", &"runner"]
	for path_idx: int in mini(3, _stage.paths.size()):
		model._spawn({"enemy_id": enemy_ids[path_idx], "path_idx": path_idx})
		var enemy := model.enemies[-1] as EnemyState
		var path := model.path_for(path_idx)
		var cell_index := path.find(center)
		if cell_index >= 0:
			enemy.progress_units = cell_index * Pathing.PROGRESS_SCALE + path_idx * 170_000

	var mode := OS.get_environment("SLOW_FIELD_VISUAL_MODE")
	if mode == "tutorial":
		_tutorial = SlowFieldTutorial.new()
		_tutorial.name = "SlowFieldTutorial"
		add_child(_tutorial)
		_tutorial.call("setup", model, self, _spell_bar)
		await get_tree().process_frame
		var primary := _tutorial.find_child("SlowFieldTutorialPrimary", true, false) as Button
		if primary != null:
			primary.pressed.emit()
	else:
		if not model.apply_action([&"cast", &"slow_field", center]):
			push_error("slow_field_visual_harness: cast rejected")
			get_tree().quit(1)
			return
		model.tick = 60
		_spell_bar.call("_refresh_buttons")
	_project()
	_relayout()
	await get_tree().process_frame
	if mode != "tutorial":
		if _slow_field_rects.size() != 1:
			push_error("slow_field_visual_harness: active aura projection is missing")
			get_tree().quit(1)
			return
		var aura := _slow_field_rects.values()[0] as Control
		if aura == null or aura.modulate.a > 0.5:
			push_error("slow_field_visual_harness: active aura is not sufficiently transparent")
			get_tree().quit(1)
			return
		var rotation_before := aura.rotation
		await get_tree().create_timer(0.35).timeout
		if absf(aura.rotation - rotation_before) < 0.01:
			push_error("slow_field_visual_harness: active aura is not rotating")
			get_tree().quit(1)
			return
	await RenderingServer.frame_post_draw
	var capture_path := OS.get_environment("SLOW_FIELD_CAPTURE")
	if capture_path.is_empty():
		capture_path = "/tmp/slow-field-visual.png"
	var error := get_viewport().get_texture().get_image().save_png(capture_path)
	if error != OK:
		push_error("slow_field_visual_harness: screenshot failed %s" % error)
		get_tree().quit(1)
		return
	Sfx.stop_all()
	await get_tree().create_timer(0.5).timeout
	print("SLOW_FIELD_VISUAL_HARNESS_OK ", mode, " ", capture_path)
	get_tree().quit(0)


func _shared_cells(stage: StageDef) -> Array[Vector2i]:
	var owners := {}
	for path_idx: int in stage.paths.size():
		for cell: Vector2i in stage.path_cells(path_idx):
			owners[cell] = int(owners.get(cell, 0)) + 1
	var result: Array[Vector2i] = []
	for cell: Vector2i in owners:
		if int(owners[cell]) > 1:
			result.append(cell)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	return result
