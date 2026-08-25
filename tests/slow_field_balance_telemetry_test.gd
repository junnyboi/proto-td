extends SceneTree

const MAX_TICKS := 5000
const SPELL_ID := &"slow_field"

var _failures: Array[String] = []
var _rows: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stages: Array[StringName] = [&"s7", &"s8"]
	var paired: Dictionary = {}
	for stage_id: StringName in stages:
		var baseline := _run_scenario(stage_id, false)
		var with_field := _run_scenario(stage_id, true)
		var replay := _run_scenario(stage_id, true)
		paired[stage_id] = {"baseline": baseline, "slow_field": with_field}
		_check(not baseline.is_empty(), "%s baseline telemetry failed" % stage_id)
		_check(not with_field.is_empty(), "%s Slow Field telemetry failed" % stage_id)
		_check(
			JSON.stringify(with_field) == JSON.stringify(replay),
			"%s Slow Field telemetry is not deterministic" % stage_id,
		)
		if baseline.is_empty() or with_field.is_empty():
			continue
		_check(int(with_field["casts"]) >= 1, "%s convergence policy never cast" % stage_id)
		_check(
			int(with_field["ground_affected"]) >= 1,
			"%s Slow Field never affected a ground enemy" % stage_id,
		)
		_check(
			float(with_field["mean_ground_transit_ticks"])
			> float(baseline["mean_ground_transit_ticks"]),
			"%s Slow Field did not increase ground transit time" % stage_id,
		)
		_check(
			is_equal_approx(
				float(with_field["mean_aerial_transit_ticks"]),
				float(baseline["mean_aerial_transit_ticks"]),
			),
			"%s aerial transit changed under a ground-only field" % stage_id,
		)
		_check(int(baseline["slow_contact_ticks"]) == 0, "%s baseline recorded slow contact" % stage_id)
		_append_csv_rows(stage_id, &"baseline", baseline)
		_append_csv_rows(stage_id, &"slow_field", with_field)

	var payload := {
		"schema": "protos_slow_field_balance_telemetry_v1",
		"ticks_per_second": 30,
		"policy": {
			"baseline": "No spell casts; identical authored waves and no combatants.",
			"slow_field": (
				"Cast at the median shared-path cell whenever Slow Field is ready and at "
				+ "least two live ground enemies occupy its 3x3 footprint."
			),
			"isolation": (
				"Leak limit and base HP are raised only to let every authored wave resolve; "
				+ "operators, traps, damage spells, and combat are absent."
			),
		},
		"stages": paired,
	}
	_write_json(payload)
	_write_csv()
	if _failures.is_empty():
		print("SLOW_FIELD_BALANCE_TELEMETRY_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _run_scenario(stage_id: StringName, use_slow_field: bool) -> Dictionary:
	var source := load("res://data/stages/%s.tres" % stage_id) as StageDef
	if source == null:
		return {}
	var stage := source.duplicate(true) as StageDef
	stage.leak_limit = 999
	var config := (load("res://data/config/game.tres") as GameConfig).duplicate(true) as GameConfig
	config.base_hp_start = 999
	var enemy_defs := _load_catalog("res://data/enemies")
	var slow := load("res://data/spells/slow_field.tres") as SpellDef
	var model := BattleModel.create(
		stage,
		[],
		7700 + int(stage.campaign_index),
		config,
		enemy_defs,
		{},
		{},
		{SPELL_ID: slow},
	)
	if model == null:
		return {}
	var center := _shared_corridor_cell(stage)
	var authored := stage.waves.duplicate(true)
	authored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["tick"]) < int(b["tick"]))
	var records: Dictionary = {}
	var casts: Array[int] = []
	var slow_contact_ticks := 0
	var max_alive := 0
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		_register_new_enemies(model, authored, records)
		if use_slow_field and model.is_castable(SPELL_ID):
			if _ground_in_footprint(model, center, slow.radius) >= 2:
				if model.apply_action([&"cast", SPELL_ID, center]):
					casts.append(model.tick)
		for enemy: EnemyState in model.enemies:
			if not enemy.alive or enemy.aerial:
				continue
			var cell := Pathing.cell_of(model.path_for(enemy.path_idx), enemy.progress_units)
			for field: SlowFieldState in model.slow_fields:
				if field.covers(cell):
					slow_contact_ticks += 1
					var record := records[enemy.id] as Dictionary
					record["affected"] = true
					record["slow_contact_ticks"] = int(record["slow_contact_ticks"]) + 1
					break
		max_alive = maxi(max_alive, model.alive_enemy_count())
		var alive_before: Dictionary = {}
		for enemy: EnemyState in model.enemies:
			alive_before[enemy.id] = enemy.alive
		model.step()
		_register_new_enemies(model, authored, records)
		for enemy: EnemyState in model.enemies:
			if bool(alive_before.get(enemy.id, false)) and not enemy.alive:
				var record := records[enemy.id] as Dictionary
				record["resolved_tick"] = model.tick
				record["transit_ticks"] = model.tick - int(record["spawn_tick"])
	if model.result == BattleModel.Result.RUNNING:
		_failures.append("%s telemetry exceeded %d ticks" % [stage_id, MAX_TICKS])
		return {}
	for enemy: EnemyState in model.enemies:
		if not records.has(enemy.id):
			continue
		var record := records[enemy.id] as Dictionary
		if int(record["resolved_tick"]) < 0:
			record["resolved_tick"] = model.tick
			record["transit_ticks"] = model.tick - int(record["spawn_tick"])
	return _summarize(stage, model, center, records, casts, slow_contact_ticks, max_alive)


