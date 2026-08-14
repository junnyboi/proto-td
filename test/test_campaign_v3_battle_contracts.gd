extends GutTest

const ContextScript := preload("res://test/fixtures/p16/campaign_v3_context.gd")


func test_ticket_canonical_bytes_and_hash_bind_every_persisted_field() -> void:
	var data: Dictionary = CampaignV3Codec.create_fresh(42, 1, ContextScript.build())["value"]
	var ticket := _ticket(data)
	assert_true(ticket["accepted"], str(ticket.get("error_code", &"")))
	var normalized: Dictionary = ticket["value"]
	var restored := BattleTicket.normalize(normalized)
	assert_true(restored["accepted"])
	assert_eq(restored["value"], normalized)
	var hashes := {}
	for field: String in ["seed", "expected_save_revision", "stage_id", "strategic_hash"]:
		var changed: Dictionary = normalized.duplicate(true)
		match field:
			"seed": changed[field] = 43
			"expected_save_revision": changed[field] = 2
			"stage_id": changed[field] = "s2"
			"strategic_hash": changed[field] = "0123456789abcdef"
		changed.erase("ticket_hash")
		var sealed := BattleTicket.seal(changed)
		assert_true(sealed["accepted"], field)
		assert_ne(sealed["value"]["ticket_hash"], normalized["ticket_hash"], field)
		hashes[sealed["value"]["ticket_hash"]] = true
	assert_eq(hashes.size(), 4)

	for row_field: String in [
		"battle_id", "hero_id", "class_id", "operator_def_id", "operator_content_sha256",
		"combat_spec", "target_policy_spec", "skill_spec", "visual_spec",
	]:
		var changed: Dictionary = normalized.duplicate(true)
		match row_field:
			"battle_id": changed["squad"][0][row_field] = "3333333333333333"
			"hero_id": changed["squad"][0][row_field] = "aaaaaaaaaaaaaaaa"
			"class_id": changed["squad"][0][row_field] = "defender"
			"operator_def_id": changed["squad"][0][row_field] = "defender_1"
			"operator_content_sha256": changed["squad"][0][row_field] = "a".repeat(64)
			"combat_spec": changed["squad"][0][row_field]["atk"] = 5
			"target_policy_spec": changed["squad"][0][row_field]["policy_id"] = (
				"operator_ground_only_frontmost"
			)
			"skill_spec": changed["squad"][0][row_field]["payload"] = {"power": 1}
			"visual_spec": changed["squad"][0][row_field]["sprite_id"] = "defender_1"
		changed.erase("ticket_hash")
		var sealed := BattleTicket.seal(changed)
		assert_true(sealed["accepted"], row_field)
		assert_ne(sealed["value"]["ticket_hash"], normalized["ticket_hash"], row_field)
	for field: String in ["defense", "resistance_permille", "attack_damage_kind"]:
		var changed: Dictionary = normalized.duplicate(true)
		changed["squad"][0]["combat_spec"][field] = 1
		changed.erase("ticket_hash")
		var sealed := BattleTicket.seal(changed)
		assert_true(sealed["accepted"], field)
		assert_ne(sealed["value"]["ticket_hash"], normalized["ticket_hash"], field)


func test_ticket_rejects_omitted_duplicate_and_noncanonical_rows_without_mutation() -> void:
	var data: Dictionary = CampaignV3Codec.create_fresh(42, 1, ContextScript.build())["value"]
	var valid: Dictionary = _ticket(data)["value"]
	var cases: Array[Dictionary] = []
	var omitted: Dictionary = valid.duplicate(true)
	omitted["squad"][0].erase("hero_id")
	cases.append(omitted)
	var duplicate_battle: Dictionary = valid.duplicate(true)
	duplicate_battle["squad"][1]["battle_id"] = duplicate_battle["squad"][0]["battle_id"]
	cases.append(duplicate_battle)
	var duplicate_hero: Dictionary = valid.duplicate(true)
	duplicate_hero["squad"][1]["hero_id"] = duplicate_hero["squad"][0]["hero_id"]
	cases.append(duplicate_hero)
	var swapped: Dictionary = valid.duplicate(true)
	var row: Dictionary = swapped["squad"][0]
	swapped["squad"][0] = swapped["squad"][1]
	swapped["squad"][1] = row
	cases.append(swapped)
	for candidate: Dictionary in cases:
		var before := CanonicalJson.text(candidate)
		var rejected := BattleTicket.normalize(candidate)
		assert_false(rejected["accepted"])
		assert_eq(CanonicalJson.text(candidate), before)


