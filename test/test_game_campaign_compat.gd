extends GutTest

const GameScript := preload("res://autoloads/game.gd")


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
	_cleanup_slot()
	var game := GameScript.new()
	assert_true(game.start_campaign(false))
	var campaign: CampaignStateV3 = game.campaign
	var before := String(campaign.encode_save()["text"])
	assert_eq(game.loadout_operator_ids(), [&"recruit"])
	assert_eq((game.call("loadout_trap_ids") as Array).size(), 0)
	assert_eq((game.call("loadout_spell_ids") as Array).size(), 0)

	game.call("_debug_unlock_all")
	assert_true(bool(game.get("_debug_catalog_override")))
	assert_eq((game.call("loadout_operator_ids") as Array).size(), 12)
	assert_eq((game.call("loadout_trap_ids") as Array).size(), 2)
	assert_eq((game.call("loadout_spell_ids") as Array).size(), 2)
	assert_eq(campaign.encode_save()["text"], before)

	assert_true(game.start_campaign(false))
	assert_false(bool(game.get("_debug_catalog_override")))
	assert_eq(game.loadout_operator_ids(), [&"recruit"])
	assert_eq(game.campaign.encode_save()["text"], before)
	var resumed_generation: int = game.campaign.campaign_generation()
	var resumed_uid: String = game.campaign.campaign_uid()
	assert_true(game.start_campaign(false, true))
	assert_eq(game.campaign.campaign_generation(), resumed_generation + 1)
	assert_ne(game.campaign.campaign_uid(), resumed_uid)
	assert_eq(game.loadout_operator_ids(), [&"recruit"])
	game.free()
	_cleanup_slot()


func test_legacy_slot_rolls_into_a_playable_recruit_generation() -> void:
	_cleanup_slot()
	var legacy_text := FileAccess.get_file_as_string(
		"res://test/fixtures/p16/campaign_v1_seed42.json"
	)
	var file := FileAccess.open(CampaignSaveStore.PRODUCTION_SLOT, FileAccess.WRITE)
	assert_not_null(file)
	file.store_string(legacy_text)
	file.close()
	var game := GameScript.new()
	game.set_run_seed(42)
	assert_true(game.start_campaign(false))
	assert_eq(game.campaign.campaign_generation(), 2)
	var ready: Array = game.campaign_projection()["ready_heroes"]
	assert_eq(ready.size(), 5)
	var ids: Array[StringName] = []
	for hero: Dictionary in ready.slice(0, 3):
		assert_eq(hero["operator_def_id"], "recruit")
		ids.append(StringName(hero["hero_id"]))
	var begun: Dictionary = game.start_stage(&"s1", ids, false)
	assert_true(begun["accepted"], str(begun.get("error_code", &"")))
	assert_eq(game.campaign.save_revision(), 2)
	game.free()
	_cleanup_slot()


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


func _cleanup_slot() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path("user://campaign_v1.json%s" % suffix)
		)
