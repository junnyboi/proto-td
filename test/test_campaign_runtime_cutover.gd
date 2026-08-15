extends GutTest

const GameScript := preload("res://autoloads/game.gd")
const ContextScript := preload("res://sim/campaign_runtime_context.gd")
const S1 := preload("res://data/stages/s1.tres")
const CONFIG := preload("res://data/config/game.tres")
const MAX_TICKS := 2_400

var _game: Node = null


class MockBattleView:
	extends Node2D

	func grid_scale() -> float:
		return 1.0


func before_each() -> void:
	_cleanup_slot()
	_game = GameScript.new()
	_game.set_run_seed(42)


func after_each() -> void:
	_cleanup_slot()
	_game.free()
	_game = null


func test_fresh_runtime_owns_five_distinct_recruits_and_durable_ticket() -> void:
	assert_true(_game.start_campaign(false))
	assert_true(_game.campaign is CampaignStateV3)
	var projection: Dictionary = _game.campaign_projection()
	assert_eq(projection["ready_heroes"].size(), 5)
	var hero_ids: Array[StringName] = []
	var portraits := {}
	for index: int in 5:
		var hero: Dictionary = projection["ready_heroes"][index]
		hero_ids.append(StringName(hero["hero_id"]))
		portraits[hero["portrait_asset_id"]] = true
		assert_eq(hero["recruitment_index"], index)
		assert_eq(hero["current_class_id"], "recruit")
		assert_eq(hero["operator_def_id"], "recruit")
		assert_eq(hero["portrait_instance_id"], "portrait:%s" % hero["hero_id"])
	assert_eq(portraits.size(), 5)
	var before_text: String = _game.campaign.encode_save()["text"]
	var begun: Dictionary = _game.start_stage(&"s1", hero_ids.slice(0, 3), false)
	assert_true(begun["accepted"], str(begun.get("error_code", &"")))
	assert_eq(_game.campaign.save_revision(), 2)
	assert_ne(_game.campaign.encode_save()["text"], before_text)
	var launch: Dictionary = _game.battle_launch()
	var ticket: Dictionary = launch["input"]
	assert_eq(ticket, begun["ticket"])
	assert_eq(launch["trusted_ticket_hashes"], [ticket["ticket_hash"]])
	assert_eq(ticket["squad"].size(), 3)
	assert_ne(ticket["squad"][0]["hero_id"], ticket["squad"][1]["hero_id"])
	assert_ne(ticket["squad"][0]["battle_id"], ticket["squad"][1]["battle_id"])
	var loaded: Dictionary = _game.campaign_store.load()
	assert_true(loaded["accepted"])
	assert_eq(loaded["state"].encode_save()["text"], _game.campaign.encode_save()["text"])


func test_restart_after_durable_begin_restores_exact_ticket_and_resolves() -> void:
	assert_true(_game.start_campaign(false))
	var hero_ids: Array[StringName] = []
	for hero: Dictionary in _game.campaign_projection()["ready_heroes"].slice(0, 3):
		hero_ids.append(StringName(hero["hero_id"]))
	var begun: Dictionary = _game.start_stage(&"s1", hero_ids, false)
	assert_true(begun["accepted"])
	var ticket: Dictionary = begun["ticket"]
	var begun_text: String = _game.campaign.encode_save()["text"]
	_game.free()
	_game = GameScript.new()
	_game.set_run_seed(42)
	assert_true(_game.start_campaign(false))
	assert_eq(_game.campaign.encode_save()["text"], begun_text)
	assert_eq(_game.selected_stage_id, &"s1")
	assert_eq(_game.selected_squad, hero_ids)
	var launch: Dictionary = _game.battle_launch()
	assert_eq(launch["input"], ticket)
	assert_eq(launch["trusted_ticket_hashes"], [ticket["ticket_hash"]])
	var model := _model_from_launch(launch)
	assert_not_null(model)
	_game.current_battle = model
	_run(model, _winner(ticket))
	assert_eq(model.result, BattleModel.Result.CLEAR)
	assert_true(_game.record_result(model.result, model.stars))
	assert_eq(_game.campaign.save_revision(), 3)
	assert_eq(_game.campaign.next_attempt_id(), _game.campaign.next_resolution_index())


