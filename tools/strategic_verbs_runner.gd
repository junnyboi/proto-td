extends SceneTree

const RESULT_PREFIX := "STRATEGIC_VERBS_RESULT="
const SLOT := "user://p162-runner.json"

class RunnerOps extends CampaignFileOps:
	var files := {}

	func file_exists(path: String) -> bool:
		return files.has(path)

	func read_bytes(path: String) -> Dictionary:
		if not files.has(path):
			return {"accepted": false, "error_code": &"file_missing", "bytes": PackedByteArray()}
		return {"accepted": true, "error_code": &"", "bytes": files[path]}

	func write_bytes(path: String, bytes: PackedByteArray) -> Dictionary:
		files[path] = bytes.duplicate()
		return {"accepted": true, "error_code": &""}

	func rename_path(from_path: String, to_path: String) -> Dictionary:
		if not files.has(from_path):
			return {"accepted": false, "error_code": &"file_missing"}
		files[to_path] = files[from_path]
		files.erase(from_path)
		return {"accepted": true, "error_code": &""}

	func remove_path(path: String) -> Dictionary:
		if not files.has(path):
			return {"accepted": false, "error_code": &"file_missing"}
		files.erase(path)
		return {"accepted": true, "error_code": &""}


func _init() -> void:
	_cleanup_production_slot()
	var result := _run()
	if not result["accepted"]:
		_cleanup_production_slot()
		push_error("STRATEGIC_VERBS_FAILED %s" % str(result))
		quit(1)
		return
	print(RESULT_PREFIX + CanonicalJson.text(result["value"]).strip_edges())
	_cleanup_production_slot()
	quit(0)


func _run() -> Dictionary:
	var prepared := _prepare_paid()
	if not prepared["accepted"]:
		return prepared
	var setup: Dictionary = prepared["setup"]
	var state: CampaignState = prepared["state"]
	var store: CampaignSaveStore = prepared["store"]
	var fresh: Dictionary = prepared["fresh"]
	var rejected: Dictionary = prepared["rejected"]
	var paid_hero: HeroState = prepared["paid_hero"]
	var paid_pins: Dictionary = prepared["paid_pins"]
	var renamed := _apply(state.rename_hero(paid_hero.hero_id(), "Aegis"), store)
	if not renamed["accepted"]:
		return renamed
	state = renamed["state"]
	var renamed_pins := _state_pins(state)
	renamed_pins["events"] = renamed["events"]
	var begun := _apply(state.begin_attempt(&"s1", [_ready_ids(state)[0]]), store)
	if not begun["accepted"]:
		return begun
	state = begun["state"]
	var pending: CampaignPendingAttempt = state.pending_attempt()
	var ticket := pending.ticket()
	var ticket_pins := {
		"attempt_id": ticket.attempt_id(),
		"manifest_hash": ticket.manifest_hash(),
		"sha256": ticket.canonical_sha256(),
		"data": ticket.data_copy(),
		"events": begun["events"],
	}
	var outcome := _outcome(ticket, ticket.manifest()[0]["battle_id"])
	var resolved := _apply(state.resolve_attempt(ticket, outcome, pending), store)
	if not resolved["accepted"]:
		return resolved
	state = resolved["state"]
	var receipt: CampaignResolution = resolved["result"]["receipt"]
	var resolution_pins := _state_pins(state)
	resolution_pins["receipt_sha256"] = receipt.canonical_sha256()
	resolution_pins["receipt"] = receipt.data_copy()
	resolution_pins["dead_hero_ids"] = receipt.dead_hero_ids()
	resolution_pins["created_hero_ids"] = receipt.created_hero_ids()
	resolution_pins["events"] = resolved["events"]
	var duplicate := state.resolve_attempt(ticket, outcome, pending)
	var proofs := _extra_proofs()
	if not proofs["accepted"]:
		return proofs
	return {
		"accepted": true,
		"error_code": &"",
		"value": {
			"environment_sha256": _definition().environment_sha256,
			"fresh": fresh,
			"rejection": {
				"error_code": String(rejected["error_code"]),
				"state_equal": _state_pins(setup["initial_state"]) == fresh,
			},
			"paid_recruit": paid_pins,
			"renamed": renamed_pins,
			"ticket": ticket_pins,
			"resolution": resolution_pins,
				"duplicate": {
				"accepted": duplicate["accepted"],
				"fresh": duplicate["payload"]["fresh"],
					"event_names": _event_names(duplicate["events"]),
				},
				"load_matrix": proofs["load_matrix"],
				"sibling_cas": proofs["sibling_cas"],
				"precedence": proofs["precedence"],
					"recovery_totals": _recovery_totals(),
			},
	}


