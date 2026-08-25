extends SceneTree

const STATUS_SCRIPT := preload("res://scripts/ui/components/music_pack_status.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var music := root.get_node_or_null("Music")
	_check(music != null, "Music autoload missing")
	if music == null:
		_finish()
		return

	var fake_spec := {
		1: {
			"url": "http://127.0.0.1:9/music-act-1.pck",
			"sha256": "a".repeat(64),
			"bytes": 1024,
		},
	}
	_check(int(music.call("configure_content_packs", fake_spec)) == 1, "fake pack spec rejected")
	_check(int(music.call("active_content_pack_act", 1)) == 1, "preferred configured act not exposed")

	var status := STATUS_SCRIPT.new()
	status.set_act(1)
	var retry_availability: Array[bool] = []
	status.retry_availability_changed.connect(
		func(available: bool) -> void: retry_availability.append(available)
	)
	root.add_child(status)
	await process_frame
	_check(not status.visible, "configured idle pack status should remain unobtrusive")

	music.call("_set_pack_state", 1, &"loading")
	await process_frame
	var progress := status.find_child("DownloadProgress", true, false) as ProgressBar
	var label := status.find_child("StatusLabel", true, false) as Label
	var retry := status.find_child("RetryButton", true, false) as Button
	_check(status.visible, "loading pack status did not appear")
	_check(progress != null and progress.visible, "loading progress bar missing")
	_check(retry != null and not retry.visible, "retry appeared before failure")
	_check(label != null and label.text.contains("DOWNLOADING"), "loading copy missing")

	music.call("_set_pack_state", 1, &"failed")
	await process_frame
	_check(status.visible, "failed pack status disappeared")
	_check(progress != null and not progress.visible, "failed pack kept progress bar visible")
	_check(retry != null and retry.visible, "failed pack did not expose retry")
	_check(
		not retry_availability.is_empty() and retry_availability[-1],
		"retry availability did not notify focus owners",
	)
	_check(retry != null and retry.focus_mode == Control.FOCUS_ALL, "retry is not keyboard focusable")
	_check(label != null and label.text.contains("DOWNLOAD INTERRUPTED"), "failure copy missing")

	var retry_count := [0]
	status.retry_requested.connect(func(_act: int) -> void: retry_count[0] += 1)
	retry.pressed.emit()
	await process_frame
	_check(retry_count[0] == 1, "retry signal did not fire exactly once")
	_check(music.call("pack_state", 1) == &"loading", "retry did not restart the request")
	music.call("configure_content_packs", fake_spec)
	music.call("_set_pack_state", 1, &"ready")
	await process_frame
	_check(not status.visible, "ready pack status did not auto-hide")

	status.set_compact(true)
	_check(status.custom_minimum_size.x == 270.0, "compact status width is incorrect")

	var title_source := FileAccess.get_file_as_string("res://scripts/ui/title.gd")
	var staging_source := FileAccess.get_file_as_string("res://scripts/ui/staging.gd")
	_check(title_source.contains("MusicPackStatusType"), "title screen does not own pack status")
	_check(staging_source.contains("MusicPackStatusType"), "Company Command does not own pack status")
	for path: String in [
		"res://scripts/ui/stage_select.gd",
		"res://scripts/ui/squad_select.gd",
		"res://scripts/view/battle_view.gd",
		"res://scripts/ui/results.gd",
	]:
		_check(
			not FileAccess.get_file_as_string(path).contains("MusicPackStatusType"),
			"pack status leaked outside title/start surfaces: %s" % path,
		)

	music.call("configure_content_packs", fake_spec)
	music.call("_set_pack_state", 1, &"loading")
	var title: Node = load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	await process_frame
	music.call("_set_pack_state", 1, &"failed")
	await process_frame
	var title_start := title.find_child("StartButton", true, false) as Button
	var title_retry := title.find_child("RetryButton", true, false) as Button
	_check(title_retry != null and title_retry.visible, "title Retry did not appear after dynamic failure")
	_check(
		title_start != null and title_retry != null
		and title_start.focus_previous == title_start.get_path_to(title_retry),
		"title focus cycle did not dynamically include Retry",
	)
	if title_retry != null:
		title_retry.grab_focus()
		await process_frame
		_check(root.gui_get_focus_owner() == title_retry, "title Retry could not receive keyboard focus")

	music.call("configure_content_packs", {})
	var game: Node = root.get_node_or_null("Game")
	if game != null:
		game.set("content", null)
	music.call("stop")
	title.queue_free()
	status.queue_free()
	title = null
	status = null
	for _frame: int in range(8):
		await process_frame
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MUSIC_PACK_STATUS_UI_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
