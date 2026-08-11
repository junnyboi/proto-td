extends GutTest

## P14 exactness: same-tick timeline entries apply in AUTHORED order.
## Godot's introsort preserves equal keys only <=16 elements (measured:
## permutes at >=20), so run_timeline carries an index tie-break. This
## suite drives 24 rows — above the threshold — where order is observable
## through existing model state: each burst is [debug_set_dp, deploy A to
## cX, deploy B to cX (rejects: occupied), deploy C to cY]; if the sort
## moved debug_set_dp after the deploys they would reject on DP, and if A/B
## swapped the winner at cX would change. dp_spent is exact only in the
## authored order.

const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"
const FAR_WAVE := {"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0}
const CX := Vector2i(3, 2)
const CY := Vector2i(4, 2)


func _catalog(dir_path: String) -> Dictionary:
	var defs: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	for file: String in dir.get_files():
		if file.ends_with(".tres"):
			var def: Resource = load(dir_path + "/" + file)
			defs[def.get("id")] = def
	return defs


func _make_model() -> BattleModel:
	var stage := (load(STAGE_PATH) as StageDef).duplicate(true) as StageDef
	var waves: Array[Dictionary] = [FAR_WAVE]
	stage.waves = waves
	var squad: Array[StringName] = [&"vanguard_1", &"guard_1", &"defender_1"]
	return BattleModel.create(
		stage, squad, 42, load(CONFIG_PATH) as GameConfig,
		{&"grunt": load("res://data/enemies/grunt.tres") as EnemyDef},
		_catalog("res://data/operators"), _catalog("res://data/traps"),
		_catalog("res://data/spells"),
	)


## Burst rows for tick t. Same-tick order is load-bearing: set_dp FIRST
## (without it dp is too low for the burst), the cX winner SECOND, the cX
## loser THIRD (must reject on occupancy), cY LAST.
func _burst(t: int) -> Array:
	return [
		[t, &"debug_set_dp", 99],
		[t, &"deploy", &"vanguard_1", CX, int(UnitState.Facing.RIGHT)],
		[t, &"deploy", &"guard_1", CX, int(UnitState.Facing.RIGHT)],
		[t, &"deploy", &"defender_1", CY, int(UnitState.Facing.RIGHT)],
	]


## Retreat rows: the two deploys of the previous burst (ids are sequential
## and deterministic), padded with two order-insensitive rows to keep every
## group at 4 entries (24 rows total).
func _retreats(t: int, id_a: int, id_b: int) -> Array:
	return [
		[t, &"retreat", id_a],
		[t, &"retreat", id_b],
		[t, &"debug_set_dp", 50],
		[t, &"debug_set_dp", 60],
	]


func test_24_row_same_tick_timeline_preserves_authored_order() -> void:
	var groups: Array = [
		_burst(10),
		_retreats(20, 0, 1),
		_burst(30),
		_retreats(40, 2, 3),
		_burst(50),
		_retreats(60, 4, 5),
	]
	# feed tick-groups in scrambled order (the sort must order ticks) while
	# each group's internal, same-tick order stays exactly as authored
	var scrambled: Array = []
	for gi: int in [4, 1, 5, 0, 3, 2]:
		scrambled.append_array(groups[gi])
	assert_eq(scrambled.size(), 24)
	var m := _make_model()
	m.run_timeline(scrambled, 70)
	assert_eq(m.result, BattleModel.Result.RUNNING)
	# authored-order evidence: every burst deployed exactly vanguard(8) +
	# defender(16) — dp_spent is 72 ONLY in the authored order (set_dp
	# sorted after the deploys, or guard winning cX, both change it)
	assert_eq(m.dp_spent, 72, "dp_spent = 3 x (8 + 16), authored order only")
	assert_eq(m.retreated, 6, "all six deployed units retreated")
	assert_eq(m.alive_count(), 0)


func test_small_timeline_unchanged() -> void:
	# regression guard for the pre-P14 shape: small, distinct-tick timelines
	# (every shipped bot) behave identically
	var m := _make_model()
	var rows: Array = [
		[10, &"debug_set_dp", 99],
		[12, &"deploy", &"vanguard_1", CX, int(UnitState.Facing.RIGHT)],
		[14, &"deploy", &"defender_1", CY, int(UnitState.Facing.DOWN)],
	]
	m.run_timeline(rows, 20)
	assert_not_null(m.alive_unit_at(CX))
	assert_not_null(m.alive_unit_at(CY))
	assert_eq(m.dp_spent, 24, "vanguard 8 + defender 16")
