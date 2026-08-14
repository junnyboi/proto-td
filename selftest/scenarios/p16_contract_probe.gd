extends RefCounted

## P16.0 non-player-facing contract sentinel. No screenshots: this phase locks
## deterministic data contracts and exposes no gameplay or presentation.


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 600
	var uid := HeroIdentity.campaign_uid(h.seed_value, 1)
	h.check("seed-42 campaign uid", uid == "ce46150984346591", uid)
	var name := HeroNames.default_name(HeroIdentity.hero_bits(h.seed_value, 1, 0, 0))
	h.check("starter zero default name", name["value"] == "Dara Ember", str(name["value"]))
	var save_file := FileAccess.open(
		"res://test/fixtures/p16/campaign_v2_seed42.json",
		FileAccess.READ,
	)
	h.check("fresh save fixture opens", save_file != null)
	if save_file == null:
		h.done()
		return
	var context := _context()
	var save := CampaignCodec.decode_save(save_file.get_as_text(), context)
	save_file.close()
	h.check("fresh save fixture validates", save["accepted"], str(save.get("error_code", &"")))
	if save["accepted"]:
		var strategic := CampaignHash.of_data(save["data"], context)
		h.check("fresh strategic hash", strategic["hex"] == "baa4d62d418258a5", strategic["hex"])
	var v3_context := _v3_context()
	h.check("v3 context validates", not v3_context.is_empty())
	if not v3_context.is_empty():
		var fresh_v3 := CampaignV3Codec.create_fresh(h.seed_value, 1, v3_context)
		h.check(
			"v3 fresh roster validates", fresh_v3["accepted"],
			str(fresh_v3.get("error_code", &"")),
		)
		if fresh_v3["accepted"]:
			var hero_ids := {}
			for hero: Dictionary in fresh_v3["value"]["heroes"]:
				hero_ids[hero["hero_id"]] = true
				h.check("v3 starter is Recruit", hero["current_class_id"] == "recruit")
			h.check("v3 has five distinct starters", hero_ids.size() == 5, str(hero_ids.size()))
			var v3_hash := CampaignV3Hash.of_data(fresh_v3["value"], v3_context)
			h.check("v3 fresh strategic hash", v3_hash["hex"] == "bf4a5c25be2b0efd")
		var graph: Dictionary = v3_context["class_by_id"]
		h.check("v3 class graph has twelve nodes", graph.size() == 12, str(graph.size()))
		h.check(
			"Recruit has five first choices",
			(graph["recruit"]["promotion_to_class_ids"] as Array).size() == 5,
		)
	var replay := ReplayCodec.load_file(
		"res://playtests/replays/v1/s8.json",
		_replay_context(),
	)
	h.check("s8 replay fixture validates", replay["accepted"], str(replay.get("error_code", &"")))
	var stage := load("res://data/stages/s8.tres") as StageDef
	h.check("s8 recovery roster fills capacity", stage.recovery_roster.size() == stage.squad_size)
	h.done()


func _context() -> Dictionary:
	var stages: Array = []
	for index: int in range(1, 9):
		stages.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	return CampaignCodec.build_context(
		_catalog_ids("res://data/operators"),
		_catalog_ids("res://data/traps"),
		_catalog_ids("res://data/spells"),
		stages,
		[{"offer_id": "p16_caster_contract", "operator_def_id": "caster_1", "cost": 80}],
	)


func _v3_context() -> Dictionary:
	var stages: Array = []
	for index: int in range(1, 9):
		stages.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	var parsed: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://localization/en-US.json")
	)
	return CampaignV3Codec.build_context(
		_catalog_resources("res://data/operators"),
		_catalog_resources("res://data/classes"),
		_catalog_ids("res://data/traps"),
		_catalog_ids("res://data/spells"),
		stages,
		load("res://data/campaigns/p16_v3.tres") as CampaignDef,
		parsed["entries"],
		_context(),
	)


func _catalog_ids(path: String) -> Array:
	var ids: Array = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			ids.append(source.trim_suffix(".tres"))
	return ids


func _replay_context() -> Dictionary:
	return ReplayCodec.build_context(
		_catalog_defs("res://data/operators"),
		_catalog_defs("res://data/traps"),
		_catalog_defs("res://data/spells"),
		_catalog_defs("res://data/stages"),
		load("res://data/config/game.tres") as GameConfig,
	)


func _catalog_defs(path: String) -> Dictionary:
	var defs := {}
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var resource: Resource = load("%s/%s" % [path, source])
			defs[resource.get("id")] = resource
	return defs


func _catalog_resources(path: String) -> Array:
	var resources: Array = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			resources.append(load("%s/%s" % [path, source]))
	return resources
