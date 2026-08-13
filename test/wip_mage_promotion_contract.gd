extends GutTest

const CONTRACT_PATH := "res://test/fixtures/p16/promotion_contract_v1.json"


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


func test_promotion_model_surface_has_landed() -> void:
	var state := _fresh()
	var hero := state.roster().all()[0]
	assert_true(state.has_method("promotion_options"))
	assert_true(state.has_method("promote_hero"))
	for method_name: String in [
		"acquisition_operator_def_id",
		"first_class_id",
		"advanced_class_id",
		"progression_rules_version",
		"xp",
		"identity_portrait_id",
	]:
		assert_true(hero.has_method(method_name), "missing HeroState.%s" % method_name)


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


func _fresh() -> CampaignState:
	var created := CampaignState.create(42, 1, _definition(), _catalogs(), _stages())
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	return created["value"] as CampaignState


func _definition() -> CampaignDef:
	return load("res://data/campaigns/p16_v1.tres") as CampaignDef


func _catalogs() -> Dictionary:
	return {
		"operators": _catalog_ids("res://data/operators"),
		"traps": _catalog_ids("res://data/traps"),
		"spells": _catalog_ids("res://data/spells"),
	}


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
