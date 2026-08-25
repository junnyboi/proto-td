class_name TrainingSupport
extends RefCounted

## Pure presentation adapter over CampaignStateV3. Legal choices and eligibility
## always come from promotion_options(); this helper only adds identity and resource
## projections needed by Training, Results, and Staging.

const HeroIdentityScript := preload("res://sim/hero_identity.gd")
const HeroNamesScript := preload("res://sim/hero_names.gd")
const ClassDefType := preload("res://data/class_def.gd")
const OperatorDefType := preload("res://data/operator_def.gd")

const REQUIRED_CAMPAIGN_METHODS := [
	&"data_copy",
	&"promotion_options",
	&"campaign_uid",
	&"save_revision",
	&"strategic_hash",
]


static func supports_campaign(value: Variant) -> bool:
	if value == null:
		return false
	for method_name: StringName in REQUIRED_CAMPAIGN_METHODS:
		if not value.has_method(method_name):
			return false
	return true


static func roster(value: Variant) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if not supports_campaign(value):
		return rows
	var data: Dictionary = value.call("data_copy")
	for hero: Dictionary in data.get("heroes", []):
		var hero_id := String(hero.get("hero_id", ""))
		var current_class_id := String(hero.get("current_class_id", ""))
		var definition := class_definition(current_class_id)
		var is_premium := String(hero.get("hero_kind", "recruit")) == "premium"
		var required := (
			0 if is_premium else int(definition.promotion_xp_required) if definition != null else 0
		)
		var options: Dictionary = value.call("promotion_options", hero_id)
		var projection := enrich_choices(options.get("choices", []))
		var model_accepted := bool(options.get("accepted", false))
		var projection_accepted := bool(projection["accepted"])
		rows.append(
			{
				"hero_id": hero_id,
				"callsign": callsign(hero),
				"recruitment_index": int(hero.get("recruitment_index", -1)),
				"current_class_id": current_class_id,
				"operator_def_id": String(hero.get("operator_def_id", "")),
				"portrait_asset_id": String(
					hero.get("portrait_asset_id", hero.get("identity_portrait_id", ""))
				),
				"life_status": String(hero.get("life_status", "")),
				"hero_kind": String(hero.get("hero_kind", "recruit")),
				"premium_id": hero.get("premium_id"),
				"premium_lives": int(hero.get("premium_lives", 0)),
				"premium_pull_count": int(hero.get("premium_pull_count", 0)),
				"is_premium": is_premium,
				"xp": int(hero.get("xp", 0)),
				"xp_required": required,
				"model_can_promote": model_accepted,
				"can_promote": model_accepted and projection_accepted,
				"eligibility_error": (
					StringName(projection["error_code"])
					if model_accepted and not projection_accepted
					else StringName(options.get("error_code", &""))
				),
				"choices": projection["choices"],
			}
		)
	rows.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return (
				int(a["recruitment_index"]) < int(b["recruitment_index"])
				or (
					int(a["recruitment_index"]) == int(b["recruitment_index"])
					and String(a["hero_id"]) < String(b["hero_id"])
				)
			)
	)
	return rows


static func eligible_count(value: Variant) -> int:
	var count := 0
	if not supports_campaign(value):
		return count
	var data: Dictionary = value.call("data_copy")
	for hero: Dictionary in data.get("heroes", []):
		var projected: Dictionary = value.call(
			"promotion_options", String(hero.get("hero_id", "")),
		)
		if bool(projected.get("accepted", false)):
			count += 1
	return count


static func summary_by_id(value: Variant, hero_id: String) -> Dictionary:
	for row: Dictionary in roster(value):
		if String(row["hero_id"]) == hero_id:
			return row
	return {}


static func options(value: Variant, hero_id: String) -> Dictionary:
	if not supports_campaign(value):
		return {"accepted": false, "error_code": &"campaign_inactive", "choices": []}
	var result: Dictionary = value.call("promotion_options", hero_id)
	if not bool(result.get("accepted", false)):
		return {
			"accepted": false,
			"error_code": StringName(result.get("error_code", &"unknown_error")),
			"choices": [],
		}
	return enrich_choices(result.get("choices", []))


static func enrich_choices(raw_choices: Array) -> Dictionary:
	var result: Array[Dictionary] = []
	for raw: Variant in raw_choices:
		if typeof(raw) != TYPE_DICTIONARY:
			return {"accepted": false, "error_code": &"missing_catalog", "choices": []}
		var choice := (raw as Dictionary).duplicate(true)
		var class_id := String(choice.get("to_class_id", ""))
		var definition := class_definition(class_id)
		var operator := operator_definition(String(choice.get("operator_def_id", "")))
		if definition == null or operator == null:
			return {"accepted": false, "error_code": &"missing_catalog", "choices": []}
		choice["class_name_key"] = definition.name_key
		choice["class_name_fallback"] = definition.name
		choice["role_key"] = definition.role_key
		choice["role_fallback"] = definition.role
		choice["description_key"] = definition.description_key
		choice["description_fallback"] = definition.description
		choice["dp_cost"] = operator.dp_cost
		choice["block"] = operator.block
		choice["placement"] = int(operator.placement)
		choice["range_cells"] = operator.range_offsets.size()
		choice["attack_interval_ticks"] = operator.atk_interval_ticks
		choice["skill_name"] = operator.skill.display_name if operator.skill != null else ""
		result.append(choice)
	result.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return String(a["to_class_id"]) < String(b["to_class_id"])
	)
	if result.is_empty():
		return {"accepted": false, "error_code": &"missing_catalog", "choices": []}
	return {"accepted": true, "error_code": &"", "choices": result}


static func callsign(hero: Dictionary) -> String:
	if hero.get("custom_callsign") != null:
		var custom := String(hero["custom_callsign"]).strip_edges()
		if not custom.is_empty():
			return custom
	var parsed := HeroIdentityScript.parse_u64_hex(String(hero.get("hero_id", "")))
	if parsed["accepted"]:
		var generated := HeroNamesScript.default_name(
			int(parsed["bits"]), int(hero.get("name_version", 1)),
		)
		var value := String(generated.get("value", "")).strip_edges()
		if not value.is_empty():
			return value
	return "Recruit #%d" % (int(hero.get("recruitment_index", -1)) + 1)


static func class_definition(class_id: String) -> ClassDefType:
	var path := "res://data/classes/%s.tres" % class_id
	return load(path) as ClassDefType if ResourceLoader.exists(path) else null


static func operator_definition(operator_id: String) -> OperatorDefType:
	var path := "res://data/operators/%s.tres" % operator_id
	return load(path) as OperatorDefType if ResourceLoader.exists(path) else null
