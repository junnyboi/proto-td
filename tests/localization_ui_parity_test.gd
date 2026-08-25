extends SceneTree

const ThemeType := preload("res://scripts/ui/components/aetheria_theme.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var i18n := root.get_node_or_null("I18n")
	_check(i18n != null, "I18n autoload missing")
	if i18n == null:
		_finish()
		return
	var ui_copy_type := load("res://scripts/ui/components/ui_copy.gd") as GDScript
	_check(ui_copy_type != null, "UiCopy script failed to load after I18n initialization")
	if ui_copy_type == null:
		_finish()
		return
	_check(bool(i18n.call("reload_catalogs")), "English/Chinese catalogs failed canonical parity validation")
	var english := i18n.call("catalog_keys", &"en-US") as PackedStringArray
	var chinese := i18n.call("catalog_keys", &"zh-CN") as PackedStringArray
	_check(not english.is_empty() and english == chinese, "English/Chinese key sets differ")
	var english_lookup := {}
	for key: String in english:
		english_lookup[StringName(key)] = true
	for key: StringName in ui_copy_type.call("static_fallbacks"):
		_check(english_lookup.has(key), "static fallback is absent from catalogs: %s" % key)
	for key: StringName in ui_copy_type.call("placeholder_types"):
		_check(english_lookup.has(key), "typed placeholder schema is absent from catalogs: %s" % key)
	_check(bool(i18n.call("set_locale", &"zh-CN")), "Chinese locale activation failed")
	_check(StringName(i18n.call("locale")) == &"zh-CN", "Chinese locale did not become active")
	var chinese_back := String(i18n.call("t", &"ui.common.back", "Back"))
	_check(not chinese_back.is_empty() and chinese_back != "Back", "Chinese UI copy fell back to English")
	var theme := ThemeType.new()
	var font := theme.default_font
	_check(font != null and font.has_char("中".unicode_at(0)), "default UI font lacks CJK glyph coverage")
	_check(bool(i18n.call("set_locale", &"en-US")), "English locale restoration failed")
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("LOCALIZATION_UI_PARITY_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
