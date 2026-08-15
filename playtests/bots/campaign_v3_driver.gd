class_name CampaignV3Driver
extends RefCounted

## Deterministic Phase 4 campaign driver. One step performs one bounded battle or
## promotion checkpoint; every strategic transition commits through Game and
## SaveStore. No debug grants, adapter rewards, or direct state writes.

const CONFIG := preload("res://data/config/game.tres")
const CLASS_SCRIPT := preload("res://data/class_def.gd")
const TRAINING_GOALS := [
	{"class_id": "shock_trooper", "operator_id": "vanguard_1"},
	{"class_id": "swordmaster", "operator_id": "guard_1"},
	{"class_id": "defender", "operator_id": "defender_1"},
	{"class_id": "gunner", "operator_id": "sniper_1"},
	{"class_id": "mage_apprentice", "operator_id": "caster_1"},
]
const ADVANCED_BY_STAGE := {
	"s6":
	[
		{"from": "guard_1", "class_id": "sword_saint"},
		{"from": "defender_1", "class_id": "immovable"},
	],
	"s8": [{"from": "caster_1", "class_id": "sorcerer"}],
}
const TRAINING_BY_OPERATOR := {
	"vanguard_1": {"first": "shock_trooper", "final": "shock_trooper", "clears": 1},
	"guard_1": {"first": "swordmaster", "final": "swordmaster", "clears": 1},
	"defender_1": {"first": "defender", "final": "defender", "clears": 1},
	"sniper_1": {"first": "gunner", "final": "gunner", "clears": 1},
	"caster_1": {"first": "mage_apprentice", "final": "mage_apprentice", "clears": 1},
	"guard_2": {"first": "swordmaster", "final": "sword_saint", "clears": 4},
	"defender_2": {"first": "defender", "final": "immovable", "clears": 4},
	"caster_2": {"first": "mage_apprentice", "final": "sorcerer", "clears": 4},
}
const GROUND_OPERATORS := [
	"vanguard_1",
	"vanguard_2",
	"guard_1",
	"guard_2",
	"defender_1",
	"defender_2",
	"recruit",
]
const LOW_COST_SCREENERS := ["recruit", "vanguard_1", "vanguard_2"]
const PRESERVATION_ACTIONS := {
	"s2": [[753, &"retreat", 0]],
	"s4": [[563, &"retreat", 0]],
	"s5": [[720, &"retreat", 2], [750, &"retreat", 1], [1400, &"retreat", 3]],
	"s6": [[563, &"retreat", 0], [1250, &"retreat", 3]],
	"s7": [[563, &"retreat", 0], [1060, &"retreat", 1], [1650, &"retreat", 5]],
}
const CAMPAIGN_STAGE_SQUADS := {
	"s6": ["vanguard_1", "guard_2", "recruit", "caster_1"],
	"s7": ["vanguard_1", "guard_2", "sniper_1", "defender_2", "recruit", "caster_1"],
	"s8": ["vanguard_1", "guard_2", "sniper_1", "defender_2", "caster_2"],
}
const TIMELINE_OPERATOR_MAPS := {
	"s6": {"guard_1": "guard_2", "guard_2": "recruit"},
	"s7": {"guard_1": "guard_2", "guard_2": "recruit", "defender_1": "defender_2"},
	"s8": {"guard_1": "guard_2"},
}
const TIMELINE_DEPLOY_TICKS := {
	"s6": {"guard_1": 450},
	"s7": {"guard_1": 360, "sniper_1": 550, "defender_1": 980},
	"s8": {"guard_1": 360, "defender_2": 1080, "caster_2": 1680},
}
const CAMPAIGN_EXTRA_ACTIONS := {
	"s6": [[1100, &"deploy", &"caster_1", Vector2i(5, 1), 0]],
	"s7": [[1500, &"deploy", &"caster_1", Vector2i(8, 1), 0]],
}
const MAX_BATTLE_TICKS := 6_000

var failed := false
var error := ""
var completed := false
var stage_clears: Array[StringName] = []
var training_clears := 0
var promotions := 0
var replacements := 0
var command_count := 0

var _started := false
var _training_goal := 0
var _training_target := ""
var _training_target_clears := 0
var _preserve_training_screeners := false
var _stage_index := 1
var _recovery_recruit_used := false
var _contract_recruit_used := false
var _operators: Dictionary = {}
var _enemies: Dictionary = {}
var _traps: Dictionary = {}
var _spells: Dictionary = {}


