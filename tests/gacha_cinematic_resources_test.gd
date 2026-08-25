extends SceneTree

const PlayerType := preload("res://scripts/ui/components/gacha_cinematic_player.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected_ids := ["lunaris_vessel", "reliquary_duelist", "archive_caster"]
	_check(PlayerType.PROFILES.size() == expected_ids.size(), "cinematic profile count is incorrect")
	_check(PlayerType.STREAMS.size() == expected_ids.size() * 2, "stream manifest count is incorrect")
	for premium_id: String in expected_ids:
		var profile: Dictionary = PlayerType.PROFILES.get(premium_id, {})
		_check(not profile.is_empty(), "missing cinematic profile %s" % premium_id)
		for orientation: String in ["landscape", "portrait"]:
			var stream_key := String(profile.get("%s_stream" % orientation, ""))
			var final_path := String(profile.get("%s_final" % orientation, ""))
			var stream_spec: Dictionary = PlayerType.STREAMS.get(stream_key, {})
			var bundled_path := String(stream_spec.get("bundled_path", ""))
			_check(not stream_key.is_empty(), "missing %s stream key for %s" % [orientation, premium_id])
			_check(not stream_spec.is_empty(), "missing stream spec %s" % stream_key)
			_check(int(stream_spec.get("bytes", 0)) > 0, "missing byte size %s" % stream_key)
			_check(String(stream_spec.get("sha256", "")).length() == 64, "invalid SHA-256 %s" % stream_key)
			_check(ResourceLoader.exists(bundled_path), "missing native cinematic fallback %s" % bundled_path)
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
