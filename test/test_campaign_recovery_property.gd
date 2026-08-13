extends GutTest

const CHECKPOINT_512_PATH := "res://test/fixtures/p16/roster_limit_checkpoint_512.json"
const CHECKPOINT_512_SHA := "90857657b587835de530ddca0d4f55ab0a7a079800f33855d62b19cafca6a76e"
const CHECKPOINT_768_PATH := "res://test/fixtures/p16/roster_limit_checkpoint_768.json"
const CHECKPOINT_768_SHA := "966f6391ae36813c1f824d81befdd94260637c0a1564a383b515050919f58678"
const CHECKPOINT_896_PATH := "res://test/fixtures/p16/roster_limit_checkpoint_896.json"
const CHECKPOINT_896_SHA := "393ef66e7a8227d9c04c3e2a3166f730040f50462c8021ff8ca1cadf778514df"

func test_all_296_casualty_subsets_accept_exactly_812_recovery_recruits() -> void:
	if OS.get_environment("P16_PROPERTY_SEGMENT") not in ["", "subsets", "capture"]:
		pass_test("inactive casualty-subset segment")
		return
	var subset_total := 0
	var recruit_total := 0
	var expected_subsets := [8, 16, 16, 32, 32, 64, 64, 64]
	for stage_index: int in range(8):
		var base := _progress_to(stage_index)
		var roster_ids := _recovery_ids(base, stage_index)
		assert_eq(1 << roster_ids.size(), expected_subsets[stage_index])
		for mask: int in range(1 << roster_ids.size()):
			var session := _session(_restore(base.data_copy()))
			var begun := _apply(
				session,
				session["state"].begin_attempt(StringName("s%d" % (stage_index + 1)), roster_ids),
			)
			var ticket: CampaignBattleTicket = session["last_result"]["ticket"]
			var fallen := _mask_ids(roster_ids, mask)
			var outcome := _outcome(ticket, &"defeat", fallen, 0)
			var resolved := _apply(session, _resolve_certified(begun, outcome, ticket))
			var offers := resolved.recovery_offers(StringName("s%d" % (stage_index + 1)))
			assert_true(offers["accepted"])
			assert_eq(offers["offers"].size(), fallen.size())
			for offer: Dictionary in offers["offers"]:
				var recruited := _apply(session, resolved.recruit(offer["offer_id"]))
				resolved = recruited
				recruit_total += 1
			subset_total += 1
	assert_eq(subset_total, 296)
	assert_eq(recruit_total, 812)
	gut.p("P16_RECOVERY_SUBSETS=%d" % subset_total, 0)
	gut.p("P16_RECOVERY_ACCEPTS=%d" % recruit_total, 0)


func test_roster_limit_is_reached_by_1019_recovery_cycles_and_1024_renames() -> void:
	var mode := OS.get_environment("P16_PROPERTY_SEGMENT")
	if mode == "subsets":
		pass_test("inactive roster-limit segment")
		return
	_assert_indexed_recovery_matches_original_scan()
	var start_cycle := {
		"second": 512, "third": 768, "fourth": 896,
	}.get(mode, 0) as int
	var end_cycle := {
		"first": 512, "second": 768, "third": 896,
	}.get(mode, 1019) as int
	var initial := _checkpoint_state(start_cycle) if start_cycle > 0 else _fresh()
	var session := _session(initial)
	var rename_total := 5 + start_cycle
	var recovery_cycles := start_cycle
	var vanguard_id := _ready_operator(session["state"], "vanguard_1").hero_id()
	if start_cycle == 0:
		rename_total = 0
		for index: int in range(5):
			var hero: HeroState = (session["state"] as CampaignState).roster().all()[index]
			_apply(session, (session["state"] as CampaignState).rename_hero(
				hero.hero_id(), "hero_%d" % index,
			))
			rename_total += 1
	for cycle: int in range(start_cycle, end_cycle):
		var state: CampaignState = session["state"]
		var begun := _apply(session, state.begin_attempt(&"s1", [vanguard_id]))
		var ticket: CampaignBattleTicket = session["last_result"]["ticket"]
		var outcome := _outcome(ticket, &"defeat", [vanguard_id], 0)
		var resolved := _apply(session, _resolve_certified(begun, outcome, ticket))
		var recruited := _apply(session, resolved.recruit("recovery:s1:vanguard_1"))
		vanguard_id = String(session["last_result"]["hero_id"])
		var renamed_state := _apply(
			session, recruited.rename_hero(vanguard_id, "hero_%d" % (5 + cycle)),
		)
		recovery_cycles += 1
		rename_total += 1
		assert_eq(renamed_state.next_recruitment_index(), 6 + cycle)
		if (cycle + 1) % 64 == 0:
			_assert_full_equivalent(renamed_state)
		if not OS.get_environment("P16_CAPTURE_DIR").is_empty() and cycle + 1 in [512, 768, 896]:
			_write_checkpoint(renamed_state)
	if end_cycle < 1019:
		var boundary: CampaignState = session["state"]
		_assert_full_equivalent(boundary)
		assert_eq(boundary.next_recruitment_index(), 5 + end_cycle)
		gut.p("P16_ROSTER_SEGMENT=%d:%d" % [start_cycle, end_cycle], 0)
		return
	var full: CampaignState = session["state"]
	_assert_full_equivalent(full)
	assert_eq(full.roster().all().size(), CampaignCodec.MAX_ROSTER)
	var boundary_begun := _apply(session, full.begin_attempt(&"s1", [vanguard_id]))
	var boundary_ticket: CampaignBattleTicket = session["last_result"]["ticket"]
	var boundary_outcome := _outcome(
		boundary_ticket, &"defeat", [vanguard_id], 0,
	)
	var boundary_resolved := _apply(
		session, _resolve_certified(boundary_begun, boundary_outcome, boundary_ticket),
	)
	var before := _snapshot(boundary_resolved)
	var rejected := boundary_resolved.recruit("recovery:s1:vanguard_1")
	assert_false(rejected["accepted"])
	assert_eq(rejected["error_code"], &"roster_limit")
	assert_eq(_snapshot(boundary_resolved), before)
	assert_eq(boundary_resolved.save_revision(), 1 + 1019 * 3 + 1024 + 2)
	assert_eq(recovery_cycles, 1019)
	assert_eq(rename_total, 1024)
	gut.p("P16_ROSTER_LIMIT_CYCLES=%d" % recovery_cycles, 0)
	gut.p("P16_ROSTER_LIMIT_RENAMES=%d" % rename_total, 0)
	gut.p("P16_ROSTER_SEGMENT=%d:%d" % [start_cycle, end_cycle], 0)


