extends GutTest

const CONTRACT_PATH := "res://test/fixtures/p16/promotion_contract_v1.json"
const TRANSACTION_PATH := "res://test/fixtures/p16/transaction_vectors_v2.json"


func test_contract_pins_company_33_mage_destinations() -> void:
	var contract := _contract()
	var rules: Dictionary = contract["rules"]
	assert_eq(contract["company_name"], "Company 33")
	assert_eq(rules["progression_rules_version"], 1)
	assert_eq(rules["source_class_id"], "mage_apprentice")
	assert_eq(rules["advanced_xp_required"], 400)
	assert_eq(rules["promotion_marks_cost"], 0)
	assert_eq(rules["eligible_life_status"], "ready")
	assert_false(rules["respec_available"])
	assert_true(rules["choice_is_permanent"])
	assert_false(rules["xp_is_consumed"])
	assert_eq(contract["choices"].map(
		func(choice: Dictionary) -> String: return choice["advanced_class_id"]
	), ["witch_doctor", "sorcerer"])
	assert_eq(contract["choices"].map(
		func(choice: Dictionary) -> String: return choice["operator_def_id"]
	), ["witch_doctor_1", "caster_2"])
	assert_eq(contract["choices"].map(
		func(choice: Dictionary) -> int: return choice["dp_cost"]
	), [18, 20])


func test_contract_pins_complete_exactly_once_xp_rules() -> void:
	var rules: Dictionary = _contract()["rules"]
	assert_eq(rules["xp_domain"], {
		"type": "signed_int64",
		"minimum": 0,
		"maximum": 9223372036854775807,
		"checked_addition": true,
		"overflow_error": "xp_overflow",
		"overflow_rejects_whole_resolution": true,
		"overflow_reject_is_byte_equal": true,
		"overflow_reject_is_hash_equal": true,
	})
	assert_eq(rules["xp_derivation"], {
		"source": "authoritative_exactly_once_operation_resolution",
		"deduplicate_by": "hero_id",
		"requires_accepted_deploy": true,
		"retreat_preserves_credit": true,
		"preview_delta": 0,
		"ui_visit_delta": 0,
		"rejected_outcome_delta": 0,
		"exact_retry_delta": 0,
		"repeated_receipt_delta": 0,
	})
	assert_eq(rules["xp_awards"], [
		{"condition": "unique_deployed_ready_clear", "delta": 100},
		{"condition": "unique_deployed_ready_defeat", "delta": 100},
		{"condition": "unique_deployed_retreated_ready", "delta": 100},
		{"condition": "never_deployed", "delta": 0},
		{"condition": "dead_in_committed_outcome", "delta": 0},
		{
			"condition": "dead_before_attempt",
			"delta": 0,
			"ticket_eligible": false,
		},
		{"condition": "already_promoted_deployed_ready", "delta": 100},
		{
			"condition": "duplicate_same_outcome",
			"delta": 0,
			"returns_exact_stored_receipt": true,
		},
	])


