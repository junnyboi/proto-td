class_name PlaytestBot
extends RefCounted

## Base class for scripted playtest bots, driven by PlaytestRunner every
## physics tick. Override tick(); return true when done. Bots live inside the
## process and read game state directly through `tree` — no protocol needed.
## expects_completion: true = hitting --max-ticks is a watchdog failure
## (exit 3); false = idle-style bots where duration_reached is success.

var tree: SceneTree
var expects_completion := false


func tick(_t: int) -> bool:
	return false


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
