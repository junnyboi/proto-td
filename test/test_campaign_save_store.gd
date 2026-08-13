extends "res://test/campaign_save_store_cases.gd"

const SLOT := "user://p162-store.json"
const TMP := "user://p162-store.tmp"
const BAK := "user://p162-store.bak"

class FaultOps extends CampaignFileOps:
	var files := {}
	var failures := {}
	var corrupt_reads := {}
	var corrupt_writes := {}
	var partial_write_failures := {}
	var calls := {}

	func file_exists(path: String) -> bool:
		return files.has(path)

	func read_bytes(path: String) -> Dictionary:
		var ordinal := _ordinal("read", path)
		if failures.has(_key("read", path, ordinal)):
			return {"accepted": false, "error_code": &"injected", "bytes": PackedByteArray()}
		if not files.has(path):
			return {"accepted": false, "error_code": &"file_missing", "bytes": PackedByteArray()}
		var key := _key("read", path, ordinal)
		var bytes: PackedByteArray = corrupt_reads.get(key, files[path])
		return {"accepted": true, "error_code": &"", "bytes": bytes.duplicate()}

	func write_bytes(path: String, bytes: PackedByteArray) -> Dictionary:
		var ordinal := _ordinal("write", path)
		var key := _key("write", path, ordinal)
		if partial_write_failures.has(key):
			files[path] = bytes.slice(0, mini(7, bytes.size()))
			return {"accepted": false, "error_code": &"injected"}
		if failures.has(_key("write", path, ordinal)):
			return {"accepted": false, "error_code": &"injected"}
		files[path] = (corrupt_writes.get(key, bytes) as PackedByteArray).duplicate()
		return {"accepted": true, "error_code": &""}

	func rename_path(from_path: String, to_path: String) -> Dictionary:
		var path := "%s->%s" % [from_path, to_path]
		var ordinal := _ordinal("rename", path)
		if failures.has(_key("rename", path, ordinal)) or not files.has(from_path):
			return {"accepted": false, "error_code": &"injected"}
		files[to_path] = files[from_path]
		files.erase(from_path)
		return {"accepted": true, "error_code": &""}

	func remove_path(path: String) -> Dictionary:
		var ordinal := _ordinal("remove", path)
		if failures.has(_key("remove", path, ordinal)) or not files.has(path):
			return {"accepted": false, "error_code": &"injected"}
		files.erase(path)
		return {"accepted": true, "error_code": &""}

	func _ordinal(method: String, path: String) -> int:
		var prefix := "%s:%s" % [method, path]
		calls[prefix] = int(calls.get(prefix, 0)) + 1
		return calls[prefix]

	func _key(method: String, path: String, ordinal: int) -> String:
		return "%s:%s:%d" % [method, path, ordinal]


func test_load_empty_slot_reports_slot_missing() -> void:
	var state := _fresh()
	var store := _store(state, FaultOps.new())
	var result := store.load()
	assert_false(result["accepted"])
	assert_eq(result["error_code"], &"slot_missing")


func test_load_main_wins_and_cleans_sidecars() -> void:
	var states := _states()
	var ops := FaultOps.new()
	_seed(ops, SLOT, states[1])
	_seed(ops, BAK, states[0])
	_seed(ops, TMP, states[2])
	var result := _store(states[0], ops).load()
	assert_true(result["accepted"])
	assert_eq(result["source"], &"main")
	assert_eq((result["state"] as CampaignState).save_revision(), 2)
	assert_false(ops.file_exists(BAK))
	assert_false(ops.file_exists(TMP))


func test_load_bak_when_main_missing() -> void:
	_assert_load_layout({BAK: _states()[1]}, &"bak", 2)


func test_load_tmp_when_main_and_bak_missing() -> void:
	_assert_load_layout({TMP: _states()[2]}, &"tmp", 3)


func test_load_bak_beats_newer_tmp_by_frozen_policy() -> void:
	var states := _states()
	_assert_load_layout({BAK: states[1], TMP: states[3]}, &"bak", 2)


func test_load_corrupt_main_uses_valid_bak() -> void:
	var states := _states()
	_assert_load_bytes({SLOT: _bad(), BAK: states[1].encode_save()["bytes"]}, &"bak", 2)


