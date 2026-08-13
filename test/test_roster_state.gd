extends GutTest

const TRANSACTION_PATH := "res://test/fixtures/p16/transaction_vectors_v1.json"


func test_roster_lookup_ready_filter_and_owned_projection_are_exact() -> void:
	var state := _resolved()
	var roster := state.roster()
	assert_eq(roster.all().size(), 7)
	assert_eq(roster.ready().size(), 6)
	assert_true(roster.contains_id("7179faeace82abbe"))
	assert_false(roster.contains_id("0000000000000000"))
	assert_eq(roster.by_id("fe0ff2c1e3ecc49d").operator_def_id(), &"guard_2")
	assert_eq(roster.owned_operator_def_ids(), [
		&"caster_1", &"defender_1", &"defender_2", &"guard_1",
		&"vanguard_1", &"guard_2",
	])


func test_allocation_accepts_exact_collision_ordinals_and_exhausts() -> void:
	var state := _fresh()
	var roster := state.roster()
	var index := state.next_recruitment_index()
	var before_hash: String = state.strategic_hash()["hex"]
	var ordinal_zero := roster.plan_allocation(
		42, 1, index, &"caster_1", &"contract", "p16_caster_contract", 0,
	)
	assert_true(ordinal_zero["accepted"])
	assert_eq(ordinal_zero["collision_ordinal"], 0)
	assert_eq((ordinal_zero["hero"] as HeroState).hero_id(), "e54c103e46898f5d")

	var taken_zero: String = (ordinal_zero["hero"] as HeroState).hero_id()
	var ordinal_one := roster.plan_allocation(
		42, 1, index, &"caster_1", &"contract", "p16_caster_contract", 0, 1,
		func(candidate: String) -> bool: return candidate == taken_zero,
	)
	assert_true(ordinal_one["accepted"])
	assert_eq(ordinal_one["collision_ordinal"], 1)

	var taken_through_30 := _collision_set(42, 1, index, 30)
	var ordinal_31 := roster.plan_allocation(
		42, 1, index, &"caster_1", &"contract", "p16_caster_contract", 0, 1,
		func(candidate: String) -> bool: return taken_through_30.has(candidate),
	)
	assert_true(ordinal_31["accepted"])
	assert_eq(ordinal_31["collision_ordinal"], 31)

	var all_taken := _collision_set(42, 1, index, 31)
	var exhausted := roster.plan_allocation(
		42, 1, index, &"caster_1", &"contract", "p16_caster_contract", 0, 1,
		func(candidate: String) -> bool: return all_taken.has(candidate),
	)
	assert_false(exhausted["accepted"])
	assert_eq(exhausted["error_code"], &"id_collision_exhausted")
	assert_false(exhausted.has("row"))
	assert_eq(state.next_recruitment_index(), index)
	assert_eq(state.strategic_hash()["hex"], before_hash)


func test_roster_views_are_defensive_and_allocation_is_pure() -> void:
	var state := _fresh()
	var before_data := state.data_copy()
	var before_hash: String = state.strategic_hash()["hex"]
	var roster := state.roster()
	var rows := roster.rows_copy()
	rows[0]["life_status"] = "dead"
	var heroes := roster.all()
	var hero_row := heroes[0].to_row()
	hero_row["operator_def_id"] = "guard_2"
	roster.plan_allocation(
		42, 1, 5, &"caster_1", &"contract", "p16_caster_contract", 0,
	)
	assert_eq(state.data_copy(), before_data)
	assert_eq(state.strategic_hash()["hex"], before_hash)
	assert_true(state.roster().all()[0].is_ready())
	assert_eq(state.roster().all()[0].operator_def_id(), &"caster_1")


func test_collision_override_cannot_mask_an_owned_candidate() -> void:
	var state := _fresh()
	var rows := state.roster().rows_copy()
	var occupied := HeroIdentity.hero_id(42, 1, 5, 0)
	rows[0]["hero_id"] = occupied
	var roster := RosterState.from_normalized_rows(rows)
	var planned := roster.plan_allocation(
		42, 1, 5, &"caster_1", &"contract", "p16_caster_contract", 0, 1,
		func(_candidate: String) -> bool: return false,
	)
	assert_true(planned["accepted"])
	assert_eq(planned["collision_ordinal"], 1)
	assert_ne((planned["hero"] as HeroState).hero_id(), occupied)


func test_allocator_rejects_full_roster_counter_bounds_and_noncanonical_ids() -> void:
	var state := _fresh()
	var before_hash: String = state.strategic_hash()["hex"]
	var template := state.roster().rows_copy()[0]
	var full: Array[Dictionary] = []
	for _index: int in CampaignCodec.MAX_ROSTER:
		full.append((template as Dictionary).duplicate(true))
	var full_result := RosterState.from_normalized_rows(full).plan_allocation(
		42, 1, CampaignCodec.MAX_ROSTER, &"caster_1", &"contract",
		"p16_caster_contract", 0,
	)
	assert_false(full_result["accepted"])
	assert_eq(full_result["error_code"], &"roster_limit")
	var mismatch := state.roster().plan_allocation(
		42, 1, CampaignCodec.U63_MAX, &"caster_1", &"contract",
		"p16_caster_contract", 0,
	)
	assert_false(mismatch["accepted"])
	assert_eq(mismatch["error_code"], &"recruitment_counter_mismatch")
	var unsupported_name := state.roster().plan_allocation(
		42, 1, 5, &"caster_1", &"contract", "p16_caster_contract", 0, 2,
	)
	assert_false(unsupported_name["accepted"])
	assert_eq(unsupported_name["error_code"], &"invalid_allocation_request")
	var invalid_source := state.roster().plan_allocation(
		42, 1, 5, &"caster_1", &"contract", "not canonical", 0,
	)
	assert_false(invalid_source["accepted"])
	assert_eq(state.strategic_hash()["hex"], before_hash)


func _collision_set(seed_value: int, generation: int, index: int, last: int) -> Dictionary:
	var values := {}
	for ordinal: int in last + 1:
		values[HeroIdentity.hero_id(seed_value, generation, index, ordinal)] = true
	return values


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
	return load("res://data/campaigns/p16_v1.tres") as CampaignDef


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
