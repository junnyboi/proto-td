class_name PlaytestBot
extends RefCounted

const STOP_REASONS: Array[String] = [
	"campaign_complete",
	"terminal_clear",
	"terminal_defeat",
	"duration_reached",
	"command_ceiling",
	"no_progress",
	"bot_failed",
	"watchdog_max_ticks",
	"bot_load_failed",
]

const SUCCESSFUL_STOP_REASONS: Array[String] = [
	"campaign_complete",
	"terminal_clear",
	"terminal_defeat",
	"duration_reached",
]

## Base class for scripted playtest bots, driven by PlaytestRunner every
## physics tick. Override tick(); return true when done. Bots live inside the
## process and read game state directly through `tree` — no protocol needed.
## expects_completion: true = hitting --max-ticks is a watchdog failure
## (exit 3); false = idle-style bots where duration_reached is success.

var tree: SceneTree
var expects_completion := false


func tick(_t: int) -> bool:
	return false


func stop_reason() -> String:
	return ""


func final_summary() -> Dictionary:
	return {}


static func recognized_stop_reason(reason: String) -> bool:
	return STOP_REASONS.has(reason)


static func successful_stop_reason(reason: String) -> bool:
	return SUCCESSFUL_STOP_REASONS.has(reason)


static func stop_exit_code(reason: String) -> int:
	if successful_stop_reason(reason):
		return 0
	if reason == "bot_load_failed":
		return 4
	return 3


func press(action: String) -> void:
	Input.action_press(action)


func release(action: String) -> void:
	Input.action_release(action)


func click_view(view_pos: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.device = SelfTestHarness.SYNTHETIC_DEVICE
		ev.position = view_pos
		ev.global_position = view_pos
		ev.button_index = button
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()