func test_ticket_target_policy_nulls_reject_structurally_without_mutation() -> void:
	var data: Dictionary = CampaignV3Codec.create_fresh(42, 1, ContextScript.build())["value"]
	var valid: Dictionary = _ticket(data)["value"]
	for field: String in ["policy_id", "policy_content_sha256"]:
		var candidate: Dictionary = valid.duplicate(true)
		candidate["squad"][0]["target_policy_spec"][field] = null
		var before := CanonicalJson.text(candidate)
		var rejected := BattleTicket.normalize(candidate)
		assert_true(rejected.has("accepted"), field)
		assert_false(rejected["accepted"], field)
		assert_eq(rejected["error_code"], &"invalid_ticket_target_policy", field)
		assert_eq(CanonicalJson.text(candidate), before, field)


func test_ticket_rejects_invalid_mitigation_without_mutation() -> void:
	var data: Dictionary = CampaignV3Codec.create_fresh(42, 1, ContextScript.build())["value"]
	var valid: Dictionary = _ticket(data)["value"]
	for field: String in ["defense", "resistance_permille", "attack_damage_kind"]:
		var candidate: Dictionary = valid.duplicate(true)
		candidate["squad"][0]["combat_spec"][field] = (
			-1 if field == "defense" else 1001 if field == "resistance_permille" else 2
		)
		var before := CanonicalJson.text(candidate)
		var rejected := BattleTicket.normalize(candidate)
		assert_false(rejected["accepted"], field)
		assert_eq(rejected["error_code"], &"invalid_ticket_combat", field)
		assert_eq(CanonicalJson.text(candidate), before, field)


func test_outcome_binds_ticket_rows_and_hashes_every_terminal_field() -> void:
	var data: Dictionary = CampaignV3Codec.create_fresh(42, 1, ContextScript.build())["value"]
	var ticket: Dictionary = _ticket(data)["value"]
	var outcome := _outcome(ticket)
	assert_true(outcome["accepted"], str(outcome.get("error_code", &"")))
	var normalized: Dictionary = outcome["value"]
	assert_eq(BattleOutcomeV3.normalize(normalized, ticket)["value"], normalized)
	for field: String in ["terminal_tick", "stars", "leaks", "kills"]:
		var changed: Dictionary = normalized.duplicate(true)
		match field:
			"terminal_tick": changed[field] = 901
			"stars": changed[field] = 2
			"leaks": changed[field] = 1
			"kills": changed[field] = 6
		changed.erase("outcome_hash")
		var sealed := BattleOutcomeV3.seal(changed, ticket)
		assert_true(sealed["accepted"], field)
		assert_ne(sealed["value"]["outcome_hash"], normalized["outcome_hash"], field)
	var defeated: Dictionary = normalized.duplicate(true)
	defeated["result"] = "defeat"
	defeated["terminal_reason"] = "leak_defeat"
	defeated["stars"] = 0
	defeated.erase("outcome_hash")
	var defeated_sealed := BattleOutcomeV3.seal(defeated, ticket)
	assert_true(defeated_sealed["accepted"])
	assert_ne(defeated_sealed["value"]["outcome_hash"], normalized["outcome_hash"])
	var changed_row: Dictionary = normalized.duplicate(true)
	changed_row["rows"][0]["deployments"] = 2
	changed_row.erase("outcome_hash")
	var row_sealed := BattleOutcomeV3.seal(changed_row, ticket)
	assert_true(row_sealed["accepted"])
	assert_ne(row_sealed["value"]["outcome_hash"], normalized["outcome_hash"])


