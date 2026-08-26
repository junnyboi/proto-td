extends SceneTree

const RuntimeContext := preload("res://sim/campaign_runtime_context.gd")
const CampaignStateV3 := preload("res://sim/campaign_state_v3.gd")

var _failures: Array[String] = []


func _init() -> void:
	_run()
	if _failures.is_empty():
		print("PREMIUM_GACHA_HISTORY_PROJECTION_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _run() -> void:
	var context := RuntimeContext.build()
	context["campaign"]["initial_marks"] = 2000
	var created: Dictionary = CampaignStateV3.create(4242, 1, context)
	_check(created.get("accepted", false), "history fixture creation failed")
	if not created.get("accepted", false):
		return
	var state: Variant = created["value"]
	var fresh: Dictionary = state.runtime_projection()
	_check((fresh["premium_pull_history"] as Array).is_empty(), "fresh campaign exposed pull history")
	_check(int(fresh["premium_pull_history_total"]) == 0, "fresh history total was not zero")

	for pull_index: int in 12:
		var command: Dictionary = state.pull_premium_hero(
			"history:test:%d" % pull_index,
			state.save_revision(),
		)
		_check(
			command.get("accepted", false),
			"pull %d failed: %s" % [pull_index, command.get("error_code", &"unknown")],
		)
		if not command.get("accepted", false):
			return
		state = _restore_mutation(command, context)
		if state == null:
			return

	var projection: Dictionary = state.runtime_projection()
	var history: Array = projection["premium_pull_history"]
	_check(int(projection["premium_pull_history_total"]) == 12, "history total did not include all receipts")
	_check(history.size() == 10, "history did not enforce the compact ten-row limit")
	for offset: int in history.size():
		var row: Dictionary = history[offset]
		_check(int(row["pull_index"]) == 11 - offset, "history is not newest-first at row %d" % offset)
		_check(int(row["lives_after"]) == int(row["lives_before"]) + 1, "history lost life conversion at row %d" % offset)
		_check(int(row["rarity"]) in [4, 5], "history exposed invalid rarity at row %d" % offset)
	var duplicate_rows := history.filter(func(row: Dictionary) -> bool: return not bool(row["new_hero"]))
	_check(not duplicate_rows.is_empty(), "history omitted duplicate conversion receipts")

	var encoded: Dictionary = state.encode_save()
	_check(encoded.get("accepted", false), "history fixture save did not encode")
	if encoded.get("accepted", false):
		var restored: Dictionary = CampaignStateV3.restore_source(String(encoded["text"]), context)
		_check(restored.get("accepted", false), "history fixture save did not restore")
		if restored.get("accepted", false):
			_check(
				restored["value"].runtime_projection()["premium_pull_history"] == history,
				"pull history changed across exact save restore",
			)

	if not history.is_empty():
		history[0]["premium_id"] = "tampered"
		var fresh_projection: Dictionary = state.runtime_projection()
		_check(
			String(fresh_projection["premium_pull_history"][0]["premium_id"]) != "tampered",
			"history projection leaked mutable receipt state",
		)


func _restore_mutation(command: Dictionary, context: Dictionary) -> Variant:
	var mutation: Variant = command.get("payload", {}).get("mutation")
	if mutation == null:
		_check(false, "accepted pull did not return a mutation")
		return null
	var restored: Dictionary = CampaignStateV3.restore_source(
		mutation.prospective_save_text(), context,
	)
	_check(
		restored.get("accepted", false),
		"prospective history save rejected: %s" % restored.get("error_code", &"unknown"),
	)
	return restored["value"] if restored.get("accepted", false) else null


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
