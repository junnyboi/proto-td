class_name MemorialSupport
extends RefCounted

const TrainingSupportType := preload("res://scripts/ui/components/training_support.gd")


static func supports_campaign(value: Variant) -> bool:
	return value != null and value.has_method(&"data_copy")


static func count(value: Variant) -> int:
	if not supports_campaign(value):
		return 0
	var data: Dictionary = value.call("data_copy")
	return (data.get("memorial", []) as Array).size()


static func rows(value: Variant) -> Array[Dictionary]:
	if not supports_campaign(value):
		return []
	return rows_from_data(value.call("data_copy"))


static func rows_from_data(data: Dictionary) -> Array[Dictionary]:
	var heroes_by_id := {}
	for raw_hero: Variant in data.get("heroes", []):
		if raw_hero is Dictionary:
			var hero := raw_hero as Dictionary
			heroes_by_id[String(hero.get("hero_id", ""))] = hero
	var deeds_by_id := _deeds(data.get("command_receipts", []))
	var projected: Array[Dictionary] = []
	for raw_memorial: Variant in data.get("memorial", []):
		if raw_memorial is not Dictionary:
			continue
		var memorial := raw_memorial as Dictionary
		var hero_id := String(memorial.get("hero_id", ""))
		var hero: Dictionary = heroes_by_id.get(hero_id, {})
		var death: Dictionary = memorial.get("death", {})
		if hero.is_empty() or death.is_empty():
			continue
		(
			projected
			. append(
				{
					"memorial_id": String(memorial.get("memorial_id", "")),
					"hero_id": hero_id,
					"callsign": TrainingSupportType.callsign(hero),
					"service_number": int(hero.get("recruitment_index", -1)) + 1,
					"recruitment_index": int(hero.get("recruitment_index", -1)),
					"portrait_instance_id": String(memorial.get("portrait_instance_id", "")),
					"portrait_asset_id": String(memorial.get("portrait_asset_id", "")),
					"class_id": String(memorial.get("class_id", "")),
					"xp": int(hero.get("xp", 0)),
					"death": death.duplicate(true),
					"deeds": deeds_by_id.get(hero_id, _empty_deeds()).duplicate(true),
				}
			)
		)
	projected.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var a_resolution := int((a["death"] as Dictionary).get("resolution_index", 0))
			var b_resolution := int((b["death"] as Dictionary).get("resolution_index", 0))
			if a_resolution != b_resolution:
				return a_resolution > b_resolution
			if int(a["recruitment_index"]) != int(b["recruitment_index"]):
				return int(a["recruitment_index"]) < int(b["recruitment_index"])
			return String(a["hero_id"]) < String(b["hero_id"])
	)
	return projected


static func _deeds(raw_records: Variant) -> Dictionary:
	var result := {}
	if raw_records is not Array:
		return result
	var records: Array[Dictionary] = []
	for raw_record: Variant in raw_records:
		if raw_record is Dictionary:
			records.append(raw_record)
	records.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if int(a.get("save_revision", 0)) != int(b.get("save_revision", 0)):
				return int(a.get("save_revision", 0)) < int(b.get("save_revision", 0))
			return String(a.get("command_id", "")) < String(b.get("command_id", ""))
	)
	var seen_commands := {}
	for record: Dictionary in records:
		var command_id := String(record.get("command_id", ""))
		if (
			String(record.get("verb", "")) != "resolve_attempt"
			or command_id.is_empty()
			or seen_commands.has(command_id)
		):
			continue
		seen_commands[command_id] = true
		var payload: Variant = record.get("payload", {})
		if payload is not Dictionary:
			continue
		var outcome: Variant = (payload as Dictionary).get("outcome", {})
		if outcome is not Dictionary:
			continue
		var cleared := String((outcome as Dictionary).get("result", "")) == "clear"
		var matched_hero_ids := {}
		for raw_row: Variant in (outcome as Dictionary).get("rows", []):
			if raw_row is not Dictionary:
				continue
			var row := raw_row as Dictionary
			var deployments := int(row.get("deployments", 0))
			if deployments <= 0:
				continue
			var hero_id := String(row.get("hero_id", ""))
			if hero_id.is_empty() or matched_hero_ids.has(hero_id):
				continue
			matched_hero_ids[hero_id] = true
			if not result.has(hero_id):
				result[hero_id] = _empty_deeds()
			var deeds := result[hero_id] as Dictionary
			deeds["operations_deployed"] = int(deeds["operations_deployed"]) + 1
			deeds["deployments"] = int(deeds["deployments"]) + deployments
			deeds["retreats"] = int(deeds["retreats"]) + int(row.get("retreats", 0))
			if cleared:
				deeds["successful_operations"] = int(deeds["successful_operations"]) + 1
	return result


static func _empty_deeds() -> Dictionary:
	return {
		"operations_deployed": 0,
		"deployments": 0,
		"successful_operations": 0,
		"retreats": 0,
	}