func _prepare_paid() -> Dictionary:
	var setup := _setup()
	if not setup["accepted"]:
		return setup
	var state: CampaignState = setup["state"]
	var store: CampaignSaveStore = setup["store"]
	var fresh := _state_pins(state)
	var rejected := state.rename_hero("missing", "Nova")
	var paid := _apply(state.recruit("p16_caster_contract"), store)
	if not paid["accepted"]:
		return paid
	state = paid["state"]
	var paid_hero := state.roster().all()[-1]
	var paid_pins := _state_pins(state)
	paid_pins["hero_id"] = paid_hero.hero_id()
	paid_pins["events"] = paid["events"]
	return {
		"accepted": true,
		"setup": setup,
		"state": state,
		"store": store,
		"fresh": fresh,
		"rejected": rejected,
		"paid_hero": paid_hero,
		"paid_pins": paid_pins,
	}


func _setup() -> Dictionary:
	var created := CampaignState.create(42, 1, _definition(), _catalogs(), _stages())
	if not created["accepted"]:
		return created
	var state: CampaignState = created["value"]
	var store_result := CampaignSaveStore.create_production(state)
	if not store_result["accepted"]:
		return store_result
	var store: CampaignSaveStore = store_result["value"]
	var file := FileAccess.open(CampaignSaveStore.PRODUCTION_SLOT, FileAccess.WRITE)
	if file == null:
		return {"accepted": false, "error_code": &"seed_failed"}
	file.store_buffer(state.encode_save()["bytes"])
	file.close()
	return {
		"accepted": true,
		"error_code": &"",
		"state": state,
		"initial_state": state,
		"store": store,
	}


func _cleanup_production_slot() -> void:
	for path: String in [
		CampaignSaveStore.PRODUCTION_SLOT,
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".tmp",
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".bak",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _extra_proofs() -> Dictionary:
	var load_matrix := _load_matrix_pins()
	if not load_matrix["accepted"]:
		return load_matrix
	var sibling := _sibling_cas_pin()
	if not sibling["accepted"]:
		return sibling
	var precedence := _precedence_pins()
	if not precedence["accepted"]:
		return precedence
	return {
		"accepted": true,
		"error_code": &"",
		"load_matrix": load_matrix["value"],
		"sibling_cas": sibling["value"],
		"precedence": precedence["value"],
	}


func _load_matrix_pins() -> Dictionary:
	var states := _matrix_states()
	if not states["accepted"]:
		return states
	var fresh: CampaignState = states["fresh"]
	var paid: CampaignState = states["paid"]
	var begun: CampaignState = states["begun"]
	var renamed: CampaignState = states["renamed"]
	var bad := "bad".to_utf8_buffer()
	var rows := [
		["empty", {}], ["main", {SLOT: fresh}],
		["main_bak", {SLOT: paid, "user://p162-runner.bak": fresh}],
		["main_tmp", {SLOT: paid, "user://p162-runner.tmp": begun}],
		["main_bak_tmp", {
			SLOT: paid, "user://p162-runner.bak": fresh,
			"user://p162-runner.tmp": begun,
		}],
		["main_equal_divergent_sidecars", {
			SLOT: fresh, "user://p162-runner.bak": paid,
			"user://p162-runner.tmp": renamed,
		}],
		["bak", {"user://p162-runner.bak": paid}],
		["tmp", {"user://p162-runner.tmp": begun}],
		["bak_tmp", {
			"user://p162-runner.bak": paid, "user://p162-runner.tmp": begun,
		}],
		["corrupt_main_bak", {SLOT: bad, "user://p162-runner.bak": paid}],
		["corrupt_main_tmp", {SLOT: bad, "user://p162-runner.tmp": begun}],
		["all_invalid", {
			SLOT: bad, "user://p162-runner.bak": bad, "user://p162-runner.tmp": bad,
		}],
		["equal_version_divergence", {
			"user://p162-runner.bak": paid, "user://p162-runner.tmp": renamed,
		}],
		["tmp_not_newer_than_invalid_header", {
			SLOT: _corrupt_checksum(begun), "user://p162-runner.tmp": paid,
		}],
		["tmp_same_generation_higher_revision", {
			SLOT: _corrupt_checksum(fresh), "user://p162-runner.tmp": paid,
		}],
		["tmp_same_generation_lower_than_invalid_bak", {
			"user://p162-runner.bak": _corrupt_checksum(begun),
			"user://p162-runner.tmp": paid,
		}],
		["invalid_main_invalid_bak_newer_tmp", {
			SLOT: _corrupt_checksum(fresh),
			"user://p162-runner.bak": _corrupt_checksum(fresh),
			"user://p162-runner.tmp": paid,
		}],
	]
	if OS.get_cmdline_user_args().has("--reverse"):
		rows.reverse()
	var values: Array[Dictionary] = []
	for row: Array in rows:
		values.append(_load_projection(String(row[0]), row[1], fresh))
	values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])
	return {"accepted": true, "error_code": &"", "value": values}


