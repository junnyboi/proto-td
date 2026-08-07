extends GutTest

## Phase 10 Lane-C gates at model speed (td-phase-10.md §4.2, K11): every
## stage bot's declarative timeline runs through the pure model per commit —
## clearability, the idle differential (empty timeline loses every campaign
## stage), the S6 no-charm differential, and an S8 determinism spot-check.
## This file is also the stage-tuning inner loop: failures print the full
## terminal snapshot.

const MAX_TICKS := 6_000

var _catalogs: Dictionary = {}


func before_each() -> void:
	_catalogs = {
		"enemies": _load_defs("res://data/enemies"),
		"operators": _load_defs("res://data/operators"),
		"traps": _load_defs("res://data/traps"),
		"spells": _load_defs("res://data/spells"),
	}


func _load_defs(dir_path: String) -> Dictionary:
	var defs: Dictionary = {}
	for f: String in DirAccess.open(dir_path).get_files():
		if f.ends_with(".tres"):
			var def: Resource = load(dir_path + "/" + f)
			defs[def.get("id")] = def
	return defs


func _bot(bot_name: String) -> StageBot:
	return (load("res://playtests/bots/%s.gd" % bot_name) as GDScript).new()


func _make_model(stage_id: StringName, squad: Array[StringName]) -> BattleModel:
	var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
	var config := load("res://data/config/game.tres") as GameConfig
	return BattleModel.create(
		stage, squad, 42, config, _catalogs["enemies"], _catalogs["operators"],
		_catalogs["traps"], _catalogs["spells"],
	)


## Runs a timeline to terminal, asserting every action is accepted (a
## silently rejected verb is a broken timeline — fail there, not at DEFEAT).
func _run(model: BattleModel, timeline: Array, tag: String) -> void:
	var rows := timeline.duplicate()
	rows.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	var idx := 0
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		while idx < rows.size() and int(rows[idx][0]) == model.tick:
			var row: Array = rows[idx]
			assert_true(
				model.apply_action(row.slice(1)),
				"%s: action accepted @tick %d: %s (dp=%d)" % [tag, model.tick, str(row), model.dp],
			)
			idx += 1
		model.step()
	assert_eq(idx, rows.size(), "%s: every timeline row played" % tag)


func _snapshot_line(model: BattleModel) -> String:
	return "result=%d leaked=%d killed=%d alive=%d charmed=%d base_hp=%d tick=%d" % [
		model.result, model.leaked, model.killed, model.alive_enemy_count(),
		model.charmed, model.base_hp, model.tick,
	]


## §4.2.1 gate: every stage bot clears inside its leak band.
func test_stage_clearability() -> void:
	for i: int in range(1, 9):
		var bot := _bot("bot_stage_0%d" % i)
		var model := _make_model(bot.stage_id(), bot.squad())
		_run(model, bot.timeline(), String(bot.stage_id()))
		assert_eq(
			model.result, BattleModel.Result.CLEAR,
			"%s clears (%s)" % [bot.stage_id(), _snapshot_line(model)],
		)
		assert_true(
			model.leaked <= bot.leak_band(),
			"%s leak band: %d <= %d" % [bot.stage_id(), model.leaked, bot.leak_band()],
		)


## §4.2.2 gate: the empty timeline loses every campaign stage.
func test_idle_loses_everywhere() -> void:
	for i: int in range(1, 9):
		var sid := StringName("s%d" % i)
		var model := _make_model(sid, [] as Array[StringName])
		while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
			model.step()
		assert_eq(
			model.result, BattleModel.Result.DEFEAT,
			"idle loses %s (%s)" % [sid, _snapshot_line(model)],
		)


## §4.2.3 gate: S6's timeline minus the charm casts loses while the full
## timeline clears — the same stage, the same squad, one verb apart.
func test_s6_no_charm_differential() -> void:
	var full := _bot("bot_stage_06")
	var full_model := _make_model(full.stage_id(), full.squad())
	_run(full_model, full.timeline(), "s6-full")
	assert_eq(full_model.result, BattleModel.Result.CLEAR, "full s6 timeline clears")

	var cut := _bot("bot_stage_06_no_charm")
	assert_eq(cut.stage_id(), &"s6")
	assert_lt(cut.timeline().size(), full.timeline().size(), "the filter removed the casts")
	var cut_model := _make_model(cut.stage_id(), cut.squad())
	_run(cut_model, cut.timeline(), "s6-no-charm")
	assert_eq(
		cut_model.result, BattleModel.Result.DEFEAT,
		"charmless s6 loses (%s)" % _snapshot_line(cut_model),
	)


## §4.2.4: S8 determinism spot-check — stage data can't smoke out latent
## nondeterminism (paranoia; no model change exists in this phase).
func test_s8_determinism() -> void:
	var traces: Array = []
	for _round: int in 2:
		var bot := _bot("bot_stage_08")
		var model := _make_model(bot.stage_id(), bot.squad())
		var rows := bot.timeline().duplicate()
		rows.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
		var idx := 0
		var trace: Array[int] = []
		while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
			while idx < rows.size() and int(rows[idx][0]) == model.tick:
				model.apply_action((rows[idx] as Array).slice(1))
				idx += 1
			model.step()
			if model.tick % 500 == 0:
				trace.append(model.state_hash())
		trace.append(int(model.result))
		traces.append(trace)
	assert_eq(traces[0], traces[1], "s8 timeline is deterministic")
