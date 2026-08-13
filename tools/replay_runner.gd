extends SceneTree

const DEFAULT_FIXTURES := "res://playtests/replays/v1"
const EXPECTATIONS_FILE := "expectations.json"
const TRANSACTION_FIXTURE := "res://test/fixtures/p16/transaction_vectors_v2.json"
const DEFAULT_HASH_EVERY := 100
const DEFAULT_MAX_TICKS := 6000

var _fixtures_dir := DEFAULT_FIXTURES
var _out_path := ""
var _hash_every := DEFAULT_HASH_EVERY
var _max_ticks := DEFAULT_MAX_TICKS
var _catalogs := {}


func _initialize() -> void:
	if not _parse_args():
		quit(2)
		return
	_catalogs = {
		"stages": _load_defs("res://data/stages"),
		"enemies": _load_defs("res://data/enemies"),
		"operators": _load_defs("res://data/operators"),
		"traps": _load_defs("res://data/traps"),
		"spells": _load_defs("res://data/spells"),
	}
	var result := _run_all()
	if not result["accepted"]:
		printerr("[replay-runner] %s" % result["error"])
		quit(int(result["exit_code"]))
		return
	if not _write_manifest(result["manifest"]):
		quit(5)
		return
	print("[replay-runner] OK %s" % _out_path)
	quit(0)


func _parse_args() -> bool:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--fixtures="):
			_fixtures_dir = arg.trim_prefix("--fixtures=")
		elif arg.begins_with("--out="):
			_out_path = arg.trim_prefix("--out=")
		elif arg.begins_with("--hash-every="):
			_hash_every = int(arg.trim_prefix("--hash-every="))
		elif arg.begins_with("--max-ticks="):
			_max_ticks = int(arg.trim_prefix("--max-ticks="))
		else:
			printerr("[replay-runner] unknown argument: %s" % arg)
			return false
	if _out_path.is_empty() or _hash_every < 1 or _max_ticks < 1:
		printerr("[replay-runner] --out is required; numeric limits must be positive")
		return false
	return true


func _run_all() -> Dictionary:
	var setup := _prepare_run()
	if not setup["accepted"]:
		return setup
	var expectations: Dictionary = setup["expectations"]
	var campaign_contract: Dictionary = setup["campaign_contract"]
	var files: Array = setup["files"]
	var runs: Array = []
	var accepted_actions := 0
	var rejected_actions := 0
	for filename: String in files:
		var replay := ReplayCodec.load_file(
			"%s/%s" % [_fixtures_dir, filename],
			_replay_context(),
		)
		if not replay["accepted"]:
			return _fail(2, "%s: %s" % [filename, replay["error_code"]])
		var run := _run_one(filename, replay, expectations[filename])
		if not run["accepted"]:
			return run
		runs.append(run["value"])
		accepted_actions += int(run["value"]["accepted_actions"])
		rejected_actions += int(run["value"]["rejected_actions"])
	if accepted_actions < 1 or rejected_actions < 1:
		return _fail(3, "verdict coverage is vacuous")
	var manifest := {}
	manifest["schema"] = "prototype_td_replay_run"
	manifest["version"] = 1
	manifest["status"] = "PASS"
	manifest["sentinel"] = "REPLAY_RUN_OK"
	manifest["hash_every"] = _hash_every
	manifest["accepted_actions"] = accepted_actions
	manifest["rejected_actions"] = rejected_actions
	manifest["campaign_contract"] = campaign_contract["value"]
	manifest["runs"] = runs
	return {"accepted": true, "manifest": manifest}


func _prepare_run() -> Dictionary:
	var expectations := _load_expectations()
	if not expectations["accepted"]:
		return expectations
	var batch := _fixture_files(expectations["value"])
	if not batch["accepted"]:
		return batch
	var campaign_contract := _campaign_contract_proof()
	if not campaign_contract["accepted"]:
		return campaign_contract
	return {
		"accepted": true,
		"expectations": expectations["value"],
		"campaign_contract": campaign_contract,
		"files": batch["value"],
	}


