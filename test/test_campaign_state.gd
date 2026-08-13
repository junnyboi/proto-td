extends GutTest

## Phase 10 unlock-flow gates (td-phase-10.md §4.1) — pure CampaignState,
## no autoload, no residual state. Run against the LIVE catalogs and stage
## files so a roster or reward edit that breaks the campaign design fails
## loudly here.

var _catalogs: Dictionary = {}
var _stages: Array = []


func before_each() -> void:
	_catalogs = {
		"operators": _scan("res://data/operators"),
		"traps": _scan("res://data/traps"),
		"spells": _scan("res://data/spells"),
	}
	_stages = []
	for sid: StringName in _scan("res://data/stages"):
		_stages.append(load("res://data/stages/%s.tres" % sid) as StageDef)


func _scan(dir_path: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for f: String in DirAccess.open(dir_path).get_files():
		if f.ends_with(".tres"):
			ids.append(StringName(f.trim_suffix(".tres")))
	return ids


func _stage(sid: StringName) -> StageDef:
	for stage: StageDef in _stages:
		if stage.id == sid:
			return stage
	return null


func _fresh() -> CampaignState:
	return CampaignState.create(_catalogs, _stages)


## §4.1.1 gate: derivation exactness against the live data (K7 rosters).
func test_derivation_exactness() -> void:
	var starting := CampaignState.derive_starting_unlocks(_catalogs, _stages)
	var expected_ops: Array[StringName] = [
		&"caster_1", &"defender_1", &"defender_2", &"guard_1", &"vanguard_1",
	]
	assert_eq(starting["operators"], expected_ops, "exactly the five starting operators")
	assert_eq((starting["traps"] as Array).size(), 0, "no traps before S2's reward")
	assert_eq((starting["spells"] as Array).size(), 0, "no spells before S4's reward")


## §4.1.2: linear lock chain; DEFEAT unlocks nothing.
func test_lock_chain() -> void:
	var state := _fresh()
	assert_true(state.is_stage_unlocked(&"s1"))
	assert_false(state.is_stage_unlocked(&"s2"))
	assert_false(state.is_stage_unlocked(&"s8"))
	assert_true(state.is_stage_unlocked(&"test_lane"), "non-campaign stages are never locked")
	var defeat_grants := state.record_result(_stage(&"s1"), BattleModel.Result.DEFEAT, 0)
	assert_eq(defeat_grants.size(), 0)
	assert_false(state.is_stage_unlocked(&"s2"), "DEFEAT records no clear")
	state.record_result(_stage(&"s1"), BattleModel.Result.CLEAR, 2)
	assert_true(state.is_stage_unlocked(&"s2"))
	assert_false(state.is_stage_unlocked(&"s3"))


## §4.1.3: reward grant on first clear only; sets never grow on re-clear.
func test_reward_grant_idempotency() -> void:
	var state := _fresh()
	state.record_result(_stage(&"s1"), BattleModel.Result.CLEAR, 3)
	state.record_result(_stage(&"s2"), BattleModel.Result.CLEAR, 3)
	var granted := state.record_result(_stage(&"s3"), BattleModel.Result.CLEAR, 2)
	assert_eq(granted.size(), 2, "s3 grants exactly two rewards")
	assert_true(state.unlocked_operators.has(&"sniper_1"))
	assert_true(state.unlocked_traps.has(&"tar_pit"))
	var ops_before := state.unlocked_operators.size()
	var again := state.record_result(_stage(&"s3"), BattleModel.Result.CLEAR, 3)
	assert_eq(again.size(), 0, "re-clear grants nothing")
	assert_eq(state.unlocked_operators.size(), ops_before, "sets never grow on re-clear")


## §4.1.4: stars are best-of; DEFEAT after a clear changes nothing.
func test_star_best_of() -> void:
	var state := _fresh()
	state.record_result(_stage(&"s1"), BattleModel.Result.CLEAR, 2)
	assert_eq(int(state.stage_stars[&"s1"]), 2)
	state.record_result(_stage(&"s1"), BattleModel.Result.CLEAR, 3)
	assert_eq(int(state.stage_stars[&"s1"]), 3)
	state.record_result(_stage(&"s1"), BattleModel.Result.CLEAR, 1)
	assert_eq(int(state.stage_stars[&"s1"]), 3, "best-of keeps 3")
	state.record_result(_stage(&"s1"), BattleModel.Result.DEFEAT, 0)
	assert_eq(int(state.stage_stars[&"s1"]), 3, "DEFEAT changes nothing")


## §4.1.5: the whole chain end-to-end — Witch Doctor remains locked through
## S6, then the first S7 clear makes the full eleven-template catalog available.
func test_chain_integrity() -> void:
	var state := _fresh()
	for sid: StringName in [&"s1", &"s2", &"s3", &"s4", &"s5", &"s6"]:
		assert_true(state.is_stage_unlocked(sid), "%s unlocked in order" % sid)
		state.record_result(_stage(sid), BattleModel.Result.CLEAR, 2)
	assert_eq(state.unlocked_operators.size(), 10, "ten pre-healer operators after s6")
	assert_false(state.unlocked_operators.has(&"witch_doctor_1"))
	assert_eq(state.unlocked_traps.size(), 2)
	assert_eq(state.unlocked_spells.size(), 2)
	assert_eq(state.stage_stars.size(), 6)
	assert_true(state.is_stage_unlocked(&"s7"))
	var granted := state.record_result(_stage(&"s7"), BattleModel.Result.CLEAR, 2)
	assert_eq(granted, [{"kind": &"operator", "id": &"witch_doctor_1"}])
	assert_eq(state.unlocked_operators.size(), 11, "all eleven operators after s7")
	assert_true(state.unlocked_operators.has(&"witch_doctor_1"))
	assert_eq(state.record_result(_stage(&"s7"), BattleModel.Result.CLEAR, 3), [])
