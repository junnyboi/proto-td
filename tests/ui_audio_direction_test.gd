extends SceneTree

const UI_IDS := [
	&"ui_click",
	&"ui_back",
	&"ui_confirm",
	&"menu_open",
	&"menu_close",
]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sfx := root.get_node_or_null("Sfx")
	_check(sfx != null, "Sfx autoload is available")
	if sfx != null:
		_check(bool(sfx.call("reload_catalog")), "SFX catalog loads")
		_check(int(sfx.call("catalog_entry_count")) >= 15, "expanded catalog contains UI suite")
		for id: StringName in UI_IDS:
			_check(sfx.call("resolved_id_for", id) == id, "%s resolves directly" % id)
			_check(bool(sfx.call("play", String(id))), "%s plays" % id)
			_check(sfx.call("last_resolved_id") == id, "%s owns the last voice" % id)
			var stream := load(String(sfx.call("last_stream_path"))) as AudioStream
			_check(stream != null, "%s stream loads" % id)
			if stream != null:
				_check(stream.get_length() >= 1.0, "%s is at least one second" % id)
				_check(stream.get_length() <= 3.05, "%s stays within the three-second SFX budget" % id)
			stream = null
			await process_frame
		_check(sfx.call("resolved_id_for", &"ui_accept") == &"ui_confirm", "accept alias resolves")
		_check(sfx.call("resolved_id_for", &"ui_select") == &"ui_click", "select alias resolves")
		_check(sfx.call("resolved_id_for", &"ui_hover") == &"ui_click", "hover alias resolves")
		for spell_id: StringName in [&"bolt", &"charm", &"slow_field"]:
			_check(
				sfx.call("resolved_id_for", spell_id) == &"ability_ready",
				"%s spell SFX resolves" % spell_id,
			)
		sfx.call("stop_all")
		for _frame: int in range(16):
			await process_frame
		await create_timer(0.5).timeout
	call_deferred("_finish")


func _finish() -> void:
	if _failures.is_empty():
		print("UI_AUDIO_DIRECTION_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
