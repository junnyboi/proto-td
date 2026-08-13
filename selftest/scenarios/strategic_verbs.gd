extends RefCounted

## P16.2 model-only command probe. No rendering or player-facing claim.

func run(h: SelfTestHarness) -> void:
	_cleanup_production_slot()
	h.expect_done()
	h.max_frames = 900
	var created := CampaignState.create(
		h.seed_value, 1, _definition(), _catalogs(), _stages(),
	)
	h.check("canonical state creates", created["accepted"],
		str(created.get("error_code", &"")))
	if not created["accepted"]:
		return
	var state: CampaignState = created["value"]
	var store_result := CampaignSaveStore.create_production(state)
	h.check("production SaveStore creates", store_result["accepted"],
		str(store_result.get("error_code", &"")))
	if not store_result["accepted"]:
		_cleanup_production_slot()
		return
	var store: CampaignSaveStore = store_result["value"]
	var file := FileAccess.open(CampaignSaveStore.PRODUCTION_SLOT, FileAccess.WRITE)
	h.check("production seed opens", file != null)
	if file == null:
		_cleanup_production_slot()
		return
	file.store_buffer(state.encode_save()["bytes"])
	file.close()
	h.check("fresh strategic hash pinned",
		state.strategic_hash()["hex"] == "85f2c11018249153")
	var rejected := state.rename_hero("missing", "Nova")
	h.check("unknown hero rejects exactly",
		not rejected["accepted"] and rejected["error_code"] == &"unknown_hero")
	state = _commit(h, state.recruit("p16_caster_contract"), store)
	h.check("paid hero pin", state.roster().all()[-1].hero_id() == "e54c103e46898f5d")
	state = _commit(
		h, state.rename_hero(state.roster().all()[-1].hero_id(), "Aegis"), store,
	)
	var selected: Array[String] = [state.roster().ready()[0].hero_id()]
	state = _commit(h, state.begin_attempt(&"s1", selected), store)
	var pending: CampaignPendingAttempt = state.pending_attempt()
	var ticket := pending.ticket()
	h.check("ticket SHA pinned",
		ticket.canonical_sha256()
		== "8d6fbd0dadad3cc4b12df8f51ada0d59f6d377dfece18aec8aef953a5fb17a53")
	var outcome := _outcome(ticket, selected[0])
	var command := state.resolve_attempt(ticket, outcome, pending)
	var mutation: CampaignMutation = command["payload"]["mutation"]
	var committed := mutation.retry_save(store)
	h.check("resolution commits", committed["accepted"],
		str(committed.get("error_code", &"")))
	if not committed["accepted"]:
		_cleanup_production_slot()
		return
	state = committed["payload"]["state"]
	var receipt: CampaignResolution = committed["payload"]["result"]["receipt"]
	h.check("receipt SHA pinned",
		receipt.canonical_sha256()
		== "7a80c58cf5acf69959d774c245e4ccc9f5e972472c291b9541c6dc538912b312")
	h.check("resolved strategic hash pinned",
		state.strategic_hash()["hex"] == "5e0fba8ed23d6057")
	var duplicate := state.resolve_attempt(ticket, outcome, pending)
	h.check("duplicate accepted without freshness",
		duplicate["accepted"] and not duplicate["payload"]["fresh"])
	print("STRATEGIC_VERBS_COMPLETED")
	_cleanup_production_slot()
	h.done()


func _cleanup_production_slot() -> void:
	for path: String in [
		CampaignSaveStore.PRODUCTION_SLOT,
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".tmp",
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".bak",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _commit(
	h: SelfTestHarness,
	command: Dictionary,
	store: CampaignSaveStore,
) -> CampaignState:
	h.check("command accepted", command["accepted"],
		str(command.get("error_code", &"")))
	if not command["accepted"]:
		return null
	var committed := (command["payload"]["mutation"] as CampaignMutation).retry_save(store)
	h.check("command save committed", committed["accepted"],
		str(committed.get("error_code", &"")))
	return committed["payload"]["state"] if committed["accepted"] else null


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


func _definition() -> CampaignDef:
	return load("res://data/campaigns/p16_v1.tres") as CampaignDef


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
