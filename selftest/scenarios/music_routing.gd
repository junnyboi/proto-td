extends RefCounted

## Runtime music contract: one player, catalog IDs, idempotent duplicate calls,
## data-owned boss boundaries, and silence on non-battle scenes.


func run(h: SelfTestHarness) -> void:
	h.max_frames = 1600
	await h.frames(10)
	h.expect_done()
	var music := h.autoload("Music")
	var game := h.autoload("Game")
	h.check("Music autoload exists", music != null)
	h.check("Game autoload exists", game != null)
	if music == null or game == null:
		return
	music.call("stop")
	var starts_at_entry := int(music.call("start_count"))
	var stops_at_entry := int(music.call("stop_count"))
	(
		h
		. check(
			"Music owns exactly one AudioStreamPlayer",
			int(music.call("player_count")) == 1,
			"players=%d" % int(music.call("player_count")),
		)
	)
	h.check("title begins without a cue", music.call("current_id") == &"")

	# Directly exercise S8's data route: wave 1 stays BGM; wave 2 starts boss.
	var s8 := load("res://data/stages/s8.tres") as StageDef
	h.check("S8 BGM request accepted", bool(music.call("sync_stage_wave", s8, 0)))
	h.check("S8 begins Act II BGM", music.call("current_id") == &"act_2_bgm")
	h.check("S8 wave 1 request accepted", bool(music.call("sync_stage_wave", s8, 1)))
	(
		h
		. check(
			"S8 wave 1 does not restart BGM",
			int(music.call("start_count")) == starts_at_entry + 1,
			"starts=%d" % int(music.call("start_count")),
		)
	)
	h.check("S8 boss request accepted", bool(music.call("sync_stage_wave", s8, 2)))
	h.check("S8 wave 2 selects Act II boss", music.call("current_id") == &"act_2_boss")
	var starts_after_s8_boss := int(music.call("start_count"))
	for _i: int in 8:
		music.call("sync_stage_wave", s8, 2)
	(
		h
		. check(
			"eight repeated S8 boss requests never fire again",
			int(music.call("start_count")) == starts_after_s8_boss,
			"starts=%d" % int(music.call("start_count")),
		)
	)
	(
		h
		. check(
			"S8 routing still owns one player",
			int(music.call("player_count")) == 1,
			"players=%d" % int(music.call("player_count")),
		)
	)
	h.check("test reset stops one active cue", bool(music.call("stop")))

	# Start a real BattleView for S4. Music._process observes the live battle
	# projection and owns both the BGM request and final-wave boss transition.
	game.call("start_battle", &"s4")
	var model := await _await_battle(h, game)
	h.check("S4 battle starts", model != null)
	if model == null:
		return
	var view := game.get("content") as Node
	view.set("ticks_per_frame_scale", 0.0)
	h.check("S4 Music route starts Act I BGM", music.call("current_id") == &"act_1_bgm")
	var starts_after_s4_bgm := int(music.call("start_count"))
	await h.frames(8)
	(
		h
		. check(
			"S4 repeated controller frames do not restart BGM",
			int(music.call("start_count")) == starts_after_s4_bgm,
			"starts=%d" % int(music.call("start_count")),
		)
	)
	while model.tick < 290 and model.result == BattleModel.Result.RUNNING:
		model.step()
	await h.frames(3)
	(
		h
		. check(
			"S4 reaches the configured final wave",
			model.tick >= 290 and model.result == BattleModel.Result.RUNNING,
			"tick=%d result=%d" % [model.tick, model.result],
		)
	)
	h.check("S4 final wave selects Act I boss", music.call("current_id") == &"act_1_boss")
	var starts_after_s4_boss := int(music.call("start_count"))
	await h.frames(8)
	(
		h
		. check(
			"S4 boss controller frames never fire multiple times",
			int(music.call("start_count")) == starts_after_s4_boss,
			"starts=%d" % int(music.call("start_count")),
		)
	)
	(
		h
		. check(
			"S4 boss still owns exactly one player",
			int(music.call("player_count")) == 1,
			"players=%d" % int(music.call("player_count")),
		)
	)

	var stops_before_results := int(music.call("stop_count"))
	game.call("open_results")
	var results := await _await_screen(h, game, "ResultsColumn")
	h.check("results screen opens", results != null)
	h.check("non-battle swap clears current cue", music.call("current_id") == &"")
	(
		h
		. check(
			"non-battle swap stops exactly once",
			int(music.call("stop_count")) == stops_before_results + 1,
			"before=%d after=%d" % [stops_before_results, int(music.call("stop_count"))],
		)
	)
	music.call("stop")
	(
		h
		. check(
			"repeated stop is a no-op",
			int(music.call("stop_count")) == stops_before_results + 1,
		)
	)
	(
		h
		. check(
			"scenario exercised expected minimum starts and stops",
			(
				int(music.call("start_count")) >= starts_at_entry + 4
				and int(music.call("stop_count")) >= stops_at_entry + 3
			),
			(
				"starts=%d stops=%d"
				% [
					int(music.call("start_count")),
					int(music.call("stop_count")),
				]
			),
		)
	)
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