func test_outcome_rejects_omitted_duplicate_mismatched_and_forged_rows_without_mutation() -> void:
	var data: Dictionary = CampaignV3Codec.create_fresh(42, 1, ContextScript.build())["value"]
	var ticket: Dictionary = _ticket(data)["value"]
	var valid: Dictionary = _outcome(ticket)["value"]
	var cases: Array[Dictionary] = []
	var omitted: Dictionary = valid.duplicate(true)
	omitted["rows"].remove_at(1)
	cases.append(omitted)
	var duplicate: Dictionary = valid.duplicate(true)
	duplicate["rows"][1]["battle_id"] = duplicate["rows"][0]["battle_id"]
	cases.append(duplicate)
	var mismatched: Dictionary = valid.duplicate(true)
	mismatched["rows"][0]["class_id"] = "defender"
	cases.append(mismatched)
	var forged: Dictionary = valid.duplicate(true)
	forged["kills"] = 99
	cases.append(forged)
	var clear_without_stars: Dictionary = valid.duplicate(true)
	clear_without_stars["stars"] = 0
	clear_without_stars.erase("outcome_hash")
	clear_without_stars["outcome_hash"] = CanonicalJson.sha256_hex(clear_without_stars)
	cases.append(clear_without_stars)
	var defeat_with_stars: Dictionary = valid.duplicate(true)
	defeat_with_stars["result"] = "defeat"
	defeat_with_stars["terminal_reason"] = "base_defeat"
	defeat_with_stars.erase("outcome_hash")
	defeat_with_stars["outcome_hash"] = CanonicalJson.sha256_hex(defeat_with_stars)
	cases.append(defeat_with_stars)
	var fall_after_terminal: Dictionary = valid.duplicate(true)
	fall_after_terminal["rows"][0]["fell"] = true
	fall_after_terminal["rows"][0]["first_fall_tick"] = 901
	fall_after_terminal.erase("outcome_hash")
	fall_after_terminal["outcome_hash"] = CanonicalJson.sha256_hex(fall_after_terminal)
	cases.append(fall_after_terminal)
	for index: int in cases.size():
		var candidate: Dictionary = cases[index]
		var before := CanonicalJson.text(candidate)
		var rejected := BattleOutcomeV3.normalize(candidate, ticket)
		assert_false(rejected["accepted"], "rejection case %d" % index)
		assert_eq(CanonicalJson.text(candidate), before)


func _ticket(data: Dictionary) -> Dictionary:
	var pre_attempt := {}
	for key: String in CampaignV3Codec.CORE_KEYS:
		pre_attempt[key] = data[key]
	var strategic: String = CampaignV3Hash.of_core(pre_attempt, ContextScript.build())["hex"]
	return BattleTicket.seal({
		"schema_version": BattleTicket.SCHEMA_VERSION,
		"campaign_uid": data["campaign_uid"],
		"attempt_id": 1,
		"stage_id": "s1",
		"seed": 42,
		"expected_save_revision": 1,
		"strategic_hash": strategic,
		"squad": [
			_ticket_row(data["heroes"][0], 0, "1111111111111111"),
			_ticket_row(data["heroes"][1], 1, "2222222222222222"),
		],
	})


func _ticket_row(hero: Dictionary, slot_index: int, battle_id: String) -> Dictionary:
	return {
		"slot_index": slot_index,
		"battle_id": battle_id,
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


func _outcome(ticket: Dictionary) -> Dictionary:
	var rows: Array[Dictionary] = []
	for frozen: Dictionary in ticket["squad"]:
		rows.append({
			"slot_index": frozen["slot_index"],
			"battle_id": frozen["battle_id"],
			"hero_id": frozen["hero_id"],
			"class_id": frozen["class_id"],
			"operator_def_id": frozen["operator_def_id"],
			"deployments": 1,
			"retreats": 0,
			"fell": false,
			"first_fall_tick": null,
		})
	return BattleOutcomeV3.seal({
		"schema_version": BattleOutcomeV3.SCHEMA_VERSION,
		"attempt_id": ticket["attempt_id"],
		"ticket_hash": ticket["ticket_hash"],
		"result": "clear",
		"terminal_reason": "clear",
		"terminal_tick": 900,
		"stars": 3,
		"leaks": 0,
		"kills": 5,
		"rows": rows,
	}, ticket)
