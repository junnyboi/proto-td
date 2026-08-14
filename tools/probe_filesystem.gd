extends SceneTree

const ContextScript := preload("res://test/fixtures/p16/campaign_v3_context.gd")
const ROOT := "user://p16_filesystem_probe"
const MAIN := ROOT + "/main"
const TMP := ROOT + "/tmp"
const BAK := ROOT + "/bak"
const V3_SLOT := ROOT + "/campaign.json"
const V3_TMP := ROOT + "/campaign.tmp"
const V3_BAK := ROOT + "/campaign.bak"
const MAGIC := "P16FS1"

var _failures: Array[String] = []
var _checks := 0
var _case_ids: Array[String] = []


func _initialize() -> void:
	var requested := "all"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--case="):
			requested = arg.trim_prefix("--case=")
		else:
			_failures.append("unknown argument: %s" % arg)
	if requested != "all":
		_failures.append("unsupported case: %s" % requested)
	if _failures.is_empty():
		_run_all()
	_cleanup()
	_check(
		not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(ROOT)),
		"final probe root cleanup completed",
	)
	var result := {}
	result["id"] = "filesystem"
	result["engine_version"] = Engine.get_version_info()["string"]
	result["platform"] = OS.get_name()
	result["headless"] = DisplayServer.get_name() == "headless"
	result["web"] = OS.has_feature("web")
	result["user_root"] = ProjectSettings.globalize_path(ROOT)
	result["checks"] = _checks
	result["case_count"] = _case_ids.size()
	result["case_ids"] = _case_ids
	result["mandatory_failures"] = _failures
	result["verdict"] = "pass" if _failures.is_empty() else "fail"
	print("P16_FILESYSTEM_RESULT=" + CanonicalJson.text(result).strip_edges())
	quit(0 if _failures.is_empty() else 1)


func _run_all() -> void:
	_check(OS.get_name() == "Linux", "probe acceptance platform is Linux")
	_check(DisplayServer.get_name() == "headless", "probe runs headless")
	_check(not OS.has_feature("web"), "native probe is not Web")
	_cleanup()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
	_test_write_and_truncate()
	_test_rename_replace_delete()
	_test_failed_promotion_restores_backup()
	_test_recovery_matrix()
	_test_v3_store_round_trip()


func _test_v3_store_round_trip() -> void:
	_case_ids.append("v3_store_round_trip")
	var created := CampaignStateV3.create(42, 1, ContextScript.build())
	_check(created["accepted"], "v3 fresh authority creates")
	if not created["accepted"]:
		return
	var state: CampaignStateV3 = created["value"]
	var store_result := CampaignSaveStore.create(
		V3_SLOT, state.restore_factory(), CampaignFileOps.new(),
	)
	_check(store_result["accepted"], "v3 store creates")
	_check(_write(V3_SLOT, state.encode_save()["text"]), "v3 seed writes")
	var hero_id: String = state.data_copy()["heroes"][0]["hero_id"]
	var command := state.begin_attempt("filesystem-v3", "s1", [hero_id], 42, 1)
	_check(command["accepted"], "v3 begin command creates prospective authority")
	if not command["accepted"]:
		return
	var prospective: CampaignStateV3 = (
		(command["payload"]["mutation"] as CampaignMutation)._prospective_state
	)
	var store: CampaignSaveStore = store_result["value"]
	var saved := store.save(state._validated_save_text(), prospective)
	_check(saved["status"] == &"committed", "v3 save commits")
	_check(_read(V3_SLOT) == prospective.encode_save()["text"], "v3 save bytes exact")
	var reopened := CampaignSaveStore.create(
		V3_SLOT, state.restore_factory(), CampaignFileOps.new(),
	)
	_check(reopened["accepted"], "v3 store reopens after process boundary")
	var loaded := (reopened["value"] as CampaignSaveStore).load()
	_check(loaded["accepted"], "v3 store reloads")
	if loaded["accepted"]:
		var restored: CampaignStateV3 = loaded["state"]
		_check(restored.save_revision() == 2, "v3 revision survives reload")
		_check(
			restored.encode_save()["text"] == prospective.encode_save()["text"],
			"v3 canonical save survives reload",
		)
		_check(restored.data_copy()["command_receipts"].size() == 1,
			"v3 command ledger survives")
	_cleanup_v3_files()
	_check(not FileAccess.file_exists(V3_SLOT), "v3 storage cleanup completes")