func test_load_corrupt_main_uses_valid_newer_tmp() -> void:
	var states := _states()
	_assert_load_bytes({SLOT: _bad(), TMP: states[2].encode_save()["bytes"]}, &"tmp", 3)


func test_load_all_invalid_reports_slot_corrupt() -> void:
	var result := _load_bytes({SLOT: _bad(), BAK: _bad(), TMP: _bad()})
	assert_false(result["accepted"])
	assert_eq(result["error_code"], &"slot_corrupt")


func test_equal_version_divergent_bak_tmp_blocks() -> void:
	var fresh := _fresh()
	var paid := _commit_state(fresh.recruit("p16_caster_contract"), fresh)
	var renamed := _commit_state(fresh.rename_hero(_ready_ids(fresh)[0], "Nova"), fresh)
	var result := _load_bytes({
		BAK: paid.encode_save()["bytes"], TMP: renamed.encode_save()["bytes"],
	})
	assert_false(result["accepted"])
	assert_eq(result["error_code"], &"slot_corrupt")


func test_tmp_older_than_invalid_higher_generation_header_blocks() -> void:
	var generation_two := _fresh_generation(2)
	var tmp := _states()[3]
	var result := _load_bytes({
		SLOT: _corrupt_checksum(generation_two.encode_save()["text"]),
		TMP: tmp.encode_save()["bytes"],
	})
	assert_false(result["accepted"])
	assert_eq(result["error_code"], &"slot_corrupt")


func test_tmp_same_generation_higher_revision_recovers() -> void:
	var states := _states()
	var result := _load_bytes({
		SLOT: _corrupt_checksum(states[1].encode_save()["text"]),
		TMP: states[2].encode_save()["bytes"],
	})
	assert_true(result["accepted"])
	assert_eq(result["source"], &"tmp")


func test_tmp_lower_than_invalid_bak_blocks() -> void:
	var states := _states()
	var result := _load_bytes({
		BAK: _corrupt_checksum(states[3].encode_save()["text"]),
		TMP: states[2].encode_save()["bytes"],
	})
	assert_false(result["accepted"])
	assert_eq(result["error_code"], &"slot_corrupt")


func test_invalid_main_bak_and_equal_or_newer_tmp_recovers() -> void:
	var states := _states()
	var result := _load_bytes({
		SLOT: _corrupt_checksum(states[2].encode_save()["text"]),
		BAK: _corrupt_checksum(states[1].encode_save()["text"]),
		TMP: states[2].encode_save()["bytes"],
	})
	assert_true(result["accepted"])
	assert_eq((result["state"] as CampaignState).save_revision(), 3)


func test_save_success_commits_exact_prospective_and_removes_bak() -> void:
	var states := _states()
	var ops := FaultOps.new()
	_seed(ops, SLOT, states[0])
	var store := _store(states[0], ops)
	var result := store.save(
		states[0].encode_save()["text"], states[1],
	)
	assert_eq(result["status"], &"committed")
	assert_eq((ops.files[SLOT] as PackedByteArray).get_string_from_utf8(),
		states[1].encode_save()["text"])
	assert_true(store._consume_commit_authority().is_empty())
	assert_false(ops.file_exists(BAK))


func test_save_exact_prospective_winner_is_idempotent_success() -> void:
	var states := _states()
	var ops := FaultOps.new()
	_seed(ops, SLOT, states[1])
	var result := _store(states[0], ops).save(
		states[0].encode_save()["text"], states[1],
	)
	assert_eq(result["status"], &"committed")
	assert_eq(int(ops.calls.get("write:%s" % TMP, 0)), 0)


func test_save_divergent_winner_blocks_without_write() -> void:
	var fresh := _fresh()
	var paid := _commit_state(fresh.recruit("p16_caster_contract"), fresh)
	var renamed := _commit_state(fresh.rename_hero(_ready_ids(fresh)[0], "Nova"), fresh)
	var ops := FaultOps.new()
	_seed(ops, SLOT, renamed)
	var result := _store(fresh, ops).save(fresh.encode_save()["text"], paid)
	assert_eq(result["status"], &"indeterminate")
	assert_eq(result["error_code"], &"store_integrity_failure")
	assert_eq(int(ops.calls.get("write:%s" % TMP, 0)), 0)


