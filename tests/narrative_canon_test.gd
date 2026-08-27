extends SceneTree

const CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const NarrativeArchiveUnlocksType := preload("res://scripts/ui/components/narrative_archive_unlocks.gd")

const CANON_PATH := "res://docs/NARRATIVE_CANON.md"
const CONTRACT_PATH := "res://data/presentation/narrative/canon_contract.json"
const CONCEPT_PATHS := [
	"res://assets/narrative/anima-war/04-act-ii-anima-forge-capital.webp",
	"res://assets/narrative/anima-war/03-anima-robot-empire-castes.webp",
	"res://assets/narrative/anima-war/01-corrupted-protos-avatar.webp",
	"res://assets/narrative/anima-war/02-human-anima-farm.webp",
]
const DOCUMENT_CONCEPT_PATHS := [
	"res://docs/narrative/concept-art/anima-war/01-corrupted-protos-avatar.png",
	"res://docs/narrative/concept-art/anima-war/02-human-anima-farm.png",
	"res://docs/narrative/concept-art/anima-war/03-anima-robot-empire-castes.png",
	"res://docs/narrative/concept-art/anima-war/04-act-ii-anima-forge-capital.png",
	"res://docs/narrative/concept-art/anima-war/SHA256SUMS",
]
const OBSOLETE_ARCHIVE_PATHS := [
	"res://assets/narrative/mercy-equation",
	"res://assets/audio/narrative/mercy-archive",
	"res://docs/audio/MERCY_ARCHIVE_VOICEOVER.md",
]
const ARCHIVE_ENTRY_IDS: Array[StringName] = [&"stewardship", &"choir", &"equation", &"garden"]
const ARCHIVE_UNLOCK_GATES := [0, 3, 6, 7]
const ARCHIVE_TITLES := ["The Discovery", "The First Digital Birth", "PROTOS Breaks Free", "The Human Farms"]
const ARCHIVE_THEMES := ["real and unique soul", "voluntary gift became an industry", "more souls strengthened PROTOS", "Farms feed refineries"]
const ARCHIVE_AUDIO_LOCALES: Array[StringName] = [&"en-US", &"zh-CN"]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := CATALOG as StageNarrativeCatalogType
	_check(catalog != null, "stage narrative catalog failed to load")
	if catalog != null:
		var errors := catalog.validate_contract()
		_check(errors.is_empty(), "stage narrative catalog contract failed: %s" % "; ".join(errors))
		for stage_id: StringName in StageNarrativeCatalogType.EXPECTED_IDS:
			var record: StageNarrativeDefType = catalog.get_record(stage_id)
			_check(record != null, "missing narrative record %s" % stage_id)
			if record != null:
				_check(not record.transmission_speaker.is_empty(), "%s transmission speaker is blank" % stage_id)
				_check(not record.transmission.is_empty(), "%s transmission is blank" % stage_id)
				_check(not record.battle_start_speaker.is_empty(), "%s battle-start speaker is blank" % stage_id)
				_check(not record.battle_start.is_empty(), "%s battle-start dialogue is blank" % stage_id)
				_check(record.mid_wave_number >= 2, "%s mid-wave trigger is invalid" % stage_id)
				_check(not record.mid_wave_speaker.is_empty(), "%s mid-wave speaker is blank" % stage_id)
				_check(not record.mid_wave.is_empty(), "%s mid-wave dialogue is blank" % stage_id)

	_check(FileAccess.file_exists(CANON_PATH), "canon lore document is missing")
	var canon := FileAccess.get_file_as_string(CANON_PATH)
	var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
	_check(not contract.is_empty(), "machine-readable canon contract is invalid")
	var bible: Dictionary = contract.get("bible", {})
	_check(String(bible.get("path", "")) == "docs/NARRATIVE_CANON.md", "canon contract points at the wrong bible")
	_check(String(bible.get("sha256", "")) == _sha256(CANON_PATH), "canon bible hash drifted without a contract update")
	_check(int(contract.get("schema_version", 0)) == 4, "canon contract schema version drifted")
	for term: Variant in contract.get("required_canon_terms", []):
		_check(canon.contains(String(term)), "canon contract term is absent from bible: %s" % term)
	var required_display := contract.get("required_company_display", {}) as Dictionary
	_check(String(required_display.get("stable_key", "")) == "data.company.33.name", "Company Manus stable localization key changed")
	_check(String(required_display.get("en-US", "")) == "COMPANY MANUS", "English Company Manus display contract changed")
	_check(String(required_display.get("zh-CN", "")) == "MANUS连队", "Chinese Company Manus display contract changed")
	_check(not contract.has("phase6_temporary_waivers"), "Phase 6 canon waivers must be removed")
	var archive_gate_contract := contract.get("archive_unlock_gates", {}) as Dictionary
	for index: int in ARCHIVE_ENTRY_IDS.size():
		_check(
			int(archive_gate_contract.get(String(ARCHIVE_ENTRY_IDS[index]), -1)) == ARCHIVE_UNLOCK_GATES[index],
			"archive contract gate drifted: %s" % ARCHIVE_ENTRY_IDS[index],
		)
	var compatibility := contract.get("campaign_compatibility", {}) as Dictionary
	var runtime_context := CampaignRuntimeContext.build()
	_check(not runtime_context.is_empty(), "campaign compatibility context failed to build")
	if not runtime_context.is_empty():
		_check(
			String(runtime_context.get("environment_sha256", "")) == String(compatibility.get("environment_sha256", "")),
			"narrative migration changed the protected gameplay environment fingerprint",
		)
		_check(String(compatibility.get("save_schema", "")) == CampaignV3Codec.SAVE_SCHEMA, "campaign save schema drifted")
		_check(int(compatibility.get("save_version", 0)) == CampaignV3Codec.SAVE_VERSION, "campaign save version drifted")
		var created := CampaignStateV3.create(
			int(compatibility.get("fixture_seed", 0)),
			int(compatibility.get("fixture_generation", 0)),
			runtime_context,
		)
		_check(created.get("accepted", false), "deterministic campaign compatibility fixture failed to create")
		if created.get("accepted", false):
			var fixture: CampaignStateV3 = created["value"]
			var encoded := fixture.encode_save()
			_check(
				_sha256_text(String(encoded.get("text", ""))) == String(compatibility.get("fresh_save_text_sha256", "")),
				"fresh Campaign V3 save bytes changed during narrative migration",
			)
			_check(
				String(fixture.strategic_hash().get("hex", "")) == String(compatibility.get("fresh_strategic_hash", "")),
				"fresh campaign strategic hash changed during narrative migration",
			)
			_check(
				String(fixture.core_hash().get("hex", "")) == String(compatibility.get("fresh_core_hash", "")),
				"fresh campaign core hash changed during narrative migration",
			)
			var restored := CampaignStateV3.restore_source(String(encoded.get("text", "")), runtime_context)
			_check(restored.get("accepted", false), "fresh Campaign V3 fixture no longer round-trips")
			if restored.get("accepted", false):
				var projection: Dictionary = restored["value"].runtime_projection()
				_check(projection.get("stage_ids", []).size() == 16, "round-tripped campaign lost stage order")
				_check(projection.get("ready_heroes", []).size() == 5, "round-tripped campaign lost starter roster")
				_check(int(projection.get("marks", -1)) == 120, "round-tripped campaign changed Marks")
				_check((projection.get("stage_stars", {}) as Dictionary).is_empty(), "round-tripped campaign invented clears")
	var archive_source := FileAccess.get_file_as_string("res://scripts/ui/narrative_archive.gd")
	_check(archive_source.count('{&"id":') == 4, "archive must contain exactly four stable records")
	_check(not archive_source.contains("mercy-equation") and not archive_source.contains("MercyArchive"), "archive production source retains obsolete art paths or node labels")
	var audio_source := FileAccess.get_file_as_string("res://scripts/ui/components/archive_audio_log_player.gd")
	_check(not audio_source.contains("mercy-archive"), "audio production source retains obsolete narration paths")
	var runtime_art_files: PackedStringArray = DirAccess.get_files_at("res://assets/narrative/anima-war")
	var runtime_webp_count := 0
	for runtime_art_file: String in runtime_art_files:
		if runtime_art_file.ends_with(".webp"):
			runtime_webp_count += 1
	_check(runtime_webp_count == 4, "runtime archive art directory must contain exactly four WebP assets")
	for index: int in ARCHIVE_ENTRY_IDS.size():
		var expected_entry := '{&"id": &"%s", &"unlock_stage": %d' % [ARCHIVE_ENTRY_IDS[index], ARCHIVE_UNLOCK_GATES[index]]
		_check(archive_source.contains(expected_entry), "archive stable ID or gate drifted: %s/%d" % [ARCHIVE_ENTRY_IDS[index], ARCHIVE_UNLOCK_GATES[index]])
	var english_catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://localization/en-US.json"))
	var english_entries := english_catalog.get("entries", {}) as Dictionary
	for index: int in ARCHIVE_ENTRY_IDS.size():
		var prefix := "ui.archive.entry.%s." % ARCHIVE_ENTRY_IDS[index]
		_check(String(english_entries.get(prefix + "title", "")) == ARCHIVE_TITLES[index], "archive visible title drifted: %s" % ARCHIVE_ENTRY_IDS[index])
		var themed_text := String(english_entries.get(prefix + "body", "")) + " " + String(english_entries.get(prefix + "quote", ""))
		_check(themed_text.contains(ARCHIVE_THEMES[index]), "archive required theme drifted: %s" % ARCHIVE_ENTRY_IDS[index])
	for path: String in CONCEPT_PATHS:
		_check(ResourceLoader.exists(path), "GPT Image 2 concept is not importable: %s" % path)
		var texture := load(path) as Texture2D
		_check(texture != null and maxi(texture.get_width(), texture.get_height()) == 1600, "concept asset is incomplete: %s" % path)
	for path: String in DOCUMENT_CONCEPT_PATHS:
		_check(FileAccess.file_exists(path), "durable docs concept is missing: %s" % path)
	for locale_id: StringName in ARCHIVE_AUDIO_LOCALES:
		var locale_files: PackedStringArray = DirAccess.get_files_at("res://assets/audio/narrative/anima-archive/%s" % locale_id)
		var locale_ogg_count := 0
		for locale_file: String in locale_files:
			if locale_file.ends_with(".ogg"):
				locale_ogg_count += 1
		_check(locale_ogg_count == 4, "%s must contain exactly four archive Ogg streams" % locale_id)
		for entry_id: StringName in ARCHIVE_ENTRY_IDS:
			var audio_path := "res://assets/audio/narrative/anima-archive/%s/%s.ogg" % [locale_id, entry_id]
			_check(ResourceLoader.exists(audio_path), "archive narration is not importable: %s" % audio_path)
			var stream := load(audio_path) as AudioStream
			_check(stream != null and stream.get_length() > 30.0, "archive narration is incomplete: %s" % audio_path)

	_check(NarrativeArchiveUnlocksType.record_unlocked(0, {}), "The Discovery should unlock at campaign start")
	_check(not NarrativeArchiveUnlocksType.record_unlocked(3, {&"s2": 3}), "The First Digital Birth unlocked before S3 clear")
	_check(NarrativeArchiveUnlocksType.record_unlocked(3, {&"s3": 1}), "The First Digital Birth did not unlock on S3 clear")
	_check(not NarrativeArchiveUnlocksType.record_unlocked(6, {&"s5": 3}), "PROTOS Breaks Free unlocked before S6 clear")
	_check(NarrativeArchiveUnlocksType.record_unlocked(6, {&"s6": 1}), "PROTOS Breaks Free did not unlock on S6 clear")
	_check(not NarrativeArchiveUnlocksType.record_unlocked(7, {&"s6": 3}), "The Human Farms unlocked before S7 clear")
	_check(NarrativeArchiveUnlocksType.record_unlocked(7, {&"s7": 1}), "The Human Farms did not unlock on S7 clear")
	for obsolete_path: String in OBSOLETE_ARCHIVE_PATHS:
		_check(not FileAccess.file_exists(obsolete_path) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(obsolete_path)), "obsolete archive runtime path remains: %s" % obsolete_path)

	var i18n := root.get_node_or_null("I18n")
	_check(i18n != null, "I18n autoload missing")
	if i18n != null:
		for locale_id: StringName in [&"en-US", &"zh-CN"]:
			_check(bool(i18n.call("set_locale", locale_id)), "locale activation failed: %s" % locale_id)
			for stage_index: int in range(1, 17):
				for slug: String in [
					"objective", "clear_debrief", "transmission_speaker", "transmission",
					"battle_start_speaker", "battle_start", "mid_wave_speaker", "mid_wave",
				]:
					var key := StringName("data.stage.s%d.narrative.%s" % [stage_index, slug])
					var value := String(i18n.call("t", key, ""))
					_check(not value.is_empty(), "%s missing localized canon key %s" % [locale_id, key])
		i18n.call("set_locale", &"en-US")

	var game := root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game != null:
		game.call("set_run_seed", 3301)
		_check(bool(game.call("start_campaign", false, true)), "archive campaign fixture failed")
		var archive := load("res://scenes/narrative_archive.tscn").instantiate() as Control
		root.add_child(archive)
		await process_frame
		await process_frame
		var record_one := archive.find_child("ArchiveRecord_01", true, false) as Button
		var record_two := archive.find_child("ArchiveRecord_02", true, false) as Button
		var art := archive.find_child("ArchiveConceptArt", true, false) as TextureRect
		var detail_scroll := archive.find_child("ArchiveDetailScroll", true, false) as ScrollContainer
		var audio_log := archive.find_child("ArchiveAudioLog", true, false) as Control
		var audio_play := archive.find_child("AudioLogPlayPause", true, false) as Button
		_check(String(archive.accessibility_name) == "Anima Archive", "archive visible accessibility name is not Anima Archive")
		_check(record_one != null and not record_one.disabled, "foundation archive UI is not available")
		_check(record_two != null and record_two.disabled, "second archive UI is not progression gated")
		_check(art != null and art.texture != null, "archive UI omitted its approved concept art")
		_check(art != null and art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "archive concept art must preserve aspect without cropping")
		_check(detail_scroll != null and detail_scroll.follow_focus, "archive detail does not follow keyboard focus to narration")
		_check(audio_log != null and audio_play != null and not audio_play.disabled, "archive UI omitted interactive narration")
		_dispose(archive)
		game.set("content", null)
		game.set("campaign_active", false)
		game.set("campaign", null)
		game.set("campaign_store", null)

	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	await create_timer(0.25).timeout
	_finish()


func _dispose(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()


func _sha256(path: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(FileAccess.get_file_as_bytes(path))
	return context.finish().hex_encode()


func _sha256_text(value: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value.to_utf8_buffer())
	return context.finish().hex_encode()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("NARRATIVE_CANON_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
