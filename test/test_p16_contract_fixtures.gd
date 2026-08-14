extends GutTest

const CONTRACT_PATH := "res://test/fixtures/p16/contract_vectors_v1.json"
const TRANSACTION_PATH := "res://test/fixtures/p16/transaction_vectors_v2.json"
const LEGACY_TRANSACTION_PATH := "res://test/fixtures/p16/transaction_vectors_v1.json"
const LEGACY_SAVE_PATH := "res://test/fixtures/p16/campaign_v1_seed42.json"
const SAVE_PATH := "res://test/fixtures/p16/campaign_v2_seed42.json"


func test_identity_and_name_goldens() -> void:
	var fixture: Dictionary = _json(CONTRACT_PATH)
	assert_eq(HeroIdentity.campaign_uid(42, 1), fixture["campaign_uid"])
	for row: Dictionary in fixture["heroes"]:
		var bits := HeroIdentity.hero_bits(42, 1, int(row["index"]), 0)
		assert_eq(HeroIdentity.format_u64_hex(bits), row["hero_id"])
		var name_result := HeroNames.default_name(bits)
		assert_true(name_result["accepted"])
		assert_eq(name_result["value"], row["default_name"])
	print("P16_CONTRACT_DIGEST=%s" % CanonicalJson.sha256_hex(fixture))


func test_hex_boundaries_and_rejections() -> void:
	var fixture: Dictionary = _json(CONTRACT_PATH)
	for value: String in fixture["hex_boundaries"]:
		var parsed := HeroIdentity.parse_u64_hex(value)
		assert_true(parsed["accepted"], value)
		assert_eq(HeroIdentity.format_u64_hex(parsed["bits"]), value)
	for invalid: String in ["0", "00000000000000000", "ABCDEF0123456789", "gggggggggggggggg"]:
		assert_false(HeroIdentity.parse_u64_hex(invalid)["accepted"], invalid)


func test_collision_ordinals_and_exhaustion_are_exact() -> void:
	var calls: Array[String] = []
	var free := HeroIdentity.allocate_hero_id(42, 1, 10, func(candidate: String) -> bool:
		calls.append(candidate)
		return false)
	assert_true(free["accepted"])
	assert_eq(free["collision_ordinal"], 0)
	assert_eq(calls.size(), 1)

	calls.clear()
	var second := HeroIdentity.allocate_hero_id(42, 1, 10, func(candidate: String) -> bool:
		calls.append(candidate)
		return calls.size() == 1)
	assert_true(second["accepted"])
	assert_eq(second["collision_ordinal"], 1)
	assert_eq(calls.size(), 2)

	calls.clear()
	var last := HeroIdentity.allocate_hero_id(42, 1, 10, func(candidate: String) -> bool:
		calls.append(candidate)
		return calls.size() <= 31)
	assert_true(last["accepted"])
	assert_eq(last["collision_ordinal"], 31)
	assert_eq(calls.size(), 32)

	calls.clear()
	var exhausted := HeroIdentity.allocate_hero_id(42, 1, 10, func(candidate: String) -> bool:
		calls.append(candidate)
		return true)
	assert_false(exhausted["accepted"])
	assert_eq(exhausted["error_code"], &"id_collision_exhausted")
	assert_eq(calls.size(), 32)


func test_v1_migrates_to_byte_exact_v2_save_and_hash() -> void:
	var source := _text(LEGACY_SAVE_PATH)
	var context := _context()
	var decoded := CampaignCodec.decode_save(source, context)
	assert_true(decoded["accepted"], str(decoded.get("error_code", &"")))
	assert_eq(decoded["migrated_from_version"], 1)
	var expected := CampaignCodec.decode_save(_text(SAVE_PATH), context)
	assert_true(expected["accepted"], str(expected.get("error_code", &"")))
	assert_eq(expected["migrated_from_version"], 2)
	assert_eq(decoded["text"], expected["text"])
	var root: Dictionary = JSON.parse_string(decoded["text"])
	assert_eq(int(root["version"]), 2)
	assert_eq(root["checksum"], "c2b4b7aa1fd6671b8ff227da9279f119920327e8ae3f059a617e88fe757bad70")
	var strategic := CampaignHash.of_data(decoded["data"], context)
	assert_true(strategic["accepted"])
	assert_eq(strategic["hex"], "baa4d62d418258a5")
	var restored := CampaignCodec.decode_save(decoded["text"], context)
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	assert_null(restored["migrated_from_version"])
	assert_eq(restored["text"], decoded["text"])
	assert_eq(restored["data"], decoded["data"])
	assert_eq(restored["sha256"], "55f73ce3b738743c25379ac2b0e42ad33fd66c273037c7d0615aa358767f94de")

	var legacy_resolved: Dictionary = _json(LEGACY_TRANSACTION_PATH)["resolved_save"]["value"]
	assert_true(CampaignCodec.decode_save(_raw_save(legacy_resolved), context)["accepted"])
	var forged_rows: Array[Dictionary] = []
	for section: String in ["resolution_anchor", "last_resolution"]:
		for field: String in ["strategic_body_hash_before", "strategic_body_hash_after"]:
			var forged: Dictionary = legacy_resolved.duplicate(true)
			forged[section][field] = "1111111111111111"
			forged_rows.append(forged)
	for field: String in ["strategic_body_hash_before", "strategic_body_hash_after"]:
		var synchronized: Dictionary = legacy_resolved.duplicate(true)
		synchronized["resolution_anchor"][field] = "2222222222222222"
		synchronized["last_resolution"][field] = "2222222222222222"
		forged_rows.append(synchronized)
	for forged: Dictionary in forged_rows:
		var rejected := CampaignCodec.decode_save(_raw_save(forged), context)
		assert_false(rejected["accepted"])
		assert_eq(rejected["error_code"], &"invalid_v1_integrity")


