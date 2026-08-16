class_name RecruitPromotionScenarioSupport
extends RefCounted

const BattleModelType := preload("res://sim/battle_model.gd")
const GameConfigType := preload("res://data/game_config.gd")
const StageDefType := preload("res://data/stage_def.gd")
const S1 := preload("res://data/stages/s1.tres")
const CONFIG := preload("res://data/config/game.tres")
const MAX_MODEL_TICKS := 2_400


func prepare_eligible_recruit(h: SelfTestHarness, game: Node) -> Dictionary:
	var started := bool(game.call("start_campaign", false, true))
	h.check("fresh v3 campaign starts", started)
	if not started:
		return {}
	var initial: Array = game.call("campaign_projection")["ready_heroes"]
	h.check("five Recruit starters exist", initial.size() == 5)
	if initial.size() < 3:
		return {}
	var hero_ids: Array[StringName] = []
	for hero: Dictionary in initial.slice(0, 3):
		hero_ids.append(StringName(hero["hero_id"]))
	var target_id := String(hero_ids[2])
	var target_before := _hero_by_id(game, target_id)
	var begun: Dictionary = game.call("start_stage", &"s1", hero_ids, false)
	h.check(
		"real S1 attempt begins", begun.get("accepted", false),
		str(begun.get("error_code", &"")),
	)
	if not begun.get("accepted", false):
		return {}
	var launch: Dictionary = game.call("battle_launch")
	var model := (
		BattleModelType
		. create(
			S1 as StageDefType,
			launch["input"],
			42,
			CONFIG as GameConfigType,
			_catalog("res://data/enemies"),
			_catalog("res://data/operators"),
			_catalog("res://data/traps"),
			_catalog("res://data/spells"),
			launch["trusted_ticket_hashes"],
		)
	)
	h.check("ticket creates S1 BattleModel", model != null)
	if model == null:
		return {}
	var ticket: Dictionary = begun["ticket"]
	var timeline: Array = [
		[6, &"deploy", StringName(ticket["squad"][0]["battle_id"]), Vector2i(3, 2), 0],
		[180, &"deploy", StringName(ticket["squad"][1]["battle_id"]), Vector2i(1, 2), 0],
		[420, &"deploy", StringName(ticket["squad"][2]["battle_id"]), Vector2i(2, 2), 0],
		[860, &"retreat", 1],
		[1040, &"retreat", 0],
	]
	var action_index := 0
	while model.result == BattleModelType.Result.RUNNING and model.tick < MAX_MODEL_TICKS:
		while action_index < timeline.size() and int(timeline[action_index][0]) == model.tick:
			h.check(
				"S1 training action accepted",
				model.apply_action((timeline[action_index] as Array).slice(1)),
				str(timeline[action_index]),
			)
			action_index += 1
		model.step()
		if model.tick % 300 == 0:
			await h.frames(1)
	h.check(
		"S1 training clear stays within pinned budget",
		model.result == BattleModelType.Result.CLEAR,
		"tick=%d leaked=%d" % [model.tick, model.leaked],
	)
	game.set("current_battle", model)
	var committed := bool(game.call("record_result", model.result, model.stars))
	h.check("S1 outcome commits durably", committed)
	if not committed:
		return {}
	var target_after := _hero_by_id(game, target_id)
	h.check(
		"target Recruit earns exactly first-promotion XP",
		int(target_after.get("xp", -1)) == 100,
		str(target_after),
	)
	return {
		"target_id": target_id,
		"eligible_ids": [String(hero_ids[0]), String(hero_ids[1]), target_id],
		"target_before": target_before,
		"target_after": target_after,
		"initial": initial,
		"revision_after_result": game.get("campaign").save_revision(),
	}


func open_results_training(h: SelfTestHarness, game: Node) -> Control:
	game.call("open_results")
	var results := await await_screen(h, game, "ResultsColumn")
	h.check("Results opens after committed S1", results != null)
	if results == null:
		return null
	var training := find(results, "TrainRecruits") as Button
	var count := find(results, "TrainingAvailable") as Label
	h.check(
		"Results exposes Train Recruits without hiding debrief",
		training != null and not training.disabled and count != null
		and find(results, "Headline") != null and find(results, "ReturnToStaging") != null,
	)
	return results


func open_training_from_results(
	h: SelfTestHarness, game: Node, results: Control,
) -> Control:
	var button := find(results, "TrainRecruits") as Button
	await ensure_visible(h, button)
	await h.click_view(button.get_global_rect().get_center())
	var training := await await_screen(h, game, "TrainingRoot")
	h.check("Results Train Recruits opens v3 board", training != null)
	return training