func test_contract_migration_is_exact_and_total_over_current_templates() -> void:
	var rows: Array = _contract()["migration"]
	var actual: Array[String] = []
	var expected_advanced := {
		"vanguard_1": null,
		"vanguard_2": "banner_guard",
		"guard_1": null,
		"guard_2": "sword_saint",
		"defender_1": null,
		"defender_2": "immovable",
		"sniper_1": null,
		"sniper_2": "sniper",
		"caster_1": null,
		"caster_2": "sorcerer",
		"witch_doctor_1": "witch_doctor",
	}
	var expected_first := {
		"vanguard_1": "shock_trooper",
		"vanguard_2": "shock_trooper",
		"guard_1": "swordmaster",
		"guard_2": "swordmaster",
		"defender_1": "defender",
		"defender_2": "defender",
		"sniper_1": "gunner",
		"sniper_2": "gunner",
		"caster_1": "mage_apprentice",
		"caster_2": "mage_apprentice",
		"witch_doctor_1": "mage_apprentice",
	}
	for row: Dictionary in rows:
		var template: String = row["v1_template"]
		actual.append(template)
		assert_eq(_sorted_keys(row), [
			"acquisition_operator_def_id",
			"advanced_class_id",
			"first_class_id",
			"identity_portrait_id",
			"operator_def_id",
			"progression_rules_version",
			"v1_template",
			"xp",
		])
		assert_eq(row["acquisition_operator_def_id"], template)
		assert_eq(row["operator_def_id"], template)
		assert_eq(row["identity_portrait_id"], template)
		assert_eq(row["first_class_id"], expected_first[template])
		assert_eq(row["advanced_class_id"], expected_advanced[template])
		assert_eq(row["progression_rules_version"], 1)
		assert_eq(row["xp"], 0)
	actual.sort()
	var expected_strings: Array[String] = []
	for operator_id: StringName in _catalog_ids("res://data/operators"):
		if operator_id == &"recruit":
			continue
		expected_strings.append(String(operator_id))
	expected_strings.sort()
	assert_eq(actual, expected_strings)
	assert_eq(actual.size(), 11)


func test_contract_pins_identity_command_receipt_and_replay_semantics() -> void:
	var contract := _contract()
	assert_eq(contract["mutation"], {
		"changed_hero_fields": ["advanced_class_id", "operator_def_id"],
		"preserved_hero_fields": [
			"hero_id",
			"identity_portrait_id",
			"acquisition_operator_def_id",
			"first_class_id",
			"progression_rules_version",
			"recruitment_index",
			"recruited_after_resolution_index",
			"recruit_source",
			"source_id",
			"name_version",
			"custom_callsign",
			"life_status",
			"death",
			"xp",
		],
		"preserves_unrelated_heroes": true,
		"preserves_unrelated_campaign_fields": true,
		"identity_portrait_uses_current_operator_projection": false,
	})
	var command: Dictionary = contract["command"]
	assert_eq(command["version"], 1)
	assert_eq(command["verb"], "promote_hero")
	assert_eq(
		command["id_format"],
		"promote:<campaign_uid>:<expected_save_revision>:<hero_id>:<choice>",
	)
	assert_eq(command["ordered_keys"], [
		"version", "verb", "command_id", "hero_id",
		"advanced_class_id", "expected_save_revision",
	])
	assert_eq(command["accepted_receipt_ordered_keys"], [
		"version", "command_id", "verb", "hero_id", "prior_class_id",
		"new_class_id", "prior_operator_def_id", "new_operator_def_id",
		"prior_save_revision", "new_save_revision", "before_strategic_hash",
		"after_strategic_hash",
	])
	assert_eq(command["exact_retry"], {
		"same_command_id_same_payload": "return_stored_receipt_byte_for_byte",
		"additional_revision_delta": 0,
		"additional_xp_delta": 0,
	})
	assert_eq(command["conflict"], {
		"same_command_id_different_payload_error": "command_id_conflict",
		"reject_is_byte_equal": true,
		"reject_is_hash_equal": true,
	})
	assert_eq(command["after_commit"], {
		"new_command_id_error": "already_promoted",
		"alternate_path_error": "already_promoted",
		"reject_is_byte_equal": true,
		"reject_is_hash_equal": true,
	})
	assert_eq(command["stale_revision"], {
		"error": "stale_revision",
		"reject_is_byte_equal": true,
		"reject_is_hash_equal": true,
	})
	assert_false(command["cancel_emits_command"])
	assert_false(command["cancel_emits_replay_row"])
	var replay: Dictionary = contract["strategic_replay_v2"]
	assert_eq(replay["row_ordered_keys"], ["seq", "verb", "args"])
	assert_eq(replay["verb"], "promote_hero")
	assert_eq(replay["args_ordered_keys"], [
		"version", "command_id", "hero_id",
		"advanced_class_id", "expected_save_revision",
	])
	assert_eq(replay["seq"], "monotonically_increasing_integer")
	assert_eq(replay["result_ordered_keys"], [
		"accepted", "error_code", "receipt_bytes",
		"save_revision", "strategic_hash",
	])
	assert_eq(replay["goldens"], [
		"witch_doctor_accepted",
		"sorcerer_accepted",
		"cancel_no_command",
		"exact_retry",
		"command_id_conflict",
		"alternate_path_after_commit",
		"malformed_type",
		"stale_revision",
		"save_load_restart",
		"two_process_equality",
	])
	assert_eq(contract["reject_error_codes"], [
		"invalid_argument_type",
		"unknown_hero",
		"hero_not_ready",
		"insufficient_xp",
		"wrong_source_class",
		"invalid_choice",
		"already_promoted",
		"stale_revision",
		"command_id_conflict",
		"xp_overflow",
	])


