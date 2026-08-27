extends SceneTree

const MAX_TICKS := 3600
const STAGES: Array[StringName] = [&"s2", &"s3", &"s4"]
const PROFILES := {
	"guided": {"response_ticks": 15, "queue_key": "guided_queue", "use_traps": true},
	"slow_polling": {"response_ticks": 60, "queue_key": "guided_queue", "use_traps": true},
	"counter_blind": {"response_ticks": 15, "queue_key": "blind_queue", "use_traps": false},
}
const PLANS := {
	&"s2": {
		"guided_queue": [&"vanguard_1", &"guard_1", &"caster_1", &"defender_1"],
		"blind_queue": [&"vanguard_1", &"guard_1", &"defender_1"],
		"placements": {
			&"vanguard_1": [Vector2i(3, 1), UnitState.Facing.RIGHT],
			&"guard_1": [Vector2i(4, 1), UnitState.Facing.RIGHT],
			&"defender_1": [Vector2i(4, 3), UnitState.Facing.LEFT],
			&"caster_1": [Vector2i(2, 0), UnitState.Facing.DOWN],
		},
		"traps": [],
		"trap_after": 99,
	},
	&"s3": {
		"guided_queue": [&"vanguard_1", &"guard_1", &"defender_1", &"caster_1"],
		"blind_queue": [&"vanguard_1", &"guard_1", &"caster_1"],
		"placements": {
			&"vanguard_1": [Vector2i(2, 1), UnitState.Facing.RIGHT],
			&"guard_1": [Vector2i(3, 2), UnitState.Facing.RIGHT],
			&"defender_1": [Vector2i(4, 3), UnitState.Facing.LEFT],
			&"caster_1": [Vector2i(5, 2), UnitState.Facing.DOWN],
		},
		"traps": [[&"spike_plate", Vector2i(3, 3)]],
		"trap_after": 3,
	},
	&"s4": {
		"guided_queue": [&"vanguard_1", &"sniper_1", &"guard_1", &"caster_1", &"defender_1"],
		"blind_queue": [&"vanguard_1", &"guard_1", &"caster_1", &"defender_1"],
		"placements": {
			&"vanguard_1": [Vector2i(3, 4), UnitState.Facing.RIGHT],
			&"guard_1": [Vector2i(5, 4), UnitState.Facing.RIGHT],
			&"defender_1": [Vector2i(8, 3), UnitState.Facing.LEFT],
			&"sniper_1": [Vector2i(2, 2), UnitState.Facing.UP],
			&"caster_1": [Vector2i(8, 2), UnitState.Facing.LEFT],
		},
		"traps": [[&"tar_pit", Vector2i(7, 3)], [&"spike_plate", Vector2i(4, 4)]],
		"trap_after": 3,
	},
}

