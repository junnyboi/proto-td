extends GutTest

const ContextScript := preload("res://test/fixtures/p16/campaign_v3_context.gd")
const CAMPAIGN := preload("res://data/campaigns/p16_v3.tres")
const V1_PATH := "res://test/fixtures/p16/campaign_v1_seed42.json"
const V2_PATH := "res://test/fixtures/p16/campaign_v2_seed42.json"
const V3_PATH := "res://test/fixtures/p16/campaign_v3_seed42.json"
const FRESH_V3_PATH := "res://test/fixtures/p16/campaign_v3_fresh_seed42.json"


func test_fresh_v3_has_five_distinct_recruits_and_matches_golden() -> void:
	var context := ContextScript.build()
	assert_false(context.is_empty())
	var fresh := CampaignV3Codec.create_fresh(42, 1, context)
	assert_true(fresh["accepted"], str(fresh.get("error_code", &"")))
	var data: Dictionary = fresh["value"]
	assert_eq(data["heroes"].size(), 5)
	var hero_ids := {}
	var portrait_instances := {}
	var portrait_assets := {}
	for hero: Dictionary in data["heroes"]:
		assert_eq(hero["acquisition_operator_def_id"], "recruit")
		assert_eq(hero["operator_def_id"], "recruit")
		assert_eq(hero["current_class_id"], "recruit")
		assert_eq(hero["first_class_id"], "recruit")
		assert_null(hero["advanced_class_id"])
		assert_eq(hero["progression_rules_version"], 2)
		assert_eq(hero["portrait_instance_id"], "portrait:%s" % hero["hero_id"])
		hero_ids[hero["hero_id"]] = true
		portrait_instances[hero["portrait_instance_id"]] = true
		portrait_assets[hero["portrait_asset_id"]] = true
	assert_eq(hero_ids.size(), 5)
	assert_eq(portrait_instances.size(), 5)
	assert_eq(portrait_assets.size(), 5)
	assert_true(data["tickets"].is_empty())
	assert_true(data["memorial"].is_empty())
	assert_eq(data["offers"], [{
		"offer_id": "p16_caster_contract",
		"operator_def_id": "recruit",
		"cost": 80,
		"consumed": false,
	}])
	var encoded := CampaignCodec.encode_save_v3(data, context)
	assert_true(encoded["accepted"], str(encoded.get("error_code", &"")))
	assert_eq(encoded["text"], _text(FRESH_V3_PATH))
	var decoded := CampaignCodec.decode_save(encoded["text"], context)
	assert_true(decoded["accepted"], str(decoded.get("error_code", &"")))
	assert_eq(decoded["data"], data)
	assert_eq(decoded["text"], encoded["text"])
	assert_eq(decoded["sha256"], encoded["sha256"])
	assert_null(decoded["migrated_from_version"])


func test_v1_and_v2_migrate_to_the_same_byte_exact_v3_document() -> void:
	var context := ContextScript.build()
	var from_v1 := CampaignCodec.decode_save(_text(V1_PATH), context)
	var from_v2 := CampaignCodec.decode_save(_text(V2_PATH), context)
	for result: Dictionary in [from_v1, from_v2]:
		assert_true(result["accepted"], str(result.get("error_code", &"")))
		assert_eq(result["value"]["version"], 3)
		assert_eq(result["text"], _text(V3_PATH))
	assert_eq(from_v1["migrated_from_version"], 1)
	assert_eq(from_v2["migrated_from_version"], 2)
	assert_eq(from_v1["text"], from_v2["text"])
	for hero: Dictionary in from_v2["data"]["heroes"]:
		var expected_class: Variant = hero["advanced_class_id"] \
			if hero["advanced_class_id"] != null else hero["first_class_id"]
		assert_eq(hero["current_class_id"], expected_class)
		assert_eq(hero["portrait_instance_id"], "portrait:%s" % hero["hero_id"])
		assert_eq(hero["portrait_asset_id"], hero["identity_portrait_id"])
	assert_eq(from_v2["data"]["offers"][0]["operator_def_id"], "recruit")
	assert_true(from_v2["data"]["tickets"].is_empty())
	assert_true(from_v2["data"]["memorial"].is_empty())