func test_save_write_failure_is_retryable_and_preserves_preimage() -> void:
	var states := _states()
	var ops := FaultOps.new()
	_seed(ops, SLOT, states[0])
	ops.failures["write:%s:1" % TMP] = true
	var result := _store(states[0], ops).save(states[0].encode_save()["text"], states[1])
	assert_eq(result["status"], &"retryable")
	assert_eq(result["error_code"], &"store_write_failed")
	assert_eq((ops.files[SLOT] as PackedByteArray).get_string_from_utf8(),
		states[0].encode_save()["text"])


func test_save_corrupt_tmp_validation_is_retryable() -> void:
	var states := _states()
	var ops := FaultOps.new()
	_seed(ops, SLOT, states[0])
	ops.corrupt_writes["write:%s:1" % TMP] = _bad()
	var result := _store(states[0], ops).save(states[0].encode_save()["text"], states[1])
	assert_eq(result["status"], &"retryable")
	assert_eq(result["error_code"], &"store_validate_failed")


func test_save_promote_failure_restores_exact_main_and_retryable() -> void:
	var states := _states()
	var ops := FaultOps.new()
	_seed(ops, SLOT, states[0])
	ops.failures["rename:%s->%s:1" % [TMP, SLOT]] = true
	var result := _store(states[0], ops).save(states[0].encode_save()["text"], states[1])
	assert_eq(result["status"], &"retryable")
	assert_eq(result["error_code"], &"store_promote_failed")
	assert_eq((ops.files[SLOT] as PackedByteArray).get_string_from_utf8(),
		states[0].encode_save()["text"])


func test_save_post_promotion_corruption_rolls_back_exact_main() -> void:
	var states := _states()
	var ops := FaultOps.new()
	_seed(ops, SLOT, states[0])
	ops.corrupt_reads["read:%s:2" % SLOT] = _bad()
	var result := _store(states[0], ops).save(states[0].encode_save()["text"], states[1])
	assert_eq(result["status"], &"retryable")
	assert_eq(result["error_code"], &"store_validate_failed")
	assert_eq((ops.files[SLOT] as PackedByteArray).get_string_from_utf8(),
		states[0].encode_save()["text"])


func _assert_exact_load_matrix_and_recovered_winner_saves() -> void:
	var states := _states()
	var fresh := states[0]
	var paid := states[1]
	var begun := states[2]
	var renamed := _commit_state(
		fresh.rename_hero(_ready_ids(fresh)[0], "Nova"), fresh,
	)
	var bad := _bad()
	var cases := [
		["empty", {}, false, &"slot_missing", &"none", ""],
		["main", {SLOT: fresh}, true, &"", &"main", SLOT],
		["main_bak", {SLOT: paid, BAK: fresh}, true, &"", &"main", SLOT],
		["main_tmp", {SLOT: paid, TMP: begun}, true, &"", &"main", SLOT],
		["main_bak_tmp", {SLOT: paid, BAK: fresh, TMP: begun}, true, &"", &"main", SLOT],
		[
			"main_equal_divergent_sidecars",
			{SLOT: fresh, BAK: paid, TMP: renamed}, true, &"", &"main", SLOT,
		],
		["bak", {BAK: paid}, true, &"", &"bak", BAK],
		["tmp", {TMP: begun}, true, &"", &"tmp", TMP],
		["bak_tmp", {BAK: paid, TMP: begun}, true, &"", &"bak", BAK],
		["corrupt_main_bak", {SLOT: bad, BAK: paid}, true, &"", &"bak", BAK],
		["corrupt_main_tmp", {SLOT: bad, TMP: begun}, true, &"", &"tmp", TMP],
		[
			"all_invalid", {SLOT: bad, BAK: bad, TMP: bad},
			false, &"slot_corrupt", &"none", "",
		],
		[
			"equal_version_divergence", {BAK: paid, TMP: renamed},
			false, &"slot_corrupt", &"none", "",
		],
		[
			"tmp_not_newer_than_invalid_header",
			{SLOT: _corrupt_checksum(begun.encode_save()["text"]), TMP: paid},
			false, &"slot_corrupt", &"none", "",
		],
		[
			"tmp_same_generation_higher_revision",
			{SLOT: _corrupt_checksum(fresh.encode_save()["text"]), TMP: paid},
			true, &"", &"tmp", TMP,
		],
		[
			"tmp_same_generation_lower_than_invalid_bak",
			{BAK: _corrupt_checksum(begun.encode_save()["text"]), TMP: paid},
			false, &"slot_corrupt", &"none", "",
		],
		[
			"invalid_main_invalid_bak_newer_tmp",
			{
				SLOT: _corrupt_checksum(fresh.encode_save()["text"]),
				BAK: _corrupt_checksum(fresh.encode_save()["text"]),
				TMP: paid,
			}, true, &"", &"tmp", TMP,
		],
	]
	var projections: Array[String] = []
	for row: Array in cases:
		_assert_matrix_row(row, projections)
	assert_eq(projections.size(), 17)
	_assert_save_from_bak_winner(paid)
	_assert_save_from_tmp_winner(paid)


