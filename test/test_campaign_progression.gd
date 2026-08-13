extends GutTest

const CONTRACT_PATH := "res://test/fixtures/p16/promotion_contract_v1.json"
const SAVE_PATH := "res://test/fixtures/p16/campaign_v2_seed42.json"


func test_all_eleven_template_rows_match_the_pinned_total_migration() -> void:
	var contract := _contract()
	var rows: Array = contract["migration"]
	assert_eq(rows.size(), 11)
	for row: Dictionary in rows:
		var actual := CampaignProgression.initial_fields(row["v1_template"])
		assert_eq(actual, {
			"acquisition_operator_def_id": row["acquisition_operator_def_id"],
			"first_class_id": row["first_class_id"],
			"advanced_class_id": row["advanced_class_id"],
			"progression_rules_version": row["progression_rules_version"],
			"xp": row["xp"],
			"identity_portrait_id": row["identity_portrait_id"],
		})
		assert_true(CampaignProgression.projection_is_valid(row))


func test_xp_awards_are_sorted_unique_and_limited_to_deployed_survivors() -> void:
	var ready := _hero("0000000000000001", "caster_1")
	var undeployed := _hero("0000000000000002", "defender_1")
	var dead := _hero("0000000000000003", "guard_1")
	dead["life_status"] = "dead"
	dead["death"] = {
		"resolution_index": 1, "attempt_id": 1, "stage_id": "s1",
		"terminal_reason": "clear", "terminal_tick": 100,
	}
	var heroes: Array = [ready, undeployed, dead]
	var outcome_rows: Array = [
		_outcome_hero(ready, true, "ready"),
		_outcome_hero(ready, true, "ready"),
		_outcome_hero(undeployed, false, "ready"),
		_outcome_hero(dead, true, "dead"),
		{
			"hero_id": "ffffffffffffffff", "operator_def_id": "caster_1",
			"deployments": 1, "fell": false,
		},
	]
	var expected := [{"hero_id": "0000000000000001", "delta": 100}]
	assert_eq(CampaignProgression.derive_xp_awards(outcome_rows, heroes), expected)
	outcome_rows.reverse()
	assert_eq(CampaignProgression.derive_xp_awards(outcome_rows, heroes), expected)


func test_xp_apply_is_exact_and_overflow_rejects_without_mutation() -> void:
	var heroes: Array = [
		_hero("0000000000000001", "caster_1"),
		_hero("0000000000000002", "defender_1"),
	]
	assert_true(CampaignProgression.apply_xp(heroes, [
		{"hero_id": "0000000000000001", "delta": 100},
	]))
	assert_eq(heroes[0]["xp"], 100)
	assert_eq(heroes[1]["xp"], 0)

	heroes[0]["xp"] = CampaignProgression.XP_MAX
	var before: Array = heroes.duplicate(true)
	assert_false(CampaignProgression.apply_xp(heroes, [
		{"hero_id": "0000000000000001", "delta": 1},
	]))
	assert_eq(heroes, before)
	assert_false(CampaignProgression.apply_xp(heroes, [
		{"hero_id": "ffffffffffffffff", "delta": 100},
	]))
	assert_eq(heroes, before)


func test_progression_fields_change_hash_and_round_trip_through_v2_save() -> void:
	var decoded := CampaignCodec.decode_save(_text(SAVE_PATH), _context())
	assert_true(decoded["accepted"], str(decoded.get("error_code", &"")))
	var baseline: Dictionary = decoded["data"]
	var changed: Dictionary = baseline.duplicate(true)
	changed["heroes"][0]["xp"] = 100
	var baseline_hash := CampaignHash.of_data(baseline, _context())
	var changed_hash := CampaignHash.of_data(changed, _context())
	assert_true(baseline_hash["accepted"])
	assert_true(changed_hash["accepted"])
	assert_ne(baseline_hash["hex"], changed_hash["hex"])

	var encoded := CampaignCodec.encode_save(changed, _context())
	assert_true(encoded["accepted"], str(encoded.get("error_code", &"")))
	var restored := CampaignCodec.decode_save(encoded["text"], _context())
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	assert_eq(restored["data"], changed)
	assert_eq(restored["text"], encoded["text"])
	assert_eq(CampaignHash.of_data(restored["data"], _context())["hex"], changed_hash["hex"])


func _hero(hero_id: String, operator_id: String) -> Dictionary:
	return CampaignProgression.add_initial_fields({
		"hero_id": hero_id,
		"operator_def_id": operator_id,
		"recruitment_index": int(hero_id.right(1)),
		"recruited_after_resolution_index": 0,
		"recruit_source": "starter",
		"source_id": "",
		"name_version": 1,
		"custom_callsign": null,
		"life_status": "ready",
		"death": null,
	})


func _outcome_hero(hero: Dictionary, deployed: bool, status: String) -> Dictionary:
	return {
		"hero_id": hero["hero_id"],
		"operator_def_id": hero["operator_def_id"],
		"deployments": 1 if deployed else 0,
		"fell": status == "dead",
	}


func _contract() -> Dictionary:
	var source := _text(CONTRACT_PATH)
	var parser := JSON.new()
	assert_eq(parser.parse(source), OK)
	var restored := CanonicalJson.restore_exact_integers(source, parser.data)
	assert_true(restored["accepted"])
	return restored["value"] as Dictionary


func _context() -> Dictionary:
	return CampaignCodec.build_context(
		_catalog_ids("res://data/operators"),
		_catalog_ids("res://data/traps"),
		_catalog_ids("res://data/spells"),
		_stages(),
		[{"offer_id": "p16_caster_contract", "operator_def_id": "caster_1", "cost": 80}],
	)


func _catalog_ids(path: String) -> Array:
	var ids: Array = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			ids.append(source.trim_suffix(".tres"))
	return ids


func _stages() -> Array:
	var values: Array = []
	for index: int in range(1, 9):
		values.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	return values


func _text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file)
	var source := file.get_as_text()
	file.close()
	return source
