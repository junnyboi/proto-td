extends SceneTree

const ContextScript := preload("res://test/fixtures/p16/campaign_v3_context.gd")
const RESULT_PREFIX := "STRATEGIC_VERBS_V3_RESULT="


func _init() -> void:
	_cleanup()
	var result := _run()
	if not result["accepted"]:
		push_error("STRATEGIC_VERBS_V3_FAILED %s" % str(result))
		_cleanup()
		quit(1)
		return
	print(RESULT_PREFIX + CanonicalJson.text(result["value"]).strip_edges())
	_cleanup()
	quit(0)


func _run() -> Dictionary:
	var setup := _setup()
	if not setup["accepted"]:
		return setup
	var context: Dictionary = setup["context"]
	var state: CampaignStateV3 = setup["state"]
	var store: CampaignSaveStore = setup["store"]
	var hero_ids: Array[String] = setup["hero_ids"]
	var transaction := _begin_and_resolve(state, store, hero_ids)
	if not transaction["accepted"]:
		return transaction
	state = transaction["state"]
	var begun: Dictionary = transaction["begun"]
	var resolved: Dictionary = transaction["resolved"]
	var outcome: Dictionary = transaction["outcome"]
	var choices := [
		{"hero_id": hero_ids[1], "to_class_id": "defender"},
		{"hero_id": hero_ids[0], "to_class_id": "swordmaster"},
	]
	var progression := _promote_and_recruit(state, store, choices)
	if not progression["accepted"]:
		return progression
	state = progression["state"]
	var promoted: Dictionary = progression["promoted"]
	var recruited: Dictionary = progression["recruited"]
	var duplicate_begin := (
		state
		. begin_attempt(
			"v3-begin-0001",
			"s1",
			[hero_ids[1], hero_ids[0]],
			77,
			1,
		)
	)
	var duplicate_resolve := state.resolve_attempt("v3-resolve-0001", 1, outcome, 2)
	var duplicate_promote := state.confirm_promotions("v3-promote-0001", 3, choices)
	var duplicate_recruit := state.recruit_person(
		"v3-recruit-0001", 4, "contract", "p16_caster_contract"
	)
	for duplicate: Dictionary in [
		duplicate_begin,
		duplicate_resolve,
		duplicate_promote,
		duplicate_recruit,
	]:
		if not duplicate["accepted"] or duplicate["payload"]["fresh"]:
			return _reject(&"duplicate_retry_failed")
	var conflicting := (
		state
		. confirm_promotions(
			"v3-promote-0001",
			3,
			[
				{
					"hero_id": hero_ids[0],
					"to_class_id": "defender",
				}
			]
		)
	)
	var encoded := state.encode_save()
	var data := state.data_copy()
	return {
		"accepted": true,
		"error_code": &"",
		"value":
		{
			"environment_sha256": context["environment_sha256"],
			"final_save_text": encoded["text"],
			"final_save_sha256": encoded["sha256"],
			"final_data_checksum": state.encode_data()["sha256"],
			"final_full_hash": state.strategic_hash()["hex"],
			"final_core_hash": state.core_hash()["hex"],
			"save_revision": state.save_revision(),
			"next_attempt_id": state.next_attempt_id(),
			"next_resolution_index": state.next_resolution_index(),
			"heroes": data["heroes"],
			"tickets": data["tickets"],
			"memorial": data["memorial"],
			"promotion_receipts": data["promotion_receipts"],
			"command_receipts": data["command_receipts"],
			"receipt_texts":
			{
				"begin": _receipt_text(begun),
				"resolve": _receipt_text(resolved),
				"promote": _receipt_text(promoted),
				"recruit": _receipt_text(recruited),
			},
			"duplicate_receipt_texts":
			{
				"begin": _duplicate_text(duplicate_begin),
				"resolve": _duplicate_text(duplicate_resolve),
				"promote": _duplicate_text(duplicate_promote),
				"recruit": _duplicate_text(duplicate_recruit),
			},
			"conflict_error": String(conflicting["error_code"]),
		},
	}


func _promote_and_recruit(
	state: CampaignStateV3,
	store: CampaignSaveStore,
	choices: Array,
) -> Dictionary:
	var promoted := _apply(
		state.confirm_promotions("v3-promote-0001", 3, choices),
		store,
	)
	if not promoted["accepted"]:
		return promoted
	state = _reload(store)
	if state == null:
		return _reject(&"reload_failed")
	var recruited := _apply(
		state.recruit_person("v3-recruit-0001", 4, "contract", "p16_caster_contract"),
		store,
	)
	if not recruited["accepted"]:
		return recruited
	state = _reload(store)
	if state == null:
		return _reject(&"reload_failed")
	return {
		"accepted": true,
		"error_code": &"",
		"state": state,
		"promoted": promoted,
		"recruited": recruited,
	}


