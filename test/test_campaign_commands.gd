extends GutTest

const SLOT := "user://p162-command.json"

class MemoryOps extends CampaignFileOps:
	var files := {}
	var write_count := 0

	func file_exists(path: String) -> bool:
		return files.has(path)

	func read_bytes(path: String) -> Dictionary:
		if not files.has(path):
			return {"accepted": false, "error_code": &"file_missing", "bytes": PackedByteArray()}
		return {"accepted": true, "error_code": &"", "bytes": files[path]}

	func write_bytes(path: String, bytes: PackedByteArray) -> Dictionary:
		write_count += 1
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


class BrokenCommittedStore extends CampaignSaveStore:
	var called := false

	func save(_expected_pre_text: String, prospective_state: Variant) -> Dictionary:
		called = true
		return {
			"status": COMMITTED,
			"error_code": &"",
			"save_revision": prospective_state.save_revision(),
		}


func test_typed_wrappers_are_codec_strict_and_defensive() -> void:
	assert_false(CampaignMutation.new().has_method("create"))
	var state := _fresh()
	var begun := state.begin_attempt(&"s1", [_ready_ids(state)[0]])
	assert_true(begun["accepted"])
	var mutation: CampaignMutation = begun["payload"]["mutation"]
	var ticket: CampaignBattleTicket = mutation._result["ticket"]
	var row := ticket.data_copy()
	row["stage_id"] = "forged"
	assert_eq(String(ticket.stage_id()), "s1")
	row["extra"] = true
	assert_eq(CampaignBattleTicket.from_data(row)["error_code"], &"invalid_ticket_schema")
	var outcome := _outcome(ticket, &"defeat", [], 0)
	var copied := outcome.data_copy()
	copied["heroes"][0]["fell"] = true
	assert_false(outcome.heroes()[0]["fell"])


func test_recovery_offers_are_derived_ordered_and_nonpersistent() -> void:
	var state := _resolved()
	var before := _snapshot(state)
	var offered := state.recovery_offers(&"s2")
	assert_true(offered["accepted"])
	assert_eq(offered["offers"], [{
		"offer_id": "recovery:s2:defender_1",
		"operator_def_id": "defender_1",
		"cost": 0,
	}])
	assert_eq(_snapshot(state), before)
	assert_eq(state.recovery_offers(&"s1")["error_code"], &"stage_cleared")


func test_paid_recruit_commits_exact_economy_provenance_and_events() -> void:
	var state := _fresh()
	var harness := _seed_store(state)
	var command := state.recruit("p16_caster_contract")
	assert_true(command["accepted"])
	assert_eq(_event_names(command["events"]), [&"recruit_attempted"])
	var committed := _commit(command, harness["store"])
	assert_true(committed["accepted"])
	assert_eq(_event_names(committed["events"]), [
		&"autosave_attempted", &"autosave_succeeded", &"hero_created", &"recruit_accepted",
	])
	var after: CampaignState = committed["payload"]["state"]
	assert_eq(after.marks(), 40)
	assert_true(after.offer("p16_caster_contract")["consumed"])
	var hero := after.roster().all()[-1]
	assert_eq(hero.recruit_source(), &"contract")
	assert_eq(hero.source_id(), "p16_caster_contract")
	assert_eq(hero.recruited_after_resolution_index(), 0)


func test_recovery_recruit_commits_without_marks_or_persisted_offer() -> void:
	var state := _resolved()
	var harness := _seed_store(state)
	var command := state.recruit("recovery:s2:defender_1")
	assert_true(command["accepted"])
	var committed := _commit(command, harness["store"])
	assert_true(committed["accepted"])
	var after: CampaignState = committed["payload"]["state"]
	assert_eq(after.marks(), state.marks())
	assert_eq(after.offers(), state.offers())
	var hero := after.roster().all()[-1]
	assert_eq(hero.recruit_source(), &"recovery")
	assert_eq(hero.source_id(), "s2")
	assert_eq(hero.recruited_after_resolution_index(), 1)
	assert_true(after.recovery_offers(&"s2")["offers"].is_empty())


