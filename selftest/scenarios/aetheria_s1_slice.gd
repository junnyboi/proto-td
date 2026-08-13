extends RefCounted

## AUI-20 focused playable proof. The campaign route and the new raw deploy /
## skill surfaces use live Controls; measured stretches use campaign_flow's
## incumbent paused-view + direct model-step seam so tick actions stay exact.

const PICKS: Array[StringName] = [&"vanguard_1", &"guard_1", &"defender_1"]
const VANGUARD_CELL := Vector2i(3, 2)
const GUARD_CELL := Vector2i(4, 2)
const DEFENDER_CELL := Vector2i(5, 2)
const INVALID_CELL := Vector2i(0, 2)
const RIGHT := int(UnitState.Facing.RIGHT)
const PROOF_VIEWPORT := Vector2i(1920, 1080)
const SETTLE_TRANSIENT_FRAMES := 46
const CUES_PATH := "res://data/presentation/s1_slice_cues.tres"
const FIXTURE_CONTRACT_SHA256 := "bd0f253b561a530905eb862dd1640ca53f940c9700fd4087a8592f018174f97f"
const VANGUARD_SHA256 := "ab72a790deb56d6899fb0d40ec32e725ff8688f80e1542102f8c081c2209e85c"
const GRUNT_SHA256 := "be7095a1a58a33bd70ef5ad8c913255a4bcc57a1a3ce5d2f5411d8f0a6e747ba"
const SOURCE_PATHS: Array[String] = [
	"res://assets/sprites/aui20_fixture_vanguard_1.png",
	"res://assets/sprites/aui20_fixture_grunt.png",
	"res://data/presentation/s1_slice_fixture_manifest.gd",
	"res://data/presentation/s1_slice_fixture_manifest.tres",
	"res://data/presentation/s1_slice_cues.tres",
]


