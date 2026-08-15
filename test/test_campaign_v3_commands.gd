extends GutTest

const ContextScript := preload("res://test/fixtures/p16/campaign_v3_context.gd")


func test_begin_persists_frozen_ticket_and_retries_exactly_after_reload() -> void:
	var state := _fresh()
	var store := _seed_store(state)
	var ids := _ready_ids(state)
	var command := state.begin_attempt("begin-0001", "s1", [ids[1], ids[0]], 77, 1)
	assert_true(command["accepted"], str(command.get("error_code", &"")))
	var committed := _commit(command, store)
	assert_true(committed["accepted"], str(committed.get("error_code", &"")))
	var after: CampaignStateV3 = committed["payload"]["state"]
	var ticket: Dictionary = committed["payload"]["result"]["ticket"]
	assert_eq(after.save_revision(), 2)
	assert_eq(after.next_attempt_id(), 2)
	assert_eq(ticket["seed"], 77)
	assert_eq(ticket["expected_save_revision"], 2)
	assert_eq(
		ticket["squad"].map(func(row: Dictionary) -> String: return row["hero_id"]),
		[ids[1], ids[0]]
	)
	assert_ne(ticket["squad"][0]["battle_id"], ticket["squad"][1]["battle_id"])
	assert_eq(after.data_copy()["tickets"], [ticket])
	var receipt_bytes: PackedByteArray = committed["payload"]["result"]["receipt_bytes"]
	var loaded: CampaignStateV3 = store.load()["state"]
	var duplicate := loaded.begin_attempt("begin-0001", "s1", [ids[1], ids[0]], 77, 1)
	assert_true(duplicate["accepted"])
	assert_false(duplicate["payload"]["fresh"])
	assert_eq(duplicate["payload"]["receipt_bytes"], receipt_bytes)
	assert_eq(_snapshot(loaded), _snapshot(after))


func test_clear_resolution_commits_survivor_xp_death_memorial_and_exact_retry() -> void:
	var begun := _begun_two()
	var state: CampaignStateV3 = begun["state"]
	var ticket: Dictionary = state.data_copy()["tickets"][-1]
	var fallen_id: String = ticket["squad"][1]["hero_id"]
	var outcome := _outcome(ticket, "clear", [fallen_id], 3)
	var command := state.resolve_attempt("resolve-0001", 1, outcome, 2)
	assert_true(command["accepted"], str(command.get("error_code", &"")))
	var committed := _commit(command, begun["store"])
	assert_true(committed["accepted"], str(committed.get("error_code", &"")))
	var after: CampaignStateV3 = committed["payload"]["state"]
	var data := after.data_copy()
	var resolution: Dictionary = committed["payload"]["result"]["resolution"]
	assert_eq(committed["payload"]["result"]["outcome"], outcome)
	assert_eq(after.save_revision(), 3)
	assert_eq(after.next_resolution_index(), 2)
	assert_eq(data["stage_stars"][0]["stars"], 3)
	assert_eq(data["class_entitlements"], ["sword_saint"])
	assert_eq(
		resolution["xp_awards"],
		[
			{
				"hero_id": ticket["squad"][0]["hero_id"],
				"delta": 100,
			}
		]
	)
	assert_eq(_hero(data, ticket["squad"][0]["hero_id"])["xp"], 100)
	assert_eq(_hero(data, fallen_id)["life_status"], "dead")
	assert_eq(_hero(data, fallen_id)["xp"], 0)
	assert_eq(data["memorial"].size(), 1)
	assert_eq(data["memorial"][0]["hero_id"], fallen_id)
	assert_eq(
		data["memorial"][0]["portrait_instance_id"], _hero(data, fallen_id)["portrait_instance_id"]
	)
	var receipt_bytes: PackedByteArray = committed["payload"]["result"]["receipt_bytes"]
	var loaded: CampaignStateV3 = begun["store"].load()["state"]
	var duplicate := loaded.resolve_attempt("resolve-0001", 1, outcome, 2)
	assert_true(duplicate["accepted"])
	assert_false(duplicate["payload"]["fresh"])
	assert_eq(duplicate["payload"]["receipt_bytes"], receipt_bytes)
	assert_eq(duplicate["payload"]["resolution"], resolution)
	assert_eq(duplicate["payload"]["outcome"], outcome)
	assert_eq(_snapshot(loaded), _snapshot(after))