func test_p16_2_base_save_authority_has_landed() -> void:
	var minimum_version := int(_contract()["dependency"]["minimum_save_version"])
	assert_gte(
		CampaignCodec.SAVE_VERSION,
		minimum_version,
		"P16.2 base must own the versioned strategic save before promotion mutates state",
	)


func test_progression_save_surface_has_landed() -> void:
	var state := _fresh()
	var hero := state.roster().all()[0]
	for method_name: String in [
		"acquisition_operator_def_id",
		"first_class_id",
		"advanced_class_id",
		"progression_rules_version",
		"xp",
		"identity_portrait_id",
	]:
		assert_true(hero.has_method(method_name), "missing HeroState.%s" % method_name)
	assert_eq(hero.acquisition_operator_def_id(), &"caster_1")
	assert_eq(hero.first_class_id(), &"mage_apprentice")
	assert_null(hero.advanced_class_id())
	assert_eq(hero.progression_rules_version(), 1)
	assert_eq(hero.xp(), 0)
	assert_eq(hero.identity_portrait_id(), &"caster_1")
	var restored := CampaignState.restore(
		state.data_copy(), _definition(), _catalogs(), _stages(),
	)
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	assert_eq((restored["value"] as CampaignState).encode_data(), state.encode_data())


func test_promotion_options_are_pure_and_pin_the_399_400_boundary() -> void:
	var under := _promotion_state(399)
	var hero_id := String(under.data_copy()["heroes"][0]["hero_id"])
	var under_bytes: PackedByteArray = under.encode_data()["bytes"]
	var under_hash := String(under.strategic_hash()["hex"])
	var rejected: Dictionary = under.promotion_options(hero_id)
	assert_false(rejected["accepted"])
	assert_eq(rejected["error_code"], &"insufficient_xp")
	assert_eq(under.encode_data()["bytes"], under_bytes)
	assert_eq(under.strategic_hash()["hex"], under_hash)

	var ready := _promotion_state(400)
	var options: Dictionary = ready.promotion_options(hero_id)
	assert_true(options["accepted"], str(options.get("error_code", &"")))
	assert_eq(options["hero_id"], hero_id)
	assert_eq(options["xp"], 400)
	assert_eq(options["xp_required"], 400)
	assert_eq(options["choices"], _contract()["choices"])
	(options["choices"] as Array).clear()
	assert_eq(ready.promotion_options(hero_id)["choices"], _contract()["choices"])


