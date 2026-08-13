extends GutTest

const SLOT := "user://p162-resolution.json"

class MemoryOps extends CampaignFileOps:
	var files := {}
	var fail_write_count := 0

	func file_exists(path: String) -> bool:
		return files.has(path)

	func read_bytes(path: String) -> Dictionary:
		if not files.has(path):
			return {"accepted": false, "error_code": &"file_missing", "bytes": PackedByteArray()}
		return {"accepted": true, "error_code": &"", "bytes": files[path]}

	func write_bytes(path: String, bytes: PackedByteArray) -> Dictionary:
		if fail_write_count > 0:
			fail_write_count -= 1
			return {"accepted": false, "error_code": &"injected"}
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


func test_fresh_clear_derives_receipt_reward_death_anchor_and_events() -> void:
	var begun := _begun()
	var state: CampaignState = begun["state"]
	var pending: CampaignPendingAttempt = begun["pending"]
	var ticket := pending.ticket()
	var outcome := _outcome(ticket, &"clear", [ticket.manifest()[0]["battle_id"]], 3)
	var command := state.resolve_attempt(ticket, outcome, pending)
	assert_true(command["accepted"])
	var committed := _commit(command, begun["store"])
	assert_true(committed["accepted"], str(committed.get("error_code", &"")))
	var after: CampaignState = committed["payload"]["state"]
	var receipt: CampaignResolution = committed["payload"]["result"]["receipt"]
	assert_true(committed["payload"]["result"]["fresh"])
	assert_eq(receipt.resolution_index(), 1)
	assert_eq(receipt.stars_before(), 0)
	assert_eq(receipt.stars_after(), 3)
	assert_eq(receipt.created_hero_ids().size(), 1)
	assert_eq(receipt.dead_hero_ids(), [ticket.manifest()[0]["battle_id"]])
	assert_eq(after.data_copy()["resolution_anchor"]["strategic_body_hash_after"],
		receipt.strategic_body_hash_after())
	assert_eq(_event_names(committed["events"]), [
		&"autosave_attempted", &"autosave_succeeded", &"campaign_resolution_committed",
		&"hero_fallen", &"permanent_death_committed",
	])
	assert_eq(pending.status(), &"resolved")


func test_fresh_defeat_commits_zero_stars_rewards_and_deaths() -> void:
	var begun := _begun()
	var pending: CampaignPendingAttempt = begun["pending"]
	var outcome := _outcome(pending.ticket(), &"defeat", [], 0)
	var committed := _commit(
		(begun["state"] as CampaignState).resolve_attempt(pending.ticket(), outcome, pending),
		begun["store"],
	)
	assert_true(committed["accepted"])
	var receipt: CampaignResolution = committed["payload"]["result"]["receipt"]
	assert_eq(receipt.stars_after(), 0)
	assert_true(receipt.rewards_granted().is_empty())
	assert_true(receipt.created_hero_ids().is_empty())
	assert_true(receipt.dead_hero_ids().is_empty())


func test_same_outcome_duplicate_returns_receipt_without_mutation_or_pending() -> void:
	var resolved := _resolved_once(&"defeat", [], 0)
	var state: CampaignState = resolved["state"]
	var before := _snapshot(state)
	var duplicate := state.resolve_attempt(
		resolved["ticket"], resolved["outcome"], resolved["pending"],
	)
	assert_true(duplicate["accepted"])
	assert_false(duplicate["payload"]["fresh"])
	assert_true(duplicate["payload"]["receipt"] is CampaignResolution)
	assert_eq(_event_names(duplicate["events"]), [&"resolution_duplicate_observed"])
	assert_eq(_snapshot(state), before)