func test_batch_promotion_is_sorted_atomic_one_revision_and_idempotent() -> void:
	var resolved := _resolved_two_survivors()
	var state: CampaignStateV3 = resolved["state"]
	var data := state.data_copy()
	var first_id: String = data["heroes"][0]["hero_id"]
	var second_id: String = data["heroes"][1]["hero_id"]
	assert_eq(state.promotion_options(first_id)["choices"].size(), 5)
	var before_first: Dictionary = _hero(data, first_id).duplicate(true)
	var before_second: Dictionary = _hero(data, second_id).duplicate(true)
	var command := (
		state
		. confirm_promotions(
			"promote-0001",
			3,
			[
				{"hero_id": second_id, "to_class_id": "defender"},
				{"hero_id": first_id, "to_class_id": "swordmaster"},
			]
		)
	)
	assert_true(command["accepted"], str(command.get("error_code", &"")))
	var committed := _commit(command, resolved["store"])
	assert_true(committed["accepted"], str(committed.get("error_code", &"")))
	var after: CampaignStateV3 = committed["payload"]["state"]
	var after_data := after.data_copy()
	assert_eq(after.save_revision(), 4)
	assert_eq(after_data["promotion_receipts"].size(), 1)
	assert_eq(
		after_data["promotion_receipts"][0]["choices"].map(
			func(row: Dictionary) -> String: return row["hero_id"]
		),
		[first_id, second_id]
	)
	assert_eq(_hero(after_data, first_id)["current_class_id"], "swordmaster")
	assert_eq(_hero(after_data, second_id)["current_class_id"], "defender")
	for field: String in [
		"hero_id",
		"acquisition_operator_def_id",
		"xp",
		"identity_portrait_id",
		"portrait_instance_id",
		"portrait_asset_id",
		"recruitment_index",
		"recruit_source",
		"source_id",
		"custom_callsign",
		"life_status",
		"death",
	]:
		assert_eq(_hero(after_data, first_id)[field], before_first[field], field)
		assert_eq(_hero(after_data, second_id)[field], before_second[field], field)
	var receipt_bytes: PackedByteArray = committed["payload"]["result"]["receipt_bytes"]
	var loaded: CampaignStateV3 = resolved["store"].load()["state"]
	var duplicate := (
		loaded
		. confirm_promotions(
			"promote-0001",
			3,
			[
				{"hero_id": second_id, "to_class_id": "defender"},
				{"hero_id": first_id, "to_class_id": "swordmaster"},
			]
		)
	)
	assert_true(duplicate["accepted"])
	assert_eq(duplicate["payload"]["receipt_bytes"], receipt_bytes)
	assert_eq(_snapshot(loaded), _snapshot(after))