func _matrix_states() -> Dictionary:
	var paid_setup := _setup()
	var paid_result := _apply(
		(paid_setup["state"] as CampaignState).recruit("p16_caster_contract"),
		paid_setup["store"],
	)
	if not paid_result["accepted"]:
		return paid_result
	var paid: CampaignState = paid_result["state"]
	var begun_result := _apply(
		paid.begin_attempt(&"s1", [_ready_ids(paid)[0]]), paid_setup["store"],
	)
	if not begun_result["accepted"]:
		return begun_result
	_cleanup_production_slot()
	var renamed_setup := _setup()
	var renamed_result := _apply(
		(renamed_setup["state"] as CampaignState).rename_hero(
			_ready_ids(renamed_setup["state"])[0], "Nova",
		), renamed_setup["store"],
	)
	if not renamed_result["accepted"]:
		return renamed_result
	return {
		"accepted": true,
		"fresh": paid_setup["initial_state"],
		"paid": paid,
		"begun": begun_result["state"],
		"renamed": renamed_result["state"],
	}


func _load_projection(id: String, layout: Dictionary, fresh: CampaignState) -> Dictionary:
	var ops := RunnerOps.new()
	for path: String in layout:
		var value: Variant = layout[path]
		ops.files[path] = (
			value.encode_save()["bytes"].duplicate()
			if value is CampaignState
			else (value as PackedByteArray).duplicate()
		)
	var store: CampaignSaveStore = CampaignSaveStore.create(
		SLOT, fresh.restore_factory(), ops,
	)["value"]
	var loaded: Dictionary = store.load()
	var state_pins := {}
	if loaded["accepted"]:
		state_pins = _state_pins(loaded["state"])
	return {
		"id": id,
		"accepted": loaded["accepted"],
		"error_code": String(loaded["error_code"]),
		"source": String(loaded["source"]),
		"winner": state_pins,
		"final_layout": _file_layout(ops.files),
	}


func _sibling_cas_pin() -> Dictionary:
	var setup := _setup()
	var state: CampaignState = setup["state"]
	var paid := state.recruit("p16_caster_contract")
	var renamed := state.rename_hero(_ready_ids(state)[0], "Nova")
	var first := _apply(paid, setup["store"])
	if not first["accepted"]:
		return first
	var blocked := (renamed["payload"]["mutation"] as CampaignMutation).retry_save(setup["store"])
	return {
		"accepted": true,
		"error_code": &"",
			"value": {
				"first": _result_projection(first),
				"sibling": _result_projection(blocked),
			"final_layout": _production_layout(),
		},
	}


func _production_layout() -> Array[Dictionary]:
	var files := {}
	var ops := CampaignFileOps.new()
	for path: String in [
		CampaignSaveStore.PRODUCTION_SLOT,
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".tmp",
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".bak",
	]:
		if ops.file_exists(path):
			files[path] = ops.read_bytes(path)["bytes"]
	return _file_layout(files)


