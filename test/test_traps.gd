extends GutTest

## Phase 6 gate tests (td-phase-6-7.md §3.4, model-level). Paper-derived
## constants (derivation written BEFORE the tests, per §3.7):
##   grunt step 33_333 u/tick; runner 66_666; drone 40_000 (1.2 tiles/s).
##   test_lane path = 7 cells -> 7_000_000 u; cell k spans [k*1M, (k+1)*1M).
##   An enemy spawned at tick T advances during entry ticks T+1, T+2, ...;
##   advance i lands during the step whose entry tick is T+i (observable at
##   model.tick == T+i+1, the repo convention).
##   Grunt enters cell 3 on advance 91 (33_333*91 = 3_033_303) and cell 4 on
##   advance 121 (33_333*121 = 4_033_293) -> spike-on-cell-4 triggers at
##   tick spawn+121. Runner enters cell 4 on advance 61 (66_666*61 =
##   4_066_626). Drone leaks on advance 175 (40_000*175 = 7_000_000).

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const RUNNER_PATH := "res://data/enemies/runner.tres"
const DRONE_PATH := "res://data/enemies/drone.tres"
const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"
const VG_PATH := "res://data/operators/vanguard_1.tres"
const SPIKE_PATH := "res://data/traps/spike_plate.tres"
const TAR_PATH := "res://data/traps/tar_pit.tres"

const SPIKE_CELL := Vector2i(4, 2)
const TAR_CELL := Vector2i(3, 2)
const OFF_PATH_GROUND := Vector2i(1, 0)
const ELEV_CELL := Vector2i(2, 1)
const SPAWN_CELL := Vector2i(0, 2)
const BASE_CELL := Vector2i(6, 2)
const VOID_CELL := Vector2i(7, 2)

const RIGHT := UnitState.Facing.RIGHT
const MAX_TICKS := 20_000


func _config() -> GameConfig:
	return load(CONFIG_PATH) as GameConfig


func _stage() -> StageDef:
	return load(STAGE_PATH) as StageDef


func _stage_with_waves(entries: Array[Dictionary]) -> StageDef:
	var stage := _stage().duplicate(true) as StageDef
	var waves: Array[Dictionary] = []
	for entry: Dictionary in entries:
		waves.append(entry)
	stage.waves = waves
	return stage


func _grunt_waves(spawn_ticks: Array[int]) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for t: int in spawn_ticks:
		entries.append({"tick": t, "enemy_id": &"grunt", "path_idx": 0})
	return entries


func _trap_catalog() -> Dictionary:
	return {
		&"spike_plate": load(SPIKE_PATH) as TrapDef,
		&"tar_pit": load(TAR_PATH) as TrapDef,
	}


## In-test ON_ENTER trap (data-in-test, same license as in-test stages).
func _custom_spike(dmg: int, charge_count: int) -> Dictionary:
	var def := TrapDef.new()
	def.id = &"test_spike"
	def.display_name = "Test Spike"
	def.dp_cost = 1
	def.trigger = TrapDef.Trigger.ON_ENTER
	def.effect = TrapDef.Effect.DAMAGE
	def.damage = dmg
	def.charges = charge_count
	return {&"test_spike": def}


func _make_model(
	stage: StageDef, config: GameConfig, extra_traps: Dictionary = {}
) -> BattleModel:
	var trap_defs := _trap_catalog()
	for key: StringName in extra_traps:
		trap_defs[key] = extra_traps[key]
	var enemy_defs: Dictionary = {
		&"grunt": load(GRUNT_PATH) as EnemyDef,
		&"runner": load(RUNNER_PATH) as EnemyDef,
		&"drone": load(DRONE_PATH) as EnemyDef,
	}
	var ops: Dictionary = {&"vanguard_1": load(VG_PATH) as OperatorDef}
	var squad: Array[StringName] = [&"vanguard_1"]
	return BattleModel.create(stage, squad, 42, config, enemy_defs, ops, trap_defs)


func _assert_rejected(model: BattleModel, action: Array, label: String) -> void:
	var before := model.state_hash()
	assert_false(model.apply_action(action), label + " rejects")
	assert_eq(model.state_hash(), before, label + " leaves state untouched")