func test_rejections_are_stable_and_leave_every_strategic_surface_equal() -> void:
	var fresh := _fresh()
	var ids := _ready_ids(fresh)
	_assert_rejected_unchanged(
		fresh, fresh.begin_attempt("b", "s2", [ids[0]], 42, 1), &"stage_locked"
	)
	_assert_rejected_unchanged(
		fresh, fresh.begin_attempt("b", "s1", [ids[0], ids[0]], 42, 1), &"invalid_command_payload"
	)
	_assert_rejected_unchanged(
		fresh, fresh.begin_attempt("b", "s1", [ids[0]], 42, 9), &"stale_revision"
	)
	_assert_rejected_unchanged(
		fresh,
		(
			fresh
			. confirm_promotions(
				"p",
				1,
				[
					{
						"hero_id": ids[0],
						"to_class_id": "defender",
					}
				]
			)
		),
		&"insufficient_xp"
	)
	_assert_rejected_unchanged(
		fresh,
		(
			fresh
			. confirm_promotions(
				"p",
				1,
				[
					{"hero_id": ids[0], "to_class_id": "defender"},
					{"hero_id": ids[0], "to_class_id": "swordmaster"},
				]
			)
		),
		&"duplicate_hero_choice"
	)
	var resolved := _resolved_two_survivors()
	var state: CampaignStateV3 = resolved["state"]
	var rid := _ready_ids(state)[0]
	_assert_rejected_unchanged(
		state,
		(
			state
			. confirm_promotions(
				"p2",
				3,
				[
					{"hero_id": rid, "to_class_id": "sorcerer"},
				]
			)
		),
		&"illegal_class_edge"
	)
	var valid := (
		state
		. confirm_promotions(
			"same-id",
			3,
			[
				{
					"hero_id": rid,
					"to_class_id": "defender",
				}
			]
		)
	)
	var committed := _commit(valid, resolved["store"])
	var promoted: CampaignStateV3 = committed["payload"]["state"]
	_assert_rejected_unchanged(
		promoted,
		(
			promoted
			. confirm_promotions(
				"same-id",
				3,
				[
					{
						"hero_id": rid,
						"to_class_id": "swordmaster",
					}
				]
			)
		),
		&"command_id_conflict"
	)


func test_one_invalid_batch_row_rejects_all_valid_rows() -> void:
	var resolved := _resolved_two_survivors()
	var state: CampaignStateV3 = resolved["state"]
	var ids := _ready_ids(state)
	_assert_rejected_unchanged(
		state,
		(
			state
			. confirm_promotions(
				"batch-bad",
				3,
				[
					{"hero_id": ids[0], "to_class_id": "defender"},
					{"hero_id": ids[1], "to_class_id": "sorcerer"},
				]
			)
		),
		&"illegal_class_edge"
	)


func test_advanced_options_require_xp_and_stage_entitlements() -> void:
	var resolved := _resolved_two_survivors()
	var state: CampaignStateV3 = resolved["state"]
	var store: CampaignSaveStore = resolved["store"]
	var hero_id := _ready_ids(state)[0]
	var promoted := _commit(
		(
			state
			. confirm_promotions(
				"mage-standard",
				state.save_revision(),
				[
					{
						"hero_id": hero_id,
						"to_class_id": "mage_apprentice",
					}
				]
			)
		),
		store,
	)
	state = promoted["payload"]["state"]
	assert_eq(state.promotion_options(hero_id)["error_code"], &"insufficient_xp")
	for ordinal: int in range(2, 5):
		state = _play_clear(state, store, "s1", "xp-%d" % ordinal)
	assert_eq(_hero(state.data_copy(), hero_id)["xp"], 400)
	assert_eq(state.promotion_options(hero_id)["error_code"], &"locked_class")
	for stage_number: int in range(2, 6):
		state = _play_clear(state, store, "s%d" % stage_number, "unlock-%d" % stage_number)
	assert_eq(
		state.promotion_options(hero_id)["choices"].map(
			func(row: Dictionary) -> String: return row["to_class_id"]
		),
		["sorcerer"],
	)
	state = _play_clear(state, store, "s6", "unlock-6")
	state = _play_clear(state, store, "s7", "unlock-7")
	assert_eq(
		state.promotion_options(hero_id)["choices"].map(
			func(row: Dictionary) -> String: return row["to_class_id"]
		),
		["sorcerer", "witch_doctor"],
	)
	var advanced := _commit(
		(
			state
			. confirm_promotions(
				"mage-advanced",
				state.save_revision(),
				[
					{
						"hero_id": hero_id,
						"to_class_id": "witch_doctor",
					}
				]
			)
		),
		store,
	)
	assert_true(advanced["accepted"], str(advanced.get("error_code", &"")))
	var final_state: CampaignStateV3 = advanced["payload"]["state"]
	var hero := _hero(final_state.data_copy(), hero_id)
	assert_eq(hero["first_class_id"], "mage_apprentice")
	assert_eq(hero["advanced_class_id"], "witch_doctor")
	assert_eq(hero["current_class_id"], "witch_doctor")
	assert_eq(final_state.promotion_options(hero_id)["error_code"], &"already_promoted_class")