func run(h: SelfTestHarness) -> void:
	# 902 model ticks are stepped at model speed; the budget covers the real
	# shell route, raw-input holds, seven conditional shots, and swap polling.
	h.max_frames = 3000
	h.expect_done()
	await h.frames(10)
	var source_before := _source_hashes()
	var route := await _route_to_paused_battle(h)
	if route.is_empty():
		return
	var game: Node = route[&"game"]
	var model: BattleModel = route[&"model"]
	var view: Node2D = route[&"view"]
	h.check("picked squad reaches the model unchanged", model.squad == PICKS, str(model.squad))
	h.root.size = PROOF_VIEWPORT
	await h.frames(5)

	var cues := load(CUES_PATH) as TacticalCueConfig
	var manifest := _check_fixture_contract(h, view, model)
	_check_world_and_cues(h, view, model, cues)
	_check_battle_accessibility(h, view)
	_check_control_union(h, view)
	await _capture_still(h, "s1_route_core_idle", model)

	# Exact tick-6 raw deployment: legal and invalid states are captured from
	# the same drag, then the incumbent four-button FacingRight chooser commits.
	_step_exact(model, 6)
	h.check("placement begins at exact tick 6", model.tick == 6)
	await _settle_presentation(h, model, "tick 6 placement")
	var bar := view.find_child("DeployBar", true, false) as Control
	var slot := bar.find_child("Slot_vanguard_1", true, false) as Button
	h.check("live S1 vanguard slot is enabled", slot != null and not slot.disabled)
	if slot == null:
		return
	await h.press_mouse_at(slot.get_global_rect().get_center())
	h.move_mouse_to_view(view.call("cell_center", VANGUARD_CELL))
	await h.frames(3)
	var cursor := bar.find_child("CursorRect", true, false) as Polygon2D
	var legal_color: Color = cues.cues[&"legal"][&"color"]
	var invalid_color: Color = cues.cues[&"invalid"][&"color"]
	h.check(
		"legal placement uses the approved legal cue",
		cursor != null and cursor.visible and cursor.color == legal_color
	)
	await _capture_still(h, "legal_placement", model)
	h.move_mouse_to_view(view.call("cell_center", INVALID_CELL))
	await h.frames(3)
	h.check(
		"S1 spawn is authoritatively invalid", not model.can_deploy_at(&"vanguard_1", INVALID_CELL)
	)
	h.check(
		"invalid placement differs from legal",
		cursor.color == invalid_color and invalid_color != legal_color
	)
	await _capture_still(h, "invalid_placement", model)
	h.move_mouse_to_view(view.call("cell_center", VANGUARD_CELL))
	await h.frames(2)
	await h.release_mouse_at(view.call("cell_center", VANGUARD_CELL))
	await h.frames(3)
	var face_right := bar.find_child("FacingRight", true, false) as Button
	h.check(
		"FacingRight is a live >=44 px control",
		face_right != null and face_right.visible and _large_enough(face_right)
	)
	if face_right == null:
		return
	await h.click_view(face_right.get_global_rect().get_center())
	await h.frames(3)
	var vanguard := model.alive_unit_at(VANGUARD_CELL)
	h.check("raw deployment lands at tick 6", model.tick == 6 and vanguard != null)
	h.check(
		"raw deployment commits FacingRight", vanguard != null and int(vanguard.facing) == RIGHT
	)
	if vanguard == null:
		return
	_check_vanguard_fixture(h, view, manifest, vanguard)

	# One real unit click exposes range; the expected nodes derive from the same
	# Targeting.range_cells call as production, never copied geometry.
	await h.click_view(view.call("cell_center", VANGUARD_CELL))
	await h.frames(3)
	_check_authoritative_range(h, view, vanguard)
	await _capture_still(h, "first_deploy", model)

	await _step_to(h, model, 306)
	(
		h
		. check(
			"guard action accepted at tick 306",
			(
				model.tick == 306
				and (
					model
					. apply_action(
						[
							&"deploy",
							&"guard_1",
							GUARD_CELL,
							RIGHT,
						]
					)
				)
			)
		)
	)
	await _step_to(h, model, 331)
	h.check("no early kill before measured observation", model.tick == 331 and model.killed == 0)
	model.step()
	h.check("first kill observed exactly at tick 332", model.tick == 332 and model.killed == 1)

	await _step_to(h, model, 456)
	h.check(
		"vanguard is skill-ready exactly at tick 456",
		model.tick == 456 and vanguard.is_skill_ready()
	)
	await _settle_presentation(h, model, "tick 456 skill ready")
	var ready_ring := bar.find_child("SkillReadyRing", true, false) as Line2D
	var ready_text := view.find_child("SkillReadinessReport", true, false) as Label
	h.check("authoritative skill-ready ring is visible", ready_ring != null and ready_ring.visible)
	h.check(
		"normal readiness text is >=32 px",
		(
			ready_text != null
			and ready_text.text.contains("SKILL READY")
			and ready_text.get_theme_font_size("font_size") >= 32
			)
		)
	_check_readiness_report(h, ready_text, "Shock Trooper")
	await _capture_still(h, "skill_ready", model)
	await h.click_view(view.call("cell_center", VANGUARD_CELL))
	h.check(
		"real vanguard click fires at tick 456",
		vanguard.skill_triggered_tick == 456 and vanguard.sp == 0
	)
	h.check("real vanguard skill increments the exact model counter", model.skills_fired == 1)

	await _step_to(h, model, 800)
	(
		h
		. check(
			"defender action accepted at tick 800",
			(
				model.tick == 800
				and (
					model
					. apply_action(
						[
							&"deploy",
							&"defender_1",
							DEFENDER_CELL,
							RIGHT,
						]
					)
				)
			)
		)
	)
	model.step()
	var tick_801_exact := (
		model.tick == 801
		and model.units.size() == 3
		and model.alive_enemy_count() == 2
		and model.spawned == 6
		and model.killed == 4
		and model.leaked == 0
		and model.result == BattleModel.Result.RUNNING
	)
	h.check("tick 801 exact dense-state contract", tick_801_exact, _tally(model))
	await _settle_presentation(h, model, "tick 801 dense state")
	_check_enemy_fixture(h, view, manifest, model)
	_check_route_core_visible(h, view, "dense tick 801")
	_check_readiness_report(h, ready_text, "Swordmaster")
	await _capture_still(h, "dense_tick_801", model)

	await _step_to(h, model, 901)
	h.check(
		"S1 remains RUNNING through tick 901",
		model.tick == 901 and model.result == BattleModel.Result.RUNNING
	)
	model.step()
	var terminal_exact := (
		model.tick == 902
		and model.result == BattleModel.Result.CLEAR
		and model.killed == 6
		and model.leaked == 0
		and model.stars == 3
	)
	h.check("tick 902 exact CLEAR contract", terminal_exact, _tally(model))
	await h.frames(5)
	var continue_button := view.find_child("ContinueButton", true, false) as Button
	h.check(
		"terminal exposes the real Continue control",
		continue_button != null and _large_enough(continue_button)
	)
	if continue_button == null:
		return
	await h.click_view(continue_button.get_global_rect().get_center())
	var results := await _await_screen(h, game, "ResultsColumn")
	h.check("Continue routes to Results", results != null)
	if results == null:
		return
	_check_results(h, results, model)
	await h.shot("results")

	h.check("approved presentation sources were never written", _source_hashes() == source_before)
	h.check(
		"fixture hashes still match after the playable run",
		manifest != null and manifest.files_match_hashes()
	)
	h.done()


