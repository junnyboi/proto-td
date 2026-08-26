extends Node

const BattleTicketRuntimeScript := preload("res://sim/battle_ticket_runtime.gd")
const UnitStateScript := preload("res://sim/unit_state.gd")

var _battle: Node2D = null
var _attack_mode := false


func _ready() -> void:
	Game.run_seed = 404
	Game.campaign_active = false
	Game.pending_stage = load("res://data/stages/s5.tres") as StageDef
	Game.default_squad = [&"guard_2"]
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var battle := packed.instantiate()
	add_child(battle)
	_battle = battle
	if not battle.startup_succeeded:
		push_error("reliquary_duelist_visual_harness: BattleView failed to start")
		return
	battle.ticks_per_frame_scale = 0.0
	battle._enemy_anim_seconds = 0.0
	_attack_mode = OS.get_environment("PREMIUM_VISUAL_STATE") == "attack"
	var cells: Array[Vector2i] = [Vector2i(4, 2), Vector2i(5, 2), Vector2i(7, 3), Vector2i(9, 4)]
	var facings: Array[int] = [
		UnitStateScript.Facing.RIGHT,
		UnitStateScript.Facing.DOWN,
		UnitStateScript.Facing.LEFT,
		UnitStateScript.Facing.UP,
	]
	var operator := battle._op_defs.get(&"guard_2") as OperatorDef
	if operator == null:
		push_error("reliquary_duelist_visual_harness: guard_2 is missing")
		return
	for index: int in cells.size():
		var unit := UnitStateScript.new()
		unit.id = 200 + index
		unit.hero_id = StringName("visual-duelist-%d" % index)
		unit.cell = cells[index]
		unit.facing = facings[index] as UnitState.Facing
		BattleTicketRuntimeScript.copy_legacy_unit(operator, unit)
		unit.portrait_asset_id = &"portrait_reliquary_duelist"
		unit.last_attack_tick = 0 if _attack_mode else -1
		battle.model.units.append(unit)
	battle.model.tick = 16 if _attack_mode else 0
	battle._project_units()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		_attack_mode = not _attack_mode
		_apply_animation_state()
		get_viewport().set_input_as_handled()


func _apply_animation_state() -> void:
	if _battle == null or _battle.model == null:
		return
	_battle.model.tick = 16 if _attack_mode else 0
	for unit: UnitState in _battle.model.units:
		unit.last_attack_tick = 0 if _attack_mode else -1
	_battle._project_units()
