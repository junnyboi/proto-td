extends SceneTree

## Scratch probe: is the no_focus creation flag active under override.cfg?


func _initialize() -> void:
	await process_frame
	print("[probe] no_focus flag: ", DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS))
	print("[probe] focused: ", DisplayServer.window_is_focused())
	quit(0)