func step(game: Node) -> void:
	if failed or completed:
		return
	if not _started:
		_started = true
		if not game.start_campaign(false, true):
			_fail("fresh campaign start rejected")
			return
		_cache_catalogs()
		return
	if _training_goal < TRAINING_GOALS.size():
		_train_one_clear(game)
		return
	if _stage_index >= 8:
		completed = true
		return
	var stage_number := _stage_index + 1
	var stage_id := StringName("s%d" % stage_number)
	if ADVANCED_BY_STAGE.has(String(stage_id)):
		for spec: Dictionary in ADVANCED_BY_STAGE[String(stage_id)]:
			if not _promote_operator(game, spec["from"], spec["class_id"]):
				return
	var bot := _stage_bot(stage_number)
	if _run_stage_bot(game, bot):
		if _replace_last_casualties(game):
			stage_clears.append(stage_id)
			_stage_index += 1
			print("[CAMPAIGN_V3] %s durably cleared" % stage_id)


func _train_one_clear(game: Node) -> void:
	var goal: Dictionary = TRAINING_GOALS[_training_goal]
	var prepared := _prepare_training(game, goal)
	if not prepared["accepted"]:
		return
	if not _run_battle(game, &"s1", prepared["hero_ids"], prepared["timeline"]):
		return
	training_clears += 1
	if not _replace_last_casualties(game):
		return
	if _promote_training_survivors(game) <= 0 and not failed:
		_fail("S1 produced no XP-eligible Recruit survivor")


func _prepare_training(game: Node, goal: Dictionary) -> Dictionary:
	var required_recruits := 1 if _training_target.is_empty() else 0
	if not _ensure_recruit_pool(game, required_recruits):
		return {"accepted": false}
	if _training_target.is_empty():
		var recruit := _ready_hero_by_operator(game, "recruit")
		if recruit.is_empty():
			_fail("no ready Recruit available for %s" % goal["class_id"])
			return {"accepted": false}
		_training_target = recruit["hero_id"]
		_training_target_clears = 0
	var target := _hero_by_id(game, _training_target)
	if target.is_empty() or target["life_status"] != "ready":
		_fail("training target unavailable: %s" % _training_target)
		return {"accepted": false}
	var expendable := _training_screeners(game)
	if expendable.size() != 2:
		_fail("training requires two ready Recruit screeners")
		return {"accepted": false}
	var target_operator := String(target["operator_def_id"])
	var first_track := _training_goal == 0
	var target_cell := (
		Vector2i(3, 1)
		if target_operator in ["sniper_1", "caster_1"]
		else (Vector2i(2, 2) if first_track else Vector2i(5, 2))
	)
	var timeline: Array
	if first_track:
		timeline = [
			[6, &"deploy_slot", 0, Vector2i(3, 2), 0],
			[180, &"deploy_slot", 1, Vector2i(1, 2), 0],
			[420, &"deploy_slot", 2, target_cell, 0],
			[860, &"retreat", 1],
			[1040, &"retreat", 0],
		]
	elif _preserve_training_screeners:
		timeline = [
			[6, &"deploy_slot", 0, Vector2i(3, 2), 0],
			[450, &"deploy_slot", 1, Vector2i(4, 2), 0],
			[800, &"deploy_slot", 2, target_cell, 0],
		]
	else:
		timeline = [
			[6, &"deploy_slot", 0, Vector2i(3, 2), 0],
			[450, &"deploy_slot", 1, Vector2i(4, 2), 0],
			[800, &"deploy_slot", 2, target_cell, 0],
		]
	return {
		"accepted": true,
		"hero_ids":
		(
			[
				StringName(expendable[0]),
				StringName(expendable[1]),
				StringName(_training_target),
			]
			as Array[StringName]
		),
		"timeline": timeline,
	}


func _promote_training_survivors(game: Node) -> int:
	var candidates: Array[String] = [_training_target]
	for hero: Dictionary in game.campaign.data_copy()["heroes"]:
		if (
			hero["life_status"] == "ready"
			and hero["operator_def_id"] == "recruit"
			and int(hero["xp"]) >= 100
			and not candidates.has(hero["hero_id"])
		):
			candidates.append(hero["hero_id"])
	var promoted_now := 0
	for hero_id: String in candidates:
		if _training_goal >= TRAINING_GOALS.size():
			break
		var hero := _hero_by_id(game, hero_id)
		if hero.is_empty() or hero["operator_def_id"] != "recruit" or int(hero["xp"]) < 100:
			continue
		var goal: Dictionary = TRAINING_GOALS[_training_goal]
		if not _promote_hero(game, hero_id, goal["class_id"]):
			return -1
		var trained := _hero_by_id(game, hero_id)
		if trained.get("operator_def_id", "") != goal["operator_id"]:
			_fail("training class mismatch for %s" % goal["class_id"])
			return -1
		if _training_goal == 0:
			stage_clears.append(&"s1")
		_training_goal += 1
		promoted_now += 1
		print("[CAMPAIGN_V3] trained %s through a real S1 clear" % goal["class_id"])
	_training_target = ""
	_training_target_clears = 0
	return promoted_now