func test_valid_progressed_v3_states_round_trip_and_change_strategic_hash() -> void:
	var context := ContextScript.build()
	var baseline: Dictionary = CampaignV3Codec.create_fresh(42, 1, context)["value"]
	var baseline_hash := CampaignV3Hash.of_data(baseline, context)
	assert_true(baseline_hash["accepted"])
	var states: Array[Dictionary] = [
		_promoted_state(baseline),
		_entitled_state(baseline),
		_ticketed_state(baseline),
		_dead_memorial_state(baseline),
		_replacement_state(baseline, "aaaaaaaaaaaaaaaa", "portrait_recruit_05"),
		_replacement_state(baseline, "bbbbbbbbbbbbbbbb", "portrait_recruit_06"),
	]
	var hashes := {}
	for state: Dictionary in states:
		var encoded := CampaignCodec.encode_save_v3(state, context)
		assert_true(encoded["accepted"], str(encoded.get("error_code", &"")))
		var restored := CampaignCodec.decode_save(encoded["text"], context)
		assert_true(restored["accepted"], str(restored.get("error_code", &"")))
		assert_eq(restored["data"], state)
		var strategic := CampaignV3Hash.of_data(state, context)
		assert_true(strategic["accepted"])
		assert_ne(strategic["hex"], baseline_hash["hex"])
		hashes[strategic["hex"]] = true
	assert_eq(hashes.size(), states.size())


func test_resolved_v2_history_migrates_entitlements_and_anchor_cores() -> void:
	var context := ContextScript.build()
	var fixture := _json("res://test/fixtures/p16/transaction_vectors_v2.json")
	var source := _raw_v2_save(fixture["resolved_save"]["value"])
	var migrated := CampaignCodec.decode_save(source, context)
	assert_true(migrated["accepted"], str(migrated.get("error_code", &"")))
	assert_eq(migrated["data"]["class_entitlements"], ["sword_saint"])
	var anchor: Dictionary = migrated["data"]["resolution_anchor"]
	assert_eq(anchor["before_core"]["class_entitlements"], [])
	assert_eq(anchor["after_core"]["class_entitlements"], ["sword_saint"])
	assert_true(anchor["before_core"]["tickets"].is_empty())
	assert_true(anchor["after_core"]["memorial"].is_empty())
	var restored := CampaignCodec.decode_save(migrated["text"], context)
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	assert_eq(restored["text"], migrated["text"])
	assert_eq(restored["data"], migrated["data"])


func test_rules_v2_resolution_history_rejects_forged_closure_without_mutation() -> void:
	var context := ContextScript.build()
	var baseline: Dictionary = CampaignV3Codec.create_fresh(42, 1, context)["value"]
	var valid := _resolved_state(baseline, true)
	assert_true(CampaignV3Codec.normalize_data(valid, context)["accepted"])
	var cases: Array[Dictionary] = []
	var forged_hash: Dictionary = valid.duplicate(true)
	for key: String in ["strategic_body_hash_before", "strategic_body_hash_after"]:
		forged_hash["resolution_anchor"][key] = "0".repeat(16)
		forged_hash["last_resolution"][key] = "0".repeat(16)
	cases.append(forged_hash)
	var identical_cores: Dictionary = valid.duplicate(true)
	identical_cores["resolution_anchor"]["after_core"] = (
		identical_cores["resolution_anchor"]["before_core"].duplicate(true)
	)
	identical_cores["resolution_anchor"]["strategic_body_hash_after"] = (
		identical_cores["resolution_anchor"]["strategic_body_hash_before"]
	)
	identical_cores["last_resolution"]["strategic_body_hash_after"] = (
		identical_cores["resolution_anchor"]["strategic_body_hash_before"]
	)
	cases.append(identical_cores)
	var malformed_rows: Dictionary = valid.duplicate(true)
	malformed_rows["last_resolution"]["xp_awards"] = ["forged"]
	cases.append(malformed_rows)
	var current_mismatch: Dictionary = valid.duplicate(true)
	current_mismatch["marks"] += 1
	cases.append(current_mismatch)
	for candidate: Dictionary in cases:
		var before := CanonicalJson.text(candidate)
		var rejected := CampaignV3Codec.normalize_data(candidate, context)
		assert_false(rejected["accepted"])
		assert_eq(CanonicalJson.text(candidate), before)


