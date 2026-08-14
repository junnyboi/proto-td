extends GutTest


func test_legacy_adapter_preserves_exact_start_and_first_clear_behavior() -> void:
	var adapter: LegacyCampaignAdapter = LegacyCampaignAdapter.create(_catalogs(), _stages())
	assert_eq(adapter.unlocked_operators, [
		&"caster_1", &"defender_1", &"defender_2", &"guard_1", &"vanguard_1",
	])
	assert_eq(adapter.unlocked_traps, [])
	assert_eq(adapter.unlocked_spells, [])
	assert_true(adapter.is_stage_unlocked(&"s1"))
	assert_false(adapter.is_stage_unlocked(&"s2"))
	var stage := load("res://data/stages/s1.tres") as StageDef
	var granted: Array[Dictionary] = adapter.record_result(
		stage, BattleModel.Result.CLEAR, 3,
	)
	assert_eq(granted, stage.rewards)
	assert_eq(adapter.stage_stars, {&"s1": 3})
	assert_true(adapter.unlocked_operators.has(&"guard_2"))
	assert_true(adapter.is_stage_unlocked(&"s2"))
	assert_true(adapter.record_result(stage, BattleModel.Result.CLEAR, 2).is_empty())
	assert_eq(adapter.stage_stars[&"s1"], 3)


func test_debug_unlock_is_projection_only_and_new_campaign_clears_it() -> void:
	var game := get_node("/root/Game")
	var saved := _save_game(game)
	game.call("start_campaign", false)
	var campaign: LegacyCampaignAdapter = game.get("campaign")
	var before := _legacy_snapshot(campaign)
	assert_eq((game.call("loadout_operator_ids") as Array).size(), 5)
	assert_eq((game.call("loadout_trap_ids") as Array).size(), 0)
	assert_eq((game.call("loadout_spell_ids") as Array).size(), 0)

	game.call("debug_unlock_all")
	assert_true(bool(game.get("_debug_catalog_override")))
	assert_eq((game.call("loadout_operator_ids") as Array).size(), 12)
	assert_eq((game.call("loadout_trap_ids") as Array).size(), 2)
	assert_eq((game.call("loadout_spell_ids") as Array).size(), 2)
	assert_eq(_legacy_snapshot(campaign), before)

	game.call("start_campaign", false)
	assert_false(bool(game.get("_debug_catalog_override")))
	assert_eq((game.call("loadout_operator_ids") as Array).size(), 5)
	_restore_game(game, saved)


func _legacy_snapshot(campaign: LegacyCampaignAdapter) -> Dictionary:
	return {
		"operators": campaign.unlocked_operators.duplicate(),
		"traps": campaign.unlocked_traps.duplicate(),
		"spells": campaign.unlocked_spells.duplicate(),
		"stars": campaign.stage_stars.duplicate(true),
	}


func _save_game(game: Node) -> Dictionary:
	return {
		"campaign": game.get("campaign"),
		"campaign_active": game.get("campaign_active"),
		"pending_stage": game.get("pending_stage"),
		"current_battle": game.get("current_battle"),
		"selected_stage_id": game.get("selected_stage_id"),
		"selected_squad": (game.get("selected_squad") as Array).duplicate(),
		"last_result": (game.get("last_result") as Dictionary).duplicate(true),
		"debug_override": game.get("_debug_catalog_override"),
	}


func _restore_game(game: Node, saved: Dictionary) -> void:
	game.set("campaign", saved["campaign"])
	game.set("campaign_active", saved["campaign_active"])
	game.set("pending_stage", saved["pending_stage"])
	game.set("current_battle", saved["current_battle"])
	game.set("selected_stage_id", saved["selected_stage_id"])
	game.set("selected_squad", saved["selected_squad"])
	game.set("last_result", saved["last_result"])
	game.set("_debug_catalog_override", saved["debug_override"])


func _catalogs() -> Dictionary:
	return {
		"operators": _catalog_ids("res://data/operators"),
		"traps": _catalog_ids("res://data/traps"),
		"spells": _catalog_ids("res://data/spells"),
	}


func _stages() -> Array:
	var stages: Array = []
	for stage_id: StringName in _catalog_ids("res://data/stages"):
		stages.append(load("res://data/stages/%s.tres" % stage_id) as StageDef)
	return stages


func _catalog_ids(path: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			ids.append(StringName(source.trim_suffix(".tres")))
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		return String(a) < String(b))
	return ids
