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
	var expected_scale := minf(
		IsoProjection.height_fill_scale(stage, viewport),
		MAP_NAVIGATOR_SCRIPT.PORTRAIT_MAX_SCALE,
	)
	if not is_equal_approx(navigator.scale, expected_scale):
		failures.append("portrait must use capped height-fill scale")
	if not is_zero_approx(navigator.bounds.size.y) or not is_zero_approx(navigator.pan.y):
		failures.append("portrait pan must remain horizontal")
	if not is_equal_approx(navigator.pan.x, navigator.bounds.end.x):
		failures.append("portrait must start on the clockwise-rotated base side")
	if navigator.bounds.size.x <= 0.0:
		failures.append("S8 portrait must expose horizontal overflow for panning")
		return
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
	if navigator.pan.y != 0.0:
		failures.append("portrait drag changed vertical pan")


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