func _route_to_paused_battle(h: SelfTestHarness) -> Dictionary:
	var route: Dictionary = {}
	var game := h.autoload("Game")
	while true:
		var start := (
			(game.get("content") as Control).find_child("StartButton", true, false) as Button
		)
		h.check("title exposes the real Start control", start != null and start.text == "Start")
		if start == null:
			break
		await h.click_view(start.get_global_rect().get_center())
		var staging := await _await_screen(h, game, "StagingRoot")
		h.check("Start routes to Staging", staging != null)
		if staging == null:
			break
		var mission := staging.find_child("MissionControlButton", true, false) as Button
		h.check("Staging exposes Mission Control", mission != null)
		if mission == null:
			break
		var staging_scroll := staging.find_child("StagingScroll", true, false) as ScrollContainer
		if staging_scroll != null:
			staging_scroll.ensure_control_visible(mission)
			await h.frames(3)
		await h.click_view(mission.get_global_rect().get_center())
		var stages := await _await_screen(h, game, "StageColumn")
		h.check("Mission Control routes to stage select", stages != null)
		if stages == null:
			break
		var s1 := stages.find_child("Stage_s1", true, false) as Button
		h.check("S1 is a live unlocked control", s1 != null and not s1.disabled)
		if s1 == null:
			break
		await h.click_view(s1.get_global_rect().get_center())
		var squad := await _await_screen(h, game, "SquadColumn")
		h.check("S1 routes to squad select", squad != null)
		if squad == null:
			break
		var squad_scroll := squad.find_child("SquadScroll", true, false) as ScrollContainer
		var all_picks_present := true
		for op_id: StringName in PICKS:
			var pick := squad.find_child("Pick_%s" % op_id, true, false) as Button
			h.check("squad exposes %s" % op_id, pick != null)
			if pick == null:
				all_picks_present = false
				break
			if squad_scroll != null:
				squad_scroll.ensure_control_visible(pick)
				await h.frames(3)
			await h.click_view(pick.get_global_rect().get_center())
		if not all_picks_present:
			break
		var counter := squad.find_child("PickCounter", true, false) as Label
		var battle_start := squad.find_child("StartBattle", true, false) as Button
		h.check(
			"real squad controls select exactly 3/3",
			counter != null and counter.text.begins_with("3/3")
		)
		h.check(
			"Start Battle enables after the three picks",
			battle_start != null and not battle_start.disabled
		)
		if battle_start == null:
			break
		if squad_scroll != null:
			squad_scroll.ensure_control_visible(battle_start)
			await h.frames(3)
		await h.click_view(battle_start.get_global_rect().get_center())
		var model := await _await_paused_battle(h, game)
		h.check("real shell route boots seeded S1", model != null and model.stage.id == &"s1")
		if model == null:
			break
		route = {&"game": game, &"model": model, &"view": game.get("content") as Node2D}
		break
	return route


func _settle_presentation(h: SelfTestHarness, model: BattleModel, label: String) -> void:
	var tick_before := model.tick
	await h.frames(SETTLE_TRANSIENT_FRAMES)
	h.check(
		"%s settles render transients without model movement" % label, model.tick == tick_before
	)