func _assert_full_equivalent(state: CampaignState) -> void:
	state._strategic_hash_cache = {}
	var restored := CampaignState.restore(
		state.data_copy(), _definition(), _catalogs(), _stages(),
	)
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	if not restored["accepted"]:
		return
	var cold: CampaignState = restored["value"]
	assert_eq(cold.encode_save()["text"], state._validated_save_text())
	assert_eq(cold.strategic_hash()["hex"], state._validated_hash_hex())


func _checkpoint_state(cycle: int) -> CampaignState:
	var paths := {
		512: CHECKPOINT_512_PATH, 768: CHECKPOINT_768_PATH, 896: CHECKPOINT_896_PATH,
	}
	var hashes := {
		512: CHECKPOINT_512_SHA, 768: CHECKPOINT_768_SHA, 896: CHECKPOINT_896_SHA,
	}
	var path: String = paths[cycle]
	var expected: String = hashes[cycle]
	var source := FileAccess.get_file_as_string(path)
	assert_eq(source.sha256_text(), expected)
	var parser := JSON.new()
	assert_eq(parser.parse(source), OK)
	var exact := CanonicalJson.restore_exact_integers(source, parser.data)
	assert_true(exact["accepted"])
	var restored := CampaignState.restore(
		exact["value"], _definition(), _catalogs(), _stages(),
	)
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	return restored["value"]


func _write_checkpoint(state: CampaignState) -> void:
	var directory := OS.get_environment("P16_CAPTURE_DIR")
	if directory.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(directory)
	var cycle := state.next_recruitment_index() - 5
	var file := FileAccess.open(directory.path_join("roster_limit_checkpoint_%d.json" % cycle),
		FileAccess.WRITE)
	file.store_string(CanonicalJson.text(state.data_copy()))
	file.close()


func _assert_indexed_recovery_matches_original_scan() -> void:
	var heroes: Array = []
	var history := {}
	var context := {"stage_order": ["s1", "s2"]}
	var clears := {"s1": 2, "s2": 4}
	for position: int in range(65):
		for operator_id: String in ["vanguard_1", "guard_1"]:
			for stage_id: String in ["s1", "s2"]:
				for created_after: int in range(6):
					var scanned := CampaignInvariants._recovery_reachable(
						heroes, heroes.size(), operator_id, stage_id,
						created_after, context, clears,
					)
					var indexed := CampaignInvariants._recovery_reachable_indexed(
						history.get(operator_id, {}), stage_id,
						created_after, context, clears,
					)
					assert_eq(indexed, scanned)
		if position == 64:
			continue
		var operator_id := "vanguard_1" if position % 2 == 0 else "guard_1"
		var is_ready := position % 7 == 0
		var death: Variant = {"resolution_index": 1 + position % 5}
		if is_ready:
			death = null
		var hero := {
			"acquisition_operator_def_id": operator_id,
			"operator_def_id": operator_id,
			"life_status": "ready" if is_ready else "dead",
			"death": death,
		}
		heroes.append(hero)
		CampaignInvariants._update_operator_history(history, hero)


