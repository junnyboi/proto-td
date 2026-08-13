extends GutTest

const SAVE_PATH := "res://test/fixtures/p16/campaign_v2_seed42.json"
const TRANSACTION_PATH := "res://test/fixtures/p16/transaction_vectors_v2.json"


func test_fresh_factory_matches_frozen_fixture_checksum_and_hash() -> void:
	var state := _fresh()
	var fixture := CampaignCodec.decode_save(_text(SAVE_PATH), _context())
	assert_true(fixture["accepted"])
	assert_eq(state.data_copy(), fixture["data"])
	assert_eq(state.encode_data()["sha256"],
		"69270968b2fedd82f98de96cf6ad530ad8e694d241aabdba5ab97a396e1b664b")
	assert_eq(state.strategic_hash()["hex"], "baa4d62d418258a5")
	assert_eq(state.campaign_uid(), "ce46150984346591")
	assert_eq(state.next_recruitment_index(), 5)
	assert_eq(state.next_attempt_id(), 1)
	assert_eq(state.next_resolution_index(), 1)
	assert_eq(state.marks(), 120)
	assert_false(bool(state.offer("p16_caster_contract")["consumed"]))


func test_factory_is_catalog_and_stage_order_independent() -> void:
	var catalogs := _catalogs()
	for key: String in catalogs:
		(catalogs[key] as Array).reverse()
	var stages := _stages()
	stages.reverse()
	var shuffled := CampaignState.create(42, 1, _definition(), catalogs, stages)
	assert_true(shuffled["accepted"], str(shuffled.get("error_code", &"")))
	var state := shuffled["value"] as CampaignState
	assert_eq(state.encode_data()["text"], _fresh().encode_data()["text"])
	assert_eq(state.strategic_hash()["hex"], "baa4d62d418258a5")


func test_compatibility_projection_is_exact_and_defensive() -> void:
	var state := _resolved()
	var projection := state.compatibility_projection()
	assert_eq(projection["unlocked_operators"], [
		&"caster_1", &"defender_1", &"defender_2", &"guard_1",
		&"vanguard_1", &"guard_2",
	])
	assert_eq(projection["unlocked_traps"], [])
	assert_eq(projection["unlocked_spells"], [])
	assert_eq(projection["stage_stars"], {&"s1": 3})
	(projection["unlocked_operators"] as Array).clear()
	(projection["stage_stars"] as Dictionary)[&"s1"] = 1
	assert_eq(state.compatibility_projection()["unlocked_operators"].size(), 6)
	assert_eq(state.compatibility_projection()["stage_stars"][&"s1"], 3)


func test_reward_preview_is_pure_and_uses_next_free_index() -> void:
	var fresh := _fresh()
	var before: String = fresh.encode_data()["text"]
	var before_hash: String = fresh.strategic_hash()["hex"]
	var first := fresh.preview_first_clear_rewards(&"s1")
	var repeated := fresh.preview_first_clear_rewards(&"s1")
	assert_true(first["accepted"])
	assert_true(first["first_clear"])
	assert_eq(first, repeated)
	assert_eq(first["next_recruitment_index"], 6)
	assert_eq(first["rewards_granted"], [{
		"kind": "operator",
		"id": "guard_2",
		"hero_instance_id": "e54c103e46898f5d",
	}])
	assert_eq(first["created_hero_rows"][0]["recruitment_index"], 5)
	assert_eq(first["created_hero_rows"][0]["recruit_source"], "reward")
	assert_eq(first["created_hero_rows"][0]["source_id"], "s1")
	assert_eq(fresh.encode_data()["text"], before)
	assert_eq(fresh.strategic_hash()["hex"], before_hash)

	var paid := _restore(_paid_data())
	var paid_preview := paid.preview_first_clear_rewards(&"s1")
	assert_true(paid_preview["accepted"])
	assert_eq(paid_preview["next_recruitment_index"], 7)
	assert_eq(paid_preview["created_hero_rows"][0]["hero_id"], "fe0ff2c1e3ecc49d")
	assert_eq(paid_preview["created_hero_rows"][0]["recruitment_index"], 6)

	var resolved := _resolved()
	var complete := resolved.preview_first_clear_rewards(&"s1")
	assert_true(complete["accepted"])
	assert_false(complete["first_clear"])
	assert_true((complete["rewards_granted"] as Array).is_empty())
	assert_true((complete["created_hero_rows"] as Array).is_empty())
	assert_eq(complete["next_recruitment_index"], 7)


func test_locked_unknown_and_impossible_states_reject_without_shadow_hashes() -> void:
	var state := _fresh()
	assert_eq(state.preview_first_clear_rewards(&"s2")["error_code"], &"stage_locked")
	assert_eq(state.preview_first_clear_rewards(&"test_lane")["error_code"],
		&"unknown_campaign_stage")
	var impossible := state.data_copy()
	impossible["next_recruitment_index"] = 6
	var rejected := CampaignState.restore(impossible, _definition(), _catalogs(), _stages())
	assert_false(rejected["accepted"])
	assert_eq(rejected["error_code"], &"recruitment_counter_mismatch")
	assert_eq(state.strategic_hash()["hex"], "baa4d62d418258a5")


