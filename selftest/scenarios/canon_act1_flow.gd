extends RefCounted

const CONTRACT_PATH := "res://selftest/scenarios/canon_act1_flow.gd.contract.json"
const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const PICKS: Array[StringName] = [&"vanguard_1", &"guard_1", &"defender_1"]
const REQUIRED_SHOTS: Array[String] = [
	"canon_staging_1280x720", "canon_staging_720x1280",
	"canon_s1_squad_1280x720", "canon_s1_squad_720x1280",
	"canon_s6_squad_1280x720", "canon_s8_squad_1280x720",
	"canon_s1_clear_1280x720", "canon_s6_clear_1280x720",
	"canon_s6_defeat_1280x720", "canon_s7_clear_1280x720",
	"canon_s8_clear_1280x720", "canon_missing_record_1280x720",
]

var _requested_shots: Array[String] = []


func run(h: SelfTestHarness) -> void:
	var contract := JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH)) as Dictionary
	h.max_frames = int(contract.get("max_frames", 0))
	h.expect_done()
	h.check("canon contract exact seed", h.seed_value == int(contract.get("seed", -1)))
	h.check("canon contract exact shot basenames", contract.get("shot_basenames", []) == REQUIRED_SHOTS)
	h.check("canon catalog valid", (NARRATIVE_CATALOG as StageNarrativeCatalogType).validate_contract().is_empty())
	if h.max_frames != 4800 or contract.get("shot_basenames", []) != REQUIRED_SHOTS:
		return
	await h.frames(10)
	var game := h.autoload("Game")
	var saved := _save_game(game)
	var ok := await _ordinary_s1(h, game)
	if ok:
		ok = await _projection_sweep(h, game)
	_restore_game(game, saved)
	var requested_sorted := _requested_shots.duplicate()
	var required_sorted := REQUIRED_SHOTS.duplicate()
	requested_sorted.sort()
	required_sorted.sort()
	h.check("canon scenario requested exact twelve-shot basename set", requested_sorted == required_sorted and _requested_shots.size() == 12, str(_requested_shots))
	if ok:
		h.done()


func _ordinary_s1(h: SelfTestHarness, game: Node) -> bool:
	var title := game.get("content") as Control
	var start := _find(title, "StartButton") as Button
	h.check("ordinary Start exists", start != null and start.text == "Start")
	if start == null:
		return false
	await h.click_view(start.get_global_rect().get_center())
	var staging := await _await_screen(h, game, "StagingShell")
	h.check("ordinary Start opens Staging", staging != null)
	if staging == null:
		return false
	await _inspect_staging(h, staging, Vector2i(1280, 720), "canon_staging_1280x720")
	await _inspect_staging(h, staging, Vector2i(720, 1280), "canon_staging_720x1280")
	h.root.size = Vector2i(1280, 720)
	await h.frames(4)
	var staging_scroll := _find(staging, "StagingScroll") as ScrollContainer
	staging_scroll.scroll_vertical = int(staging_scroll.get_v_scroll_bar().max_value)
	await h.frames(3)
	var mission := _find(staging, "MissionControlButton") as Button
	h.check("ordinary Mission Control enabled", mission != null and not mission.disabled)
	if mission == null:
		return false
	await h.click_view(mission.get_global_rect().get_center())
	var select := await _await_screen(h, game, "StageColumn")
	h.check("ordinary Mission Control opens Stage Select", select != null)
	if select == null:
		return false
	var s1 := _find(select, "Stage_s1") as Button
	h.check("ordinary S1 row enabled", s1 != null and not s1.disabled)
	if s1 == null:
		return false
	await h.click_view(s1.get_global_rect().get_center())
	var squad := await _await_screen(h, game, "SquadColumn")
	h.check("ordinary S1 opens Squad Select", squad != null)
	if squad == null:
		return false
	_check_squad_semantics(h, squad, &"s1")
	await _inspect_squad_geometry(h, squad, Vector2i(1280, 720), "canon_s1_squad_1280x720")
	await _inspect_squad_geometry(h, squad, Vector2i(720, 1280), "canon_s1_squad_720x1280")
	h.root.size = Vector2i(1280, 720)
	await h.frames(4)
	var squad_scroll := _find(squad, "SquadScroll") as ScrollContainer
	for op_id: StringName in PICKS:
		var pick := _find(squad, "Pick_%s" % op_id) as Button
		if not await _ensure_scroll_control_visible(
			h, squad_scroll, pick, "ordinary S1 Pick_%s" % op_id,
		):
			return false
		await h.click_view(pick.get_global_rect().get_center())
	var primary := _find(squad, "StartBattle") as Button
	h.check("ordinary S1 primary enabled after picks", primary != null and not primary.disabled)
	if primary == null:
		return false
	if not await _ensure_scroll_control_visible(
		h, squad_scroll, primary, "ordinary S1 StartBattle",
	):
		return false
	primary.grab_focus()
	await h.frames(1)
	h.check("focus reaches S1 primary", primary.has_focus())
	await h.click_view(primary.get_global_rect().get_center())
	return await _clear_real_s1(h, game)


