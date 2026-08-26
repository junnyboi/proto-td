extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sfx := root.get_node_or_null("Sfx")
	_check(sfx != null, "Sfx autoload is available")
	if sfx == null:
		_finish()
		return
	_check(bool(sfx.call("reload_catalog")), "SFX catalog loads")
	sfx.call("stop_all")

	var view_script: GDScript = load("res://scripts/view/battle_view.gd") as GDScript
	var view: Variant = view_script.new()
	var model := BattleModel.new()
	var spell := load("res://data/spells/slow_field.tres") as SpellDef
	_check(spell != null, "Slow Field definition loads")
	if spell == null:
		view.free()
		_finish()
		return
	model.spell_book = SpellBook.create({&"slow_field": spell}, PackedInt32Array([0]))
	view.model = model

	var starts_before := int(sfx.call("audible_start_count"))
	view.call("_push_spell_sfx")
	_check(
		int(sfx.call("audible_start_count")) == starts_before,
		"zero-cast ledger stays silent",
	)
	model.spell_book.mark_cast(&"slow_field", 0)
	view.call("_push_spell_sfx")
	_check(sfx.call("last_resolved_id") == &"slow_field_cast", "accepted cast plays blizzard cast")
	_check(
		String(sfx.call("last_stream_path")).ends_with("/slow_field_cast.wav"),
		"cast routes to the generated runtime derivative",
	)
	var starts_after_cast := int(sfx.call("audible_start_count"))
	view.call("_push_spell_sfx")
	_check(
		int(sfx.call("audible_start_count")) == starts_after_cast,
		"unchanged cast ledger does not replay audio",
	)

	var field := SlowFieldState.new()
	field.id = 42
	model.slow_fields.append(field)
	view.call("_sync_slow_field_audio_ids")
	_check(
		int(sfx.call("audible_start_count")) == starts_after_cast,
		"first observation of an active field does not fake an expiration",
	)
	model.slow_fields.clear()
	view.call("_sync_slow_field_audio_ids")
	_check(
		sfx.call("last_resolved_id") == &"slow_field_expire",
		"field disappearance plays the expiration blizzard",
	)
	_check(
		String(sfx.call("last_stream_path")).ends_with("/slow_field_expire.wav"),
		"expiration routes to the generated runtime derivative",
	)
	var starts_after_expire := int(sfx.call("audible_start_count"))
	view.call("_sync_slow_field_audio_ids")
	_check(
		int(sfx.call("audible_start_count")) == starts_after_expire,
		"an already-consumed expiration edge stays silent",
	)

	sfx.call("stop_all")
	view.free()
	for _frame: int in range(16):
		await process_frame
	await create_timer(0.5).timeout
	call_deferred("_finish")


func _finish() -> void:
	if _failures.is_empty():
		print("SLOW_FIELD_SFX_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