func _assert_matrix_row(row: Array, projections: Array[String]) -> void:
	var layout := _layout_bytes(row[1])
	var ops := FaultOps.new()
	ops.files = layout.duplicate(true)
	var result := _store(_fresh(), ops).load()
	assert_eq(result["accepted"], row[2], row[0])
	assert_eq(result["error_code"], row[3], row[0])
	assert_eq(result["source"], row[4], row[0])
	projections.append("%s:%s:%s" % [row[0], row[3], row[4]])
	if row[2]:
		assert_eq(ops.files.keys(), [SLOT], row[0])
		assert_eq(ops.files[SLOT], layout[row[5]], row[0])
	else:
		assert_eq(ops.files, layout, row[0])
	for path: String in layout:
		var fault_ops := FaultOps.new()
		fault_ops.files = layout.duplicate(true)
		fault_ops.failures["read:%s:1" % path] = true
		var before: Dictionary = fault_ops.files.duplicate(true)
		var failed := _store(_fresh(), fault_ops).load()
		assert_false(failed["accepted"], "%s:%s" % [row[0], path])
		assert_eq(failed["error_code"], &"store_read_failed")
		assert_eq(fault_ops.files, before)


func _assert_save_from_bak_winner(pre_state: CampaignState) -> void:
	var ops := FaultOps.new()
	ops.files[SLOT] = _bad()
	_seed(ops, BAK, pre_state)
	ops.failures["rename:%s->%s:1" % [BAK, SLOT]] = true
	var store := _store(pre_state, ops)
	assert_eq(store.load()["source"], &"bak")
	var next: Dictionary = pre_state.rename_hero(_ready_ids(pre_state)[0], "Aegis")
	ops.failures["read:%s:2" % SLOT] = true
	var prospective: CampaignState = next["payload"]["mutation"]._prospective_state
	var saved := store.save(pre_state._validated_save_text(), prospective)
	assert_eq(saved["status"], &"retryable")
	assert_eq(saved["error_code"], &"store_read_failed")
	assert_eq((ops.files[SLOT] as PackedByteArray), pre_state.encode_save()["bytes"])


func _assert_save_from_tmp_winner(pre_state: CampaignState) -> void:
	var ops := FaultOps.new()
	ops.files[SLOT] = _bad()
	_seed(ops, TMP, pre_state)
	ops.failures["rename:%s->%s:1" % [TMP, SLOT]] = true
	var store := _store(pre_state, ops)
	assert_eq(store.load()["source"], &"tmp")
	var next: Dictionary = pre_state.rename_hero(_ready_ids(pre_state)[0], "Aegis")
	ops.partial_write_failures["write:%s:1" % TMP] = true
	var prospective: CampaignState = next["payload"]["mutation"]._prospective_state
	var saved := store.save(pre_state._validated_save_text(), prospective)
	assert_eq(saved["status"], &"retryable")
	assert_eq(saved["error_code"], &"store_write_failed")
	assert_eq((ops.files[SLOT] as PackedByteArray), pre_state.encode_save()["bytes"])


func _assert_complete_store_contract() -> void:
	_assert_exact_load_matrix_and_recovered_winner_saves()
	_assert_full_save_fault_matrix()
	_assert_load_cleanup_faults()