func test_resolution_history_rejects_resealed_ticket_snapshot_forgery() -> void:
	var context := ContextScript.build()
	var baseline: Dictionary = CampaignV3Codec.create_fresh(42, 1, context)["value"]
	var valid := _resolved_state(baseline, false)
	assert_true(CampaignV3Codec.normalize_data(valid, context)["accepted"])
	var mutations: Array[Callable] = [
		func(ticket: Dictionary) -> void: ticket["expected_save_revision"] = 999,
		func(ticket: Dictionary) -> void: ticket["strategic_hash"] = "0".repeat(16),
		func(ticket: Dictionary) -> void:
			ticket["squad"][0]["class_id"] = "defender"
			ticket["squad"][0]["operator_def_id"] = "defender_1",
		func(ticket: Dictionary) -> void:
			ticket["squad"][0]["operator_content_sha256"] = "a".repeat(64),
		func(ticket: Dictionary) -> void: ticket["squad"][0]["combat_spec"]["atk"] = 5,
		func(ticket: Dictionary) -> void:
			ticket["squad"][0]["target_policy_spec"]["policy_content_sha256"] = (
				"a".repeat(64)
			),
		func(ticket: Dictionary) -> void:
			ticket["squad"][0]["skill_spec"]["payload"] = {"power": 1},
		func(ticket: Dictionary) -> void:
			ticket["squad"][0]["visual_spec"]["sprite_id"] = "defender_1",
	]
	for index: int in mutations.size():
		var candidate := _resealed_ticket_forgery(valid, mutations[index])
		var before := CanonicalJson.text(candidate)
		var rejected := CampaignV3Codec.normalize_data(candidate, context)
		assert_false(rejected["accepted"], "resealed ticket case %d" % index)
		assert_has(
			[
				&"ticket_snapshot_mismatch", &"resolution_anchor_hash_mismatch",
				&"invalid_resolution_anchor",
			],
			rejected["error_code"],
		)
		assert_eq(CanonicalJson.text(candidate), before)


func test_unresolved_ticket_rejects_null_and_resealed_alternate_policy() -> void:
	var context := ContextScript.build()
	var baseline: Dictionary = CampaignV3Codec.create_fresh(42, 1, context)["value"]
	var ticketed := _ticketed_state(baseline)
	var null_policy: Dictionary = ticketed.duplicate(true)
	null_policy["tickets"][0]["squad"][0]["target_policy_spec"]["policy_id"] = null
	var null_before := CanonicalJson.text(null_policy)
	var null_result := CampaignV3Codec.normalize_data(null_policy, context)
	assert_true(null_result.has("accepted"))
	assert_false(null_result["accepted"])
	assert_eq(null_result["error_code"], &"invalid_ticket_target_policy")
	assert_eq(CanonicalJson.text(null_policy), null_before)

	var forged: Dictionary = ticketed.duplicate(true)
	var ticket: Dictionary = forged["tickets"][0].duplicate(true)
	ticket["squad"][0]["target_policy_spec"] = {
		"policy_id": "operator_ground_only_frontmost",
		"policy_content_sha256": FileAccess.get_sha256(
			"res://data/target_policies/operator_ground_only_frontmost.tres"
		),
		"owner_kind": 0, "candidate_domain": 2, "aerial_rule": 1,
		"primary_rank": 1,
	}
	ticket.erase("ticket_hash")
	var sealed := BattleTicket.seal(ticket)
	assert_true(sealed["accepted"])
	forged["tickets"][0] = sealed["value"]
	var forged_before := CanonicalJson.text(forged)
	var normalized := CampaignV3Codec.normalize_data(forged, context)
	assert_false(normalized["accepted"])
	assert_eq(normalized["error_code"], &"ticket_snapshot_mismatch")
	var encoded := CampaignCodec.encode_save_v3(forged, context)
	assert_false(encoded["accepted"])
	assert_eq(encoded["error_code"], &"ticket_snapshot_mismatch")
	assert_eq(CanonicalJson.text(forged), forged_before)

	var class_forged: Dictionary = ticketed.duplicate(true)
	var class_ticket: Dictionary = class_forged["tickets"][0].duplicate(true)
	var row: Dictionary = class_ticket["squad"][0]
	var caster: Dictionary = context["operator_ticket_by_id"]["caster_1"]
	row["class_id"] = "mage_apprentice"
	row["operator_def_id"] = "caster_1"
	for key: String in [
		"operator_content_sha256", "combat_spec", "target_policy_spec", "skill_spec",
		"visual_spec",
	]:
		row[key] = caster[key].duplicate(true) if caster[key] is Dictionary else caster[key]
	row["skill_spec"]["payload"] = _canonical_payload(row["skill_spec"]["payload"])
	row["visual_spec"]["portrait_asset_id"] = baseline["heroes"][0]["portrait_asset_id"]
	class_ticket.erase("ticket_hash")
	var class_sealed := BattleTicket.seal(class_ticket)
	assert_true(class_sealed["accepted"], str(class_sealed.get("error_code", &"")))
	class_forged["tickets"][0] = class_sealed["value"]
	var class_before := CanonicalJson.text(class_forged)
	var class_normalized := CampaignV3Codec.normalize_data(class_forged, context)
	assert_false(class_normalized["accepted"])
	assert_eq(class_normalized["error_code"], &"ticket_snapshot_mismatch")
	var class_encoded := CampaignCodec.encode_save_v3(class_forged, context)
	assert_false(class_encoded["accepted"])
	assert_eq(class_encoded["error_code"], &"ticket_snapshot_mismatch")
	assert_eq(CanonicalJson.text(class_forged), class_before)

	for metadata: Dictionary in [
		{"field": "expected_save_revision", "value": 2},
		{"field": "strategic_hash", "value": "0".repeat(16)},
		{"field": "stage_id", "value": "not_a_campaign_stage"},
	]:
		var metadata_forged: Dictionary = ticketed.duplicate(true)
		var metadata_ticket: Dictionary = metadata_forged["tickets"][0].duplicate(true)
		metadata_ticket[metadata["field"]] = metadata["value"]
		metadata_ticket.erase("ticket_hash")
		var metadata_sealed := BattleTicket.seal(metadata_ticket)
		assert_true(metadata_sealed["accepted"])
		metadata_forged["tickets"][0] = metadata_sealed["value"]
		var metadata_before := CanonicalJson.text(metadata_forged)
		var metadata_normalized := CampaignV3Codec.normalize_data(
			metadata_forged, context,
		)
		assert_false(metadata_normalized["accepted"])
		assert_eq(metadata_normalized["error_code"], &"ticket_issuance_mismatch")
		var metadata_encoded := CampaignCodec.encode_save_v3(metadata_forged, context)
		assert_false(metadata_encoded["accepted"])
		assert_eq(metadata_encoded["error_code"], &"ticket_issuance_mismatch")
		assert_eq(CanonicalJson.text(metadata_forged), metadata_before)


