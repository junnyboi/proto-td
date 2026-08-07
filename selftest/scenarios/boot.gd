extends RefCounted

## Boot scenario: title boots -> Start button (input-adapter wiring check)
## -> battle loads -> enemies spawn and advance (model-state asserts, per
## learnings: never assert node transforms against injected-input races)
## -> battle reaches a terminal state. Shots: boot, battle_early, battle_end.


func run(h: SelfTestHarness) -> void:
	await h.frames(10)
	var title := h.scene as Control
	h.check("title scene is a Control", title != null)
	var label := h.scene.find_child("TitleLabel", true, false) as Label
	h.check(
		"title label present + non-empty",
		label != null and not label.text.is_empty(),
		"text=%s" % (label.text if label != null else "<missing>"),
	)
	var button := h.scene.find_child("StartButton", true, false) as Button
	var rect := button.get_global_rect() if button != null else Rect2()
	h.check(
		"start button has a visible rect",
		button != null and rect.size.x > 0.0 and rect.size.y > 0.0,
		"rect=%s" % rect,
	)
	await h.shot("boot")

	# Input-adapter wiring check: one synthetic click on the live button rect
	# (never hardcoded positions). The seam (Game.start_battle) is what every
	# later scenario uses; the raw input path is validated once, here.
	var game := h.autoload("Game")
	await h.click_view(rect.get_center())
	await h.frames(5)
	var started_by_click: bool = game.get("current_battle") != null
	h.check("start button click starts a battle", started_by_click)
	if not started_by_click:
		game.call("start_battle", game.get("default_stage_id"))
		await h.frames(5)

	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null)
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