func test_transaction_goldens_are_byte_exact() -> void:
	var fixture: Dictionary = _json(TRANSACTION_PATH)
	var encoders := {
		"manifest": func(value: Variant) -> Dictionary: return CampaignCodec.encode_manifest(value),
		"ticket": func(value: Variant) -> Dictionary: return CampaignCodec.encode_ticket(value),
		"outcome_body": func(value: Variant) -> Dictionary:
			return CampaignCodec.encode_outcome_body(value),
		"outcome": func(value: Variant) -> Dictionary: return CampaignCodec.encode_outcome(value),
		"resolution": func(value: Variant) -> Dictionary:
			return CampaignCodec.encode_resolution(value),
		"replay_v1_golden": func(value: Variant) -> Dictionary:
			return _encode_replay(value),
		"replay_v1_all_verbs": func(value: Variant) -> Dictionary:
			return _encode_replay(value),
	}
	for key: String in encoders:
		var vector: Dictionary = fixture[key]
		var encoded: Dictionary = encoders[key].call(vector["value"])
		assert_true(encoded["accepted"], "%s: %s" % [key, encoded.get("error_code", &"")])
		assert_eq(encoded["sha256"], vector["sha256"], key)
		assert_true(String(encoded["text"]).ends_with("\n"), key)
	assert_eq(
		fixture["replay_v1_golden"]["sha256"],
		"14d60edee09f396700b148034fee6c946660b5af0b1d7d8a48244a67f6895de9",
	)
	assert_eq(
		fixture["resolution"]["sha256"],
		"841e5f97d01222671fe209e915923e9a85f23ec57e0ce134b6ceb384db096a44",
	)
	var resolved: Dictionary = fixture["resolved_save"]
	var encoded_save := CampaignCodec.encode_save(resolved["value"], _context())
	assert_true(encoded_save["accepted"])
	assert_eq(
		encoded_save["value"]["checksum"],
		"d320beb49bf84932207ad17997e7b86ea3fdec1ff75151ca310d6a6c188164e1",
	)
	assert_eq(
		encoded_save["sha256"],
		"a890a242927ad80aab0f28c73f206df478d3d38460974edc5c084a75da9681f8",
	)
	var normalized := CampaignCodec.normalize_data(resolved["value"], _context())
	assert_true(normalized["accepted"], str(normalized.get("error_code", &"")))
	var full_hash := CampaignHash.of_data(normalized["value"], _context())
	assert_eq(full_hash["hex"], "6c13f78c886d80cc")
	var anchor: Dictionary = normalized["value"]["resolution_anchor"]
	var before_hash := CampaignHash.of_core_snapshot(anchor["before_core"], _context())
	var after_hash := CampaignHash.of_core_snapshot(anchor["after_core"], _context())
	assert_eq(before_hash["hex"], "39725890ee4a6a1a")
	assert_eq(after_hash["hex"], "4942c92d813313ac")


func test_campaign_transaction_oracle_accepts_exactly_one_transition() -> void:
	var transition := _valid_transition()
	var accepted := CampaignHash.validate_transaction(
		transition["ticket"],
		transition["outcome"],
		transition["resolution"],
		transition["before"],
		transition["after"],
		_context(),
	)
	assert_true(accepted["accepted"], String(accepted["error_code"]))
	for mutation: Dictionary in _transition_mutations(transition):
		var rejected := CampaignHash.validate_transaction(
			mutation["ticket"],
			mutation["outcome"],
			mutation["resolution"],
			mutation["before"],
			mutation["after"],
			_context(),
		)
		assert_false(rejected["accepted"], mutation["label"])


func test_save_rejects_noncanonical_and_context_invalid_documents() -> void:
	var source := _text(SAVE_PATH)
	var good := CampaignCodec.decode_save(source, _context())
	assert_true(good["accepted"])
	var unknown_operator: Dictionary = good["data"].duplicate(true)
	unknown_operator["heroes"][0]["operator_def_id"] = "missing_operator"
	var unsorted_heroes: Dictionary = good["data"].duplicate(true)
	unsorted_heroes["heroes"].reverse()
	var bad_counter: Dictionary = good["data"].duplicate(true)
	bad_counter["next_recruitment_index"] = 4
	var duplicate_callsign: Dictionary = good["data"].duplicate(true)
	duplicate_callsign["heroes"][0]["custom_callsign"] = "ACE"
	duplicate_callsign["heroes"][1]["custom_callsign"] = "ace"
	var invalid_sources: Array[String] = [
		source.trim_suffix("\n") + " \n",
		_raw_save(unknown_operator),
		_raw_save(unsorted_heroes),
		_raw_save(bad_counter),
		_raw_save(duplicate_callsign),
	]
	for invalid_source: String in invalid_sources:
		assert_false(CampaignCodec.decode_save(invalid_source, _context())["accepted"])