func test_player_battle_resolves_model_outcome_and_reloads_exact_authority() -> void:
	assert_true(_game.start_campaign(false))
	var initial: Array = _game.campaign_projection()["ready_heroes"]
	var hero_ids: Array[StringName] = []
	for hero: Dictionary in initial.slice(0, 3):
		hero_ids.append(StringName(hero["hero_id"]))
	var begun: Dictionary = _game.start_stage(&"s1", hero_ids, false)
	assert_true(begun["accepted"])
	var ticket: Dictionary = begun["ticket"]
	var model := _model_from_launch(_game.battle_launch())
	assert_not_null(model)
	_game.current_battle = model
	_run(model, _winner(ticket))
	assert_eq(model.result, BattleModel.Result.CLEAR)
	assert_true(_game.record_result(model.result, model.stars))
	assert_eq(_game.campaign.save_revision(), 3)
	assert_eq(_game.campaign_projection()["stage_stars"][&"s1"], model.stars)
	assert_eq(_game.last_result["xp_awards"].size(), 1)
	assert_eq(_game.last_result["dead_hero_ids"].size(), 2)
	var all_rows: Array = _game.campaign.data_copy()["heroes"]
	assert_eq(all_rows.size(), 5)
	for index: int in 5:
		assert_eq(all_rows[index]["hero_id"], initial[index]["hero_id"])
	var persisted: Dictionary = _game.campaign_store.load()
	assert_true(persisted["accepted"])
	assert_eq(persisted["state"].encode_save()["text"], _game.campaign.encode_save()["text"])
	var dead_id := StringName(_game.last_result["dead_hero_ids"][0])
	var before_reject := _authority_facts()
	var dead: Dictionary = _game.start_stage(&"s1", [dead_id] as Array[StringName], false)
	assert_false(dead["accepted"])
	assert_eq(_authority_facts(), before_reject)


func test_campaign_results_ignore_mismatched_caller_terminal_facts() -> void:
	assert_true(_game.start_campaign(false))
	var hero_ids: Array[StringName] = []
	for hero: Dictionary in _game.campaign_projection()["ready_heroes"].slice(0, 3):
		hero_ids.append(StringName(hero["hero_id"]))
	var begun: Dictionary = _game.start_stage(&"s1", hero_ids, false)
	assert_true(begun["accepted"])
	var model := _model_from_launch(_game.battle_launch())
	assert_not_null(model)
	_game.current_battle = model
	_run(model, _winner(begun["ticket"]))
	assert_eq(model.result, BattleModel.Result.CLEAR)
	assert_true(_game.record_result(BattleModel.Result.DEFEAT, 0))
	assert_eq(_game.last_result["stage_id"], &"s1")
	assert_eq(_game.last_result["result"], BattleModel.Result.CLEAR)
	assert_eq(_game.last_result["stars"], model.stars)
	assert_eq(_game.last_result["leaks"], model.leaked)
	assert_eq(_game.last_result["kills"], model.killed)
	assert_eq(_game.campaign_projection()["stage_stars"][&"s1"], model.stars)


func test_campaign_result_retry_uses_original_accepted_outcome() -> void:
	assert_true(_game.start_campaign(false))
	var hero_ids: Array[StringName] = []
	for hero: Dictionary in _game.campaign_projection()["ready_heroes"].slice(0, 3):
		hero_ids.append(StringName(hero["hero_id"]))
	var begun: Dictionary = _game.start_stage(&"s1", hero_ids, false)
	assert_true(begun["accepted"])
	var model := _model_from_launch(_game.battle_launch())
	assert_not_null(model)
	_game.current_battle = model
	_run(model, _winner(begun["ticket"]))
	assert_eq(model.result, BattleModel.Result.CLEAR)
	var accepted_outcome: Dictionary = model.snapshot()["outcome"].duplicate(true)
	assert_true(_game.campaign_store._is_authority_store())
	var tmp_path := ProjectSettings.globalize_path("user://campaign_v1.tmp")
	assert_eq(DirAccess.make_dir_absolute(tmp_path), OK)
	assert_false(_game.record_result(BattleModel.Result.DEFEAT, 0))
	assert_eq(_game.last_campaign_error, &"store_write_failed")
	assert_eq(DirAccess.remove_absolute(tmp_path), OK)
	var conflicting_outcome: Dictionary = accepted_outcome.duplicate(true)
	conflicting_outcome["result"] = "defeat"
	conflicting_outcome["terminal_reason"] = "base_defeat"
	conflicting_outcome["stars"] = 0
	conflicting_outcome["leaks"] = 999
	conflicting_outcome["kills"] = 0
	model._outcome = conflicting_outcome
	assert_true(_game.record_result(BattleModel.Result.DEFEAT, 0))
	assert_eq(_game.last_result["stage_id"], &"s1")
	assert_eq(_game.last_result["result"], BattleModel.Result.CLEAR)
	for key: String in ["stars", "leaks", "kills"]:
		assert_eq(_game.last_result[key], accepted_outcome[key])
	assert_eq(_game.campaign_projection()["stage_stars"][&"s1"], accepted_outcome["stars"])


