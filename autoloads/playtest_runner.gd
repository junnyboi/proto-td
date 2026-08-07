extends Node

## Bot playtest driver. Dormant unless launched with a --playtest user arg:
##   godot --headless --fixed-fps 60 --path . -- \
##       --playtest=<bot> --seed=42 --max-ticks=3600
## Loads playtests/bots/<bot>.gd, ticks it every physics frame, enforces the
## --max-ticks watchdog, flushes Telemetry and quits.
## Exit codes: 0 = bot done or duration reached (idle-style bots);
## 3 = a bot that expects_completion never finished; 4 = bot failed to load.

var _bot: PlaytestBot = null
var _bot_name := ""
var _seed_value: int = 42
var _max_ticks: int = 3600
var _tick: int = 0
var _start_ms: int = 0


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--playtest="):
			_bot_name = arg.trim_prefix("--playtest=")
		elif arg.begins_with("--seed="):
			_seed_value = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--max-ticks="):
			_max_ticks = int(arg.trim_prefix("--max-ticks="))
	if _bot_name.is_empty():
		set_physics_process(false)
		return
	Game.set_run_seed(_seed_value)
	var bot_path := "res://playtests/bots/%s.gd" % _bot_name
	if not ResourceLoader.exists(bot_path):
		push_error("playtest bot not found: " + bot_path)
		_quit("bot_load_failed", 4)
		return
	var script: GDScript = load(bot_path)
	_bot = script.new()
	_bot.tree = get_tree()
	_start_ms = Time.get_ticks_msec()
	print("[PLAYTEST] bot=%s seed=%d max_ticks=%d" % [_bot_name, _seed_value, _max_ticks])


func _physics_process(_delta: float) -> void:
	if _bot == null:
		return
	Telemetry.current_tick = _tick
	var done: bool = _bot.tick(_tick)
	_tick += 1
	if done:
		_quit("bot_done", 0)
	elif _tick >= _max_ticks:
		if _bot.expects_completion:
			_quit("watchdog_max_ticks", 3)
		else:
			_quit("duration_reached", 0)


func _quit(reason: String, code: int) -> void:
	_bot = null
	Telemetry.flush({
		"bot": _bot_name,
		"seed": _seed_value,
		"ticks": _tick,
		"wall_ms": Time.get_ticks_msec() - _start_ms,
		"engine": Engine.get_version_info()["string"],
		"headless": DisplayServer.get_name() == "headless",
		"quit_reason": reason,
	})
	print("[PLAYTEST] quit: %s (exit %d)" % [reason, code])
	get_tree().quit(code)
