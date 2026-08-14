extends SceneTree

const OUT_DEFAULT := "/tmp/mitigation_legacy_v1.json"
const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"
const RIGHT := int(UnitState.Facing.RIGHT)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path := OUT_DEFAULT if args.is_empty() else String(args[0])
	var rows: Array[Dictionary] = []
	rows.append(_operator_and_enemy_row())
	rows.append(_caster_splash_row())
	rows.append(_bolt_row())
	rows.append(_trap_row())
	rows.append(_charm_duel_row())
	var payload := {
		"schema": "td_mitigation_legacy_v1",
		"source_commit": "9767e3af419448e01f9ac2dd7a6317ee92d2cdd3",
		"rows": rows,
	}
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		push_error("TD-MITIGATION fixture open failed: %s" % out_path)
		quit(1)
		return
	file.store_string(CanonicalJson.text(payload))
	file.close()
	print("TD_MITIGATION_BASELINE_CAPTURE_PASS rows=%d sha256=%s" % [
		rows.size(), CanonicalJson.sha256_hex(payload),
	])
	quit()


func _operator_and_enemy_row() -> Dictionary:
	var stage := _stage([
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
	])
	var model := _model(stage, [&"vanguard_1"])
	var accepted := model.apply_action([
		&"deploy", &"vanguard_1", Vector2i(3, 2), RIGHT,
	])
	model.step(301)
	return {
		"case_id": "operator_and_enemy_basic_attacks",
		"deploy_accepted": accepted,
		"tick": model.tick,
		"enemy_hp": model.enemies[0].hp,
		"unit_hp": model.units[0].hp,
		"killed": model.killed,
		"model_hash": HeroIdentity.format_u64_hex(model.state_hash()),
	}


func _caster_splash_row() -> Dictionary:
	var stage := _stage([
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 90, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 150, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 400, "enemy_id": &"grunt", "path_idx": 0},
	])
	var wall := (load("res://data/operators/defender_1.tres") as OperatorDef).duplicate()
	wall.id = &"mitigation_wall"
	wall.atk = 0
	wall.hp = 9999
	wall.dp_cost = 0
	var model := _model(stage, [&"caster_1", &"mitigation_wall"], {wall.id: wall})
	var wall_ok := model.apply_action([
		&"deploy", wall.id, Vector2i(4, 2), RIGHT,
	])
	model.step(450)
	var caster_ok := model.apply_action([
		&"deploy", &"caster_1", Vector2i(2, 1), RIGHT,
	])
	model.step()
	return {
		"case_id": "caster_primary_and_splash",
		"deploys_accepted": wall_ok and caster_ok,
		"tick": model.tick,
		"enemy_hp": [
			model.enemies[0].hp, model.enemies[1].hp,
			model.enemies[2].hp, model.enemies[3].hp,
		],
		"model_hash": HeroIdentity.format_u64_hex(model.state_hash()),
	}


func _bolt_row() -> Dictionary:
	var stage := _stage([
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
	])
	var model := _model(stage, [], {}, {}, {
		&"bolt": load("res://data/spells/bolt.tres") as SpellDef,
	})
	model.step(100)
	var accepted := model.apply_action([&"cast", &"bolt", Vector2i(3, 2)])
	return {
		"case_id": "bolt_burst",
		"accepted": accepted,
		"tick": model.tick,
		"enemy_hp": model.enemies[0].hp,
		"killed": model.killed,
		"model_hash": HeroIdentity.format_u64_hex(model.state_hash()),
	}


func _trap_row() -> Dictionary:
	var stage := _stage([
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
	])
	var model := _model(stage, [], {}, {
		&"spike_plate": load("res://data/traps/spike_plate.tres") as TrapDef,
	})
	var accepted := model.apply_action([
		&"place_trap", &"spike_plate", Vector2i(4, 2),
	])
	model.step(122)
	return {
		"case_id": "trap_damage",
		"accepted": accepted,
		"tick": model.tick,
		"enemy_hp": model.enemies[0].hp,
		"traps_triggered": model.traps_triggered,
		"model_hash": HeroIdentity.format_u64_hex(model.state_hash()),
	}


func _charm_duel_row() -> Dictionary:
	var stage := _stage([
		{"tick": 0, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 60, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 100000, "enemy_id": &"grunt", "path_idx": 0},
	])
	var model := _model(stage, [], {}, {}, {
		&"charm": load("res://data/spells/charm.tres") as SpellDef,
	})
	model.step(100)
	var accepted := model.apply_action([&"cast", &"charm", 0])
	model.step(236 - model.tick)
	return {
		"case_id": "charm_duel_both_directions",
		"accepted": accepted,
		"tick": model.tick,
		"ally_hp": model.enemies[0].hp,
		"enemy_hp": model.enemies[1].hp,
		"enemy_alive": model.enemies[1].alive,
		"killed": model.killed,
		"charmed": model.charmed,
		"model_hash": HeroIdentity.format_u64_hex(model.state_hash()),
	}


func _stage(waves: Array[Dictionary]) -> StageDef:
	var stage := (load(STAGE_PATH) as StageDef).duplicate(true) as StageDef
	stage.waves = waves
	return stage


func _model(
	stage: StageDef,
	squad: Array[StringName],
	extra_ops: Dictionary = {},
	traps: Dictionary = {},
	spells: Dictionary = {},
) -> BattleModel:
	var enemy_defs := {
		&"grunt": load("res://data/enemies/grunt.tres") as EnemyDef,
		&"heavy": load("res://data/enemies/heavy.tres") as EnemyDef,
	}
	var operators: Dictionary = {}
	for op_id: StringName in squad:
		if extra_ops.has(op_id):
			operators[op_id] = extra_ops[op_id]
		else:
			operators[op_id] = load("res://data/operators/%s.tres" % op_id) as OperatorDef
	return BattleModel.create(
		stage, squad, 42, load(CONFIG_PATH) as GameConfig,
		enemy_defs, operators, traps, spells,
	)
