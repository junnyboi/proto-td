extends SceneTree

const RuntimeContext := preload("res://sim/campaign_runtime_context.gd")
const CampaignStateV3 := preload("res://sim/campaign_state_v3.gd")
const CampaignV3Codec := preload("res://sim/campaign_v3_codec.gd")
const CanonicalJson := preload("res://sim/canonical_json.gd")
const BattleOutcomeV3 := preload("res://sim/battle_outcome_v3.gd")

var _failures: Array[String] = []


func _init() -> void:
	_test_legacy_v3_migration()
	_test_gacha_and_lifecycle()
	if _failures.is_empty():
		print("PREMIUM_HERO_SYSTEM_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _test_legacy_v3_migration() -> void:
	var context := RuntimeContext.build()
	var created: Dictionary = CampaignStateV3.create(777, 2, context)
	_check(created.get("accepted", false), "migration fixture creation failed")
	if not created.get("accepted", false):
		return
	var current: Dictionary = created["value"].data_copy()
	var legacy := {}
	for key: String in CampaignV3Codec.LEGACY_DATA_KEYS:
		if key == "heroes":
			var heroes: Array[Dictionary] = []
			for source: Dictionary in current["heroes"]:
				var hero := {}
				for hero_key: String in CampaignV3Codec.LEGACY_HERO_KEYS:
					hero[hero_key] = source[hero_key]
				heroes.append(hero)
			legacy[key] = heroes
		else:
			legacy[key] = current[key]
	var root := {
		"schema": CampaignV3Codec.SAVE_SCHEMA,
		"version": CampaignV3Codec.SAVE_VERSION,
		"checksum": CanonicalJson.sha256_hex(legacy),
		"data": legacy,
	}
	var restored: Dictionary = CampaignStateV3.restore_source(CanonicalJson.text(root), context)
	_check(restored.get("accepted", false), "legacy v3 save did not migrate")
	if not restored.get("accepted", false):
		return
	var migrated: Dictionary = restored["value"].data_copy()
	_check(migrated["next_premium_pull_index"] == 0, "migrated pull index was not zero")
	for hero: Dictionary in migrated["heroes"]:
		_check(hero["hero_kind"] == "recruit", "migrated hero kind changed")
		_check(hero["premium_id"] == null, "migrated hero gained premium identity")
		_check(hero["premium_lives"] == 0, "migrated hero gained premium lives")
		_check(hero["premium_pull_count"] == 0, "migrated hero gained pull count")


func _test_gacha_and_lifecycle() -> void:
	var context := RuntimeContext.build()
	context["campaign"]["initial_marks"] = 400
	var created: Dictionary = CampaignStateV3.create(42, 1, context)
	_check(created.get("accepted", false), "premium fixture creation failed")
	if not created.get("accepted", false):
		return
	var state = created["value"]
	state = _advance_pull(state, context, 0)
	if state == null:
		return
	var first_data: Dictionary = state.data_copy()
	var first_record: Dictionary = first_data["command_receipts"][-1]
	var duplicate: Dictionary = state.pull_premium_hero(
		first_record["command_id"], first_record["expected_save_revision"],
	)
	_check(duplicate.get("accepted", false), "duplicate premium command was rejected")
	_check(duplicate.get("payload", {}).get("fresh", true) == false, "duplicate command rerolled")
	state = _advance_pull(state, context, 1)
	state = _advance_pull(state, context, 2)
	if state == null:
		return
	var data: Dictionary = state.data_copy()
	_check(data["marks"] == 280, "three premium pulls did not charge exactly 120 Marks")
	_check(data["next_premium_pull_index"] == 3, "premium pull counter drifted")
	var vessel := _premium(data["heroes"], "lunaris_vessel")
	_check(not vessel.is_empty(), "deterministic seed did not acquire Lunaris Vessel")
	_check(vessel.get("premium_lives") == 2, "duplicate pull did not grant a second life")
	_check(vessel.get("premium_pull_count") == 2, "duplicate pull count is incorrect")
	if vessel.is_empty():
		return
	var training: Dictionary = state.promotion_options(vessel["hero_id"])
	_check(not training.get("accepted", false), "premium hero appeared trainable")
	_check(training.get("error_code") == &"premium_hero_untrainable", "wrong training rejection")

	state = _fall_once(state, context, String(vessel["hero_id"]), 1)
	if state == null:
		return
	data = state.data_copy()
	vessel = _premium(data["heroes"], "lunaris_vessel")
	_check(vessel["premium_lives"] == 1, "first fall did not consume one life")
	_check(vessel["life_status"] == "ready", "hero locked before final life")
	_check(vessel["xp"] == 0, "premium hero received XP")
	_check(data["last_resolution"]["dead_hero_ids"].is_empty(), "surviving fall was marked dead")
	_check(data["last_resolution"]["premium_life_losses"].size() == 1, "life loss missing")

	state = _fall_once(state, context, String(vessel["hero_id"]), 2)
	if state == null:
		return
	data = state.data_copy()
	vessel = _premium(data["heroes"], "lunaris_vessel")
	_check(vessel["premium_lives"] == 0, "last fall did not consume final life")
	_check(vessel["life_status"] == "dead", "zero-life hero was not locked")
	_check(not _memorial(data["memorial"], vessel["hero_id"]).is_empty(), "zero-life memorial missing")
	var locked: Dictionary = state.begin_attempt(
		"test:locked", "s1", [vessel["hero_id"]], 42, state.save_revision(),
	)
	_check(not locked.get("accepted", false), "zero-life premium hero deployed")

	var revived := false
	for pull_index: int in range(3, 10):
		state = _advance_pull(state, context, pull_index)
		if state == null:
			return
		data = state.data_copy()
		vessel = _premium(data["heroes"], "lunaris_vessel")
		if vessel["life_status"] == "ready":
			revived = true
			break
	_check(revived, "repeat pull did not revive zero-life premium hero")
	_check(vessel["premium_lives"] >= 1, "revived hero has no life")
	_check(_memorial(data["memorial"], vessel["hero_id"]).is_empty(), "revival left memorial behind")


func _advance_pull(state: Variant, context: Dictionary, index: int) -> Variant:
	var command: Dictionary = state.pull_premium_hero(
		"test:pull:%d" % index, state.save_revision(),
	)
	_check(command.get("accepted", false), "pull %d failed: %s" % [index, command.get("error_code", &"unknown")])
	return _restore_mutation(command, context) if command.get("accepted", false) else null


func _fall_once(state: Variant, context: Dictionary, hero_id: String, ordinal: int) -> Variant:
	var begin: Dictionary = state.begin_attempt(
		"test:begin:%d" % ordinal, "s1", [hero_id], 100 + ordinal, state.save_revision(),
	)
	_check(begin.get("accepted", false), "begin %d failed: %s" % [ordinal, begin.get("error_code", &"unknown")])
	if not begin.get("accepted", false):
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
	_check(outcome.get("accepted", false), "outcome %d failed" % ordinal)
	if not outcome.get("accepted", false):
		return null
	var resolved: Dictionary = state.resolve_attempt(
		"test:resolve:%d" % ordinal,
		ticket["attempt_id"],
		outcome["value"],
		state.save_revision(),
	)
	_check(resolved.get("accepted", false), "resolve %d failed: %s" % [ordinal, resolved.get("error_code", &"unknown")])
	return _restore_mutation(resolved, context) if resolved.get("accepted", false) else null


func _restore_mutation(command: Dictionary, context: Dictionary) -> Variant:
	var mutation: Variant = command.get("payload", {}).get("mutation")
	if mutation == null:
		_check(false, "command did not return a mutation")
		return null
	var restored: Dictionary = CampaignStateV3.restore_source(mutation.prospective_save_text(), context)
	_check(restored.get("accepted", false), "prospective save rejected: %s" % restored.get("error_code", &"unknown"))
	return restored["value"] if restored.get("accepted", false) else null


func _premium(heroes: Array, premium_id: String) -> Dictionary:
	for hero: Dictionary in heroes:
		if hero["hero_kind"] == "premium" and hero["premium_id"] == premium_id:
			return hero
	return {}


func _memorial(rows: Array, hero_id: String) -> Dictionary:
	for row: Dictionary in rows:
		if row["hero_id"] == hero_id:
			return row
	return {}


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