func test_save_integer_lexemes_are_exact_through_u63_max() -> void:
	var good := CampaignCodec.decode_save(_text(SAVE_PATH), _context())
	for boundary: int in [9_007_199_254_740_991, 9_007_199_254_740_992,
		9_007_199_254_740_993, 9_223_372_036_854_775_807]:
		var data: Dictionary = good["data"].duplicate(true)
		data["save_revision"] = boundary
		var encoded := CampaignCodec.encode_save(data, _context())
		assert_true(encoded["accepted"], str(boundary))
		var decoded := CampaignCodec.decode_save(encoded["text"], _context())
		assert_true(decoded["accepted"], str(boundary))
		assert_eq(decoded["data"]["save_revision"], boundary, str(boundary))
		assert_eq(decoded["text"], encoded["text"], str(boundary))
	for invalid: String in ["9223372036854775808", "-9223372036854775809", "1.0", "1e0", "01"]:
		var source := _text(SAVE_PATH).replace("\"save_revision\":1", "\"save_revision\":%s" % invalid)
		assert_false(CampaignCodec.decode_save(source, _context())["accepted"], invalid)


func test_provenance_ascii_and_callsign_controls_are_strict() -> void:
	var transition := _valid_transition()
	var context := _context()
	for codepoint: int in [1, 31, 127, 128, 159]:
		var data: Dictionary = transition["before"].duplicate(true)
		data["heroes"][0]["custom_callsign"] = "A%sB" % String.chr(codepoint)
		assert_false(CampaignCodec.normalize_data(data, context)["accepted"], str(codepoint))
	var non_ascii: Dictionary = transition["before"].duplicate(true)
	non_ascii["heroes"][0]["operator_def_id"] = "guárd_1"
	var unicode_context := _context()
	unicode_context["operator_ids"]["guárd_1"] = true
	assert_false(CampaignCodec.normalize_data(non_ascii, unicode_context)["accepted"])
	var bad_contract: Dictionary = transition["before"].duplicate(true)
	bad_contract["heroes"][5]["operator_def_id"] = "defender_1"
	assert_false(CampaignCodec.normalize_data(bad_contract, context)["accepted"])
	var bad_identity: Dictionary = transition["before"].duplicate(true)
	bad_identity["heroes"][5]["hero_id"] = "0000000000000001"
	assert_false(CampaignCodec.normalize_data(bad_identity, context)["accepted"])
	var duplicate_reward: Dictionary = transition["resolution"].duplicate(true)
	duplicate_reward["rewards_granted"].append(
		duplicate_reward["rewards_granted"][0].duplicate(true),
	)
	assert_false(CampaignCodec.normalize_resolution(duplicate_reward)["accepted"])