func _training_screeners(game: Node) -> Array[String]:
	var ready: Array = game.campaign.data_copy()["heroes"]
	var result: Array[String] = []
	for operator_id: String in LOW_COST_SCREENERS:
		for hero: Dictionary in ready:
			if (
				hero["life_status"] == "ready"
				and hero["hero_id"] != _training_target
				and hero["operator_def_id"] == operator_id
			):
				result.append(hero["hero_id"])
				if result.size() == 2:
					break
		if result.size() == 2:
			break
	for operator_id: String in GROUND_OPERATORS:
		if result.size() == 2:
			break
		for hero: Dictionary in ready:
			if (
				hero["life_status"] == "ready"
				and hero["hero_id"] != _training_target
				and not result.has(hero["hero_id"])
				and hero["operator_def_id"] == operator_id
			):
				result.append(hero["hero_id"])
				break
	for hero: Dictionary in ready:
		if (
			result.size() < 2
			and hero["life_status"] == "ready"
			and hero["hero_id"] != _training_target
			and not result.has(hero["hero_id"])
			and hero["operator_def_id"] in GROUND_OPERATORS
		):
			result.append(hero["hero_id"])
	return result


func _ensure_recruit_pool(game: Node, minimum: int) -> bool:
	while _ready_recruit_count(game) < minimum:
		var source := ""
		var source_id := ""
		if not _recovery_recruit_used:
			source = "recovery"
			source_id = "s1"
			_recovery_recruit_used = true
		elif not _contract_recruit_used:
			source = "contract"
			source_id = "p16_caster_contract"
			_contract_recruit_used = true
		else:
			return _fail("Recruit support paths exhausted")
		var command: Dictionary = (
			game
			. campaign
			. recruit_person(
				_next_command_id(source),
				game.campaign.save_revision(),
				source,
				source_id,
			)
		)
		var committed: Dictionary = game.commit_campaign_command(command)
		if not committed["accepted"]:
			return _fail("%s Recruit rejected: %s" % [source, committed["error_code"]])
	return true


func _ready_recruit_count(game: Node) -> int:
	var count := 0
	for hero: Dictionary in game.campaign.data_copy()["heroes"]:
		if hero["life_status"] == "ready" and hero["operator_def_id"] == "recruit":
			count += 1
	return count


func _run_stage_bot(game: Node, bot: StageBot) -> bool:
	var stage_key := String(bot.stage_id())
	var requested_squad: Array = CAMPAIGN_STAGE_SQUADS.get(stage_key, bot.squad())
	var hero_ids: Array[StringName] = []
	for operator_value: Variant in requested_squad:
		var operator_id := String(operator_value)
		var hero := _ready_hero_by_operator(game, operator_id)
		if hero.is_empty():
			if operator_id == "recruit" and not _ensure_recruit_pool(game, 1):
				return false
			hero = _ready_hero_by_operator(game, operator_id)
		if hero.is_empty():
			print("[CAMPAIGN_V3] restoring %s for %s" % [operator_id, bot.stage_id()])
			if not _restore_operator(game, operator_id):
				return false
			hero = _ready_hero_by_operator(game, operator_id)
			if hero.is_empty():
				return _fail("%s missing retrained %s" % [bot.stage_id(), operator_id])
		hero_ids.append(StringName(hero["hero_id"]))
	var timeline: Array = []
	for row: Array in bot.timeline():
		var adapted: Array = row.duplicate(true)
		if adapted[1] == &"deploy":
			var source_operator := String(adapted[2])
			var tick_map: Dictionary = TIMELINE_DEPLOY_TICKS.get(stage_key, {})
			adapted[0] = int(tick_map.get(source_operator, adapted[0]))
			var operator_map: Dictionary = TIMELINE_OPERATOR_MAPS.get(stage_key, {})
			adapted[2] = StringName(operator_map.get(source_operator, source_operator))
		timeline.append(adapted)
	for row: Array in PRESERVATION_ACTIONS.get(stage_key, []):
		timeline.append(row.duplicate(true))
	for row: Array in CAMPAIGN_EXTRA_ACTIONS.get(stage_key, []):
		timeline.append(row.duplicate(true))
	timeline.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	return _run_battle(game, bot.stage_id(), hero_ids, timeline)