func _test_write_and_truncate() -> void:
	var long := _envelope(1, "generation-one-payload-with-trailing-data")
	var short := _envelope(2, "g2")
	_check(_write(MAIN, long), "write generation one")
	_check(_read(MAIN) == long, "read generation one exactly")
	_check(_write(MAIN, short), "rewrite main in truncate mode")
	_check(_read(MAIN) == short, "rewrite removes old trailing bytes")
	_check(_candidate(MAIN)["valid"], "rewritten main validates")
	_cleanup_files()


func _test_rename_replace_delete() -> void:
	var old_main := _envelope(10, "old-main")
	var old_bak := _envelope(9, "stale-bak")
	var new_main := _envelope(11, "new-main")
	_check(_write(MAIN, old_main), "replacement writes old main")
	_check(_write(BAK, old_bak), "replacement writes stale bak")
	_check(_write(TMP, new_main), "replacement writes tmp")
	_check(_candidate(TMP)["valid"], "replacement validates tmp before rotation")
	_check(_remove(BAK) == OK, "replacement deletes stale bak")
	_check(_rename(MAIN, BAK) == OK, "replacement rotates main to bak")
	_check(_read(BAK) == old_main, "backup retains old main bytes")
	_check(_rename(TMP, MAIN) == OK, "replacement promotes tmp")
	_check(_read(MAIN) == new_main, "promoted main has new bytes")
	_check(_candidate(MAIN)["valid"], "promoted main validates")
	_check(_remove(BAK) == OK, "validated main permits backup cleanup")
	_check(not FileAccess.file_exists(BAK), "backup deleted after commit")
	_check(_remove(MAIN) == OK, "existing main deletion succeeds")
	_check(_remove(MAIN) != OK, "missing main deletion rejects")
	_cleanup_files()


func _test_failed_promotion_restores_backup() -> void:
	var old_main := _envelope(50, "committed-main")
	var new_main := _envelope(51, "prospective-main")
	_check(_write(MAIN, old_main), "rollback fixture writes committed main")
	_check(_write(TMP, new_main), "rollback fixture writes prospective tmp")
	_check(not _commit_tmp(true), "injected post-rotation failure rejects")
	_check(_read(MAIN) == old_main, "post-rotation failure restores committed main")
	_check(_candidate(MAIN)["valid"], "restored committed main validates")
	_cleanup_files()
	_check(_write(MAIN, old_main), "validation fixture writes committed main")
	_check(_write(TMP, new_main), "validation fixture writes prospective tmp")
	_check(not _commit_tmp(false, true), "injected promoted-main validation failure rejects")
	_check(_read(MAIN) == old_main, "validation failure restores committed main")
	_check(_candidate(MAIN)["valid"], "validation rollback main validates")
	_cleanup_files()


func _commit_tmp(inject_after_rotation: bool, inject_invalid_main: bool = false) -> bool:
	var accepted: bool = _candidate(TMP)["valid"]
	var rotated := false
	if accepted and FileAccess.file_exists(BAK):
		accepted = _remove(BAK) == OK
	if accepted and FileAccess.file_exists(MAIN):
		accepted = _rename(MAIN, BAK) == OK
		rotated = accepted
	if accepted:
		accepted = not inject_after_rotation and _rename(TMP, MAIN) == OK
	if accepted and inject_invalid_main:
		accepted = _write(MAIN, "invalid-promoted-main")
	if accepted:
		accepted = bool(_candidate(MAIN)["valid"])
	if not accepted and rotated:
		_check(_restore_backup(), "failed commit restores backup without filesystem errors")
	if accepted and FileAccess.file_exists(BAK):
		accepted = _remove(BAK) == OK
	return accepted


func _restore_backup() -> bool:
	var restored := true
	if FileAccess.file_exists(BAK):
		if FileAccess.file_exists(MAIN):
			restored = _remove(MAIN) == OK
		if restored:
			restored = _rename(BAK, MAIN) == OK
	return restored


