extends GutTest

const TRANSACTION_PATH := "res://test/fixtures/p16/transaction_vectors_v2.json"


func test_seed_42_starters_have_exact_identity_and_names() -> void:
	var state := _fresh()
	var heroes := state.roster().all()
	var expected := [
		["7179faeace82abbe", &"caster_1", "Dara Ember"],
		["cb0a9db634ff05af", &"defender_1", "Kira Jade"],
		["3ffd85bae32fdb57", &"defender_2", "Lio Pyre"],
		["1dfb65faeaddb4df", &"guard_1", "Niko Cinder"],
		["f6775da4ffcc6738", &"vanguard_1", "Dara Lark"],
	]
	assert_eq(heroes.size(), expected.size())
	for index: int in heroes.size():
		var hero: HeroState = heroes[index]
		assert_eq(hero.hero_id(), expected[index][0])
		assert_eq(hero.operator_def_id(), expected[index][1])
		assert_eq(hero.recruitment_index(), index)
		assert_eq(hero.recruit_source(), &"starter")
		assert_eq(hero.source_id(), "")
		assert_eq(hero.name_version(), 1)
		assert_eq(hero.default_name()["value"], expected[index][2])
		assert_eq(hero.display_callsign()["value"], expected[index][2])
		assert_true(hero.is_ready())


func test_resolved_hero_exposes_sticky_death_and_derived_default_name() -> void:
	var state := _resolved()
	var hero := state.roster().by_id("cb0a9db634ff05af")
	assert_not_null(hero)
	assert_false(hero.is_ready())
	assert_eq(hero.life_status(), &"dead")
	assert_eq(hero.default_name()["value"], "Kira Jade")
	assert_eq(hero.display_callsign()["value"], "Kira Jade")
	assert_eq(hero.death(), {
		"resolution_index": 1,
		"attempt_id": 1,
		"stage_id": "s1",
		"terminal_reason": "clear",
		"terminal_tick": 1000,
	})


func test_returned_rows_and_death_records_are_defensive() -> void:
	var state := _resolved()
	var hero := state.roster().by_id("cb0a9db634ff05af")
	var row := hero.to_row()
	var death: Dictionary = hero.death()
	row["operator_def_id"] = "guard_2"
	(row["death"] as Dictionary)["terminal_tick"] = 7
	death["terminal_tick"] = 8
	assert_eq(hero.operator_def_id(), &"defender_1")
	assert_eq(int((hero.death() as Dictionary)["terminal_tick"]), 1000)
	assert_eq(state.strategic_hash()["hex"], "e293b40478a9771c")


func _fresh() -> CampaignState:
	var created := CampaignState.create(42, 1, _definition(), _catalogs(), _stages())
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	return created["value"] as CampaignState


func _resolved() -> CampaignState:
	var fixture := _transaction_fixture()
	var data: Dictionary = fixture["resolved_save"]["value"]
	var restored := CampaignState.restore(data, _definition(), _catalogs(), _stages())
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	return restored["value"] as CampaignState


func _transaction_fixture() -> Dictionary:
	var source := _text(TRANSACTION_PATH)
	var parser := JSON.new()
	assert_eq(parser.parse(source), OK)
	var restored := CanonicalJson.restore_exact_integers(source, parser.data)
	assert_true(restored["accepted"])
	return restored["value"] as Dictionary


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


func _catalog_ids(path: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			ids.append(StringName(source.trim_suffix(".tres")))
	return ids


func _text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file)
	var source := file.get_as_text()
	file.close()
	return source