func test_save_history_provenance_is_exhaustive() -> void:
	var context := _context()
	var fresh: Dictionary = CampaignCodec.decode_save(_text(SAVE_PATH), context)["data"]
	var forged_starter: Dictionary = fresh.duplicate(true)
	forged_starter["heroes"][0]["operator_def_id"] = "guard_2"
	var premature_recovery: Dictionary = fresh.duplicate(true)
	premature_recovery["next_recruitment_index"] = 6
	premature_recovery["heroes"].append({
		"hero_id": "e54c103e46898f5d", "operator_def_id": "vanguard_1",
		"recruitment_index": 5, "recruited_after_resolution_index": 0,
		"recruit_source": "recovery", "source_id": "s2",
		"name_version": 1, "custom_callsign": null, "life_status": "ready", "death": null,
	})
	var duplicate_ready_recovery: Dictionary = premature_recovery.duplicate(true)
	duplicate_ready_recovery["heroes"][-1]["source_id"] = "s1"
	var impossible_death: Dictionary = fresh.duplicate(true)
	impossible_death["heroes"][0]["life_status"] = "dead"
	impossible_death["heroes"][0]["death"] = {
		"resolution_index": 1, "attempt_id": 1, "stage_id": "s8",
		"terminal_reason": "base_defeat", "terminal_tick": 10,
	}
	var missing_reward: Dictionary = fresh.duplicate(true)
	missing_reward["stage_stars"] = [{
		"stage_id": "s1", "stars": 1, "first_clear_resolution_index": 1,
		"first_clear_attempt_id": 1, "first_clear_terminal_tick": 1000,
	}]
	var transition := _valid_transition()
	var extra_latest_death: Dictionary = transition["after"].duplicate(true)
	extra_latest_death["heroes"][0]["life_status"] = "dead"
	extra_latest_death["heroes"][0]["death"] = {
		"resolution_index": 1, "attempt_id": 1, "stage_id": "s1",
		"terminal_reason": "clear", "terminal_tick": 800,
	}
	var invalid_stars: Dictionary = transition["after"].duplicate(true)
	invalid_stars["last_resolution"]["stars_after"] = 2
	var reversed_rewards := _reversed_reward_history(fresh)
	var conflicting_deaths := _conflicting_death_history(transition["after"])
	var late_recovery := _late_recovery_history(transition["after"])
	var forged_marks: Dictionary = transition["after"].duplicate(true)
	forged_marks["marks"] = 120
	forged_marks["last_resolution"]["marks_after"] = 120
	forged_marks["last_resolution"]["strategic_body_hash_after"] = "0000000000000000"
	var forged_hash: Dictionary = transition["after"].duplicate(true)
	forged_hash["last_resolution"]["strategic_body_hash_before"] = "1111111111111111"
	forged_hash["last_resolution"]["strategic_body_hash_after"] = "2222222222222222"
	var synchronized_forgery: Dictionary = transition["after"].duplicate(true)
	synchronized_forgery["save_revision"] = 5
	synchronized_forgery["next_attempt_id"] = 3
	var forged_anchor: Dictionary = synchronized_forgery["resolution_anchor"]
	forged_anchor["before_core"]["next_attempt_id"] = 3
	forged_anchor["after_core"]["next_attempt_id"] = 3
	var forged_before_hash: String = CampaignHash.of_core_snapshot(
		forged_anchor["before_core"], context,
	)["hex"]
	var forged_after_hash: String = CampaignHash.of_core_snapshot(
		forged_anchor["after_core"], context,
	)["hex"]
	forged_anchor["strategic_body_hash_before"] = forged_before_hash
	forged_anchor["strategic_body_hash_after"] = forged_after_hash
	synchronized_forgery["last_resolution"]["strategic_body_hash_before"] = forged_before_hash
	synchronized_forgery["last_resolution"]["strategic_body_hash_after"] = forged_after_hash
	var invalid_core := _core_snapshot(transition["after"])
	invalid_core["campaign_uid"] = "0000000000000000"
	assert_false(CampaignHash.of_core_snapshot(invalid_core, context)["accepted"])
	for invalid: Dictionary in [
		forged_starter, premature_recovery, duplicate_ready_recovery,
		impossible_death, missing_reward, extra_latest_death,
		invalid_stars, reversed_rewards, conflicting_deaths, late_recovery,
		forged_marks, forged_hash, synchronized_forgery,
	]:
		var prior_hash: String = CampaignHash.of_data(fresh, context)["hex"]
		var decoded := CampaignCodec.decode_save(_raw_save(invalid), context)
		assert_false(decoded["accepted"], str(decoded.get("error_code", &"")))
		assert_eq(CampaignHash.of_data(fresh, context)["hex"], prior_hash)


func test_post_resolution_mutations_keep_anchor_loadable() -> void:
	var transition := _valid_transition()
	var context := _context()
	var renamed_save: Dictionary = transition["after"].duplicate(true)
	renamed_save["save_revision"] = 5
	renamed_save["heroes"][0]["custom_callsign"] = "Nova"
	assert_true(CampaignCodec.encode_save(renamed_save, context)["accepted"])
	var begun: Dictionary = transition["after"].duplicate(true)
	begun["save_revision"] = 5
	begun["next_attempt_id"] = 3
	assert_true(CampaignCodec.encode_save(begun, context)["accepted"])
	var revision_only: Dictionary = transition["after"].duplicate(true)
	revision_only["save_revision"] = 5
	assert_false(CampaignCodec.encode_save(revision_only, context)["accepted"])
	var jumped_attempt: Dictionary = transition["after"].duplicate(true)
	jumped_attempt["save_revision"] = 5
	jumped_attempt["next_attempt_id"] = 4
	assert_false(CampaignCodec.encode_save(jumped_attempt, context)["accepted"])
	var recovered: Dictionary = transition["after"].duplicate(true)
	recovered["save_revision"] = 5
	recovered["next_recruitment_index"] = 8
	var allocation := HeroIdentity.allocate_hero_id(42, 1, 7, func(_id: String) -> bool: return false)
	recovered["heroes"].append(_hero_row(
		allocation["hero_id"], "defender_1", 7, "recovery", "s2", 1,
	))
	assert_true(CampaignCodec.encode_save(recovered, context)["accepted"])
	var late_transition := _valid_transition_without_contract()
	assert_true(CampaignHash.validate_transaction(
		late_transition["ticket"], late_transition["outcome"], late_transition["resolution"],
		late_transition["before"], late_transition["after"], context,
	)["accepted"])
	var contracted: Dictionary = late_transition["after"].duplicate(true)
	contracted["save_revision"] = 5
	contracted["marks"] = 40
	contracted["offers"][0]["consumed"] = true
	contracted["next_recruitment_index"] = 7
	var contract_id := HeroIdentity.allocate_hero_id(42, 1, 6, func(_id: String) -> bool: return false)
	contracted["heroes"].append(_hero_row(
		contract_id["hero_id"], "caster_1", 6, "contract", "p16_caster_contract", 1,
	))
	assert_true(CampaignCodec.encode_save(contracted, context)["accepted"])


