extends SceneTree

const RuntimeContext := preload("res://sim/campaign_runtime_context.gd")
const CampaignStateV3 := preload("res://sim/campaign_state_v3.gd")
const BattleOutcomeV3 := preload("res://sim/battle_outcome_v3.gd")

var _failures: Array[String] = []


func _init() -> void:
	_test_survivor_xp_policy()
	if _failures.is_empty():
		print("RESIGN_XP_POLICY_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _test_survivor_xp_policy() -> void:
	var resigned := _resolve_survivor(&"resign", 8801)
	_check(not resigned.is_empty(), "resignation fixture did not resolve")
	if not resigned.is_empty():
		_check((resigned["resolution"]["xp_awards"] as Array).is_empty(), "resignation awarded survivor XP")
		_check(resigned["xp_after"] == resigned["xp_before"], "resignation changed survivor XP")

	var leaked := _resolve_survivor(&"leak_defeat", 8802)
	_check(not leaked.is_empty(), "ordinary defeat fixture did not resolve")
	if not leaked.is_empty():
		var awards: Array = leaked["resolution"]["xp_awards"]
		_check(awards.size() == 1, "ordinary defeat lost its survivor XP award")
		if awards.size() == 1:
			_check(int(awards[0]["delta"]) == 100, "ordinary defeat survivor award is not +100 XP")
		_check(leaked["xp_after"] == leaked["xp_before"] + 100, "ordinary defeat did not apply +100 survivor XP")


func _resolve_survivor(reason: StringName, seed: int) -> Dictionary:
	var context := RuntimeContext.build()
	var created: Dictionary = CampaignStateV3.create(seed, 1, context)
	_check(created.get("accepted", false), "%s campaign creation failed" % reason)
	if not created.get("accepted", false):
		return {}
	var state: Variant = created["value"]
	var ready: Array = state.runtime_projection()["ready_heroes"]
	var hero_id := String(ready[0]["hero_id"])
	var xp_before := int(ready[0]["xp"])
	var begin: Dictionary = state.begin_attempt(
		"resign-xp:begin:%s" % reason,
		"s1",
		[hero_id],
		seed + 100,
		state.save_revision(),
	)
	_check(begin.get("accepted", false), "%s begin attempt failed" % reason)
	if not begin.get("accepted", false):
		return {}
	state = _restore_mutation(begin, context)
	if state == null:
		return {}
	var ticket: Dictionary = state.data_copy()["tickets"][-1]
	var frozen: Dictionary = ticket["squad"][0]
	var outcome: Dictionary = BattleOutcomeV3.seal({
		"schema_version": BattleOutcomeV3.SCHEMA_VERSION,
		"attempt_id": ticket["attempt_id"],
		"ticket_hash": ticket["ticket_hash"],
		"result": "defeat",
		"terminal_reason": String(reason),
		"terminal_tick": 120,
		"stars": 0,
		"leaks": 4 if reason == &"leak_defeat" else 0,
		"kills": 3,
		"rows": [{
			"slot_index": frozen["slot_index"],
			"battle_id": frozen["battle_id"],
			"hero_id": frozen["hero_id"],
			"class_id": frozen["class_id"],
			"operator_def_id": frozen["operator_def_id"],
			"deployments": 1,
			"retreats": 0,
			"fell": false,
			"first_fall_tick": null,
		}],
	}, ticket)
	_check(outcome.get("accepted", false), "%s outcome sealing failed" % reason)
	if not outcome.get("accepted", false):
		return {}
	var resolved: Dictionary = state.resolve_attempt(
		"resign-xp:resolve:%s" % reason,
		ticket["attempt_id"],
		outcome["value"],
		state.save_revision(),
	)
	_check(resolved.get("accepted", false), "%s resolution failed" % reason)
	if not resolved.get("accepted", false):
		return {}
	state = _restore_mutation(resolved, context)
	if state == null:
		return {}
	var data: Dictionary = state.data_copy()
	var xp_after := -1
	for hero: Dictionary in data["heroes"]:
		if String(hero["hero_id"]) == hero_id:
			xp_after = int(hero["xp"])
			break
	return {
		"resolution": (data["last_resolution"] as Dictionary).duplicate(true),
		"xp_before": xp_before,
		"xp_after": xp_after,
	}


func _restore_mutation(command: Dictionary, context: Dictionary) -> Variant:
	var mutation: Variant = command.get("payload", {}).get("mutation")
	_check(mutation != null, "campaign command omitted its mutation")
	if mutation == null:
		return null
	var restored: Dictionary = CampaignStateV3.restore_source(
		mutation.prospective_save_text(), context,
	)
	_check(restored.get("accepted", false), "prospective campaign save did not restore")
	return restored.get("value") if restored.get("accepted", false) else null


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
