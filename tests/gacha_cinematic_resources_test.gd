extends SceneTree

const PlayerType := preload("res://scripts/ui/components/gacha_cinematic_player.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected_ids := ["lunaris_vessel", "reliquary_duelist", "archive_caster"]
	_check(PlayerType.PROFILES.size() == expected_ids.size(), "cinematic profile count is incorrect")
	for premium_id: String in expected_ids:
		var profile: Dictionary = PlayerType.PROFILES.get(premium_id, {})
		_check(not profile.is_empty(), "missing cinematic profile %s" % premium_id)
		for orientation: String in ["landscape", "portrait"]:
			var video_path := String(profile.get("%s_video" % orientation, ""))
			var final_path := String(profile.get("%s_final" % orientation, ""))
			_check(ResourceLoader.exists(video_path), "missing cinematic stream %s" % video_path)
			_check(ResourceLoader.exists(final_path), "missing final identity plate %s" % final_path)
		var music_id := StringName(profile.get("music_id", &""))
		_check(not music_id.is_empty(), "missing cinematic music id %s" % premium_id)
		var audio_path := "res://assets/cinematics/gacha/audio/%s-cinematic.ogg" % premium_id.replace("_", "-")
		_check(ResourceLoader.exists(audio_path), "missing cinematic mix %s" % audio_path)
	await process_frame
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("GACHA_CINEMATIC_RESOURCES_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
