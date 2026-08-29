extends SceneTree

const RuntimeContext := preload("res://sim/campaign_runtime_context.gd")
const CampaignStateV3 := preload("res://sim/campaign_state_v3.gd")
const CampaignV3Codec := preload("res://sim/campaign_v3_codec.gd")
const CampaignV3Gacha := preload("res://sim/campaign_v3_gacha.gd")
const CampaignV3Hash := preload("res://sim/campaign_v3_hash.gd")
const CanonicalJson := preload("res://sim/canonical_json.gd")
const BattleOutcomeV3 := preload("res://sim/battle_outcome_v3.gd")

var _failures: Array[String] = []


func _init() -> void:
	_test_pool_contract()
	_test_hard_pity_and_natural_reset()
	_test_prepity_save_activation()
	_test_prereplay_save_activation()
	_test_marks_pacing_and_replay_stipend()
	if _failures.is_empty():
		print("PREMIUM_GACHA_PITY_ECONOMY_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _test_pool_contract() -> void:
	var context := RuntimeContext.build()
	var rows: Array = context["campaign"]["premium_hero_rows"]
	_check(rows.size() == 3, "premium pool size changed")
	var total_weight := 0
	var five_star_weight := 0
	var five_star_ids: Array[String] = []
	for row: Dictionary in rows:
		total_weight += int(row["weight"])
		if int(row["rarity"]) == 5:
			five_star_weight += int(row["weight"])
			five_star_ids.append(String(row["premium_id"]))
	_check(total_weight == 40, "premium pool weight total is not 40")
	_check(five_star_weight == 2, "five-star base rate is not 2/40")
	_check(five_star_ids == ["lunaris_vessel"], "Lunaris Vessel is not the sole five-star")
	var marks_sum := 0
	for stage: Dictionary in context["campaign"]["v3_stage_rewards"]:
		var stage_marks := 0
		for reward: Dictionary in stage["rewards"]:
			if reward["kind"] == "currency" and reward["id"] == "marks":
				stage_marks += int(reward["amount"])
		_check(stage_marks == 40, "%s does not grant exactly 40 Marks" % stage["stage_id"])
		marks_sum += stage_marks
	_check(marks_sum == 640, "campaign first-clear Marks total is not 640")
	_check((120 + marks_sum) / 40 == 19, "campaign baseline does not fund exactly 19 pulls")


func _test_hard_pity_and_natural_reset() -> void:
	var context := RuntimeContext.build()
	context["campaign"]["initial_marks"] = 1000
	var rows: Array = context["campaign"]["premium_hero_rows"]
	var hard_pity_seed := _seed_missing_first_n_five_stars(rows, 9)
	_check(hard_pity_seed >= 0, "could not find deterministic hard-pity seed")
	if hard_pity_seed < 0:
		return
	var created: Dictionary = CampaignStateV3.create(hard_pity_seed, 1, context)
	_check(created.get("accepted", false), "hard-pity fixture creation failed")
	if not created.get("accepted", false):
		return
	var state = created["value"]
	for pull_index: int in 10:
		var advanced := _pull(state, context, "pity:%d" % pull_index)
		if advanced.is_empty():
			return
		state = advanced["state"]
		var receipt: Dictionary = advanced["receipt"]
		if pull_index < 9:
			_check(receipt["rarity"] == 4, "early non-five-star sequence changed")
			_check(not receipt["five_star"], "early pull incorrectly marked five-star")
			_check(not receipt["pity_forced"], "hard pity fired before pull ten")
			_check(receipt["pity_before"] == pull_index, "pity-before counter drifted")
			_check(receipt["pity_after"] == pull_index + 1, "pity-after counter drifted")
		else:
			_check(receipt["rarity"] == 5, "tenth pull was not five-star")
			_check(receipt["five_star"], "tenth pull five-star flag missing")
			_check(receipt["pity_forced"], "tenth pull was not marked forced")
			_check(receipt["pity_before"] == 9, "forced pull did not begin at nine misses")
			_check(receipt["pity_after"] == 0, "forced five-star did not reset pity")
			_check(receipt["guarantee_in_after"] == 10, "post-five-star guarantee did not reset")
	_check(state.data_copy()["premium_pity_streak"] == 0, "final pity state did not reset")

	var natural_seed := _seed_with_first_five_star(rows)
	_check(natural_seed >= 0, "could not find deterministic natural-five-star seed")
	if natural_seed < 0:
		return
	created = CampaignStateV3.create(natural_seed, 1, context)
	state = created["value"]
	var natural := _pull(state, context, "natural:0")
	_check(not natural.is_empty(), "natural five-star pull failed")
	if natural.is_empty():
		return
	var natural_receipt: Dictionary = natural["receipt"]
	_check(natural_receipt["five_star"], "natural five-star was not selected")
	_check(not natural_receipt["pity_forced"], "natural five-star was marked forced")
	_check(natural_receipt["pity_after"] == 0, "natural five-star did not reset pity")


func _test_prepity_save_activation() -> void:
	var context := RuntimeContext.build()
	context["campaign"]["initial_marks"] = 1000
	var rows: Array = context["campaign"]["premium_hero_rows"]
	var seed_value := _seed_matching_legacy_selection(rows, 3)
	_check(seed_value >= 0, "could not find migration-compatible deterministic seed")
	if seed_value < 0:
		return
	var created: Dictionary = CampaignStateV3.create(seed_value, 1, context)
	var state = created["value"]
	for index: int in 3:
		var advanced := _pull(state, context, "migration:%d" % index)
		if advanced.is_empty():
			return
		state = advanced["state"]
	var current: Dictionary = state.data_copy()
	var prepity := {}
	for key: String in CampaignV3Codec.PREPITY_DATA_KEYS:
		prepity[key] = current[key].duplicate(true) \
			if current[key] is Array or current[key] is Dictionary else current[key]
	for record: Dictionary in prepity["command_receipts"]:
		if record["verb"] != "pull_premium_hero":
			continue
		var receipt: Dictionary = record["receipt"]["premium_pull"]
		for key: String in [
			"rarity", "five_star", "pity_eligible", "pity_before", "pity_after",
			"pity_forced", "guarantee_in_after",
		]:
			receipt.erase(key)
	var root_document := {
		"schema": CampaignV3Codec.SAVE_SCHEMA,
		"version": CampaignV3Codec.SAVE_VERSION,
		"checksum": CanonicalJson.sha256_hex(prepity),
		"data": prepity,
	}
	var restored: Dictionary = CampaignStateV3.restore_source(
		CanonicalJson.text(root_document), context,
	)
	_check(
		restored.get("accepted", false),
		"pre-pity save did not migrate: %s" % restored.get("error_code", &"unknown"),
	)
	if not restored.get("accepted", false):
		return
	state = restored["value"]
	var migrated: Dictionary = state.data_copy()
	_check(migrated["premium_pity_started_at_pull"] == 3, "pity did not activate after old pulls")
	_check(migrated["premium_pity_streak"] == 0, "migrated save did not receive a fresh pity window")
	for record: Dictionary in migrated["command_receipts"]:
		if record["verb"] == "pull_premium_hero":
			_check(not record["receipt"]["premium_pull"]["pity_eligible"], "old pull became pity eligible")
	var next_pull := _pull(state, context, "migration:new")
	_check(not next_pull.is_empty(), "first post-migration pull failed")
	if not next_pull.is_empty():
		var receipt: Dictionary = next_pull["receipt"]
		_check(receipt["pity_eligible"], "first post-migration pull was not pity eligible")
		_check(receipt["pity_before"] == 0, "post-migration pity did not start at zero")


func _test_marks_pacing_and_replay_stipend() -> void:
	var context := RuntimeContext.build()
	var created: Dictionary = CampaignStateV3.create(808, 1, context)
	_check(created.get("accepted", false), "Marks fixture creation failed")
	if not created.get("accepted", false):
		return
	var state = created["value"]
	var hero_id := String(state.data_copy()["heroes"][0]["hero_id"])
	var first := _clear_stage(state, context, hero_id, 1, 1)
	if first.is_empty():
		return
	state = first["state"]
	var first_receipt: Dictionary = first["receipt"]
	_check(first_receipt["marks_before"] == 120, "first clear Marks-before changed")
	_check(first_receipt["marks_after"] == 160, "first clear did not grant 40 Marks")
	_check(_currency_total(first_receipt["rewards_granted"]) == 40, "first-clear currency receipt missing")
	var replay := _clear_stage(state, context, hero_id, 2, 3)
	if replay.is_empty():
		return
	var replay_receipt: Dictionary = replay["receipt"]
	_check(replay_receipt["marks_before"] == 160, "repeat clear Marks-before changed")
	_check(replay_receipt["stars_before"] == 1, "repeat clear did not read prior star record")
	_check(replay_receipt["stars_after"] == 3, "repeat clear did not improve the star record")
	_check(
		int(replay["state"].runtime_projection()["stage_stars"].get(&"s1", 0)) == 3,
		"restored Campaign projection did not retain the improved star record",
	)
	_check(replay_receipt["marks_after"] == 180, "repeat clear did not grant 20 Marks")
	_check(_currency_total(replay_receipt["rewards_granted"]) == 20, "repeat-clear currency receipt missing")
	var defeat := _clear_stage(replay["state"], context, hero_id, 3, 0, false)
	if defeat.is_empty():
		return
	_check(defeat["receipt"]["marks_before"] == 180, "replay defeat Marks-before changed")
	_check(defeat["receipt"]["marks_after"] == 180, "replay defeat granted Marks")
	_check(defeat["receipt"]["rewards_granted"].is_empty(), "replay defeat retained a reward")
	_check(defeat["receipt"]["stars_after"] == 3, "replay defeat reduced the best star record")


func _test_prereplay_save_activation() -> void:
	var context := RuntimeContext.build()
	var created: Dictionary = CampaignStateV3.create(809, 1, context)
	_check(created.get("accepted", false), "pre-replay-economy fixture creation failed")
	if not created.get("accepted", false):
		return
	var state = created["value"]
	var hero_id := String(state.data_copy()["heroes"][0]["hero_id"])
	var first := _clear_stage(state, context, hero_id, 1, 1)
	if first.is_empty():
		return
	state = first["state"]
	var old_replay := _clear_stage(state, context, hero_id, 2, 3)
	if old_replay.is_empty():
		return
	state = old_replay["state"]
	_check(old_replay["receipt"]["marks_after"] == 180, "current replay fixture did not gain Marks")

	var prereplay_data: Dictionary = state.data_copy()
	prereplay_data["marks"] = 160
	var old_after_core: Dictionary = prereplay_data["resolution_anchor"]["after_core"]
	old_after_core["marks"] = 160
	old_after_core["replay_marks_started_at_resolution"] = 3
	var old_after_hash: Dictionary = CampaignV3Hash.of_core(old_after_core, context)
	_check(old_after_hash.get("accepted", false), "legacy replay after-core hash fixture failed")
	if not old_after_hash.get("accepted", false):
		return
	prereplay_data["resolution_anchor"]["strategic_body_hash_after"] = old_after_hash["hex"]
	for receipt: Dictionary in [
		prereplay_data["last_resolution"],
		prereplay_data["command_receipts"][-1]["receipt"]["resolution"],
	]:
		receipt["rewards_granted"] = []
		receipt["marks_after"] = 160
		receipt["strategic_body_hash_after"] = old_after_hash["hex"]
	prereplay_data.erase("replay_marks_started_at_resolution")
	for core_key: String in ["before_core", "after_core"]:
		prereplay_data["resolution_anchor"][core_key].erase(
			"replay_marks_started_at_resolution",
		)
	var prereplay_document := {
		"schema": CampaignV3Codec.SAVE_SCHEMA,
		"version": CampaignV3Codec.SAVE_VERSION,
		"checksum": CanonicalJson.sha256_hex(prereplay_data),
		"data": prereplay_data,
	}
	var migrated: Dictionary = CampaignStateV3.restore_source(
		CanonicalJson.text(prereplay_document), context,
	)
	_check(
		migrated.get("accepted", false),
		"pre-replay-economy save did not migrate: %s" % migrated.get("error_code", &"unknown"),
	)
	if not migrated.get("accepted", false):
		return
	state = migrated["value"]
	var migrated_data: Dictionary = state.data_copy()
	_check(
		migrated_data["replay_marks_started_at_resolution"] == 3,
		"replay Marks activated retroactively during migration",
	)
	_check(
		int(state.runtime_projection()["stage_stars"].get(&"s1", 0)) == 3,
		"pre-replay-economy migration lost the improved star record",
	)
	var new_replay := _clear_stage(state, context, hero_id, 3, 3)
	if new_replay.is_empty():
		return
	_check(new_replay["receipt"]["marks_before"] == 160, "migrated replay Marks-before changed")
	_check(new_replay["receipt"]["marks_after"] == 180, "first post-migration replay did not grant 20 Marks")


func _pull(state: Variant, context: Dictionary, command_id: String) -> Dictionary:
	var command: Dictionary = state.pull_premium_hero(command_id, state.save_revision())
	_check(command.get("accepted", false), "%s rejected" % command_id)
	if not command.get("accepted", false):
		return {}
	var restored: Variant = _restore(command, context)
	var receipt: Dictionary = {}
	if restored != null:
		receipt = restored.data_copy()["command_receipts"][-1]["receipt"]["premium_pull"]
	return {
		"state": restored,
		"receipt": receipt.duplicate(true),
	} if restored != null else {}


func _clear_stage(
	state: Variant,
	context: Dictionary,
	hero_id: String,
	ordinal: int,
	stars: int = 3,
	cleared: bool = true,
) -> Dictionary:
	var begin: Dictionary = state.begin_attempt(
		"marks:begin:%d" % ordinal, "s1", [hero_id], 900 + ordinal, state.save_revision(),
	)
	_check(
		begin.get("accepted", false),
		"Marks begin %d failed: %s" % [ordinal, begin.get("error_code", &"unknown")],
	)
	if not begin.get("accepted", false):
		return {}
	state = _restore(begin, context)
	if state == null:
		return {}
	var ticket: Dictionary = state.data_copy()["tickets"][-1]
	var frozen: Dictionary = ticket["squad"][0]
	var outcome := BattleOutcomeV3.seal({
		"schema_version": BattleOutcomeV3.SCHEMA_VERSION,
		"attempt_id": ticket["attempt_id"],
		"ticket_hash": ticket["ticket_hash"],
		"result": "clear" if cleared else "defeat",
		"terminal_reason": "clear" if cleared else "leak_defeat",
		"terminal_tick": 120,
		"stars": stars if cleared else 0,
		"leaks": 0 if cleared else 1,
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
	_check(outcome.get("accepted", false), "Marks outcome %d failed" % ordinal)
	if not outcome.get("accepted", false):
		return {}
	var resolve_command_id := "marks:resolve:%d" % ordinal
	var resolve_revision: int = state.save_revision()
	var resolved: Dictionary = state.resolve_attempt(
		resolve_command_id,
		ticket["attempt_id"],
		outcome["value"],
		resolve_revision,
	)
	_check(
		resolved.get("accepted", false),
		"Marks resolution %d failed: %s" % [ordinal, resolved.get("error_code", &"unknown")],
	)
	if not resolved.get("accepted", false):
		return {}
	var restored: Variant = _restore(resolved, context)
	var receipt: Dictionary = restored.data_copy()["last_resolution"] if restored != null else {}
	if restored != null:
		var duplicate: Dictionary = restored.resolve_attempt(
			resolve_command_id,
			ticket["attempt_id"],
			outcome["value"],
			resolve_revision,
		)
		_check(duplicate.get("accepted", false), "duplicate Marks resolution was rejected")
		_check(not duplicate.get("payload", {}).has("mutation"), "duplicate Marks resolution created a mutation")
		_check(
			duplicate.get("payload", {}).get("resolution", {}) == receipt,
			"duplicate Marks resolution changed its receipt",
		)
	return {
		"state": restored,
		"receipt": receipt.duplicate(true),
	} if restored != null else {}


func _restore(command: Dictionary, context: Dictionary) -> Variant:
	var mutation: Variant = command.get("payload", {}).get("mutation")
	if mutation == null:
		_check(false, "accepted command did not return mutation")
		return null
	var restored: Dictionary = CampaignStateV3.restore_source(
		mutation.prospective_save_text(), context,
	)
	_check(restored.get("accepted", false), "prospective save did not restore")
	return restored["value"] if restored.get("accepted", false) else null


func _seed_missing_first_n_five_stars(rows: Array, count: int) -> int:
	for seed_value: int in 10_000:
		var valid := true
		for pull_index: int in count:
			if int(CampaignV3Gacha._select_row(rows, seed_value, 1, pull_index)["rarity"]) == 5:
				valid = false
				break
		if valid:
			return seed_value
	return -1


func _seed_with_first_five_star(rows: Array) -> int:
	for seed_value: int in 10_000:
		if int(CampaignV3Gacha._select_row(rows, seed_value, 1, 0)["rarity"]) == 5:
			return seed_value
	return -1


func _seed_matching_legacy_selection(rows: Array, count: int) -> int:
	for seed_value: int in 10_000:
		var valid := true
		for pull_index: int in count:
			var current: Dictionary = CampaignV3Gacha._select_row(rows, seed_value, 1, pull_index)
			var legacy: Dictionary = CampaignV3Gacha._select_row(rows, seed_value, 1, pull_index, 0, true)
			if current["premium_id"] != legacy["premium_id"]:
				valid = false
				break
		if valid:
			return seed_value
	return -1


func _currency_total(rewards: Array) -> int:
	var total := 0
	for reward: Dictionary in rewards:
		if reward["kind"] == "currency" and reward["id"] == "marks":
			total += int(reward["amount"])
	return total


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
