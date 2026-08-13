class_name CampaignProgression
extends RefCounted

## Versioned personnel progression rules. This module owns only deterministic
## model facts: migration defaults, XP derivation, and legal class projections.

const RULES_VERSION := 1
const XP_PER_OPERATION := 100
const XP_MAX := 9_223_372_036_854_775_807
const ADVANCED_XP_REQUIRED := 400
const HERO_FIELD_ORDER := [
	"hero_id", "acquisition_operator_def_id", "operator_def_id",
	"first_class_id", "advanced_class_id", "progression_rules_version", "xp",
	"identity_portrait_id", "recruitment_index", "recruited_after_resolution_index",
	"recruit_source", "source_id", "name_version", "custom_callsign",
	"life_status", "death",
]

const PROFILES := {
	"vanguard_1": {
		"first_class_id": "shock_trooper", "advanced_class_id": null,
	},
	"vanguard_2": {
		"first_class_id": "shock_trooper", "advanced_class_id": "banner_guard",
	},
	"guard_1": {
		"first_class_id": "swordmaster", "advanced_class_id": null,
	},
	"guard_2": {
		"first_class_id": "swordmaster", "advanced_class_id": "sword_saint",
	},
	"defender_1": {
		"first_class_id": "defender", "advanced_class_id": null,
	},
	"defender_2": {
		"first_class_id": "defender", "advanced_class_id": "immovable",
	},
	"sniper_1": {
		"first_class_id": "gunner", "advanced_class_id": null,
	},
	"sniper_2": {
		"first_class_id": "gunner", "advanced_class_id": "sniper",
	},
	"caster_1": {
		"first_class_id": "mage_apprentice", "advanced_class_id": null,
	},
	"caster_2": {
		"first_class_id": "mage_apprentice", "advanced_class_id": "sorcerer",
	},
	"witch_doctor_1": {
		"first_class_id": "mage_apprentice", "advanced_class_id": "witch_doctor",
	},
}


static func initial_fields(operator_def_id: String) -> Dictionary:
	if not PROFILES.has(operator_def_id):
		return {}
	var profile: Dictionary = PROFILES[operator_def_id]
	return {
		"acquisition_operator_def_id": operator_def_id,
		"first_class_id": profile["first_class_id"],
		"advanced_class_id": profile["advanced_class_id"],
		"progression_rules_version": RULES_VERSION,
		"xp": 0,
		"identity_portrait_id": operator_def_id,
	}


static func add_initial_fields(row: Dictionary) -> Dictionary:
	var fields := initial_fields(String(row.get("operator_def_id", "")))
	if fields.is_empty():
		return {}
	var result := {}
	for key: String in HERO_FIELD_ORDER:
		if fields.has(key):
			result[key] = fields[key]
		elif row.has(key):
			result[key] = row[key]
		else:
			return {}
	return result


static func projection_is_valid(row: Dictionary) -> bool:
	var acquisition := String(row.get("acquisition_operator_def_id", ""))
	var current := String(row.get("operator_def_id", ""))
	if not PROFILES.has(acquisition) or not PROFILES.has(current):
		return false
	if row.get("identity_portrait_id") != acquisition:
		return false
	if int(row.get("progression_rules_version", 0)) != RULES_VERSION:
		return false
	var xp: Variant = row.get("xp")
	if typeof(xp) != TYPE_INT or int(xp) < 0:
		return false
	var acquisition_profile: Dictionary = PROFILES[acquisition]
	if row.get("first_class_id") != acquisition_profile["first_class_id"]:
		return false
	var advanced: Variant = row.get("advanced_class_id")
	if acquisition == "caster_1" and advanced in ["witch_doctor", "sorcerer"]:
		var expected := "witch_doctor_1" if advanced == "witch_doctor" else "caster_2"
		return current == expected
	return (
		current == acquisition
		and advanced == acquisition_profile["advanced_class_id"]
	)


static func derive_xp_awards(outcome_heroes: Array, before_heroes: Array) -> Array[Dictionary]:
	var ready := {}
	for hero: Dictionary in before_heroes:
		if hero["life_status"] == "ready" and hero["death"] == null:
			ready[String(hero["hero_id"])] = true
	var awarded := {}
	for outcome: Dictionary in outcome_heroes:
		var hero_id := String(outcome["hero_id"])
		if (
			ready.has(hero_id)
			and int(outcome["deployments"]) > 0
			and not bool(outcome["fell"])
		):
			awarded[hero_id] = true
	var hero_ids: Array = awarded.keys()
	hero_ids.sort()
	var rows: Array[Dictionary] = []
	for hero_id: String in hero_ids:
		rows.append({"hero_id": hero_id, "delta": XP_PER_OPERATION})
	return rows


static func can_apply_xp(rows: Array, awards: Array) -> bool:
	var by_id := _heroes_by_id(rows)
	for award: Dictionary in awards:
		var hero: Dictionary = by_id.get(String(award["hero_id"]), {})
		if hero.is_empty():
			return false
		var delta := int(award["delta"])
		var prior := int(hero["xp"])
		if delta < 0 or prior > XP_MAX - delta:
			return false
	return true


static func apply_xp(rows: Array, awards: Array) -> bool:
	if not can_apply_xp(rows, awards):
		return false
	var by_id := _heroes_by_id(rows)
	for award: Dictionary in awards:
		var hero: Dictionary = by_id[String(award["hero_id"])]
		hero["xp"] = int(hero["xp"]) + int(award["delta"])
	return true


static func reverse_xp(rows: Array, awards: Array) -> bool:
	var by_id := _heroes_by_id(rows)
	for award: Dictionary in awards:
		var hero: Dictionary = by_id.get(String(award["hero_id"]), {})
		if hero.is_empty() or int(hero["xp"]) < int(award["delta"]):
			return false
	for award: Dictionary in awards:
		var hero: Dictionary = by_id[String(award["hero_id"])]
		hero["xp"] = int(hero["xp"]) - int(award["delta"])
	return true


static func _heroes_by_id(rows: Array) -> Dictionary:
	var result := {}
	for row: Dictionary in rows:
		result[String(row["hero_id"])] = row
	return result