func _assert_full_save_fault_matrix() -> void:
	var states := _states()
	var before: CampaignState = states[0]
	var prospective: CampaignState = states[1]
	var cases := [
		["write:%s:1" % TMP, &"store_write_failed", &"retryable"],
		["read:%s:1" % TMP, &"store_read_failed", &"retryable"],
		["remove:%s:1" % BAK, &"store_cleanup_failed", &"retryable"],
		["rename:%s->%s:1" % [SLOT, BAK], &"store_rotate_failed", &"retryable"],
		["rename:%s->%s:1" % [TMP, SLOT], &"store_promote_failed", &"retryable"],
		["read:%s:2" % SLOT, &"store_read_failed", &"retryable"],
		["remove:%s:2" % BAK, &"", &"committed"],
	]
	for row: Array in cases:
		var ops := FaultOps.new()
		_seed(ops, SLOT, before)
		if String(row[0]).begins_with("remove:%s:1" % BAK):
			_seed(ops, BAK, before)
		ops.failures[String(row[0])] = true
		var result := _store(before, ops).save(
			before._validated_save_text(), prospective,
		)
		assert_eq(result["status"], row[2], row[0])
		assert_eq(result["error_code"], row[1], row[0])
		if row[2] == &"committed":
			assert_eq(ops.files[SLOT], prospective.encode_save()["bytes"], row[0])
		else:
			assert_true(
				ops.files.get(SLOT, PackedByteArray()) == before.encode_save()["bytes"]
				or ops.files.get(BAK, PackedByteArray()) == before.encode_save()["bytes"],
				row[0],
			)
	_assert_restore_failure_override(before, prospective)
	_assert_reclassification_read_failure(before, prospective)


func _assert_restore_failure_override(
	before: CampaignState,
	prospective: CampaignState,
) -> void:
	var ops := FaultOps.new()
	_seed(ops, SLOT, before)
	ops.failures["rename:%s->%s:1" % [TMP, SLOT]] = true
	ops.failures["rename:%s->%s:1" % [BAK, SLOT]] = true
	ops.failures["rename:%s->%s:2" % [BAK, SLOT]] = true
	var result := _store(before, ops).save(before._validated_save_text(), prospective)
	assert_eq(result["status"], &"retryable")
	assert_eq(result["error_code"], &"store_restore_failed")
	assert_eq(ops.files[BAK], before.encode_save()["bytes"])


func _assert_reclassification_read_failure(
	before: CampaignState,
	prospective: CampaignState,
) -> void:
	var ops := FaultOps.new()
	_seed(ops, SLOT, before)
	ops.failures["write:%s:1" % TMP] = true
	ops.failures["read:%s:2" % SLOT] = true
	var result := _store(before, ops).save(before._validated_save_text(), prospective)
	assert_eq(result["status"], &"indeterminate")
	assert_eq(result["error_code"], &"store_integrity_failure")
	assert_eq(ops.files[SLOT], before.encode_save()["bytes"])


func _assert_load_cleanup_faults() -> void:
	var states := _states()
	var rows := [
		[{SLOT: states[0], BAK: states[1], TMP: states[2]}, "remove:%s:1" % BAK, &"main"],
		[{SLOT: states[0], BAK: states[1], TMP: states[2]}, "remove:%s:1" % TMP, &"main"],
		[{BAK: states[1]}, "rename:%s->%s:1" % [BAK, SLOT], &"bak"],
		[{TMP: states[2]}, "rename:%s->%s:1" % [TMP, SLOT], &"tmp"],
	]
	for row: Array in rows:
		var ops := FaultOps.new()
		for path: String in row[0]:
			_seed(ops, path, row[0][path])
		ops.failures[row[1]] = true
		var store := _store(states[0], ops)
		var first := store.load()
		assert_true(first["accepted"], row[1])
		assert_eq(first["source"], row[2], row[1])
		var repeat := store.load()
		assert_true(repeat["accepted"], row[1])
		assert_eq(repeat["state"].encode_save()["text"], first["state"].encode_save()["text"])


func _layout_bytes(layout: Dictionary) -> Dictionary:
	var result := {}
	for path: String in layout:
		var value: Variant = layout[path]
		result[path] = (
			value.encode_save()["bytes"].duplicate()
			if value is CampaignState
			else (value as PackedByteArray).duplicate()
		)
	return result


func _assert_load_layout(layout: Dictionary, source: StringName, revision: int) -> void:
	var bytes := {}
	for path: String in layout:
		bytes[path] = (layout[path] as CampaignState).encode_save()["bytes"]
	_assert_load_bytes(bytes, source, revision)


