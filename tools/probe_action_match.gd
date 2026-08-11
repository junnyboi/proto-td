extends SceneTree

## Scratch probe (Phase 13 A3): does a synthetic-device InputEventKey match
## the battle_pause action registered by add_input_actions.gd?


func _initialize() -> void:
	InputMap.load_from_project_settings()
	var ev := InputEventKey.new()
	ev.device = 4242
	ev.physical_keycode = KEY_SPACE
	ev.pressed = true
	print("[probe] device-4242 space matches action: ", ev.is_action_pressed("battle_pause"))
	var ev0 := InputEventKey.new()
	ev0.physical_keycode = KEY_SPACE
	ev0.pressed = true
	print("[probe] default-device space matches action: ", ev0.is_action_pressed("battle_pause"))
	quit(0)
