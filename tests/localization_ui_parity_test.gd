extends SceneTree

const ThemeType := preload("res://scripts/ui/components/aetheria_theme.gd")
const CHINESE_CATALOG_PATH := "res://localization/zh-CN.json"
const BUNDLED_CHINESE_FONT_PATH := "res://assets/fonts/ProtosSansSC.otf"
const SOURCE_ROOTS := ["res://scripts/ui", "res://scripts/view"]
const SOURCE_SYMBOLS := "←→↔↕《》×…"

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
	var body_font := theme.default_font
	var display_font := theme.get_font(&"font", &"AuiTitleLabel")
	var bundled_font := FontFile.new()
	var font_error := bundled_font.load_dynamic_font(BUNDLED_CHINESE_FONT_PATH)
	_check(font_error == OK, "bundled Chinese font failed to load")
	var catalog_text := FileAccess.get_file_as_string(CHINESE_CATALOG_PATH)
	var catalog_variant: Variant = JSON.parse_string(catalog_text)
	_check(catalog_variant is Dictionary, "Chinese catalog JSON failed to parse for font coverage")
	if catalog_variant is Dictionary:
		var catalog := catalog_variant as Dictionary
		var entries := catalog.get("entries", {}) as Dictionary
		var required := _required_codepoints(entries)
		for codepoint: int in required:
			var label := "U+%04X '%s'" % [codepoint, String.chr(codepoint)]
			_check(bundled_font.has_char(codepoint), "bundled Chinese font lacks %s" % label)
			_check(body_font != null and body_font.has_char(codepoint), "body font chain lacks %s" % label)
			_check(display_font != null and display_font.has_char(codepoint), "display font chain lacks %s" % label)
	_check_literal_source_keys(english_lookup)
	_check(bool(i18n.call("set_locale", &"en-US")), "English locale restoration failed")
	_finish()


func _required_codepoints(entries: Dictionary) -> Array[int]:
	var unique := {}
	for raw_value: Variant in entries.values():
		var value := String(raw_value)
		for index: int in value.length():
			var codepoint := value.unicode_at(index)
			if codepoint >= 32 and codepoint != 127:
				unique[codepoint] = true
	for index: int in SOURCE_SYMBOLS.length():
		unique[SOURCE_SYMBOLS.unicode_at(index)] = true
	var required: Array[int] = []
	for raw_codepoint: Variant in unique:
		required.append(int(raw_codepoint))
	required.sort()
	return required


func _check_literal_source_keys(catalog_lookup: Dictionary) -> void:
	var regex := RegEx.new()
	regex.compile('[&]?"((?:ui|data)\\.[A-Za-z0-9_.]*[A-Za-z0-9_])"')
	for source_root: String in SOURCE_ROOTS:
		_scan_source_dir(source_root, regex, catalog_lookup)


func _scan_source_dir(path: String, regex: RegEx, catalog_lookup: Dictionary) -> void:
	var directory := DirAccess.open(path)
	_check(directory != null, "localization source directory missing: %s" % path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var child := path.path_join(entry)
			if directory.current_is_dir():
				_scan_source_dir(child, regex, catalog_lookup)
			elif entry.ends_with(".gd"):
				var source := FileAccess.get_file_as_string(child)
				for result: RegExMatch in regex.search_all(source):
					var key := StringName(result.get_string(1))
					_check(catalog_lookup.has(key), "literal production localization key is absent from catalogs: %s (%s)" % [key, child])
		entry = directory.get_next()
	directory.list_dir_end()


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