func test_promote_hero_accepts_witch_doctor_with_exact_receipt_and_identity() -> void:
	var state := _promotion_state(400)
	var before := state.data_copy()
	var hero: Dictionary = before["heroes"][0]
	var before_hash := String(state.strategic_hash()["hex"])
	var command := _command(state, String(hero["hero_id"]), "witch_doctor")
	var result: Dictionary = state.promote_hero(command)
	assert_true(result["accepted"], str(result.get("error_code", &"")))
	var receipt: Dictionary = result["receipt"]
	assert_eq(_keys(receipt), _contract()["command"]["accepted_receipt_ordered_keys"])
	assert_eq(receipt, {
		"version": 1,
		"command_id": command["command_id"],
		"verb": "promote_hero",
		"hero_id": hero["hero_id"],
		"prior_class_id": "mage_apprentice",
		"new_class_id": "witch_doctor",
		"prior_operator_def_id": "caster_1",
		"new_operator_def_id": "witch_doctor_1",
		"prior_save_revision": 1,
		"new_save_revision": 2,
		"before_strategic_hash": before_hash,
		"after_strategic_hash": state.strategic_hash()["hex"],
	})
	assert_eq(result["receipt_bytes"], CanonicalJson.text(receipt).to_utf8_buffer())
	var after := state.data_copy()
	var promoted: Dictionary = after["heroes"][0]
	assert_eq(promoted["advanced_class_id"], "witch_doctor")
	assert_eq(promoted["operator_def_id"], "witch_doctor_1")
	for key: String in _contract()["mutation"]["preserved_hero_fields"]:
		assert_eq(promoted[key], hero[key], key)
	assert_eq(after["promotion_receipts"], [receipt])
	assert_eq(after["save_revision"], 2)
	assert_ne(state.strategic_hash()["hex"], before_hash)


func test_promote_hero_accepts_sorcerer_and_choice_is_permanent() -> void:
	var state := _promotion_state(900)
	var hero: Dictionary = state.data_copy()["heroes"][0]
	var first: Dictionary = state.promote_hero(_command(
		state, String(hero["hero_id"]), "sorcerer",
	))
	assert_true(first["accepted"])
	assert_eq(first["receipt"]["new_class_id"], "sorcerer")
	assert_eq(first["receipt"]["new_operator_def_id"], "caster_2")
	assert_eq(state.data_copy()["heroes"][0]["xp"], 900)
	var after_bytes: PackedByteArray = state.encode_data()["bytes"]
	var after_hash := String(state.strategic_hash()["hex"])
	var second: Dictionary = state.promote_hero(_command(
		state, String(hero["hero_id"]), "witch_doctor",
	))
	assert_false(second["accepted"])
	assert_eq(second["error_code"], &"already_promoted")
	assert_eq(state.encode_data()["bytes"], after_bytes)
	assert_eq(state.strategic_hash()["hex"], after_hash)


func test_exact_retry_returns_stored_receipt_and_conflict_is_hash_equal() -> void:
	var state := _promotion_state(400)
	var hero_id := String(state.data_copy()["heroes"][0]["hero_id"])
	var command := _command(state, hero_id, "witch_doctor")
	var accepted: Dictionary = state.promote_hero(command)
	assert_true(accepted["accepted"])
	var after_bytes: PackedByteArray = state.encode_data()["bytes"]
	var after_hash := String(state.strategic_hash()["hex"])
	var retry: Dictionary = state.promote_hero(command.duplicate(true))
	assert_true(retry["accepted"])
	assert_eq(retry["receipt"], accepted["receipt"])
	assert_eq(retry["receipt_bytes"], accepted["receipt_bytes"])
	assert_eq(state.encode_data()["bytes"], after_bytes)
	assert_eq(state.strategic_hash()["hex"], after_hash)

	var conflict := command.duplicate(true)
	conflict["advanced_class_id"] = "sorcerer"
	var rejected: Dictionary = state.promote_hero(conflict)
	assert_false(rejected["accepted"])
	assert_eq(rejected["error_code"], &"command_id_conflict")
	assert_eq(state.encode_data()["bytes"], after_bytes)
	assert_eq(state.strategic_hash()["hex"], after_hash)