func _register_new_enemies(model: BattleModel, authored: Array, records: Dictionary) -> void:
	for enemy: EnemyState in model.enemies:
		if records.has(enemy.id):
			continue
		var row: Dictionary = authored[enemy.id]
		records[enemy.id] = {
			"enemy_id": String(enemy.def_id),
			"path_idx": enemy.path_idx,
			"wave": _wave_index(model.stage, int(row["tick"])),
			"spawn_tick": int(row["tick"]),
			"resolved_tick": -1,
			"transit_ticks": 0,
			"aerial": enemy.aerial,
			"affected": false,
			"slow_contact_ticks": 0,
		}


func _summarize(
	stage: StageDef,
	model: BattleModel,
	center: Vector2i,
	records: Dictionary,
	casts: Array[int],
	slow_contact_ticks: int,
	max_alive: int,
) -> Dictionary:
	var ground: Array[Dictionary] = []
	var aerial: Array[Dictionary] = []
	var affected := 0
	var by_wave: Array[Dictionary] = []
	for _wave: int in stage.wave_starts.size():
		by_wave.append({"ground": [], "aerial": [], "affected": 0, "slow_contact_ticks": 0})
	for enemy_id: int in records:
		var record := records[enemy_id] as Dictionary
		if bool(record["aerial"]):
			aerial.append(record)
		else:
			ground.append(record)
			if bool(record["affected"]):
				affected += 1
		var wave_row := by_wave[int(record["wave"])] as Dictionary
		var domain := "aerial" if bool(record["aerial"]) else "ground"
		(wave_row[domain] as Array).append(record)
		if bool(record["affected"]):
			wave_row["affected"] = int(wave_row["affected"]) + 1
		wave_row["slow_contact_ticks"] = (
			int(wave_row["slow_contact_ticks"]) + int(record["slow_contact_ticks"])
		)
	var waves: Array[Dictionary] = []
	for wave_index: int in by_wave.size():
		var wave_row := by_wave[wave_index] as Dictionary
		var wave_ground := wave_row["ground"] as Array
		var wave_aerial := wave_row["aerial"] as Array
		waves.append({
			"wave": wave_index + 1,
			"start_tick": stage.wave_starts[wave_index],
			"casts": _casts_in_wave(stage, casts, wave_index),
			"ground_spawned": wave_ground.size(),
			"aerial_spawned": wave_aerial.size(),
			"ground_affected": int(wave_row["affected"]),
			"ground_affected_pct": _percent(int(wave_row["affected"]), wave_ground.size()),
			"slow_contact_ticks": int(wave_row["slow_contact_ticks"]),
			"mean_ground_transit_ticks": _mean_transit(wave_ground),
			"p95_ground_transit_ticks": _percentile_transit(wave_ground, 0.95),
			"mean_aerial_transit_ticks": _mean_transit(wave_aerial),
		})
	return {
		"stage": String(stage.id),
		"center": {"x": center.x, "y": center.y},
		"terminal_tick": model.tick,
		"result": model.result,
		"spawned": model.spawned,
		"resolved": records.size(),
		"ground_spawned": ground.size(),
		"aerial_spawned": aerial.size(),
		"ground_affected": affected,
		"ground_affected_pct": _percent(affected, ground.size()),
		"casts": casts.size(),
		"cast_ticks": casts,
		"slow_contact_ticks": slow_contact_ticks,
		"mean_ground_transit_ticks": _mean_transit(ground),
		"p95_ground_transit_ticks": _percentile_transit(ground, 0.95),
		"mean_aerial_transit_ticks": _mean_transit(aerial),
		"max_alive": max_alive,
		"waves": waves,
	}


