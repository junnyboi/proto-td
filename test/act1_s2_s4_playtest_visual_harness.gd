extends "res://scripts/view/battle_view.gd"

const WATCHDOG_SECONDS := 20.0
const TARGET_TICKS := {&"s2": 520, &"s3": 650, &"s4": 830}
const PLANS := {
	&"s2": {
		"queue": [&"vanguard_1", &"guard_1", &"caster_1", &"defender_1"],
		"placements": {
			&"vanguard_1": [Vector2i(3, 1), UnitState.Facing.RIGHT],
			&"guard_1": [Vector2i(4, 1), UnitState.Facing.RIGHT],
			&"defender_1": [Vector2i(4, 3), UnitState.Facing.LEFT],
			&"caster_1": [Vector2i(2, 0), UnitState.Facing.DOWN],
		},
		"traps": [],
	},
	&"s3": {
		"queue": [&"vanguard_1", &"guard_1", &"defender_1", &"caster_1"],
		"placements": {
			&"vanguard_1": [Vector2i(2, 1), UnitState.Facing.RIGHT],
			&"guard_1": [Vector2i(3, 2), UnitState.Facing.RIGHT],
			&"defender_1": [Vector2i(4, 3), UnitState.Facing.LEFT],
			&"caster_1": [Vector2i(5, 2), UnitState.Facing.DOWN],
		},
		"traps": [[&"spike_plate", Vector2i(3, 3)]],
	},
	&"s4": {
		"queue": [&"vanguard_1", &"sniper_1", &"guard_1", &"caster_1", &"defender_1"],
		"placements": {
			&"vanguard_1": [Vector2i(3, 4), UnitState.Facing.RIGHT],
			&"guard_1": [Vector2i(5, 4), UnitState.Facing.RIGHT],
			&"defender_1": [Vector2i(8, 3), UnitState.Facing.LEFT],
			&"sniper_1": [Vector2i(2, 2), UnitState.Facing.UP],
			&"caster_1": [Vector2i(8, 2), UnitState.Facing.LEFT],
		},
		"traps": [[&"tar_pit", Vector2i(7, 3)], [&"spike_plate", Vector2i(4, 4)]],
	},
}

var _finished := false
var _portrait_mode := false
var _source_grid_size := Vector2i.ZERO


func _ready() -> void:
	get_tree().create_timer(WATCHDOG_SECONDS).timeout.connect(_on_watchdog_timeout)
	var stage_id := StringName(OS.get_environment("ACT1_PLAYTEST_STAGE"))
	if not PLANS.has(stage_id):
		stage_id = &"s2"
	var source_stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
	_portrait_mode = get_viewport_rect().size.y > get_viewport_rect().size.x
	_source_grid_size = source_stage.grid_size()
	var theme_result := _resolve_stage_theme(source_stage)
	if not String(theme_result["error"]).is_empty():
		_fail("stage theme failed for %s" % stage_id)
		return
	_stage_theme = theme_result["theme"] as Resource
	_stage = source_stage.copy_for_viewport(get_viewport_rect().size)
	if _portrait_mode and _stage_theme != null:
		_stage_theme = _stage_theme.call("clockwise_rotated_copy", source_stage.grid_size())
	var config := load("res://data/config/game.tres") as GameConfig
	_enemy_defs = _load_enemy_defs(_stage)
	_op_defs = _load_catalog("res://data/operators", "OperatorDef")
	_trap_defs = _load_catalog("res://data/traps", "TrapDef")
	_spell_defs = _load_catalog("res://data/spells", "SpellDef")
	model = BattleModel.create(
		_stage,
		_stage.recovery_roster,
		16000 + int(_stage.campaign_index),
		config,
		_enemy_defs,
		_op_defs,
		_trap_defs,
		_spell_defs,
	)
	if model == null or not _build_grid(_stage):
		_fail("setup failed for %s" % stage_id)
		return
	cfg = load("res://data/juice_config.tres") as JuiceConfig
	_build_hud()
	_portrait_flash = ColorRect.new()
	_portrait_flash.name = "PortraitFlash"
	_portrait_flash.visible = false
	add_child(_portrait_flash)
	ticks_per_frame_scale = 0.0
	set_physics_process(false)
	set_process(false)
	_run_guided_plan(stage_id, int(TARGET_TICKS[stage_id]))
	_center_live_combat()
	_project()
	_relayout()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var capture_path := OS.get_environment("ACT1_PLAYTEST_CAPTURE")
	if capture_path.is_empty():
		capture_path = "/tmp/act1-playtest-%s.png" % stage_id
	var error := get_viewport().get_texture().get_image().save_png(capture_path)
	if error != OK:
		_fail("capture failed: %s" % error_string(error))
		return
	Sfx.stop_all()
	_finished = true
	print(
		"ACT1_S2_S4_PLAYTEST_VISUAL_OK|%s|tick=%d|alive=%d|leaked=%d|%s"
		% [stage_id, model.tick, model.alive_enemy_count(), model.leaked, capture_path]
	)
	get_tree().quit(0)


func _run_guided_plan(stage_id: StringName, target_tick: int) -> void:
	var plan: Dictionary = PLANS[stage_id]
	var queue: Array = (plan["queue"] as Array).duplicate()
	var trap_plan: Array = (plan["traps"] as Array).duplicate()
	var trap_index := 0
	while model.result == BattleModel.Result.RUNNING and model.tick < target_tick:
		if model.tick % 15 == 0:
			if not queue.is_empty():
				var op_id := StringName(queue[0])
				var placement: Array = plan["placements"][op_id]
				var cell := _rotated_cell(placement[0] as Vector2i)
				var facing := _rotated_facing(int(placement[1]))
				if model.apply_action([&"deploy", op_id, cell, facing]):
					queue.pop_front()
			for unit: UnitState in model.units:
				if unit.alive and unit.is_skill_ready():
					model.apply_action([&"trigger_skill", unit.id])
			if trap_index < trap_plan.size() and model.deployed_count() >= 3:
				var row: Array = trap_plan[trap_index]
				if model.apply_action([&"place_trap", row[0], _rotated_cell(row[1] as Vector2i)]):
					trap_index += 1
		model.step()


func _rotated_cell(cell: Vector2i) -> Vector2i:
	return StageDef.rotate_cell_clockwise(cell, _source_grid_size) if _portrait_mode else cell


func _rotated_facing(facing: int) -> int:
	return (facing + 1) % 4 if _portrait_mode else facing


func _center_live_combat() -> void:
	var world_positions: Array[Vector2] = []
	for enemy: EnemyState in model.enemies:
		if enemy.alive:
			world_positions.append(Pathing.position_of(model.path_for(enemy.path_idx), enemy.progress_units))
	for unit: UnitState in model.units:
		if unit.alive:
			world_positions.append(Vector2(unit.cell) + Vector2.ONE * 0.5)
	if world_positions.is_empty():
		return
	var projected_center := Vector2.ZERO
	for world_position: Vector2 in world_positions:
		projected_center += IsoProjection.project(world_position)
	projected_center /= float(world_positions.size())
	var desired_pan: Vector2 = (
		get_viewport_rect().size * 0.5 - _map_nav.origin - projected_center * _map_nav.scale
	)
	_map_nav.pan = IsoProjection.clamp_pan(desired_pan, _map_nav.bounds)
	_apply_map_transform()


func _on_watchdog_timeout() -> void:
	if not _finished:
		_fail("timed out waiting for rendered capture")


func _fail(message: String) -> void:
	push_error("act1_s2_s4_playtest_visual_harness: %s" % message)
	get_tree().quit(1)
