extends GutTest

## Phase 7 spell gate tests (td-phase-6-7.md §4.5, model-level). Paper
## derivations (written BEFORE the tests, per §4.9):
##   Cooldown (M1): cast at tick T sets ready_at_tick = T + cooldown_ticks;
##   run_timeline applies actions BEFORE the step of the same tick (T12), so
##   a bolt cast at 0 rejects through tick 899 and is accepted exactly at
##   tick 900.
##   Wave windows: wave_starts [0, 600] -> wave_index_of(t) = 0 for t < 600,
##   1 for t >= 600; a cast ON the wave-start tick is allowed.
##   Positions: a grunt spawned at s has advanced (T - 1 - s) steps of
##   33_333 when an action fires at tick T (spawn happens after the advance
##   pass of step s; the action precedes step T). Cell c spans
##   [c*1M, (c+1)*1M).

const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"
const MAX_TICKS := 20_000
const FAR_WAVE := {"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0}


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


func _spell_catalog() -> Dictionary:
	return {
		&"bolt": load("res://data/spells/bolt.tres") as SpellDef,
		&"charm": load("res://data/spells/charm.tres") as SpellDef,
	}


func _enemy_catalog() -> Dictionary:
	return {
		&"grunt": load("res://data/enemies/grunt.tres") as EnemyDef,
		&"runner": load("res://data/enemies/runner.tres") as EnemyDef,
		&"heavy": load("res://data/enemies/heavy.tres") as EnemyDef,
		&"drone": load("res://data/enemies/drone.tres") as EnemyDef,
		&"mini_boss": load("res://data/enemies/mini_boss.tres") as EnemyDef,
	}


func _make_model(stage: StageDef, config: GameConfig = _config()) -> BattleModel:
	var squad: Array[StringName] = []
	return BattleModel.create(stage, squad, 42, config, _enemy_catalog(), {}, {}, _spell_catalog())


func _assert_rejected(model: BattleModel, action: Array, label: String) -> void:
	var before := model.state_hash()
	assert_false(model.apply_action(action), label + " rejects")
	assert_eq(model.state_hash(), before, label + " leaves state untouched")


## §4.5.1 gate: bolt accepted at tick 0 (spells start ready), re-cast
## rejected through cast + 899 (boundary spot checks are hash-equal no-ops),
## accepted exactly at cast + 900.
func test_cooldown_ledger() -> void:
	var model := _make_model(_stage_with_waves([FAR_WAVE] as Array[Dictionary]))
	var target := Vector2i(3, 2)
	assert_true(model.apply_action([&"cast", &"bolt", target]), "bolt ready at tick 0")
	assert_eq(model.spell_book.ready_at(&"bolt"), 900, "ready_at = cast tick + cooldown")
	model.step()
	_assert_rejected(model, [&"cast", &"bolt", target], "re-cast at cast + 1")
	model.step(899 - model.tick)
	_assert_rejected(model, [&"cast", &"bolt", target], "re-cast at cast + 899")
	model.step()
	assert_eq(model.tick, 900)
	assert_true(model.apply_action([&"cast", &"bolt", target]), "accepted exactly at cast + 900")
	assert_eq(model.spell_book.casts(&"bolt"), 2)


## §4.5.2: Bolt hits exactly the Chebyshev-1 square around the target cell —
## grunts staged into seven distinct cells of the 3x3 (incl. diagonals) each
## take exactly 60 and die through the killed path; an aerial drone inside
## dies too (bursts are area denial); enemies at Chebyshev 2 and a charmed
## ally inside take 0. A bolt kill on the last enemy triggers CLEAR the
## same tick.
## Derivation: serpentine path (0,2)(1,2)(1,1)(1,0)(2,0)(3,0)(3,1)(3,2)
## (4,2)(5,2)(6,2) = 11 cells; bolt center (2,1) covers path indices 1-7.
## A grunt in cell c at tick 300 needs advances a in [30c+1, 30c+30]; with
## a = 30c+15, s = 299 - a = 284 - 30c. Drone (40_000/tick) in cell 4 needs
## a in [100, 124]; a = 112 -> s = 187. Charmed-inside: the cell-5 grunt
## (s = 134) charmed at 299 reverses to 5_433_279, still cell 5.
func test_bolt_exactness() -> void:
	var stage := _stage().duplicate(true) as StageDef
	stage.grid_rows = PackedStringArray(["GGGGGGGG", "GGEGGGGG", "SGGGGGB.", "GGGGGEGG", "GGGGGGGG"])
	var path := PackedVector2Array([
		Vector2(0, 2), Vector2(1, 2), Vector2(1, 1), Vector2(1, 0), Vector2(2, 0),
		Vector2(3, 0), Vector2(3, 1), Vector2(3, 2), Vector2(4, 2), Vector2(5, 2), Vector2(6, 2),
	])
	var paths: Array[PackedVector2Array] = [path]
	stage.paths = paths
	var waves: Array[Dictionary] = [FAR_WAVE]
	for c: int in range(1, 8):
		waves.append({"tick": 284 - 30 * c, "enemy_id": &"grunt", "path_idx": 0})
	waves.append({"tick": 44, "enemy_id": &"grunt", "path_idx": 0})
	waves.append({"tick": 284, "enemy_id": &"grunt", "path_idx": 0})
	waves.append({"tick": 187, "enemy_id": &"drone", "path_idx": 0})
	stage.waves = waves
	var model := _make_model(stage)
	model.step(299)
	var charm_target := -1
	var inside: Array[int] = []
	var outside: Array[int] = []
	var drone_id := -1
	for e: EnemyState in model.enemies:
		var cell := Pathing.cell_of(model.path_for(e.path_idx), e.progress_units)
		var dist := maxi(absi(cell.x - 2), absi(cell.y - 1))
		if e.def_id == &"drone":
			drone_id = e.id
		elif dist <= 1 and cell == Vector2i(3, 0):
			charm_target = e.id
		elif dist <= 1:
			inside.append(e.id)
		else:
			outside.append(e.id)
	assert_eq(inside.size(), 6, "six uncharmed grunts inside the 3x3")
	assert_eq(outside.size(), 2, "two grunts at Chebyshev 2")
	assert_true(model.apply_action([&"cast", &"charm", charm_target]), "charm the cell-5 grunt")
	model.step()
	assert_eq(model.tick, 300)
	assert_true(model.apply_action([&"cast", &"bolt", Vector2i(2, 1)]))
	for enemy_id: int in inside:
		assert_false(model.enemies[enemy_id].alive, "inside grunt %d died to exactly 60" % enemy_id)
	assert_false(model.enemies[drone_id].alive, "aerial drone inside dies too")
	for enemy_id: int in outside:
		assert_eq(model.enemies[enemy_id].hp, 40, "Chebyshev-2 grunt %d untouched" % enemy_id)
	assert_eq(model.enemies[charm_target].hp, 40, "charmed ally inside the burst takes 0")
	assert_eq(model.killed, 7, "6 grunts + 1 drone through the killed path")
	# CLEAR the same tick: bolt the last enemy of an exhausted timeline
	var solo_waves: Array[Dictionary] = [{"tick": 0, "enemy_id": &"grunt", "path_idx": 0}]
	var solo := _make_model(_stage_with_waves(solo_waves))
	solo.step(100)
	assert_true(solo.apply_action([&"cast", &"bolt", Vector2i(3, 2)]), "grunt at cell 3 at tick 100")
	assert_eq(solo.killed, 1)
	solo.step()
	assert_eq(solo.result, BattleModel.Result.CLEAR, "bolt kill on the last enemy clears same tick")


## §4.5.3 gate: once-per-wave over wave_starts [0, 600] — first charm at 590
## accepted (wave 0), 595 rejected (wave 0 used), 600 accepted (the
## wave-start tick itself opens wave 1), 601 rejected (wave 1 used). The two
## charmed allies (h0 from wave 0, g0 from wave 1) coexist and the charm
## ledger holds every tick.
## Derivation: h0 (heavy, s=300) at 590 has advanced 289 steps of 16_666 ->
## P = 4_816_474, alive (leak would be 721). g0 (grunt, s=400) leaks at 611,
## so it is alive at 600 with P = 199 * 33_333 = 6_633_267 and exits
## ceil(P / 33_333) = 200 reversal steps after 600 -> step 799. g1 (s=550)
## is the alive-and-valid target of the 601 rejection.
func test_once_per_wave() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 300, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 400, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 550, "enemy_id": &"grunt", "path_idx": 0},
		FAR_WAVE,
	]
	var stage := _stage_with_waves(entries)
	stage.wave_starts = PackedInt32Array([0, 600])
	var model := _make_model(stage)
	model.step(590)
	assert_true(model.apply_action([&"cast", &"charm", 0]), "wave-0 charm at 590")
	model.step(5)
	_assert_rejected(model, [&"cast", &"charm", 1], "second wave-0 charm at 595")
	model.step(5)
	assert_eq(model.tick, 600)
	assert_true(model.apply_action([&"cast", &"charm", 1]), "cast on the wave-start tick itself")
	model.step()
	_assert_rejected(model, [&"cast", &"charm", 2], "second wave-1 charm at 601")
	while model.tick < 1300:
		model.step()
		assert_eq(
			model.spawned,
			model.alive_enemy_count() + model.killed + model.leaked + model.charmed,
			"enemy books @ %d" % model.tick
		)
		assert_eq(
			model.charmed,
			model.alive_charmed_count() + model.charmed_dead + model.charmed_exited,
			"charm books @ %d" % model.tick
		)
		if model.tick == 650:
			assert_eq(model.alive_charmed_count(), 2, "allies from two waves coexist")
	assert_eq(model.charmed, 2)
	assert_eq(model.charmed_exited, 2, "both allies ran back out")
	assert_eq(model.charmed_dead, 0)


