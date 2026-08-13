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
var _pixel_skipped: Array[String] = []
var _done_expected := false
var _done_called := false
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


## (P12.0: the origin-anchored cell-click family — click_cell,
## press/release/hold_mouse_on_cell — is gone. It ignored the grid origin
## and predates the iso projection; grid clicks resolve coordinates via
## view.cell_center + the view-space helpers above, never harness cell math.)
func move_mouse_to_view(view_pos: Vector2) -> void:
	_send_view_motion(view_pos)


func check(check_name: String, ok: bool, detail: String = "") -> void:
	_checks.append({"name": check_name, "ok": ok, "detail": detail})
	print("[%s] %s %s" % ["PASS" if ok else "FAIL", check_name, detail])


## Completion sentinel (opt-in): a scenario whose run() aborts on a script
## error resumes the harness normally, and if every check recorded so far
## passed the report reads as a vacuous green. Scenarios call expect_done()
## first and done() last; _finish fails the run if the pair is broken.
func expect_done() -> void:
	_done_expected = true


func done() -> void:
	_done_called = true


func shot(shot_name: String) -> void:
	await shot_grab(shot_name)


## shot() that also returns the captured Image for pixel probes (null in the
## headless lane, where pixels don't exist — G2). Callers pass the Image to
## check_pixels; a skipped probe is recorded, never counted as a pass.
func shot_grab(shot_name: String) -> Image:
	if DisplayServer.get_name() == "headless":
		print("[SHOT-SKIPPED] " + shot_name)
		return null
	# macOS suspends drawing for fully-occluded windows (batch verify opens
	# each scenario's window behind the active app), so a bare
	# frame_post_draw can wait forever while process_frame spins uncapped —
	# the watchdog then reds out at the first late shot. Force a draw, but
	# never await the signal unbounded: after a frame deadline, grab the
	# last-rendered texture (best effort beats an infinite hang; the
	# foregrounding in _run makes the deadline path rare).
	var drawn := [false]
	var on_draw := func() -> void: drawn[0] = true
	RenderingServer.frame_post_draw.connect(on_draw, CONNECT_ONE_SHOT)
	RenderingServer.force_draw()
	var deadline := 30
	while not drawn[0] and deadline > 0:
		deadline -= 1
		await process_frame
	if not drawn[0]:
		if RenderingServer.frame_post_draw.is_connected(on_draw):
			RenderingServer.frame_post_draw.disconnect(on_draw)
		print("[SHOT-STALE] %s (no draw within deadline — occluded window?)" % shot_name)
	var img := root.get_texture().get_image()
	var file := "%s/%s.png" % [_shots_dir, shot_name]
	img.save_png(ProjectSettings.globalize_path(file))
	_shots.append(shot_name + ".png")
	print("[SHOT] " + file)
	return img


## Pixel check with the headless-skip discipline: img == null records a
## [PIXEL-SKIPPED] entry in report.json (NOT a pass — the juice gate is only
## judged from a windowed run with zero skips, td-phase-9.md §2.1.8).
func check_pixels(check_name: String, img: Image, predicate: Callable, detail := "") -> void:
	if img == null:
		_pixel_skipped.append(check_name)
		print("[PIXEL-SKIPPED] " + check_name)
		return
	check(check_name, bool(predicate.call(img)), detail)


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
	if DisplayServer.get_name() != "headless":
		# quiet window (PAINPOINTS Phase 13): never take focus (creation-time
		# no_focus comes from verify.sh's transient override.cfg; this covers
		# focus-taking after boot) and park bottom-right, out of the human's
		# way. Never minimize/hide instead — macOS stops drawing hidden
		# windows and shot_grab stalls on frame_post_draw.
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		var usable := DisplayServer.screen_get_usable_rect()
		var park := usable.position + usable.size \
			- DisplayServer.window_get_size() - Vector2i(8, 8)
		DisplayServer.window_set_position(park)
	var shield := SelfTestInputShield.new()
	shield.name = "RealInputShield"
	root.add_child(shield)
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
	# defensive teardown: a scenario that failed mid-drag/mid-beat must not
	# poison the next run's wall clock (td-phase-9.md §2.1.3)
	Engine.time_scale = 1.0
	if _done_expected and not _done_called:
		check("scenario ran to completion", false, "run() aborted before done()")
	var all_ok := true
	for c: Dictionary in _checks:
		if not c["ok"]:
			all_ok = false
	var report := {
		"scenario": _scenario_name,
		"seed": seed_value,
		"checks": _checks,
		"shots": _shots,
		"pixel_skipped": _pixel_skipped,
		"frames_used": _frames_used,
		"done_expected": _done_expected,
		"done_called": _done_called,
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