func test_recruitment_history_has_no_gaps_or_counter_ahead() -> void:
	var fresh: Dictionary = CampaignCodec.decode_save(_text(SAVE_PATH), _context())["data"]
	var gap: Dictionary = fresh.duplicate(true)
	gap["offers"][0]["consumed"] = true
	gap["marks"] = 40
	gap["next_recruitment_index"] = 8
	var allocation := HeroIdentity.allocate_hero_id(42, 1, 7, func(_id: String) -> bool: return false)
	gap["heroes"].append(_hero_row(
		allocation["hero_id"], "caster_1", 7, "contract", "p16_caster_contract",
	))
	assert_false(CampaignCodec.encode_save(gap, _context())["accepted"])
	var counter_ahead: Dictionary = fresh.duplicate(true)
	counter_ahead["next_recruitment_index"] = 6
	assert_false(CampaignCodec.encode_save(counter_ahead, _context())["accepted"])
	var decreasing_attempt: Dictionary = fresh.duplicate(true)
	decreasing_attempt["stage_stars"] = [
		{
			"stage_id": "s1", "stars": 1, "first_clear_resolution_index": 1,
			"first_clear_attempt_id": 2, "first_clear_terminal_tick": 100,
		},
		{
			"stage_id": "s2", "stars": 1, "first_clear_resolution_index": 2,
			"first_clear_attempt_id": 1, "first_clear_terminal_tick": 200,
		},
	]
	var normalized := CampaignCodec.normalize_data(decreasing_attempt, _context())
	assert_false(normalized["accepted"])
	assert_eq(normalized["error_code"], &"noncanonical_stage_history")


func test_resolution_events_share_exact_stage_attempt_reason_and_tick() -> void:
	var transition := _valid_transition()
	var dead: Dictionary = transition["after"].heroes[1]
	dead = transition["after"].heroes.filter(
		func(hero: Dictionary) -> bool: return hero["hero_id"] == "cb0a9db634ff05af",
	)[0]
	assert_eq(dead["death"]["terminal_tick"], transition["outcome"]["terminal_tick"])
	assert_ne(dead["death"]["terminal_tick"], transition["outcome"]["heroes"][2]["first_fall_tick"])
	var conflict: Dictionary = transition["after"].duplicate(true)
	for hero: Dictionary in conflict["heroes"]:
		if hero["hero_id"] == "cb0a9db634ff05af":
			hero["death"]["stage_id"] = "s2"
	assert_false(CampaignCodec.encode_save(conflict, _context())["accepted"])
	var duplicate_attempt_receipt: Dictionary = transition["resolution"].duplicate(true)
	duplicate_attempt_receipt["resolution_index"] = 2
	duplicate_attempt_receipt["attempt_id"] = 2
	var duplicate_attempt_events := {
		"stage_stars": [{
			"stage_id": "s1", "stars": 1, "first_clear_resolution_index": 1,
			"first_clear_attempt_id": 2, "first_clear_terminal_tick": 100,
		}],
		"heroes": [],
		"last_resolution": duplicate_attempt_receipt,
	}
	var ledger := CampaignInvariants._validate_global_events(duplicate_attempt_events)
	assert_false(ledger["accepted"])
	assert_eq(ledger["error_code"], &"resolution_attempt_history_mismatch")


func test_callsign_scalar_and_identity_boundaries() -> void:
	var context := _context()
	var fresh: Dictionary = CampaignCodec.decode_save(_text(SAVE_PATH), context)["data"]
	for callsign: String in [" ACE", "ACE ", "\tACE", "ACE\t", "A\nB"]:
		var invalid: Dictionary = fresh.duplicate(true)
		invalid["heroes"][0]["custom_callsign"] = callsign
		assert_false(CampaignCodec.normalize_data(invalid, context)["accepted"], callsign)
	var twenty: Dictionary = fresh.duplicate(true)
	twenty["heroes"][0]["custom_callsign"] = "A".repeat(20)
	assert_true(CampaignCodec.normalize_data(twenty, context)["accepted"])
	var twenty_one: Dictionary = fresh.duplicate(true)
	twenty_one["heroes"][0]["custom_callsign"] = "A".repeat(21)
	assert_false(CampaignCodec.normalize_data(twenty_one, context)["accepted"])
	var combining: Dictionary = fresh.duplicate(true)
	combining["heroes"][0]["custom_callsign"] = "A\u0301"
	var encoded := CampaignCodec.encode_save(combining, context)
	assert_true(encoded["accepted"])
	var decoded := CampaignCodec.decode_save(encoded["text"], context)
	assert_eq(decoded["data"]["heroes"][0]["custom_callsign"], "A\u0301")
	var unicode_case: Dictionary = fresh.duplicate(true)
	unicode_case["heroes"][0]["custom_callsign"] = "Élan"
	unicode_case["heroes"][1]["custom_callsign"] = "élan"
	assert_false(CampaignCodec.normalize_data(unicode_case, context)["accepted"])
	var duplicate_default: Dictionary = fresh.duplicate(true)
	var other_bits: int = HeroIdentity.parse_u64_hex(fresh["heroes"][1]["hero_id"])["bits"]
	duplicate_default["heroes"][0]["custom_callsign"] = HeroNames.default_name(other_bits)["value"]
	assert_false(CampaignCodec.normalize_data(duplicate_default, context)["accepted"])


