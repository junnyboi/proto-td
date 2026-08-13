extends SceneTree

const RESULT_PREFIX := "MODEL_ROSTER_RESULT="

var _reverse_inputs := false


func _init() -> void:
	_reverse_inputs = OS.get_cmdline_user_args().has("--reverse-inputs")
	call_deferred("_run")


func _run() -> void:
	var definition := load("res://data/campaigns/p16_v1.tres") as CampaignDef
	var catalogs := _catalogs()
	var stages := _stages()
	if _reverse_inputs:
		for key: String in catalogs:
			(catalogs[key] as Array).reverse()
		stages.reverse()
	var created := CampaignState.create(42, 1, definition, catalogs, stages)
	if not created["accepted"]:
		_fail(created["error_code"])
		return
	var state := created["value"] as CampaignState
	var paid := CampaignState.restore(_paid_data(state), definition, catalogs, stages)
	if not paid["accepted"]:
		_fail(paid["error_code"])
		return
	var paid_state := paid["value"] as CampaignState
	var fresh_preview := state.preview_first_clear_rewards(&"s1")
	var paid_preview := paid_state.preview_first_clear_rewards(&"s1")
	if not fresh_preview["accepted"] or not paid_preview["accepted"]:
		_fail(&"preview_rejected")
		return
	var heroes: Array[Dictionary] = []
	for hero: HeroState in state.roster().all():
		heroes.append({
			"hero_id": hero.hero_id(),
			"operator_def_id": String(hero.operator_def_id()),
			"default_name": hero.default_name()["value"],
		})
	var result := {
		"environment_sha256": definition.environment_sha256,
		"fresh_checksum": state.encode_data()["sha256"],
		"fresh_hash": state.strategic_hash()["hex"],
		"campaign_uid": state.campaign_uid(),
		"heroes": heroes,
		"compatibility": _string_projection(state.compatibility_projection()),
		"fresh_reward_hero_id": fresh_preview["created_hero_rows"][0]["hero_id"],
		"paid_reward_hero_id": paid_preview["created_hero_rows"][0]["hero_id"],
	}
	print(RESULT_PREFIX + JSON.stringify(result, "", false, true))
	quit(0)


func _paid_data(state: CampaignState) -> Dictionary:
	var data := state.data_copy()
	var allocation := state.roster().plan_allocation(
		42, 1, 5, &"caster_1", &"contract", "p16_caster_contract", 0,
	)
	data["save_revision"] = 2
	data["next_recruitment_index"] = 6
	data["marks"] = 40
	data["offers"][0]["consumed"] = true
	data["heroes"].append((allocation["row"] as Dictionary).duplicate(true))
	return data


func _string_projection(value: Dictionary) -> Dictionary:
	return {
		"unlocked_operators": _strings(value["unlocked_operators"]),
		"unlocked_traps": _strings(value["unlocked_traps"]),
		"unlocked_spells": _strings(value["unlocked_spells"]),
		"stage_stars": value["stage_stars"].duplicate(true),
	}


func _strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in values:
		result.append(String(value))
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


func _fail(error_code: Variant) -> void:
	printerr("MODEL_ROSTER_ERROR=" + String(error_code))
	quit(1)
