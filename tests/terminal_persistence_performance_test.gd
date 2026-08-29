extends SceneTree

const CampaignRuntimeAuthorityScript := preload("res://sim/campaign_runtime_authority.gd")
const CampaignStateV3Script := preload("res://sim/campaign_state_v3.gd")
const BattleOutcomeV3Script := preload("res://sim/battle_outcome_v3.gd")

const TERMINAL_COMMIT_BUDGET_USEC := 250_000
const TERMINAL_PHASE_BUDGET_USEC := 100_000
const TERMINAL_SCALE_FLOOR_USEC := 100_000
const TERMINAL_SCALE_ALLOWANCE := 8.0
const STRATEGIC_ACTION_BUDGET_USEC := 250_000

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 601_601)
	_check(bool(game.call("start_campaign", false, true)), "performance campaign failed to start")
	if not bool(game.get("campaign_active")):
		_finish()
		return
	var first_terminal_usec := 0
	var last_terminal_usec := 0
	var last_prepare_usec := 0
	var last_commit_usec := 0
	for stage_index: int in range(1, 17):
		var elapsed: Dictionary = _clear_stage(game, stage_index)
		if elapsed.is_empty():
			break
		if stage_index == 1:
			first_terminal_usec = elapsed["total_usec"]
		if stage_index == 16:
			last_terminal_usec = elapsed["total_usec"]
			last_prepare_usec = elapsed["prepare_usec"]
			last_commit_usec = elapsed["commit_usec"]
	var state: Variant = game.get("campaign")
	if state != null and last_terminal_usec > 0:
		var records: Array = state.data_copy()["command_receipts"]
		_check(records.size() == 32, "performance fixture did not reach a 32-command ledger")
		_check(
			last_terminal_usec <= TERMINAL_COMMIT_BUDGET_USEC,
			"mission 16 terminal commit exceeded %dms: %.2fms"
			% [TERMINAL_COMMIT_BUDGET_USEC / 1000, last_terminal_usec / 1000.0],
		)
		_check(
			maxi(last_prepare_usec, last_commit_usec) <= TERMINAL_PHASE_BUDGET_USEC,
			"mission 16 retained a long single-frame phase: prepare %.2fms, commit %.2fms"
			% [last_prepare_usec / 1000.0, last_commit_usec / 1000.0],
		)
		_check(
			last_terminal_usec <= maxf(
				float(TERMINAL_SCALE_FLOOR_USEC),
				float(first_terminal_usec) * TERMINAL_SCALE_ALLOWANCE,
			),
			"terminal commit retained a history-length cliff: %.2fms → %.2fms"
			% [first_terminal_usec / 1000.0, last_terminal_usec / 1000.0],
		)
		var cold := CampaignStateV3Script.restore_source(
			state._validated_save_text(), state._context_ref(),
		)
		_check(cold.get("accepted", false), "fast-path save failed exhaustive cold restore")
		if cold.get("accepted", false):
			_check(
				cold["value"].data_copy() == state.data_copy(),
				"cold restore differs from certified runtime authority",
			)
		print(
			(
				"TERMINAL_PERSISTENCE_PROFILE mission1=%.2fms mission16=%.2fms "
				+ "prepare16=%.2fms commit16=%.2fms"
			)
			% [
				first_terminal_usec / 1000.0,
				last_terminal_usec / 1000.0,
				last_prepare_usec / 1000.0,
				last_commit_usec / 1000.0,
			]
		)
		_profile_strategic_actions(game)
	_cleanup(game)
	await process_frame
	_finish()