func test_second_unresolved_attempt_is_representable_and_rejects_dead_hero() -> void:
	var context := ContextScript.build()
	var baseline: Dictionary = CampaignV3Codec.create_fresh(42, 1, context)["value"]
	for anchored: Dictionary in [_resolved_state(baseline, false), _promoted_state(baseline)]:
		var second := _append_unresolved_ticket(anchored, 0, context)
		var normalized := CampaignV3Codec.normalize_data(second, context)
		assert_true(normalized["accepted"], str(normalized.get("error_code", &"")))
		var encoded := CampaignCodec.encode_save_v3(second, context)
		assert_true(encoded["accepted"], str(encoded.get("error_code", &"")))

	var dead := _resolved_state(baseline, true)
	var dead_second := _append_unresolved_ticket(dead, 1, context)
	var dead_core := {}
	for key: String in CampaignV3Codec.CORE_KEYS:
		dead_core[key] = dead_second[key]
	var dead_before := CanonicalJson.text(dead_core)
	var rejected := CampaignV3Codec.normalize_core(dead_core, context)
	assert_false(rejected["accepted"])
	assert_eq(rejected["error_code"], &"ticket_snapshot_mismatch")
	assert_eq(CanonicalJson.text(dead_core), dead_before)


func test_mixed_rules_forged_projection_and_rejected_input_do_not_mutate() -> void:
	var context := ContextScript.build()
	var legacy: Dictionary = CampaignCodec.decode_save(_text(V3_PATH), context)["data"]
	var mixed: Dictionary = legacy.duplicate(true)
	mixed["heroes"][0]["progression_rules_version"] = 2
	var mixed_before := CanonicalJson.text(mixed)
	var mixed_result := CampaignV3Codec.normalize_data(mixed, context)
	assert_false(mixed_result["accepted"])
	assert_eq(mixed_result["error_code"], &"mixed_progression_rules")
	assert_eq(CanonicalJson.text(mixed), mixed_before)

	var fresh: Dictionary = CampaignV3Codec.create_fresh(42, 1, context)["value"]
	var forged: Dictionary = fresh.duplicate(true)
	forged["heroes"][0]["current_class_id"] = "sorcerer"
	var forged_before := CanonicalJson.text(forged)
	var rejected := CampaignV3Codec.normalize_data(forged, context)
	assert_false(rejected["accepted"])
	assert_eq(rejected["error_code"], &"invalid_class_projection")
	assert_eq(CanonicalJson.text(forged), forged_before)


