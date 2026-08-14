extends GutTest

const SfxScript := preload("res://autoloads/sfx.gd")
const SkillReadyFeedbackScript := preload("res://scripts/view/skill_ready_feedback.gd")
const SFX_SCRIPT_PATH := "res://autoloads/sfx.gd"
const SFX_CATALOG_SCRIPT_PATH := "res://assets/sfx/sfx_catalog.gd"
const DEPLOY_BAR_SCRIPT_PATH := "res://scripts/ui/deploy_bar.gd"
const CATALOG_PATH := "res://assets/sfx/catalog.tres"
const PROMPTS_PATH := "res://assets/sfx/prompts/batch-01-prompts.json"
const ACCEPTANCE_PATH := "res://assets/sfx/human-acceptance.json"
const EXPECTED_IDS: Array[StringName] = [
	&"operator_select",
	&"ability_ready",
	&"action_reject",
	&"ui_click",
	&"placement_ready",
	&"base_breach",
	&"victory",
	&"defeat",
	&"deploy",
	&"trap_trigger",
]

var sfx: Node = null


func before_each() -> void:
	sfx = SfxScript.new()
	sfx.name = "TestSfx"
	add_child_autoqfree(sfx)
	assert_true(sfx.call("reload_catalog"))


func test_autoload_pins_catalog_as_an_explicit_resource_dependency() -> void:
	var source := FileAccess.get_file_as_string(SFX_SCRIPT_PATH)
	assert_false(source.is_empty(), SFX_SCRIPT_PATH)
	assert_true(
		source.contains('preload("%s")' % SFX_CATALOG_SCRIPT_PATH),
		"Sfx must parse when the SfxCatalog cache entry is absent",
	)
	assert_false(
		source.contains("SfxCatalog"),
		"Sfx autoload cannot type or cast through the cache-backed global class name",
	)


func test_catalog_resolves_ten_accepted_48khz_stereo_pcm_assets() -> void:
	var catalog := load(CATALOG_PATH) as Resource
	assert_not_null(catalog)
	var entries: Dictionary = catalog.get("entries")
	assert_eq(entries.size(), 10)
	var prompts: Dictionary = _json_object(PROMPTS_PATH)
	var acceptance: Dictionary = _json_object(ACCEPTANCE_PATH)
	assert_eq(String(acceptance.get("verdict", "")), "ACCEPT")
	assert_true(bool(acceptance.get("integration_authorized", false)))
	var accepted_assets: Dictionary = acceptance.get("assets", {})
	for cue_id: StringName in EXPECTED_IDS:
		assert_true(entries.has(cue_id), String(cue_id))
		var entry: Dictionary = entries[cue_id]
		var path := String(entry.get("path", ""))
		var source_path := "res://assets/sfx/sources/%s.wav.source" % cue_id
		assert_true(FileAccess.file_exists(path), path)
		assert_true(FileAccess.file_exists(source_path), source_path)
		assert_eq(FileAccess.get_sha256(path), String(entry.get("runtime_sha256", "")), path)
		assert_eq(
			FileAccess.get_sha256(source_path),
			String(entry.get("accepted_source_sha256", "")),
			source_path,
		)
		assert_eq(
			FileAccess.get_sha256(source_path),
			String(accepted_assets.get(String(cue_id), "")),
		)
		assert_false(bool(entry.get("placeholder", true)), String(cue_id))
		var stream := load(path) as AudioStreamWAV
		assert_not_null(stream, path)
		if stream != null:
			assert_eq(int(stream.get("mix_rate")), 48000, path)
			assert_true(bool(stream.get("stereo")), path)
			assert_eq(int(stream.get("format")), int(AudioStreamWAV.FORMAT_16_BITS), path)
		var prompt := _prompt_for(prompts, cue_id)
		assert_false(prompt.is_empty(), String(cue_id))
		assert_eq(prompt.sha256_text(), String(entry.get("prompt_sha256", "")))


func test_controller_owns_eight_bounded_voices_and_starts_all_direct_cues() -> void:
	assert_eq(int(sfx.call("catalog_entry_count")), 10)
	assert_eq(int(sfx.call("player_count")), 8)
	var starts_before := int(sfx.call("audible_start_count"))
	for cue_id: StringName in EXPECTED_IDS:
		assert_true(bool(sfx.call("play", String(cue_id))), String(cue_id))
	assert_eq(int(sfx.call("audible_start_count")), starts_before + EXPECTED_IDS.size())
	assert_eq(int(sfx.call("player_count")), 8)
	assert_eq(int(sfx.call("assigned_voice_count")), 8)
	assert_eq(sfx.call("last_resolved_id"), &"trap_trigger")
	assert_true(String(sfx.call("last_stream_path")).ends_with("trap_trigger.wav"))