func test_recruit_rejections_are_exact_and_state_equal() -> void:
	var fresh := _fresh()
	_assert_rejected_unchanged(fresh, fresh.recruit("missing"), &"unknown_offer")
	var consumed := _commit_state(fresh.recruit("p16_caster_contract"), fresh)
	_assert_rejected_unchanged(
		consumed, consumed.recruit("p16_caster_contract"), &"offer_consumed",
	)
	_assert_rejected_unchanged(
		fresh, fresh.recruit("recovery:s2:defender_1"), &"stage_locked",
	)
	_assert_rejected_unchanged(
		fresh, fresh.recruit("recovery:s1:vanguard_1"), &"recovery_not_available",
	)


func test_rename_trims_commits_and_preserves_default_identity() -> void:
	var state := _fresh()
	var hero := state.roster().all()[0]
	var default_name := String(hero.display_callsign()["value"])
	var committed := _commit_state(state.rename_hero(hero.hero_id(), "  Nova\t"), state)
	var renamed := committed.roster().by_id(hero.hero_id())
	assert_eq(renamed.custom_callsign(), "Nova")
	assert_eq(renamed.default_name()["value"], default_name)


func test_rename_rejects_empty_unchanged_duplicate_and_unknown() -> void:
	var state := _fresh()
	var ids := _ready_ids(state)
	_assert_rejected_unchanged(state, state.rename_hero("missing", "Nova"), &"unknown_hero")
	_assert_rejected_unchanged(state, state.rename_hero(ids[0], " \t "), &"invalid_callsign")
	var named := _commit_state(state.rename_hero(ids[0], "Nova"), state)
	_assert_rejected_unchanged(named, named.rename_hero(ids[0], "Nova"), &"callsign_unchanged")
	_assert_rejected_unchanged(named, named.rename_hero(ids[1], "nOvA"), &"duplicate_callsign")


func test_begin_commits_ordered_manifest_and_state_bound_capability() -> void:
	var state := _fresh()
	var ids := _ready_ids(state)
	var harness := _seed_store(state)
	var command := state.begin_attempt(&"s1", [ids[2], ids[0]])
	assert_true(command["accepted"])
	var committed := _commit(command, harness["store"])
	assert_true(committed["accepted"])
	var after: CampaignState = committed["payload"]["state"]
	var pending: CampaignPendingAttempt = committed["payload"]["result"]["pending_attempt"]
	assert_eq(after.pending_attempt(), pending)
	assert_eq(pending.status(), &"active")
	assert_eq(pending.ticket().manifest()[0]["battle_id"], ids[2])
	assert_eq(after.next_attempt_id(), 2)
	assert_eq(after.save_revision(), 2)


func test_begin_rejections_follow_exact_precedence_and_do_not_mutate() -> void:
	var state := _fresh()
	var ids := _ready_ids(state)
	_assert_rejected_unchanged(state, state.begin_attempt(9, []), &"unknown_campaign_stage")
	_assert_rejected_unchanged(state, state.begin_attempt(&"s2", []), &"stage_locked")
	_assert_rejected_unchanged(state, state.begin_attempt(&"s1", []), &"empty_squad")
	_assert_rejected_unchanged(
		state, state.begin_attempt(&"s1", [ids[0], ids[0]]), &"duplicate_hero",
	)
	_assert_rejected_unchanged(state, state.begin_attempt(&"s1", ["missing"]), &"unknown_hero")


func test_pending_attempt_blocks_recruit_rename_and_second_begin() -> void:
	var state := _fresh()
	var begun := _commit_state(state.begin_attempt(&"s1", [_ready_ids(state)[0]]), state)
	_assert_rejected_unchanged(begun, begun.recruit("p16_caster_contract"), &"attempt_pending")
	_assert_rejected_unchanged(
		begun, begun.rename_hero(_ready_ids(begun)[0], "Nova"), &"attempt_pending",
	)
	_assert_rejected_unchanged(
		begun, begun.begin_attempt(&"s1", [_ready_ids(begun)[0]]), &"attempt_pending",
	)