func _check_fixture_contract(
	h: SelfTestHarness,
	view: Node2D,
	model: BattleModel,
) -> S1SliceFixtureManifest:
	var manifest := (
		load("res://data/presentation/s1_slice_fixture_manifest.tres") as S1SliceFixtureManifest
	)
	h.check("approved fixture manifest loads", manifest != null)
	if manifest == null:
		return null
	h.check(
		"fixture manifest contract is exact",
		(
			manifest.validate_contract().is_empty()
			and manifest.fixture_contract_sha256 == FIXTURE_CONTRACT_SHA256
		)
	)
	h.check(
		"fixture manifest is the live S1 selector",
		view.get("_s1_fixture") == manifest and manifest.stage_id == model.stage.id
	)
	h.check(
		"approved atlas hashes are exact",
		(
			manifest.files_match_hashes()
			and manifest.entry_sha256(&"operator") == VANGUARD_SHA256
			and manifest.entry_sha256(&"enemy") == GRUNT_SHA256
		)
	)
	return manifest


func _check_world_and_cues(
	h: SelfTestHarness, view: Node2D, model: BattleModel, cues: TacticalCueConfig
) -> void:
	var theme := StageArtTheme.load_for(model.stage)
	h.check(
		"approved S1 world theme is active",
		theme != null and theme.applies_to(model.stage) and theme.human_final_art
	)
	var grid := view.find_child("GridRoot", true, false) as Node2D
	var route := grid.get_node_or_null("Tile_7_2") as TextureRect
	var core := grid.get_node_or_null("CoreLandmark") as TextureRect
	h.check(
		"S1 route uses the approved world texture",
		route != null and route.texture == Art.texture(theme.route_id)
	)
	h.check(
		"S1 Core uses the approved landmark texture",
		core != null and core.texture == Art.texture(theme.core_landmark_id)
	)
	_check_route_core_visible(h, view, "idle")
	h.check("approved S1 cue contract loads", cues != null and cues.validate_contract().is_empty())
	if cues != null:
		h.check(
			"warning and lethal have no authored output",
			cues.cues[&"warning"][&"color"].a == 0.0 and cues.cues[&"lethal"][&"color"].a == 0.0
		)
	h.check("warning nodes are absent", view.find_children("Warning*", "", true, false).is_empty())
	h.check("lethal nodes are absent", view.find_children("Lethal*", "", true, false).is_empty())


func _check_route_core_visible(h: SelfTestHarness, view: Node2D, label: String) -> void:
	var grid := view.find_child("GridRoot", true, false) as Node2D
	var route := grid.get_node_or_null("Tile_7_2") as TextureRect
	var core := grid.get_node_or_null("CoreLandmark") as TextureRect
	var screen := Rect2(Vector2.ZERO, Vector2(PROOF_VIEWPORT))
	var visible := (
		route != null
		and core != null
		and route.is_visible_in_tree()
		and core.is_visible_in_tree()
		and screen.intersects(route.get_global_rect())
		and screen.intersects(core.get_global_rect())
	)
	h.check("route and Core remain visible at %s" % label, visible)


func _check_vanguard_fixture(
	h: SelfTestHarness,
	view: Node2D,
	manifest: S1SliceFixtureManifest,
	unit: UnitState,
) -> void:
	var nodes: Dictionary = view.get("_unit_nodes")
	var body := (nodes.get(unit.id) as Node2D).get_node("Body") as ColorRect
	var sprite := body.get_node("Sprite") as TextureRect
	h.check(
		"S1 vanguard fixture sprite is visibly selected",
		_uses_atlas(sprite, manifest.atlas_texture(&"operator")) and sprite.is_visible_in_tree()
	)
	h.check(
		"S1 fixture uses the exact 144 px runtime canvas",
		sprite.size.distance_to(Vector2.ONE * S1SliceFixtureManifest.RUNTIME_CANVAS_PX) <= 0.5
	)
	h.check(
		"S1 vanguard body carries the 72 px display contract",
		body.size.distance_to(Vector2.ONE * 72.0) <= 0.5
	)


