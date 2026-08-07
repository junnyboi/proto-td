extends SceneTree

## Scratch tool: registers input actions via the ProjectSettings API (never
## hand-write Object(InputEventKey...) serialization). Run once, idempotent:
##   godot --headless --path . -s tools/add_input_actions.gd


func _initialize() -> void:
	_add_key_action("ui_debug_overlay", KEY_F12)
	ProjectSettings.save()
	print("[input-actions] saved")
	quit(0)


func _add_key_action(action_name: String, keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	ProjectSettings.set_setting(
		"input/%s" % action_name,
		{"deadzone": 0.2, "events": [ev]},
	)