func test_command_receipt_ledger_is_full_hash_bound_but_outside_core_hash() -> void:
	var fresh := _fresh()
	var hero_id := _ready_ids(fresh)[0]
	var command := fresh.begin_attempt("hash-ledger", "s1", [hero_id], 42, 1)
	assert_true(command["accepted"], str(command.get("error_code", &"")))
	var with_ledger: CampaignStateV3 = (
		(command["payload"]["mutation"] as CampaignMutation)._prospective_state
	)
	var without_data := with_ledger.data_copy()
	without_data["command_receipts"] = []
	var restored := CampaignStateV3.restore(without_data, ContextScript.build())
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	var without_ledger: CampaignStateV3 = restored["value"]
	assert_ne(with_ledger.strategic_hash()["hex"], without_ledger.strategic_hash()["hex"])
	assert_eq(with_ledger.core_hash()["hex"], without_ledger.core_hash()["hex"])


func test_resolution_rejects_forged_payload_rows_and_terminal_facts_without_mutation() -> void:
	var begun := _begun_two()
	var state: CampaignStateV3 = begun["state"]
	var ticket: Dictionary = state.data_copy()["tickets"][-1]
	var base := _outcome(ticket, "clear", [], 3)
	var cases: Array[Dictionary] = []
	var forged_hash: Dictionary = base.duplicate(true)
	forged_hash["outcome_hash"] = "0".repeat(64)
	cases.append({"value": forged_hash, "code": &"outcome_hash_mismatch"})
	var omitted: Dictionary = base.duplicate(true)
	omitted["rows"].pop_back()
	cases.append({"value": omitted, "code": &"outcome_ticket_mismatch"})
	var duplicate: Dictionary = base.duplicate(true)
	duplicate["rows"][1] = duplicate["rows"][0].duplicate(true)
	duplicate["rows"][1]["slot_index"] = 1
	cases.append({"value": duplicate, "code": &"duplicate_outcome_identity"})
	var attribution: Dictionary = base.duplicate(true)
	attribution["rows"][0]["hero_id"] = "aaaaaaaaaaaaaaaa"
	cases.append({"value": attribution, "code": &"outcome_ticket_mismatch"})
	var terminal: Dictionary = base.duplicate(true)
	terminal["result"] = "defeat"
	cases.append({"value": terminal, "code": &"invalid_outcome_terminal"})
	for index: int in cases.size():
		var row: Dictionary = cases[index]
		_assert_rejected_unchanged(
			state,
			state.resolve_attempt("forged-%d" % index, 1, row["value"], 2),
			row["code"],
		)


