extends SceneTree

const RESULT_PREFIX := "MODEL_PROMOTION_RESULT="

var _choice := "witch_doctor"
var _reverse_inputs := false


func _init() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--reverse-inputs":
			_reverse_inputs = true
		elif argument.begins_with("--choice="):
			_choice = argument.trim_prefix("--choice=")
	call_deferred("_run")


func _run() -> void:
	if _choice not in ["witch_doctor", "sorcerer"]:
		_fail(&"invalid_choice")
		return
	var setup := _setup()
	if not setup["accepted"]:
		_fail(setup["error_code"])
		return
	var exercised := _exercise(setup)
	if not exercised["accepted"]:
		_fail(exercised["error_code"])
		return
	var durable := _durability(setup, exercised)
	if not durable["accepted"]:
		_fail(durable["error_code"])
		return
	print(RESULT_PREFIX + JSON.stringify(_result(setup, exercised, durable), "", false, true))
	quit(0)


func _setup() -> Dictionary:
	var definition := load("res://data/campaigns/p16_v2.tres") as CampaignDef
	var catalogs := _catalogs()
	var stages := _stages()
	if _reverse_inputs:
		for key: String in catalogs:
			(catalogs[key] as Array).reverse()
		stages.reverse()
	var created := CampaignState.create(42, 1, definition, catalogs, stages)
	if not created["accepted"]:
		return created
	var state := created["value"] as CampaignState
	var ready_data := state.data_copy()
	ready_data["heroes"][0]["xp"] = 400
	var ready := CampaignState.restore(ready_data, definition, catalogs, stages)
	if not ready["accepted"]:
		return ready
	state = ready["value"] as CampaignState
	var hero_id := String(state.data_copy()["heroes"][0]["hero_id"])
	return {
		"accepted": true,
		"error_code": &"",
		"definition": definition,
		"catalogs": catalogs,
		"stages": stages,
		"state": state,
		"hero_id": hero_id,
		"command": _command(state, hero_id, _choice),
		"before_hash": String(state.strategic_hash()["hex"]),
	}


func _exercise(setup: Dictionary) -> Dictionary:
	var state := setup["state"] as CampaignState
	var command: Dictionary = setup["command"]
	var accepted := state.promote_hero(command)
	if not accepted["accepted"]:
		return accepted
	var accepted_bytes: PackedByteArray = state.encode_data()["bytes"]
	var accepted_hash := String(state.strategic_hash()["hex"])
	var retry := state.promote_hero(command.duplicate(true))
	if not retry["accepted"] or retry["receipt_bytes"] != accepted["receipt_bytes"]:
		return _reject(&"retry_mismatch")
	var conflict_command: Dictionary = command.duplicate(true)
	conflict_command["advanced_class_id"] = _other_choice(_choice)
	var conflict := state.promote_hero(conflict_command)
	var alternate_command := _command(
		state, String(setup["hero_id"]), _other_choice(_choice),
	)
	var alternate := state.promote_hero(alternate_command)
	if (
		conflict["error_code"] != &"command_id_conflict"
		or alternate["error_code"] != &"already_promoted"
		or state.encode_data()["bytes"] != accepted_bytes
		or state.strategic_hash()["hex"] != accepted_hash
	):
		return _reject(&"rejection_mutated_state")
	var replay := CampaignPromotion.encode_replay_rows([
		CampaignPromotion.replay_row(1, command),
		CampaignPromotion.replay_row(2, command),
		CampaignPromotion.replay_row(3, conflict_command),
		CampaignPromotion.replay_row(4, alternate_command),
	])
	if not replay["accepted"]:
		return replay
	return {
		"accepted": true,
		"error_code": &"",
		"accepted_command": accepted,
		"accepted_bytes": accepted_bytes,
		"accepted_hash": accepted_hash,
		"replay": replay,
		"results": [
			CampaignPromotion.replay_result(accepted, state),
			CampaignPromotion.replay_result(retry, state),
			CampaignPromotion.replay_result(conflict, state),
			CampaignPromotion.replay_result(alternate, state),
		],
	}


