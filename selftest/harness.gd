class_name SelfTestHarness
extends SceneTree

## Scenario self-test runner (game-agnostic). Runs in two lanes with the same
## scenario file:
##   headless (fast, default in verify.sh): shots no-op with [SHOT-SKIPPED]
##   windowed (pixels): ~/bin/godot --path . --resolution 1280x720 \
##       -s selftest/harness.gd -- --scenario=<name> --seed=42 \
##       --shots=res://artifacts/<name>
## Scenarios live at res://selftest/scenarios/<name>.gd:
## `extends RefCounted` with `func run(h: SelfTestHarness) -> void`.

const TILE_SIZE := 64.0
const DEFAULT_MAX_FRAMES := 3600
## Marks injected events so game code can ignore the REAL mouse during tests
## (a human moving the cursor over the focused test window would otherwise
## race the scenario's input).
const SYNTHETIC_DEVICE := 4242

var seed_value: int = 42
var max_frames: int = DEFAULT_MAX_FRAMES
var scene: Node

var _scenario_name := ""
var _shots_dir := "res://artifacts/misc"
var _frames_used := 0
var _checks: Array[Dictionary] = []
var _shots: Array[String] = []
var _finished := false


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			_scenario_name = arg.trim_prefix("--scenario=")
		elif arg.begins_with("--seed="):
			seed_value = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shots_dir))
	process_frame.connect(_on_frame)
	_run()


func frames(n: int) -> void:
	for _i: int in n:
		await process_frame


func physics_frames(n: int) -> void:
	for _i: int in n:
		await physics_frame


func autoload(autoload_name: String) -> Node:
	return root.get_node(NodePath(autoload_name))


func press(action: String) -> void:
	Input.action_press(action)


func release(action: String) -> void:
	Input.action_release(action)


func move_mouse_to(world_pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.device = SYNTHETIC_DEVICE
	ev.position = root.canvas_transform * world_pos
	ev.global_position = ev.position
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func click_cell(cell: Vector2i, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var world_pos := Vector2(cell) * TILE_SIZE + Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	move_mouse_to(world_pos)
	await frames(2)
	_send_mouse_button(world_pos, button, true)
	await physics_frames(3)
	_send_mouse_button(world_pos, button, false)
	await frames(2)


## Click at raw viewport coordinates (UI controls). The press is held across
## PHYSICS frames — render frames can outnumber physics ticks, so a
## render-frame hold may never be seen by _physics_process-driven reads.
func click_view(view_pos: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var motion := InputEventMouseMotion.new()
	motion.device = SYNTHETIC_DEVICE
	motion.position = view_pos
	motion.global_position = view_pos
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await frames(2)
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.device = SYNTHETIC_DEVICE
		ev.position = view_pos
		ev.global_position = view_pos
		ev.button_index = button
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()
		await physics_frames(3)
		await frames(1)


## Press/release halves of a drag at raw viewport coordinates (drags that
## start on a UI control and end on the game grid). Motion precedes each half
## so pointer-tracking adapters stay current (injected motion never moves
## get_mouse_position); presses are held across PHYSICS frames (see click_view).
func press_mouse_at(view_pos: Vector2) -> void:
	_send_view_motion(view_pos)
	await frames(2)
	_send_view_button(view_pos, MOUSE_BUTTON_LEFT, true)
	await physics_frames(3)
	await frames(1)


func release_mouse_at(view_pos: Vector2) -> void:
	_send_view_motion(view_pos)
	await frames(2)
	_send_view_button(view_pos, MOUSE_BUTTON_LEFT, false)
	await frames(2)


func move_mouse_to_view(view_pos: Vector2) -> void:
	_send_view_motion(view_pos)


func press_mouse_on_cell(cell: Vector2i, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var world_pos := Vector2(cell) * TILE_SIZE + Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	move_mouse_to(world_pos)
	await frames(2)
	_send_mouse_button(world_pos, button, true)


func release_mouse_on_cell(cell: Vector2i, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var world_pos := Vector2(cell) * TILE_SIZE + Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	_send_mouse_button(world_pos, button, false)
	await frames(2)


func hold_mouse_on_cell(cell: Vector2i, seconds: float) -> void:
	var world_pos := Vector2(cell) * TILE_SIZE + Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	move_mouse_to(world_pos)
	await frames(2)
	_send_mouse_button(world_pos, MOUSE_BUTTON_LEFT, true)
	await physics_frames(int(seconds * 60.0))
	_send_mouse_button(world_pos, MOUSE_BUTTON_LEFT, false)
	await frames(2)


func check(check_name: String, ok: bool, detail: String = "") -> void:
	_checks.append({"name": check_name, "ok": ok, "detail": detail})
	print("[%s] %s %s" % ["PASS" if ok else "FAIL", check_name, detail])


func shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("[SHOT-SKIPPED] " + shot_name)
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var file := "%s/%s.png" % [_shots_dir, shot_name]
	img.save_png(ProjectSettings.globalize_path(file))
	_shots.append(shot_name + ".png")
	print("[SHOT] " + file)


func _send_view_motion(view_pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.device = SYNTHETIC_DEVICE
	ev.position = view_pos
	ev.global_position = view_pos
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _send_view_button(view_pos: Vector2, button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.device = SYNTHETIC_DEVICE
	ev.position = view_pos
	ev.global_position = view_pos
	ev.button_index = button
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _send_mouse_button(world_pos: Vector2, button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.device = SYNTHETIC_DEVICE
	ev.position = root.canvas_transform * world_pos
	ev.global_position = ev.position
	ev.button_index = button
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _run() -> void:
	# The headless dummy window boots 64x64 regardless of project display
	# settings and silently drops GUI events beyond that rect. Pinning the
	# design size only sticks after the first frame (earlier sets are
	# clobbered during engine setup), so it happens here, pre-scene-load.
	await process_frame
	root.size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"),
	)
	var game := root.get_node_or_null("Game")
	if game != null and game.has_method("set_run_seed"):
		game.call("set_run_seed", seed_value)
	var main_scene_path: String = ProjectSettings.get_setting("application/run/main_scene")
	var packed: PackedScene = load(main_scene_path)
	scene = packed.instantiate()
	root.add_child(scene)
	var scenario_path := "res://selftest/scenarios/%s.gd" % _scenario_name
	if not ResourceLoader.exists(scenario_path):
		check("scenario exists: " + _scenario_name, false, scenario_path)
		_finish()
		return
	var scenario: RefCounted = (load(scenario_path) as GDScript).new()
	await frames(5)
	await scenario.call("run", self)
	_finish()


func _on_frame() -> void:
	_frames_used += 1
	if not _finished and _frames_used > max_frames:
		check("watchdog: frame budget", false, "exceeded %d frames" % max_frames)
		_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	var all_ok := true
	for c: Dictionary in _checks:
		if not c["ok"]:
			all_ok = false
	var report := {
		"scenario": _scenario_name,
		"seed": seed_value,
		"checks": _checks,
		"shots": _shots,
		"frames_used": _frames_used,
		"result": "pass" if all_ok else "fail",
	}
	var report_path := ProjectSettings.globalize_path(_shots_dir + "/report.json")
	var f := FileAccess.open(report_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  "))
		f.close()
	print("[RESULT] %s (%d checks, %d shots, %d frames)" % [
		report["result"], _checks.size(), _shots.size(), _frames_used,
	])
	quit(0 if all_ok else 1)