func test_locale_copy_and_keys_are_excluded_from_environment_hash() -> void:
	var context := ContextScript.build()
	var baseline := CampaignV3Codec.derive_environment_sha256(
		_resources("res://data/operators"), _resources("res://data/classes"),
		_ids("res://data/traps"), _ids("res://data/spells"), _stages(),
		CAMPAIGN as CampaignDef, _locale_entries(),
	)
	assert_true(baseline["accepted"])
	assert_eq(baseline["value"], CampaignDef.P16_V3_ENVIRONMENT_SHA256)
	var changed_classes := _resources("res://data/classes")
	var recruit := (changed_classes[5] as ClassDef).duplicate(true) as ClassDef
	var changed_entries := _locale_entries().duplicate(true)
	changed_entries.erase(String(recruit.description_key))
	recruit.description_key = &"data.class.recruit.description.audit"
	recruit.description = "Changed presentation copy"
	changed_entries[String(recruit.description_key)] = recruit.description
	changed_classes[5] = recruit
	var changed := CampaignV3Codec.derive_environment_sha256(
		_resources("res://data/operators"), changed_classes,
		_ids("res://data/traps"), _ids("res://data/spells"), _stages(),
		CAMPAIGN as CampaignDef, changed_entries,
	)
	assert_true(changed["accepted"], str(changed.get("error_code", &"")))
	assert_eq(changed["value"], baseline["value"])


func test_skill_resource_content_is_bound_into_environment_hash() -> void:
	var operators := _resources("res://data/operators")
	var classes := _resources("res://data/classes")
	var stages := _stages()
	var copy_entries := _locale_entries()
	var campaign := CAMPAIGN as CampaignDef
	var baseline := CampaignV3Codec.derive_environment_sha256(
		operators, classes, _ids("res://data/traps"), _ids("res://data/spells"),
		stages, campaign, copy_entries,
	)
	assert_true(baseline["accepted"])
	var with_skill: OperatorDef = null
	for definition: OperatorDef in operators:
		if definition.skill != null:
			with_skill = definition
			break
	assert_not_null(with_skill)
	if with_skill == null:
		return
	var original_skill: SkillDef = with_skill.skill
	with_skill.skill = null
	var changed := CampaignV3Codec.derive_environment_sha256(
		operators, classes, _ids("res://data/traps"), _ids("res://data/spells"),
		stages, campaign, copy_entries,
	)
	with_skill.skill = original_skill
	assert_true(changed["accepted"])
	assert_ne(changed["value"], baseline["value"])


func test_target_policy_resource_is_bound_into_environment_hash() -> void:
	var operators := _resources("res://data/operators")
	var baseline := CampaignV3Codec.derive_environment_sha256(
		operators, _resources("res://data/classes"), _ids("res://data/traps"),
		_ids("res://data/spells"), _stages(), CAMPAIGN as CampaignDef, _locale_entries(),
	)
	assert_true(baseline["accepted"])
	var recruit: OperatorDef = null
	for definition: OperatorDef in operators:
		if definition.id == &"recruit":
			recruit = definition
			break
	assert_not_null(recruit)
	if recruit == null:
		return
	var original: Resource = recruit.target_policy
	recruit.target_policy = load(
		"res://data/target_policies/operator_ground_only_frontmost.tres"
	)
	var changed := CampaignV3Codec.derive_environment_sha256(
		operators, _resources("res://data/classes"), _ids("res://data/traps"),
		_ids("res://data/spells"), _stages(), CAMPAIGN as CampaignDef, _locale_entries(),
	)
	recruit.target_policy = original
	assert_true(changed["accepted"])
	assert_ne(changed["value"], baseline["value"])


func test_mitigation_semantics_are_bound_into_environment_hash() -> void:
	var operators := _resources("res://data/operators")
	var baseline := CampaignV3Codec.derive_environment_sha256(
		operators, _resources("res://data/classes"), _ids("res://data/traps"),
		_ids("res://data/spells"), _stages(), CAMPAIGN as CampaignDef, _locale_entries(),
	)
	assert_true(baseline["accepted"])
	var recruit: OperatorDef = null
	for definition: OperatorDef in operators:
		if definition.id == &"recruit":
			recruit = definition
			break
	assert_not_null(recruit)
	if recruit == null:
		return
	var original := recruit.defense
	recruit.defense = original + 1
	var changed := CampaignV3Codec.derive_environment_sha256(
		operators, _resources("res://data/classes"), _ids("res://data/traps"),
		_ids("res://data/spells"), _stages(), CAMPAIGN as CampaignDef, _locale_entries(),
	)
	recruit.defense = original
	assert_true(changed["accepted"])
	assert_ne(changed["value"], baseline["value"])