func test_promotion_reject_matrix_is_zero_state_change() -> void:
	var cases: Array[Dictionary] = []
	var insufficient := _fresh()
	var mage_id := String(insufficient.data_copy()["heroes"][0]["hero_id"])
	cases.append({
		"state": insufficient,
		"command": _command(insufficient, mage_id, "witch_doctor"),
		"error": &"insufficient_xp",
	})
	var ready := _promotion_state(400)
	var ready_id := String(ready.data_copy()["heroes"][0]["hero_id"])
	cases.append({
		"state": ready,
		"command": _command(ready, "ffffffffffffffff", "witch_doctor"),
		"error": &"unknown_hero",
	})
	var wrong_id := String(ready.data_copy()["heroes"][1]["hero_id"])
	cases.append({
		"state": ready,
		"command": _command(ready, wrong_id, "witch_doctor"),
		"error": &"wrong_source_class",
	})
	cases.append({
		"state": ready,
		"command": _command(ready, ready_id, "necromancer"),
		"error": &"invalid_choice",
	})
	var stale := _command(ready, ready_id, "witch_doctor")
	stale["expected_save_revision"] = 2
	stale["command_id"] = _command_id(ready, 2, ready_id, "witch_doctor")
	cases.append({"state": ready, "command": stale, "error": &"stale_revision"})
	var malformed := _command(ready, ready_id, "witch_doctor")
	malformed["expected_save_revision"] = 1.0
	cases.append({
		"state": ready,
		"command": malformed,
		"error": &"invalid_argument_type",
	})
	var resolved := _resolved()
	var dead_id := "cb0a9db634ff05af"
	cases.append({
		"state": resolved,
		"command": _command(resolved, dead_id, "witch_doctor"),
		"error": &"hero_not_ready",
	})
	for item: Dictionary in cases:
		var target := item["state"] as CampaignState
		var before_bytes: PackedByteArray = target.encode_data()["bytes"]
		var before_hash := String(target.strategic_hash()["hex"])
		var result: Dictionary = target.promote_hero(item["command"])
		assert_false(result["accepted"], str(item["error"]))
		assert_eq(result["error_code"], item["error"])
		assert_eq(target.encode_data()["bytes"], before_bytes, str(item["error"]))
		assert_eq(target.strategic_hash()["hex"], before_hash, str(item["error"]))


func test_promotion_receipt_round_trip_hash_paranoia_and_replay_v2() -> void:
	var state := _promotion_state(400)
	var hero_id := String(state.data_copy()["heroes"][0]["hero_id"])
	var command := _command(state, hero_id, "witch_doctor")
	var accepted: Dictionary = state.promote_hero(command)
	assert_true(accepted["accepted"])
	var encoded := CampaignCodec.encode_save(state.data_copy(), _context())
	assert_true(encoded["accepted"], str(encoded.get("error_code", &"")))
	var decoded := CampaignCodec.decode_save(encoded["text"], _context())
	assert_true(decoded["accepted"], str(decoded.get("error_code", &"")))
	var restored_result := CampaignState.restore(
		decoded["data"], _definition(), _catalogs(), _stages(),
	)
	assert_true(restored_result["accepted"], str(restored_result.get("error_code", &"")))
	var restored := restored_result["value"] as CampaignState
	assert_eq(restored.encode_data()["bytes"], state.encode_data()["bytes"])
	assert_eq(restored.strategic_hash()["hex"], state.strategic_hash()["hex"])
	assert_eq(restored.data_copy()["promotion_proofs"].size(), 1)
	assert_eq(restored.promote_hero(command)["receipt_bytes"], accepted["receipt_bytes"])

	var normalized := state.data_copy()
	var baseline := String(CampaignHash.of_normalized_data(normalized, false)["hex"])
	for key: String in [
		"command_id", "hero_id", "prior_class_id", "new_class_id",
		"prior_operator_def_id", "new_operator_def_id", "prior_save_revision",
		"before_strategic_hash",
	]:
		var changed: Dictionary = normalized.duplicate(true)
		var receipt: Dictionary = changed["promotion_receipts"][0]
		if key in ["prior_save_revision"]:
			receipt[key] = int(receipt[key]) + 2
		else:
			receipt[key] = String(receipt[key]) + "x"
		assert_ne(
			CampaignHash.of_normalized_data(changed, false)["hex"], baseline, key,
		)
	var forged: Dictionary = normalized.duplicate(true)
	forged["promotion_receipts"][0]["after_strategic_hash"] = "0".repeat(16)
	assert_false(CampaignCodec.encode_data(forged, _context())["accepted"])

	var row: Dictionary = CampaignPromotion.replay_row(1, command)
	assert_eq(_keys(row), _contract()["strategic_replay_v2"]["row_ordered_keys"])
	assert_eq(_keys(row["args"]), _contract()["strategic_replay_v2"]["args_ordered_keys"])
	var replay: Dictionary = CampaignPromotion.encode_replay_rows([row])
	assert_true(replay["accepted"], str(replay.get("error_code", &"")))
	var replay_result: Dictionary = CampaignPromotion.replay_result(accepted, state)
	assert_eq(_keys(replay_result), _contract()["strategic_replay_v2"]["result_ordered_keys"])
	assert_true(replay_result["accepted"])
	assert_eq(replay_result["receipt_bytes"], Array(accepted["receipt_bytes"]))
	assert_eq(replay_result["save_revision"], 2)
	assert_eq(replay_result["strategic_hash"], state.strategic_hash()["hex"])


