extends GutTest

## Phase 9 sim-surface tests (td-phase-9.md §5). Juice is view-side; the
## model's whole contribution is two hashed records — died_at_tick (kill
## paths only, either faction) and last_trigger_tick — plus the JuiceConfig
## schema. The disambiguation rule under test (§2.1.7): leaks and charmed
## exits leave died_at_tick at -1, so kill juice can never fire for them.

const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"
const FAR_WAVE := {"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0}


func _config() -> GameConfig:
	return load(CONFIG_PATH) as GameConfig


func _stage_with_waves(entries: Array[Dictionary]) -> StageDef:
	var stage := (load(STAGE_PATH) as StageDef).duplicate(true) as StageDef
	var waves: Array[Dictionary] = []
	for entry: Dictionary in entries:
		waves.append(entry)
	stage.waves = waves
	return stage


func _catalog(dir_path: String) -> Dictionary:
	var defs: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	for file: String in dir.get_files():
		if file.ends_with(".tres"):
			var def: Resource = load(dir_path + "/" + file)
			defs[def.get("id")] = def
	return defs


func _enemy_catalog() -> Dictionary:
	return {
		&"grunt": load("res://data/enemies/grunt.tres") as EnemyDef,
		&"heavy": load("res://data/enemies/heavy.tres") as EnemyDef,
	}


func _make_model(stage: StageDef, trap_defs: Dictionary = {}) -> BattleModel:
	if trap_defs.is_empty():
		trap_defs = _catalog("res://data/traps")
	var squad: Array[StringName] = [&"guard_1"]
	return BattleModel.create(
		stage, squad, 42, _config(), _enemy_catalog(),
		_catalog("res://data/operators"), trap_defs, _catalog("res://data/spells"),
	)


## Steps until `counter_of.call()` increments; returns the tick the event
## landed on (entry-tick convention: observable at model.tick == T + 1).
func _step_until_delta(model: BattleModel, counter_of: Callable, max_ticks: int) -> int:
	var before := int(counter_of.call())
	while model.tick < max_ticks and model.result == BattleModel.Result.RUNNING:
		var t := model.tick
		model.step()
		if int(counter_of.call()) > before:
			return t
	return -1


## §5.1: died_at_tick set to the exact kill tick by a unit kill and a Bolt
## kill; -1 for a leaked enemy.
func test_died_at_tick_unit_bolt_leak() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(entries))
	model.apply_action([&"debug_set_dp", 99])
	assert_true(model.apply_action([&"deploy", &"guard_1", Vector2i(3, 2), 0]))
	var kill_tick := _step_until_delta(model, func() -> int: return model.killed, 2_000)
	assert_true(kill_tick > 0, "the guard killed the blocked grunt")
	assert_eq(model.enemies[0].died_at_tick, kill_tick, "unit kill stamps the kill tick")

	var bolt_model := _make_model(_stage_with_waves(entries))
	bolt_model.step(100)
	assert_true(bolt_model.apply_action([&"cast", &"bolt", Vector2i(3, 2)]), "grunt in cell 3")
	assert_eq(bolt_model.enemies[0].died_at_tick, 100, "bolt kill stamps the cast tick")

	var leak_model := _make_model(_stage_with_waves(entries))
	var leak_tick := _step_until_delta(leak_model, func() -> int: return leak_model.leaked, 2_000)
	assert_true(leak_tick > 0, "undefended grunt leaked")
	assert_eq(leak_model.enemies[0].died_at_tick, -1, "a leak never stamps died_at_tick")


## §5.1: a trap kill stamps died_at_tick (in-test high-damage spike — the
## stock 20 damage can't kill; damage is data, rule 4); a duel kill of a
## charmed ally stamps it via _kill_charmed; a charmed exit leaves -1.
func test_died_at_tick_trap_duel_exit() -> void:
	var lethal: TrapDef = (load("res://data/traps/spike_plate.tres") as TrapDef).duplicate(true)
	lethal.damage = 999
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(entries), {&"spike_plate": lethal})
	assert_true(model.apply_action([&"place_trap", &"spike_plate", Vector2i(3, 2)]))
	var trap_tick := _step_until_delta(model, func() -> int: return model.killed, 2_000)
	assert_true(trap_tick > 0, "the lethal spike killed the grunt")
	assert_eq(model.enemies[0].died_at_tick, trap_tick, "trap kill stamps the trigger tick")

	# duel: charm the lead grunt at 150 (cell 4); the heavy walking behind it
	# meets it mid-reversal; heavy atk 12 kills the 40 hp ally -> charmed_dead
	var duel_entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 60, "enemy_id": &"heavy", "path_idx": 0},
		FAR_WAVE,
	]
	var duel := _make_model(_stage_with_waves(duel_entries))
	duel.step(150)
	assert_true(duel.apply_action([&"cast", &"charm", 0]))
	var dead_tick := _step_until_delta(duel, func() -> int: return duel.charmed_dead, 2_000)
	assert_true(dead_tick > 0, "the heavy won the duel")
	assert_eq(duel.enemies[0].died_at_tick, dead_tick, "duel kill stamps via _kill_charmed")

	# exit: nothing behind the charmed grunt -> it walks out at spawn
	var exit_model := _make_model(_stage_with_waves(entries))
	exit_model.step(100)
	assert_true(exit_model.apply_action([&"cast", &"charm", 0]))
	var exit_tick := _step_until_delta(
		exit_model, func() -> int: return exit_model.charmed_exited, 2_000
	)
	assert_true(exit_tick > 0, "the ally exited at spawn")
	assert_eq(exit_model.enemies[0].died_at_tick, -1, "a charmed exit never stamps died_at_tick")


