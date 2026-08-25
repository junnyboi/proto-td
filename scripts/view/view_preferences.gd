class_name ViewPreferences
extends RefCounted

## Durable presentation-only preferences. These never enter campaign state,
## tickets, replays, or simulation hashes.

const DEFAULT_PATH := "user://view_preferences.cfg"
const NAVIGATION_SECTION := "navigation"
const PAN_HINT_KEY := "pan_hint_completed"
const AUDIO_SECTION := "audio"
const TITLE_MUSIC_ENABLED_KEY := "title_music_enabled"
const MASTER_VOLUME_KEY := "master_volume"
const MUSIC_VOLUME_KEY := "music_volume"
const SFX_VOLUME_KEY := "sfx_volume"
const GRAPHICS_SECTION := "graphics"
const REDUCED_MOTION_KEY := "reduced_motion"
const FRAME_LIMIT_KEY := "frame_limit"
const VALID_FRAME_LIMITS := [0, 30, 60, 120]


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


static func master_volume(path: String = DEFAULT_PATH) -> float:
	return _volume_value(MASTER_VOLUME_KEY, path)


static func set_master_volume(value: float, path: String = DEFAULT_PATH) -> bool:
	return _set_value(AUDIO_SECTION, MASTER_VOLUME_KEY, clampf(value, 0.0, 1.0), path)


static func music_volume(path: String = DEFAULT_PATH) -> float:
	return _volume_value(MUSIC_VOLUME_KEY, path)


static func set_music_volume(value: float, path: String = DEFAULT_PATH) -> bool:
	return _set_value(AUDIO_SECTION, MUSIC_VOLUME_KEY, clampf(value, 0.0, 1.0), path)


static func sfx_volume(path: String = DEFAULT_PATH) -> float:
	return _volume_value(SFX_VOLUME_KEY, path)


static func set_sfx_volume(value: float, path: String = DEFAULT_PATH) -> bool:
	return _set_value(AUDIO_SECTION, SFX_VOLUME_KEY, clampf(value, 0.0, 1.0), path)


static func reduced_motion(path: String = DEFAULT_PATH) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return false
	return bool(config.get_value(GRAPHICS_SECTION, REDUCED_MOTION_KEY, false))


static func set_reduced_motion(enabled: bool, path: String = DEFAULT_PATH) -> bool:
	return _set_value(GRAPHICS_SECTION, REDUCED_MOTION_KEY, enabled, path)


static func frame_limit(path: String = DEFAULT_PATH) -> int:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return 0
	var value := int(config.get_value(GRAPHICS_SECTION, FRAME_LIMIT_KEY, 0))
	return value if value in VALID_FRAME_LIMITS else 0


static func set_frame_limit(value: int, path: String = DEFAULT_PATH) -> bool:
	var sanitized := value if value in VALID_FRAME_LIMITS else 0
	return _set_value(GRAPHICS_SECTION, FRAME_LIMIT_KEY, sanitized, path)


static func _volume_value(key: String, path: String) -> float:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return 1.0
	return clampf(float(config.get_value(AUDIO_SECTION, key, 1.0)), 0.0, 1.0)


static func _set_value(section: String, key: String, value: Variant, path: String) -> bool:
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		config = ConfigFile.new()
	config.set_value(section, key, value)
	return config.save(path) == OK