func _test_recovery_matrix() -> void:
	_recovery_case("empty", {}, "none", -1)
	_recovery_case("main", {MAIN: _envelope(20, "main")}, "main", 20)
	_recovery_case(
		"main_bak",
		{MAIN: _envelope(20, "main"), BAK: _envelope(19, "bak")},
		"main",
		20,
	)
	_recovery_case(
		"main_tmp",
		{MAIN: _envelope(20, "main"), TMP: _envelope(21, "tmp")},
		"main",
		20,
	)
	_recovery_case(
		"main_bak_tmp",
		{MAIN: _envelope(20, "main"), BAK: _envelope(19, "bak"), TMP: _envelope(21, "tmp")},
		"main",
		20,
	)
	_recovery_case(
		"main_equal_divergent_sidecars",
		{
			MAIN: _envelope(25, "main", 5),
			BAK: _envelope(25, "bak", 5),
			TMP: _envelope(25, "tmp", 5),
		},
		"main",
		25,
	)
	_recovery_case("bak", {BAK: _envelope(19, "bak")}, "bak", 19)
	_recovery_case("tmp", {TMP: _envelope(21, "tmp")}, "tmp", 21)
	_recovery_case(
		"bak_tmp",
		{BAK: _envelope(19, "bak"), TMP: _envelope(21, "tmp")},
		"bak",
		19,
	)
	_recovery_case(
		"corrupt_main_bak",
		{MAIN: "{broken", BAK: _envelope(19, "bak")},
		"bak",
		19,
	)
	_recovery_case(
		"corrupt_main_tmp",
		{MAIN: "{broken", TMP: _envelope(21, "tmp")},
		"tmp",
		21,
	)
	_recovery_case(
		"all_invalid",
		{MAIN: "bad-main", BAK: "bad-bak", TMP: "bad-tmp"},
		"none",
		-1,
		false,
	)
	_recovery_case(
		"equal_version_divergence",
		{BAK: _envelope(30, "bak", 4), TMP: _envelope(30, "tmp", 4)},
		"none",
		-1,
		false,
	)
	var corrupt_newer := _envelope(40, "newer-corrupt", 8).replace(
		CanonicalJson.sha256_text("newer-corrupt"),
		"0000000000000000000000000000000000000000000000000000000000000000",
	)
	_recovery_case(
		"tmp_not_newer_than_invalid_header",
		{MAIN: corrupt_newer, TMP: _envelope(39, "older-tmp", 9)},
		"none",
		-1,
		false,
	)
	_recovery_case(
		"tmp_same_generation_higher_revision",
		{MAIN: _invalid_envelope(40, "bad-main", 8), TMP: _envelope(40, "tmp", 9)},
		"tmp",
		40,
	)
	_recovery_case(
		"tmp_same_generation_lower_than_invalid_bak",
		{BAK: _invalid_envelope(40, "bad-bak", 10), TMP: _envelope(40, "tmp", 9)},
		"none",
		-1,
		false,
	)
	_recovery_case(
		"invalid_main_invalid_bak_newer_tmp",
		{
			MAIN: _invalid_envelope(40, "bad-main", 8),
			BAK: _invalid_envelope(39, "bad-bak", 9),
			TMP: _envelope(40, "tmp", 8),
		},
		"tmp",
		40,
	)


func _recovery_case(
	tag: String,
	layout: Dictionary,
	expected_source: String,
	expected_generation: int,
	expect_valid_main: bool = true,
) -> void:
	_case_ids.append(tag)
	_cleanup_files()
	for path: String in layout:
		_check(_write(path, String(layout[path])), "%s fixture write %s" % [tag, path.get_file()])
	var before := _snapshot()
	var source := _recover()
	_check(source == expected_source, "%s recovery source=%s" % [tag, expected_source])
	if expect_valid_main and expected_source != "none":
		var candidate := _candidate(MAIN)
		_check(bool(candidate["valid"]), "%s recovered main validates" % tag)
		_check(int(candidate["generation"]) == expected_generation, "%s generation" % tag)
		var source_path: String = {"main": MAIN, "bak": BAK, "tmp": TMP}[expected_source]
		_check(_read(MAIN) == layout[source_path], "%s recovered bytes" % tag)
		_check(not FileAccess.file_exists(TMP), "%s tmp cleaned" % tag)
		_check(not FileAccess.file_exists(BAK), "%s backup cleaned after load" % tag)
	else:
		_check(_snapshot() == before, "%s preserves invalid evidence" % tag)
	_cleanup_files()


func _recover() -> String:
	var main := _candidate(MAIN)
	var backup := _candidate(BAK)
	var temporary := _candidate(TMP)
	var result := "none"
	if main["valid"]:
		var cleanup_ok := true
		if FileAccess.file_exists(TMP):
			cleanup_ok = _remove(TMP) == OK
		if FileAccess.file_exists(BAK):
			cleanup_ok = _remove(BAK) == OK and cleanup_ok
		result = "main" if cleanup_ok else "none"
	elif backup["valid"] and temporary["valid"]:
		if _same_version(backup, temporary) and backup["bytes"] != temporary["bytes"]:
			result = "none"
		else:
			result = _promote(BAK, "bak", true)
	elif backup["valid"]:
		result = _promote(BAK, "bak", true)
	elif temporary["valid"]:
		var blocked: bool = (
			main["header_valid"] and not _at_least(temporary, main)
			or backup["header_valid"] and not _at_least(temporary, backup)
		)
		if not blocked and FileAccess.file_exists(BAK):
			blocked = _remove(BAK) != OK
		if not blocked:
			result = _promote(TMP, "tmp", false)
	return result