## §5.2: last_trigger_tick on every spike trigger, including the final
## charge — the trap leaves model.traps that tick but the held ref keeps
## the record (the view's sprung frame depends on exactly this).
func test_last_trigger_tick() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 60, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 120, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(entries))
	assert_true(model.apply_action([&"place_trap", &"spike_plate", Vector2i(3, 2)]))
	var trap: TrapState = model.traps[0]
	assert_eq(trap.last_trigger_tick, -1, "armed and untriggered")
	var t1 := _step_until_delta(model, func() -> int: return model.traps_triggered, 2_000)
	assert_eq(trap.last_trigger_tick, t1, "first trigger stamped")
	assert_eq(trap.charges_left, 2)
	var t2 := _step_until_delta(model, func() -> int: return model.traps_triggered, 2_000)
	assert_gt(t2, t1)
	var t3 := _step_until_delta(model, func() -> int: return model.traps_triggered, 2_000)
	assert_eq(model.traps.size(), 0, "final charge removed the trap from the model")
	assert_eq(trap.last_trigger_tick, t3, "the held ref keeps the final trigger tick")


## §5.3: the hash extensions are real — models differing ONLY in a juice
## field hash differently; and the oracle holds over a kill+trap+charm
## timeline stepped twice from fresh models.
func test_hash_and_determinism() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var a := _make_model(_stage_with_waves(entries))
	var b := _make_model(_stage_with_waves(entries))
	a.step(10)
	b.step(10)
	assert_eq(a.state_hash(), b.state_hash(), "twin models agree")
	a.enemies[0].died_at_tick = 5
	assert_ne(a.state_hash(), b.state_hash(), "died_at_tick is hashed")
	a.enemies[0].died_at_tick = -1
	a.apply_action([&"place_trap", &"spike_plate", Vector2i(3, 2)])
	b.apply_action([&"place_trap", &"spike_plate", Vector2i(3, 2)])
	assert_eq(a.state_hash(), b.state_hash(), "twin traps agree")
	a.traps[0].last_trigger_tick = 7
	assert_ne(a.state_hash(), b.state_hash(), "last_trigger_tick is hashed")

	var first := _run_juice_timeline()
	var second := _run_juice_timeline()
	assert_eq(first, second, "kill+trap+charm timeline is deterministic")


func _run_juice_timeline() -> Array[int]:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 60, "enemy_id": &"heavy", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(entries))
	var actions := {
		1: [&"debug_set_dp", 99],
		5: [&"place_trap", &"spike_plate", Vector2i(4, 2)],
		10: [&"deploy", &"guard_1", Vector2i(5, 2), 0],
		100: [&"cast", &"bolt", Vector2i(3, 2)],
		150: [&"cast", &"charm", 2],
	}
	var trace: Array[int] = []
	while model.tick < 500:
		if actions.has(model.tick):
			model.apply_action(actions[model.tick])
		model.step()
		if model.tick % 100 == 0:
			trace.append(model.state_hash())
	trace.append(int(model.result))
	return trace


## §5.4: the config resource loads and every value is sane.
func test_juice_config_sanity() -> void:
	var cfg := load("res://data/juice_config.tres") as JuiceConfig
	assert_not_null(cfg)
	assert_true(cfg.deploy_drag_time_scale > 0.0 and cfg.deploy_drag_time_scale <= 1.0)
	assert_true(cfg.charm_beat_time_scale > 0.0 and cfg.charm_beat_time_scale <= 1.0)
	var frame_fields := [
		cfg.deploy_crouch_frames, cfg.deploy_dust_frames, cfg.skill_flash_frames,
		cfg.skill_burst_frames, cfg.kill_spark_frames, cfg.kill_spark_cap,
		cfg.leak_vignette_frames, cfg.leak_shake_frames, cfg.leak_hit_stop_frames,
		cfg.wave_banner_frames, cfg.star_burst_stagger_frames, cfg.trap_sprung_frames,
		cfg.tar_shimmer_period_frames, cfg.charm_swirl_frames, cfg.charm_beat_frames,
		cfg.charm_shake_frames, cfg.charm_hit_stop_frames, cfg.tracer_frames,
	]
	for value: int in frame_fields:
		assert_true(value >= 0, "frame counts are non-negative")
	assert_true(cfg.leak_shake_amplitude_px >= 0.0 and cfg.charm_shake_amplitude_px >= 0.0)
	assert_true(cfg.shake_events.has("leak") and cfg.shake_events.has("charm_beat"))