var _rows: Array[Dictionary] = []
var _failures: Array[String] = []
var _s4_tuning_comparison: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for stage_id: StringName in STAGES:
		for profile_name: String in PROFILES:
			var first := _run_scenario(stage_id, profile_name, PROFILES[profile_name])
			var replay := _run_scenario(stage_id, profile_name, PROFILES[profile_name])
			_check(
				JSON.stringify(first) == JSON.stringify(replay),
				"nondeterministic S2-S4 playtest %s/%s" % [stage_id, profile_name],
			)
			_rows.append(first)
	var previous_s4 := _run_scenario(&"s4", "guided_previous_order", PROFILES["guided"], true)
	var final_s4 := _row(&"s4", "guided")
	_s4_tuning_comparison = {"previous_order": previous_s4, "interceptor_led": final_s4}
	_check(int(previous_s4["stars"]) == 3 and int(previous_s4["leaked"]) == 0, "S4 original pair order must reproduce its overly soft guided clear")
	_check(int(final_s4["stars"]) == 2 and int(final_s4["leaked"]) == 2, "S4 Interceptor-led pairs must produce the intended fair two-star step")
	_check(
		int(final_s4["pressure_auc"]) > int(previous_s4["pressure_auc"]),
		"S4 Interceptor-led pairs must increase guided sustained pressure",
	)
	_assert_progression()
	_write_outputs()
	if _failures.is_empty():
		print("ACT1_S2_S4_BALANCE_PLAYTEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _assert_progression() -> void:
	var indexed: Dictionary = {}
	for row: Dictionary in _rows:
		indexed["%s/%s" % [row["stage"], row["profile"]]] = row
	for stage_id: String in ["s2", "s3", "s4"]:
		_check(String(indexed["%s/guided" % stage_id]["result"]) == "clear", "%s guided policy must clear" % stage_id)
		_check(String(indexed["%s/slow_polling" % stage_id]["result"]) == "clear", "%s slow-polling policy must remain recoverable" % stage_id)
	_check(int(indexed["s2/guided"]["stars"]) == 3, "S2 guided play must teach counters without forced leaks")
	_check(int(indexed["s3/guided"]["stars"]) == 2, "S3 guided play must introduce a controlled one-leak step")
	_check(int(indexed["s4/guided"]["stars"]) == 2, "S4 guided play must remain a fair two-star anti-air test")
	_check(int(indexed["s4/slow_polling"]["stars"]) == 1, "S4 two-second decision polling must expose the closing air-pair pressure")
	_check(String(indexed["s3/counter_blind"]["result"]) == "defeat", "S3 must punish omitting the Defender-and-Spike-Plate counter package")
	_check(String(indexed["s4/counter_blind"]["result"]) == "defeat", "S4 must punish omitting the Sniper-and-trap counter package")
	_check(String(indexed["s2/counter_blind"]["result"]) == "clear", "S2 counter-blind play must remain recoverable")
	_check(
		int(indexed["s2/counter_blind"]["post_spawn_cleanup_ticks"])
		> int(indexed["s2/guided"]["post_spawn_cleanup_ticks"]) * 2,
		"S2 Caster omission must create a clear efficiency penalty instead of a hard fail",
	)
	_check(
		int(indexed["s2/guided"]["terminal_tick"]) < int(indexed["s3/guided"]["terminal_tick"])
		and int(indexed["s3/guided"]["terminal_tick"]) <= int(indexed["s4/guided"]["terminal_tick"]),
		"guided S2-S4 encounter duration must not regress downward",
	)


func _run_scenario(
	stage_id: StringName,
	profile_name: String,
	profile: Dictionary,
	restore_previous_s4_order := false,
) -> Dictionary:
	var stage := (load("res://data/stages/%s.tres" % stage_id) as StageDef).duplicate(true) as StageDef
	if restore_previous_s4_order:
		_restore_previous_s4_order(stage)
	var config := (load("res://data/config/game.tres") as GameConfig).duplicate(true) as GameConfig
	var model := BattleModel.create(
		stage,
		stage.recovery_roster,
		15000 + stage.campaign_index,
		config,
		_load_catalog("res://data/enemies"),
		_load_catalog("res://data/operators"),
		_load_catalog("res://data/traps"),
		{},
	)
	_check(model != null, "%s/%s model must create" % [stage_id, profile_name])
	if model == null:
		return {}
	var plan: Dictionary = PLANS[stage_id]
	var queue: Array = (plan[String(profile["queue_key"])] as Array).duplicate()
	var trap_plan: Array = (plan["traps"] as Array).duplicate()
	var trap_index := 0
	var action_counts := {"deploy": 0, "skill": 0, "trap": 0}
	var deploy_ticks: Dictionary = {}
	var unit_falls := 0
	var known_dead: Dictionary = {}
	var max_alive := 0
	var max_weighted_pressure := 0
	var pressure_auc := 0
	var unit_damage_taken := 0
	var hp_before: Dictionary = {}
	var response_ticks := int(profile["response_ticks"])
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		max_alive = maxi(max_alive, model.alive_enemy_count())
		var pressure := _weighted_pressure(model)
		max_weighted_pressure = maxi(max_weighted_pressure, pressure)
		pressure_auc += pressure
		for unit: UnitState in model.units:
			hp_before[unit.id] = unit.hp
		if model.tick % response_ticks == 0:
			_deploy_next(model, queue, plan, action_counts, deploy_ticks)
			_trigger_ready_skills(model, action_counts)
			if bool(profile["use_traps"]):
				trap_index = _place_next_trap(model, trap_plan, trap_index, int(plan["trap_after"]), action_counts)
		model.step()
		for unit: UnitState in model.units:
			if hp_before.has(unit.id) and unit.hp < int(hp_before[unit.id]):
				unit_damage_taken += int(hp_before[unit.id]) - unit.hp
			if not unit.alive and not known_dead.has(unit.id):
				known_dead[unit.id] = true
				unit_falls += 1
	_check(model.result != BattleModel.Result.RUNNING, "%s/%s must reach a terminal state" % [stage_id, profile_name])
	var last_spawn_tick := 0
	for spawn: Dictionary in stage.waves:
		last_spawn_tick = maxi(last_spawn_tick, int(spawn["tick"]))
	return {
		"stage": String(stage_id),
		"profile": profile_name,
		"result": "clear" if model.result == BattleModel.Result.CLEAR else "defeat",
		"stars": model.stars,
		"terminal_tick": model.tick,
		"duration_seconds": snappedf(float(model.tick) / float(config.ticks_per_second), 0.1),
		"post_spawn_cleanup_ticks": model.tick - last_spawn_tick,
		"spawned": model.spawned,
		"killed": model.killed,
		"leaked": model.leaked,
		"base_hp": model.base_hp,
		"max_alive": max_alive,
		"max_weighted_pressure": max_weighted_pressure,
		"pressure_auc": pressure_auc,
		"unit_falls": unit_falls,
		"unit_damage_taken": unit_damage_taken,
		"deployed": model.deployed_count(),
		"remaining_queue": queue.size(),
		"dp_spent": model.dp_spent,
		"deploy_ticks": deploy_ticks,
		"actions": action_counts,
	}


func _deploy_next(
	model: BattleModel,
	queue: Array,
	plan: Dictionary,
	counts: Dictionary,
	deploy_ticks: Dictionary,
) -> void:
	if queue.is_empty():
		return
	var op_id := StringName(queue[0])
	var placement: Array = plan["placements"][op_id]
	if model.apply_action([&"deploy", op_id, placement[0], placement[1]]):
		queue.pop_front()
		counts["deploy"] = int(counts["deploy"]) + 1
		deploy_ticks[String(op_id)] = model.tick


func _trigger_ready_skills(model: BattleModel, counts: Dictionary) -> void:
	for unit: UnitState in model.units:
		if unit.alive and unit.is_skill_ready() and model.apply_action([&"trigger_skill", unit.id]):
			counts["skill"] = int(counts["skill"]) + 1


func _place_next_trap(
	model: BattleModel,
	plan: Array,
	index: int,
	minimum_deployed: int,
	counts: Dictionary,
) -> int:
	if index >= plan.size() or model.deployed_count() < minimum_deployed:
		return index
	var row: Array = plan[index]
	if model.apply_action([&"place_trap", row[0], row[1]]):
		counts["trap"] = int(counts["trap"]) + 1
		return index + 1
	return index


func _weighted_pressure(model: BattleModel) -> int:
	var total := 0
	for enemy: EnemyState in model.enemies:
		if enemy.alive and enemy.faction == EnemyState.Faction.ENEMY:
			total += maxi(enemy.block_weight, 1)
	return total


func _restore_previous_s4_order(stage: StageDef) -> void:
	var previous := {510: &"drone", 540: &"interceptor", 750: &"drone", 810: &"interceptor"}
	for spawn: Dictionary in stage.waves:
		var tick := int(spawn.get("tick", -1))
		if previous.has(tick):
			spawn["enemy_id"] = previous[tick]


func _row(stage_id: StringName, profile_name: String) -> Dictionary:
	for row: Dictionary in _rows:
		if StringName(row["stage"]) == stage_id and String(row["profile"]) == profile_name:
			return row
	return {}


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
	var path := OS.get_environment("ACT1_S2_S4_PLAYTEST_JSON")
	if path.is_empty():
		path = "/tmp/act1-s2-s4-balance-playtest.json"
	var payload := {
		"schema": "protos_act1_s2_s4_balance_playtest_v1",
		"ticks_per_second": 30,
		"policy": "Attempt queued authored recovery-roster deployments from DP income at deterministic teaching cells until terminal, auto-trigger ready skills, and use only traps unlocked before that stage.",
		"profiles": PROFILES,
		"s4_tuning_comparison": _s4_tuning_comparison,
		"rows": _rows,
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write playtest JSON: %s" % path)
		return
	file.store_string(JSON.stringify(payload, "  "))


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