func test_decode_rejections_preserve_source_and_prior_state() -> void:
	var source := _text(SAVE_PATH)
	var context := _context()
	var good := CampaignCodec.decode_save(source, context)
	var before_data: Dictionary = good["data"].duplicate(true)
	var before_hash: String = CampaignHash.of_data(before_data, context)["hex"]
	var corrupt: Dictionary = JSON.parse_string(source)
	corrupt["data"]["marks"] = -1
	var bad_source := CanonicalJson.text(corrupt)
	var rejected := CampaignCodec.decode_save(bad_source, context)
	assert_false(rejected["accepted"])
	assert_eq(good["data"], before_data)
	assert_eq(CampaignHash.of_data(good["data"], context)["hex"], before_hash)
	assert_eq(source, _text(SAVE_PATH), "fixture bytes unchanged")


func _reversed_reward_history(fresh: Dictionary) -> Dictionary:
	var data := fresh.duplicate(true)
	data["save_revision"] = 2
	data["next_recruitment_index"] = 7
	data["next_attempt_id"] = 4
	data["next_resolution_index"] = 4
	data["stage_stars"] = [
		{"stage_id": "s1", "stars": 1, "first_clear_resolution_index": 1,
			"first_clear_attempt_id": 1, "first_clear_terminal_tick": 1000},
		{"stage_id": "s2", "stars": 1, "first_clear_resolution_index": 2,
			"first_clear_attempt_id": 2, "first_clear_terminal_tick": 1000},
		{"stage_id": "s3", "stars": 1, "first_clear_resolution_index": 3,
			"first_clear_attempt_id": 3, "first_clear_terminal_tick": 1000},
	]
	data["unlocked_traps"] = ["spike_plate", "tar_pit"]
	data["heroes"].append(_hero_row(
		"e54c103e46898f5d", "sniper_1", 5, "reward", "s3", 3,
	))
	data["heroes"].append(_hero_row(
		"fe0ff2c1e3ecc49d", "guard_2", 6, "reward", "s1", 1,
	))
	var receipt: Dictionary = _valid_transition()["resolution"].duplicate(true)
	receipt["resolution_index"] = 3
	receipt["attempt_id"] = 3
	receipt["stage_id"] = "s3"
	receipt["stars_after"] = 1
	receipt["rewards_granted"] = [
		{"kind": "operator", "id": "sniper_1", "hero_instance_id": "e54c103e46898f5d"},
		{"kind": "trap", "id": "tar_pit", "hero_instance_id": null},
	]
	receipt["created_hero_ids"] = ["e54c103e46898f5d"]
	receipt["dead_hero_ids"] = []
	data["last_resolution"] = receipt
	return data


