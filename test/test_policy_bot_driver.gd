extends GutTest


func test_pinned_ceilings_and_recognized_stops() -> void:
	assert_eq(PolicyBotDriver.MAX_COMMANDS, 256)
	assert_eq(PolicyBotDriver.NO_PROGRESS_TICKS, 300)
	for reason: String in PlaytestBot.STOP_REASONS:
		assert_true(PlaytestBot.recognized_stop_reason(reason))
	assert_false(PlaytestBot.recognized_stop_reason(""))
	assert_false(PlaytestBot.recognized_stop_reason("bot_done"))
	assert_eq(PolicyBotDriver.bounded_stop_reason(255, 299), "")
	assert_eq(PolicyBotDriver.bounded_stop_reason(256, 0), "command_ceiling")
	assert_eq(PolicyBotDriver.bounded_stop_reason(0, 300), "no_progress")
	assert_eq(PolicyBotDriver.next_no_progress_ticks(299, "same", "same"), 300)
	assert_eq(PolicyBotDriver.next_no_progress_ticks(299, "old", "new"), 0)


func test_stop_reason_success_and_failure_classification() -> void:
	var successful: Array[String] = [
		"campaign_complete", "terminal_clear", "terminal_defeat", "duration_reached",
	]
	var failed: Array[String] = [
		"command_ceiling", "no_progress", "bot_failed", "watchdog_max_ticks",
	]
	for reason: String in successful:
		assert_true(PlaytestBot.successful_stop_reason(reason), reason)
		assert_eq(PlaytestBot.stop_exit_code(reason), 0, reason)
	for reason: String in failed:
		assert_false(PlaytestBot.successful_stop_reason(reason), reason)
		assert_eq(PlaytestBot.stop_exit_code(reason), 3, reason)
	assert_false(PlaytestBot.successful_stop_reason("bot_load_failed"))
	assert_eq(PlaytestBot.stop_exit_code("bot_load_failed"), 4)
	assert_false(PlaytestBot.successful_stop_reason("bot_done"))
	assert_eq(PlaytestBot.stop_exit_code("bot_done"), 3)


func test_progress_signature_excludes_tick_but_includes_progress() -> void:
	var stage := load("res://data/stages/s6.tres") as StageDef
	var config := load("res://data/config/game.tres") as GameConfig
	var grunt := load("res://data/enemies/grunt.tres") as EnemyDef
	var squad: Array[StringName] = []
	var model := BattleModel.create(stage, squad, 42, config, {&"grunt": grunt})
	var observation := BattleObservation.from_model(model)
	var value := observation.to_dictionary()
	value["tick"] = 999
	var without_tick := value.duplicate(true)
	without_tick.erase("tick")
	assert_eq(observation.progress_signature(), CanonicalJson.sha256_hex(without_tick))
	value["dp"] = int(value["dp"]) + 1
	value.erase("tick")
	assert_ne(observation.progress_signature(), CanonicalJson.sha256_hex(value))


func test_policy_is_pure_and_driver_is_dispatch_owner() -> void:
	var policy_source := FileAccess.get_file_as_string(
		"res://playtests/bots/policy_stage_06.gd"
	)
	var driver_source := FileAccess.get_file_as_string(
		"res://playtests/bots/policy_bot_driver.gd"
	)
	assert_false(policy_source.contains("BattleModel"))
	assert_false(policy_source.contains("apply_action"))
	assert_true(driver_source.contains("_model.apply_action(action)"))
