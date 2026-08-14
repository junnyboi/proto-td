class_name PolicyBotDriver
extends StageBot

const MAX_COMMANDS := 256
const NO_PROGRESS_TICKS := 300
const OBSERVATION_SCRIPT := preload("res://sim/battle_observation.gd")
const TELEMETRY_SCRIPT := preload("res://sim/battle_observation_telemetry.gd")
const TRACE_SCRIPT := preload("res://playtests/bots/action_trace.gd")
const POLICY_SCRIPT := preload("res://playtests/bots/policy_stage_06.gd")

var _policy: ConditionalPolicy = null
var _trace: ActionTrace = null
var _observation_telemetry: BattleObservationTelemetry = null
var _last_progress_signature := ""
var _no_progress_ticks := 0
var _driver_finished := false
var _driver_stop_reason := ""
var _summary: Dictionary = {}
var _dispatch_count := 0


func policy_capabilities() -> Array[String]:
	return ["charm", "deploy", "trap", "skill"]


func expected_result() -> int:
	return BattleModel.Result.CLEAR


func accepted_terminal_results() -> Array[int]:
	return [expected_result()]


func tick(t: int) -> bool:
	if failed:
		return false
	if not _started:
		_started = true
		_game().call("start_stage", stage_id(), squad())
		_policy = POLICY_SCRIPT.new(policy_capabilities())
		_trace = TRACE_SCRIPT.new()
		_observation_telemetry = TELEMETRY_SCRIPT.new()
		return false
	if _model == null:
		_model = _game().get("current_battle") as BattleModel
		if _model == null:
			return false
		if _model.stage.id != stage_id():
			_fail("booted the wrong stage: %s" % _model.stage.id)
			return false
		(_game().get("content") as Node).set("ticks_per_frame_scale", 0.0)
	if not _driver_finished:
		_drive_chunk()
	if _driver_finished and t >= MIN_RUNNER_TICKS:
		return true
	return false


func stop_reason() -> String:
	if failed:
		return "bot_failed"
	return _driver_stop_reason


func final_summary() -> Dictionary:
	return _summary.duplicate(true)


func action_rows() -> Array:
	return [] if _trace == null else _trace.rows()


func dispatch_count() -> int:
	return _dispatch_count


func _drive_chunk() -> void:
	var budget := STEP_CHUNK
	while budget > 0 and not _driver_finished:
		var observation := OBSERVATION_SCRIPT.from_model(_model)
		var observation_value := observation.to_dictionary()
		var observation_sha := observation.sha256()
		_trace.note_observation(observation_sha)
		_observation_telemetry.consume(observation)
		_update_progress(observation.progress_signature())
		if _model.result != BattleModel.Result.RUNNING:
			_finish_terminal(observation_value)
			return
		var bounded_reason := bounded_stop_reason(
			_trace.command_count(), _no_progress_ticks
		)
		if not bounded_reason.is_empty():
			_finish(bounded_reason, "", false)
			return
		var decision := _policy.decide(observation_value.duplicate(true))
		var action := _engine_action(decision.get("action", []))
		if not action.is_empty():
			_dispatch(action, String(decision.get("reason", "")), observation_sha)
		_model.step()
		budget -= 1


func _dispatch(action: Array, reason: String, observation_sha: String) -> void:
	var before := _model.state_hash()
	var accepted := _model.apply_action(action)
	var after := _model.state_hash()
	_dispatch_count += 1
	_trace.record_attempt(_model.tick, action, reason, observation_sha, accepted, before, after)
	if not accepted:
		_fail("policy action rejected @tick %d: %s" % [_model.tick, str(action)])
		_finish("bot_failed", "", false)


static func bounded_stop_reason(command_count: int, no_progress_ticks: int) -> String:
	if command_count >= MAX_COMMANDS:
		return "command_ceiling"
	if no_progress_ticks >= NO_PROGRESS_TICKS:
		return "no_progress"
	return ""


static func next_no_progress_ticks(
	previous: int, previous_signature: String, signature: String
) -> int:
	if previous_signature.is_empty() or signature != previous_signature:
		return 0
	return previous + 1


func _update_progress(signature: String) -> void:
	_no_progress_ticks = next_no_progress_ticks(
		_no_progress_ticks, _last_progress_signature, signature
	)
	_last_progress_signature = signature


func _finish_terminal(observation: Dictionary) -> void:
	var result_text := String(observation["result"])
	var reason := "terminal_clear" if result_text == "clear" else "terminal_defeat"
	var expected := accepted_terminal_results().has(_model.result)
	if not expected:
		_fail("unexpected terminal result %s leaked=%d tick=%d" % [
			result_text, _model.leaked, _model.tick,
		])
		_finish("bot_failed", String(observation["terminal_cause"]), false)
		return
	print("[STAGE-BOT] %s %s leaked=%d stars=%d tick=%d" % [
		stage_id(), result_text.to_upper(), _model.leaked, _model.stars, _model.tick,
	])
	_finish(reason, String(observation["terminal_cause"]), false)


func _finish(reason: String, terminal_cause: String, watchdog: bool) -> void:
	if _driver_finished:
		return
	_driver_finished = true
	_driver_stop_reason = reason
	_summary = _trace.finish(_model.tick, terminal_cause, watchdog, reason)
	_summary["stage_id"] = String(stage_id())
	_summary["result"] = _result_text(_model.result)
	_summary["leaked"] = _model.leaked
	_summary["killed"] = _model.killed
	_summary["stars"] = _model.stars
	_summary["model_hash"] = HeroIdentity.format_u64_hex(_model.state_hash())
	_summary["capabilities"] = _policy.capabilities()
	_summary["telemetry"] = _observation_telemetry.summary()
	print("[TD-OBS-SUMMARY] " + CanonicalJson.text(_summary).strip_edges())


func _engine_action(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var source := value as Array
	if source.is_empty():
		return []
	var action: Array = [StringName(String(source[0]))]
	for index: int in range(1, source.size()):
		var item: Variant = source[index]
		if typeof(item) == TYPE_STRING:
			action.append(StringName(item))
		elif typeof(item) == TYPE_DICTIONARY:
			var cell := item as Dictionary
			action.append(Vector2i(int(cell["x"]), int(cell["y"])))
		else:
			action.append(item)
	return action


func _result_text(value: int) -> String:
	match value:
		BattleModel.Result.CLEAR:
			return "clear"
		BattleModel.Result.DEFEAT:
			return "defeat"
		_:
			return "running"
