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
		"res://test/fixtures/p16/campaign_v1_seed42.json",
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
		h.check("fresh strategic hash", strategic["hex"] == "85f2c11018249153", strategic["hex"])
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
