extends SceneTree

const CampaignRuntimeAuthorityScript := preload("res://sim/campaign_runtime_authority.gd")
const BattleOutcomeV3Script := preload("res://sim/battle_outcome_v3.gd")


var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 50505)
	_check(bool(game.call("start_campaign", false, true)), "campaign fixture failed")
	if not bool(game.get("campaign_active")):
		_finish()
		return
	for stage_id: StringName in [&"s1", &"s2", &"s3", &"s4"]:
		_check(await _clear_stage(game, stage_id), "%s clear fixture failed" % stage_id)
		if not _failures.is_empty():
			_cleanup(game)
			_finish()
			return
	var projection: Dictionary = game.call("campaign_projection")
	var ready: Array = projection.get("ready_heroes", [])
	_check(ready.size() >= 5, "Mission 5 fixture has fewer than five ready heroes")
	if ready.size() < 5:
		_cleanup(game)
		_finish()
		return
	var selected: Array[StringName] = []
	for index: int in range(5):
		selected.append(StringName(ready[index]["hero_id"]))
	var slot_dir := ProjectSettings.globalize_path("user://")
	_check(OS.execute("chmod", ["500", slot_dir]) == 0, "could not arm Mission 5 save fault")
	var revision_before := int(game.call("campaign_projection").get("save_revision", -1))
	var rejected: Dictionary = game.call("start_stage", &"s5", selected, false)
	_check(OS.execute("chmod", ["700", slot_dir]) == 0, "could not disarm Mission 5 save fault")
	_check(not rejected.get("accepted", false), "faulted Mission 5 launch was accepted")
	_check(
		rejected.get("error_code") == &"store_write_failed",
		"Mission 5 exposed the wrong save error: %s" % rejected.get("error_code", &"unknown"),
	)
	_check(rejected.get("retryable", false), "Mission 5 save failure was not retryable")
	_check(bool(game.call("mission_launch_retry_pending")), "Mission 5 did not retain the exact retry mutation")
	_check(bool(game.call("strategic_mutation_pending")), "pending Mission 5 retry did not serialize strategic mutations")
	_check(int(game.call("campaign_projection").get("save_revision", -1)) == revision_before, "rejected Mission 5 launch advanced campaign state")
	_check(not bool(game.get("_campaign_battle_active")), "rejected Mission 5 launch published battle state")
	var blocked_pull: Dictionary = game.call("pull_premium_hero")
	var blocked_hire: Dictionary = game.call("hire_basic_recruit")
	var blocked_training: Dictionary = game.call("training_call", &"commit", [])
	for blocked: Dictionary in [blocked_pull, blocked_hire, blocked_training]:
		_check(blocked.get("error_code") == &"strategic_mutation_pending", "pending Mission 5 retry did not block another strategic command")
	var different_selection: Array[StringName] = [selected[0]]
	var retried: Dictionary = game.call("start_stage", &"s1", different_selection, true)
	_check(retried.get("accepted", false), "Mission 5 exact retry failed: %s" % retried.get("error_code", &"unknown"))
	_check(not bool(game.call("mission_launch_retry_pending")), "Mission 5 retry state was not cleared")
	_check(int(game.call("campaign_projection").get("save_revision", -1)) == revision_before + 1, "Mission 5 retry did not advance exactly one revision")
	_check(bool(game.get("_campaign_battle_active")), "accepted Mission 5 retry did not publish battle state")
	_check(game.get("selected_stage_id") == &"s5", "retry did not preserve the original Mission 5 stage")
	_check(game.get("selected_squad") == selected, "retry did not preserve the original five-member field team")
	var ticket: Dictionary = retried.get("ticket", {})
	_check(StringName(ticket.get("stage_id", &"")) == &"s5", "retried ticket targets the wrong mission")
	_check((ticket.get("squad", []) as Array).size() == 5, "retried ticket lost Mission 5 squad members")
	_check(game.get("pending_stage") == null, "retry changed the original no-open-battle contract")
	_cleanup(game)
	await process_frame
	_finish()


func _clear_stage(game: Node, stage_id: StringName) -> bool:
	var state: Variant = game.get("campaign")
	var projection: Dictionary = state.runtime_projection()
	var ready: Array = projection.get("ready_heroes", [])
	if ready.is_empty():
		return false
	var hero_id := String(ready[0]["hero_id"])
	var ordinal := int(String(stage_id).trim_prefix("s"))
	var begin: Dictionary = state.begin_attempt(
		"mission-launch-test:begin:%s" % stage_id,
		stage_id,
		[hero_id],
		9000 + ordinal,
		state.save_revision(),
	)
	if not begin.get("accepted", false):
		_failures.append("%s begin rejected: %s" % [stage_id, begin.get("error_code", &"unknown")])
		return false
	var committed_begin: Dictionary = CampaignRuntimeAuthorityScript.commit(
		begin, game.get("campaign_store"),
	)
	if not committed_begin.get("accepted", false):
		_failures.append("%s begin save failed: %s" % [stage_id, committed_begin.get("error_code", &"unknown")])
		return false
	state = committed_begin["state"]
	game.set("campaign", state)
	var ticket: Dictionary = committed_begin["result"]["ticket"]
	var frozen: Dictionary = ticket["squad"][0]
	var outcome: Dictionary = BattleOutcomeV3Script.seal({
		"schema_version": BattleOutcomeV3Script.SCHEMA_VERSION,
		"attempt_id": ticket["attempt_id"],
		"ticket_hash": ticket["ticket_hash"],
		"result": "clear",
		"terminal_reason": "clear",
		"terminal_tick": 120,
		"stars": 3,
		"leaks": 0,
		"kills": 12,
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
	if not outcome.get("accepted", false):
		_failures.append("%s outcome rejected: %s" % [stage_id, outcome.get("error_code", &"unknown")])
		return false
	var resolved: Dictionary = state.resolve_attempt(
		"mission-launch-test:resolve:%s" % stage_id,
		ticket["attempt_id"],
		outcome["value"],
		state.save_revision(),
	)
	if not resolved.get("accepted", false):
		_failures.append("%s resolve rejected: %s" % [stage_id, resolved.get("error_code", &"unknown")])
		return false
	var committed_resolution: Dictionary = CampaignRuntimeAuthorityScript.commit(
		resolved, game.get("campaign_store"),
	)
	if not committed_resolution.get("accepted", false):
		_failures.append("%s resolution save failed: %s" % [stage_id, committed_resolution.get("error_code", &"unknown")])
		return false
	game.set("campaign", committed_resolution["state"])
	return true


func _cleanup(game: Node) -> void:
	game.call("cancel_mission_launch_retry")
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	game.set("selected_stage_id", &"")
	game.set("selected_squad", [])
	game.set("pending_stage", null)
	game.set("current_battle", null)
	game.set("_pending_battle_ticket", {})
	game.set("_pending_campaign_mutation", null)
	game.set("_pending_promotion_mutation", null)
	game.set("_pending_recruitment_mutation", null)
	game.set("_campaign_battle_active", false)
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MISSION_LAUNCH_RETRY_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