func _setup() -> Dictionary:
	var context := ContextScript.build()
	var created := CampaignStateV3.create(42, 1, context)
	if not created["accepted"]:
		return created
	var state: CampaignStateV3 = created["value"]
	var store_result := CampaignSaveStore.create_production(state)
	if not store_result["accepted"]:
		return store_result
	var file := FileAccess.open(CampaignSaveStore.PRODUCTION_SLOT, FileAccess.WRITE)
	if file == null:
		return _reject(&"seed_failed")
	file.store_buffer(state.encode_save()["bytes"])
	file.close()
	var hero_ids: Array[String] = []
	for hero: Dictionary in state.data_copy()["heroes"]:
		hero_ids.append(String(hero["hero_id"]))
	return {
		"accepted": true,
		"error_code": &"",
		"context": context,
		"state": state,
		"store": store_result["value"],
		"hero_ids": hero_ids,
	}


func _begin_and_resolve(
	state: CampaignStateV3,
	store: CampaignSaveStore,
	hero_ids: Array[String],
) -> Dictionary:
	var begun := _apply(
		(
			state
			. begin_attempt(
				"v3-begin-0001",
				"s1",
				[hero_ids[1], hero_ids[0]],
				77,
				1,
			)
		),
		store
	)
	if not begun["accepted"]:
		return begun
	state = _reload(store)
	if state == null:
		return _reject(&"reload_failed")
	var ticket: Dictionary = state.data_copy()["tickets"][-1]
	var outcome := _outcome(ticket)
	var resolved := _apply(
		state.resolve_attempt("v3-resolve-0001", 1, outcome, 2),
		store,
	)
	if not resolved["accepted"]:
		return resolved
	state = _reload(store)
	if state == null:
		return _reject(&"reload_failed")
	return {
		"accepted": true,
		"error_code": &"",
		"state": state,
		"begun": begun,
		"resolved": resolved,
		"outcome": outcome,
	}


func _apply(command: Dictionary, store: CampaignSaveStore) -> Dictionary:
	if not command["accepted"]:
		return command
	var saved := (command["payload"]["mutation"] as CampaignMutation).retry_save(store)
	if not saved["accepted"]:
		return saved
	return {
		"accepted": true,
		"error_code": &"",
		"state": saved["payload"]["state"],
		"result": saved["payload"]["result"],
	}


func _reload(store: CampaignSaveStore) -> CampaignStateV3:
	var loaded := store.load()
	return loaded["state"] if loaded["accepted"] else null


func _outcome(ticket: Dictionary) -> Dictionary:
	var rows: Array[Dictionary] = []
	for frozen: Dictionary in ticket["squad"]:
		(
			rows
			. append(
				{
					"slot_index": frozen["slot_index"],
					"battle_id": frozen["battle_id"],
					"hero_id": frozen["hero_id"],
					"class_id": frozen["class_id"],
					"operator_def_id": frozen["operator_def_id"],
					"deployments": 1,
					"retreats": 0,
					"fell": false,
					"first_fall_tick": null,
				}
			)
		)
	var sealed := (
		BattleOutcomeV3
		. seal(
			{
				"schema_version": BattleOutcomeV3.SCHEMA_VERSION,
				"attempt_id": ticket["attempt_id"],
				"ticket_hash": ticket["ticket_hash"],
				"result": "clear",
				"terminal_reason": "clear",
				"terminal_tick": 120,
				"stars": 3,
				"leaks": 0,
				"kills": 5,
				"rows": rows,
			},
			ticket
		)
	)
	return sealed["value"] if sealed["accepted"] else {}


func _receipt_text(applied: Dictionary) -> String:
	return (applied["result"]["receipt_bytes"] as PackedByteArray).get_string_from_utf8()


func _duplicate_text(result: Dictionary) -> String:
	return (result["payload"]["receipt_bytes"] as PackedByteArray).get_string_from_utf8()


func _cleanup() -> void:
	for path: String in [
		CampaignSaveStore.PRODUCTION_SLOT,
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".tmp",
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".bak",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _reject(code: StringName) -> Dictionary:
	return {"accepted": false, "error_code": code}