func test_duplicate_attempt_with_different_outcome_hash_rejects_exactly() -> void:
	var resolved := _resolved_once(&"defeat", [], 0)
	var state: CampaignState = resolved["state"]
	var forged := (resolved["outcome"] as BattleOutcome).data_copy()
	forged["terminal_tick"] = 121
	forged["outcome_hash"] = CanonicalJson.sha256_hex(_without_key(forged, "outcome_hash"))
	var mismatch := BattleOutcome.from_data(forged)
	assert_true(mismatch["accepted"])
	_assert_rejected_unchanged(
		state,
		state.resolve_attempt(resolved["ticket"], mismatch["value"], resolved["pending"]),
		&"resolved_attempt_mismatch",
	)


func test_full_ticket_and_outcome_codec_rejection_precedes_capability_checks() -> void:
	var state := _fresh()
	var ticket := {
		"campaign_uid": state.campaign_uid(),
		"attempt_id": 1,
		"stage_id": "s1",
		"manifest": [],
		"manifest_hash": "0".repeat(64),
		"extra": true,
	}
	assert_eq(state.resolve_attempt(ticket, {}, null)["error_code"], &"invalid_ticket_schema")
	var begun := _begun()
	var pending: CampaignPendingAttempt = begun["pending"]
	assert_eq(
		(begun["state"] as CampaignState).resolve_attempt(pending.ticket(), {}, pending)["error_code"],
		&"invalid_outcome_schema",
	)
	var typed_ticket: CampaignBattleTicket = CampaignBattleTicket.from_data(
		pending.ticket().data_copy(),
	)["value"]
	typed_ticket._data["extra"] = true
	assert_eq(
		(begun["state"] as CampaignState).resolve_attempt(typed_ticket, {}, pending)["error_code"],
		&"invalid_ticket_schema",
	)
	var typed_outcome := _outcome(pending.ticket(), &"defeat", [], 0)
	typed_outcome._data["extra"] = true
	assert_eq(
		(begun["state"] as CampaignState).resolve_attempt(
			pending.ticket(), typed_outcome, pending,
		)["error_code"],
		&"invalid_outcome_schema",
	)


func test_wrong_campaign_precedes_duplicate_and_capability() -> void:
	var begun := _begun()
	var pending: CampaignPendingAttempt = begun["pending"]
	var ticket_data := pending.ticket().data_copy()
	ticket_data["campaign_uid"] = "0000000000000001"
	var ticket_result := CampaignBattleTicket.from_data(ticket_data)
	var outcome := _outcome(ticket_result["value"], &"defeat", [], 0)
	var result := (begun["state"] as CampaignState).resolve_attempt(
		ticket_result["value"], outcome, null,
	)
	assert_eq(result["error_code"], &"wrong_campaign")


func test_absent_foreign_and_restored_capabilities_reject_without_mutation() -> void:
	var begun := _begun()
	var state: CampaignState = begun["state"]
	var pending: CampaignPendingAttempt = begun["pending"]
	assert_false(state.has_method("issuer_ref"))
	assert_false(state.has_method("attach_pending_attempt"))
	for forbidden: String in [
		"_issue", "_reserve", "_release_reservation", "_mark_resolved", "_mark_aborted",
	]:
		assert_false(pending.has_method(forbidden))
	var outcome := _outcome(pending.ticket(), &"defeat", [], 0)
	_assert_rejected_unchanged(
		state, state.resolve_attempt(pending.ticket(), outcome, null), &"no_pending_ticket",
	)
	var other := _begun()
	_assert_rejected_unchanged(
		state, state.resolve_attempt(pending.ticket(), outcome, other["pending"]),
		&"no_pending_ticket",
	)
	var restored := _restore(state.data_copy())
	assert_false(state.restored_copy_without_pending().has("pending_issue"))
	var public_restore := CampaignState.restore(
		state.data_copy(), _definition(), _catalogs(), _stages(),
	)
	assert_false(public_restore.has("pending_issue"))
	var factory_restore: Dictionary = state.restore_factory().call(state.encode_save()["text"])
	assert_true(factory_restore["accepted"])
	assert_false(factory_restore.has("pending_issue"))
	var factory_state: CampaignState = factory_restore["value"]
	assert_false(factory_state.has_pending_attempt())
	assert_eq(
		factory_state.resolve_attempt(pending.ticket(), outcome, pending)["error_code"],
		&"no_pending_ticket",
	)
	_assert_rejected_unchanged(
		restored, restored.resolve_attempt(pending.ticket(), outcome, pending), &"no_pending_ticket",
	)


