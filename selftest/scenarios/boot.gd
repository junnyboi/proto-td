extends RefCounted

## Boot scenario: title boots with exactly one Start action -> real input opens
## a fresh campaign Staging session. The battle engine is then exercised through
## its explicit harness/debug seam: enemies spawn, advance, and reach terminal.
## Shots: boot, battle_early, battle_end.


func run(h: SelfTestHarness) -> void:
	# measured 876 render frames @60 for the full run (defeat ~tick 421);
	# x2 for 120 Hz = 1752, +25% headroom (td-phase-14.md pin)
	h.max_frames = 2200
	await h.frames(10)
	h.expect_done()
	var game := h.autoload("Game")
	var title := h.scene as Control
	h.check("title scene is a Control", title != null)
	var label := title.find_child("TitleLabel", true, false) as Label
	var i18n := h.autoload("I18n")
	h.check(
		"title label is Proto Defense",
		label != null and label.text == "Proto Defense",
		"text=%s" % (label.text if label != null else "<missing>"),
	)
	h.check(
		"title matches localized ui.game_title",
		i18n != null and label != null
			and label.text == str(i18n.call("t", &"ui.game_title", "Proto Defense")),
	)
	h.check(
		"project metadata is Proto Defense",
		str(ProjectSettings.get_setting("application/config/name", "")) == "Proto Defense",
	)
	var title_rect := title.get_global_rect()
	var label_rect := label.get_global_rect() if label != null else Rect2()
	h.check(
		"title label is fully inside the usable viewport",
		label != null and title_rect.encloses(label_rect) and label_rect.size.x > 0.0
			and label_rect.size.y > 0.0,
		"title=%s label=%s" % [title_rect, label_rect],
	)
	var button := title.find_child("StartButton", true, false) as Button
	var rect := button.get_global_rect() if button != null else Rect2()
	h.check(
		"start button has a visible rect",
		button != null and rect.size.x > 0.0 and rect.size.y > 0.0,
		"rect=%s" % rect,
	)
	h.check("start button label is Start", button != null and button.text == "Start")
	h.check("Campaign button is absent", title.find_child("CampaignButton", true, false) == null)
	var title_buttons: Array[Node] = title.find_children("*", "Button", true, false)
	h.check(
		"title exposes exactly one action",
		title_buttons.size() == 1,
		"buttons=%d" % title_buttons.size(),
	)
	await h.shot("boot")
	if button == null:
		return

	# Input-adapter wiring check: one synthetic click on the sole live action.
	# Dirty every resettable route field first so freshness checks cannot pass
	# from constructor defaults.
	var stale_squad: Array[StringName] = [&"vanguard_1"]
	game.set("pending_stage", load("res://data/stages/test_lane.tres") as StageDef)
	game.set("selected_stage_id", &"stale_stage")
	game.set("selected_squad", stale_squad)
	game.set("last_result", {"stale": true})
	await h.click_view(rect.get_center())
	var staging := await _await_screen(h, game, "StagingRoot")
	h.check("Start opens Staging", staging != null)
	h.check("Start does not open a battle", game.get("current_battle") == null)
	h.check("Start creates a campaign", game.get("campaign") != null)
	h.check("Start activates campaign flow", bool(game.get("campaign_active")))
	h.check("Start clears pending stage", game.get("pending_stage") == null)
	h.check("Start clears selected stage", game.get("selected_stage_id") == &"")
	h.check("Start clears selected squad", (game.get("selected_squad") as Array).is_empty())
	h.check("Start clears last result", (game.get("last_result") as Dictionary).is_empty())
	if staging == null:
		return

	# Direct battle startup is retained only as a harness/debug seam.
	game.call("start_battle", game.get("default_stage_id"))
	var model := await _await_battle(h, game)
	h.check("harness battle seam starts a model", model != null)
	if model == null:
		return

	# spawn check: first grunt at tick 30, second at 90 -> exactly 1 by tick 40
	while model.tick < 40:
		await h.physics_frames(1)
	h.check("one enemy spawned by tick 40", model.spawned == 1, "spawned=%d" % model.spawned)
	h.check("enemy alive on the path", model.alive_count() == 1)

	# progress advances by exactly step_units per tick (race-immune sampling:
	# capture tick+progress pairs, compare deltas)
	var enemy: EnemyState = model.enemies[0]
	var t1 := model.tick
	var p1 := enemy.progress_units
	await h.physics_frames(120)
	var t2 := model.tick
	var p2 := enemy.progress_units
	h.check(
		"progress advances by step_units per tick",
		t2 > t1 and p2 - p1 == (t2 - t1) * enemy.step_units,
		"dt=%d dp=%d step=%d" % [t2 - t1, p2 - p1, enemy.step_units],
	)
	await h.shot("battle_early")

	# run to terminal: test_lane (5 grunts, leak_limit 3, no defenders) must
	# DEFEAT on the 4th leak with 5 spawned
	while model.result == BattleModel.Result.RUNNING:
		await h.physics_frames(10)
	h.check(
		"battle reached terminal state",
		model.result == BattleModel.Result.DEFEAT,
		"result=%d" % model.result,
	)
	h.check("defeat on the 4th leak", model.leaked == 4, "leaked=%d" % model.leaked)
	h.check("all five grunts spawned by then", model.spawned == 5, "spawned=%d" % model.spawned)
	await h.frames(5)
	await h.shot("battle_end")
	h.done()


func _await_battle(h: SelfTestHarness, game: Node) -> BattleModel:
	var budget := 120
	while budget > 0:
		var model: BattleModel = game.get("current_battle")
		var content := game.get("content") as Node
		if model != null and content != null and content is Node2D:
			await h.frames(3)
			return model
		budget -= 1
		await h.frames(1)
	return null


func _await_screen(h: SelfTestHarness, game: Node, marker: String) -> Control:
	var budget := 120
	while budget > 0:
		var content := game.get("content") as Node
		if content != null and is_instance_valid(content) and content is Control \
				and (content.name == marker or content.find_child(marker, true, false) != null):
			await h.frames(3)
			return content
		budget -= 1
		await h.frames(1)
	return null