func _durability(setup: Dictionary, exercised: Dictionary) -> Dictionary:
	var definition := setup["definition"] as CampaignDef
	var catalogs: Dictionary = setup["catalogs"]
	var stages: Array = setup["stages"]
	var state := setup["state"] as CampaignState
	var context := CampaignCodec.build_context(
		catalogs["operators"], catalogs["traps"], catalogs["spells"],
		stages, definition.paid_offers,
	)
	var save := CampaignCodec.encode_save(state.data_copy(), context)
	if not save["accepted"]:
		return save
	var decoded := CampaignCodec.decode_save(save["text"], context)
	if not decoded["accepted"]:
		return decoded
	var restarted := CampaignState.restore(decoded["data"], definition, catalogs, stages)
	if not restarted["accepted"]:
		return restarted
	var restarted_state := restarted["value"] as CampaignState
	var accepted: Dictionary = exercised["accepted_command"]
	var restart_retry := restarted_state.promote_hero(setup["command"])
	if (
		not restart_retry["accepted"]
		or restart_retry["receipt_bytes"] != accepted["receipt_bytes"]
		or restarted_state.encode_data()["bytes"] != exercised["accepted_bytes"]
		or restarted_state.strategic_hash()["hex"] != exercised["accepted_hash"]
	):
		return _reject(&"restart_retry_mismatch")
	return {
		"accepted": true,
		"error_code": &"",
		"save": save,
		"state": restarted_state,
	}


func _result(setup: Dictionary, exercised: Dictionary, durable: Dictionary) -> Dictionary:
	var definition := setup["definition"] as CampaignDef
	var state := durable["state"] as CampaignState
	var command: Dictionary = setup["command"]
	var accepted: Dictionary = exercised["accepted_command"]
	var replay: Dictionary = exercised["replay"]
	var save: Dictionary = durable["save"]
	var hero: Dictionary = state.data_copy()["heroes"][0]
	return {
		"choice": _choice,
		"environment_sha256": definition.environment_sha256,
		"command": command,
		"command_bytes": _bytes(CanonicalJson.text(command).to_utf8_buffer()),
		"replay_sha256": replay["sha256"],
		"replay_rows": replay["value"],
		"results": exercised["results"],
		"receipt": accepted["receipt"],
		"receipt_bytes": _bytes(accepted["receipt_bytes"]),
		"before_strategic_hash": setup["before_hash"],
		"after_strategic_hash": exercised["accepted_hash"],
		"save_sha256": save["sha256"],
		"save_revision": state.save_revision(),
		"hero_id": hero["hero_id"],
		"identity_portrait_id": hero["identity_portrait_id"],
		"acquisition_operator_def_id": hero["acquisition_operator_def_id"],
		"operator_def_id": hero["operator_def_id"],
		"first_class_id": hero["first_class_id"],
		"advanced_class_id": hero["advanced_class_id"],
		"xp": hero["xp"],
		"restart_byte_identical": true,
		"exact_retry_byte_identical": true,
		"rejects_hash_equal": true,
	}


func _command(state: CampaignState, hero_id: String, choice: String) -> Dictionary:
	var revision := state.save_revision()
	return {
		"version": 1,
		"verb": "promote_hero",
		"command_id": CampaignPromotion.command_id(
			state.campaign_uid(), revision, hero_id, choice,
		),
		"hero_id": hero_id,
		"advanced_class_id": choice,
		"expected_save_revision": revision,
	}


func _other_choice(choice: String) -> String:
	return "sorcerer" if choice == "witch_doctor" else "witch_doctor"


func _bytes(value: PackedByteArray) -> Array[int]:
	var result: Array[int] = []
	for byte: int in value:
		result.append(byte)
	return result


func _catalogs() -> Dictionary:
	return {
		"operators": _catalog_ids("res://data/operators"),
		"traps": _catalog_ids("res://data/traps"),
		"spells": _catalog_ids("res://data/spells"),
	}


func _stages() -> Array:
	var values: Array = []
	for index: int in range(1, 9):
		values.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	return values


func _catalog_ids(path: String) -> Array[StringName]:
	var values: Array[StringName] = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			values.append(StringName(source.trim_suffix(".tres")))
	return values


func _reject(error_code: StringName) -> Dictionary:
	return {"accepted": false, "error_code": error_code}


func _fail(error_code: Variant) -> void:
	printerr("MODEL_PROMOTION_ERROR=" + String(error_code))
	quit(1)
