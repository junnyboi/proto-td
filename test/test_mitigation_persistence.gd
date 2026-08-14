extends GutTest

const OLD_SAVE_PATH := "res://test/fixtures/p16/campaign_v2_seed42.json"
const LEGACY_SHA256 := \
	"8cb77b6296a6fe814a6bf6ef458ff7a7153b48a9f4e32eb41accea80f36aeee7"


func test_canonical_binding_is_zero_legacy_and_permutation_invariant() -> void:
	var catalogs := _catalogs()
	var stages := _stages()
	var baseline := CombatContentBinding.build(catalogs, stages)
	assert_true(baseline["accepted"])
	assert_eq(baseline["sha256"], LEGACY_SHA256)
	assert_eq(baseline["manifest"]["version"], DamageRules.VERSION)
	assert_eq(baseline["manifest"]["operators"].size(), 11)
	assert_eq(baseline["manifest"]["enemies"].size(), 6)
	for key: String in catalogs:
		(catalogs[key] as Array).reverse()
	stages.reverse()
	var permuted := CombatContentBinding.build(catalogs, stages)
	assert_true(permuted["accepted"])
	assert_eq(permuted["manifest"], baseline["manifest"])
	assert_eq(permuted["sha256"], baseline["sha256"])


func test_pre_mitigation_v2_save_upgrades_to_bound_canonical_bytes() -> void:
	var source := _text(OLD_SAVE_PATH)
	assert_false(source.contains("combat_rules_sha256"))
	var decoded := CampaignCodec.decode_save(source, _context())
	assert_true(decoded["accepted"], str(decoded.get("error_code", &"")))
	assert_eq(decoded["migrated_from_version"], 2)
	assert_eq(decoded["data"]["combat_rules_sha256"], LEGACY_SHA256)
	assert_true(String(decoded["text"]).contains("combat_rules_sha256"))
	var repeated := CampaignCodec.decode_save(decoded["text"], _context())
	assert_true(repeated["accepted"])
	assert_null(repeated["migrated_from_version"])
	assert_eq(repeated["bytes"], decoded["bytes"])
	assert_eq(repeated["sha256"], decoded["sha256"])
	var future_rejected := CampaignCodec.decode_save(source, _context("a".repeat(64)))
	assert_false(future_rejected["accepted"])
	assert_eq(future_rejected["error_code"], &"combat_rules_mismatch")


func test_new_save_round_trip_and_tampered_binding_reject() -> void:
	var state := _fresh()
	assert_eq(state.data_copy()["combat_rules_sha256"], LEGACY_SHA256)
	var encoded := CampaignCodec.encode_save(state.data_copy(), _context())
	assert_true(encoded["accepted"])
	var decoded := CampaignCodec.decode_save(encoded["text"], _context())
	assert_true(decoded["accepted"])
	assert_eq(decoded["bytes"], encoded["bytes"])
	var tampered := state.data_copy()
	tampered["combat_rules_sha256"] = "a".repeat(64)
	var rejected := CampaignState.restore(
		tampered, _definition(), _catalogs(), _stages(),
	)
	assert_false(rejected["accepted"])
	assert_eq(rejected["error_code"], &"combat_rules_mismatch")


func test_nonlegacy_binding_changes_campaign_hash_and_nested_core_bytes() -> void:
	var state := _fresh()
	var legacy_hash := state.strategic_hash()
	var changed_sha := "a".repeat(64)
	var changed_data := state.data_copy()
	changed_data["combat_rules_sha256"] = changed_sha
	var changed_context := _context(changed_sha)
	var changed_hash := CampaignHash.of_data(changed_data, changed_context)
	assert_true(changed_hash["accepted"])
	assert_ne(changed_hash["hex"], legacy_hash["hex"])
	assert_gt(changed_hash["bytes"].size(), legacy_hash["bytes"].size())
	var core := changed_data.duplicate(true)
	core.erase("resolution_anchor")
	core.erase("last_resolution")
	var core_hash := CampaignHash.of_core_snapshot(core, changed_context)
	assert_true(core_hash["accepted"])
	assert_ne(core_hash["hex"], legacy_hash["hex"])


func test_manifest_semantic_mutation_changes_sha256() -> void:
	var binding := CombatContentBinding.build(_catalogs(), _stages())
	assert_true(binding["accepted"])
	var mutated: Dictionary = binding["manifest"].duplicate(true)
	mutated["operators"][0]["defense"] = 1
	assert_ne(CanonicalJson.sha256_hex(mutated), binding["sha256"])
	mutated = binding["manifest"].duplicate(true)
	mutated["spells"][0]["damage_kind"] = DamageRules.Kind.ARTS
	assert_ne(CanonicalJson.sha256_hex(mutated), binding["sha256"])


func test_shipping_catalogs_keep_zero_physical_compatibility_defaults() -> void:
	for directory: String in ["operators", "enemies"]:
		for resource: Resource in _resources("res://data/%s" % directory, true):
			assert_eq(resource.get("defense"), 0, "%s DEF default" % resource.get("id"))
			assert_eq(
				resource.get("resistance_permille"), 0,
				"%s RES default" % resource.get("id"),
			)
			assert_eq(
				resource.get("attack_damage_kind"), DamageRules.Kind.PHYSICAL,
				"%s attack kind default" % resource.get("id"),
			)
	for directory: String in ["traps", "spells"]:
		for resource: Resource in _resources("res://data/%s" % directory):
			assert_eq(
				resource.get("damage_kind"), DamageRules.Kind.PHYSICAL,
				"%s damage kind default" % resource.get("id"),
			)
	var armor := load("res://data/enemies/test_high_def.tres") as EnemyDef
	var ward := load("res://data/enemies/test_high_res.tres") as EnemyDef
	assert_gt(armor.defense, 0)
	assert_gt(ward.resistance_permille, 0)


func _fresh() -> CampaignState:
	var created := CampaignState.create(42, 1, _definition(), _catalogs(), _stages())
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	return created["value"] as CampaignState


func _definition() -> CampaignDef:
	return load("res://data/campaigns/p16_v2.tres") as CampaignDef


func _catalogs() -> Dictionary:
	return {
		"operators": _catalog_ids("res://data/operators"),
		"traps": _catalog_ids("res://data/traps"),
		"spells": _catalog_ids("res://data/spells"),
	}


func _stages() -> Array:
	var stages: Array = []
	for index: int in range(1, 9):
		stages.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	return stages


func _context(binding: String = LEGACY_SHA256) -> Dictionary:
	return CampaignCodec.build_context(
		_catalogs()["operators"], _catalogs()["traps"], _catalogs()["spells"],
		_stages(), _definition().paid_offers, [], [], {}, binding,
	)


func _catalog_ids(path: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			ids.append(StringName(source.trim_suffix(".tres")))
	return ids


func _resources(path: String, exclude_test_only: bool = false) -> Array[Resource]:
	var result: Array[Resource] = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if not source.ends_with(".tres"):
			continue
		if exclude_test_only and source.begins_with("test_"):
			continue
		result.append(load("%s/%s" % [path, source]) as Resource)
	return result


func _text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file)
	var source := file.get_as_text()
	file.close()
	return source