func _campaign_contract_proof() -> Dictionary:
	var file := FileAccess.open(TRANSACTION_FIXTURE, FileAccess.READ)
	if file == null:
		return _fail(2, "missing transaction fixture")
	var source := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(source)
	var restored := CanonicalJson.restore_exact_integers(source, parsed)
	if not restored["accepted"]:
		return _fail(2, "invalid transaction fixture integers")
	var vector: Dictionary = restored["value"].get("resolved_save", {})
	if vector.is_empty():
		return _fail(2, "missing resolved save vector")
	var context := _campaign_context()
	var encoded := CampaignCodec.encode_save(vector["value"], context)
	var full_hash := CampaignHash.of_data(vector["value"], context)
	if not encoded["accepted"] or not full_hash["accepted"]:
		return _fail(3, "resolved save vector rejected")
	var anchor: Dictionary = vector["value"]["resolution_anchor"]
	var before_hash := CampaignHash.of_core_snapshot(anchor["before_core"], context)
	var after_hash := CampaignHash.of_core_snapshot(anchor["after_core"], context)
	var actual := {
		"checksum": encoded["value"]["checksum"],
		"save_sha256": encoded["sha256"],
		"full_strategic_hash": full_hash["hex"],
		"strategic_body_hash_before": before_hash["hex"],
		"strategic_body_hash_after": after_hash["hex"],
	}
	for key: String in actual:
		if actual[key] != vector[key]:
			return _fail(3, "resolved save pin mismatch: %s" % key)
	return {"accepted": true, "value": actual}


func _campaign_context() -> Dictionary:
	var stages: Array = []
	for index: int in range(1, 9):
		stages.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	return CampaignCodec.build_context(
		_catalogs["operators"].keys(),
		_catalogs["traps"].keys(),
		_catalogs["spells"].keys(),
		stages,
		[{"offer_id": "p16_caster_contract", "operator_def_id": "caster_1", "cost": 80}],
	)


func _fixture_files(expectations: Dictionary) -> Dictionary:
	var directory := DirAccess.open(_fixtures_dir)
	if directory == null:
		return _fail(2, "cannot open fixtures: %s" % _fixtures_dir)
	var files: Array[String] = []
	for filename: String in directory.get_files():
		if filename.ends_with(".json") and filename != EXPECTATIONS_FILE:
			files.append(filename)
	files.sort()
	if files.is_empty():
		return _fail(2, "no replay fixtures")
	var expected_files: Array = expectations.keys()
	expected_files.sort()
	if files != expected_files:
		return _fail(2, "expectation fixture set mismatch")
	return {"accepted": true, "value": files}