func test_malformed_catalog_stage_and_reward_environments_reject() -> void:
	var missing_reward_def := _catalogs()
	missing_reward_def["operators"].erase(&"guard_2")
	assert_false(_create(_definition(), missing_reward_def, _stages())["accepted"])
	var duplicate_catalog := _catalogs()
	duplicate_catalog["operators"].append(&"caster_1")
	assert_false(_create(_definition(), duplicate_catalog, _stages())["accepted"])
	var cross_kind_duplicate := _catalogs()
	cross_kind_duplicate["traps"].append(&"caster_1")
	assert_false(_create(_definition(), cross_kind_duplicate, _stages())["accepted"])

	var duplicate_stage := _stages()
	var replacement := (duplicate_stage[0] as StageDef).duplicate(true) as StageDef
	replacement.campaign_index = 2
	duplicate_stage[1] = replacement
	assert_false(_create(_definition(), _catalogs(), duplicate_stage)["accepted"])
	var empty_stage := _stages()
	var empty := (empty_stage[0] as StageDef).duplicate(true) as StageDef
	empty.id = &""
	empty_stage[0] = empty
	assert_false(_create(_definition(), _catalogs(), empty_stage)["accepted"])
	var wrong_reward := _stages()
	var wrong := (wrong_reward[0] as StageDef).duplicate(true) as StageDef
	wrong.rewards = [{"kind": &"trap", "id": &"guard_2"}]
	wrong_reward[0] = wrong
	assert_false(_create(_definition(), _catalogs(), wrong_reward)["accepted"])
	var extra_reward_key := _stages()
	var extra := (extra_reward_key[0] as StageDef).duplicate(true) as StageDef
	extra.rewards = [{"kind": &"operator", "id": &"guard_2", "extra": true}]
	extra_reward_key[0] = extra
	assert_false(_create(_definition(), _catalogs(), extra_reward_key)["accepted"])


func test_malformed_campaign_definition_values_reject_without_coercion() -> void:
	var fractional := _definition().duplicate(true) as CampaignDef
	fractional.paid_offers = [{
		"offer_id": "p16_caster_contract",
		"operator_def_id": "caster_1",
		"cost": 80.5,
	}]
	assert_false(_create(fractional, _catalogs(), _stages())["accepted"])
	var boolean_cost := _definition().duplicate(true) as CampaignDef
	boolean_cost.paid_offers = [{
		"offer_id": "p16_caster_contract",
		"operator_def_id": "caster_1",
		"cost": true,
	}]
	assert_false(_create(boolean_cost, _catalogs(), _stages())["accepted"])
	var unknown_operator := _definition().duplicate(true) as CampaignDef
	unknown_operator.paid_offers = [{
		"offer_id": "p16_caster_contract",
		"operator_def_id": "unknown_operator",
		"cost": 80,
	}]
	assert_false(_create(unknown_operator, _catalogs(), _stages())["accepted"])
	var wrong_starters := _definition().duplicate(true) as CampaignDef
	var reversed_starters: Array[StringName] = wrong_starters.starter_operator_ids.duplicate()
	reversed_starters.reverse()
	wrong_starters.starter_operator_ids = reversed_starters
	assert_false(_create(wrong_starters, _catalogs(), _stages())["accepted"])
	var wrong_environment := _definition().duplicate(true) as CampaignDef
	wrong_environment.environment_sha256 = "0".repeat(64)
	assert_false(_create(wrong_environment, _catalogs(), _stages())["accepted"])


func test_recovery_rosters_enforce_nonempty_capacity_and_availability() -> void:
	var empty_recovery := _stages()
	var empty := (empty_recovery[0] as StageDef).duplicate(true) as StageDef
	var empty_values: Array[StringName] = []
	empty.recovery_roster = empty_values
	empty_recovery[0] = empty
	assert_false(_create(_definition(), _catalogs(), empty_recovery)["accepted"])
	var oversized_recovery := _stages()
	var oversized := (oversized_recovery[0] as StageDef).duplicate(true) as StageDef
	var oversized_values: Array[StringName] = [
		&"vanguard_1", &"guard_1", &"defender_1", &"caster_1",
	]
	oversized.recovery_roster = oversized_values
	oversized_recovery[0] = oversized
	assert_false(_create(_definition(), _catalogs(), oversized_recovery)["accepted"])
	var unavailable_recovery := _stages()
	var unavailable := (unavailable_recovery[0] as StageDef).duplicate(true) as StageDef
	var unavailable_values: Array[StringName] = [
		&"vanguard_1", &"guard_1", &"guard_2",
	]
	unavailable.recovery_roster = unavailable_values
	unavailable_recovery[0] = unavailable
	assert_false(_create(_definition(), _catalogs(), unavailable_recovery)["accepted"])