func test_restore_rejects_self_consistent_impossible_promotion_histories() -> void:
	var context := ContextScript.build()
	var resolved := _resolved_two_survivors()
	var base: CampaignStateV3 = resolved["state"]
	var hero_id := _ready_ids(base)[0]
	var insufficient := _append_forged_promotion(
		base.data_copy(),
		hero_id,
		"forged-first",
		"mage_apprentice",
		"caster_1",
	)
	insufficient = _append_forged_promotion(
		insufficient,
		hero_id,
		"forged-advanced",
		"sorcerer",
		"caster_2",
	)
	assert_false(CampaignStateV3.restore(insufficient, context)["accepted"])
	var begun := _begun_two()
	var begun_state: CampaignStateV3 = begun["state"]
	var ticket: Dictionary = begun_state.data_copy()["tickets"][-1]
	var fallen_id: String = ticket["squad"][0]["hero_id"]
	var death_result := _commit(
		(
			begun_state
			. resolve_attempt(
				"dead-resolve",
				1,
				_outcome(ticket, "clear", [fallen_id], 3),
				2,
			)
		),
		begun["store"],
	)
	var dead_state: CampaignStateV3 = death_result["payload"]["state"]
	var dead_forgery := _append_forged_promotion(
		dead_state.data_copy(),
		fallen_id,
		"forged-dead",
		"defender",
		"defender_1",
	)
	assert_false(CampaignStateV3.restore(dead_forgery, context)["accepted"])
	var locked_setup := _resolved_two_survivors()
	var locked_base: CampaignStateV3 = locked_setup["state"]
	hero_id = _ready_ids(locked_base)[0]
	var promotion := _commit(
		(
			locked_base
			. confirm_promotions(
				"legit-mage",
				3,
				[
					{
						"hero_id": hero_id,
						"to_class_id": "mage_apprentice",
					}
				]
			)
		),
		locked_setup["store"],
	)
	var experienced: CampaignStateV3 = promotion["payload"]["state"]
	for ordinal: int in range(2, 5):
		experienced = _play_clear(
			experienced,
			locked_setup["store"],
			"s1",
			"locked-xp-%d" % ordinal,
		)
	assert_eq(_hero(experienced.data_copy(), hero_id)["xp"], 400)
	assert_false((experienced.data_copy()["class_entitlements"] as Array).has("sorcerer"))
	var locked := _append_forged_promotion(
		experienced.data_copy(),
		hero_id,
		"forged-locked",
		"sorcerer",
		"caster_2",
	)
	assert_false(CampaignStateV3.restore(locked, context)["accepted"])


func _fresh() -> CampaignStateV3:
	var created := CampaignStateV3.create(42, 1, ContextScript.build())
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	return created["value"]


func _begun_two() -> Dictionary:
	var state := _fresh()
	var store := _seed_store(state)
	var ids := _ready_ids(state)
	var committed := _commit(state.begin_attempt("begin-two", "s1", [ids[0], ids[1]], 42, 1), store)
	assert_true(committed["accepted"], str(committed.get("error_code", &"")))
	return {"state": committed["payload"]["state"], "store": store}


func _resolved_two_survivors() -> Dictionary:
	var begun := _begun_two()
	var state: CampaignStateV3 = begun["state"]
	var ticket: Dictionary = state.data_copy()["tickets"][-1]
	var committed := _commit(
		state.resolve_attempt("resolve-two", 1, _outcome(ticket, "clear", [], 3), 2),
		begun["store"],
	)
	assert_true(committed["accepted"], str(committed.get("error_code", &"")))
	return {"state": committed["payload"]["state"], "store": begun["store"]}


func _play_clear(
	state: CampaignStateV3,
	store: CampaignSaveStore,
	stage_id: String,
	suffix: String,
) -> CampaignStateV3:
	var begun := _commit(
		(
			state
			. begin_attempt(
				"begin-%s" % suffix,
				stage_id,
				[_ready_ids(state)[0]],
				40 + state.next_attempt_id(),
				state.save_revision(),
			)
		),
		store,
	)
	assert_true(begun["accepted"], str(begun.get("error_code", &"")))
	var begun_state: CampaignStateV3 = begun["payload"]["state"]
	var ticket: Dictionary = begun_state.data_copy()["tickets"][-1]
	var resolved := _commit(
		(
			begun_state
			. resolve_attempt(
				"resolve-%s" % suffix,
				ticket["attempt_id"],
				_outcome(ticket, "clear", [], 3),
				begun_state.save_revision(),
			)
		),
		store,
	)
	assert_true(resolved["accepted"], str(resolved.get("error_code", &"")))
	return resolved["payload"]["state"]


func _seed_store(state: CampaignStateV3) -> CampaignSaveStore:
	_cleanup_slot()
	var created := CampaignSaveStore.create_production(state)
	assert_true(created["accepted"])
	var file := FileAccess.open(CampaignSaveStore.PRODUCTION_SLOT, FileAccess.WRITE)
	assert_not_null(file)
	file.store_buffer(state.encode_save()["bytes"])
	file.close()
	return created["value"]