func _progress_to(stage_index: int) -> CampaignState:
	var session := _session(_fresh())
	for index: int in range(stage_index):
		var state: CampaignState = session["state"]
		var selected := state.roster().ready()[0].hero_id()
		var begun := _apply(
			session, state.begin_attempt(StringName("s%d" % (index + 1)), [selected]),
		)
		var ticket: CampaignBattleTicket = session["last_result"]["ticket"]
		var outcome := _outcome(ticket, &"clear", [], 3)
		_apply(session, _resolve_certified(begun, outcome, ticket))
	return session["state"]


func _recovery_ids(state: CampaignState, stage_index: int) -> Array[String]:
	var result: Array[String] = []
	var stage := _stages()[stage_index] as StageDef
	for operator_id: StringName in stage.recovery_roster:
		result.append(_ready_operator(state, String(operator_id)).hero_id())
	return result


func _ready_operator(state: CampaignState, operator_id: String) -> HeroState:
	for hero: HeroState in state.roster().ready():
		if String(hero.operator_def_id()) == operator_id:
			return hero
	assert_true(false, "missing ready operator %s" % operator_id)
	return null


func _mask_ids(ids: Array[String], mask: int) -> Array[String]:
	var result: Array[String] = []
	for index: int in ids.size():
		if mask & (1 << index):
			result.append(ids[index])
	return result


func _session(state: CampaignState) -> Dictionary:
	return {"state": state, "current_text": state.encode_save()["text"]}


func _apply(session: Dictionary, command: Dictionary) -> CampaignState:
	assert_true(command["accepted"], str(command.get("error_code", &"")))
	var mutation: CampaignMutation = command["payload"]["mutation"]
	assert_eq(mutation.pre_save_text(), session["current_text"])
	session["current_text"] = mutation.prospective_save_text()
	var next_state: CampaignState = mutation._prospective_state
	var result: Dictionary = mutation._result.duplicate(true)
	session["state"] = next_state
	session["last_result"] = result
	return session["state"]


func _outcome(
	ticket: CampaignBattleTicket,
	result: StringName,
	fallen: Array[String],
	stars: int,
) -> BattleOutcome:
	var heroes: Array[Dictionary] = []
	for row: Dictionary in ticket.manifest():
		var fell := fallen.has(String(row["battle_id"]))
		var first_fall_tick: Variant = null
		if fell:
			first_fall_tick = 60
		heroes.append({
			"hero_id": row["battle_id"],
			"operator_def_id": row["operator_def_id"],
			"deployments": 1,
			"retreats": 0,
			"fell": fell,
			"first_fall_tick": first_fall_tick,
		})
	var data := {
		"schema_version": 1,
		"campaign_uid": ticket.campaign_uid(),
		"attempt_id": ticket.attempt_id(),
		"stage_id": String(ticket.stage_id()),
		"manifest_hash": ticket.manifest_hash(),
		"result": String(result),
		"terminal_reason": "clear" if result == &"clear" else "base_defeat",
		"stars": stars,
		"terminal_tick": 120,
		"model_state_hash": "0000000000000000",
		"heroes": heroes,
	}
	data["outcome_hash"] = CanonicalJson.sha256_hex(data)
	var created := BattleOutcome.from_data(data)
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	return created["value"]


func _resolve_certified(
	state: CampaignState,
	outcome: BattleOutcome,
	ticket: CampaignBattleTicket,
) -> Dictionary:
	assert_eq(ticket.campaign_uid(), outcome.campaign_uid())
	assert_eq(ticket.attempt_id(), outcome.attempt_id())
	assert_eq(ticket.stage_id(), outcome.stage_id())
	assert_eq(ticket.manifest_hash(), outcome.manifest_hash())
	var certified := CampaignHash._derive_certified_transaction(
		ticket.data_copy(), outcome.data_copy(), state._data, state._context,
	)
	assert_true(certified["accepted"], str(certified.get("error_code", &"")))
	if state.next_resolution_index() % 64 == 0:
		var cold := CampaignHash.derive_transaction(
			ticket.data_copy(), outcome.data_copy(), state.data_copy(), state._context,
		)
		assert_eq(cold, certified)
	var next := state._state_from_data(certified["state_after"])
	assert_true(next["accepted"])
	var receipt := CampaignResolution.from_data(certified["resolution"])
	assert_true(receipt["accepted"])
	return {
		"accepted": true,
		"error_code": &"",
		"events": [],
		"payload": {"mutation": CampaignMutation._create(
			&"resolve_attempt", state, next["value"], [],
			{"receipt": receipt["value"], "fresh": true},
		)["value"]},
	}


func _snapshot(state: CampaignState) -> Array[String]:
	return [state.encode_save()["text"], state.strategic_hash()["hex"]]


func _fresh() -> CampaignState:
	var created := CampaignState.create(42, 1, _definition(), _catalogs(), _stages())
	assert_true(created["accepted"])
	return created["value"]


func _restore(data: Dictionary) -> CampaignState:
	var restored := CampaignState.restore(data, _definition(), _catalogs(), _stages())
	assert_true(restored["accepted"])
	return restored["value"]


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
