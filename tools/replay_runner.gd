extends SceneTree

const DEFAULT_FIXTURES := "res://playtests/replays/v1"
const EXPECTATIONS_FILE := "expectations.json"
const TRANSACTION_FIXTURE := "res://test/fixtures/p16/transaction_vectors_v1.json"
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


func _run_one(filename: String, replay: Dictionary, expected: Array) -> Dictionary:
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
	var index := 0
	var action_results: Array = []
	var resign_tick := -1
	var hashes: Array = [{"tick": 0, "hash": HeroIdentity.format_u64_hex(model.state_hash())}]
	while model.result == BattleModel.Result.RUNNING and model.tick < _max_ticks:
		while index < rows.size() and int(rows[index][0]) == model.tick:
			var row: Array = rows[index]
			var state_hash_before := HeroIdentity.format_u64_hex(model.state_hash())
			var accepted := model.apply_action(row.slice(1))
			var state_hash_after := HeroIdentity.format_u64_hex(model.state_hash())
			if index >= expected.size() or accepted != bool(expected[index]):
				return _fail(3, "%s action %d verdict mismatch" % [filename, index])
			action_results.append({
				"tick": int(row[0]),
				"verb": String(row[1]),
				"accepted": accepted,
				"expected_accepted": bool(expected[index]),
				"state_hash_before": state_hash_before,
				"state_hash_after": state_hash_after,
			})
			if accepted and row[1] == &"resign":
				resign_tick = int(row[0])
			index += 1
		model.step()
		if model.tick % _hash_every == 0:
			hashes.append({
				"tick": model.tick,
				"hash": HeroIdentity.format_u64_hex(model.state_hash()),
			})
	if model.result == BattleModel.Result.RUNNING:
		return _fail(4, "%s did not terminate by tick %d" % [filename, _max_ticks])
	if index != rows.size():
		return _fail(3, "%s ended with %d unplayed actions" % [filename, rows.size() - index])
	if index != expected.size():
		return _fail(3, "%s expectation count mismatch" % filename)
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
	value["hashes"] = hashes
	value["terminal"] = terminal
	value["telemetry"] = _normalized_telemetry(model, terminal)
	return {"accepted": true, "value": value}


func _load_expectations() -> Dictionary:
	var path := "%s/%s" % [_fixtures_dir, EXPECTATIONS_FILE]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail(2, "missing replay expectations")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	var error := ""
	if typeof(parsed) != TYPE_DICTIONARY:
		error = "invalid replay expectations"
	elif parsed.get("schema", "") != "prototype_td_replay_expectations":
		error = "invalid replay expectation schema"
	elif int(parsed.get("version", 0)) != 1 or typeof(parsed.get("fixtures")) != TYPE_DICTIONARY:
		error = "invalid replay expectation version"
	var fixtures: Dictionary = parsed.get("fixtures", {}) if error.is_empty() else {}
	for filename: Variant in fixtures:
		if typeof(fixtures[filename]) != TYPE_ARRAY:
			error = "invalid verdict expectations"
			break
		for verdict: Variant in fixtures[filename]:
			if typeof(verdict) != TYPE_BOOL:
				error = "invalid verdict expectation"
				break
		if not error.is_empty():
			break
	return _fail(2, error) if not error.is_empty() else {"accepted": true, "value": fixtures}


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
