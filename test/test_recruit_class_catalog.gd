extends GutTest

const CAMPAIGN := preload("res://data/campaigns/p16_v3.tres")
const CLASS_IDS: Array[String] = [
	"banner_guard",
	"defender",
	"gunner",
	"immovable",
	"mage_apprentice",
	"recruit",
	"shock_trooper",
	"sniper",
	"sorcerer",
	"sword_saint",
	"swordmaster",
	"witch_doctor",
]
const STANDARD_IDS: Array[StringName] = [
	&"defender",
	&"gunner",
	&"mage_apprentice",
	&"shock_trooper",
	&"swordmaster",
]
const ADVANCED_STAGE_ROWS := [
	{"class_id": "sword_saint", "stage_id": "s1"},
	{"class_id": "immovable", "stage_id": "s3"},
	{"class_id": "sniper", "stage_id": "s4"},
	{"class_id": "sorcerer", "stage_id": "s5"},
	{"class_id": "banner_guard", "stage_id": "s6"},
	{"class_id": "witch_doctor", "stage_id": "s7"},
]


func test_operator_ordinals_and_production_recruit_are_exact() -> void:
	assert_eq(OperatorDef.OpClass.VANGUARD, 0)
	assert_eq(OperatorDef.OpClass.GUARD, 1)
	assert_eq(OperatorDef.OpClass.DEFENDER, 2)
	assert_eq(OperatorDef.OpClass.SNIPER, 3)
	assert_eq(OperatorDef.OpClass.CASTER, 4)
	assert_eq(OperatorDef.OpClass.HEALER, 5)
	assert_eq(OperatorDef.OpClass.RECRUIT, 6)
	var recruit := load("res://data/operators/recruit.tres") as OperatorDef
	assert_not_null(recruit)
	assert_eq(recruit.id, &"recruit")
	assert_eq(recruit.op_class, OperatorDef.OpClass.RECRUIT)
	assert_eq(recruit.dp_cost, 8)
	assert_eq(recruit.block, 1)
	assert_eq(recruit.hp, 110)
	assert_eq(recruit.atk, 4)
	assert_eq(recruit.defense, 0)
	assert_eq(recruit.resistance_permille, 0)
	assert_eq(recruit.attack_damage_kind, DamageRules.Kind.PHYSICAL)
	assert_eq(recruit.atk_interval_ticks, 36)
	assert_eq(recruit.range_offsets, [Vector2i.ZERO])
	assert_eq(recruit.placement, OperatorDef.Placement.GROUND)
	assert_eq(recruit.dp_generation_interval_ticks, 0)
	assert_eq(recruit.splash_dim, 0)
	assert_null(recruit.skill)


func test_class_graph_and_v3_obtainability_are_exact() -> void:
	var normalized := (
		ClassDef
		. normalize_catalog(
			_class_resources(),
			_operator_ids(),
			_locale_entries(),
		)
	)
	assert_true(normalized["accepted"], str(normalized.get("error_code", &"")))
	var rows: Array = normalized["value"]
	assert_eq(rows.size(), 12)
	var by_id := _by_id(rows)
	assert_eq(
		by_id["recruit"]["promotion_to_class_ids"],
		[
			"defender",
			"gunner",
			"mage_apprentice",
			"shock_trooper",
			"swordmaster",
		]
	)
	assert_eq(
		by_id["mage_apprentice"]["promotion_to_class_ids"],
		[
			"sorcerer",
			"witch_doctor",
		]
	)
	assert_eq(by_id["shock_trooper"]["promotion_to_class_ids"], ["banner_guard"])
	assert_eq(by_id["swordmaster"]["promotion_to_class_ids"], ["sword_saint"])
	assert_eq(by_id["defender"]["promotion_to_class_ids"], ["immovable"])
	assert_eq(by_id["gunner"]["promotion_to_class_ids"], ["sniper"])
	for advanced_id: String in [
		"banner_guard",
		"immovable",
		"sniper",
		"sorcerer",
		"sword_saint",
		"witch_doctor",
	]:
		assert_true((by_id[advanced_id]["promotion_to_class_ids"] as Array).is_empty())
	var campaign := CAMPAIGN as CampaignDef
	assert_not_null(campaign)
	assert_eq(campaign.schema_version, 3)
	assert_eq(campaign.starting_class_ids, STANDARD_IDS)
	assert_eq(campaign.stage_class_entitlements, ADVANCED_STAGE_ROWS)
	assert_eq(
		campaign.v3_stage_rewards,
		[
			{"rewards": [], "stage_id": "s1"},
			{"rewards": [{"id": "spike_plate", "kind": "trap"}], "stage_id": "s2"},
			{"rewards": [{"id": "tar_pit", "kind": "trap"}], "stage_id": "s3"},
			{"rewards": [{"id": "bolt", "kind": "spell"}], "stage_id": "s4"},
			{"rewards": [{"id": "charm", "kind": "spell"}], "stage_id": "s5"},
			{"rewards": [], "stage_id": "s6"},
			{"rewards": [], "stage_id": "s7"},
			{"rewards": [], "stage_id": "s8"},
		]
	)
	var obtainable := ClassDef.validate_obtainability(rows, campaign)
	assert_true(obtainable["accepted"], str(obtainable.get("error_code", &"")))