func _clear_real_s1(h: SelfTestHarness, game: Node) -> bool:
	var budget := 120
	while budget > 0 and game.get("current_battle") == null:
		budget -= 1
		await h.frames(1)
	var model: BattleModel = game.get("current_battle")
	h.check("production S1 battle booted", model != null and model.stage.id == &"s1")
	if model == null:
		return false
	var view := game.get("content") as Node
	view.set("ticks_per_frame_scale", 0.0)
	var bot: StageBot = (load("res://playtests/bots/bot_stage_01.gd") as GDScript).new()
	var timeline: Array = bot.timeline()
	timeline.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	var index := 0
	while model.result == BattleModel.Result.RUNNING and model.tick < 4000:
		while index < timeline.size() and int(timeline[index][0]) == model.tick:
			h.check("real S1 scripted action accepted", model.apply_action((timeline[index] as Array).slice(1)))
			index += 1
		model.step()
		if model.tick % 300 == 0:
			await h.frames(1)
	h.check("real S1 clears", model.result == BattleModel.Result.CLEAR)
	await h.frames(4)
	var continue_button := _find(view, "ContinueButton") as Button
	h.check("real S1 Continue appears", continue_button != null)
	if continue_button == null:
		return false
	await h.click_view(continue_button.get_global_rect().get_center())
	var results := await _await_screen(h, game, "ResultsColumn")
	h.check("real S1 Results opens", results != null)
	if results == null:
		return false
	_check_result_semantics(h, results, &"s1", true)
	await _inspect_results_geometry(h, results, "canon_s1_clear_1280x720")
	return true


func _projection_sweep(h: SelfTestHarness, game: Node) -> bool:
	for stage_id: StringName in [&"s1", &"s2", &"s3", &"s4", &"s5", &"s6", &"s7", &"s8"]:
		game.set("selected_stage_id", stage_id)
		game.call("open_squad_select")
		var squad := await _await_screen(h, game, "SquadColumn")
		h.check("%s Squad projection opens" % stage_id, squad != null)
		if squad == null:
			return false
		_check_squad_semantics(h, squad, stage_id)
		if stage_id == &"s6":
			await _inspect_squad_geometry(h, squad, Vector2i(1280, 720), "canon_s6_squad_1280x720")
		elif stage_id == &"s8":
			await _inspect_squad_geometry(h, squad, Vector2i(1280, 720), "canon_s8_squad_1280x720")
		var result_kinds: Array[int] = [BattleModel.Result.CLEAR]
		if stage_id == &"s6":
			result_kinds.append(BattleModel.Result.DEFEAT)
		for result_kind: int in result_kinds:
			game.set("last_result", {
				"stage_id": stage_id, "result": result_kind,
				"stars": 3 if result_kind == BattleModel.Result.CLEAR else 0,
				"leaks": 0 if result_kind == BattleModel.Result.CLEAR else 3,
				"kills": 12, "rewards_granted": [],
			})
			game.call("open_results")
			var results := await _await_screen(h, game, "ResultsColumn")
			h.check("%s Results projection opens" % stage_id, results != null)
			if results == null:
				return false
			_check_result_semantics(h, results, stage_id, result_kind == BattleModel.Result.CLEAR)
			var shot := _result_shot(stage_id, result_kind)
			if not shot.is_empty():
				await _inspect_results_geometry(h, results, shot)
	return await _missing_record_projection(h, game)