func _profile_strategic_actions(game: Node) -> void:
	var state: Variant = game.get("campaign")
	var hero_id := ""
	var target_class_id := ""
	for hero: Dictionary in state.data_copy().get("heroes", []):
		var candidate_id := String(hero.get("hero_id", ""))
		var options: Dictionary = state.promotion_options(candidate_id)
		if bool(options.get("accepted", false)):
			hero_id = candidate_id
			target_class_id = String((options["choices"] as Array)[0]["to_class_id"])
			break
	_check(not hero_id.is_empty(), "long-history fixture has no promotable operator")
	if hero_id.is_empty():
		return
	var promotion_started := Time.get_ticks_usec()
	var promoted: Dictionary = game.call(
		"training_call", &"commit", [{"hero_id": hero_id, "to_class_id": target_class_id}],
	)
	var promotion_usec := Time.get_ticks_usec() - promotion_started
	_check(promoted.get("accepted", false), "long-history promotion commit failed")
	_check(
		promotion_usec <= STRATEGIC_ACTION_BUDGET_USEC,
		"promotion commit exceeded %dms: %.2fms"
		% [STRATEGIC_ACTION_BUDGET_USEC / 1000, promotion_usec / 1000.0],
	)
	var hire_started := Time.get_ticks_usec()
	var hired: Dictionary = game.call("hire_basic_recruit")
	var hire_usec := Time.get_ticks_usec() - hire_started
	_check(hired.get("accepted", false), "long-history recruit hire failed")
	_check(
		hire_usec <= STRATEGIC_ACTION_BUDGET_USEC,
		"recruit hire exceeded %dms: %.2fms"
		% [STRATEGIC_ACTION_BUDGET_USEC / 1000, hire_usec / 1000.0],
	)
	print(
		"STRATEGIC_ACTION_PROFILE promotion=%.2fms hire=%.2fms"
		% [promotion_usec / 1000.0, hire_usec / 1000.0]
	)


func _clear_stage(game: Node, stage_index: int) -> Dictionary:
	var state: Variant = game.get("campaign")
	var ready: Array = state.runtime_projection()["ready_heroes"]
	if ready.is_empty():
		_failures.append("s%d has no ready hero" % stage_index)
		return {}
	var hero_id := String(ready[0]["hero_id"])
	var stage_id := StringName("s%d" % stage_index)
	var begin: Dictionary = state.begin_attempt(
		"terminal-performance:begin:%d" % stage_index,
		stage_id,
		[hero_id],
		70_000 + stage_index,
		state.save_revision(),
	)
	if not begin.get("accepted", false):
		_failures.append("s%d begin rejected: %s" % [stage_index, begin.get("error_code")])
		return {}
	var committed_begin := CampaignRuntimeAuthorityScript.commit(
		begin, game.get("campaign_store"),
	)
	if not committed_begin.get("accepted", false):
		_failures.append(
			"s%d begin save failed: %s" % [stage_index, committed_begin.get("error_code")]
		)
		return {}
	state = committed_begin["state"]
	game.set("campaign", state)
	var ticket: Dictionary = committed_begin["result"]["ticket"]
	var frozen: Dictionary = ticket["squad"][0]
	var outcome := BattleOutcomeV3Script.seal({
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
		_failures.append("s%d outcome failed: %s" % [stage_index, outcome.get("error_code")])
		return {}
	var started := Time.get_ticks_usec()
	var resolve: Dictionary = state.resolve_attempt(
		"terminal-performance:resolve:%d" % stage_index,
		ticket["attempt_id"],
		outcome["value"],
		state.save_revision(),
	)
	if not resolve.get("accepted", false):
		_failures.append("s%d resolve rejected: %s" % [stage_index, resolve.get("error_code")])
		return {}
	var prepared := Time.get_ticks_usec()
	var committed := CampaignRuntimeAuthorityScript.commit(
		resolve, game.get("campaign_store"),
	)
	var finished := Time.get_ticks_usec()
	if not committed.get("accepted", false):
		_failures.append("s%d resolve save failed: %s" % [stage_index, committed.get("error_code")])
		return {}
	game.set("campaign", committed["state"])
	return {
		"prepare_usec": prepared - started,
		"commit_usec": finished - prepared,
		"total_usec": finished - started,
	}


func _cleanup(game: Node) -> void:
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	game.set("current_battle", null)
	game.set("_pending_campaign_mutation", null)
	game.set("_campaign_battle_active", false)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TERMINAL_PERSISTENCE_PERFORMANCE_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
