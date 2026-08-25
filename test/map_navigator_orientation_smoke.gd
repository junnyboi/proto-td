extends SceneTree

const MAP_NAVIGATOR_SCRIPT := preload("res://scripts/view/map_navigator.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures := PackedStringArray()
	var source := load("res://data/stages/s8.tres") as StageDef
	if source == null:
		failures.append("S8 failed to load")
	else:
		_validate_portrait(source, failures)
		_validate_landscape(source, failures)
	if failures.is_empty():
		print("MAP_NAVIGATOR_ORIENTATION_SMOKE_OK")
		quit(0)
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _validate_portrait(source: StageDef, failures: PackedStringArray) -> void:
	var viewport := Vector2(720.0, 1280.0)
	var stage := source.copy_for_viewport(viewport)
	var navigator: RefCounted = MAP_NAVIGATOR_SCRIPT.new()
	navigator.relayout(stage, viewport)
	var expected_scale := IsoProjection.height_fill_scale(stage, viewport)
	if not is_equal_approx(navigator.scale, expected_scale):
		failures.append("portrait must use exact height-fill scale")
	if not is_equal_approx(navigator.pan.x, navigator.bounds.end.x):
		failures.append("portrait must start on the clockwise-rotated base side")
	if navigator.bounds.size.x <= 0.0:
		failures.append("S8 portrait must expose horizontal overflow for panning")
		return
	if not navigator.pan.is_equal_approx(navigator.default_pan()):
		failures.append("portrait default pan must match its boot framing")
	var edge_press := InputEventScreenTouch.new()
	edge_press.index = 0
	edge_press.position = Vector2(360.0, 640.0)
	edge_press.pressed = true
	navigator.handle_input(edge_press)
	var edge_drag := InputEventScreenDrag.new()
	edge_drag.index = 0
	edge_drag.position = Vector2(520.0, 640.0)
	edge_drag.relative = Vector2(160.0, 0.0)
	if not navigator.handle_input(edge_drag):
		failures.append("portrait edge drag was not consumed")
	if navigator.pan.x <= navigator.bounds.end.x:
		failures.append("portrait edge drag did not rubber-band past the bound")
	if navigator.pan.x > navigator.bounds.end.x + MAP_NAVIGATOR_SCRIPT.OVERSCROLL_LIMIT_PX:
		failures.append("portrait rubber-band exceeded its visual limit")
	var edge_release := InputEventScreenTouch.new()
	edge_release.index = 0
	edge_release.position = edge_drag.position
	edge_release.pressed = false
	navigator.handle_input(edge_release)
	var snap_frames := 0
	while navigator.is_inertia_active() and snap_frames < 300:
		navigator.advance_inertia(1.0 / 60.0)
		snap_frames += 1
	if not is_equal_approx(navigator.pan.x, navigator.bounds.end.x):
		failures.append("portrait rubber-band did not snap to the edge")
	if snap_frames >= 300:
		failures.append("portrait snap-back did not settle in bounded time")
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = Vector2(360.0, 640.0)
	press.pressed = true
	navigator.handle_input(press)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(240.0, 640.0)
	drag.relative = Vector2(-120.0, 0.0)
	if not navigator.handle_input(drag):
		failures.append("portrait touch drag was not consumed")
	if navigator.pan.x >= navigator.bounds.end.x:
		failures.append("portrait touch drag did not move horizontally")
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = drag.position
	release.pressed = false
	if not navigator.handle_input(release):
		failures.append("portrait drag release was not consumed")
	if not navigator.consume_primary_click_suppression():
		failures.append("portrait drag must suppress the deployment click")
	if not navigator.recenter():
		failures.append("recenter must report a changed panned view")
	if not navigator.pan.is_equal_approx(navigator.default_pan()):
		failures.append("recenter must restore the portrait default pan")


func _validate_landscape(source: StageDef, failures: PackedStringArray) -> void:
	var viewport := Vector2(1280.0, 720.0)
	var navigator: RefCounted = MAP_NAVIGATOR_SCRIPT.new()
	navigator.relayout(source.copy_for_viewport(viewport), viewport)
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = Vector2(640.0, 360.0)
	press.pressed = true
	if navigator.handle_input(press):
		failures.append("landscape primary touch must remain available for deployment")
	if navigator.is_dragging() or navigator.is_inertia_active():
		failures.append("landscape must not enter portrait drag state")
