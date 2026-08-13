extends GutTest

## Phase 13a gate tests (td-phase-13.md §3). Resign rides apply_action
## (rule 3/5) and is an IMMEDIATE result write (DC1): DEFEAT is observable
## at the tick it is applied and the next step() no-ops via the terminal
## early-return — the generic verb-at-T-observable-at-T+1 convention does
## not apply because nothing is derived by _check_terminal. Also pins the
## Q4 record guard: reward granting requires campaign_active, not just a
## non-null LegacyCampaignAdapter.

const STAGE_PATH := "res://data/stages/test_lane.tres"
const CONFIG_PATH := "res://data/config/game.tres"
const RESIGN_TICK := 60  # mid-wave on test_lane (first wave 30, first leak ~240)


func _config() -> GameConfig:
	return load(CONFIG_PATH) as GameConfig


func _stage() -> StageDef:
	return load(STAGE_PATH) as StageDef


func _catalog(dir_path: String) -> Dictionary:
	var defs: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	for file: String in dir.get_files():
		if file.ends_with(".tres"):
			var def: Resource = load(dir_path + "/" + file)
			defs[def.get("id")] = def
	return defs


func _enemy_catalog() -> Dictionary:
	return {&"grunt": load("res://data/enemies/grunt.tres") as EnemyDef}


func _make_model() -> BattleModel:
	return BattleModel.create(
		_stage(), [&"guard_1"] as Array[StringName], 42, _config(), _enemy_catalog(),
		_catalog("res://data/operators"), _catalog("res://data/traps"),
		_catalog("res://data/spells"),
	)


func _step_to(model: BattleModel, target_tick: int) -> void:
	while model.tick < target_tick and model.result == BattleModel.Result.RUNNING:
		model.step()


## §3.1: immediate acceptance — DEFEAT and stars 0 at the same tick.
func test_resign_is_immediate() -> void:
	var model := _make_model()
	_step_to(model, RESIGN_TICK)
	assert_eq(model.result, BattleModel.Result.RUNNING, "running before the resign")
	assert_true(model.apply_action([&"resign"]), "resign accepted")
	assert_eq(model.result, BattleModel.Result.DEFEAT, "DEFEAT immediately (DC1)")
	assert_eq(model.stars, 0, "resign is a 0-star defeat")
	assert_eq(model.tick, RESIGN_TICK, "observable at the applied tick, not T+1")


## §3.2: the next step() no-ops — tick frozen, hash byte-identical.
func test_step_after_resign_noops() -> void:
	var model := _make_model()
	_step_to(model, RESIGN_TICK)
	assert_true(model.apply_action([&"resign"]))
	var hash_after_resign := model.state_hash()
	model.step()
	assert_eq(model.tick, RESIGN_TICK, "tick frozen at the resign tick")
	assert_eq(model.state_hash(), hash_after_resign, "terminal step leaves state untouched")


## §3.3: terminal reject discipline — resign and player verbs reject
## hash-equal on a resigned battle; wrong arity rejects too.
func test_terminal_and_arity_rejects() -> void:
	var model := _make_model()
	_step_to(model, RESIGN_TICK)
	assert_false(model.apply_action([&"resign", 1]), "wrong arity rejects")
	assert_true(model.apply_action([&"resign"]))
	var before := model.state_hash()
	assert_false(model.apply_action([&"resign"]), "second resign rejects")
	assert_eq(model.state_hash(), before, "second resign leaves state untouched")
	assert_false(
		model.apply_action([&"deploy", &"guard_1", Vector2i(3, 2), int(UnitState.Facing.RIGHT)]),
		"deploy after resign rejects",
	)
	assert_eq(model.state_hash(), before, "rejected deploy leaves state untouched")


## §3.4: determinism oracle — the same stage+seed+squad with a resign at the
## same pinned tick replays to an identical hash trail and outcome.
func test_resign_timeline_is_deterministic() -> void:
	var a := _make_model()
	var b := _make_model()
	while a.tick < RESIGN_TICK and a.result == BattleModel.Result.RUNNING:
		a.step()
		b.step()
		if a.tick % 10 == 0:
			assert_eq(a.state_hash(), b.state_hash(), "hash trail identical at tick %d" % a.tick)
	assert_true(a.apply_action([&"resign"]))
	assert_true(b.apply_action([&"resign"]))
	assert_eq(a.state_hash(), b.state_hash(), "identical hash after the resign")
	assert_eq(a.result, BattleModel.Result.DEFEAT)
	assert_eq(b.result, BattleModel.Result.DEFEAT)


## §3.5: Q4 record guard — a stale LegacyCampaignAdapter grants nothing while
## campaign_active is false; an active campaign DEFEAT still records
## nothing. Game session fields are saved/restored explicitly
## (test_campaign_state.gd stays autoload-free by its own pin).
func test_record_result_requires_active_campaign() -> void:
	var game: Node = get_node("/root/Game")
	var saved_battle: BattleModel = game.get("current_battle")
	var saved_campaign: LegacyCampaignAdapter = game.get("campaign")
	var saved_active: bool = game.get("campaign_active")
	var saved_last: Dictionary = game.get("last_result")

	var stage := load("res://data/stages/s1.tres") as StageDef
	var model := BattleModel.create(
		stage, [&"guard_1"] as Array[StringName], 42, _config(), _enemy_catalog(),
		_catalog("res://data/operators"), _catalog("res://data/traps"),
		_catalog("res://data/spells"),
	)
	var campaign: LegacyCampaignAdapter = LegacyCampaignAdapter.create(
		game.call("_catalogs"), game.call("_all_stage_defs"),
	)
	game.set("current_battle", model)
	game.set("campaign", campaign)

	game.set("campaign_active", false)
	game.call("record_result", BattleModel.Result.CLEAR, 3)
	var last: Dictionary = game.get("last_result")
	assert_eq((last["rewards_granted"] as Array).size(), 0, "inactive campaign grants nothing")
	assert_false(campaign.stage_stars.has(&"s1"), "inactive campaign records no stars")

	game.set("campaign_active", true)
	game.call("record_result", BattleModel.Result.DEFEAT, 0)
	last = game.get("last_result")
	assert_eq((last["rewards_granted"] as Array).size(), 0, "DEFEAT grants nothing")
	assert_false(campaign.stage_stars.has(&"s1"), "DEFEAT records no stars")

	game.set("current_battle", saved_battle)
	game.set("campaign", saved_campaign)
	game.set("campaign_active", saved_active)
	game.set("last_result", saved_last)
