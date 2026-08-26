extends Node

const RuntimeContext := preload("res://sim/campaign_runtime_context.gd")
const CampaignStateV3 := preload("res://sim/campaign_state_v3.gd")
const BattleOutcomeV3 := preload("res://sim/battle_outcome_v3.gd")


func _ready() -> void:
	call_deferred("_mount_fixture")


func _mount_fixture() -> void:
	var screen_id := OS.get_environment("ROSTER_DENSITY_SCREEN").strip_edges().to_lower()
	if screen_id.is_empty():
		screen_id = "mission"
	Game.set_run_seed(9917)
	if not Game.start_campaign(false, true):
		push_error("roster density fixture could not start campaign")
		return
	Game.selected_stage_id = &"s1"
	match screen_id:
		"mission":
			_mount("res://scenes/squad_select.tscn")
		"gacha":
			_mount("res://scenes/gacha.tscn")
		"vahalla":
			var fallen: Variant = _campaign_with_one_fallen()
			if fallen == null:
				push_error("roster density fixture could not create fallen operator")
				return
			Game.campaign = fallen
			Game.campaign_active = true
			_mount("res://scenes/vahalla.tscn")
		"results", "results-defeat":
			var projection: Dictionary = Game.campaign_projection()
			var ready_heroes: Array = projection.get("ready_heroes", [])
			var hero_id := String(ready_heroes[0].get("hero_id", ""))
			var survivor_id := String(ready_heroes[1].get("hero_id", "")) if ready_heroes.size() > 1 else hero_id
			var defeated := screen_id == "results-defeat"
			Game.last_result = {
				"stage_id": &"s1",
				"result": BattleModel.Result.DEFEAT if defeated else BattleModel.Result.CLEAR,
				"stars": 0 if defeated else 3,
				"kills": 4 if defeated else 14,
				"leaks": 12 if defeated else 0,
				"rewards_granted": [{"kind": "currency", "id": "marks", "amount": 7 if defeated else 40}],
				"class_entitlements_granted": [] if defeated else [&"mage_apprentice"],
				"xp_awards": [{"hero_id": survivor_id if defeated else hero_id, "delta": 100}],
				"dead_hero_ids": [hero_id] if defeated else [],
				"premium_life_losses": [],
			}
			_mount("res://scenes/results.tscn")
		"staging":
			_mount("res://scenes/staging.tscn")
		"battle":
			Game.start_battle(&"s1", true)
			await get_tree().process_frame
			await get_tree().process_frame
			var skip := get_tree().root.find_child("SkipTutorial", true, false) as Button
			if skip != null:
				skip.pressed.emit()
		_:
			push_error("unknown roster density screen: %s" % screen_id)


func _mount(path: String) -> void:
	var screen: Node = load(path).instantiate()
	add_child(screen)


func _campaign_with_one_fallen() -> Variant:
	var context := RuntimeContext.build()
	var created: Dictionary = CampaignStateV3.create(31337, 1, context)
	if not bool(created.get("accepted", false)):
		return null
	var state: Variant = created["value"]
	var initial: Dictionary = state.runtime_projection()
	var hero_id := String(initial["ready_heroes"][0]["hero_id"])
	var begin: Dictionary = state.begin_attempt(
		"visual:roster-density:begin", "s1", [hero_id], 404, state.save_revision(),
	)
	if not bool(begin.get("accepted", false)):
		return null
	state = _restore_mutation(begin, context)
	if state == null:
		return null
	var ticket: Dictionary = state.data_copy()["tickets"][-1]
	var frozen: Dictionary = ticket["squad"][0]
	var outcome := BattleOutcomeV3.seal({
		"schema_version": BattleOutcomeV3.SCHEMA_VERSION,
		"attempt_id": ticket["attempt_id"],
		"ticket_hash": ticket["ticket_hash"],
		"result": "defeat",
		"terminal_reason": "resign",
		"terminal_tick": 20,
		"stars": 0,
		"leaks": 0,
		"kills": 0,
		"rows": [{
			"slot_index": frozen["slot_index"],
			"battle_id": frozen["battle_id"],
			"hero_id": frozen["hero_id"],
			"class_id": frozen["class_id"],
			"operator_def_id": frozen["operator_def_id"],
			"deployments": 1,
			"retreats": 0,
			"fell": true,
			"first_fall_tick": 10,
		}],
	}, ticket)
	if not bool(outcome.get("accepted", false)):
		return null
	var resolved: Dictionary = state.resolve_attempt(
		"visual:roster-density:resolve",
		ticket["attempt_id"],
		outcome["value"],
		state.save_revision(),
	)
	return _restore_mutation(resolved, context) if bool(resolved.get("accepted", false)) else null


func _restore_mutation(command: Dictionary, context: Dictionary) -> Variant:
	var mutation: Variant = command.get("payload", {}).get("mutation")
	if mutation == null:
		return null
	var restored: Dictionary = CampaignStateV3.restore_source(
		mutation.prospective_save_text(), context,
	)
	return restored.get("value") if bool(restored.get("accepted", false)) else null
