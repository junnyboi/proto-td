extends SceneTree

const COVER_SCRIPT := preload("res://scripts/ui/components/top_aligned_cover.gd")
const LOADING_ART := preload("res://assets/loading/lunaris_reliquary_loading.png")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cover := COVER_SCRIPT.new()
	cover.texture = LOADING_ART
	root.add_child(cover)
	await process_frame

	var landscape := cover.source_rect_for_target(Vector2(1280.0, 720.0))
	_check(landscape.is_equal_approx(Rect2(0.0, 0.0, 2560.0, 1440.0)), "landscape should use the complete source")

	var portrait := cover.source_rect_for_target(Vector2(720.0, 1280.0))
	_check(is_equal_approx(portrait.position.x, 875.0), "portrait crop should remain horizontally centered")
	_check(is_zero_approx(portrait.position.y), "portrait crop must begin at the source top")
	_check(is_equal_approx(portrait.size.x, 810.0), "portrait crop width is incorrect")
	_check(is_equal_approx(portrait.size.y, 1440.0), "portrait crop must retain full source height")

	var ultrawide := cover.source_rect_for_target(Vector2(1920.0, 720.0))
	_check(is_zero_approx(ultrawide.position.y), "wide crop must remain pinned to the source top")
	_check(is_equal_approx(ultrawide.size.y, 960.0), "wide crop height is incorrect")
	_check(cover.mouse_filter == Control.MOUSE_FILTER_IGNORE, "cover must not intercept input")

	var loading := load("res://scenes/loading.tscn").instantiate() as Control
	root.add_child(loading)
	await process_frame
	var artwork := loading.get_node_or_null("LunarisArtwork")
	_check(artwork != null, "loading scene is missing LunarisArtwork")
	_check(artwork != null and artwork.get_script() == COVER_SCRIPT, "loading scene does not use top-aligned cover")
	_check(artwork != null and artwork.texture == LOADING_ART, "loading scene uses the wrong artwork")

	loading.queue_free()
	cover.queue_free()
	for _frame: int in range(4):
		await process_frame
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("LOADING_ART_ALIGNMENT_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
