extends SceneTree

const MAX_TICKS := 6000
const STAGE_IDS: Array[StringName] = [&"s9", &"s12", &"s16"]
const SQUAD: Array[StringName] = [
	&"vanguard_1", &"guard_2", &"defender_2", &"sniper_1", &"caster_2", &"witch_doctor_1",
]
const PROFILES := {
	"field": {
		"operators": [&"vanguard_1", &"sniper_1", &"defender_2", &"caster_2"],
		"use_traps": false,
		"use_spells": false,
		"response_ticks": 30,
	},
	"standard": {
		"operators": SQUAD,
		"use_traps": true,
		"use_spells": true,
		"response_ticks": 15,
	},
	"rapid": {
		"operators": SQUAD,
		"use_traps": true,
		"use_spells": true,
		"response_ticks": 5,
	},
}

var _rows: Array[Dictionary] = []
var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for stage_id: StringName in STAGE_IDS:
		for profile_name: String in PROFILES:
			var first := _run_scenario(stage_id, profile_name, PROFILES[profile_name])
			var replay := _run_scenario(stage_id, profile_name, PROFILES[profile_name])
			_check(
				JSON.stringify(first) == JSON.stringify(replay),
				"nondeterministic playtest %s/%s" % [stage_id, profile_name],
			)
			_rows.append(first)
	_assert_balance_envelopes()
	_write_outputs()
	if _failures.is_empty():
		print("ACT2_BALANCE_PLAYTEST_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _assert_balance_envelopes() -> void:
	var indexed: Dictionary = {}
	for row: Dictionary in _rows:
		indexed["%s/%s" % [row["stage"], row["profile"]]] = row
	for key: String in [
		"s9/standard", "s12/standard", "s16/standard",
		"s9/rapid", "s12/rapid", "s16/rapid",
	]:
		_check(String(indexed[key]["result"]) == "clear", "%s no longer clears" % key)
	_check(String(indexed["s9/field"]["result"]) == "clear", "S9 field policy should clear")
	_check(String(indexed["s12/field"]["result"]) == "clear", "S12 field policy should clear")
	_check(String(indexed["s16/field"]["result"]) == "defeat", "S16 field policy should expose boss-level failure")
	_check(int(indexed["s9/standard"]["stars"]) == 3, "S9 standard policy should earn three stars")
	_check(int(indexed["s12/standard"]["stars"]) >= 2, "S12 standard policy should earn at least two stars")
	_check(int(indexed["s16/standard"]["stars"]) == 2, "S16 standard policy should earn two stars")
	_check(_inside(float(indexed["s9/standard"]["duration_seconds"]), 45.0, 70.0), "S9 duration left its target band")
	_check(_inside(float(indexed["s12/standard"]["duration_seconds"]), 60.0, 90.0), "S12 duration left its target band")
	_check(_inside(float(indexed["s16/standard"]["duration_seconds"]), 90.0, 125.0), "S16 duration left its target band")
	_check(int(indexed["s12/standard"]["restoration_healing"]) < int(indexed["s12/field"]["restoration_healing"]), "S12 Slow Field did not suppress restoration")
	_check(int(indexed["s16/standard"]["restoration_healing"]) < int(indexed["s16/field"]["restoration_healing"]), "S16 Slow Field did not suppress restoration")


func _inside(value: float, lower: float, upper: float) -> bool:
	return value >= lower and value <= upper


func _run_scenario(stage_id: StringName, profile_name: String, profile: Dictionary) -> Dictionary:
	var stage := (load("res://data/stages/%s.tres" % stage_id) as StageDef).duplicate(true) as StageDef
	var config := (load("res://data/config/game.tres") as GameConfig).duplicate(true) as GameConfig
	var enemy_defs := _load_catalog("res://data/enemies")
	var op_defs := _load_catalog("res://data/operators")
	var trap_defs := _load_catalog("res://data/traps")
	var spell_defs := _load_catalog("res://data/spells")
	var model := BattleModel.create(stage, SQUAD, 8200 + stage.campaign_index, config, enemy_defs, op_defs, trap_defs, spell_defs)
	var plan := _placement_plan(stage, op_defs)
	var queue: Array = (profile["operators"] as Array).duplicate()
	var action_counts := {"deploy": 0, "skill": 0, "mend": 0, "trap": 0, "slow": 0, "bolt": 0, "charm": 0}
	var trap_plan: Array = _trap_plan(stage)
	var trap_index := 0
	var max_alive := 0
	var max_pressure := 0
	var unit_falls := 0
	var known_dead_units: Dictionary = {}
	var restoration_healing := 0
	var enemy_hp_before: Dictionary = {}
	var response_ticks := int(profile["response_ticks"])
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		max_alive = maxi(max_alive, model.alive_enemy_count())
		max_pressure = maxi(max_pressure, _weighted_pressure(model))
		for enemy: EnemyState in model.enemies:
			enemy_hp_before[enemy.id] = enemy.hp
		if model.tick % response_ticks == 0:
			_deploy_next(model, queue, plan, action_counts)
			_trigger_ready_skills(model, action_counts)
			_heal_ready_units(model, action_counts)
			if bool(profile["use_traps"]):
				trap_index = _place_next_trap(model, trap_plan, trap_index, action_counts)
			if bool(profile["use_spells"]):
				_cast_policy(model, stage, profile_name, action_counts)
		model.step()
		for enemy: EnemyState in model.enemies:
			if enemy_hp_before.has(enemy.id) and enemy.hp > int(enemy_hp_before[enemy.id]):
				restoration_healing += enemy.hp - int(enemy_hp_before[enemy.id])
		for unit: UnitState in model.units:
			if not unit.alive and not known_dead_units.has(unit.id):
				known_dead_units[unit.id] = true
				unit_falls += 1
	return {
		"stage": String(stage_id),
		"profile": profile_name,
		"result": "clear" if model.result == BattleModel.Result.CLEAR else "defeat",
		"stars": model.stars,
		"terminal_tick": model.tick,
		"duration_seconds": snappedf(float(model.tick) / float(config.ticks_per_second), 0.1),
		"spawned": model.spawned,
		"killed": model.killed,
		"charmed": model.charmed,
		"charmed_exited": model.charmed_exited,
		"leaked": model.leaked,
		"base_hp": model.base_hp,
		"max_alive": max_alive,
		"max_weighted_pressure": max_pressure,
		"unit_falls": unit_falls,
		"deployed": model.units.size(),
		"dp_spent": model.dp_spent,
		"restoration_healing": restoration_healing,
		"actions": action_counts,
	}


func _deploy_next(model: BattleModel, queue: Array, plan: Dictionary, counts: Dictionary) -> void:
	if queue.is_empty():
		return
	var op_id := StringName(queue[0])
	if not model.is_deployable(op_id):
		return
	var placement: Dictionary = plan.get(op_id, {})
	if placement.is_empty():
		queue.pop_front()
		return
	if model.apply_action([&"deploy", op_id, placement["cell"], placement["facing"]]):
		queue.pop_front()
		counts["deploy"] = int(counts["deploy"]) + 1


func _trigger_ready_skills(model: BattleModel, counts: Dictionary) -> void:
	for unit: UnitState in model.units:
		if unit.is_skill_ready() and unit.skill_effect != SkillDef.Effect.HEAL_TARGET:
			if model.apply_action([&"trigger_skill", unit.id]):
				counts["skill"] = int(counts["skill"]) + 1


func _heal_ready_units(model: BattleModel, counts: Dictionary) -> void:
	for healer: UnitState in model.units:
		if not healer.is_skill_ready() or healer.skill_effect != SkillDef.Effect.HEAL_TARGET:
			continue
		var target: UnitState = null
		for unit: UnitState in model.units:
			if not unit.alive or unit.hp >= unit.hp_max:
				continue
			if target == null or float(unit.hp) / unit.hp_max < float(target.hp) / target.hp_max:
				target = unit
		if target != null and model.apply_action([&"mend", healer.id, target.id]):
			counts["mend"] = int(counts["mend"]) + 1


func _place_next_trap(model: BattleModel, plan: Array, index: int, counts: Dictionary) -> int:
	if index >= plan.size() or model.deployed_count() < 3:
		return index
	var row: Dictionary = plan[index]
	if model.can_place_trap_at(row["id"], row["cell"]):
		if model.apply_action([&"place_trap", row["id"], row["cell"]]):
			counts["trap"] = int(counts["trap"]) + 1
			return index + 1
	return index


func _cast_policy(model: BattleModel, stage: StageDef, profile_name: String, counts: Dictionary) -> void:
	if model.is_castable(&"charm"):
		var target := _best_charm_target(model)
		if target >= 0 and model.apply_action([&"cast", &"charm", target]):
			counts["charm"] = int(counts["charm"]) + 1
	if model.is_castable(&"slow_field"):
		var slow_target := _best_area_target(model, stage, true)
		var slow_threshold := 2
		if int(slow_target["count"]) >= slow_threshold:
			if model.apply_action([&"cast", &"slow_field", slow_target["cell"]]):
				counts["slow"] = int(counts["slow"]) + 1
	if model.is_castable(&"bolt"):
		var bolt_target := _best_area_target(model, stage, false)
		var bolt_threshold := 2
		if int(bolt_target["count"]) >= bolt_threshold:
			if model.apply_action([&"cast", &"bolt", bolt_target["cell"]]):
				counts["bolt"] = int(counts["bolt"]) + 1


func _best_charm_target(model: BattleModel) -> int:
	var best_id := -1
	var best_score := -1
	for enemy: EnemyState in model.enemies:
		if not enemy.alive or enemy.aerial or enemy.faction != EnemyState.Faction.ENEMY or enemy.charm_immune:
			continue
		var score := enemy.hp * 10 + enemy.progress_units
		if score > best_score:
			best_score = score
			best_id = enemy.id
	return best_id


func _best_area_target(model: BattleModel, stage: StageDef, restoration_only: bool) -> Dictionary:
	var candidates: Array[Vector2i] = []
	if restoration_only:
		for point: Vector2 in stage.restoration_cells:
			candidates.append(Vector2i(point))
	else:
		for y: int in stage.grid_size().y:
			for x: int in stage.grid_size().x:
				candidates.append(Vector2i(x, y))
	var best := {"cell": Vector2i.ZERO, "count": 0, "score": -1}
	for cell: Vector2i in candidates:
		var count := 0
		var hp_score := 0
		for enemy: EnemyState in model.enemies:
			if not enemy.alive or enemy.faction != EnemyState.Faction.ENEMY:
				continue
			if restoration_only and enemy.aerial:
				continue
			var enemy_cell := Pathing.cell_of(model.path_for(enemy.path_idx), enemy.progress_units)
			if maxi(absi(enemy_cell.x - cell.x), absi(enemy_cell.y - cell.y)) <= 1:
				count += 1
				hp_score += enemy.hp
		var score := count * 10000 + hp_score
		if score > int(best["score"]):
			best = {"cell": cell, "count": count, "score": score}
	return best


func _weighted_pressure(model: BattleModel) -> int:
	var total := 0
	for enemy: EnemyState in model.enemies:
		if not enemy.alive or enemy.faction != EnemyState.Faction.ENEMY:
			continue
		total += enemy.block_weight + (1 if enemy.aerial else 0)
	return total


func _placement_plan(stage: StageDef, op_defs: Dictionary) -> Dictionary:
	var used: Dictionary = {}
	var plan: Dictionary = {}
	var ground_targets := {
		&"vanguard_1": 0.52,
		&"guard_2": 0.68,
		&"defender_2": 0.80,
	}
	for op_id: StringName in [&"vanguard_1", &"guard_2", &"defender_2"]:
		var cell := _best_ground_cell(stage, float(ground_targets[op_id]), used)
		used[cell] = true
		plan[op_id] = {"cell": cell, "facing": int(UnitState.Facing.RIGHT)}
	for op_id: StringName in [&"sniper_1", &"caster_2"]:
		var placement := _best_ranged_placement(stage, op_defs[op_id], used)
		used[placement["cell"]] = true
		plan[op_id] = placement
	plan[&"witch_doctor_1"] = _best_healer_placement(stage, used, plan)
	return plan


func _best_ground_cell(stage: StageDef, target_fraction: float, used: Dictionary) -> Vector2i:
	var best := Vector2i.ZERO
	var best_score := -INF
	for y: int in stage.grid_size().y:
		for x: int in stage.grid_size().x:
			var cell := Vector2i(x, y)
			if stage.tile_at(cell) != StageDef.Tile.GROUND or used.has(cell):
				continue
			var membership := 0
			var progress_total := 0.0
			for path_index: int in stage.paths.size():
				var cells := stage.path_cells(path_index)
				var at := cells.find(cell)
				if at >= 0:
					membership += 1
					progress_total += float(at) / maxf(float(cells.size() - 1), 1.0)
			if membership <= 0:
				continue
			var progress := progress_total / membership
			var score := float(membership) * 1000.0 - absf(progress - target_fraction) * 500.0
			if score > best_score:
				best_score = score
				best = cell
	return best


func _best_ranged_placement(stage: StageDef, op_def: OperatorDef, used: Dictionary) -> Dictionary:
	var best := {"cell": Vector2i.ZERO, "facing": int(UnitState.Facing.RIGHT), "score": -INF}
	for y: int in stage.grid_size().y:
		for x: int in stage.grid_size().x:
			var cell := Vector2i(x, y)
			if stage.tile_at(cell) != StageDef.Tile.ELEVATED or used.has(cell):
				continue
			for facing: int in range(4):
				var covered := Targeting.range_cells(cell, op_def.range_offsets, facing)
				var score := 0.0
				for path_index: int in stage.paths.size():
					var cells := stage.path_cells(path_index)
					for index: int in cells.size():
						if covered.has(cells[index]):
							score += 1.0 + 2.0 * float(index) / maxf(float(cells.size() - 1), 1.0)
				if score > float(best["score"]):
					best = {"cell": cell, "facing": facing, "score": score}
	return best


func _best_healer_placement(stage: StageDef, used: Dictionary, plan: Dictionary) -> Dictionary:
	var best := {"cell": Vector2i.ZERO, "facing": int(UnitState.Facing.RIGHT), "score": -INF}
	for y: int in stage.grid_size().y:
		for x: int in stage.grid_size().x:
			var cell := Vector2i(x, y)
			if stage.tile_at(cell) != StageDef.Tile.ELEVATED or used.has(cell):
				continue
			var score := 0.0
			for op_id: StringName in [&"vanguard_1", &"guard_2", &"defender_2"]:
				var ground: Vector2i = plan[op_id]["cell"]
				var distance := maxi(absi(cell.x - ground.x), absi(cell.y - ground.y))
				if distance <= 2:
					score += 10.0 - distance
			if score > float(best["score"]):
				best = {"cell": cell, "facing": int(UnitState.Facing.RIGHT), "score": score}
	return best


func _trap_plan(stage: StageDef) -> Array:
	var used: Dictionary = {}
	var late := _best_ground_cell(stage, 0.62, used)
	used[late] = true
	var later := _best_ground_cell(stage, 0.72, used)
	return [
		{"id": &"tar_pit", "cell": late},
		{"id": &"spike_plate", "cell": later},
	]


func _load_catalog(path: String) -> Dictionary:
	var result: Dictionary = {}
	for filename: String in DirAccess.get_files_at(path):
		if not filename.ends_with(".tres"):
			continue
		var resource := load("%s/%s" % [path, filename])
		if resource != null and "id" in resource:
			result[resource.id] = resource
	return result


func _write_outputs() -> void:
	var json_path := OS.get_environment("ACT2_BALANCE_JSON")
	if json_path.is_empty():
		json_path = "/tmp/act2-balance-playtest.json"
	var json_file := FileAccess.open(json_path, FileAccess.WRITE)
	json_file.store_string(JSON.stringify({"schema": "protos_act2_balance_playtest_v1", "rows": _rows}, "  "))
	var csv_path := OS.get_environment("ACT2_BALANCE_CSV")
	if csv_path.is_empty():
		csv_path = "/tmp/act2-balance-playtest.csv"
	var csv_file := FileAccess.open(csv_path, FileAccess.WRITE)
	var columns := ["stage", "profile", "result", "stars", "terminal_tick", "duration_seconds", "spawned", "killed", "charmed", "leaked", "base_hp", "max_alive", "max_weighted_pressure", "unit_falls", "deployed", "dp_spent", "restoration_healing"]
	csv_file.store_csv_line(columns)
	for row: Dictionary in _rows:
		var values := PackedStringArray()
		for column: String in columns:
			values.append(str(row[column]))
		csv_file.store_csv_line(values)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