func test_mutation_abandon_restores_exact_preimage_without_touching_store() -> void:
	var state := _fresh()
	var before := _snapshot(state)
	var command := state.recruit("p16_caster_contract")
	var mutation: CampaignMutation = command["payload"]["mutation"]
	var abandoned := mutation.abandon()
	assert_true(abandoned["accepted"])
	assert_eq(abandoned["payload"]["status"], "abandoned")
	assert_eq(_snapshot(abandoned["payload"]["state"]), before)
	assert_eq(_event_names(abandoned["events"]), [&"strategic_mutation_abandoned"])
	assert_eq(mutation.status(), &"abandoned")


func test_committed_mutation_is_terminal_and_restore_has_no_pending_capability() -> void:
	var state := _fresh()
	var harness := _seed_store(state)
	var command := state.begin_attempt(&"s1", [_ready_ids(state)[0]])
	var mutation: CampaignMutation = command["payload"]["mutation"]
	var committed := mutation.retry_save(harness["store"])
	assert_true(committed["accepted"])
	assert_eq(mutation.retry_save(harness["store"])["error_code"], &"mutation_not_pending")
	assert_eq(mutation.abandon()["error_code"], &"mutation_not_pending")
	var loaded: Dictionary = harness["store"].load()
	assert_true(loaded["accepted"])
	assert_false((loaded["state"] as CampaignState).has_pending_attempt())
	var blocked_command := state.rename_hero(_ready_ids(state)[0], "Nova")
	var blocked_mutation: CampaignMutation = blocked_command["payload"]["mutation"]
	var liar := BrokenCommittedStore.new()
	var false_commit := blocked_mutation.retry_save(liar)
	assert_false(false_commit["accepted"])
	assert_eq(false_commit["error_code"], &"invalid_save_store")
	assert_false(liar.called)
	assert_eq(blocked_mutation.status(), &"pending")
	var injected_ops := MemoryOps.new()
	injected_ops.files[SLOT] = state.encode_save()["bytes"]
	var injected := CampaignSaveStore.create(SLOT, state.restore_factory(), injected_ops)
	assert_true(injected["accepted"])
	false_commit = blocked_mutation.retry_save(injected["value"])
	assert_false(false_commit["accepted"])
	assert_eq(false_commit["error_code"], &"invalid_save_store")
	assert_eq(injected_ops.write_count, 0)


func _fresh() -> CampaignState:
	var created := CampaignState.create(42, 1, _definition(), _catalogs(), _stages())
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	return created["value"]


func _resolved() -> CampaignState:
	var source := FileAccess.get_file_as_string("res://test/fixtures/p16/transaction_vectors_v1.json")
	var parser := JSON.new()
	assert_eq(parser.parse(source), OK)
	var exact := CanonicalJson.restore_exact_integers(source, parser.data)
	var data: Dictionary = exact["value"]["resolved_save"]["value"]
	var restored := CampaignState.restore(data, _definition(), _catalogs(), _stages())
	assert_true(restored["accepted"])
	return restored["value"]


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
		var absolute := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(absolute)


func _commit(command: Dictionary, store: CampaignSaveStore) -> Dictionary:
	assert_true(command["accepted"], str(command.get("error_code", &"")))
	return (command["payload"]["mutation"] as CampaignMutation).retry_save(store)


func _commit_state(command: Dictionary, before: CampaignState) -> CampaignState:
	var harness := _seed_store(before)
	var committed := _commit(command, harness["store"])
	assert_true(committed["accepted"], str(committed.get("error_code", &"")))
	return committed["payload"]["state"]


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
	var names: Array[StringName] = []
	for event: Dictionary in events:
		names.append(event["name"])
	return names


func _ready_ids(state: CampaignState) -> Array[String]:
	var ids: Array[String] = []
	for hero: HeroState in state.roster().ready():
		ids.append(hero.hero_id())
	return ids


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
