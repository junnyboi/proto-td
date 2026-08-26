extends SceneTree

const PlayerType := preload("res://scripts/ui/components/archive_audio_log_player.gd")
const IDS: Array[StringName] = [&"stewardship", &"choir", &"equation", &"garden"]
const LOCALES: Array[StringName] = [&"en-US", &"zh-CN"]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var i18n := root.get_node_or_null("I18n")
	_check(i18n != null, "I18n autoload missing")
	if i18n == null:
		_finish()
		return

	for locale_id: StringName in LOCALES:
		_check(bool(i18n.call("set_locale", locale_id)), "locale activation failed: %s" % locale_id)
		for entry_id: StringName in IDS:
			var player := PlayerType.new() as ArchiveAudioLogPlayer
			root.add_child(player)
			await process_frame
			_check(player.set_entry(entry_id), "%s/%s narration did not load" % [locale_id, entry_id])
			_check(player.stream_path().contains(String(locale_id)), "%s/%s selected the wrong locale stream" % [locale_id, entry_id])
			_check(player.duration_seconds() >= 30.0, "%s/%s narration is unexpectedly short" % [locale_id, entry_id])
			var play := player.find_child("AudioLogPlayPause", true, false) as Button
			var restart := player.find_child("AudioLogRestart", true, false) as Button
			var seek := player.find_child("AudioLogSeek", true, false) as HSlider
			var status := player.find_child("AudioLogStatus", true, false) as Label
			_check(play != null and restart != null and seek != null and status != null, "audio controls are incomplete")
			_check(play.custom_minimum_size.y >= 44.0 and restart.custom_minimum_size.y >= 44.0, "audio controls are not touch safe")
			_check(seek.focus_mode == Control.FOCUS_ALL and not seek.accessibility_name.is_empty(), "audio seek control is not accessible")
			if entry_id == &"stewardship":
				play.pressed.emit()
				await create_timer(0.15).timeout
				_check(player.narration_playing(), "%s narration did not start" % locale_id)
				_check(status.text.contains("NARRAT") or status.text.contains("旁白"), "%s narration status did not update" % locale_id)
				play.pressed.emit()
				_check(not player.narration_playing(), "%s narration did not pause" % locale_id)
				restart.pressed.emit()
				await process_frame
				_check(player.narration_playing(), "%s narration did not restart" % locale_id)
			_dispose(player)
			await process_frame

	i18n.call("set_locale", &"en-US")
	var game := root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game != null:
		game.call("set_run_seed", 3318)
		_check(bool(game.call("start_campaign", false, true)), "archive audio campaign fixture failed")
		var archive := load("res://scenes/narrative_archive.tscn").instantiate() as Control
		root.add_child(archive)
		await process_frame
		await process_frame
		var embedded := archive.find_child("ArchiveAudioLog", true, false) as ArchiveAudioLogPlayer
		_check(embedded != null, "Mercy Archive omitted the audio-log player")
		if embedded != null:
			_check(embedded.entry_id() == &"stewardship", "first archive record did not bind its narration")
			_check(embedded.stream_path().contains("en-US/stewardship"), "first archive record bound the wrong narration")
		_dispose(archive)
		game.set("content", null)
		game.set("campaign_active", false)
		game.set("campaign", null)
		game.set("campaign_store", null)

	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	await create_timer(0.15).timeout
	_finish()


func _dispose(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("ARCHIVE_AUDIO_LOG_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