func _append_csv_rows(stage_id: StringName, scenario: StringName, summary: Dictionary) -> void:
	_rows.append(_csv_row(stage_id, scenario, "overall", summary))
	for wave: Dictionary in summary["waves"]:
		_rows.append(_csv_row(stage_id, scenario, "wave_%d" % int(wave["wave"]), wave))


func _csv_row(stage_id: StringName, scenario: StringName, scope: String, data: Dictionary) -> Dictionary:
	return {
		"stage": String(stage_id),
		"scenario": String(scenario),
		"scope": scope,
		"casts": data.get("casts", ""),
		"ground_spawned": int(data.get("ground_spawned", 0)),
		"aerial_spawned": int(data.get("aerial_spawned", 0)),
		"ground_affected": int(data.get("ground_affected", 0)),
		"ground_affected_pct": data.get("ground_affected_pct", ""),
		"slow_contact_ticks": data.get("slow_contact_ticks", ""),
		"mean_ground_transit_ticks": data.get("mean_ground_transit_ticks", ""),
		"p95_ground_transit_ticks": data.get("p95_ground_transit_ticks", ""),
		"mean_aerial_transit_ticks": data.get("mean_aerial_transit_ticks", ""),
		"max_alive": data.get("max_alive", ""),
		"terminal_tick": data.get("terminal_tick", ""),
	}


func _casts_in_wave(stage: StageDef, casts: Array[int], wave_index: int) -> int:
	var start := stage.wave_starts[wave_index]
	var end := MAX_TICKS
	if wave_index + 1 < stage.wave_starts.size():
		end = stage.wave_starts[wave_index + 1]
	var count := 0
	for cast_tick: int in casts:
		if cast_tick >= start and cast_tick < end:
			count += 1
	return count


func _ground_in_footprint(model: BattleModel, center: Vector2i, radius: int) -> int:
	var count := 0
	for enemy: EnemyState in model.enemies:
		if not enemy.alive or enemy.aerial or enemy.faction != EnemyState.Faction.ENEMY:
			continue
		var cell := Pathing.cell_of(model.path_for(enemy.path_idx), enemy.progress_units)
		if maxi(absi(cell.x - center.x), absi(cell.y - center.y)) <= radius:
			count += 1
	return count


func _shared_corridor_cell(stage: StageDef) -> Vector2i:
	var owners: Dictionary = {}
	for path_index: int in stage.paths.size():
		for cell: Vector2i in stage.path_cells(path_index):
			owners[cell] = int(owners.get(cell, 0)) + 1
	var shared: Array[Vector2i] = []
	for cell: Vector2i in owners:
		if int(owners[cell]) > 1:
			shared.append(cell)
	shared.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	return shared[shared.size() / 2]


func _wave_index(stage: StageDef, spawn_tick: int) -> int:
	var result := 0
	for index: int in stage.wave_starts.size():
		if spawn_tick >= stage.wave_starts[index]:
			result = index
	return result


func _mean_transit(records: Array) -> float:
	if records.is_empty():
		return 0.0
	var total := 0.0
	for record: Dictionary in records:
		total += float(record["transit_ticks"])
	return total / float(records.size())


func _percentile_transit(records: Array, percentile: float) -> float:
	if records.is_empty():
		return 0.0
	var values: Array[int] = []
	for record: Dictionary in records:
		values.append(int(record["transit_ticks"]))
	values.sort()
	var index := clampi(ceili(percentile * float(values.size())) - 1, 0, values.size() - 1)
	return float(values[index])


func _percent(numerator: int, denominator: int) -> float:
	if denominator <= 0:
		return 0.0
	return snappedf(float(numerator) * 100.0 / float(denominator), 0.1)


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
	var path := OS.get_environment("SLOW_FIELD_TELEMETRY_JSON")
	if path.is_empty():
		path = "/tmp/slow-field-balance-telemetry.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write telemetry JSON: %s" % path)
		return
	file.store_string(JSON.stringify(payload, "  "))


func _write_csv() -> void:
	var path := OS.get_environment("SLOW_FIELD_TELEMETRY_CSV")
	if path.is_empty():
		path = "/tmp/slow-field-balance-telemetry.csv"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write telemetry CSV: %s" % path)
		return
	var columns := [
		"stage", "scenario", "scope", "casts", "ground_spawned", "aerial_spawned",
		"ground_affected", "ground_affected_pct", "slow_contact_ticks",
		"mean_ground_transit_ticks", "p95_ground_transit_ticks",
		"mean_aerial_transit_ticks", "max_alive", "terminal_tick",
	]
	file.store_csv_line(columns)
	for row: Dictionary in _rows:
		var values := PackedStringArray()
		for column: String in columns:
			values.append(str(row[column]))
		file.store_csv_line(values)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