func test_pre_mitigation_v2_bytes_upgrade_once_and_repeat_exactly() -> void:
	var context := ContextScript.build()
	var legacy_context: Dictionary = context["legacy_context"]
	var source := _text(V2_PATH)
	var decoded := CampaignCodec.decode_save(source, legacy_context)
	assert_true(decoded["accepted"], str(decoded.get("error_code", &"")))
	assert_eq(decoded["migrated_from_version"], 2)
	assert_ne(decoded["text"], source)
	assert_eq(
		decoded["data"]["combat_rules_sha256"],
		CombatContentBinding.LEGACY_ZERO_SHA256,
	)
	var repeated := CampaignCodec.decode_save(decoded["text"], legacy_context)
	assert_true(repeated["accepted"], str(repeated.get("error_code", &"")))
	assert_null(repeated["migrated_from_version"])
	assert_eq(repeated["bytes"], decoded["bytes"])
	assert_eq(repeated["sha256"], decoded["sha256"])


func _resealed_ticket_forgery(
	valid: Dictionary,
	mutate: Callable,
) -> Dictionary:
	var candidate: Dictionary = valid.duplicate(true)
	var ticket: Dictionary = candidate["resolution_anchor"]["before_core"]["tickets"][0]
	ticket.erase("ticket_hash")
	mutate.call(ticket)
	var sealed := BattleTicket.seal(ticket)
	assert_true(sealed["accepted"], str(sealed.get("error_code", &"")))
	var frozen: Dictionary = sealed["value"]
	candidate["resolution_anchor"]["before_core"]["tickets"][0] = frozen.duplicate(true)
	candidate["resolution_anchor"]["after_core"]["tickets"][0] = frozen.duplicate(true)
	candidate["tickets"][0] = frozen.duplicate(true)
	candidate["last_resolution"]["ticket_hash"] = frozen["ticket_hash"]
	return candidate


func _canonical_payload(value: Variant) -> Variant:
	if value is Array:
		var items: Array = []
		for item: Variant in value:
			items.append(_canonical_payload(item))
		return items
	if value is Dictionary:
		var names: Array[String] = []
		for raw_key: Variant in value:
			names.append(String(raw_key))
		names.sort()
		var object := {}
		for key: String in names:
			object[key] = _canonical_payload(value[key])
		return object
	return value


func _promoted_state(baseline: Dictionary) -> Dictionary:
	var state: Dictionary = _resolved_state(baseline, false)
	var hero: Dictionary = state["heroes"][0]
	hero["operator_def_id"] = "defender_1"
	hero["current_class_id"] = "defender"
	hero["first_class_id"] = "defender"
	state["save_revision"] = 3
	state["promotion_receipts"] = [{
		"command_id": "promote-0001",
		"save_revision": 3,
		"choices": [{
			"hero_id": hero["hero_id"],
			"from_class_id": "recruit",
			"to_class_id": "defender",
		}],
	}]
	return state


func _entitled_state(baseline: Dictionary) -> Dictionary:
	return _resolved_state(baseline, false)


func _ticketed_state(baseline: Dictionary) -> Dictionary:
	var state: Dictionary = baseline.duplicate(true)
	var hero: Dictionary = state["heroes"][0]
	var pre_attempt := {}
	for key: String in CampaignV3Codec.CORE_KEYS:
		pre_attempt[key] = state[key]
	var ticket_without_hash := {
		"schema_version": BattleTicket.SCHEMA_VERSION,
		"campaign_uid": state["campaign_uid"],
		"attempt_id": 1,
		"stage_id": "s1",
		"seed": 42,
		"expected_save_revision": 1,
		"strategic_hash": CampaignV3Hash.of_core(pre_attempt, ContextScript.build())["hex"],
		"squad": [_ticket_row(hero)],
	}
	var sealed := BattleTicket.seal(ticket_without_hash)
	assert_true(sealed["accepted"], str(sealed.get("error_code", &"")))
	state["tickets"] = [sealed["value"]]
	state["next_attempt_id"] = 2
	return state