## §4.5.4: every invalid cast returns false with hash-equal state; target
## eligibility is asserted through cast_target_valid (the targeting
## cursor's own query) so the wave gate can't mask it.
func test_cast_rejections() -> void:
	var entries: Array[Dictionary] = [
		{"tick": 0, "enemy_id": &"heavy", "path_idx": 0},
		{"tick": 30, "enemy_id": &"grunt", "path_idx": 0},
		{"tick": 60, "enemy_id": &"drone", "path_idx": 0},
		{"tick": 90, "enemy_id": &"mini_boss", "path_idx": 0},
		FAR_WAVE,
	]
	var model := _make_model(_stage_with_waves(entries))
	_assert_rejected(model, [&"cast", &"nope", Vector2i(1, 1)], "unknown spell")
	_assert_rejected(model, [&"cast", &"bolt", Vector2i(99, 99)], "out-of-grid cell")
	_assert_rejected(model, [&"cast", &"bolt", Vector2i(-1, 0)], "negative cell")
	_assert_rejected(model, [&"cast", &"bolt", 3], "bolt with an enemy-id target")
	_assert_rejected(model, [&"cast", &"charm", Vector2i(1, 1)], "charm with a cell target")
	model.step(200)
	assert_true(model.apply_action([&"cast", &"charm", 0]), "heavy is charmable")
	assert_false(model.cast_target_valid(&"charm", 0), "already-charmed target ineligible")
	assert_false(model.cast_target_valid(&"charm", 2), "aerial drone ineligible")
	assert_false(model.cast_target_valid(&"charm", 3), "charm_immune mini_boss ineligible")
	assert_false(model.cast_target_valid(&"charm", 99), "unknown enemy id")
	model.step(41 + 300 - model.tick)
	assert_false(model.enemies[1].alive, "the grunt leaked at 241")
	assert_false(model.cast_target_valid(&"charm", 1), "dead target ineligible")
	_assert_rejected(model, [&"cast", &"charm", 1], "full verb on the dead target")
