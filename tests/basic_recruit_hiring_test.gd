extends SceneTree

const RuntimeContext := preload("res://sim/campaign_runtime_context.gd")
const CampaignStateV3 := preload("res://sim/campaign_state_v3.gd")
const RecruitmentRules := preload("res://sim/campaign_v3_recruitment.gd")
const StateCodec := preload("res://sim/campaign_v3_state_codec.gd")

var _failures: Array[String] = []


func _init() -> void:
	_test_pre_feature_save_compatibility()
	_test_repeatable_hire_and_receipts()
	_test_rejections_are_side_effect_free()
	if _failures.is_empty():
		print("BASIC_RECRUIT_HIRING_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _test_pre_feature_save_compatibility() -> void:
	var context := RuntimeContext.build()
	var previous_context: Dictionary = context.duplicate(true)
	previous_context["campaign"].erase("basic_recruit_cost")
	previous_context["campaign"].erase("recruit_portrait_asset_ids")
	previous_context["environment_sha256"] = (
		"4ee7ce25ec20bc7c7d6570d7ee22b7e3ca0bba8b377a10804bf2cd43c08591e4"
	)
	var previous: Dictionary = CampaignStateV3.create(1600, 3, previous_context)
	_check(previous.get("accepted", false), "pre-feature save fixture could not be created")
	if not previous.get("accepted", false):
		return
	var encoded: Dictionary = previous["value"].encode_save()
	var restored: Dictionary = CampaignStateV3.restore_source(encoded.get("text", ""), context)
	_check(restored.get("accepted", false), "pre-feature canonical save did not restore")
	if restored.get("accepted", false):
		var projection: Dictionary = restored["value"].runtime_projection()
		_check(projection["marks"] == 120, "pre-feature restore changed Marks")
		_check((projection["ready_heroes"] as Array).size() == 5, "pre-feature restore changed roster")
		_check(projection["basic_recruit_cost"] == 5, "pre-feature restore lacks the new hire price")
	var historical_contract: Dictionary = previous["value"].recruit_person(
		"pre-feature:contract",
		previous["value"].save_revision(),
		&"contract",
		&"p16_caster_contract",
	)
	_check(historical_contract.get("accepted", false), "pre-feature contract fixture was rejected")
	if historical_contract.get("accepted", false):
		var mutation: Variant = historical_contract.get("payload", {}).get("mutation")
		var replayed: Dictionary = CampaignStateV3.restore_source(
			mutation.prospective_save_text(), context,
		)
		_check(replayed.get("accepted", false), "pre-feature command ledger did not replay")
		if replayed.get("accepted", false):
			var replay_projection: Dictionary = replayed["value"].runtime_projection()
			_check(replay_projection["marks"] == 40, "pre-feature contract Marks changed")
			_check((replay_projection["ready_heroes"] as Array).size() == 6, "pre-feature contract roster changed")


func _test_repeatable_hire_and_receipts() -> void:
	var context := RuntimeContext.build()
	_check(not context.is_empty(), "runtime context failed")
	if context.is_empty():
		return
	_check(int(context["campaign"]["basic_recruit_cost"]) == 5, "basic recruit cost is not 5 Marks")
	_check((context["campaign"]["recruit_portrait_asset_ids"] as Array).size() == 8, "recruit-only portrait pool is incomplete")
	var created: Dictionary = CampaignStateV3.create(1701, 1, context)
	_check(created.get("accepted", false), "fresh campaign creation failed")
	if not created.get("accepted", false):
		return
	var state = created["value"]
	var initial: Dictionary = state.runtime_projection()
	_check(initial["marks"] == 120, "fresh Marks balance changed")
	_check(initial["basic_recruit_cost"] == 5, "runtime projection hid the hire cost")
	_check((initial["ready_heroes"] as Array).size() == 5, "starter roster changed")
	var hash_before: String = state.strategic_hash()["hex"]
	var revision_before: int = state.save_revision()

	var command: Dictionary = state.recruit_person(
		"basic-hire:1", revision_before, &"basic_hire", &"mission_control",
	)
	_check(command.get("accepted", false), "first basic hire was rejected")
	state = _restore_mutation(command, context)
	if state == null:
		return
	var after_first: Dictionary = state.runtime_projection()
	_check(after_first["marks"] == 115, "first hire did not charge exactly 5 Marks")
	_check((after_first["ready_heroes"] as Array).size() == 6, "first hire did not add one ready Recruit")
	_check(state.save_revision() == revision_before + 1, "first hire did not advance save revision once")
	_check(state.strategic_hash()["hex"] != hash_before, "first hire did not change the strategic hash")
	var first_hero: Dictionary = (after_first["ready_heroes"] as Array)[-1]
	_check(first_hero["recruit_source"] == "basic_hire", "first hero source is not basic_hire")
	_check(first_hero["source_id"] == "mission_control", "first hero source id drifted")
	_check(first_hero["operator_def_id"] == "recruit", "basic hire did not create a Recruit")
	var first_record: Dictionary = state.data_copy()["command_receipts"][-1]
	_check(first_record["verb"] == "recruit_person", "hire command was not persisted")
	_check(first_record["receipt"]["recruitment"]["marks_before"] == 120, "receipt Marks-before drifted")
	_check(first_record["receipt"]["recruitment"]["marks_after"] == 115, "receipt Marks-after drifted")

	var duplicate: Dictionary = state.recruit_person(
		"basic-hire:1", revision_before, &"basic_hire", &"mission_control",
	)
	_check(duplicate.get("accepted", false), "duplicate hire command was not replay-safe")
	_check(duplicate.get("payload", {}).get("fresh", true) == false, "duplicate hire was not identified")
	_check(duplicate.get("payload", {}).get("mutation") == null, "duplicate hire created a second mutation")
	_check(state.runtime_projection() == after_first, "duplicate hire changed authoritative state")

	var second: Dictionary = state.recruit_person(
		"basic-hire:2", state.save_revision(), &"basic_hire", &"mission_control",
	)
	_check(second.get("accepted", false), "repeat basic hire was rejected")
	state = _restore_mutation(second, context)
	if state == null:
		return
	var after_second: Dictionary = state.runtime_projection()
	_check(after_second["marks"] == 110, "repeat hire did not charge another 5 Marks")
	_check((after_second["ready_heroes"] as Array).size() == 7, "repeat hire did not add one Recruit")
	_check(
		(after_second["ready_heroes"] as Array)[-1]["hero_id"] != first_hero["hero_id"],
		"repeat hire did not allocate a distinct deterministic hero id",
	)
	var encoded: Dictionary = state.encode_save()
	_check(encoded.get("accepted", false), "post-hire save did not encode")
	var restored: Dictionary = CampaignStateV3.restore_source(encoded.get("text", ""), context)
	_check(restored.get("accepted", false), "post-hire save did not reload")
	if restored.get("accepted", false):
		_check(
			restored["value"].runtime_projection() == after_second,
			"save/reload changed the hired roster or Marks balance",
		)

	var tampered: Dictionary = state.data_copy()
	tampered["command_receipts"][-1]["receipt"]["recruitment"]["marks_after"] += 1
	var rejected_tamper: Dictionary = CampaignStateV3.restore(tampered, context)
	_check(not rejected_tamper.get("accepted", false), "tampered hire receipt restored successfully")
	var wrap_data: Dictionary = created["value"].data_copy()
	for index: int in range(5, 22):
		wrap_data["next_recruitment_index"] = index
		var derived: Dictionary = RecruitmentRules._derive(
			wrap_data,
			context,
			{"source": "basic_hire", "source_id": "mission_control"},
		)
		_check(derived.get("accepted", false), "portrait wrap fixture rejected index %d" % index)
		if derived.get("accepted", false):
			var portrait_id := String(derived["receipt"]["hero"]["portrait_asset_id"])
			_check(portrait_id.begins_with("portrait_recruit_"), "basic hire received non-recruit portrait %s" % portrait_id)


func _test_rejections_are_side_effect_free() -> void:
	var context := RuntimeContext.build()
	var low_funds_context: Dictionary = context.duplicate(true)
	low_funds_context["campaign"]["initial_marks"] = 4
	var created: Dictionary = CampaignStateV3.create(404, 1, low_funds_context)
	_check(created.get("accepted", false), "low-funds fixture failed")
	if created.get("accepted", false):
		var state = created["value"]
		var before: Dictionary = state.data_copy()
		var rejected: Dictionary = state.recruit_person(
			"basic-hire:poor", state.save_revision(), &"basic_hire", &"mission_control",
		)
		_check(not rejected.get("accepted", false), "insufficient-Marks hire was accepted")
		_check(rejected.get("error_code") == &"insufficient_marks", "wrong insufficient-Marks error")
		_check(state.data_copy() == before, "insufficient-Marks rejection mutated state")

	created = CampaignStateV3.create(405, 1, context)
	if not created.get("accepted", false):
		_check(false, "rejection fixture failed")
		return
	var state = created["value"]
	var stale: Dictionary = state.recruit_person(
		"basic-hire:stale", state.save_revision() + 1, &"basic_hire", &"mission_control",
	)
	_check(stale.get("error_code") == &"stale_revision", "stale hire did not reject")
	var wrong_source: Dictionary = state.recruit_person(
		"basic-hire:wrong", state.save_revision(), &"basic_hire", &"field_office",
	)
	_check(wrong_source.get("error_code") == &"invalid_basic_hire_source", "wrong office was accepted")

	var hero_id := String(state.data_copy()["heroes"][0]["hero_id"])
	var begun: Dictionary = state.begin_attempt(
		"basic-hire:begin", "s1", [hero_id], 12, state.save_revision(),
	)
	state = _restore_mutation(begun, context)
	if state != null:
		var pending: Dictionary = state.recruit_person(
			"basic-hire:pending", state.save_revision(), &"basic_hire", &"mission_control",
		)
		_check(pending.get("error_code") == &"attempt_pending", "active attempt did not block hiring")

	var full_data: Dictionary = created["value"].data_copy()
	full_data["heroes"].resize(StateCodec.MAX_ROSTER)
	var roster_limit: Dictionary = RecruitmentRules._derive(
		full_data,
		context,
		{"source": "basic_hire", "source_id": "mission_control"},
	)
	_check(roster_limit.get("error_code") == &"roster_limit", "roster limit was not checked first")


func _restore_mutation(command: Dictionary, context: Dictionary) -> Variant:
	if not command.get("accepted", false):
		_check(false, "attempted to restore a rejected command")
		return null
	var mutation: Variant = command.get("payload", {}).get("mutation")
	if mutation == null:
		_check(false, "accepted fresh command did not return a mutation")
		return null
	var restored: Dictionary = CampaignStateV3.restore_source(
		mutation.prospective_save_text(), context,
	)
	_check(restored.get("accepted", false), "prospective hire save did not restore")
	return restored.get("value") if restored.get("accepted", false) else null


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
