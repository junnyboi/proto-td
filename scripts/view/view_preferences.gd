class_name ViewPreferences
extends RefCounted

## Durable presentation-only preferences. These never enter campaign state,
## tickets, replays, or simulation hashes.

const DEFAULT_PATH := "user://view_preferences.cfg"
const NAVIGATION_SECTION := "navigation"
const PAN_HINT_KEY := "pan_hint_completed"
const AUDIO_SECTION := "audio"
const TITLE_MUSIC_ENABLED_KEY := "title_music_enabled"


static func has_seen_pan_hint(path: String = DEFAULT_PATH) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return false
	return bool(config.get_value(NAVIGATION_SECTION, PAN_HINT_KEY, false))


static func mark_pan_hint_seen(path: String = DEFAULT_PATH) -> bool:
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		config = ConfigFile.new()
	config.set_value(NAVIGATION_SECTION, PAN_HINT_KEY, true)
	return config.save(path) == OK


static func title_music_enabled(path: String = DEFAULT_PATH) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return true
	return bool(config.get_value(AUDIO_SECTION, TITLE_MUSIC_ENABLED_KEY, true))


static func set_title_music_enabled(enabled: bool, path: String = DEFAULT_PATH) -> bool:
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		config = ConfigFile.new()
	config.set_value(AUDIO_SECTION, TITLE_MUSIC_ENABLED_KEY, enabled)
	return config.save(path) == OK