func _append_unresolved_ticket(
	source: Dictionary,
	hero_index: int,
	context: Dictionary,
) -> Dictionary:
	var state: Dictionary = source.duplicate(true)
	var pre_attempt := {}
	for key: String in CampaignV3Codec.CORE_KEYS:
		pre_attempt[key] = state[key]
	var attempt_id := int(state["next_attempt_id"])
	var sealed := BattleTicket.seal({
		"schema_version": BattleTicket.SCHEMA_VERSION,
		"campaign_uid": state["campaign_uid"],
		"attempt_id": attempt_id,
		"stage_id": "s1",
		"seed": 41 + attempt_id,
		"expected_save_revision": state["save_revision"],
		"strategic_hash": CampaignV3Hash.of_core(pre_attempt, context)["hex"],
		"squad": [_projected_ticket_row(state["heroes"][hero_index], context)],
	})
	assert_true(sealed["accepted"], str(sealed.get("error_code", &"")))
	state["tickets"].append(sealed["value"])
	state["next_attempt_id"] = attempt_id + 1
	return state


func _projected_ticket_row(hero: Dictionary, context: Dictionary) -> Dictionary:
	var projection: Dictionary = context["operator_ticket_by_id"][hero["operator_def_id"]]
	var row := {
		"slot_index": 0,
		"battle_id": "1111111111111111",
		"hero_id": hero["hero_id"],
		"class_id": hero["current_class_id"],
		"operator_def_id": hero["operator_def_id"],
		"operator_content_sha256": projection["operator_content_sha256"],
		"combat_spec": projection["combat_spec"].duplicate(true),
		"target_policy_spec": projection["target_policy_spec"].duplicate(true),
		"skill_spec": projection["skill_spec"].duplicate(true),
		"visual_spec": projection["visual_spec"].duplicate(true),
	}
	row["skill_spec"]["payload"] = _canonical_payload(row["skill_spec"]["payload"])
	row["visual_spec"]["portrait_asset_id"] = hero["portrait_asset_id"]
	return row


func _ticket_row(hero: Dictionary) -> Dictionary:
	return {
		"slot_index": 0,
		"battle_id": "1111111111111111",
		"hero_id": hero["hero_id"],
		"class_id": hero["current_class_id"],
		"operator_def_id": hero["operator_def_id"],
		"operator_content_sha256": FileAccess.get_sha256("res://data/operators/recruit.tres"),
		"combat_spec": {
			"dp_cost": 8, "block": 1, "hp": 110, "atk": 4,
			"defense": 0, "resistance_permille": 0, "attack_damage_kind": 0,
			"atk_interval_ticks": 36, "placement": 0,
			"range_cells": [{"x": 0, "y": 0}],
			"dp_generation_interval_ticks": 0, "splash_dim": 0,
		},
		"target_policy_spec": {
			"policy_id": "operator_blocked_assignment_order",
			"policy_content_sha256": FileAccess.get_sha256(
				"res://data/target_policies/operator_blocked_assignment_order.tres"
			),
			"owner_kind": 0, "candidate_domain": 1, "aerial_rule": 0,
			"primary_rank": 3,
		},
		"skill_spec": {
			"skill_id": "", "skill_content_sha256": CanonicalJson.sha256_hex({}),
			"payload": {},
		},
		"visual_spec": {
			"sprite_id": "recruit", "portrait_asset_id": hero["portrait_asset_id"],
		},
	}


func _dead_memorial_state(baseline: Dictionary) -> Dictionary:
	return _resolved_state(baseline, true)