func _assert_ledger(model: BattleModel) -> void:
	var expected := (
		model.config.dp_start
		+ model.dp_regen_accrued
		+ model.dp_vanguard_generated
		+ model.dp_refunded
		+ model.dp_skill_granted
		- model.dp_spent
		- model.dp_lost_to_cap
	)
	assert_eq(model.dp, expected, "DP ledger exact @ tick %d" % model.tick)


## §3.4.1 gate: three grunts pay exactly 20 each on their entry tick, the
## trap is removed after the 3rd charge, a 4th crosses unharmed, and the
## cell accepts a new trap again.
func test_spike_exactness() -> void:
	var spawn_ticks: Array[int] = [0, 60, 120, 180]
	var model := _make_model(_stage_with_waves(_grunt_waves(spawn_ticks)), _config())
	assert_true(model.apply_action([&"place_trap", &"spike_plate", SPIKE_CELL]))
	assert_eq(model.dp, 6, "10 - spike cost 4")
	var entry_ticks: Array[int] = [121, 181, 241]
	for i: int in entry_ticks.size():
		model.step(entry_ticks[i] - model.tick)
		assert_eq(model.enemies[i].hp, 40, "g%d untouched before entry" % i)
		model.step()
		assert_eq(model.enemies[i].hp, 20, "g%d pays exactly 20 on entry" % i)
	assert_null(model.alive_trap_at(SPIKE_CELL), "trap removed at 0 charges")
	assert_eq(model.traps_triggered, 3)
	model.step(301 - model.tick)
	model.step()
	assert_eq(model.enemies[3].hp, 40, "4th grunt crosses unharmed")
	assert_true(
		model.apply_action([&"place_trap", &"spike_plate", SPIKE_CELL]),
		"exhausted cell is placeable again"
	)


## §3.4.2 gate: tar on cell 3 (slow 500 permille -> slowed step 16_666).
## Paper derivation: advance 91 ENTERS cell 3 unslowed (its start-of-tick
## cell is cell 2, progress 2_999_970). Slowed advances are those whose
## start-of-tick progress lies in [3_033_303, 4_000_000): 16_666*k >=
## 4_000_000 - 3_033_303 = 966_697 -> k = 59 (advances 92..150, exiting at
## progress 4_016_597). Remaining: ceil(2_983_403 / 33_333) = 90 advances.
## Total 91 + 59 + 90 = 240 -> leak at tick spawn + 240 (unslowed: 211;
## unslowed decomposition 91 + 30 + 90 cross-checks).
func test_tar_exactness() -> void:
	var spawn_ticks: Array[int] = [30]
	var model := _make_model(_stage_with_waves(_grunt_waves(spawn_ticks)), _config())
	assert_true(model.apply_action([&"place_trap", &"tar_pit", TAR_CELL]))
	model.step(160)
	var p1 := model.enemies[0].progress_units
	model.step()
	assert_eq(
		model.enemies[0].progress_units - p1,
		16_666,
		"start-of-tick cell 3 advances at the slowed step"
	)
	model.step(270 - model.tick)
	assert_eq(model.leaked, 0, "no leak before tick 270 (tick=%d)" % model.tick)
	model.step()
	assert_eq(model.leaked, 1, "tar-slowed leak lands exactly at spawn + 240")
	assert_eq(model.traps_triggered, 0, "aura traps never consume triggers")


## §3.4.3: placement under an enemy already standing on the cell never
## triggers; a later enemy entering the same cell triggers normally.
func test_entry_semantics_placement_under_feet() -> void:
	var spawn_ticks: Array[int] = [30, 90]
	var model := _make_model(_stage_with_waves(_grunt_waves(spawn_ticks)), _config())
	model.step(130)
	# g0 (spawn 30) entered cell 3 at tick 121 and stands on it until 151
	assert_true(model.apply_action([&"place_trap", &"spike_plate", TAR_CELL]))
	model.step(155 - model.tick)
	assert_eq(model.enemies[0].hp, 40, "no free hit on placement under feet")
	assert_eq(model.traps_triggered, 0)
	# g1 (spawn 90) enters cell 3 at tick 90 + 91 = 181 and triggers
	model.step(181 - model.tick)
	assert_eq(model.enemies[1].hp, 40)
	model.step()
	assert_eq(model.enemies[1].hp, 20, "a real entry still triggers")
	assert_eq(model.traps_triggered, 1)