func _promote(path: String, label: String, remove_tmp_after: bool) -> String:
	if FileAccess.file_exists(MAIN) and _remove(MAIN) != OK:
		return "none"
	if _rename(path, MAIN) != OK or not _candidate(MAIN)["valid"]:
		return "none"
	if remove_tmp_after and FileAccess.file_exists(TMP) and _remove(TMP) != OK:
		return "none"
	return label


func _envelope(generation: int, payload: String, revision: int = -1) -> String:
	if revision < 0:
		revision = generation
	var value := {}
	value["magic"] = MAGIC
	value["generation"] = generation
	value["revision"] = revision
	value["payload"] = payload
	value["payload_sha256"] = CanonicalJson.sha256_text(payload)
	return CanonicalJson.text(value)


func _invalid_envelope(generation: int, payload: String, revision: int) -> String:
	return _envelope(generation, payload, revision).replace(
		CanonicalJson.sha256_text(payload),
		"0000000000000000000000000000000000000000000000000000000000000000",
	)


func _candidate(path: String) -> Dictionary:
	var result := {
		"valid": false,
		"header_valid": false,
		"generation": -1,
		"revision": -1,
		"bytes": "",
	}
	if FileAccess.file_exists(path):
		result["bytes"] = _read(path)
		var parser := JSON.new()
		var parse_error := parser.parse(result["bytes"])
		var parsed: Variant = parser.data if parse_error == OK else null
		var expected := ["magic", "generation", "revision", "payload", "payload_sha256"]
		var schema_ok: bool = (
			typeof(parsed) == TYPE_DICTIONARY and parsed.size() == expected.size()
		)
		if schema_ok:
			for key: String in expected:
				schema_ok = schema_ok and parsed.has(key)
		if schema_ok:
			var typed: bool = (
				parsed["magic"] == MAGIC
				and _is_integer(parsed["generation"])
				and _is_integer(parsed["revision"])
				and typeof(parsed["payload"]) == TYPE_STRING
				and typeof(parsed["payload_sha256"]) == TYPE_STRING
			)
			if typed:
				parsed["generation"] = int(parsed["generation"])
				parsed["revision"] = int(parsed["revision"])
				result["generation"] = int(parsed["generation"])
				result["revision"] = int(parsed["revision"])
				result["header_valid"] = (
					int(parsed["generation"]) >= 1 and int(parsed["revision"]) >= 1
				)
				result["valid"] = (
					result["header_valid"]
					and result["bytes"] == CanonicalJson.text(parsed)
					and CanonicalJson.sha256_text(parsed["payload"])
					== parsed["payload_sha256"]
				)
	return result


func _at_least(a: Dictionary, b: Dictionary) -> bool:
	return (
		int(a["generation"]) > int(b["generation"])
		or (
			int(a["generation"]) == int(b["generation"])
			and int(a["revision"]) >= int(b["revision"])
		)
	)


func _same_version(a: Dictionary, b: Dictionary) -> bool:
	return a["generation"] == b["generation"] and a["revision"] == b["revision"]


func _write(path: String, source: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var stored := file.store_buffer(source.to_utf8_buffer())
	file.flush()
	var error := file.get_error()
	file.close()
	return stored and error == OK


func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var bytes := file.get_buffer(file.get_length())
	file.close()
	return bytes.get_string_from_utf8()


func _rename(from_path: String, to_path: String) -> Error:
	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(from_path),
		ProjectSettings.globalize_path(to_path),
	)


func _remove(path: String) -> Error:
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _snapshot() -> Dictionary:
	var snapshot := {}
	for path: String in [MAIN, TMP, BAK]:
		if FileAccess.file_exists(path):
			snapshot[path.get_file()] = _read(path)
	return snapshot


func _cleanup_files() -> void:
	for path: String in [MAIN, TMP, BAK]:
		if FileAccess.file_exists(path):
			_remove(path)
	_cleanup_v3_files()


func _cleanup_v3_files() -> void:
	for path: String in [V3_SLOT, V3_TMP, V3_BAK]:
		if FileAccess.file_exists(path):
			_remove(path)


func _cleanup() -> void:
	_cleanup_files()
	var absolute := ProjectSettings.globalize_path(ROOT)
	if DirAccess.dir_exists_absolute(absolute):
		DirAccess.remove_absolute(absolute)


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(message)


func _is_integer(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT:
		return false
	var number := float(value)
	return is_finite(number) and number == floor(number)