func _check_enemy_fixture(
	h: SelfTestHarness,
	view: Node2D,
	manifest: S1SliceFixtureManifest,
	model: BattleModel,
) -> void:
	var rects: Dictionary = view.get("_enemy_rects")
	var selected := 0
	var visible := 0
	for enemy: EnemyState in model.enemies:
		if not enemy.alive or enemy.faction != EnemyState.Faction.ENEMY or enemy.def_id != &"grunt":
			continue
		var body := rects.get(enemy.id) as ColorRect
		if body == null:
			continue
		var sprite := body.get_node_or_null("Sprite") as TextureRect
		if _uses_atlas(sprite, manifest.atlas_texture(&"enemy")):
			selected += 1
			if sprite.is_visible_in_tree():
				visible += 1
	h.check(
		"every alive ordinary grunt selects the approved fixture",
		selected == model.alive_enemy_count(),
		"selected=%d alive=%d" % [selected, model.alive_enemy_count()]
	)
	h.check("ordinary grunt fixture sprites are visible in the dense frame", visible > 0)


func _uses_atlas(sprite: TextureRect, atlas: Texture2D) -> bool:
	if sprite == null or not sprite.texture is AtlasTexture:
		return false
	return (sprite.texture as AtlasTexture).atlas == atlas


func _check_authoritative_range(h: SelfTestHarness, view: Node2D, unit: UnitState) -> void:
	var expected := Targeting.range_cells(unit.cell, unit.range_offsets, int(unit.facing))
	var root := view.find_child("RangeCueRoot", true, false) as Control
	var actual: Dictionary = {}
	for child: Node in root.get_children():
		var cue := child as Polygon2D
		if cue == null:
			continue
		for cell: Vector2i in expected:
			if (
				cue.name == "RangeCue_%d_%d" % [cell.x, cell.y]
				and cue.position.is_equal_approx(view.call("cell_center", cell))
			):
				actual[cell] = true
	h.check(
		"range cue uses exactly authoritative Targeting cells",
		actual == expected and root.get_child_count() == expected.size(),
		"actual=%s expected=%s" % [actual, expected]
	)


func _check_battle_accessibility(h: SelfTestHarness, view: Node2D) -> void:
	var all_large := true
	var detail := ""
	for node: Node in view.find_children("*", "Button", true, false):
		var button := node as Button
		if button.visible and not _large_enough(button):
			all_large = false
			detail += "%s=%s " % [button.name, button.get_global_rect().size]
	h.check("visible battle controls are at least 44 px", all_large, detail)
	var hud := view.find_child("BattleHud", true, false) as Label
	var report := view.find_child("SkillReadinessReport", true, false) as Label
	h.check(
		"affected normal battle text is at least 32 px",
		(
			hud != null
			and report != null
			and hud.get_theme_font_size("font_size") >= 32
			and report.get_theme_font_size("font_size") >= 32
		)
	)


func _check_control_union(h: SelfTestHarness, view: Node2D) -> void:
	var rects: Array[Rect2] = []
	var viewport := Rect2(Vector2.ZERO, Vector2(PROOF_VIEWPORT))
	for node: Node in view.find_children("*", "Button", true, false):
		var button := node as Button
		if button.visible:
			rects.append(button.get_global_rect().intersection(viewport))
	for label_name: String in ["BattleHud", "SkillReadinessReport"]:
		var label := view.find_child(label_name, true, false) as Label
		if label != null and label.visible:
			rects.append(label.get_global_rect().intersection(viewport))
	var ratio := _rect_union_area(rects) / (viewport.size.x * viewport.size.y)
	h.check(
		"persistent HUD/control node-union stays below 18% at 1920x1080",
		ratio < 0.18,
		"ratio=%.4f" % ratio
	)


func _rect_union_area(rects: Array[Rect2]) -> float:
	var xs: Array[float] = []
	for rect: Rect2 in rects:
		if rect.has_area():
			xs.append(rect.position.x)
			xs.append(rect.end.x)
	xs.sort()
	var area := 0.0
	for index: int in range(maxi(0, xs.size() - 1)):
		var left := xs[index]
		var right := xs[index + 1]
		if right <= left:
			continue
		var spans: Array[Vector2] = []
		for rect: Rect2 in rects:
			if rect.position.x < right and rect.end.x > left and rect.has_area():
				spans.append(Vector2(rect.position.y, rect.end.y))
		spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var height := 0.0
		if not spans.is_empty():
			var start := spans[0].x
			var finish := spans[0].y
			for span: Vector2 in spans.slice(1):
				if span.x > finish:
					height += finish - start
					start = span.x
					finish = span.y
				else:
					finish = maxf(finish, span.y)
			height += finish - start
		area += (right - left) * height
	return area