func test_attempt_precedes_pending_state_hash_mismatch() -> void:
	var begun := _begun()
	var state: CampaignState = begun["state"]
	var pending: CampaignPendingAttempt = begun["pending"]
	state._data["marks"] = state.marks() + 1
	var before := CanonicalJson.text(state.data_copy())
	var wrong_ticket := _ticket_variant(pending.ticket(), {"attempt_id": 2})
	var wrong_outcome := _outcome(wrong_ticket, &"defeat", [], 0)
	var result := state.resolve_attempt(wrong_ticket, wrong_outcome, pending)
	assert_eq(result["error_code"], &"wrong_attempt")
	var outcome := _outcome(pending.ticket(), &"defeat", [], 0)
	result = state.resolve_attempt(pending.ticket(), outcome, pending)
	assert_eq(result["error_code"], &"pending_state_mismatch")
	assert_eq(CanonicalJson.text(state.data_copy()), before)


func test_attempt_stage_manifest_and_counter_precedence_is_exact() -> void:
	var begun := _begun()
	var state: CampaignState = begun["state"]
	var pending: CampaignPendingAttempt = begun["pending"]
	var attempt_ticket := _ticket_variant(pending.ticket(), {"attempt_id": 2})
	var attempt_outcome := _outcome(attempt_ticket, &"defeat", [], 0)
	assert_eq(state.resolve_attempt(attempt_ticket, attempt_outcome, pending)["error_code"],
		&"wrong_attempt")
	var stage_ticket := _ticket_variant(pending.ticket(), {"stage_id": "s2"})
	var stage_outcome := _outcome(stage_ticket, &"defeat", [], 0)
	assert_eq(state.resolve_attempt(stage_ticket, stage_outcome, pending)["error_code"],
		&"stage_mismatch")
	var manifest := pending.ticket().manifest()
	manifest[0]["operator_def_id"] = "caster_2"
	var manifest_ticket := _ticket_variant(pending.ticket(), {
		"manifest": manifest,
		"manifest_hash": CanonicalJson.sha256_hex(manifest),
	})
	var manifest_outcome := _outcome(manifest_ticket, &"defeat", [], 0)
	assert_eq(state.resolve_attempt(manifest_ticket, manifest_outcome, pending)["error_code"],
		&"manifest_mismatch")


func test_resolution_abandon_aborts_attempt_and_requires_new_begin() -> void:
	var begun := _begun()
	var state: CampaignState = begun["state"]
	var pending: CampaignPendingAttempt = begun["pending"]
	var outcome := _outcome(pending.ticket(), &"defeat", [], 0)
	var command := state.resolve_attempt(pending.ticket(), outcome, pending)
	var mutation: CampaignMutation = command["payload"]["mutation"]
	assert_eq(mutation.status(), &"pending")
	assert_eq(pending.status(), &"reserved")
	var abandoned := mutation.abandon()
	assert_true(abandoned["accepted"])
	assert_eq(pending.status(), &"aborted")
	var restored: CampaignState = abandoned["payload"]["state"]
	assert_false(restored.has_pending_attempt())
	assert_eq(restored.resolve_attempt(pending.ticket(), outcome, pending)["error_code"],
		&"no_pending_ticket")
	var new_begin := restored.begin_attempt(&"s1", [_ready_ids(restored)[0]])
	assert_true(new_begin["accepted"])
	var new_ticket: CampaignBattleTicket = (
		(new_begin["payload"]["mutation"] as CampaignMutation)._result["ticket"]
	)
	assert_eq(new_ticket.attempt_id(), 2)