func _run_one(filename: String, replay: Dictionary, expected: Variant) -> Dictionary:
	var stage_id: StringName = replay["stage_id"]
	var stage_path := "res://data/stages/%s.tres" % stage_id
	var stage := ResourceLoader.load(
		stage_path,
		"",
		ResourceLoader.CACHE_MODE_IGNORE,
	) as StageDef
	var config := ResourceLoader.load(
		"res://data/config/game.tres",
		"",
		ResourceLoader.CACHE_MODE_IGNORE,
	) as GameConfig
	var squad: Array[StringName] = replay["squad"]
	var input_error := _validate_model_inputs(stage, config, squad)
	if not input_error.is_empty():
		return _fail(2, "%s: %s" % [filename, input_error])
	var model := BattleModel.create(
		stage,
		squad,
		int(replay["seed"]),
		config,
		_catalogs["enemies"],
		_catalogs["operators"],
		_catalogs["traps"],
		_catalogs["spells"],
	)
	var rows: Array = replay["timeline"]
	var verdicts := _expected_verdicts(expected)
	var post_expectations := _post_action_expectations(expected)
	var terminal_expectation := _terminal_expectation(expected)
	var index := 0
	var action_results: Array = []
	var semantic_checks: Array = []
	var resign_tick := -1
	var hashes: Array = [{"tick": 0, "hash": HeroIdentity.format_u64_hex(model.state_hash())}]
	while model.result == BattleModel.Result.RUNNING and model.tick < _max_ticks:
		while index < rows.size() and int(rows[index][0]) == model.tick:
			var row: Array = rows[index]
			var state_hash_before := HeroIdentity.format_u64_hex(model.state_hash())
			var accepted := model.apply_action(row.slice(1))
			var state_hash_after := HeroIdentity.format_u64_hex(model.state_hash())
			if index >= verdicts.size() or accepted != bool(verdicts[index]):
				return _fail(3, "%s action %d verdict mismatch" % [filename, index])
			var result_row := {
				"tick": int(row[0]),
				"verb": String(row[1]),
				"accepted": accepted,
				"expected_accepted": bool(verdicts[index]),
				"state_hash_before": state_hash_before,
				"state_hash_after": state_hash_after,
			}
			action_results.append(result_row)
			var semantic := _check_post_action(
				filename,
				index,
				post_expectations,
				model,
				state_hash_before,
				state_hash_after,
			)
			if not semantic["accepted"]:
				return semantic
			if semantic["checked"]:
				semantic_checks.append(semantic["value"])
			if accepted and row[1] == &"resign":
				resign_tick = int(row[0])
			index += 1
		model.step()
		if model.tick % _hash_every == 0:
			hashes.append({
				"tick": model.tick,
				"hash": HeroIdentity.format_u64_hex(model.state_hash()),
			})
	var completion_error := _completion_error(
		model,
		index,
		rows.size(),
		verdicts.size(),
		semantic_checks.size(),
		post_expectations.size(),
	)
	if not completion_error.is_empty():
		return _fail(
			4 if model.result == BattleModel.Result.RUNNING else 3,
			"%s: %s" % [filename, completion_error],
		)
	var terminal := {}
	terminal["result"] = "clear" if model.result == BattleModel.Result.CLEAR else "defeat"
	terminal["reason"] = _terminal_reason(model, resign_tick)
	terminal["stars"] = model.stars
	terminal["leaked"] = model.leaked
	terminal["killed"] = model.killed
	terminal["charmed"] = model.charmed
	terminal["base_hp"] = model.base_hp
	terminal["tick"] = model.tick
	terminal["hash"] = HeroIdentity.format_u64_hex(model.state_hash())
	terminal["units"] = _unit_state(model)
	var terminal_error := _subset_error(terminal_expectation, terminal, "terminal")
	if not terminal_error.is_empty():
		return _fail(3, "%s %s" % [filename, terminal_error])
	var value := {}
	value["fixture"] = filename
	value["canonical_replay_sha256"] = replay["sha256"]
	value["canonical_replay"] = replay["text"]
	value["stage_id"] = String(stage_id)
	value["seed"] = int(replay["seed"])
	value["action_count"] = rows.size()
	value["accepted_actions"] = action_results.filter(func(row: Dictionary) -> bool:
		return bool(row["accepted"])).size()
	value["rejected_actions"] = action_results.size() - int(value["accepted_actions"])
	value["action_results"] = action_results
	value["semantic_checks"] = semantic_checks
	value["hashes"] = hashes
	value["terminal"] = terminal
	value["telemetry"] = _normalized_telemetry(model, terminal)
	return {"accepted": true, "value": value}


func _completion_error(
	model: BattleModel,
	action_index: int,
	row_count: int,
	verdict_count: int,
	semantic_count: int,
	post_expectation_count: int,
) -> String:
	if model.result == BattleModel.Result.RUNNING:
		return "did not terminate by tick %d" % _max_ticks
	if action_index != row_count:
		return "ended with %d unplayed actions" % [row_count - action_index]
	if action_index != verdict_count:
		return "expectation count mismatch"
	if semantic_count != post_expectation_count:
		return "post-action expectation coverage mismatch"
	return ""


