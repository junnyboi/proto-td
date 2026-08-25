extends SceneTree

const UI_IDS := [
	&"ui_hover",
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
		_check(int(sfx.call("catalog_entry_count")) >= 16, "expanded catalog contains hover UI suite")
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
		_check(sfx.call("resolved_id_for", &"ui_hover") == &"ui_hover", "dedicated hover cue resolves")
		for spell_id: StringName in [&"bolt", &"charm", &"slow_field"]:
			_check(
				sfx.call("resolved_id_for", spell_id) == &"ability_ready",
				"%s spell SFX resolves" % spell_id,
			)
		var button := Button.new()
		button.name = "HoverAudioTestButton"
		button.text = "Hover"
		var custom_control := Control.new()
		custom_control.focus_mode = Control.FOCUS_ALL
		custom_control.mouse_filter = Control.MOUSE_FILTER_STOP
		var hover_controls: Array[Control] = [
			button,
			HSlider.new(),
			LineEdit.new(),
			TextEdit.new(),
			OptionButton.new(),
			SpinBox.new(),
			VScrollBar.new(),
			ItemList.new(),
			TabBar.new(),
			MenuBar.new(),
			custom_control,
		]
		for control: Control in hover_controls:
			root.add_child(control)
		var ephemeral_control := Control.new()
		root.add_child(ephemeral_control)
		ephemeral_control.queue_free()
		await process_frame
		await create_timer(0.15).timeout
		for control: Control in hover_controls:
			_check(
				bool(sfx.call("hover_is_bound", control)),
				"%s receives global hover binding" % control.get_class(),
			)
		_check(bool(sfx.call("hover_target_eligible", button)), "enabled button is hover eligible")
		var hover_plays_before := int(sfx.call("hover_play_count"))
		button.mouse_entered.emit()
		await process_frame
		_check(
			int(sfx.call("hover_play_count")) == hover_plays_before + 1,
			"hovering an eligible button plays exactly one hover cue",
		)
		_check(sfx.call("last_resolved_id") == &"ui_hover", "global hover resolves the hover cue")
		var option_button := hover_controls[4] as OptionButton
		option_button.mouse_entered.emit()
		await process_frame
		_check(
			int(sfx.call("hover_play_count")) == hover_plays_before + 1,
			"global debounce suppresses rapid movement between controls",
		)
		await create_timer(0.08).timeout
		option_button.mouse_entered.emit()
		await process_frame
		_check(
			int(sfx.call("hover_play_count")) == hover_plays_before + 2,
			"a new control plays after the debounce window",
		)
		button.disabled = true
		button.mouse_exited.emit()
		await create_timer(0.08).timeout
		button.mouse_entered.emit()
		await process_frame
		_check(
			int(sfx.call("hover_play_count")) == hover_plays_before + 2,
			"disabled controls remain silent on hover",
		)
		button.disabled = false
		button.hide()
		await create_timer(0.08).timeout
		button.mouse_entered.emit()
		await process_frame
		_check(
			int(sfx.call("hover_play_count")) == hover_plays_before + 2,
			"hidden controls remain silent on hover",
		)
		var slider := hover_controls[1] as HSlider
		slider.editable = false
		await create_timer(0.08).timeout
		slider.mouse_entered.emit()
		await process_frame
		_check(
			int(sfx.call("hover_play_count")) == hover_plays_before + 2,
			"non-editable sliders remain silent on hover",
		)
		slider.editable = true
		await create_timer(0.08).timeout
		slider.mouse_entered.emit()
		await process_frame
		_check(
			int(sfx.call("hover_play_count")) == hover_plays_before + 3,
			"re-enabled sliders receive hover audio without rebinding",
		)
		custom_control.set_meta(&"sfx_hover_disabled", true)
		await create_timer(0.08).timeout
		custom_control.mouse_entered.emit()
		await process_frame
		_check(
			int(sfx.call("hover_play_count")) == hover_plays_before + 3,
			"opt-out metadata suppresses hover audio",
		)
		var dynamic_control := Control.new()
		dynamic_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dynamic_control.focus_mode = Control.FOCUS_NONE
		root.add_child(dynamic_control)
		await process_frame
		_check(bool(sfx.call("hover_is_bound", dynamic_control)), "initially inert controls bind safely")
		dynamic_control.mouse_filter = Control.MOUSE_FILTER_STOP
		dynamic_control.focus_mode = Control.FOCUS_ALL
		dynamic_control.mouse_entered.emit()
		await process_frame
		_check(
			int(sfx.call("hover_play_count")) == hover_plays_before + 3,
			"readiness delay suppresses newly interactive controls under the pointer",
		)
		await create_timer(0.15).timeout
		dynamic_control.mouse_entered.emit()
		await process_frame
		_check(
			int(sfx.call("hover_play_count")) == hover_plays_before + 4,
			"dynamically enabled controls receive hover audio after readiness",
		)
		dynamic_control.queue_free()
		for control: Control in hover_controls:
			control.queue_free()
		await process_frame
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