func _assert_load_bytes(layout: Dictionary, source: StringName, revision: int) -> void:
	var result := _load_bytes(layout)
	assert_true(result["accepted"], str(result.get("error_code", &"")))
	assert_eq(result["source"], source)
	assert_eq((result["state"] as CampaignState).save_revision(), revision)


func _load_bytes(layout: Dictionary) -> Dictionary:
	var ops := FaultOps.new()
	for path: String in layout:
		ops.files[path] = (layout[path] as PackedByteArray).duplicate()
	return _store(_fresh(), ops).load()


func _states() -> Array[CampaignState]:
	var fresh := _fresh()
	var paid := _commit_state(fresh.recruit("p16_caster_contract"), fresh)
	var begun := _commit_state(paid.begin_attempt(&"s1", [_ready_ids(paid)[0]]), paid)
	var pending: CampaignPendingAttempt = begun.pending_attempt()
	var outcome := _outcome(pending.ticket())
	var resolved := _commit_state(begun.resolve_attempt(pending.ticket(), outcome, pending), begun)
	return [fresh, paid, begun, resolved]


func _commit_state(command: Dictionary, before: CampaignState) -> CampaignState:
	_cleanup_production_slot()
	var created := CampaignSaveStore.create_production(before)
	assert_true(created["accepted"])
	var store: CampaignSaveStore = created["value"]
	var file := FileAccess.open(CampaignSaveStore.PRODUCTION_SLOT, FileAccess.WRITE)
	assert_not_null(file)
	file.store_buffer(before.encode_save()["bytes"])
	file.close()
	var result := (command["payload"]["mutation"] as CampaignMutation).retry_save(store)
	assert_true(result["accepted"], str(result.get("error_code", &"")))
	assert_ne(result["payload"]["state"], command["payload"]["mutation"]._prospective_state)
	var state: CampaignState = result["payload"]["state"]
	_cleanup_production_slot()
	return state


func _cleanup_production_slot() -> void:
	for path: String in [
		CampaignSaveStore.PRODUCTION_SLOT,
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".tmp",
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".bak",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _outcome(ticket: CampaignBattleTicket) -> BattleOutcome:
	var heroes: Array[Dictionary] = []
	for row: Dictionary in ticket.manifest():
		heroes.append({
			"hero_id": row["battle_id"],
			"operator_def_id": row["operator_def_id"],
			"deployments": 1,
			"retreats": 0,
			"fell": false,
			"first_fall_tick": null,
		})
	var data := {
		"schema_version": 1,
		"campaign_uid": ticket.campaign_uid(),
		"attempt_id": ticket.attempt_id(),
		"stage_id": String(ticket.stage_id()),
		"manifest_hash": ticket.manifest_hash(),
		"result": "defeat",
		"terminal_reason": "base_defeat",
		"stars": 0,
		"terminal_tick": 120,
		"model_state_hash": "0000000000000000",
		"heroes": heroes,
	}
	data["outcome_hash"] = CanonicalJson.sha256_hex(data)
	var result := BattleOutcome.from_data(data)
	return result["value"]


func _store(state: CampaignState, ops: FaultOps) -> CampaignSaveStore:
	var result := CampaignSaveStore.create(SLOT, state.restore_factory(), ops)
	assert_true(result["accepted"])
	return result["value"]


func _seed(ops: FaultOps, path: String, state: CampaignState) -> void:
	ops.files[path] = state.encode_save()["bytes"].duplicate()


func _corrupt_checksum(source: String) -> PackedByteArray:
	var parser := JSON.new()
	assert_eq(parser.parse(source), OK)
	var exact := CanonicalJson.restore_exact_integers(source, parser.data)
	var root: Dictionary = exact["value"]
	root["checksum"] = "0".repeat(64)
	return CanonicalJson.text(root).to_utf8_buffer()


func _bad() -> PackedByteArray:
	return "bad".to_utf8_buffer()


func _fresh() -> CampaignState:
	return _fresh_generation(1)


func _fresh_generation(generation: int) -> CampaignState:
	var created := CampaignState.create(42, generation, _definition(), _catalogs(), _stages())
	assert_true(created["accepted"])
	return created["value"]


func _ready_ids(state: CampaignState) -> Array[String]:
	var values: Array[String] = []
	for hero: HeroState in state.roster().ready():
		values.append(hero.hero_id())
	return values


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