func _begun() -> Dictionary:
	var fresh := _fresh()
	var harness := _seed_store(fresh)
	var committed := _commit(
		fresh.begin_attempt(&"s1", [_ready_ids(fresh)[0]]), harness["store"],
	)
	assert_true(committed["accepted"])
	var state: CampaignState = committed["payload"]["state"]
	return {
		"state": state,
		"pending": state.pending_attempt(),
		"store": harness["store"],
	}


func _resolved_once(result: StringName, fallen: Array[String], stars: int) -> Dictionary:
	var begun := _begun()
	var pending: CampaignPendingAttempt = begun["pending"]
	var outcome := _outcome(pending.ticket(), result, fallen, stars)
	var committed := _commit(
		(begun["state"] as CampaignState).resolve_attempt(pending.ticket(), outcome, pending),
		begun["store"],
	)
	assert_true(committed["accepted"])
	return {
		"state": committed["payload"]["state"],
		"ticket": pending.ticket(),
		"outcome": outcome,
		"pending": pending,
	}


func _ticket_variant(ticket: CampaignBattleTicket, changes: Dictionary) -> CampaignBattleTicket:
	var data := ticket.data_copy()
	for key: String in changes:
		data[key] = changes[key]
	var created := CampaignBattleTicket.from_data(data)
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	return created["value"]


func _outcome(
	ticket: CampaignBattleTicket,
	result: StringName,
	fallen: Array[String],
	stars: int,
) -> BattleOutcome:
	var heroes: Array[Dictionary] = []
	for row: Dictionary in ticket.manifest():
		var fell := fallen.has(String(row["battle_id"]))
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
		"result": String(result),
		"terminal_reason": "clear" if result == &"clear" else "base_defeat",
		"stars": stars,
		"terminal_tick": 120,
		"model_state_hash": "0000000000000000",
		"heroes": heroes,
	}
	data["outcome_hash"] = CanonicalJson.sha256_hex(data)
	var created := BattleOutcome.from_data(data)
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	return created["value"]


func _without_key(data: Dictionary, key: String) -> Dictionary:
	var body := data.duplicate(true)
	body.erase(key)
	return body


func _seed_store(state: CampaignState) -> Dictionary:
	_cleanup_production_slot()
	var created := CampaignSaveStore.create_production(state)
	assert_true(created["accepted"])
	var store: CampaignSaveStore = created["value"]
	var file := FileAccess.open(CampaignSaveStore.PRODUCTION_SLOT, FileAccess.WRITE)
	assert_not_null(file)
	file.store_buffer(state.encode_save()["bytes"])
	file.close()
	return {"store": store}


func after_each() -> void:
	_cleanup_production_slot()


func _cleanup_production_slot() -> void:
	for path: String in [
		CampaignSaveStore.PRODUCTION_SLOT,
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".tmp",
		CampaignSaveStore.PRODUCTION_SLOT.get_basename() + ".bak",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _commit(command: Dictionary, store: CampaignSaveStore) -> Dictionary:
	assert_true(command["accepted"], str(command.get("error_code", &"")))
	return (command["payload"]["mutation"] as CampaignMutation).retry_save(store)


func _fresh() -> CampaignState:
	var created := CampaignState.create(42, 1, _definition(), _catalogs(), _stages())
	assert_true(created["accepted"])
	return created["value"]


func _restore(data: Dictionary) -> CampaignState:
	var restored := CampaignState.restore(data, _definition(), _catalogs(), _stages())
	assert_true(restored["accepted"])
	return restored["value"]


func _assert_rejected_unchanged(
	state: CampaignState,
	result: Dictionary,
	code: StringName,
) -> void:
	var before := _snapshot(state)
	assert_false(result["accepted"])
	assert_eq(result["error_code"], code)
	assert_eq(_snapshot(state), before)


func _snapshot(state: CampaignState) -> Array[String]:
	return [state.encode_save()["text"], state.strategic_hash()["hex"]]


func _event_names(events: Array) -> Array[StringName]:
	var values: Array[StringName] = []
	for event: Dictionary in events:
		values.append(event["name"])
	return values


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
