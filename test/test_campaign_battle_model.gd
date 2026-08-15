extends GutTest

const ContextScript := preload("res://test/fixtures/p16/campaign_v3_context.gd")
const BattleTicketRuntimeScript := preload("res://sim/battle_ticket_runtime.gd")
const S1 := preload("res://data/stages/s1.tres")
const CONFIG := preload("res://data/config/game.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const MAX_TICKS := 2_400


func test_same_template_recruits_deploy_by_distinct_battle_identity() -> void:
	var issued := _issued_ticket()
	var ticket: Dictionary = issued["ticket"]
	var model := _model(ticket)
	assert_not_null(model)
	assert_eq(model.squad, [] as Array[StringName])
	assert_eq(model.battle_squad.size(), 3)
	var first: StringName = ticket["squad"][0]["battle_id"]
	var second: StringName = ticket["squad"][1]["battle_id"]
	assert_true(model.apply_action([&"deploy", first, Vector2i(3, 2), 0]))
	model.step(180)
	assert_true(model.apply_action([&"deploy", second, Vector2i(1, 2), 0]))
	assert_eq(model.units.size(), 2)
	assert_true(model.units[0].alive)
	assert_true(model.units[1].alive)
	assert_eq(model.units[0].op_id, &"recruit")
	assert_eq(model.units[1].op_id, &"recruit")
	assert_ne(model.units[0].battle_id, model.units[1].battle_id)
	assert_ne(model.units[0].hero_id, model.units[1].hero_id)


func test_frozen_operator_class_map_covers_the_production_class_catalog() -> void:
	for filename: String in DirAccess.open("res://data/classes").get_files():
		var source := filename.trim_suffix(".remap")
		if not source.ends_with(".tres"):
			continue
		var class_def := load("res://data/classes/%s" % source) as ClassDef
		var operator_id := String(class_def.operator_def_id)
		var operator_def := load("res://data/operators/%s.tres" % operator_id) as OperatorDef
		assert_true(BattleTicketRuntimeScript.OP_CLASS_BY_OPERATOR.has(operator_id), operator_id)
		assert_eq(
			int(BattleTicketRuntimeScript.OP_CLASS_BY_OPERATOR.get(operator_id, -1)),
			int(operator_def.op_class),
			operator_id,
		)


func test_initial_battle_hash_binds_frozen_ticket_identity_and_content() -> void:
	var first: Dictionary = _issued_ticket({}, 42)["ticket"]
	var second: Dictionary = _issued_ticket({}, 43)["ticket"]
	assert_ne(first["ticket_hash"], second["ticket_hash"])
	assert_ne(_model(first).state_hash(), _model(second).state_hash())


func test_ticket_projection_isolated_from_live_resources_and_source_mutation() -> void:
	var issued := _issued_ticket()
	var source_ticket: Dictionary = issued["ticket"]
	var model := _model(source_ticket)
	var frozen_hash := model.state_hash()
	var battle_id: StringName = model.battle_squad[0]
	var recruit := load("res://data/operators/recruit.tres") as OperatorDef
	var original_atk := recruit.atk
	recruit.atk = 999
	source_ticket["squad"][0]["combat_spec"]["atk"] = 777
	source_ticket["squad"][0]["class_id"] = "sorcerer"
	source_ticket["squad"][0]["visual_spec"]["portrait_asset_id"] = "forged"
	assert_eq(model.state_hash(), frozen_hash)
	assert_true(model.apply_action([&"deploy", battle_id, Vector2i(3, 2), 0]))
	assert_eq(model.units[0].atk, 4)
	assert_eq(model.units[0].class_id, &"recruit")
	assert_eq(model.units[0].sprite_id, &"recruit")
	assert_eq(model.units[0].portrait_asset_id, &"portrait_recruit_00")
	assert_eq(model.units[0].target_policy["policy_id"], "operator_blocked_assignment_order")
	recruit.atk = original_atk


func test_retreat_redeploy_and_duplicate_live_identity_are_accounted_exactly() -> void:
	var ticket: Dictionary = _issued_ticket()["ticket"]
	var model := _model(ticket)
	var battle_id: StringName = ticket["squad"][0]["battle_id"]
	assert_true(model.apply_action([&"deploy", battle_id, Vector2i(3, 2), 0]))
	var duplicate_preimage := model.state_hash()
	assert_false(model.apply_action([&"deploy", battle_id, Vector2i(1, 2), 0]))
	assert_eq(model.state_hash(), duplicate_preimage)
	assert_true(model.apply_action([&"retreat", 0]))
	model.step(60)
	assert_true(model.apply_action([&"deploy", battle_id, Vector2i(1, 2), 0]))
	assert_true(model.apply_action([&"resign"]))
	var outcome: Dictionary = model.snapshot()["outcome"]
	assert_eq(outcome["rows"][0]["deployments"], 2)
	assert_eq(outcome["rows"][0]["retreats"], 1)
	assert_false(outcome["rows"][0]["fell"])


func test_fallen_identity_cannot_redeploy_and_records_first_fall_tick() -> void:
	var ticket: Dictionary = _issued_ticket()["ticket"]
	var model := _model(ticket)
	var battle_id: StringName = ticket["squad"][0]["battle_id"]
	assert_true(model.apply_action([&"debug_set_dp", 50]))
	assert_true(model.apply_action([&"deploy", battle_id, Vector2i(3, 2), 0]))
	model._damage_unit(model.units[0], 9_999, DamageRules.Kind.PHYSICAL)
	assert_false(model.is_deployable(battle_id))
	var rejected_preimage := model.state_hash()
	assert_false(model.apply_action([&"deploy", battle_id, Vector2i(1, 2), 0]))
	assert_eq(model.state_hash(), rejected_preimage)
	assert_true(model.apply_action([&"resign"]))
	var outcome: Dictionary = model.snapshot()["outcome"]
	assert_true(outcome["rows"][0]["fell"])
	assert_eq(outcome["rows"][0]["first_fall_tick"], 0)


func test_private_artifact_tampering_cannot_preserve_the_battle_hash() -> void:
	var ticket: Dictionary = _issued_ticket()["ticket"]
	var running := _model(ticket)
	var running_preimage := running.state_hash()
	running._ticket["squad"][0]["combat_spec"]["atk"] = 777
	assert_ne(running.state_hash(), running_preimage)

	var completed := _run(ticket, _winner(ticket))["model"] as BattleModel
	var completed_preimage := completed.state_hash()
	completed._outcome["rows"][0]["deployments"] = 999
	assert_ne(completed.state_hash(), completed_preimage)


func test_winning_timeline_emits_the_only_canonical_ticket_bound_outcome() -> void:
	var issued := _issued_ticket()
	var ticket: Dictionary = issued["ticket"]
	var run := _run(ticket, _winner(ticket))
	var model: BattleModel = run["model"]
	assert_eq(run["rejected"], [])
	assert_eq(model.result, BattleModel.Result.CLEAR)
	assert_eq(model.tick, 1_202)
	assert_eq(model.killed, 4)
	assert_eq(model.leaked, 2)
	var outcome: Dictionary = model.snapshot()["outcome"]
	assert_false(outcome.is_empty())
	var normalized := BattleOutcomeV3.normalize(outcome, ticket)
	assert_true(normalized["accepted"], str(normalized.get("error_code", &"")))
	assert_eq(normalized["value"], outcome)
	assert_eq(outcome["terminal_tick"], model.tick)
	assert_eq(outcome["result"], "clear")
	assert_eq(outcome["terminal_reason"], "clear")
	assert_eq(
		outcome["rows"].map(func(row: Dictionary) -> int: return row["deployments"]),
		[1, 1, 1],
	)
	assert_eq(
		outcome["rows"].map(func(row: Dictionary) -> String: return row["hero_id"]),
		ticket["squad"].map(func(row: Dictionary) -> String: return row["hero_id"]),
	)
	assert_eq(outcome["rows"].filter(func(row: Dictionary) -> bool: return row["fell"]).size(), 2)


func test_filtered_one_recruit_timeline_underperforms_from_same_source() -> void:
	var issued := _issued_ticket()
	var ticket: Dictionary = issued["ticket"]
	var winner := _winner(ticket)
	var omitted := StringName(ticket["squad"][1]["battle_id"])
	var filtered: Array = winner.filter(func(row: Array) -> bool: return row[2] != omitted)
	var full := _run(ticket, winner)["model"] as BattleModel
	var cut := _run(ticket, filtered)["model"] as BattleModel
	assert_eq(full.result, BattleModel.Result.CLEAR)
	assert_eq(cut.result, BattleModel.Result.DEFEAT)
	assert_eq(full.leaked, 2)
	assert_eq(cut.leaked, 4)
	assert_lt(full.tick, MAX_TICKS)
	assert_lt(cut.tick, MAX_TICKS)


func test_post_battle_promotion_cannot_rewrite_frozen_tactical_artifacts() -> void:
	var context: Dictionary = ContextScript.build()
	var issued := _issued_ticket(context)
	var ticket: Dictionary = issued["ticket"]
	var begun: CampaignStateV3 = issued["state"]
	var timeline := _winner(ticket)
	var model := _run(ticket, timeline)["model"] as BattleModel
	var replay_context := _replay_context([ticket["ticket_hash"]])
	var replay := ReplayCodec.encode_document_v2(ticket, timeline, replay_context)
	assert_true(replay["accepted"])
	var artifacts := model.snapshot()
	var outcome: Dictionary = artifacts["outcome"]
	var before := {
		"ticket": CanonicalJson.text(artifacts["ticket"]),
		"outcome": CanonicalJson.text(outcome),
		"records": CanonicalJson.text(artifacts["battle_rows"]),
		"hash": model.state_hash(),
		"snapshot": model.snapshot(),
		"replay": replay["text"],
	}
	var exposed := model.snapshot()
	exposed["ticket"]["squad"][0]["combat_spec"]["atk"] = 777
	exposed["outcome"]["rows"][0]["deployments"] = 999
	exposed["battle_rows"][0]["deployments"] = 999
	var after_exposure := model.snapshot()
	assert_eq(CanonicalJson.text(after_exposure["ticket"]), before["ticket"])
	assert_eq(CanonicalJson.text(after_exposure["outcome"]), before["outcome"])
	assert_eq(CanonicalJson.text(after_exposure["battle_rows"]), before["records"])
	assert_eq(model.state_hash(), before["hash"])
	var resolved := _advance(
		begun.resolve_attempt("p3-resolve", ticket["attempt_id"], outcome, 2),
		context,
	)
	var survivor_id := ""
	for row: Dictionary in outcome["rows"]:
		if not row["fell"]:
			survivor_id = String(row["hero_id"])
			break
	assert_false(survivor_id.is_empty())
	var promoted := _advance(
		(
			resolved
			. confirm_promotions(
				"p3-promote",
				3,
				[{"hero_id": survivor_id, "to_class_id": "swordmaster"}],
			)
		),
		context,
	)
	var after_promotion := model.snapshot()
	assert_eq(CanonicalJson.text(after_promotion["ticket"]), before["ticket"])
	assert_eq(CanonicalJson.text(after_promotion["outcome"]), before["outcome"])
	assert_eq(CanonicalJson.text(after_promotion["battle_rows"]), before["records"])
	assert_eq(model.state_hash(), before["hash"])
	assert_eq(model.snapshot(), before["snapshot"])
	assert_eq(
		ReplayCodec.encode_document_v2(after_promotion["ticket"], timeline, replay_context)["text"],
		before["replay"],
	)
	var later := _advance(
		promoted.begin_attempt("p3-later", "s1", [survivor_id], 43, 4),
		context,
	)
	var later_ticket: Dictionary = later.data_copy()["tickets"][-1]
	assert_eq(later_ticket["squad"][0]["hero_id"], survivor_id)
	assert_eq(later_ticket["squad"][0]["class_id"], "swordmaster")
	assert_eq(later_ticket["squad"][0]["operator_def_id"], "guard_1")
	assert_ne(later_ticket["ticket_hash"], ticket["ticket_hash"])
	var later_model := _model(later_ticket)
	var later_battle_id: StringName = later_ticket["squad"][0]["battle_id"]
	var guard := load("res://data/operators/guard_1.tres") as OperatorDef
	var original_guard_atk := guard.atk
	guard.atk = 999
	later_model.step(60)
	assert_true(later_model.apply_action([&"deploy", later_battle_id, Vector2i(3, 2), 0]))
	assert_eq(later_model.units[0].op_class, OperatorDef.OpClass.GUARD)
	assert_eq(later_model.units[0].atk, later_ticket["squad"][0]["combat_spec"]["atk"])
	guard.atk = original_guard_atk


func _issued_ticket(context: Dictionary = {}, battle_seed: int = 42) -> Dictionary:
	var use_context := ContextScript.build() if context.is_empty() else context
	var created := CampaignStateV3.create(42, 1, use_context)
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	var state: CampaignStateV3 = created["value"]
	var hero_ids: Array[String] = []
	for hero: Dictionary in state.data_copy()["heroes"]:
		hero_ids.append(String(hero["hero_id"]))
	var begun := _advance(
		state.begin_attempt("p3-begin", "s1", hero_ids.slice(0, 3), battle_seed, 1),
		use_context,
	)
	return {"state": begun, "ticket": begun.data_copy()["tickets"][-1]}


func _advance(command: Dictionary, context: Dictionary) -> CampaignStateV3:
	assert_true(command["accepted"], str(command.get("error_code", &"")))
	var mutation := command["payload"]["mutation"] as CampaignMutation
	var restored := CampaignStateV3.restore_source(mutation.prospective_save_text(), context)
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	return restored["value"]


func _model(ticket: Dictionary) -> BattleModel:
	return (
		BattleModel
		. create(
			S1 as StageDef,
			ticket,
			-999,
			CONFIG as GameConfig,
			{&"grunt": GRUNT as EnemyDef},
			{},
			{},
			{},
			[ticket["ticket_hash"]],
		)
	)


func _replay_context(trusted_ticket_hashes: Array = []) -> Dictionary:
	return (
		ReplayCodec
		. build_context(
			_catalog("res://data/operators"),
			_catalog("res://data/traps"),
			_catalog("res://data/spells"),
			_catalog("res://data/stages"),
			CONFIG as GameConfig,
			trusted_ticket_hashes,
		)
	)


func _catalog(path: String) -> Dictionary:
	var result := {}
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var resource: Resource = load("%s/%s" % [path, source])
			result[resource.get("id")] = resource
	return result


func _winner(ticket: Dictionary) -> Array:
	return [
		[6, &"deploy", StringName(ticket["squad"][0]["battle_id"]), Vector2i(3, 2), 0],
		[180, &"deploy", StringName(ticket["squad"][1]["battle_id"]), Vector2i(1, 2), 0],
		[420, &"deploy", StringName(ticket["squad"][2]["battle_id"]), Vector2i(2, 2), 0],
	]


func _run(ticket: Dictionary, actions: Array) -> Dictionary:
	var model := _model(ticket)
	var rows := actions.duplicate(true)
	var index := 0
	var rejected: Array = []
	while model.result == BattleModel.Result.RUNNING and model.tick < MAX_TICKS:
		while index < rows.size() and int(rows[index][0]) == model.tick:
			if not model.apply_action((rows[index] as Array).slice(1)):
				rejected.append(rows[index])
			index += 1
		model.step()
	return {"model": model, "rejected": rejected, "played": index}