func test_promotion_after_resolution_preserves_anchor_closure() -> void:
	var state := _resolved_promotion_state()
	var hero_id := String(state.data_copy()["heroes"][0]["hero_id"])
	var accepted: Dictionary = state.promote_hero(_command(
		state, hero_id, "sorcerer",
	))
	assert_true(accepted["accepted"], str(accepted.get("error_code", &"")))
	var data := state.data_copy()
	assert_eq(data["save_revision"], 5)
	assert_eq(data["promotion_receipts"].size(), 1)
	assert_eq(data["promotion_proofs"].size(), 1)
	assert_true(data["resolution_anchor"]["after_core"]["promotion_receipts"].is_empty())
	assert_true(data["resolution_anchor"]["after_core"]["promotion_proofs"].is_empty())
	var restored := CampaignState.restore(data, _definition(), _catalogs(), _stages())
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	assert_eq(
		(restored["value"] as CampaignState).strategic_hash()["hex"],
		state.strategic_hash()["hex"],
	)


func test_two_promotions_preserve_historical_retry_and_chain_hashes() -> void:
	var state := _two_mage_state()
	var heroes: Array = state.data_copy()["heroes"]
	var first_command := _command(state, String(heroes[0]["hero_id"]), "witch_doctor")
	var first: Dictionary = state.promote_hero(first_command)
	assert_true(first["accepted"])
	var second_command := _command(state, String(heroes[5]["hero_id"]), "sorcerer")
	var second: Dictionary = state.promote_hero(second_command)
	assert_true(second["accepted"])
	assert_eq(state.data_copy()["promotion_receipts"].size(), 2)
	assert_eq(state.data_copy()["promotion_proofs"].size(), 2)
	var before_retry: PackedByteArray = state.encode_data()["bytes"]
	var historical_retry: Dictionary = state.promote_hero(first_command)
	assert_true(historical_retry["accepted"])
	assert_eq(historical_retry["receipt_bytes"], first["receipt_bytes"])
	assert_eq(state.encode_data()["bytes"], before_retry)
	var restored := CampaignState.restore(
		state.data_copy(), _definition(), _catalogs(), _stages(),
	)
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	var forged := state.data_copy()
	forged["promotion_receipts"][0]["after_strategic_hash"] = "0".repeat(16)
	assert_false(CampaignCodec.encode_data(forged, _context())["accepted"])


