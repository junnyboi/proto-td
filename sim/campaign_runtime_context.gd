class_name CampaignRuntimeContext
extends RefCounted

## Production CampaignSave v3 validation context. This is deliberately separate
## from test fixtures: Game, SaveStore restore, and migration all share these
## exact shipping catalogs and campaign stages.

const CampaignCodecScript := preload("res://sim/campaign_codec.gd")
const CampaignV3CodecScript := preload("res://sim/campaign_v3_codec.gd")
const CampaignDefType := preload("res://data/campaign_def.gd")
const ClassDefType := preload("res://data/class_def.gd")
const StageDefType := preload("res://data/stage_def.gd")
const LEGACY_CAMPAIGN := preload("res://data/campaigns/p16_v2.tres")
const RECRUIT_CAMPAIGN := preload("res://data/campaigns/p16_v3.tres")


static func build() -> Dictionary:
	var operators := _resources("res://data/operators")
	var classes := _resources("res://data/classes")
	var traps := _ids("res://data/traps")
	var spells := _ids("res://data/spells")
	var stages: Array = []
	for index: int in range(1, 9):
		stages.append(load("res://data/stages/s%d.tres" % index) as StageDefType)
	var text_entries := _class_text_entries(classes)
	var legacy_context := (
		CampaignCodecScript
		. build_context(
			_ids("res://data/operators"),
			traps,
			spells,
			stages,
			(LEGACY_CAMPAIGN as CampaignDefType).paid_offers,
		)
	)
	return (
		CampaignV3CodecScript
		. build_context(
			operators,
			classes,
			traps,
			spells,
			stages,
			RECRUIT_CAMPAIGN as CampaignDefType,
			text_entries,
			legacy_context,
		)
	)


static func _class_text_entries(classes: Array) -> Dictionary:
	var result := {}
	for definition: ClassDefType in classes:
		result[String(definition.name_key)] = definition.name
		result[String(definition.role_key)] = definition.role
		result[String(definition.description_key)] = definition.description
	return result


static func _resources(path: String) -> Array:
	var result: Array = []
	var filenames := _resource_filenames(path)
	for filename: String in filenames:
		result.append(load("%s/%s" % [path, filename]))
	return result


static func _ids(path: String) -> Array[StringName]:
	var result: Array[StringName] = []
	for filename: String in _resource_filenames(path):
		result.append(StringName(filename.trim_suffix(".tres")))
	return result


static func _resource_filenames(path: String) -> Array[String]:
	var directory := DirAccess.open(path)
	if directory == null:
		return []
	var result: Array[String] = []
	for filename: String in directory.get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			result.append(source)
	result.sort()
	return result
