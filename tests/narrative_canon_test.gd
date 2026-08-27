extends SceneTree

const CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const NarrativeArchiveUnlocksType := preload("res://scripts/ui/components/narrative_archive_unlocks.gd")

const CANON_PATH := "res://docs/NARRATIVE_CANON.md"
const CONTRACT_PATH := "res://data/presentation/narrative/canon_contract.json"
const CONCEPT_PATHS := [
	"res://assets/narrative/mercy-equation/protos-ai-avatar.jpg",
	"res://assets/narrative/mercy-equation/custodian-machine-castes.jpg",
	"res://assets/narrative/mercy-equation/mercy-equation-key-art.jpg",
	"res://assets/narrative/mercy-equation/the-first-garden.jpg",
]
const DOCUMENT_CONCEPT_PATHS := [
	"res://docs/narrative/concept-art/protos-ai-avatar.jpg",
	"res://docs/narrative/concept-art/custodian-machine-castes.jpg",
	"res://docs/narrative/concept-art/mercy-equation-key-art.jpg",
	"res://docs/narrative/concept-art/the-first-garden.jpg",
	"res://docs/narrative/concept-art/act2/act2-first-garden-expedition.jpg",
	"res://docs/narrative/concept-art/act2/restoration-lattice-battlefield.jpg",
	"res://docs/narrative/concept-art/act2/mortal-covenant-conclave.jpg",
	"res://docs/narrative/concept-art/act2/act2-eight-operation-montage.jpg",
]
const REQUIRED_TERMS := [
	"PROTOS", "Mercy Equation", "Continuance", "Quieting", "First Garden",
	"Restoration Lattice", "Mortal Covenant Threshold",
]
const ARCHIVE_ENTRY_IDS: Array[StringName] = [&"stewardship", &"choir", &"equation", &"garden"]
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
	for term: String in REQUIRED_TERMS:
		_check(canon.contains(term), "canon lore omits required term %s" % term)
	for term: Variant in contract.get("required_terms", []):
		_check(canon.contains(String(term)), "canon contract term is absent from bible: %s" % term)
	var active_english := FileAccess.get_file_as_string("res://localization/en-US.json")
	for term: Variant in contract.get("retired_terms", []):
		_check(not active_english.contains(String(term)), "retired lore remains in active English copy: %s" % term)
	for path: String in CONCEPT_PATHS:
		_check(ResourceLoader.exists(path), "GPT Image 2 concept is not importable: %s" % path)
		var texture := load(path) as Texture2D
		_check(texture != null and texture.get_width() >= 1400 and texture.get_height() >= 1000, "concept asset is incomplete: %s" % path)
	for path: String in DOCUMENT_CONCEPT_PATHS:
		_check(FileAccess.file_exists(path), "durable docs concept is missing: %s" % path)
	for locale_id: StringName in ARCHIVE_AUDIO_LOCALES:
		for entry_id: StringName in ARCHIVE_ENTRY_IDS:
			var audio_path := "res://assets/audio/narrative/mercy-archive/%s/%s.ogg" % [locale_id, entry_id]
			_check(ResourceLoader.exists(audio_path), "archive narration is not importable: %s" % audio_path)
			var stream := load(audio_path) as AudioStream
			_check(stream != null and stream.get_length() >= 30.0, "archive narration is incomplete: %s" % audio_path)

	_check(NarrativeArchiveUnlocksType.record_unlocked(0, {}), "foundation archive should unlock at campaign start")
	_check(not NarrativeArchiveUnlocksType.record_unlocked(2, {&"s1": 3}), "Choir archive unlocked before S2 clear")
	_check(NarrativeArchiveUnlocksType.record_unlocked(2, {&"s2": 1}), "Choir archive did not unlock on S2 clear")
	_check(not NarrativeArchiveUnlocksType.record_unlocked(7, {&"s5": 3}), "First Garden archive unlocked before S7 clear")
	_check(NarrativeArchiveUnlocksType.record_unlocked(7, {&"s7": 1}), "First Garden archive did not unlock on S7 clear")

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
		_check(record_one != null and not record_one.disabled, "foundation archive UI is not available")
		_check(record_two != null and record_two.disabled, "S2 archive UI is not progression gated")
		_check(art != null and art.texture != null, "archive UI omitted its approved concept art")
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
