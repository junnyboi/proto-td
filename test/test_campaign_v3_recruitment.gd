extends GutTest

const ContextScript := preload("res://sim/campaign_runtime_context.gd")
const RecruitmentScript := preload("res://sim/campaign_v3_recruitment.gd")
const S1 := preload("res://data/stages/s1.tres")
const CONFIG := preload("res://data/config/game.tres")
const MAX_TICKS := 2_400

var _context: Dictionary = {}


func before_all() -> void:
	_context = ContextScript.build()


func test_paid_contract_creates_one_fresh_recruit_with_exact_economy_and_retry() -> void:
	var state := _fresh()
	var command := (
		RecruitmentScript
		. execute(
			state,
			"p4-contract",
			1,
			"contract",
			"p16_caster_contract",
		)
	)
	assert_true(command["accepted"], str(command.get("error_code", &"")))
	var advanced := _advance(command)
	var data := advanced.data_copy()
	assert_eq(data["marks"], 40)
	assert_true(data["offers"][0]["consumed"])
	assert_eq(data["heroes"].size(), 6)
	_assert_recruit(data["heroes"][5], 5, "contract", "p16_caster_contract", 0)
	var exact := (
		RecruitmentScript
		. execute(
			advanced,
			"p4-contract",
			1,
			"contract",
			"p16_caster_contract",
		)
	)
	assert_true(exact["accepted"])
	assert_false(exact["payload"]["fresh"])
	assert_eq(
		exact["payload"]["receipt"],
		advanced.data_copy()["command_receipts"][-1]["receipt"],
	)
	var conflict := (
		RecruitmentScript
		. execute(
			advanced,
			"p4-contract",
			1,
			"recovery",
			"s1",
		)
	)
	assert_false(conflict["accepted"])
	assert_eq(conflict["error_code"], &"command_id_conflict")
	assert_eq(advanced.data_copy(), data)


func test_recovery_and_replacement_each_create_a_new_recruit_after_real_s1() -> void:
	var resolved := _resolved_s1()
	var dead_ids: Array = resolved.data_copy()["last_resolution"]["dead_hero_ids"]
	assert_eq(dead_ids.size(), 2)
	var recovery := (
		RecruitmentScript
		. execute(
			resolved,
			"p4-recovery",
			3,
			"recovery",
			"s1",
		)
	)
	assert_true(recovery["accepted"], str(recovery.get("error_code", &"")))
	var recovered := _advance(recovery)
	_assert_recruit(recovered.data_copy()["heroes"][5], 5, "recovery", "s1", 1)
	var replacement := (
		RecruitmentScript
		. execute(
			recovered,
			"p4-replacement",
			4,
			"replacement",
			dead_ids[0],
		)
	)
	assert_true(replacement["accepted"], str(replacement.get("error_code", &"")))
	var replaced := _advance(replacement)
	_assert_recruit(
		replaced.data_copy()["heroes"][6],
		6,
		"replacement",
		dead_ids[0],
		1,
	)
	assert_ne(
		recovered.data_copy()["heroes"][5]["hero_id"],
		replaced.data_copy()["heroes"][6]["hero_id"],
	)
	var loaded := CampaignStateV3.restore(replaced.data_copy(), _context)
	assert_true(loaded["accepted"], str(loaded.get("error_code", &"")))
	assert_eq(loaded["value"].data_copy(), replaced.data_copy())


func test_creation_source_policy_rejects_unearned_duplicate_and_person_rewards_exactly() -> void:
	var fresh := _fresh()
	var before := fresh.data_copy()
	for request: Array in [
		["recovery", "s1", &"recovery_stage_not_cleared"],
		["replacement", before["heroes"][0]["hero_id"], &"replacement_source_not_dead"],
		["reward", "guard_2", &"reward_person_creation_disabled"],
	]:
		var result := (
			RecruitmentScript
			. execute(
				fresh,
				"p4-reject-%s" % request[0],
				1,
				request[0],
				request[1],
			)
		)
		assert_false(result["accepted"])
		assert_eq(result["error_code"], request[2])
		assert_eq(fresh.data_copy(), before)
	var resolved := _resolved_s1()
	var first := _advance(
		RecruitmentScript.execute(resolved, "p4-recover-once", 3, "recovery", "s1")
	)
	var duplicate := (
		RecruitmentScript
		. execute(
			first,
			"p4-recover-twice",
			4,
			"recovery",
			"s1",
		)
	)
	assert_false(duplicate["accepted"])
	assert_eq(duplicate["error_code"], &"recovery_already_used")


