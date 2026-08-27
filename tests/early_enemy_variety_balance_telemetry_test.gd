extends SceneTree

const MAX_TICKS := 5000
const STAGES: Array[StringName] = [&"s2", &"s3", &"s4"]
const BASELINE_IDS := {
	&"shieldbearer": &"grunt",
	&"breacher": &"grunt",
	&"interceptor": &"drone",
}
const DEPLOYMENTS := {
	&"s2": [
		[&"vanguard_1", Vector2i(3, 1), UnitState.Facing.RIGHT],
		[&"guard_1", Vector2i(4, 1), UnitState.Facing.RIGHT],
		[&"defender_1", Vector2i(4, 3), UnitState.Facing.LEFT],
		[&"caster_1", Vector2i(2, 0), UnitState.Facing.DOWN],
	],
	&"s3": [
		[&"vanguard_1", Vector2i(2, 1), UnitState.Facing.RIGHT],
		[&"guard_1", Vector2i(3, 2), UnitState.Facing.RIGHT],
		[&"defender_1", Vector2i(4, 3), UnitState.Facing.LEFT],
		[&"caster_1", Vector2i(5, 2), UnitState.Facing.DOWN],
	],
	&"s4": [
		[&"vanguard_1", Vector2i(3, 4), UnitState.Facing.RIGHT],
		[&"guard_1", Vector2i(5, 4), UnitState.Facing.RIGHT],
		[&"defender_1", Vector2i(8, 1), UnitState.Facing.LEFT],
		[&"sniper_1", Vector2i(2, 2), UnitState.Facing.UP],
		[&"caster_1", Vector2i(8, 2), UnitState.Facing.LEFT],
	],
}