## §3.4.4: two enemies entering a 1-charge spike cell on the same tick —
## higher path progress pays; equal progress -> lower id pays.
func test_charge_contention_ordering() -> void:
	# grunt spawn 0 and runner spawn 60 both enter cell 4 at tick 121;
	# runner progress 4_066_626 > grunt 4_033_293 -> runner pays
	var mixed: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 60, "enemy_id": &"runner", "path_idx": 0},
	]
	var model := _make_model(_stage_with_waves(mixed), _config(), _custom_spike(20, 1))
	assert_true(model.apply_action([&"place_trap", &"test_spike", SPIKE_CELL]))
	model.step(122)
	assert_eq(model.enemies[1].hp, 5, "runner (higher progress) pays the charge")
	assert_eq(model.enemies[0].hp, 40, "grunt crosses unharmed")
	assert_null(model.alive_trap_at(SPIKE_CELL), "single charge consumed")
	# tie: two grunts spawned the same tick share progress -> lower id pays
	var twins: Array[int] = [0, 0]
	var tie := _make_model(_stage_with_waves(_grunt_waves(twins)), _config(), _custom_spike(20, 1))
	assert_true(tie.apply_action([&"place_trap", &"test_spike", SPIKE_CELL]))
	tie.step(122)
	assert_eq(tie.enemies[0].hp, 20, "equal progress: lower id pays")
	assert_eq(tie.enemies[1].hp, 40, "higher id crosses unharmed")


## §3.4.5: every invalid placement returns false with hash-equal state.
func test_invalid_placements() -> void:
	var model := _make_model(_stage(), _config())
	_assert_rejected(model, [&"place_trap", &"spike_plate", OFF_PATH_GROUND], "off-path GROUND")
	_assert_rejected(model, [&"place_trap", &"spike_plate", ELEV_CELL], "ELEVATED tile")
	_assert_rejected(model, [&"place_trap", &"spike_plate", SPAWN_CELL], "SPAWN tile")
	_assert_rejected(model, [&"place_trap", &"spike_plate", BASE_CELL], "BASE tile")
	_assert_rejected(model, [&"place_trap", &"spike_plate", VOID_CELL], "VOID cell")
	_assert_rejected(model, [&"place_trap", &"nope", TAR_CELL], "unknown trap id")
	assert_true(model.apply_action([&"place_trap", &"spike_plate", TAR_CELL]))
	_assert_rejected(model, [&"place_trap", &"tar_pit", TAR_CELL], "trap-occupied cell")
	var broke := _config().duplicate() as GameConfig
	broke.dp_start = 3
	var poor := _make_model(_stage(), broke)
	_assert_rejected(poor, [&"place_trap", &"spike_plate", TAR_CELL], "insufficient DP (3 < 4)")