func test_historical_receipt_hashes_remain_closed_after_revision_advances() -> void:
	var state := _promotion_state(400)
	var hero_id := String(state.data_copy()["heroes"][0]["hero_id"])
	assert_true(state.promote_hero(_command(state, hero_id, "witch_doctor"))["accepted"])
	var historical := state.data_copy()
	historical["save_revision"] = int(historical["save_revision"]) + 1
	var valid := CampaignState.restore(
		historical, _definition(), _catalogs(), _stages(),
	)
	assert_true(valid["accepted"], str(valid.get("error_code", &"")))
	for field: String in ["before_strategic_hash", "after_strategic_hash"]:
		var forged: Dictionary = historical.duplicate(true)
		forged["promotion_receipts"][0][field] = "0".repeat(16)
		assert_false(CampaignCodec.encode_data(forged, _context())["accepted"], field)
		assert_false(CampaignState.restore(
			forged, _definition(), _catalogs(), _stages(),
		)["accepted"], field)
	var forged_proof: Dictionary = historical.duplicate(true)
	forged_proof["promotion_proofs"][0]["before_data"]["heroes"][0]["xp"] = 401
	assert_false(CampaignCodec.encode_data(forged_proof, _context())["accepted"])


func test_pre_command_v2_saves_upgrade_with_empty_promotion_history() -> void:
	var transaction := CampaignCodec.normalize_data(
		_json(TRANSACTION_PATH)["resolved_save"]["value"], _context(),
	)
	assert_true(transaction["accepted"], str(transaction.get("error_code", &"")))
	for modern: Dictionary in [
		_fresh().data_copy(),
		transaction["value"],
	]:
		var old := _without_promotion_receipts(modern)
		var root := {
			"schema": CampaignCodec.SAVE_SCHEMA,
			"version": CampaignCodec.SAVE_VERSION,
			"checksum": CanonicalJson.sha256_hex(old),
			"data": old,
		}
		var decoded := CampaignCodec.decode_save(CanonicalJson.text(root), _context())
		assert_true(decoded["accepted"], str(decoded.get("error_code", &"")))
		assert_eq(decoded["migrated_from_version"], CampaignCodec.SAVE_VERSION)
		assert_eq(decoded["data"], modern)
		assert_true(decoded["data"]["promotion_receipts"].is_empty())
		assert_true(decoded["data"]["promotion_proofs"].is_empty())


func _contract() -> Dictionary:
	var file := FileAccess.open(CONTRACT_PATH, FileAccess.READ)
	assert_not_null(file)
	var source := file.get_as_text()
	file.close()
	var parser := JSON.new()
	assert_eq(parser.parse(source), OK)
	var restored := CanonicalJson.restore_exact_integers(source, parser.data)
	assert_true(restored["accepted"])
	assert_eq(typeof(restored["value"]), TYPE_DICTIONARY)
	return restored["value"] as Dictionary


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file)
	var source := file.get_as_text()
	file.close()
	var parser := JSON.new()
	assert_eq(parser.parse(source), OK)
	var restored := CanonicalJson.restore_exact_integers(source, parser.data)
	assert_true(restored["accepted"])
	return (restored["value"] as Dictionary).duplicate(true)


func _fresh() -> CampaignState:
	var created := CampaignState.create(42, 1, _definition(), _catalogs(), _stages())
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	return created["value"] as CampaignState


func _promotion_state(xp: int) -> CampaignState:
	var data := _fresh().data_copy()
	data["heroes"][0]["xp"] = xp
	var restored := CampaignState.restore(data, _definition(), _catalogs(), _stages())
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	return restored["value"] as CampaignState


func _resolved() -> CampaignState:
	var fixture := _json(TRANSACTION_PATH)
	var restored := CampaignState.restore(
		fixture["resolved_save"]["value"], _definition(), _catalogs(), _stages(),
	)
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	return restored["value"] as CampaignState


