extends GutTest

const CATALOG_PATH := "res://assets/music/catalog.tres"
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


func test_every_entry_has_prompt_and_provenance_pending_human_acceptance() -> void:
	var catalog := _catalog()
	assert_not_null(catalog)
	if catalog == null:
		return
	var asset_hashes: Dictionary = {}
	for id: StringName in EXPECTED:
		var entry: Dictionary = catalog.entries[id]
		assert_true(bool(entry.get("placeholder", false)), "%s remains human-owned" % id)
		assert_true(bool(entry.get("loop", false)), "%s is cataloged loopable" % id)
		assert_eq(float(entry.get("loop_crossfade_seconds", 0.0)), 4.0, "%s seam" % id)
		assert_eq(String(entry.get("generator_model", "")), "not exposed by tool")
		assert_eq(String(entry.get("generator_seed", "")), "not exposed by tool")
		var source_hash := String(entry.get("source_sha256", ""))
		var prompt_hash := String(entry.get("prompt_sha256", ""))
		var asset_hash := String(entry.get("asset_sha256", ""))
		assert_eq(source_hash.length(), 64, "%s source hash" % id)
		assert_eq(prompt_hash.length(), 64, "%s prompt hash" % id)
		assert_eq(asset_hash.length(), 64, "%s asset hash" % id)
		assert_false(asset_hashes.has(asset_hash), "%s audio content is unique" % id)
		asset_hashes[asset_hash] = true
		var prompt_path := String(entry.get("prompt_path", ""))
		assert_true(FileAccess.file_exists(prompt_path), "%s prompt file exists" % id)
		if not FileAccess.file_exists(prompt_path):
			continue
		var prompt_file := FileAccess.open(prompt_path, FileAccess.READ)
		assert_not_null(prompt_file, "%s prompt file opens" % id)
		if prompt_file != null:
			assert_true(
				prompt_file.get_as_text().contains("Instrumental only, no vocals."),
				"%s prompt bans vocals" % id,
			)