## §3.4.6 gate: the Phase 2 ledger equation holds every tick of a mixed
## deploy + trap timeline (trap spends ride dp_spent); traps have no refund
## path (retreat on a trap-only id rejects).
func test_extended_dp_ledger_property() -> void:
	var config := _config().duplicate() as GameConfig
	config.dp_cap = 14
	var far := _stage_with_waves(
		[{"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0}] as Array[Dictionary]
	)
	var model := _make_model(far, config)
	var actions := [
		[30, &"deploy", &"vanguard_1", OFF_PATH_GROUND, int(RIGHT)],
		[120, &"place_trap", &"spike_plate", SPIKE_CELL],
		[300, &"place_trap", &"tar_pit", TAR_CELL],
		[400, &"retreat", 0],
	]
	var idx := 0
	while model.tick < 900:
		while idx < actions.size() and int(actions[idx][0]) == model.tick:
			var entry: Array = actions[idx]
			assert_true(model.apply_action(entry.slice(1)), "timeline action @ %d" % model.tick)
			idx += 1
		model.step()
		assert_true(model.dp >= 0 and model.dp <= config.dp_cap, "dp in [0, cap] @ %d" % model.tick)
		_assert_ledger(model)
	assert_eq(idx, actions.size(), "every timeline action was applied")
	assert_true(model.dp_lost_to_cap > 0, "the cap actually clamped during the run")
	assert_eq(model.dp_spent, 8 + 4 + 6, "trap spends ride the spent bucket")
	# no refund path for traps: a trap-only model has no unit id to retreat
	var trap_only := _make_model(far, _config())
	assert_true(trap_only.apply_action([&"place_trap", &"spike_plate", SPIKE_CELL]))
	assert_true(trap_only.apply_action([&"place_trap", &"tar_pit", TAR_CELL]))
	_assert_rejected(trap_only, [&"retreat", 0], "retreat on trap id 0")
	_assert_rejected(trap_only, [&"retreat", 1], "retreat on trap id 1")


## §3.4.7: aerial enemies ignore traps — no trigger, no slow; the drone's
## arrival tick equals the unslowed constant (spawn + 175).
func test_aerial_immunity() -> void:
	var wave: Array[Dictionary] = [{"tick": 30, "enemy_id": &"drone", "path_idx": 0}]
	var model := _make_model(_stage_with_waves(wave), _config())
	assert_true(model.apply_action([&"place_trap", &"spike_plate", SPIKE_CELL]))
	assert_true(model.apply_action([&"place_trap", &"tar_pit", TAR_CELL]))
	model.step(150)
	assert_eq(model.enemies[0].hp, 30, "drone untouched mid-path")
	model.step(205 - model.tick)
	assert_eq(model.leaked, 0, "no leak before spawn + 175")
	model.step()
	assert_eq(model.leaked, 1, "drone arrival is the unslowed constant")
	assert_eq(model.traps_triggered, 0, "no ON_ENTER trigger for aerial")
	var spike := model.alive_trap_at(SPIKE_CELL)
	assert_eq(spike.charges_left, 3, "charges intact")


## §3.4.8: a lethal spike kill routes through the one death path
## (killed += 1) and conservation holds every tick to terminal.
func test_kill_attribution_and_conservation() -> void:
	var spawn_ticks: Array[int] = [0, 60, 120]
	var model := _make_model(
		_stage_with_waves(_grunt_waves(spawn_ticks)), _config(), _custom_spike(60, 3)
	)
	assert_true(model.apply_action([&"place_trap", &"test_spike", SPIKE_CELL]))
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		model.step()
		var books := model.alive_count() + model.leaked + model.killed
		assert_eq(model.spawned, books, "conservation @ tick %d" % model.tick)
	assert_eq(model.killed, 3, "all three grunts died to the spike")
	assert_eq(model.leaked, 0)
	assert_eq(model.result, BattleModel.Result.CLEAR, "trap kills win the stage")
	assert_eq(model.stars, 3)
	_assert_rejected(model, [&"place_trap", &"spike_plate", TAR_CELL], "place_trap after terminal")


## §3.4.9 gate: determinism oracle on a trap-heavy timeline — two fresh
## models, identical hashes every 100 ticks and identical outcome.
func test_determinism_oracle_with_traps() -> void:
	var actions := [
		[0, &"place_trap", &"spike_plate", SPIKE_CELL],
		[10, &"place_trap", &"tar_pit", TAR_CELL],
		[350, &"place_trap", &"spike_plate", Vector2i(2, 2)],
	]
	var runs: Array = []
	for _run: int in 2:
		var stage := ResourceLoader.load(STAGE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var config := ResourceLoader.load(CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var grunt := ResourceLoader.load(GRUNT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var spike := ResourceLoader.load(SPIKE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var tar := ResourceLoader.load(TAR_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var squad: Array[StringName] = []
		var model := BattleModel.create(
			stage,
			squad,
			42,
			config,
			{&"grunt": grunt},
			{},
			{&"spike_plate": spike, &"tar_pit": tar}
		)
		var idx := 0
		var hashes: Array[int] = []
		while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
			while idx < actions.size() and int(actions[idx][0]) == model.tick:
				var entry: Array = actions[idx]
				model.apply_action(entry.slice(1))
				idx += 1
			model.step()
			if model.tick % 100 == 0:
				hashes.append(model.state_hash())
		hashes.append(model.state_hash())
		runs.append({
			"hashes": hashes,
			"outcome": [model.result, model.stars, model.leaked, model.killed, model.tick],
		})
	assert_eq(runs[0]["hashes"], runs[1]["hashes"], "hashes identical on a trap-heavy timeline")
	assert_eq(runs[0]["outcome"], runs[1]["outcome"], "identical terminal outcome")
	# dispatcher regressions: unknown verb still rejects without state change
	var probe := _make_model(_stage(), _config())
	_assert_rejected(probe, [&"warp", Vector2i(1, 1)], "unknown verb")