func _load_expectations() -> Dictionary:
	var path := "%s/%s" % [_fixtures_dir, EXPECTATIONS_FILE]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail(2, "missing replay expectations")
	var source := file.get_as_text()
	file.close()
	var error := ""
	var raw: Variant = JSON.parse_string(source)
	var restored := CanonicalJson.restore_exact_integers(source, raw)
	var parsed: Variant = restored.get("value") if restored["accepted"] else null
	if typeof(parsed) != TYPE_DICTIONARY:
		error = "invalid replay expectations"
	elif parsed.get("schema", "") != "prototype_td_replay_expectations":
		error = "invalid replay expectation schema"
	elif int(parsed.get("version", 0)) != 1 or typeof(parsed.get("fixtures")) != TYPE_DICTIONARY:
		error = "invalid replay expectation version"
	var fixtures: Dictionary = parsed.get("fixtures", {}) if error.is_empty() else {}
	for filename: Variant in fixtures:
		if not _valid_expectation(fixtures[filename]):
			error = "invalid expectations for %s" % filename
			break
		if not error.is_empty():
			break
	return _fail(2, error) if not error.is_empty() else {"accepted": true, "value": fixtures}


func _valid_expectation(value: Variant) -> bool:
	if typeof(value) == TYPE_ARRAY:
		return _bool_array(value)
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var expected: Dictionary = value
	var valid := (
		_has_exact_keys(expected, ["verdicts", "post_actions", "terminal"])
		and _bool_array(expected.get("verdicts"))
		and typeof(expected.get("post_actions")) == TYPE_ARRAY
		and typeof(expected.get("terminal")) == TYPE_DICTIONARY
	)
	if not valid:
		return false
	var seen: Dictionary = {}
	for raw_row: Variant in expected["post_actions"]:
		if typeof(raw_row) != TYPE_DICTIONARY:
			valid = false
			break
		var row: Dictionary = raw_row
		if not _has_exact_keys(row, ["action_index", "hash_changed", "state"]):
			valid = false
			break
		if (
			typeof(row["action_index"]) != TYPE_INT
			or int(row["action_index"]) < 0
			or seen.has(row["action_index"])
			or typeof(row["hash_changed"]) != TYPE_BOOL
			or typeof(row["state"]) != TYPE_DICTIONARY
		):
			valid = false
			break
		seen[row["action_index"]] = true
	return valid


func _bool_array(value: Variant) -> bool:
	if typeof(value) != TYPE_ARRAY or (value as Array).is_empty():
		return false
	for verdict: Variant in value:
		if typeof(verdict) != TYPE_BOOL:
			return false
	return true


func _has_exact_keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in expected:
		if not value.has(key):
			return false
	return true


func _expected_verdicts(expected: Variant) -> Array:
	return expected if typeof(expected) == TYPE_ARRAY else expected["verdicts"]


func _post_action_expectations(expected: Variant) -> Array:
	return [] if typeof(expected) == TYPE_ARRAY else expected["post_actions"]


func _terminal_expectation(expected: Variant) -> Dictionary:
	return {} if typeof(expected) == TYPE_ARRAY else expected["terminal"]


func _check_post_action(
	filename: String,
	action_index: int,
	expected_rows: Array,
	model: BattleModel,
	hash_before: String,
	hash_after: String,
) -> Dictionary:
	for expected: Dictionary in expected_rows:
		if int(expected["action_index"]) != action_index:
			continue
		var changed := hash_before != hash_after
		if changed != bool(expected["hash_changed"]):
			return _fail(3, "%s action %d hash-change mismatch" % [filename, action_index])
		var actual := _model_state(model)
		var state_error := _subset_error(expected["state"], actual, "post_action")
		if not state_error.is_empty():
			return _fail(3, "%s action %d %s" % [filename, action_index, state_error])
		return {
			"accepted": true,
			"checked": true,
			"value": {
				"action_index": action_index,
				"hash_changed": changed,
				"state": expected["state"],
			},
		}
	return {"accepted": true, "checked": false}


func _model_state(model: BattleModel) -> Dictionary:
	return {"skills_fired": model.skills_fired, "units": _unit_state(model)}