func _restore_operator(game: Node, operator_id: String) -> bool:
	if not TRAINING_BY_OPERATOR.has(operator_id):
		return _fail("no real-command training path for %s" % operator_id)
	var spec: Dictionary = TRAINING_BY_OPERATOR[operator_id]
	if not _ensure_recruit_pool(game, 3):
		return false
	var recruit := _ready_hero_by_operator(game, "recruit")
	_training_target = recruit["hero_id"]
	_training_target_clears = 0
	_preserve_training_screeners = true
	for clear_index: int in int(spec["clears"]):
		var prepared := _prepare_training(game, {"class_id": spec["final"]})
		if (
			not prepared["accepted"]
			or not _run_battle(game, &"s1", prepared["hero_ids"], prepared["timeline"])
		):
			_preserve_training_screeners = false
			return false
		training_clears += 1
		_training_target_clears += 1
		if (
			(clear_index == 0 and not _promote_hero(game, _training_target, spec["first"]))
			or not _replace_last_casualties(game)
		):
			_preserve_training_screeners = false
			return false
	if spec["final"] != spec["first"]:
		if not _promote_hero(game, _training_target, spec["final"]):
			_preserve_training_screeners = false
			return false
	_preserve_training_screeners = false
	_training_target = ""
	_training_target_clears = 0
	print("[CAMPAIGN_V3] retrained fallen %s" % operator_id)
	return true


func _run_battle(
	game: Node,
	stage_id: StringName,
	hero_ids: Array[StringName],
	timeline: Array,
) -> bool:
	var prepared := _prepare_battle(game, stage_id, hero_ids, timeline)
	if not prepared["accepted"]:
		return false
	var model: BattleModel = prepared["model"]
	var action_index := 0
	var rows: Array = prepared["timeline"]
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_BATTLE_TICKS:
		while action_index < rows.size() and int(rows[action_index][0]) == model.tick:
			if not model.apply_action((rows[action_index] as Array).slice(1)):
				return _fail(
					(
						"%s rejected action %s snapshot=%s"
						% [stage_id, rows[action_index], model.snapshot()]
					)
				)
			action_index += 1
		model.step()
	if action_index != rows.size() or model.result != BattleModel.Result.CLEAR:
		return _fail("%s failed at tick %d" % [stage_id, model.tick])
	game.current_battle = model
	if not game.record_result(model.result, model.stars):
		return _fail("%s resolution did not commit: %s" % [stage_id, game.last_campaign_error])
	command_count += 2
	return true


func _prepare_battle(
	game: Node,
	stage_id: StringName,
	hero_ids: Array[StringName],
	timeline: Array,
) -> Dictionary:
	if not game.is_stage_unlocked(stage_id):
		_fail("locked stage requested: %s" % stage_id)
		return {"accepted": false}
	var begun: Dictionary = game.start_stage(stage_id, hero_ids, false)
	if not begun["accepted"]:
		_fail("begin %s rejected: %s" % [stage_id, begun["error_code"]])
		return {"accepted": false}
	var launch: Dictionary = game.battle_launch()
	var ticket: Dictionary = launch["input"]
	var adapted := _adapt_timeline(timeline, ticket)
	if not adapted["accepted"]:
		_fail(adapted["error"])
		return {"accepted": false}
	var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
	var model := (
		BattleModel
		. create(
			stage,
			ticket,
			game.run_seed,
			CONFIG as GameConfig,
			_enemies,
			_operators,
			_traps,
			_spells,
			launch["trusted_ticket_hashes"],
		)
	)
	if model == null:
		_fail("BattleModel rejected committed ticket for %s" % stage_id)
		return {"accepted": false}
	return {"accepted": true, "model": model, "timeline": adapted["timeline"]}


