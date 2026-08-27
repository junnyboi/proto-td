extends SceneTree

const SAVE_PATH := "user://campaign_v1.json"
const SAVE_PATHS := [
	SAVE_PATH,
	SAVE_PATH + ".bak",
	SAVE_PATH + ".tmp",
	SAVE_PATH + ".invalid",
	SAVE_PATH + ".bak.invalid",
	SAVE_PATH + ".tmp.invalid",
]
const PREFS_PATH := "user://title_start_recovery_test.cfg"

var _failures: Array[String] = []
var _preserved: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_preserve_files()
	_clear_files()
	_write_text(SAVE_PATH, "corrupt-campaign-slot")
	var title := load("res://scenes/title.tscn").instantiate() as Control
	title.call("set_preferences_path", PREFS_PATH)
	root.add_child(title)
	await process_frame
	await process_frame
	var start := title.find_child("StartButton", true, false) as Button
	_check(start != null and not start.disabled, "Title Start is not initially actionable")
	title.call("_on_start_pressed")
	var game := root.get_node("Game")
	for _frame: int in range(180):
		if game.get("content") != title:
			break
		await process_frame
	var content := game.get("content") as Node
	_check(content != null and content != title, "Title Start did not leave the title after corrupt-slot recovery")
	_check(
		content != null and String(content.get_script().resource_path) == "res://scripts/ui/staging.gd",
		"Title Start did not open Company Command after corrupt-slot recovery",
	)
	_check(FileAccess.file_exists(SAVE_PATH), "recovered campaign was not durably saved")
	_check(FileAccess.file_exists(SAVE_PATH + ".invalid"), "corrupt campaign bytes were not quarantined")
	_check(_read_text(SAVE_PATH + ".invalid") == "corrupt-campaign-slot", "quarantine did not preserve the rejected campaign bytes")
	_check(StringName(game.get("last_campaign_error")) == &"", "successful recovery left a campaign error")
	if content != null and is_instance_valid(content):
		content.queue_free()
	game.set("content", null)
	game.set("campaign", null)
	game.set("campaign_store", null)
	game.set("campaign_active", false)
	var music := root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
	for _frame: int in range(8):
		await process_frame
	_clear_files()
	_restore_files()
	if _failures.is_empty():
		print("TITLE_START_RECOVERY_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _preserve_files() -> void:
	for path: String in SAVE_PATHS + [PREFS_PATH]:
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file != null:
				_preserved[path] = file.get_buffer(file.get_length())
				file.close()


func _restore_files() -> void:
	for path: String in _preserved:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(_preserved[path] as PackedByteArray)
			file.close()


func _clear_files() -> void:
	for path: String in SAVE_PATHS + [PREFS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
