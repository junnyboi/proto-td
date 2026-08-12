extends GutTest

const CATALOG_PATH := "res://assets/music/catalog.tres"
const PROVENANCE_PATH := "res://assets/music/provenance.json"
const EXPECTED := {
	&"act_1_bgm": {"act": 1, "role": &"bgm"},
	&"act_1_boss": {"act": 1, "role": &"boss"},
	&"act_2_bgm": {"act": 2, "role": &"bgm"},
	&"act_2_boss": {"act": 2, "role": &"boss"},
	&"act_3_bgm": {"act": 3, "role": &"bgm"},
	&"act_3_boss": {"act": 3, "role": &"boss"},
}


func _catalog() -> MusicCatalog:
	return load(CATALOG_PATH) as MusicCatalog


func _json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _provenance_tracks() -> Dictionary:
	var document := _json_file(PROVENANCE_PATH)
	var by_id: Dictionary = {}
	var tracks: Array = document.get("tracks", [])
	for raw_track: Variant in tracks:
		if raw_track is Dictionary:
			var track: Dictionary = raw_track
			by_id[StringName(track.get("id", ""))] = track
	return by_id


func test_catalog_has_one_bgm_and_one_boss_cue_per_act() -> void:
	var catalog := _catalog()
	assert_not_null(catalog)
	if catalog == null:
		return
	assert_eq(catalog.entries.size(), 6)
	for id: StringName in EXPECTED:
		assert_true(catalog.entries.has(id), "catalog contains %s" % id)
		if not catalog.entries.has(id):
			continue
		var entry: Dictionary = catalog.entries[id]
		assert_eq(int(entry.get("act", 0)), int(EXPECTED[id]["act"]), "%s act" % id)
		assert_eq(entry.get("role"), EXPECTED[id]["role"], "%s role" % id)


func test_every_catalog_stream_loads_loops_and_matches_measured_duration() -> void:
	var catalog := _catalog()
	assert_not_null(catalog)
	if catalog == null:
		return
	for id: StringName in EXPECTED:
		var entry: Dictionary = catalog.entries[id]
		var stream := load(String(entry["path"])) as AudioStreamOggVorbis
		assert_not_null(stream, "%s stream loads" % id)
		if stream == null:
			continue
		assert_true(stream.loop, "%s importer enables looping" % id)
		assert_almost_eq(
			stream.get_length(),
			float(entry["duration_seconds"]),
			0.05,
			"%s duration matches ffprobe metadata" % id,
		)


func test_catalog_provenance_and_raw_hashes_are_exact() -> void:
	var catalog := _catalog()
	assert_not_null(catalog)
	if catalog == null:
		return
	var provenance := _provenance_tracks()
	assert_eq(provenance.size(), 6, "provenance has exactly six unique ids")
	var asset_hashes: Dictionary = {}
	var source_hashes: Dictionary = {}
	for id: StringName in EXPECTED:
		assert_true(provenance.has(id), "provenance contains %s" % id)
		if not provenance.has(id):
			continue
		var entry: Dictionary = catalog.entries[id]
		var track: Dictionary = provenance[id]
		assert_eq(int(track.get("act", 0)), int(entry.get("act", 0)), "%s act parity" % id)
		assert_eq(String(track.get("role", "")), String(entry.get("role", "")), "%s role" % id)
		assert_eq(String(track.get("title", "")), String(entry.get("title", "")), "%s title" % id)
		assert_eq(String(track.get("asset_path", "")), String(entry.get("path", "")), "%s path" % id)
		assert_eq(
			String(track.get("prompt_path", "")),
			String(entry.get("prompt_path", "")),
			"%s prompt path" % id,
		)
		assert_eq(
			String(track.get("source_path", "")),
			String(entry.get("source_path", "")),
			"%s source path" % id,
		)
		assert_eq(
			String(track.get("transcription_path", "")),
			String(entry.get("transcription_path", "")),
			"%s transcription path" % id,
		)
		assert_almost_eq(
			float(track.get("duration_seconds", 0.0)),
			float(entry.get("duration_seconds", 0.0)),
			0.0001,
			"%s duration parity" % id,
		)
		assert_true(bool(track.get("placeholder", false)), "%s provenance remains human-owned" % id)
		assert_true(bool(entry.get("placeholder", false)), "%s catalog remains human-owned" % id)
		assert_true(bool(entry.get("loop", false)), "%s is cataloged loopable" % id)
		assert_eq(float(entry.get("loop_crossfade_seconds", 0.0)), 4.0, "%s seam" % id)
		assert_eq(String(entry.get("generator_model", "")), "not exposed by tool")
		assert_eq(String(entry.get("generator_seed", "")), "not exposed by tool")

		var asset_path := String(track.get("asset_path", ""))
		var prompt_path := String(track.get("prompt_path", ""))
		var source_path := String(track.get("source_path", ""))
		var transcription_path := String(track.get("transcription_path", ""))
		for path: String in [asset_path, prompt_path, source_path, transcription_path]:
			assert_true(FileAccess.file_exists(path), "%s evidence exists: %s" % [id, path])

		var asset_hash := FileAccess.get_sha256(asset_path)
		var prompt_hash := FileAccess.get_sha256(prompt_path)
		var source_hash := FileAccess.get_sha256(source_path)
		var transcription_hash := FileAccess.get_sha256(transcription_path)
		assert_eq(asset_hash, String(track.get("asset_sha256", "")), "%s asset hash" % id)
		assert_eq(prompt_hash, String(track.get("prompt_sha256", "")), "%s prompt hash" % id)
		assert_eq(source_hash, String(track.get("source_sha256", "")), "%s source hash" % id)
		assert_eq(
			transcription_hash,
			String(track.get("transcription_sha256", "")),
			"%s transcription hash" % id,
		)
		assert_eq(asset_hash, String(entry.get("asset_sha256", "")), "%s catalog asset hash" % id)
		assert_eq(prompt_hash, String(entry.get("prompt_sha256", "")), "%s catalog prompt hash" % id)
		assert_eq(source_hash, String(entry.get("source_sha256", "")), "%s catalog source hash" % id)
		assert_eq(
			transcription_hash,
			String(entry.get("transcription_sha256", "")),
			"%s catalog transcription hash" % id,
		)
		assert_false(asset_hashes.has(asset_hash), "%s asset audio is unique" % id)
		assert_false(source_hashes.has(source_hash), "%s generated source is unique" % id)
		asset_hashes[asset_hash] = true
		source_hashes[source_hash] = true

		var prompt_file := FileAccess.open(prompt_path, FileAccess.READ)
		assert_not_null(prompt_file, "%s prompt file opens" % id)
		if prompt_file != null:
			assert_true(
				prompt_file.get_as_text().contains("Instrumental only, no vocals."),
				"%s prompt bans vocals" % id,
			)
		var transcription := _json_file(transcription_path)
		var segments: Array = transcription.get("segments", [])
		assert_eq(segments.size(), 0, "%s transcription has no segments" % id)
		assert_eq(String(transcription.get("full_text", "")), "", "%s transcription is empty" % id)