func _missing_record_projection(h: SelfTestHarness, game: Node) -> bool:
	var catalog := NARRATIVE_CATALOG as StageNarrativeCatalogType
	var saved_records := catalog.records.duplicate()
	catalog.records[0] = null
	game.set("selected_stage_id", &"s1")
	game.call("open_squad_select")
	var squad := await _await_screen(h, game, "SquadColumn")
	catalog.records = saved_records
	h.check("missing record Squad opens", squad != null)
	if squad == null:
		return false
	var primary := _find(squad, "StartBattle") as Button
	var objective := _find(squad, "BriefingObjective") as Label
	h.check("missing record disables pre-battle primary", primary != null and primary.disabled)
	h.check("missing record renders exact fallback", objective != null and objective.text.contains("Mission record unavailable. Return to Mission Control."))
	h.root.size = Vector2i(1280, 720)
	await h.frames(5)
	_check_rect(h, objective, _find(squad, "SquadScroll") as Control, "missing narrative fallback")
	await _shot(h, "canon_missing_record_1280x720", Vector2i(1280, 720))
	return true


func _inspect_staging(h: SelfTestHarness, staging: Control, viewport: Vector2i, shot: String) -> void:
	h.root.size = viewport
	await h.frames(5)
	var heading := _find(staging, "CompanyCommandHeading") as Label
	var body := _find(staging, "CompanyCommandBody") as Label
	var title := _find(staging, "NextOperationTitle") as Label
	var objective := _find(staging, "NextOperationObjective") as Label
	var scroll := _find(staging, "StagingScroll") as Control
	h.check("Company 33 visible", heading != null and heading.text.to_lower().contains("company 33"))
	h.check("Staging canon terms visible", body != null and body.text.contains("Hearthcross") and body.text.contains("Great Flare") and body.text.contains("Custodian"))
	h.check("Staging S1 next title", title != null and title.text == "NEXT 1: First Stand")
	h.check("Staging dense heading exact", heading != null and heading.get_theme_font_size(&"font_size") == 32)
	h.check("Staging dense body exact", body != null and body.get_theme_font_size(&"font_size") == 26)
	h.check("Staging next title exact", title != null and title.get_theme_font_size(&"font_size") == 28)
	h.check("Staging objective exact", objective != null and objective.get_theme_font_size(&"font_size") == 26)
	for node: Control in [heading, body, title, objective]:
		_check_rect(h, node, scroll, "%s %s" % [shot, node.name if node != null else "missing"])
	await _shot(h, shot, viewport)


func _check_squad_semantics(h: SelfTestHarness, squad: Control, stage_id: StringName) -> void:
	var record: StageNarrativeDefType = (NARRATIVE_CATALOG as StageNarrativeCatalogType).get_record(stage_id)
	h.check("%s narrative record exact" % stage_id, record != null and record.id == stage_id)
	for specification: Array in [
		["BriefingObjective", StageNarrativeDefType.Field.OBJECTIVE],
		["BriefingThreat", StageNarrativeDefType.Field.THREAT],
		["BriefingHumanReason", StageNarrativeDefType.Field.HUMAN_REASON],
		["BriefingClue", StageNarrativeDefType.Field.CLUE],
	]:
		var label := _find(squad, specification[0]) as Label
		var expected := UiCopyType.stage_narrative_text(record, specification[1])
		h.check("%s %s full copy" % [stage_id, specification[0]], label != null and label.text.ends_with(expected), label.text if label != null else "missing")
		h.check("%s %s dense font exact" % [stage_id, specification[0]], label != null and label.get_theme_font_size(&"font_size") == 26)
	var hint := _find(squad, "TacticalHint") as Label
	var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
	h.check("%s full tactical hint" % stage_id, hint != null and hint.text.ends_with(UiCopyType.stage_hint(stage)))
	h.check("%s tactical hint dense font exact" % stage_id, hint != null and hint.get_theme_font_size(&"font_size") == 26)