func test_exact_environment_fingerprint_rejects_consistent_contract_drift() -> void:
	var renamed_stages := _stages()
	var renamed := (renamed_stages[7] as StageDef).duplicate(true) as StageDef
	renamed.id = &"x8"
	renamed_stages[7] = renamed
	var renamed_result := _create(_definition(), _catalogs(), renamed_stages)
	assert_false(renamed_result["accepted"])
	assert_eq(renamed_result["error_code"], &"campaign_environment_mismatch")

	var expanded_catalog := _catalogs()
	expanded_catalog["operators"].append(&"bonus_operator")
	var expanded_stages := _stages()
	var expanded := (expanded_stages[7] as StageDef).duplicate(true) as StageDef
	expanded.rewards = [{"kind": &"operator", "id": &"bonus_operator"}]
	expanded_stages[7] = expanded
	var expanded_result := _create(_definition(), expanded_catalog, expanded_stages)
	assert_false(expanded_result["accepted"])
	assert_eq(expanded_result["error_code"], &"campaign_environment_mismatch")

	var moved_reward_stages := _stages()
	var source := (moved_reward_stages[3] as StageDef).duplicate(true) as StageDef
	source.rewards = [{"kind": &"spell", "id": &"bolt"}]
	moved_reward_stages[3] = source
	var destination := (moved_reward_stages[5] as StageDef).duplicate(true) as StageDef
	destination.rewards = [
		{"kind": &"operator", "id": &"vanguard_2"},
		{"kind": &"operator", "id": &"sniper_2"},
	]
	moved_reward_stages[5] = destination
	var moved_result := _create(_definition(), _catalogs(), moved_reward_stages)
	assert_false(moved_result["accepted"])
	assert_eq(moved_result["error_code"], &"campaign_environment_mismatch")


func test_valid_field_families_change_the_single_frozen_full_hash() -> void:
	var fresh := _fresh()
	var hashes := {fresh.strategic_hash()["hex"]: true}
	var seed_changed := CampaignState.create(43, 1, _definition(), _catalogs(), _stages())
	var generation_changed := CampaignState.create(42, 2, _definition(), _catalogs(), _stages())
	var paid := _restore(_paid_data())
	var renamed_data := _paid_data()
	renamed_data["save_revision"] = 3
	renamed_data["heroes"][0]["custom_callsign"] = "Atlas"
	var renamed := _restore(renamed_data)
	var resolved := _resolved()
	for candidate: CampaignState in [
		seed_changed["value"], generation_changed["value"], paid, renamed, resolved,
	]:
		var value: String = candidate.strategic_hash()["hex"]
		assert_false(hashes.has(value), "field-family hashes must be distinct: %s" % value)
		hashes[value] = true
	assert_eq(resolved.strategic_hash()["hex"], "6c13f78c886d80cc")


func test_restore_encode_restore_is_byte_and_hash_exact() -> void:
	var original := _resolved()
	var encoded := original.encode_data()
	var restored := _restore(encoded["value"])
	assert_eq(restored.encode_data()["text"], encoded["text"])
	assert_eq(restored.strategic_hash()["hex"], original.strategic_hash()["hex"])


func _paid_data() -> Dictionary:
	var data := _fresh().data_copy()
	var allocation := _fresh().roster().plan_allocation(
		42, 1, 5, &"caster_1", &"contract", "p16_caster_contract", 0,
	)
	data["save_revision"] = 2
	data["next_recruitment_index"] = 6
	data["marks"] = 40
	data["offers"][0]["consumed"] = true
	data["heroes"].append((allocation["row"] as Dictionary).duplicate(true))
	return data


func _fresh() -> CampaignState:
	var created := _create(_definition(), _catalogs(), _stages())
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	return created["value"] as CampaignState


func _create(definition: CampaignDef, catalogs: Dictionary, stages: Array) -> Dictionary:
	return CampaignState.create(42, 1, definition, catalogs, stages)


func _resolved() -> CampaignState:
	var fixture := _transaction_fixture()
	return _restore(fixture["resolved_save"]["value"])


func _transaction_fixture() -> Dictionary:
	var source := _text(TRANSACTION_PATH)
	var parser := JSON.new()
	assert_eq(parser.parse(source), OK)
	var restored := CanonicalJson.restore_exact_integers(source, parser.data)
	assert_true(restored["accepted"])
	return restored["value"] as Dictionary


func _restore(data: Dictionary) -> CampaignState:
	var restored := CampaignState.restore(data, _definition(), _catalogs(), _stages())
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	return restored["value"] as CampaignState


func _definition() -> CampaignDef:
	return load("res://data/campaigns/p16_v2.tres") as CampaignDef


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


func _context() -> Dictionary:
	return CampaignCodec.build_context(
		_catalogs()["operators"], _catalogs()["traps"], _catalogs()["spells"],
		_stages(), _definition().paid_offers,
	)


func _catalog_ids(path: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			ids.append(StringName(source.trim_suffix(".tres")))
	return ids


func _text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file)
	var source := file.get_as_text()
	file.close()
	return source