func _resolved_state(baseline: Dictionary, with_death: bool) -> Dictionary:
	var context := ContextScript.build()
	var ticketed: Dictionary = _ticketed_state(baseline)
	var before := {}
	for key: String in CampaignV3Codec.CORE_KEYS:
		before[key] = ticketed[key]
	var after: Dictionary = before.duplicate(true)
	after["save_revision"] = 2
	after["next_resolution_index"] = 2
	after["stage_stars"] = [{
		"stage_id": "s1", "stars": 3, "first_clear_resolution_index": 1,
		"first_clear_attempt_id": 1, "first_clear_terminal_tick": 900,
	}]
	after["class_entitlements"] = ["sword_saint"]
	var promoted_hero: Dictionary = after["heroes"][0]
	promoted_hero["xp"] = 400
	var dead_ids: Array[String] = []
	var memorial_ids: Array[String] = []
	if with_death:
		var hero: Dictionary = after["heroes"][1]
		var death := {
			"resolution_index": 1, "attempt_id": 1, "stage_id": "s1",
			"terminal_reason": "clear", "terminal_tick": 900,
		}
		hero["life_status"] = "dead"
		hero["death"] = death
		var memorial_id := "memorial:%s" % hero["hero_id"]
		after["memorial"] = [{
			"memorial_id": memorial_id,
			"hero_id": hero["hero_id"],
			"portrait_instance_id": hero["portrait_instance_id"],
			"portrait_asset_id": hero["portrait_asset_id"],
			"class_id": hero["current_class_id"],
			"death": death,
		}]
		dead_ids = [String(hero["hero_id"])]
		memorial_ids = [memorial_id]
	var before_hash: String = CampaignV3Hash.of_core(before, context)["hex"]
	var after_hash: String = CampaignV3Hash.of_core(after, context)["hex"]
	var receipt := {
		"schema_version": 1,
		"resolution_index": 1,
		"campaign_uid": after["campaign_uid"],
		"attempt_id": 1,
		"stage_id": "s1",
		"ticket_hash": before["tickets"][0]["ticket_hash"],
		"outcome_hash": "a".repeat(64),
		"result": "clear",
		"terminal_reason": "clear",
		"terminal_tick": 900,
		"stars_before": 0,
		"stars_after": 3,
		"rewards_granted": [],
		"class_entitlements_granted": ["sword_saint"],
		"created_hero_ids": [],
		"dead_hero_ids": dead_ids,
		"xp_awards": [{"hero_id": promoted_hero["hero_id"], "delta": 400}],
		"memorial_ids": memorial_ids,
		"marks_before": 120,
		"marks_after": 120,
		"strategic_body_hash_before": before_hash,
		"strategic_body_hash_after": after_hash,
	}
	var state: Dictionary = baseline.duplicate(true)
	for key: String in CampaignV3Codec.CORE_KEYS:
		state[key] = after[key].duplicate(true) \
			if after[key] is Array or after[key] is Dictionary else after[key]
	state["resolution_anchor"] = {
		"resolution_index": 1,
		"save_revision_after": 2,
		"before_core": before.duplicate(true),
		"after_core": after.duplicate(true),
		"strategic_body_hash_before": before_hash,
		"strategic_body_hash_after": after_hash,
	}
	state["last_resolution"] = receipt
	return state


func _replacement_state(
	baseline: Dictionary,
	hero_id: String,
	portrait_asset_id: String,
) -> Dictionary:
	var state: Dictionary = baseline.duplicate(true)
	state["heroes"].append({
		"hero_id": hero_id,
		"acquisition_operator_def_id": "recruit",
		"operator_def_id": "recruit",
		"current_class_id": "recruit",
		"first_class_id": "recruit",
		"advanced_class_id": null,
		"progression_rules_version": 2,
		"xp": 0,
		"identity_portrait_id": portrait_asset_id,
		"portrait_instance_id": "portrait:%s" % hero_id,
		"portrait_asset_id": portrait_asset_id,
		"recruitment_index": 5,
		"recruited_after_resolution_index": 0,
		"recruit_source": "replacement",
		"source_id": "replacement-0001",
		"name_version": HeroNames.VERSION,
		"custom_callsign": null,
		"life_status": "ready",
		"death": null,
	})
	state["next_recruitment_index"] = 6
	return state


func _stages() -> Array:
	var result: Array = []
	for index: int in range(1, 9):
		result.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	return result


func _resources(path: String) -> Array:
	var result: Array = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			result.append(load("%s/%s" % [path, source]))
	return result


func _ids(path: String) -> Array:
	var result: Array = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			result.append(StringName(source.trim_suffix(".tres")))
	return result


func _locale_entries() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://localization/en-US.json")
	)
	return parsed["entries"]


func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _json(path: String) -> Dictionary:
	var source := _text(path)
	var parser := JSON.new()
	assert_eq(parser.parse(source), OK)
	var restored := CanonicalJson.restore_exact_integers(source, parser.data)
	assert_true(restored["accepted"])
	return restored["value"]


func _raw_v2_save(data: Dictionary) -> String:
	return CanonicalJson.text({
		"schema": "prototype_td_campaign",
		"version": 2,
		"checksum": CanonicalJson.sha256_hex(data),
		"data": data,
	})