func _conflicting_death_history(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	data["next_attempt_id"] = 3
	data["next_resolution_index"] = 3
	data["last_resolution"]["resolution_index"] = 2
	data["last_resolution"]["attempt_id"] = 2
	data["last_resolution"]["stars_before"] = 3
	data["last_resolution"]["rewards_granted"] = []
	data["last_resolution"]["created_hero_ids"] = []
	data["last_resolution"]["dead_hero_ids"] = []
	data["heroes"][0]["life_status"] = "dead"
	data["heroes"][0]["death"] = {
		"resolution_index": 1, "attempt_id": 1, "stage_id": "s2",
		"terminal_reason": "base_defeat", "terminal_tick": 700,
	}
	return data


func _late_recovery_history(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	var allocation := HeroIdentity.allocate_hero_id(42, 1, 7, func(_id: String) -> bool: return false)
	data["next_recruitment_index"] = 8
	data["heroes"].append(_hero_row(
		allocation["hero_id"], "defender_1", 7, "recovery", "s1", 1,
	))
	return data


func _hero_row(
	hero_id: String,
	operator_id: String,
	index: int,
	source: String,
	source_id: String,
	created_after: int = 0,
) -> Dictionary:
	return CampaignProgression.add_initial_fields({
		"hero_id": hero_id, "operator_def_id": operator_id,
		"recruitment_index": index,
		"recruited_after_resolution_index": created_after,
		"recruit_source": source, "source_id": source_id,
		"name_version": 1, "custom_callsign": null, "life_status": "ready", "death": null,
	})


func _valid_transition_without_contract() -> Dictionary:
	var transition := _valid_transition()
	for key: String in ["before", "after"]:
		transition[key]["heroes"] = transition[key]["heroes"].filter(
			func(hero: Dictionary) -> bool: return hero["recruit_source"] != "contract",
		)
		transition[key]["offers"][0]["consumed"] = false
		transition[key]["marks"] = 120
	transition["before"]["next_recruitment_index"] = 5
	transition["after"]["next_recruitment_index"] = 6
	for hero: Dictionary in transition["after"]["heroes"]:
		if hero["recruit_source"] == "reward":
			hero["recruitment_index"] = 5
			hero["hero_id"] = "e54c103e46898f5d"
	transition["resolution"]["marks_before"] = 120
	transition["resolution"]["marks_after"] = 120
	transition["resolution"]["rewards_granted"][0]["hero_instance_id"] = "e54c103e46898f5d"
	transition["resolution"]["created_hero_ids"] = ["e54c103e46898f5d"]
	transition["resolution"]["strategic_body_hash_before"] = CampaignHash.of_core(
		transition["before"], _context(),
	)["hex"]
	_rehash_transition(transition)
	return transition


func _valid_transition() -> Dictionary:
	var vectors := _json(TRANSACTION_PATH)
	var before: Dictionary = CampaignCodec.decode_save(_text(SAVE_PATH), _context())["data"]
	before = before.duplicate(true)
	before["save_revision"] = 3
	before["next_attempt_id"] = 2
	before["next_recruitment_index"] = 6
	before["marks"] = 40
	before["offers"][0]["consumed"] = true
	before["heroes"].append(CampaignProgression.add_initial_fields({
		"hero_id": "e54c103e46898f5d",
		"operator_def_id": "caster_1",
		"recruitment_index": 5,
		"recruited_after_resolution_index": 0,
		"recruit_source": "contract",
		"source_id": "p16_caster_contract",
		"name_version": 1,
		"custom_callsign": null,
		"life_status": "ready",
		"death": null,
	}))
	var ticket: Dictionary = vectors["ticket"]["value"].duplicate(true)
	var outcome: Dictionary = vectors["outcome"]["value"].duplicate(true)
	var resolution := _v2_resolution(vectors["resolution"]["value"])
	resolution["marks_before"] = before["marks"]
	resolution["marks_after"] = before["marks"]
	resolution["strategic_body_hash_before"] = CampaignHash.of_core(before, _context())["hex"]
	resolution["xp_awards"] = CampaignProgression.derive_xp_awards(
		outcome["heroes"], before["heroes"],
	)
	var after: Dictionary = before.duplicate(true)
	assert_true(CampaignProgression.apply_xp(after["heroes"], resolution["xp_awards"]))
	after["save_revision"] = 4
	after["next_resolution_index"] = 2
	after["next_recruitment_index"] = 7
	after["stage_stars"] = [{
		"stage_id": "s1", "stars": 3, "first_clear_resolution_index": 1,
		"first_clear_attempt_id": 1, "first_clear_terminal_tick": 1000,
	}]
	for hero: Dictionary in after["heroes"]:
		if hero["hero_id"] == "cb0a9db634ff05af":
			hero["life_status"] = "dead"
			hero["death"] = {
				"resolution_index": 1,
				"attempt_id": 1,
				"stage_id": "s1",
				"terminal_reason": "clear",
				"terminal_tick": 1000,
			}
	after["heroes"].append(CampaignProgression.add_initial_fields({
		"hero_id": "fe0ff2c1e3ecc49d",
		"operator_def_id": "guard_2",
		"recruitment_index": 6,
		"recruited_after_resolution_index": 1,
		"recruit_source": "reward",
		"source_id": "s1",
		"name_version": 1,
		"custom_callsign": null,
		"life_status": "ready",
		"death": null,
	}))
	resolution["strategic_body_hash_after"] = "0000000000000000"
	after["last_resolution"] = resolution.duplicate(true)
	resolution["strategic_body_hash_after"] = CampaignHash.of_core_snapshot(
		_core_snapshot(after), _context(),
	)["hex"]
	after["resolution_anchor"] = {
		"resolution_index": resolution["resolution_index"],
		"save_revision_after": after["save_revision"],
		"before_core": _core_snapshot(before),
		"after_core": _core_snapshot(after),
		"strategic_body_hash_before": resolution["strategic_body_hash_before"],
		"strategic_body_hash_after": resolution["strategic_body_hash_after"],
	}
	after["last_resolution"] = resolution.duplicate(true)
	return {
		"ticket": ticket,
		"outcome": outcome,
		"resolution": resolution,
		"before": before,
		"after": after,
	}


func _v2_resolution(source: Dictionary) -> Dictionary:
	var result := {}
	for key: String in CampaignCodec.RESOLUTION_KEYS:
		if key == "schema_version":
			result[key] = 2
		elif key == "xp_awards":
			result[key] = []
		else:
			result[key] = source[key]
	return result


func _transition_mutations(source: Dictionary) -> Array:
	var mutations: Array = []
	var identity: Dictionary = source.duplicate(true)
	identity["outcome"]["stage_id"] = "s2"
	mutations.append(_labeled(identity, "identity mismatch"))
	var receipt: Dictionary = source.duplicate(true)
	receipt["after"]["last_resolution"]["marks_after"] -= 1
	mutations.append(_labeled(receipt, "receipt mismatch"))
	var casualty: Dictionary = source.duplicate(true)
	for hero: Dictionary in casualty["after"]["heroes"]:
		if hero["hero_id"] == "cb0a9db634ff05af":
			hero["life_status"] = "ready"
			hero["death"] = null
	mutations.append(_labeled(casualty, "casualty mismatch"))
	var hash_after: Dictionary = source.duplicate(true)
	hash_after["resolution"]["strategic_body_hash_after"] = "0000000000000000"
	hash_after["after"]["last_resolution"] = hash_after["resolution"].duplicate(true)
	mutations.append(_labeled(hash_after, "post-state hash mismatch"))
	var unrelated_callsign: Dictionary = source.duplicate(true)
	unrelated_callsign["after"]["heroes"][0]["custom_callsign"] = "FORGED"
	_rehash_transition(unrelated_callsign)
	mutations.append(_labeled(unrelated_callsign, "unrelated callsign mutation"))
	var wrong_death_tick: Dictionary = source.duplicate(true)
	for hero: Dictionary in wrong_death_tick["after"]["heroes"]:
		if hero["hero_id"] == "cb0a9db634ff05af":
			hero["death"]["terminal_tick"] = 899
	_rehash_transition(wrong_death_tick)
	mutations.append(_labeled(wrong_death_tick, "death tick mismatch"))
	return mutations


func _rehash_transition(transition: Dictionary) -> void:
	transition["resolution"]["strategic_body_hash_after"] = "0000000000000000"
	transition["after"]["last_resolution"] = transition["resolution"].duplicate(true)
	transition["resolution"]["strategic_body_hash_after"] = CampaignHash.of_core_snapshot(
		_core_snapshot(transition["after"]), _context(),
	)["hex"]
	transition["after"]["resolution_anchor"] = {
		"resolution_index": transition["resolution"]["resolution_index"],
		"save_revision_after": transition["after"]["save_revision"],
		"before_core": _core_snapshot(transition["before"]),
		"after_core": _core_snapshot(transition["after"]),
		"strategic_body_hash_before": transition["resolution"]["strategic_body_hash_before"],
		"strategic_body_hash_after": transition["resolution"]["strategic_body_hash_after"],
	}
	transition["after"]["last_resolution"] = transition["resolution"].duplicate(true)


func _core_snapshot(data: Dictionary) -> Dictionary:
	var snapshot: Dictionary = data.duplicate(true)
	snapshot.erase("resolution_anchor")
	snapshot.erase("last_resolution")
	return snapshot


func _labeled(mutation: Dictionary, label: String) -> Dictionary:
	mutation["label"] = label
	return mutation


func _raw_save(data: Dictionary) -> String:
	var root := {}
	root["schema"] = "prototype_td_campaign"
	root["version"] = 1
	root["checksum"] = CanonicalJson.sha256_text(CanonicalJson.text(data))
	root["data"] = data
	return CanonicalJson.text(root)


func _json(path: String) -> Dictionary:
	return _coerce_fixture(JSON.parse_string(_text(path))) as Dictionary


func _coerce_fixture(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			return int(value) if float(value) == floor(float(value)) else value
		TYPE_ARRAY:
			var array: Array = []
			for item: Variant in value:
				array.append(_coerce_fixture(item))
			return array
		TYPE_DICTIONARY:
			var dictionary := {}
			for key: Variant in value:
				dictionary[key] = _coerce_fixture(value[key])
			return dictionary
		_:
			return value


func _encode_replay(value: Variant) -> Dictionary:
	var context := _replay_context()
	var decoded := ReplayCodec.decode_document(value, context)
	if not decoded["accepted"]:
		return decoded
	return ReplayCodec.encode_document(
		decoded["stage_id"],
		decoded["squad"],
		decoded["seed"],
		decoded["timeline"],
		context,
	)


func _text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, path)
	var source := file.get_as_text()
	file.close()
	return source


func _context() -> Dictionary:
	var stages: Array = []
	for index: int in range(1, 9):
		stages.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	return CampaignCodec.build_context(
		_catalog_ids("res://data/operators"),
		_catalog_ids("res://data/traps"),
		_catalog_ids("res://data/spells"),
		stages,
		[{"offer_id": "p16_caster_contract", "operator_def_id": "caster_1", "cost": 80}],
	)


func _catalog_ids(path: String) -> Array:
	var ids: Array = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			ids.append(source.trim_suffix(".tres"))
	return ids


func _replay_context() -> Dictionary:
	return ReplayCodec.build_context(
		_catalog_defs("res://data/operators"),
		_catalog_defs("res://data/traps"),
		_catalog_defs("res://data/spells"),
		_catalog_defs("res://data/stages"),
		load("res://data/config/game.tres") as GameConfig,
	)


func _catalog_defs(path: String) -> Dictionary:
	var defs := {}
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var resource: Resource = load("%s/%s" % [path, source])
			defs[resource.get("id")] = resource
	return defs