func test_restore_rejects_resealed_specialist_or_source_forgery() -> void:
	var advanced := _advance(
		(
			RecruitmentScript
			. execute(
				_fresh(),
				"p4-contract-forgery",
				1,
				"contract",
				"p16_caster_contract",
			)
		)
	)
	var specialist := advanced.data_copy()
	specialist["heroes"][5]["operator_def_id"] = "caster_1"
	specialist["heroes"][5]["current_class_id"] = "mage_apprentice"
	specialist["heroes"][5]["first_class_id"] = "mage_apprentice"
	assert_false(CampaignStateV3.restore(specialist, _context)["accepted"])
	var source_forgery := advanced.data_copy()
	source_forgery["heroes"][5]["recruit_source"] = "recovery"
	source_forgery["heroes"][5]["source_id"] = "s1"
	source_forgery["command_receipts"][0]["receipt"]["recruitment"]["hero"] = (
		source_forgery["heroes"][5].duplicate(true)
	)
	assert_false(CampaignStateV3.restore(source_forgery, _context)["accepted"])


func _fresh() -> CampaignStateV3:
	var created := CampaignStateV3.create(42, 1, _context)
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	return created["value"]


func _resolved_s1() -> CampaignStateV3:
	var state := _fresh()
	var ids: Array[String] = []
	for hero: Dictionary in state.data_copy()["heroes"].slice(0, 3):
		ids.append(String(hero["hero_id"]))
	var begun := _advance(state.begin_attempt("p4-recruit-begin", "s1", ids, 42, 1))
	var ticket: Dictionary = begun.data_copy()["tickets"][-1]
	var model := (
		BattleModel
		. create(
			S1 as StageDef,
			ticket,
			42,
			CONFIG as GameConfig,
			_catalog("res://data/enemies"),
			{},
			{},
			{},
			[ticket["ticket_hash"]],
		)
	)
	var timeline := [
		[6, &"deploy", StringName(ticket["squad"][0]["battle_id"]), Vector2i(3, 2), 0],
		[180, &"deploy", StringName(ticket["squad"][1]["battle_id"]), Vector2i(1, 2), 0],
		[420, &"deploy", StringName(ticket["squad"][2]["battle_id"]), Vector2i(2, 2), 0],
	]
	var index := 0
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		while index < timeline.size() and int(timeline[index][0]) == model.tick:
			assert_true(model.apply_action((timeline[index] as Array).slice(1)))
			index += 1
		model.step()
	assert_eq(model.result, BattleModel.Result.CLEAR)
	return _advance(
		(
			begun
			. resolve_attempt(
				"p4-recruit-resolve",
				1,
				model.snapshot()["outcome"],
				2,
			)
		)
	)


func _advance(command: Dictionary) -> CampaignStateV3:
	assert_true(command["accepted"], str(command.get("error_code", &"")))
	var mutation := command["payload"]["mutation"] as CampaignMutation
	var restored := CampaignStateV3.restore_source(mutation.prospective_save_text(), _context)
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	return restored["value"]


func _assert_recruit(
	hero: Dictionary,
	index: int,
	source: String,
	source_id: String,
	after_resolution: int,
) -> void:
	assert_eq(hero["recruitment_index"], index)
	assert_eq(hero["recruit_source"], source)
	assert_eq(hero["source_id"], source_id)
	assert_eq(hero["recruited_after_resolution_index"], after_resolution)
	assert_eq(hero["acquisition_operator_def_id"], "recruit")
	assert_eq(hero["operator_def_id"], "recruit")
	assert_eq(hero["current_class_id"], "recruit")
	assert_eq(hero["first_class_id"], "recruit")
	assert_null(hero["advanced_class_id"])
	assert_eq(hero["portrait_instance_id"], "portrait:%s" % hero["hero_id"])


func _catalog(path: String) -> Dictionary:
	var result := {}
	var directory := DirAccess.open(path)
	for filename: String in directory.get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var resource: Resource = load("%s/%s" % [path, source])
			result[resource.get("id")] = resource
	return result
