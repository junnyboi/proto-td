extends RefCounted

## P16.1 model-only probe. No screenshots or player-facing claims.


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 600
	var game := await _await_game(h)
	h.check("Game autoload available", game != null)
	if game == null:
		return
	var created := CampaignState.create(
		h.seed_value, 1, _definition(), _catalogs(), _stages(),
	)
	h.check("canonical campaign creates", created["accepted"],
		str(created.get("error_code", &"")))
	if not created["accepted"]:
		return
	var state := created["value"] as CampaignState
	h.check("authored environment fingerprint",
		_definition().environment_sha256
		== "693c3f42b492bde75c14940c1068d8a6e7ae551aa694d8551d5a49e26bdd9156")
	h.check("fresh campaign uid", state.campaign_uid() == "ce46150984346591")
	h.check("fresh strategic hash", state.strategic_hash()["hex"] == "baa4d62d418258a5")
	h.check("five canonical starters", state.roster().all().size() == 5)
	h.check("five compatibility operators",
		(state.compatibility_projection()["unlocked_operators"] as Array).size() == 5)
	var fresh_preview := state.preview_first_clear_rewards(&"s1")
	h.check("fresh S1 reward preview accepted", fresh_preview["accepted"])
	h.check("fresh S1 reward uses index five",
		fresh_preview["created_hero_rows"][0]["hero_id"] == "e54c103e46898f5d")
	var paid := CampaignState.restore(
		_paid_data(state), _definition(), _catalogs(), _stages(),
	)
	h.check("paid pre-resolution state restores", paid["accepted"],
		str(paid.get("error_code", &"")))
	if paid["accepted"]:
		var paid_preview := (paid["value"] as CampaignState).preview_first_clear_rewards(&"s1")
		h.check("paid S1 reward uses index six",
			paid_preview["created_hero_rows"][0]["hero_id"] == "fe0ff2c1e3ecc49d")
	h.check("reward previews preserve canonical hash",
		state.strategic_hash()["hex"] == "baa4d62d418258a5")
	_check_debug_override(h, game)
	game.call("open_title")
	await h.frames(4)
	h.check("Title clears debug override", not bool(game.get("_debug_catalog_override")))
	h.check("Title clears legacy campaign", game.get("campaign") == null)
	h.done()


func _await_game(h: SelfTestHarness) -> Node:
	var budget := 120
	while budget > 0:
		var game := h.autoload("Game")
		if game != null:
			return game
		budget -= 1
		await h.frames(1)
	return null


func _check_debug_override(h: SelfTestHarness, game: Node) -> void:
	game.call("start_campaign", false)
	var legacy: LegacyCampaignAdapter = game.get("campaign")
	var before := {
		"operators": legacy.unlocked_operators.duplicate(),
		"traps": legacy.unlocked_traps.duplicate(),
		"spells": legacy.unlocked_spells.duplicate(),
		"stars": legacy.stage_stars.duplicate(true),
	}
	game.call("debug_unlock_all")
	h.check("debug override reaches full operator catalog",
		(game.call("loadout_operator_ids") as Array).size() == 12)
	h.check("debug override does not mutate legacy roster",
		legacy.unlocked_operators == before["operators"])
	game.call("start_campaign", false)
	h.check("New Campaign clears debug override", not bool(game.get("_debug_catalog_override")))
	h.check("New Campaign restores five legacy starters",
		(game.call("loadout_operator_ids") as Array).size() == 5)


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


func _definition() -> CampaignDef:
	return load("res://data/campaigns/p16_v2.tres") as CampaignDef


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