func _precedence_pins() -> Dictionary:
	var setup := _setup()
	var fresh: CampaignState = setup["state"]
	var ready := _ready_ids(fresh)
	var default_name: String = fresh.roster().all()[0].display_callsign()["value"]
	var duplicate_name: String = fresh.roster().all()[1].display_callsign()["value"]
	var values: Array[Dictionary] = [
		_code("recruit_unknown", fresh.recruit("missing")),
		_code("recruit_recovery_unavailable", fresh.recruit("recovery:s1:vanguard_1")),
		_code("rename_unknown", fresh.rename_hero("missing", "Nova")),
		_code("rename_invalid", fresh.rename_hero(ready[0], "  ")),
		_code("rename_unchanged", fresh.rename_hero(ready[0], default_name)),
		_code("rename_duplicate", fresh.rename_hero(ready[0], duplicate_name)),
		_code("begin_unknown_stage", fresh.begin_attempt(&"missing", [ready[0]])),
		_code("begin_locked_stage", fresh.begin_attempt(&"s2", [ready[0]])),
		_code("begin_empty", fresh.begin_attempt(&"s1", [])),
		_code("begin_too_large", fresh.begin_attempt(&"s1", ready.slice(0, 4))),
		_code("begin_bad_member", fresh.begin_attempt(&"s1", [7])),
		_code("begin_duplicate", fresh.begin_attempt(&"s1", [ready[0], ready[0]])),
		_code("begin_unknown_hero", fresh.begin_attempt(&"s1", ["missing"])),
	]
	var begun := _begun_setup()
	if not begun["accepted"]:
		return begun
	var state: CampaignState = begun["state"]
	var pending: CampaignPendingAttempt = state.pending_attempt()
	var outcome := _outcome(pending.ticket(), "")
	values.append(_code(
		"resolve_no_capability", state.resolve_attempt(pending.ticket(), outcome, null),
	))
	var wrong_ticket := _ticket_variant(pending.ticket(), {"attempt_id": 2})
	values.append(_code(
		"resolve_wrong_attempt",
		state.resolve_attempt(wrong_ticket, _outcome(wrong_ticket, ""), pending),
	))
	var stage_ticket := _ticket_variant(pending.ticket(), {"stage_id": "s2"})
	values.append(_code(
		"resolve_stage_mismatch",
		state.resolve_attempt(stage_ticket, _outcome(stage_ticket, ""), pending),
	))
	var manifest := pending.ticket().manifest()
	manifest[0]["operator_def_id"] = "caster_2"
	var manifest_ticket := _ticket_variant(pending.ticket(), {
		"manifest": manifest,
		"manifest_hash": CanonicalJson.sha256_hex(manifest),
	})
	values.append(_code(
		"resolve_manifest_mismatch",
		state.resolve_attempt(manifest_ticket, _outcome(manifest_ticket, ""), pending),
	))
	var reserved_command := state.resolve_attempt(pending.ticket(), outcome, pending)
	if not reserved_command["accepted"]:
		return reserved_command
	values.append(_code(
		"resolve_reserved", state.resolve_attempt(pending.ticket(), outcome, pending),
	))
	var mismatch_setup := _begun_setup()
	if not mismatch_setup["accepted"]:
		return mismatch_setup
	state = mismatch_setup["state"]
	pending = state.pending_attempt()
	outcome = _outcome(pending.ticket(), "")
	state._data["marks"] = state.marks() + 1
	values.append(_code(
		"resolve_state_mismatch", state.resolve_attempt(pending.ticket(), outcome, pending),
	))
	values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])
	return {"accepted": true, "error_code": &"", "value": values}


func _begun_setup() -> Dictionary:
	var setup := _setup()
	var state: CampaignState = setup["state"]
	var begun := _apply(
		state.begin_attempt(&"s1", [_ready_ids(state)[0]]), setup["store"],
	)
	if not begun["accepted"]:
		return begun
	return {"accepted": true, "state": begun["state"]}


func _code(id: String, result: Dictionary) -> Dictionary:
	var projection := _result_projection(result)
	projection["id"] = id
	return projection


func _result_projection(result: Dictionary) -> Dictionary:
	var projection := {
		"accepted": result["accepted"],
		"error_code": String(result["error_code"]),
		"events": (result.get("events", []) as Array).duplicate(true),
		"payload": {},
	}
	var payload: Dictionary = result.get("payload", {})
	for key: String in payload:
		var value: Variant = payload[key]
		if value is CampaignState:
			projection["payload"][key] = _state_pins(value)
		elif value is Dictionary or value is Array or value == null or typeof(value) in [
			TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME,
		]:
			projection["payload"][key] = value
	return projection


static func _ticket_variant(
	ticket: CampaignBattleTicket,
	changes: Dictionary,
) -> CampaignBattleTicket:
	var data := ticket.data_copy()
	for key: String in changes:
		data[key] = changes[key]
	return CampaignBattleTicket.from_data(data)["value"]


func _corrupt_checksum(state: CampaignState) -> PackedByteArray:
	var source: String = state.encode_save()["text"]
	var parser := JSON.new()
	if parser.parse(source) != OK:
		return PackedByteArray()
	var exact := CanonicalJson.restore_exact_integers(source, parser.data)
	if not exact["accepted"]:
		return PackedByteArray()
	var root: Dictionary = exact["value"]
	root["checksum"] = "0".repeat(64)
	return CanonicalJson.text(root).to_utf8_buffer()