func _unit_state(model: BattleModel) -> Dictionary:
	var units := {}
	for unit: UnitState in model.units:
		units[String.num_int64(unit.id)] = {
			"hp": unit.hp,
			"hp_max": unit.hp_max,
			"alive": unit.alive,
			"sp": unit.sp,
			"skill_triggered_tick": unit.skill_triggered_tick,
			"skill_target_unit_id": unit.skill_target_unit_id,
		}
	return units


func _subset_error(expected: Variant, actual: Variant, path: String) -> String:
	if typeof(expected) == TYPE_DICTIONARY:
		if typeof(actual) != TYPE_DICTIONARY:
			return "%s expected Dictionary" % path
		for key: Variant in expected:
			if not (actual as Dictionary).has(key):
				return "%s missing key %s" % [path, key]
			var nested := _subset_error(expected[key], actual[key], "%s.%s" % [path, key])
			if not nested.is_empty():
				return nested
		return ""
	return "" if expected == actual else "%s expected %s got %s" % [path, expected, actual]


func _terminal_reason(model: BattleModel, resign_tick: int) -> String:
	if model.result == BattleModel.Result.CLEAR:
		return "clear"
	if resign_tick == model.tick:
		return "resign"
	if model.base_hp <= 0:
		return "base_defeat"
	return "leak_defeat"


func _normalized_telemetry(model: BattleModel, terminal: Dictionary) -> Dictionary:
	var snapshot := model.snapshot()
	var counters := {}
	for key: String in [
		"spawned", "leaked", "killed", "deploys", "retreated", "dp_spent",
		"skills_fired", "traps_placed", "trap_triggers", "charmed", "charmed_dead",
		"charmed_exited", "spells_cast",
	]:
		counters[key] = int(snapshot[key])
	var telemetry := {}
	telemetry["counters"] = counters
	telemetry["series_last"] = {"base_hp": model.base_hp, "dp": model.dp}
	telemetry["events"] = [{
		"tick": model.tick,
		"name": "result",
		"data": {"result": terminal["result"], "reason": terminal["reason"], "stars": model.stars},
	}]
	return telemetry


func _validate_model_inputs(
	stage: StageDef,
	config: GameConfig,
	squad: Array[StringName],
) -> String:
	var error := ""
	if stage == null or config == null:
		error = "stage/config load failed"
	elif squad.is_empty() or squad.size() > stage.squad_size:
		error = "squad size violates stage capacity"
	else:
		for operator_id: StringName in squad:
			if not _catalogs["operators"].has(operator_id):
				error = "unknown operator %s" % operator_id
				break
	return error


func _load_defs(dir_path: String) -> Dictionary:
	var defs := {}
	var directory := DirAccess.open(dir_path)
	if directory == null:
		return defs
	var files: Array[String] = []
	for filename: String in directory.get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres") and not files.has(source):
			files.append(source)
	files.sort()
	for filename: String in files:
		var resource := ResourceLoader.load(
			"%s/%s" % [dir_path, filename],
			"",
			ResourceLoader.CACHE_MODE_IGNORE,
		)
		if resource != null:
			defs[resource.get("id")] = resource
	return defs


func _replay_context() -> Dictionary:
	return ReplayCodec.build_context(
		_catalogs["operators"],
		_catalogs["traps"],
		_catalogs["spells"],
		_catalogs["stages"],
		load("res://data/config/game.tres") as GameConfig,
	)


func _write_manifest(manifest: Dictionary) -> bool:
	var absolute := ProjectSettings.globalize_path(_out_path)
	var parent := absolute.get_base_dir()
	if not parent.is_empty():
		DirAccess.make_dir_recursive_absolute(parent)
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file == null:
		printerr("[replay-runner] cannot write %s" % absolute)
		return false
	file.store_string(CanonicalJson.text(manifest))
	file.close()
	return true


func _fail(exit_code: int, error: String) -> Dictionary:
	return {"accepted": false, "exit_code": exit_code, "error": error}
