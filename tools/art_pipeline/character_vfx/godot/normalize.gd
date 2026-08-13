extends SceneTree

const Pipeline = preload("res://tools/art_pipeline/character_vfx/godot/pipeline.gd")


func _failure(detail: String) -> void:
	print(JSON.stringify({"status": "FAIL", "detail": detail}, "", true, true))
	quit(2)


func _parse_arguments() -> Dictionary:
	var user_arguments := OS.get_cmdline_user_args()
	if user_arguments.is_empty():
		return {"ok": false, "detail": "command expected=build-or-validate"}
	var command := user_arguments[0]
	if command not in ["build", "validate"]:
		return {"ok": false, "detail": "command expected=build-or-validate actual=%s" % command}
	var parsed := {
		"ok": true,
		"command": command,
		"spec": "",
		"input_root": "",
		"output": "",
		"backend": "godot",
		"clean": false,
	}
	var index := 1
	var parse_error := ""
	while index < user_arguments.size():
		var argument := user_arguments[index]
		if argument == "--clean":
			parsed["clean"] = true
			index += 1
			continue
		if argument not in ["--spec", "--input-root", "--output", "--backend"]:
			parse_error = "unknown argument=%s" % argument
			break
		if index + 1 >= user_arguments.size():
			parse_error = "missing value for %s" % argument
			break
		parsed[String(argument).trim_prefix("--").replace("-", "_")] = user_arguments[index + 1]
		index += 2
	if not parse_error.is_empty():
		return {"ok": false, "detail": parse_error}
	return _validate_arguments(parsed)


func _validate_arguments(parsed: Dictionary) -> Dictionary:
	for key: String in ["spec", "input_root", "output"]:
		if String(parsed[key]).is_empty():
			return {"ok": false, "detail": "missing required --%s" % String(key).replace("_", "-")}
	if parsed["backend"] != "godot":
		return {"ok": false, "detail": "backend expected=godot actual=%s" % parsed["backend"]}
	if parsed["command"] == "validate" and parsed["clean"]:
		return {"ok": false, "detail": "--clean is invalid for validate"}
	return parsed


func _absolute_path(value: String) -> String:
	if value.is_absolute_path():
		return value.simplify_path()
	return ProjectSettings.globalize_path("res://" + value).simplify_path()


func _initialize() -> void:
	var arguments := _parse_arguments()
	if not arguments["ok"]:
		_failure(String(arguments["detail"]))
		return
	var spec_path := _absolute_path(String(arguments["spec"]))
	var input_root := _absolute_path(String(arguments["input_root"]))
	var output := _absolute_path(String(arguments["output"]))
	var result: Dictionary
	if arguments["command"] == "build":
		result = Pipeline.build_packet(
			spec_path, input_root, output, bool(arguments["clean"])
		)
	else:
		result = Pipeline.validate_packet(output, spec_path, input_root)
	if not result["ok"]:
		_failure(String(result["detail"]))
		return
	var payload := {
		"status": "PASS",
		"backend": "godot",
		"output": output.get_file(),
	}
	if result.has("checks_executed"):
		payload["checks_executed"] = result["checks_executed"]
	if result.has("run_identity"):
		payload["run_identity"] = result["run_identity"]
	print(JSON.stringify(payload, "", true, true))
	quit(0)
