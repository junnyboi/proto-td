extends GutTest

const ContextScript := preload("res://test/fixtures/p16/campaign_v3_context.gd")
const SLOT := "user://p16-v3-store.json"
const TMP := "user://p16-v3-store.tmp"
const BAK := "user://p16-v3-store.bak"


class FaultOps:
	extends CampaignFileOps
	var files := {}
	var failures := {}
	var corrupt_reads := {}
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
		var bytes: PackedByteArray = corrupt_reads.get(_key("read", path, ordinal), files[path])
		return {"accepted": true, "error_code": &"", "bytes": bytes.duplicate()}

	func write_bytes(path: String, bytes: PackedByteArray) -> Dictionary:
		var ordinal := _ordinal("write", path)
		if partial_write_failures.has(_key("write", path, ordinal)):
			files[path] = bytes.slice(0, mini(7, bytes.size()))
			return {"accepted": false, "error_code": &"injected"}
		if failures.has(_key("write", path, ordinal)):
			return {"accepted": false, "error_code": &"injected"}
		files[path] = bytes.duplicate()
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


func test_v3_save_fault_matrix_preserves_old_authority_or_commits_exact_new_bytes() -> void:
	var states := _states()
	var before: CampaignStateV3 = states[0]
	var prospective: CampaignStateV3 = states[1]
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
		var result := _store(before, ops).save(before._validated_save_text(), prospective)
		assert_eq(result["status"], row[2], row[0])
		assert_eq(result["error_code"], row[1], row[0])
		if row[2] == &"committed":
			assert_eq(ops.files[SLOT], prospective.encode_save()["bytes"], row[0])
		else:
			assert_true(
				(
					ops.files.get(SLOT, PackedByteArray()) == before.encode_save()["bytes"]
					or ops.files.get(BAK, PackedByteArray()) == before.encode_save()["bytes"]
				),
				row[0],
			)


func test_v3_post_promotion_corruption_rolls_back_exact_preimage() -> void:
	var states := _states()
	var before: CampaignStateV3 = states[0]
	var prospective: CampaignStateV3 = states[1]
	var ops := FaultOps.new()
	_seed(ops, SLOT, before)
	ops.corrupt_reads["read:%s:2" % SLOT] = "bad".to_utf8_buffer()
	var result := _store(before, ops).save(before._validated_save_text(), prospective)
	assert_eq(result["status"], &"retryable")
	assert_eq(result["error_code"], &"store_validate_failed")
	assert_eq(ops.files[SLOT], before.encode_save()["bytes"])


func test_v3_partial_tmp_and_restore_failure_preserve_a_valid_old_winner() -> void:
	var states := _states()
	var before: CampaignStateV3 = states[0]
	var prospective: CampaignStateV3 = states[1]
	var partial := FaultOps.new()
	_seed(partial, SLOT, before)
	partial.partial_write_failures["write:%s:1" % TMP] = true
	var partial_result := (
		_store(before, partial)
		. save(
			before._validated_save_text(),
			prospective,
		)
	)
	assert_eq(partial_result["status"], &"retryable")
	assert_eq(partial_result["error_code"], &"store_write_failed")
	assert_eq(partial.files[SLOT], before.encode_save()["bytes"])
	var restore_failure := FaultOps.new()
	_seed(restore_failure, SLOT, before)
	restore_failure.failures["rename:%s->%s:1" % [TMP, SLOT]] = true
	restore_failure.failures["rename:%s->%s:1" % [BAK, SLOT]] = true
	restore_failure.failures["rename:%s->%s:2" % [BAK, SLOT]] = true
	var restore_result := (
		_store(before, restore_failure)
		. save(
			before._validated_save_text(),
			prospective,
		)
	)
	assert_eq(restore_result["status"], &"retryable")
	assert_eq(restore_result["error_code"], &"store_restore_failed")
	assert_eq(restore_failure.files[BAK], before.encode_save()["bytes"])
	assert_eq(before.save_revision(), 1)
	assert_eq(before.encode_save()["text"], states[0].encode_save()["text"])


func test_v3_equal_revision_divergence_blocks_and_bak_recovery_is_exact() -> void:
	var before := _fresh()
	var hero_id: String = before.data_copy()["heroes"][0]["hero_id"]
	var left := _prospective(before.begin_attempt("left", "s1", [hero_id], 41, 1))
	var right := _prospective(before.begin_attempt("right", "s1", [hero_id], 42, 1))
	var divergent := FaultOps.new()
	_seed(divergent, BAK, left)
	_seed(divergent, TMP, right)
	var blocked := _store(before, divergent).load()
	assert_false(blocked["accepted"])
	assert_eq(blocked["error_code"], &"slot_corrupt")
	var recoverable := FaultOps.new()
	recoverable.files[SLOT] = "bad".to_utf8_buffer()
	_seed(recoverable, BAK, left)
	var restored := _store(before, recoverable).load()
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	assert_eq(restored["source"], &"bak")
	assert_eq(
		(restored["state"] as CampaignStateV3).encode_save()["text"], left.encode_save()["text"]
	)
	assert_eq(recoverable.files.keys(), [SLOT])


func _states() -> Array[CampaignStateV3]:
	var before := _fresh()
	var hero_id: String = before.data_copy()["heroes"][0]["hero_id"]
	return [before, _prospective(before.begin_attempt("begin", "s1", [hero_id], 42, 1))]


func _prospective(command: Dictionary) -> CampaignStateV3:
	assert_true(command["accepted"], str(command.get("error_code", &"")))
	return (command["payload"]["mutation"] as CampaignMutation)._prospective_state


func _fresh() -> CampaignStateV3:
	var created := CampaignStateV3.create(42, 1, ContextScript.build())
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	return created["value"]


func _store(state: CampaignStateV3, ops: FaultOps) -> CampaignSaveStore:
	var created := CampaignSaveStore.create(SLOT, state.restore_factory(), ops)
	assert_true(created["accepted"])
	return created["value"]


func _seed(ops: FaultOps, path: String, state: CampaignStateV3) -> void:
	ops.files[path] = state.encode_save()["bytes"].duplicate()