func _resolved_promotion_state() -> CampaignState:
	var normalized := CampaignCodec.normalize_data(
		_json(TRANSACTION_PATH)["resolved_save"]["value"], _context(),
	)
	assert_true(normalized["accepted"], str(normalized.get("error_code", &"")))
	var data: Dictionary = normalized["value"]
	for section: String in ["before_core", "after_core"]:
		data["resolution_anchor"][section]["heroes"][0]["xp"] = 400
	data["heroes"][0]["xp"] = 400
	var before := CampaignHash.of_core_snapshot(
		data["resolution_anchor"]["before_core"], _context(),
	)
	var after := CampaignHash.of_core_snapshot(
		data["resolution_anchor"]["after_core"], _context(),
	)
	assert_true(before["accepted"])
	assert_true(after["accepted"])
	data["resolution_anchor"]["strategic_body_hash_before"] = before["hex"]
	data["resolution_anchor"]["strategic_body_hash_after"] = after["hex"]
	data["last_resolution"]["strategic_body_hash_before"] = before["hex"]
	data["last_resolution"]["strategic_body_hash_after"] = after["hex"]
	var restored := CampaignState.restore(data, _definition(), _catalogs(), _stages())
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	return restored["value"] as CampaignState


func _two_mage_state() -> CampaignState:
	var state := _fresh()
	var data := state.data_copy()
	var allocation := state.roster().plan_allocation(
		42, 1, 5, &"caster_1", &"contract", "p16_caster_contract", 0,
	)
	assert_true(allocation["accepted"])
	var second: Dictionary = allocation["row"]
	data["save_revision"] = 2
	data["next_recruitment_index"] = 6
	data["marks"] = 40
	data["offers"][0]["consumed"] = true
	data["heroes"][0]["xp"] = 400
	second["xp"] = 400
	data["heroes"].append(second)
	var restored := CampaignState.restore(data, _definition(), _catalogs(), _stages())
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	return restored["value"] as CampaignState


func _without_promotion_receipts(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	result.erase("combat_rules_sha256")
	result.erase("promotion_receipts")
	result.erase("promotion_proofs")
	if result["resolution_anchor"] != null:
		result["resolution_anchor"]["before_core"].erase("combat_rules_sha256")
		result["resolution_anchor"]["after_core"].erase("combat_rules_sha256")
		result["resolution_anchor"]["before_core"].erase("promotion_receipts")
		result["resolution_anchor"]["after_core"].erase("promotion_receipts")
		result["resolution_anchor"]["before_core"].erase("promotion_proofs")
		result["resolution_anchor"]["after_core"].erase("promotion_proofs")
	return result


func _command(state: CampaignState, hero_id: String, choice: String) -> Dictionary:
	var revision := state.save_revision()
	return {
		"version": 1,
		"verb": "promote_hero",
		"command_id": _command_id(state, revision, hero_id, choice),
		"hero_id": hero_id,
		"advanced_class_id": choice,
		"expected_save_revision": revision,
	}


func _command_id(
	state: CampaignState,
	revision: int,
	hero_id: String,
	choice: String,
) -> String:
	return "promote:%s:%d:%s:%s" % [
		state.campaign_uid(), revision, hero_id, choice,
	]


func _definition() -> CampaignDef:
	return load("res://data/campaigns/p16_v2.tres") as CampaignDef


func _catalogs() -> Dictionary:
	return {
		"operators": _catalog_ids("res://data/operators"),
		"traps": _catalog_ids("res://data/traps"),
		"spells": _catalog_ids("res://data/spells"),
	}


func _context() -> Dictionary:
	return CampaignCodec.build_context(
		_catalogs()["operators"], _catalogs()["traps"], _catalogs()["spells"],
		_stages(), _definition().paid_offers,
	)


func _stages() -> Array:
	var stages: Array = []
	for index: int in range(1, 9):
		stages.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	return stages


func _catalog_ids(path: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			ids.append(StringName(source.trim_suffix(".tres")))
	return ids


func _sorted_keys(value: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key: Variant in value.keys():
		keys.append(String(key))
	keys.sort()
	return keys


func _keys(value: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key: Variant in value.keys():
		keys.append(String(key))
	return keys