func _commit(command: Dictionary, store: CampaignSaveStore) -> Dictionary:
	assert_true(command["accepted"], str(command.get("error_code", &"")))
	if not command["accepted"]:
		return command
	return (command["payload"]["mutation"] as CampaignMutation).retry_save(store)


func _outcome(
	ticket: Dictionary,
	result: String,
	fallen_ids: Array[String],
	stars: int,
) -> Dictionary:
	var rows: Array[Dictionary] = []
	for frozen: Dictionary in ticket["squad"]:
		var fell := fallen_ids.has(String(frozen["hero_id"]))
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
					"fell": fell,
					"first_fall_tick": 60 if fell else null,
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
				"result": result,
				"terminal_reason": "clear" if result == "clear" else "base_defeat",
				"terminal_tick": 120,
				"stars": stars,
				"leaks": 0 if result == "clear" else 3,
				"kills": 5,
				"rows": rows,
			},
			ticket
		)
	)
	assert_true(sealed["accepted"], str(sealed.get("error_code", &"")))
	return sealed["value"]


func _ready_ids(state: CampaignStateV3) -> Array[String]:
	var result: Array[String] = []
	for hero: Dictionary in state.data_copy()["heroes"]:
		if hero["life_status"] == "ready":
			result.append(String(hero["hero_id"]))
	return result


func _hero(data: Dictionary, hero_id: String) -> Dictionary:
	for hero: Dictionary in data["heroes"]:
		if hero["hero_id"] == hero_id:
			return hero
	return {}


func _append_forged_promotion(
	data: Dictionary,
	hero_id: String,
	command_id: String,
	to_class_id: String,
	operator_def_id: String,
) -> Dictionary:
	var forged: Dictionary = data.duplicate(true)
	var hero := _hero(forged, hero_id)
	var from_class_id := String(hero["current_class_id"])
	var expected_revision := int(forged["save_revision"])
	var receipt := {
		"command_id": command_id,
		"save_revision": expected_revision + 1,
		"choices":
		[
			{
				"hero_id": hero_id,
				"from_class_id": from_class_id,
				"to_class_id": to_class_id,
			}
		],
	}
	forged["promotion_receipts"].append(receipt)
	(
		forged["command_receipts"]
		. append(
			(
				CampaignV3CommandCodec
				. record(
					command_id,
					"confirm_promotions",
					expected_revision,
					{"choices": [{"hero_id": hero_id, "to_class_id": to_class_id}]},
					{"promotion": receipt},
				)
			)
		)
	)
	hero["operator_def_id"] = operator_def_id
	hero["current_class_id"] = to_class_id
	if hero["first_class_id"] == "recruit":
		hero["first_class_id"] = to_class_id
	else:
		hero["advanced_class_id"] = to_class_id
	forged["save_revision"] = expected_revision + 1
	return forged


func _snapshot(state: CampaignStateV3) -> Dictionary:
	var data := state.data_copy()
	return {
		"save": state.encode_save()["text"],
		"checksum": state.encode_data()["sha256"],
		"full_hash": state.strategic_hash()["hex"],
		"core_hash": state.core_hash()["hex"],
		"revision": state.save_revision(),
		"heroes": data["heroes"],
		"receipts": data["promotion_receipts"],
		"commands": data["command_receipts"],
		"tickets": data["tickets"],
		"memorial": data["memorial"],
		"counters":
		[data["next_recruitment_index"], data["next_attempt_id"], data["next_resolution_index"]],
		"seed": data["campaign_seed"],
	}


func _assert_rejected_unchanged(
	state: CampaignStateV3,
	result: Dictionary,
	code: StringName,
) -> void:
	var before := _snapshot(state)
	assert_false(result["accepted"])
	assert_eq(result["error_code"], code)
	assert_eq(_snapshot(state), before)


func after_each() -> void:
	_cleanup_slot()


func _cleanup_slot() -> void:
	for path: String in [
		CampaignSaveStore.PRODUCTION_SLOT,
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".tmp",
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".bak",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