func test_alias_and_direct_id_dedupe_only_audio_in_same_render_frame() -> void:
	var events_before := _telemetry_events().size()
	var starts_before := int(sfx.call("audible_start_count"))
	var dedupes_before := int(sfx.call("dedupe_count"))
	assert_true(bool(sfx.call("play", "leak")))
	assert_false(bool(sfx.call("play", "base_breach")))
	assert_eq(sfx.call("last_raw_id"), &"leak")
	assert_eq(sfx.call("last_resolved_id"), &"base_breach")
	assert_eq(int(sfx.call("audible_start_count")), starts_before + 1)
	assert_eq(int(sfx.call("dedupe_count")), dedupes_before + 1)
	var new_events := _telemetry_events().slice(events_before)
	assert_eq(new_events.size(), 2)
	assert_eq(String(new_events[0]["data"]["id"]), "leak")
	assert_eq(String(new_events[1]["data"]["id"]), "base_breach")


func test_unknown_id_emits_raw_telemetry_with_zero_playback_state_change() -> void:
	assert_true(bool(sfx.call("play", "deploy")))
	var before := [
		sfx.call("audible_start_count"),
		sfx.call("dedupe_count"),
		sfx.call("assigned_voice_count"),
		sfx.call("last_raw_id"),
		sfx.call("last_resolved_id"),
		sfx.call("last_stream_path"),
	]
	var events_before := _telemetry_events().size()
	assert_false(bool(sfx.call("play", "missing")))
	var after := [
		sfx.call("audible_start_count"),
		sfx.call("dedupe_count"),
		sfx.call("assigned_voice_count"),
		sfx.call("last_raw_id"),
		sfx.call("last_resolved_id"),
		sfx.call("last_stream_path"),
	]
	assert_eq(after, before)
	var new_events := _telemetry_events().slice(events_before)
	assert_eq(new_events.size(), 1)
	assert_eq(String(new_events[0]["data"]["id"]), "missing")


func test_closed_alias_map_preserves_existing_combat_ids() -> void:
	assert_eq(sfx.call("resolved_id_for", &"leak"), &"base_breach")
	assert_eq(sfx.call("resolved_id_for", &"trap_snap"), &"trap_trigger")
	assert_eq(sfx.call("resolved_id_for", &"victory"), &"victory")
	assert_eq(sfx.call("resolved_id_for", &"defeat"), &"defeat")
	assert_eq(sfx.call("resolved_id_for", &"deploy"), &"deploy")
	assert_eq(sfx.call("resolved_id_for", &"kill"), &"")
	assert_eq(sfx.call("resolved_id_for", &"wave"), &"")


func test_deploy_bar_wires_specialized_ui_cues_to_existing_edges() -> void:
	var source := FileAccess.get_file_as_string(DEPLOY_BAR_SCRIPT_PATH)
	assert_true(source.contains('Sfx.play("operator_select")'))
	assert_true(source.contains('Sfx.play("placement_ready")'))
	assert_eq(source.count('Sfx.play("action_reject")'), 3)


func test_ability_ready_plays_only_on_false_to_true_edges() -> void:
	var feedback := SkillReadyFeedbackScript.new()
	var body := _sp_bar_body()
	var unit := UnitState.new()
	unit.id = 32032
	unit.sp_cost = 10
	unit.sp = 9
	await get_tree().process_frame
	var starts_before := int(Sfx.call("audible_start_count"))
	feedback.update(body, unit, Color.ORANGE, Color.WHITE)
	assert_eq(int(Sfx.call("audible_start_count")), starts_before)
	unit.sp = 10
	feedback.update(body, unit, Color.ORANGE, Color.WHITE)
	assert_eq(int(Sfx.call("audible_start_count")), starts_before + 1)
	await get_tree().process_frame
	feedback.update(body, unit, Color.ORANGE, Color.WHITE)
	assert_eq(int(Sfx.call("audible_start_count")), starts_before + 1)
	unit.sp = 0
	feedback.update(body, unit, Color.ORANGE, Color.WHITE)
	unit.sp = 10
	await get_tree().process_frame
	feedback.update(body, unit, Color.ORANGE, Color.WHITE)
	assert_eq(int(Sfx.call("audible_start_count")), starts_before + 2)
	body.free()


func test_stop_all_is_idempotent_and_keeps_the_voice_pool() -> void:
	assert_true(bool(sfx.call("play", "victory")))
	assert_true(bool(sfx.call("stop_all")))
	assert_false(bool(sfx.call("stop_all")))
	assert_eq(int(sfx.call("assigned_voice_count")), 0)
	assert_eq(int(sfx.call("player_count")), 8)


func _telemetry_events() -> Array:
	return Telemetry.get("_events") as Array


func _sp_bar_body() -> ColorRect:
	var body := ColorRect.new()
	body.size = Vector2(64.0, 64.0)
	var background := ColorRect.new()
	background.name = "SpBarBg"
	body.add_child(background)
	var fill := ColorRect.new()
	fill.name = "SpBarFill"
	background.add_child(fill)
	return body


func _json_object(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(value is Dictionary, path)
	return value if value is Dictionary else {}


func _prompt_for(document: Dictionary, cue_id: StringName) -> String:
	var cues: Variant = document.get("cues", [])
	if not cues is Array:
		return ""
	for raw_cue: Variant in cues:
		if raw_cue is Dictionary and String(raw_cue.get("id", "")) == String(cue_id):
			return String(raw_cue.get("prompt", ""))
	return ""