var _failures := PackedStringArray()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var paired: Dictionary = {}
	for stage_id: StringName in STAGES:
		var baseline := _run_scenario(stage_id, true)
		var candidate := _run_scenario(stage_id, false)
		var replay := _run_scenario(stage_id, false)
		paired[stage_id] = {"baseline": baseline, "candidate": candidate}
		_check(not baseline.is_empty() and not candidate.is_empty(), "%s telemetry scenario must complete" % stage_id)
		_check(JSON.stringify(candidate) == JSON.stringify(replay), "%s candidate telemetry must be deterministic" % stage_id)
		if baseline.is_empty() or candidate.is_empty():
			continue
		_check(int(candidate["spawned"]) == int(baseline["spawned"]), "%s must preserve spawn total" % stage_id)
		_check(int(candidate["result"]) == BattleModel.Result.CLEAR, "%s candidate scripted scenario must resolve" % stage_id)
		_check(int(candidate["leaked"]) <= int(baseline["leaked"]) + 1, "%s candidate may add at most one scripted-scenario leak" % stage_id)
		_check(int(candidate["terminal_tick"]) <= ceili(float(baseline["terminal_tick"]) * 1.35), "%s candidate terminal time must stay within 35%% of baseline" % stage_id)
		_check(int(candidate["peak_pressure"]) <= maxi(1, ceili(float(baseline["peak_pressure"]) * 1.35)), "%s candidate peak pressure must stay within 35%% of baseline" % stage_id)
	if paired.has(&"s3"):
		_check(int((paired[&"s3"] as Dictionary)["candidate"]["peak_blocked_weight"]) >= 2, "S3 Breacher scenario must exert at least two blocked weight")
	var payload := {
		"schema": "protos_early_enemy_variety_balance_v1",
		"ticks_per_second": 30,
		"policy": "Deploy the full recovery roster immediately at deterministic authored cells, auto-trigger ready skills, and raise HP/leak limits only so every spawn resolves.",
		"baseline": "Replace Shieldbearer/Breacher/Interceptor with their original Grunt/Grunt/Drone counterparts and restore Caster basic attacks to Physical.",
		"stages": paired,
	}
	_write_json(payload)
	if _failures.is_empty():
		print("EARLY_ENEMY_VARIETY_BALANCE_TELEMETRY_OK")
		print(JSON.stringify(payload))
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _run_scenario(stage_id: StringName, baseline: bool) -> Dictionary:
	var source := load("res://data/stages/%s.tres" % stage_id) as StageDef
	if source == null:
		return {}
	var stage := source.duplicate(true) as StageDef
	stage.leak_limit = 999
	if baseline:
		for spawn: Dictionary in stage.waves:
			var enemy_id := StringName(spawn.get("enemy_id", &""))
			if BASELINE_IDS.has(enemy_id):
				spawn["enemy_id"] = BASELINE_IDS[enemy_id]
	var config := (load("res://data/config/game.tres") as GameConfig).duplicate(true) as GameConfig
	config.base_hp_start = 999
	var enemy_defs := _load_catalog("res://data/enemies")
	var operator_defs := _load_catalog("res://data/operators")
	if baseline:
		for caster_id: StringName in [&"caster_1", &"caster_2"]:
			var caster := (operator_defs[caster_id] as OperatorDef).duplicate(true) as OperatorDef
			caster.attack_damage_kind = 0
			operator_defs[caster_id] = caster
	var model := BattleModel.create(
		stage,
		stage.recovery_roster,
		9400 + int(stage.campaign_index),
		config,
		enemy_defs,
		operator_defs,
	)
	if model == null:
		return {}
	model.dp = config.dp_cap
	for row: Array in DEPLOYMENTS[stage_id]:
		var deployed := model.apply_action([&"deploy", row[0], row[1], row[2]])
		if not deployed:
			_failures.append("%s failed scripted deployment for %s" % [stage_id, row[0]])
	var pressure_auc := 0
	var peak_pressure := 0
	var max_alive := 0
	var peak_blocked_weight := 0
	var seen: Dictionary = {}
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		for unit: UnitState in model.units:
			if unit.alive and unit.is_skill_ready():
				model.apply_action([&"trigger_skill", unit.id])
		var observation := BattleObservation.from_model(model).to_dictionary()
		var pressure := 0
		for lane: Dictionary in observation["paths"]:
			pressure += int(lane["pressure"])
		pressure_auc += pressure
		peak_pressure = maxi(peak_pressure, pressure)
		max_alive = maxi(max_alive, model.alive_enemy_count())
		for row: Dictionary in observation["operators"]:
			peak_blocked_weight = maxi(peak_blocked_weight, int(row["blocked_weight"]))
		for enemy: EnemyState in model.enemies:
			seen[String(enemy.def_id)] = true
		model.step()
	if model.result == BattleModel.Result.RUNNING:
		_failures.append("%s scenario exceeded %d ticks" % [stage_id, MAX_TICKS])
		return {}
	var seen_ids: Array = seen.keys()
	seen_ids.sort()
	return {
		"result": model.result,
		"terminal_tick": model.tick,
		"base_hp": model.base_hp,
		"spawned": model.spawned,
		"killed": model.killed,
		"leaked": model.leaked,
		"pressure_auc": pressure_auc,
		"peak_pressure": peak_pressure,
		"max_alive": max_alive,
		"peak_blocked_weight": peak_blocked_weight,
		"seen_enemy_ids": seen_ids,
	}


func _load_catalog(path: String) -> Dictionary:
	var result: Dictionary = {}
	for filename: String in DirAccess.get_files_at(path):
		if not filename.ends_with(".tres"):
			continue
		var resource := load("%s/%s" % [path, filename])
		if resource != null and "id" in resource:
			result[resource.id] = resource
	return result


func _write_json(payload: Dictionary) -> void:
	var path := OS.get_environment("EARLY_ENEMY_VARIETY_TELEMETRY_JSON")
	if path.is_empty():
		path = "/tmp/early-enemy-variety-balance-telemetry.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write telemetry JSON: %s" % path)
		return
	file.store_string(JSON.stringify(payload, "  "))


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
