class_name StageBot
extends PlaytestBot

## Shared driver for campaign stage bots (Phase 10, td-phase-10.md §2.4).
## Subclasses override stage_id/squad/timeline (+ leak_band /
## expected_result). The driver freezes the view (ticks_per_frame_scale 0)
## and steps the MODEL itself in chunks — tick-exact action scheduling,
## outcome-safe by rule 6, and the whole campaign finishes in seconds
## instead of flirting with the wall-clock budget. Filename deliberately
## does not match verify.sh's bot_*.gd scan (it is a base, not a bot).
##
## Failure mode: any rejected timeline action or wrong terminal outcome
## push_errors and never reports done — the runner's expects_completion
## watchdog turns that into exit 3. done waits for MIN_RUNNER_TICKS so the
## quality gate's tier-1 min_ticks floor stays meaningful.

const STEP_CHUNK := 120
const MIN_RUNNER_TICKS := 110

var failed := false

var _started := false
var _finished := false
var _driving: Array = []
var _next_idx := 0
var _model: BattleModel = null


func _init() -> void:
	expects_completion = true


func stage_id() -> StringName:
	return &""


func squad() -> Array[StringName]:
	return []


func timeline() -> Array:
	return []


func leak_band() -> int:
	return 2


func expected_result() -> int:
	return BattleModel.Result.CLEAR


func stop_reason() -> String:
	if failed:
		return "bot_failed"
	if not _finished or _model == null:
		return ""
	if _model.result == BattleModel.Result.CLEAR:
		return "terminal_clear"
	return "terminal_defeat"


func tick(t: int) -> bool:
	if failed:
		return false
	if not _started:
		_started = true
		var game := _game()
		game.call("start_stage", stage_id(), squad())
		_driving = timeline().duplicate()
		_driving.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
		return false
	if _model == null:
		var game := _game()
		_model = game.get("current_battle")
		if _model == null:
			return false
		if _model.stage.id != stage_id():
			_fail("booted the wrong stage: %s" % _model.stage.id)
			return false
		(game.get("content") as Node).set("ticks_per_frame_scale", 0.0)
	if _model.result == BattleModel.Result.RUNNING:
		_advance_chunk()
	if _model.result != BattleModel.Result.RUNNING and not _finished:
		_finished = true
		_check_terminal()
	return _finished and not failed and t >= MIN_RUNNER_TICKS


## Apply due actions BEFORE stepping their tick (T1: a verb at tick T
## resolves ahead of that tick's movement) — every row must be accepted.
func _advance_chunk() -> void:
	var budget := STEP_CHUNK
	while budget > 0 and _model.result == BattleModel.Result.RUNNING:
		while _next_idx < _driving.size() and int(_driving[_next_idx][0]) == _model.tick:
			var row: Array = _driving[_next_idx]
			if not _model.apply_action(row.slice(1)):
				_fail("timeline action rejected @tick %d: %s" % [_model.tick, str(row)])
				return
			_next_idx += 1
		_model.step()
		budget -= 1


func _check_terminal() -> void:
	if _next_idx < _driving.size():
		_fail("battle ended at tick %d with %d timeline rows unplayed"
			% [_model.tick, _driving.size() - _next_idx])
		return
	if _model.result != expected_result():
		_fail("expected result %d, got %d (leaked=%d killed=%d tick=%d)"
			% [expected_result(), _model.result, _model.leaked, _model.killed, _model.tick])
		return
	if _model.result == BattleModel.Result.CLEAR and _model.leaked > leak_band():
		_fail("leak band exceeded: %d > %d" % [_model.leaked, leak_band()])
		return
	print("[STAGE-BOT] %s %s leaked=%d stars=%d tick=%d" % [
		stage_id(),
		"CLEAR" if _model.result == BattleModel.Result.CLEAR else "DEFEAT",
		_model.leaked, _model.stars, _model.tick,
	])


func _fail(message: String) -> void:
	failed = true
	push_error("[STAGE-BOT] %s: %s" % [stage_id(), message])


func _game() -> Node:
	return tree.root.get_node("Game")