func _apply(command: Dictionary, store: CampaignSaveStore) -> Dictionary:
	if not command["accepted"]:
		return command
	var saved := (command["payload"]["mutation"] as CampaignMutation).retry_save(store)
	if not saved["accepted"]:
		return saved
	return {
		"accepted": true,
		"error_code": &"",
		"state": saved["payload"]["state"],
		"result": saved["payload"]["result"],
		"events": saved["events"],
		"event_names": _event_names(saved["events"]),
	}


func _outcome(ticket: CampaignBattleTicket, fallen_id: String) -> BattleOutcome:
	var heroes: Array[Dictionary] = []
	for row: Dictionary in ticket.manifest():
		var fell := String(row["battle_id"]) == fallen_id
		heroes.append({
			"hero_id": row["battle_id"],
			"operator_def_id": row["operator_def_id"],
			"deployments": 1,
			"retreats": 0,
			"fell": fell,
			"first_fall_tick": 60 if fell else null,
		})
	var data := {
		"schema_version": 1,
		"campaign_uid": ticket.campaign_uid(),
		"attempt_id": ticket.attempt_id(),
		"stage_id": String(ticket.stage_id()),
		"manifest_hash": ticket.manifest_hash(),
		"result": "clear",
		"terminal_reason": "clear",
		"stars": 3,
		"terminal_tick": 120,
		"model_state_hash": "0000000000000000",
		"heroes": heroes,
	}
	data["outcome_hash"] = CanonicalJson.sha256_hex(data)
	return BattleOutcome.from_data(data)["value"]


func _state_pins(state: CampaignState) -> Dictionary:
	var encoded := state.encode_save()
	return {
		"save_revision": state.save_revision(),
		"save_sha256": encoded["sha256"],
		"data_checksum": state.encode_data()["sha256"],
		"strategic_hash": state.strategic_hash()["hex"],
	}


func _event_names(events: Array) -> Array[String]:
	var result: Array[String] = []
	for event: Dictionary in events:
		result.append(String(event["name"]))
	return result


func _ready_ids(state: CampaignState) -> Array[String]:
	var result: Array[String] = []
	for hero: HeroState in state.roster().ready():
		result.append(hero.hero_id())
	return result


func _definition() -> CampaignDef:
	return load("res://data/campaigns/p16_v2.tres") as CampaignDef


func _catalogs() -> Dictionary:
	var catalogs := {
		"operators": _catalog_ids("res://data/operators"),
		"traps": _catalog_ids("res://data/traps"),
		"spells": _catalog_ids("res://data/spells"),
	}
	if OS.get_cmdline_user_args().has("--reverse"):
		for key: String in catalogs:
			(catalogs[key] as Array).reverse()
	return catalogs


func _stages() -> Array:
	var stages: Array = []
	for index: int in range(1, 9):
		stages.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	if OS.get_cmdline_user_args().has("--reverse"):
		stages.reverse()
	return stages


func _recovery_totals() -> Dictionary:
	var stage_subsets: Array[int] = []
	var subset_total := 0
	var recruit_total := 0
	for stage: StageDef in _stages():
		var hero_count := stage.recovery_roster.size()
		var subsets := 1 << hero_count
		stage_subsets.append(subsets)
		subset_total += subsets
		recruit_total += hero_count * (1 << (hero_count - 1))
	stage_subsets.sort()
	return {
		"stage_subsets": stage_subsets,
		"subsets": subset_total,
		"accepted_recruits": recruit_total,
		"roster_cycles": CampaignCodec.MAX_ROSTER - 5,
		"renames": CampaignCodec.MAX_ROSTER,
		"max_roster": CampaignCodec.MAX_ROSTER,
	}


func _catalog_ids(path: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			ids.append(StringName(source.trim_suffix(".tres")))
	return ids


static func _file_layout(files: Dictionary) -> Array[Dictionary]:
	var paths: Array[String] = []
	for path: String in files:
		paths.append(path)
	paths.sort()
	var result: Array[Dictionary] = []
	for path: String in paths:
		var bytes: PackedByteArray = files[path]
		result.append({
			"path": path,
			"sha256": bytes.get_string_from_utf8().sha256_text(),
			"text": bytes.get_string_from_utf8(),
		})
	return result