func draft_choice(
	h: SelfTestHarness, training: Control, hero_id: String, class_id: String,
) -> bool:
	var row := find(training, "Recruit_%s" % hero_id) as Button
	if row == null:
		h.check("target Recruit row exists", false, hero_id)
		return false
	var callsign := row.find_child("Callsign", true, false) as Control
	await ensure_visible(h, callsign)
	row.pressed.emit()
	await h.frames(3)
	h.check(
		"target Recruit selection is projected",
		String(training.call("selected_hero_id")) == hero_id,
		hero_id,
	)
	var paths := find(training, "ViewPaths") as Button
	await ensure_visible(h, paths)
	await h.click_view(paths.get_global_rect().get_center())
	await h.frames(3)
	var card := find(training, "Path_%s" % class_id) as Button
	if card == null:
		h.check("destination class card exists", false, class_id)
		return false
	var heading := card.find_child("AdvancedClassName", true, false) as Control
	await ensure_visible(h, heading)
	await h.click_view(heading.get_global_rect().get_center())
	var add := find(training, "ChoosePath") as Button
	var selected := add != null and not add.disabled
	h.check("class card selection enables Add to Plan", selected, class_id)
	if not selected:
		return false
	await ensure_visible(h, add)
	h.check(
		"Add to Plan is inside the viewport",
		Rect2(Vector2.ZERO, Vector2(h.root.size)).has_point(
			add.get_global_rect().get_center(),
		),
		str(add.get_global_rect()),
	)
	add.grab_focus()
	await h.frames(2)
	add.pressed.emit()
	await h.frames(3)
	var drafted := find(training, "Recruit_%s" % hero_id) as Button
	var draft_choices: Array = training.call("_draft_choices")
	var expected := false
	for choice: Dictionary in draft_choices:
		if (
			String(choice["hero_id"]) == hero_id
			and String(choice["to_class_id"]) == class_id
		):
			expected = true
	var accepted: bool = (
		training.call("mode") == &"roster"
		and drafted != null and expected
	)
	h.check(
		"Add to Plan records the local draft",
		accepted,
		"%s hero=%s selected=%s mode=%s row=%s draft=%s" % [
			class_id, hero_id, training.call("selected_hero_id"), training.call("mode"),
			drafted.text if drafted != null else "missing",
			draft_choices,
		],
	)
	return accepted


func open_review(h: SelfTestHarness, training: Control) -> Control:
	var review := find(training, "ReviewPlan") as Button
	if review == null:
		h.check("Review Plan action exists", false)
		return null
	await ensure_visible(h, review)
	await h.click_view(review.get_global_rect().get_center())
	await h.frames(3)
	h.check("Review state opens", training.call("mode") == &"review")
	return training


func authority_facts(game: Node) -> Dictionary:
	var campaign: Variant = game.get("campaign")
	return {
		"text": campaign.encode_save()["text"],
		"strategic": campaign.strategic_hash(),
		"core": campaign.core_hash(),
		"revision": campaign.save_revision(),
		"receipts": campaign.data_copy()["promotion_receipts"].duplicate(true),
		"roster": campaign.data_copy()["heroes"].duplicate(true),
	}


func hero_by_id(game: Node, hero_id: String) -> Dictionary:
	return _hero_by_id(game, hero_id)


func await_screen(
	h: SelfTestHarness, game: Node, marker: String,
) -> Control:
	var budget := 120
	while budget > 0:
		var content := game.get("content") as Node
		if content != null and is_instance_valid(content) and content is Control:
			if content.name == marker or content.find_child(marker, true, false) != null:
				await h.frames(3)
				return content
		budget -= 1
		await h.frames(1)
	return null


func ensure_visible(h: SelfTestHarness, control: Control) -> void:
	if control == null:
		return
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			(parent as ScrollContainer).ensure_control_visible(control)
		parent = parent.get_parent()
	await h.frames(3)


func find(root: Node, node_name: String) -> Node:
	if root == null:
		return null
	return root if root.name == node_name else root.find_child(node_name, true, false)


func _hero_by_id(game: Node, hero_id: String) -> Dictionary:
	for hero: Dictionary in game.get("campaign").data_copy()["heroes"]:
		if String(hero["hero_id"]) == hero_id:
			return hero
	return {}


func _catalog(path: String) -> Dictionary:
	var result := {}
	var directory := DirAccess.open(path)
	for filename: String in directory.get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var resource: Resource = load("%s/%s" % [path, source])
			result[resource.get("id")] = resource
	return result
