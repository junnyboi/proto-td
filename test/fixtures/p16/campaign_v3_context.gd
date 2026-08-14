extends RefCounted


static func build() -> Dictionary:
	var operators := _resources("res://data/operators")
	var classes := _resources("res://data/classes")
	var traps := _ids("res://data/traps")
	var spells := _ids("res://data/spells")
	var stages: Array = []
	for index: int in range(1, 9):
		stages.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	var locale: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://localization/en-US.json")
	)
	var legacy_campaign := load("res://data/campaigns/p16_v2.tres") as CampaignDef
	var legacy_context := CampaignCodec.build_context(
		_ids("res://data/operators"),
		traps,
		spells,
		stages,
		legacy_campaign.paid_offers,
	)
	return CampaignV3Codec.build_context(
		operators,
		classes,
		traps,
		spells,
		stages,
		load("res://data/campaigns/p16_v3.tres") as CampaignDef,
		locale["entries"],
		legacy_context,
	)


static func _resources(path: String) -> Array:
	var result: Array = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			result.append(load("%s/%s" % [path, source]))
	return result


static func _ids(path: String) -> Array:
	var result: Array = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			result.append(StringName(source.trim_suffix(".tres")))
	return result