func _inspect_squad_geometry(h: SelfTestHarness, squad: Control, viewport: Vector2i, shot: String) -> void:
	h.root.size = viewport
	await h.frames(5)
	var scroll := _find(squad, "SquadScroll") as Control
	var grid := _find(squad, "OperatorGrid") as Control
	var start := _find(squad, "StartBattle") as Control
	var heading := _find(squad, "SquadHeading") as Label
	h.check("%s squad heading dense font exact" % shot, heading != null and heading.get_theme_font_size(&"font_size") == 32)
	for node_name: String in ["BriefingObjective", "BriefingThreat", "BriefingHumanReason", "BriefingClue", "TacticalHint"]:
		var node := _find(squad, node_name) as Control
		_check_rect(h, node, scroll, "%s %s" % [shot, node_name])
		if viewport.x >= viewport.y and node != null and grid != null:
			h.check("%s does not overlap roster" % node_name, not node.get_global_rect().intersects(grid.get_global_rect()))
	if start != null and grid != null:
		h.check("primary action does not overlap roster", not start.get_global_rect().intersects(grid.get_global_rect()))
	await _shot(h, shot, viewport)


func _check_result_semantics(h: SelfTestHarness, results: Control, stage_id: StringName, clear: bool) -> void:
	var record: StageNarrativeDefType = (NARRATIVE_CATALOG as StageNarrativeCatalogType).get_record(stage_id)
	var field := StageNarrativeDefType.Field.CLEAR_DEBRIEF if clear else StageNarrativeDefType.Field.DEFEAT_DEBRIEF
	var consequence := _find(results, "ConsequenceLine") as Label
	h.check("%s exact %s consequence" % [stage_id, "clear" if clear else "defeat"], consequence != null and consequence.text == UiCopyType.stage_narrative_text(record, field), consequence.text if consequence != null else "missing")
	h.check("%s consequence dense font exact" % stage_id, consequence != null and consequence.get_theme_font_size(&"font_size") == 28)
	for action_name: String in ["RetryButton", "ReturnToStaging", "BackToTitle"]:
		var action := _find(results, action_name) as Button
		h.check("post-battle %s remains enabled" % action_name, action != null and not action.disabled)


func _inspect_results_geometry(h: SelfTestHarness, results: Control, shot: String) -> void:
	h.root.size = Vector2i(1280, 720)
	await h.frames(5)
	var scroll := _find(results, "ResultsScroll") as ScrollContainer
	var heading := _find(results, "ConsequenceHeading") as Label
	var line := _find(results, "ConsequenceLine") as Label
	var actions := _find(results, "ActionRow") as Control
	h.check("%s consequence heading dense font exact" % shot, heading != null and heading.get_theme_font_size(&"font_size") == 32)
	if scroll != null and line != null:
		scroll.ensure_control_visible(line)
		await h.frames(3)
	_check_rect(h, heading, scroll, "%s consequence heading" % shot)
	_check_rect(h, line, scroll, "%s consequence line" % shot)
	if line != null and actions != null:
		h.check("%s consequence does not overlap actions" % shot, not line.get_global_rect().intersects(actions.get_global_rect()))
	await _shot(h, shot, Vector2i(1280, 720))


