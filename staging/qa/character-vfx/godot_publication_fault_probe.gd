extends SceneTree

const Pipeline = preload("res://tools/art_pipeline/character_vfx/godot/pipeline.gd")


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 4:
		printerr("expected candidate output fault_after expected_detail")
		quit(2)
		return
	var candidate := ProjectSettings.globalize_path(arguments[0]).simplify_path()
	var output := ProjectSettings.globalize_path(arguments[1]).simplify_path()
	var fault_after := int(arguments[2])
	var expected_detail := arguments[3]
	var result := Pipeline.publish_with_fault_for_test(
		candidate, output, true, fault_after
	)
	print(JSON.stringify(result, "", true, true))
	if bool(result.get("ok", true)):
		printerr("fault injection expected publication failure")
		quit(3)
		return
	if expected_detail not in String(result.get("detail", "")):
		printerr("publication probe missing measured failure detail")
		quit(4)
		return
	quit(0)
