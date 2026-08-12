extends Node

## TD-012 presentation-only localization seam. Locale and catalog data never enter
## simulation, save, hash, replay, or telemetry state.

signal locale_changed(locale_id: StringName)

const DEFAULT_LOCALE := &"en-US"
const CATALOG_PATH := "res://localization/en-US.json"

var _locale := DEFAULT_LOCALE
var _entries: Dictionary = {}


func _ready() -> void:
	var loaded := reload_catalog()
	assert(loaded, "Aetheria Tactics en-US catalog must load")
	TranslationServer.set_locale(String(DEFAULT_LOCALE))
	DisplayServer.window_set_title(t(&"ui.game_title", "Aetheria Tactics"))


func t(key: StringName, fallback: String) -> String:
	var value: Variant = _entries.get(String(key), fallback)
	if value is String and not String(value).is_empty():
		return String(value)
	return fallback


func locale() -> StringName:
	return _locale


func supported_locales() -> PackedStringArray:
	return PackedStringArray([String(DEFAULT_LOCALE)])


func set_locale(locale_id: StringName) -> bool:
	if locale_id != DEFAULT_LOCALE:
		return false
	if _locale == locale_id:
		return true
	_locale = locale_id
	TranslationServer.set_locale(String(locale_id))
	locale_changed.emit(locale_id)
	return true


func reload_catalog() -> bool:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		_entries = {}
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_entries = {}
		return false
	var catalog := parsed as Dictionary
	if String(catalog.get("locale", "")) != String(DEFAULT_LOCALE):
		_entries = {}
		return false
	var raw_entries: Variant = catalog.get("entries", {})
	if not raw_entries is Dictionary:
		_entries = {}
		return false
	_entries = (raw_entries as Dictionary).duplicate(true)
	return true