func _check_results(h: SelfTestHarness, results: Control, model: BattleModel) -> void:
	var headline := results.find_child("Headline", true, false) as Label
	var stars := results.find_child("StarLine", true, false) as Label
	var tally := results.find_child("TallyLine", true, false) as Label
	var reward := results.find_child("Reward0", true, false) as Label
	var reward_def := load("res://data/operators/guard_2.tres") as OperatorDef
	h.check(
		"Results reads exact CLEAR and three stars",
		headline != null and headline.text == "CLEAR" and stars != null and stars.text == "***"
	)
	h.check(
		"Results reflects six kills and zero leaks",
		tally != null and tally.text.contains("kills 6") and tally.text.contains("leaks 0")
	)
	h.check(
		"Results reveals the S1 reward",
		reward != null and reward_def != null and reward.text.contains(reward_def.display_name)
	)
	h.check(
		"Results text remains at least 32 px",
		(
			headline != null
			and tally != null
			and headline.get_theme_font_size("font_size") >= 32
			and tally.get_theme_font_size("font_size") >= 32
		)
	)
	var all_large := true
	for node: Node in results.find_children("*", "Button", true, false):
		var button := node as Button
		all_large = all_large and (not button.visible or _large_enough(button))
	h.check("Results controls are at least 44 px", all_large)
	h.check(
		"Results preserves the exact terminal model",
		model.tick == 902 and model.killed == 6 and model.leaked == 0 and model.stars == 3
	)


func _large_enough(control: Control) -> bool:
	var size := control.get_global_rect().size
	return size.x >= 44.0 and size.y >= 44.0


func _check_readiness_report(h: SelfTestHarness, report: Label, operator_name: String) -> void:
	var viewport := Rect2(Vector2.ZERO, Vector2(PROOF_VIEWPORT))
	var report_rect := report.get_global_rect() if report != null else Rect2()
	h.check(
		"%s readiness report is fully inside the viewport" % operator_name,
		(
			report != null
			and report.is_visible_in_tree()
			and report.text == "%s — SKILL READY" % operator_name
			and viewport.encloses(report_rect)
		),
		"%s in %s" % [report_rect, viewport],
	)


func _capture_still(h: SelfTestHarness, shot_name: String, model: BattleModel) -> void:
	var before := model.state_hash()
	await h.shot(shot_name)
	await h.frames(1)
	h.check("%s render performs zero model writes" % shot_name, model.state_hash() == before)


func _step_exact(model: BattleModel, target_tick: int) -> void:
	while model.tick < target_tick and model.result == BattleModel.Result.RUNNING:
		model.step()


func _step_to(h: SelfTestHarness, model: BattleModel, target_tick: int) -> void:
	var since_yield := 0
	while model.tick < target_tick and model.result == BattleModel.Result.RUNNING:
		model.step()
		since_yield += 1
		if since_yield == 150:
			since_yield = 0
			await h.frames(1)


func _await_paused_battle(h: SelfTestHarness, game: Node) -> BattleModel:
	var budget := 120
	while budget > 0:
		var model := game.get("current_battle") as BattleModel
		var content := game.get("content") as Node
		if model != null and content is Node2D:
			content.set("ticks_per_frame_scale", 0.0)
			await h.frames(3)
			return model
		budget -= 1
		await h.frames(1)
	return null


func _await_screen(h: SelfTestHarness, game: Node, marker: String) -> Control:
	var budget := 120
	while budget > 0:
		var content := game.get("content") as Node
		if (
			content != null
			and is_instance_valid(content)
			and content is Control
			and (content.name == marker or content.find_child(marker, true, false) != null)
		):
			await h.frames(3)
			return content
		budget -= 1
		await h.frames(1)
	return null


func _source_hashes() -> Dictionary:
	var hashes: Dictionary = {}
	for path: String in SOURCE_PATHS:
		hashes[path] = S1SliceFixtureManifest.hash_file(path)
	return hashes


func _tally(model: BattleModel) -> String:
	return (
		"tick=%d units=%d alive_enemies=%d spawned=%d killed=%d leaked=%d result=%d stars=%d"
		% [
			model.tick,
			model.units.size(),
			model.alive_enemy_count(),
			model.spawned,
			model.killed,
			model.leaked,
			model.result,
			model.stars
		]
	)
