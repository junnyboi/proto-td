extends SceneTree

const PlayerType := preload("res://scripts/ui/components/archive_audio_log_player.gd")
const IDS: Array[StringName] = [&"stewardship", &"choir", &"equation", &"garden"]
const LOCALES: Array[StringName] = [&"en-US", &"zh-CN"]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(PlayerType.STREAMS.size() == 2, "archive audio map must contain exactly two locales")
	for locale_id: StringName in LOCALES:
		_check((PlayerType.STREAMS[locale_id] as Dictionary).size() == 4, "%s archive audio map must contain exactly four streams" % locale_id)
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
			_check(not player.set_entry(&"mercy"), "%s obsolete stable ID unexpectedly loaded" % locale_id)
			_check(player.set_entry(entry_id), "%s/%s narration did not reload after rejection" % [locale_id, entry_id])
			_check(player.stream_path().contains("assets/audio/narrative/anima-archive/%s/%s.ogg" % [locale_id, entry_id]), "%s/%s selected the wrong locale stream" % [locale_id, entry_id])
			_check(player.duration_seconds() > 30.0, "%s/%s narration is unexpectedly short" % [locale_id, entry_id])
			var play := player.find_child("AudioLogPlayPause", true, false) as Button
			var restart := player.find_child("AudioLogRestart", true, false) as Button
			var seek := player.find_child("AudioLogSeek", true, false) as HSlider
			var status := player.find_child("AudioLogStatus", true, false) as Label
			_check(play != null and restart != null and seek != null and status != null, "audio controls are incomplete")
			_check(play.custom_minimum_size.y >= 44.0 and restart.custom_minimum_size.y >= 44.0, "audio controls are not touch safe")
			_check(seek.focus_mode == Control.FOCUS_ALL and not seek.accessibility_name.is_empty(), "audio seek control is not accessible")
			_check(play.focus_mode == Control.FOCUS_ALL and restart.focus_mode == Control.FOCUS_ALL, "audio buttons are not keyboard focusable")
			_check(not play.accessibility_name.is_empty() and not restart.accessibility_name.is_empty(), "audio buttons lost accessibility names")
			if entry_id == &"stewardship":
				play.pressed.emit()
				await create_timer(0.15).timeout
				_check(player.narration_playing(), "%s narration did not start" % locale_id)
				_check(status.text.contains("NARRAT") or status.text.contains("旁白"), "%s narration status did not update" % locale_id)
				play.pressed.emit()
				_check(not player.narration_playing(), "%s narration did not pause" % locale_id)
				seek.value = 12.0
				await process_frame
				_check(is_equal_approx(seek.value, 12.0), "%s narration seek did not update" % locale_id)
				_check(absf(player.playback_position() - 12.0) < 0.5, "%s narration did not seek the active stream" % locale_id)
				restart.pressed.emit()
				await process_frame
				_check(player.narration_playing(), "%s narration did not restart" % locale_id)
				_check(player.playback_position() < 1.0, "%s restart did not return to the beginning" % locale_id)
				var raw_player := player.find_child("ArchiveNarrationPlayer", true, false) as AudioStreamPlayer
				raw_player.stop()
				player._on_finished()
				_check(not player.narration_playing() and absf(seek.value - player.duration_seconds()) < 0.2, "%s completion state drifted" % locale_id)
			_dispose(player)
			await process_frame

	var switching_player := PlayerType.new() as ArchiveAudioLogPlayer
	root.add_child(switching_player)
	await process_frame
	i18n.call("set_locale", &"en-US")
	_check(switching_player.set_entry(&"stewardship"), "locale-switch fixture failed to load")
	switching_player.find_child("AudioLogPlayPause", true, false).pressed.emit()
	await create_timer(0.1).timeout
	i18n.call("set_locale", &"zh-CN")
	await process_frame
	_check(switching_player.stream_path().contains("anima-archive/zh-CN/stewardship.ogg"), "locale switch did not replace the active stream")
	_check(switching_player.narration_playing(), "locale switch did not resume active narration")
	var fallback_stream := switching_player._stream_for_locale(&"fr-FR", &"stewardship")
	_check(fallback_stream != null and fallback_stream.resource_path.contains("anima-archive/en-US/stewardship.ogg"), "unsupported locale did not fall back to English")
	_dispose(switching_player)
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
		_check(embedded != null, "Anima Archive omitted the audio-log player")
		if embedded != null:
			_check(embedded.entry_id() == &"stewardship", "first archive record did not bind its narration")
			_check(embedded.stream_path().contains("assets/audio/narrative/anima-archive/en-US/stewardship.ogg"), "first archive record bound the wrong narration")
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