func test_class_graph_rejects_illegal_catalog_mutations() -> void:
	var locale := _locale_entries()
	var operators := _operator_ids()
	var duplicate := _class_resources()
	var duplicate_row := (duplicate[0] as ClassDef).duplicate(true) as ClassDef
	duplicate.append(duplicate_row)
	assert_false(ClassDef.normalize_catalog(duplicate, operators, locale)["accepted"])

	var missing_target := _class_resources()
	var recruit := (missing_target[5] as ClassDef).duplicate(true) as ClassDef
	recruit.promotion_to_class_ids.append(&"missing")
	missing_target[5] = recruit
	assert_false(ClassDef.normalize_catalog(missing_target, operators, locale)["accepted"])

	var cyclic := _class_resources()
	var banner := (cyclic[0] as ClassDef).duplicate(true) as ClassDef
	banner.promotion_to_class_ids = [&"recruit"]
	cyclic[0] = banner
	assert_false(ClassDef.normalize_catalog(cyclic, operators, locale)["accepted"])

	var orphan := _class_resources()
	orphan.remove_at(8)
	assert_false(ClassDef.normalize_catalog(orphan, operators, locale)["accepted"])

	var negative := _class_resources()
	var shock := (negative[6] as ClassDef).duplicate(true) as ClassDef
	shock.promotion_xp_required = -1
	negative[6] = shock
	assert_false(ClassDef.normalize_catalog(negative, operators, locale)["accepted"])

	var missing_locale := locale.duplicate()
	missing_locale.erase("data.class.recruit.description")
	assert_false(
		ClassDef.normalize_catalog(_class_resources(), operators, missing_locale)["accepted"]
	)


func test_starter_rows_and_recruit_runtime_assets_are_distinct_and_review_pending() -> void:
	var campaign := CAMPAIGN as CampaignDef
	assert_eq(campaign.starter_rows.size(), 5)
	assert_eq(campaign.portrait_asset_ids.size(), 8)
	var portraits := {}
	for row: Dictionary in campaign.starter_rows:
		assert_eq(row["class_id"], "recruit")
		assert_eq(row["operator_def_id"], "recruit")
		portraits[String(row["portrait_asset_id"])] = true
	assert_eq(portraits.size(), 5)
	var manifest := load("res://assets/manifest.tres") as AssetManifest
	assert_true(bool(manifest.entries[&"recruit"]["placeholder"]))
	assert_eq(manifest.entries[&"recruit"]["frames"], 5)
	assert_eq(manifest.entries[&"recruit"]["pattern"], "res://assets/sprites/recruit_%d.png")
	assert_eq(manifest.entries[&"recruit"]["size"], Vector2i(32, 32))
	assert_eq(manifest.entries[&"recruit"]["pivot"], Vector2(0.5, 1.0))
	assert_eq(manifest.entries[&"recruit"]["animations"], AssetManifest.legacy_animations(5))
	for frame: int in 5:
		assert_true(FileAccess.file_exists("res://assets/sprites/recruit_%d.png" % frame))
	var patterns := {}
	var portrait_hashes := {}
	for portrait_id: StringName in campaign.portrait_asset_ids:
		assert_true(manifest.entries.has(portrait_id), String(portrait_id))
		var entry: Dictionary = manifest.entries[portrait_id]
		assert_true(bool(entry["placeholder"]), String(portrait_id))
		assert_eq(entry["frames"], 1, String(portrait_id))
		assert_eq(entry["size"], Vector2i(128, 128), String(portrait_id))
		assert_eq(entry["pivot"], Vector2(0.5, 0.5), String(portrait_id))
		assert_eq(entry["animations"], AssetManifest.legacy_animations(1), String(portrait_id))
		assert_true(String(entry["pattern"]).begins_with("res://assets/portraits/recruit_"))
		assert_true(FileAccess.file_exists(entry["pattern"]), String(portrait_id))
		patterns[String(entry["pattern"])] = true
		portrait_hashes[FileAccess.get_sha256(entry["pattern"])] = true
	assert_eq(patterns.size(), 8)
	assert_eq(portrait_hashes.size(), 8)


func test_legacy_runtime_starting_set_ignores_future_recruit() -> void:
	var stages: Array = []
	for index: int in range(1, 9):
		stages.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	var catalogs := {
		"operators": _operator_ids(),
		"traps": _ids("res://data/traps"),
		"spells": _ids("res://data/spells"),
	}
	var starting := LegacyCampaignAdapter.derive_starting_unlocks(catalogs, stages)
	assert_false((starting["operators"] as Array).has(&"recruit"))
	assert_eq(
		starting["operators"],
		[
			&"caster_1",
			&"defender_1",
			&"defender_2",
			&"guard_1",
			&"vanguard_1",
		]
	)


func _class_resources() -> Array:
	var rows: Array = []
	for class_id: String in CLASS_IDS:
		rows.append(load("res://data/classes/%s.tres" % class_id) as ClassDef)
	return rows


func _operator_ids() -> Array:
	return _ids("res://data/operators")


func _ids(path: String) -> Array:
	var ids: Array = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			ids.append(StringName(source.trim_suffix(".tres")))
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func _locale_entries() -> Dictionary:
	var source := FileAccess.get_file_as_string("res://localization/en-US.json")
	var parsed: Dictionary = JSON.parse_string(source)
	return parsed["entries"]


func _by_id(rows: Array) -> Dictionary:
	var result := {}
	for row: Dictionary in rows:
		result[String(row["class_id"])] = row
	return result