func test_rejected_stage_and_squad_requests_leave_every_authority_fact_exact() -> void:
	assert_true(_game.start_campaign(false))
	var hero_id := StringName(_game.campaign_projection()["ready_heroes"][0]["hero_id"])
	var one: Array[StringName] = [hero_id]
	var duplicate_ids: Array[StringName] = [hero_id, hero_id]
	var unknown_ids: Array[StringName] = [&"0000000000000000"]
	var empty_ids: Array[StringName] = []
	var over_capacity: Array[StringName] = []
	for hero: Dictionary in _game.campaign_projection()["ready_heroes"].slice(0, 4):
		over_capacity.append(StringName(hero["hero_id"]))
	var before := _authority_facts()
	var empty: Dictionary = _game.start_stage(&"s1", empty_ids, false)
	assert_false(empty["accepted"])
	assert_eq(_authority_facts(), before)
	var over: Dictionary = _game.start_stage(&"s1", over_capacity, false)
	assert_false(over["accepted"])
	assert_eq(_authority_facts(), before)
	var locked: Dictionary = _game.start_stage(&"s2", one, false)
	assert_false(locked["accepted"])
	assert_eq(locked["error_code"], &"stage_locked")
	assert_eq(_authority_facts(), before)
	var duplicate: Dictionary = _game.start_stage(&"s1", duplicate_ids, false)
	assert_false(duplicate["accepted"])
	assert_eq(_authority_facts(), before)
	var unknown: Dictionary = _game.start_stage(&"s1", unknown_ids, false)
	assert_false(unknown["accepted"])
	assert_eq(_authority_facts(), before)
	var stale: Dictionary = _game.campaign.begin_attempt("p4-stale", &"s1", one, 42, 2)
	assert_false(stale["accepted"])
	assert_eq(stale["error_code"], &"stale_revision")
	assert_eq(_authority_facts(), before)


func test_ticket_deploy_bar_keeps_duplicate_recruit_people_as_distinct_slots() -> void:
	assert_true(_game.start_campaign(false))
	var ids: Array[StringName] = []
	for hero: Dictionary in _game.campaign_projection()["ready_heroes"].slice(0, 3):
		ids.append(StringName(hero["hero_id"]))
	assert_true(_game.start_stage(&"s1", ids, false)["accepted"])
	var model := _model_from_launch(_game.battle_launch())
	var bar := DeployBar.new()
	var view := MockBattleView.new()
	add_child_autofree(bar)
	add_child_autofree(view)
	bar.setup(model, view, _catalog("res://data/operators"))
	assert_eq(bar._slots.size(), 3)
	assert_eq(bar._slots.keys(), model.battle_squad)
	for battle_id: StringName in model.battle_squad:
		assert_true(bar._slots.has(battle_id))


func test_direct_debug_battle_cannot_mutate_campaign_authority() -> void:
	assert_true(_game.start_campaign(false))
	var before := _authority_facts()
	_game.start_battle(&"s1", false)
	var launch: Dictionary = _game.battle_launch()
	assert_true(typeof(launch["input"]) == TYPE_ARRAY)
	assert_eq(launch["trusted_ticket_hashes"], [])
	var model := _model_from_launch(launch)
	assert_not_null(model)
	_game.current_battle = model
	assert_true(model.apply_action([&"resign"]))
	assert_true(_game.record_result(model.result, model.stars))
	assert_eq(_authority_facts(), before)


func _authority_facts() -> Dictionary:
	return {
		"text": _game.campaign.encode_save()["text"],
		"strategic": _game.campaign.strategic_hash(),
		"core": _game.campaign.core_hash(),
		"revision": _game.campaign.save_revision(),
		"selection": _game.selected_squad.duplicate(),
		"stage": _game.selected_stage_id,
	}


func _model_from_launch(launch: Dictionary) -> BattleModel:
	return (
		BattleModel
		. create(
			S1 as StageDef,
			launch["input"],
			42,
			CONFIG as GameConfig,
			_catalog("res://data/enemies"),
			_catalog("res://data/operators"),
			_catalog("res://data/traps"),
			_catalog("res://data/spells"),
			launch["trusted_ticket_hashes"],
		)
	)


func _winner(ticket: Dictionary) -> Array:
	return [
		[6, &"deploy", StringName(ticket["squad"][0]["battle_id"]), Vector2i(3, 2), 0],
		[180, &"deploy", StringName(ticket["squad"][1]["battle_id"]), Vector2i(1, 2), 0],
		[420, &"deploy", StringName(ticket["squad"][2]["battle_id"]), Vector2i(2, 2), 0],
	]


func _run(model: BattleModel, timeline: Array) -> void:
	var index := 0
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		while index < timeline.size() and int(timeline[index][0]) == model.tick:
			assert_true(model.apply_action((timeline[index] as Array).slice(1)))
			index += 1
		model.step()
	assert_eq(index, timeline.size())


func _catalog(path: String) -> Dictionary:
	var result := {}
	var directory := DirAccess.open(path)
	for filename: String in directory.get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var resource: Resource = load("%s/%s" % [path, source])
			result[resource.get("id")] = resource
	return result


func _cleanup_slot() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path("user://campaign_v1.json%s" % suffix)
		)
