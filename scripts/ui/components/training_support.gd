class_name TrainingSupport
extends RefCounted

## Pure presentation adapter over CampaignStateV3. Legal choices and eligibility
## always come from promotion_options(); this helper only adds identity and resource
## projections needed by Training, Results, and Staging.

const HeroIdentityScript := preload("res://sim/hero_identity.gd")
const HeroNamesScript := preload("res://sim/hero_names.gd")
const RenamingScript := preload("res://sim/campaign_v3_renaming.gd")
const ClassDefType := preload("res://data/class_def.gd")
const OperatorDefType := preload("res://data/operator_def.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")

const SKILL_NAME_FALLBACKS := {
	&"bastion_slam": "Bastion Slam",
	&"conflagration": "Conflagration",
	&"deadeye": "Deadeye",
	&"flurry": "Flurry",
	&"hold_the_line": "Hold the Line",
	&"mend": "Mend",
	&"overpower": "Overpower",
	&"rally": "Rally",
	&"rapid_volley": "Rapid Volley",
	&"tempest": "Tempest",
	&"war_banner": "War Banner",
}
const MANIFEST_PLACEHOLDER_TYPES := {
	&"ui.training.error_message": {&"message": TYPE_STRING},
	&"ui.training.fallback_recruit": {&"index": TYPE_INT},
	&"ui.training.premium_identity": {&"count": TYPE_INT},
	&"ui.training.premium_progress": {&"count": TYPE_INT},
	&"ui.training.tooltip.attack": {&"range": TYPE_INT, &"cadence": TYPE_INT},
	&"ui.training.tooltip.core_stats": {
		&"hp": TYPE_INT, &"attack": TYPE_INT, &"defense": TYPE_INT,
		&"resistance": TYPE_STRING,
	},
	&"ui.training.tooltip.deployment": {
		&"cost": TYPE_INT, &"placement": TYPE_STRING, &"block": TYPE_INT,
		&"rarity": TYPE_INT,
	},
	&"ui.training.tooltip.eligibility": {&"eligibility": TYPE_STRING},
	&"ui.training.tooltip.identity_status": {
		&"class_name": TYPE_STRING, &"status": TYPE_STRING,
	},
	&"ui.training.tooltip.progress": {&"progress": TYPE_STRING},
	&"ui.training.tooltip.skill": {&"skill": TYPE_STRING},
}

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
				"custom_title": RenamingScript.title_for(data, hero_id),
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
				"can_rename": not is_premium and String(hero.get("life_status", "")) == "ready",
				"rename_error": (
					&"premium_name_locked"
					if is_premium
					else &"hero_not_ready"
					if String(hero.get("life_status", "")) != "ready"
					else &""
				),
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


static func filtered_sorted(
	rows: Array[Dictionary],
	query: String,
	sort_mode: StringName,
) -> Array[Dictionary]:
	var visible: Array[Dictionary] = []
	var needle := query.strip_edges().to_lower()
	for source: Dictionary in rows:
		var callsign := String(source.get("callsign", ""))
		var title := String(source.get("custom_title", "") if source.get("custom_title") != null else "")
		if not needle.is_empty() and not ("%s\n%s" % [callsign, title]).to_lower().contains(needle):
			continue
		visible.append(source)
	visible.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var a_name := String(a.get("callsign", "")).to_lower()
			var b_name := String(b.get("callsign", "")).to_lower()
			var a_title := String(a.get("custom_title", "") if a.get("custom_title") != null else "").to_lower()
			var b_title := String(b.get("custom_title", "") if b.get("custom_title") != null else "").to_lower()
			if sort_mode == &"name_asc" and a_name != b_name:
				return a_name < b_name
			if sort_mode == &"name_desc" and a_name != b_name:
				return a_name > b_name
			if sort_mode in [&"name_asc", &"name_desc"] and a_title != b_title:
				return a_title < b_title if sort_mode == &"name_asc" else a_title > b_title
			return (
				int(a.get("recruitment_index", -1)) < int(b.get("recruitment_index", -1))
				or (
					int(a.get("recruitment_index", -1)) == int(b.get("recruitment_index", -1))
					and String(a.get("hero_id", "")) < String(b.get("hero_id", ""))
				)
			)
	)
	return visible


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
		var skill_id := String(operator.skill.id) if operator.skill != null else ""
		choice["skill_id"] = skill_id
		choice["skill_name_key"] = StringName(
			"ui.training.skill_name.%s" % skill_id
			if not skill_id.is_empty()
			else "ui.training.skill.none"
		)
		choice["skill_name_fallback"] = (
			skill_name_fallback(skill_id)
			if not skill_id.is_empty()
			else "None"
		)
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
	return fallback_recruit_name(int(hero.get("recruitment_index", -1)) + 1)


static func fallback_recruit_name(index: int) -> String:
	return format_manifest_text(
		&"ui.training.fallback_recruit", "Recruit #{index}", {&"index": index},
	)


static func skill_name_fallback(skill_id: String) -> String:
	return String(SKILL_NAME_FALLBACKS.get(
		StringName(skill_id), skill_id.replace("_", " ").capitalize(),
	))


static func format_manifest_text(
	key: StringName, fallback: String, args: Dictionary,
) -> String:
	var expected: Dictionary = MANIFEST_PLACEHOLDER_TYPES.get(key, {})
	if expected.size() != args.size():
		push_error("TrainingSupport.format_manifest_text: argument set mismatch for %s" % key)
		return fallback
	for raw_name: Variant in expected:
		var name := StringName(raw_name)
		if not args.has(name) or typeof(args[name]) != int(expected[name]):
			push_error("TrainingSupport.format_manifest_text: argument type mismatch for %s.%s" % [key, name])
			return fallback
	var template := UiCopyType.text(key, fallback)
	for raw_name: Variant in expected:
		var name := StringName(raw_name)
		template = template.replace("{%s}" % name, str(args[name]))
	return template


static func class_definition(class_id: String) -> ClassDefType:
	var path := "res://data/classes/%s.tres" % class_id
	return load(path) as ClassDefType if ResourceLoader.exists(path) else null


static func operator_definition(operator_id: String) -> OperatorDefType:
	var path := "res://data/operators/%s.tres" % operator_id
	return load(path) as OperatorDefType if ResourceLoader.exists(path) else null