func _result_shot(stage_id: StringName, result_kind: int) -> String:
	if stage_id == &"s6":
		return "canon_s6_clear_1280x720" if result_kind == BattleModel.Result.CLEAR else "canon_s6_defeat_1280x720"
	if stage_id == &"s7" and result_kind == BattleModel.Result.CLEAR:
		return "canon_s7_clear_1280x720"
	if stage_id == &"s8" and result_kind == BattleModel.Result.CLEAR:
		return "canon_s8_clear_1280x720"
	return ""


func _shot(h: SelfTestHarness, shot: String, viewport: Vector2i) -> void:
	_requested_shots.append(shot)
	var image := await h.shot_grab(shot)
	if DisplayServer.get_name() == "headless":
		h.check("%s headless capture skipped" % shot, image == null)
	else:
		h.check("%s exact image size" % shot, image != null and image.get_size() == viewport)


func _check_rect(h: SelfTestHarness, node: Control, owner: Control, label: String) -> void:
	h.check("%s exists" % label, node != null)
	if node == null:
		return
	var rect := node.get_global_rect()
	h.check("%s nonzero visible" % label, node.is_visible_in_tree() and rect.size.x > 0.0 and rect.size.y > 0.0, str(rect))
	if owner != null:
		var in_scroll_content := owner is ScrollContainer and owner.is_ancestor_of(node)
		h.check("%s inside %s" % [label, owner.name], in_scroll_content or owner.get_global_rect().intersects(rect), "%s in %s" % [rect, owner.get_global_rect()])


func _ensure_scroll_control_visible(
		h: SelfTestHarness, scroll: ScrollContainer, control: Control, label: String,
	) -> bool:
	h.check("%s scroll seam exists" % label, scroll != null)
	h.check("%s control exists" % label, control != null)
	if scroll == null or control == null:
		return false
	scroll.ensure_control_visible(control)
	await h.frames(3)
	var control_rect := control.get_global_rect()
	var viewport_rect := scroll.get_global_rect()
	var visible := (
		control.is_visible_in_tree()
		and control_rect.size.x > 0.0
		and control_rect.size.y > 0.0
		and viewport_rect.intersects(control_rect)
	)
	h.check(
		"%s intersects SquadScroll viewport" % label,
		visible,
		"%s in %s" % [control_rect, viewport_rect],
	)
	return visible


func _save_game(game: Node) -> Dictionary:
	return {
		"campaign": game.get("campaign"), "campaign_active": game.get("campaign_active"),
		"pending_stage": game.get("pending_stage"), "current_battle": game.get("current_battle"),
		"selected_stage_id": game.get("selected_stage_id"),
		"selected_squad": (game.get("selected_squad") as Array).duplicate(),
		"last_result": (game.get("last_result") as Dictionary).duplicate(true),
		"debug_override": game.get("_debug_catalog_override"),
	}


func _restore_game(game: Node, saved: Dictionary) -> void:
	game.set("campaign", saved["campaign"])
	game.set("campaign_active", saved["campaign_active"])
	game.set("pending_stage", saved["pending_stage"])
	game.set("current_battle", saved["current_battle"])
	game.set("selected_stage_id", saved["selected_stage_id"])
	game.set("selected_squad", saved["selected_squad"])
	game.set("last_result", saved["last_result"])
	game.set("_debug_catalog_override", saved["debug_override"])


func _find(root: Node, node_name: String) -> Node:
	if root == null:
		return null
	if root.name == node_name:
		return root
	return root.find_child(node_name, true, false)


func _await_screen(h: SelfTestHarness, game: Node, marker: String) -> Control:
	var budget := 120
	while budget > 0:
		var content := game.get("content") as Node
		if content != null and is_instance_valid(content) and content is Control and _find(content, marker) != null:
			var candidate := content as Control
			await h.frames(3)
			if is_instance_valid(candidate) and game.get("content") == candidate and _find(candidate, marker) != null:
				return candidate
		budget -= 1
		await h.frames(1)
	return null