func _adapt_timeline(timeline: Array, ticket: Dictionary) -> Dictionary:
	var queues := {}
	for row: Dictionary in ticket["squad"]:
		var operator_id := String(row["operator_def_id"])
		if not queues.has(operator_id):
			queues[operator_id] = []
		queues[operator_id].append(StringName(row["battle_id"]))
	var result: Array = []
	for source: Array in timeline:
		var row: Array = source.duplicate(true)
		if row[1] == &"deploy_slot":
			var slot := int(row[2])
			row[1] = &"deploy"
			row[2] = StringName(ticket["squad"][slot]["battle_id"])
		elif row[1] == &"deploy":
			var operator_id := String(row[2])
			if not queues.has(operator_id) or queues[operator_id].is_empty():
				return {"accepted": false, "error": "ticket missing %s" % operator_id}
			row[2] = queues[operator_id].pop_front()
		result.append(row)
	return {"accepted": true, "error": "", "timeline": result}


func _replace_last_casualties(game: Node) -> bool:
	for hero_id: String in game.last_result["dead_hero_ids"]:
		var command_id := _next_command_id("replace")
		var command: Dictionary = (
			game
			. campaign
			. recruit_person(
				command_id,
				game.campaign.save_revision(),
				"replacement",
				hero_id,
			)
		)
		var committed: Dictionary = game.commit_campaign_command(command)
		if not committed["accepted"]:
			return _fail("replacement rejected for %s: %s" % [hero_id, committed["error_code"]])
		replacements += 1
	return true


func _promote_operator(game: Node, operator_id: String, class_id: String) -> bool:
	var hero := _ready_hero_by_operator(game, operator_id)
	if hero.is_empty():
		if not _restore_operator(game, operator_id):
			return false
		hero = _ready_hero_by_operator(game, operator_id)
		if hero.is_empty():
			return _fail("promotion source missing after retraining: %s" % operator_id)
	while int(hero["xp"]) < CLASS_SCRIPT.ADVANCED_PROMOTION_XP_REQUIRED:
		if not _train_existing_hero(game, hero["hero_id"]):
			return false
		hero = _hero_by_id(game, hero["hero_id"])
	return _promote_hero(game, hero["hero_id"], class_id)


func _train_existing_hero(game: Node, hero_id: String) -> bool:
	if not _ensure_recruit_pool(game, 3):
		return false
	_training_target = hero_id
	_training_target_clears = 0
	_preserve_training_screeners = true
	var prepared := _prepare_training(game, {"class_id": "advanced"})
	if (
		not prepared["accepted"]
		or not _run_battle(game, &"s1", prepared["hero_ids"], prepared["timeline"])
	):
		_preserve_training_screeners = false
		return false
	training_clears += 1
	_training_target_clears += 1
	_preserve_training_screeners = false
	_training_target = ""
	return _replace_last_casualties(game)


func _promote_hero(game: Node, hero_id: String, class_id: String) -> bool:
	var command: Dictionary = (
		game
		. campaign
		. confirm_promotions(
			_next_command_id("promote"),
			game.campaign.save_revision(),
			[{"hero_id": hero_id, "to_class_id": class_id}],
		)
	)
	var committed: Dictionary = game.commit_campaign_command(command)
	if not committed["accepted"]:
		return _fail("promotion to %s rejected: %s" % [class_id, committed["error_code"]])
	promotions += 1
	return true


func _ready_hero_by_operator(game: Node, operator_id: String) -> Dictionary:
	for hero: Dictionary in game.campaign.data_copy()["heroes"]:
		if hero["life_status"] == "ready" and hero["operator_def_id"] == operator_id:
			return hero
	return {}


func _hero_by_id(game: Node, hero_id: String) -> Dictionary:
	for hero: Dictionary in game.campaign.data_copy()["heroes"]:
		if hero["hero_id"] == hero_id:
			return hero
	return {}


func _stage_bot(index: int) -> StageBot:
	var script: GDScript = load("res://playtests/bots/bot_stage_0%d.gd" % index)
	return script.new()


func _cache_catalogs() -> void:
	_operators = _catalog("res://data/operators")
	_enemies = _catalog("res://data/enemies")
	_traps = _catalog("res://data/traps")
	_spells = _catalog("res://data/spells")


func _catalog(path: String) -> Dictionary:
	var result := {}
	var directory := DirAccess.open(path)
	for filename: String in directory.get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var resource: Resource = load("%s/%s" % [path, source])
			result[resource.get("id")] = resource
	return result


func _next_command_id(prefix: String) -> String:
	command_count += 1
	return "campaign-bot:%s:%d" % [prefix, command_count]


func _fail(message: String) -> bool:
	failed = true
	error = message
	push_error("[CAMPAIGN_V3] " + message)
	return false
