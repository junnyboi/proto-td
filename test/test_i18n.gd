extends GutTest

const I18nScript := preload("res://autoloads/i18n.gd")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const TITLE_KEY := &"ui.game_title"
const TITLE_FALLBACK := "Protos"
const STAGE_IDS: Array[StringName] = [
	&"s1", &"s2", &"s3", &"s4", &"s5", &"s6", &"s7", &"s8",
	&"test_drone", &"test_lane", &"test_skill",
]
const OPERATOR_IDS: Array[StringName] = [
	&"caster_1", &"caster_2", &"defender_1", &"defender_2", &"guard_1",
	&"guard_2", &"sniper_1", &"sniper_2", &"vanguard_1", &"vanguard_2",
]
const TRAP_IDS: Array[StringName] = [&"spike_plate", &"tar_pit"]
const SPELL_IDS: Array[StringName] = [&"bolt", &"charm"]


func test_en_us_catalog_resolves_exact_product_title() -> void:
	var i18n := I18nScript.new()
	assert_true(i18n.reload_catalog())
	assert_eq(i18n.t(TITLE_KEY, TITLE_FALLBACK), TITLE_FALLBACK)
	assert_eq(i18n.supported_locales(), PackedStringArray(["en-US"]))
	assert_eq(i18n.locale(), &"en-US")
	i18n.free()


func test_missing_or_blank_key_returns_exact_english_fallback() -> void:
	var i18n := I18nScript.new()
	assert_true(i18n.reload_catalog())
	assert_eq(i18n.t(&"missing.key", "Fallback"), "Fallback")
	assert_eq(i18n.t(&"missing.blank", ""), "")
	i18n.free()


func test_unsupported_and_same_locale_preserve_state_without_signal() -> void:
	var i18n := I18nScript.new()
	assert_true(i18n.reload_catalog())
	watch_signals(i18n)
	assert_false(i18n.set_locale(&"fr-FR"))
	assert_eq(i18n.locale(), &"en-US")
	assert_signal_not_emitted(i18n, "locale_changed")
	assert_true(i18n.set_locale(&"en-US"))
	assert_signal_not_emitted(i18n, "locale_changed")
	i18n.free()


func test_catalog_has_exact_generated_key_value_set_and_order() -> void:
	var text := FileAccess.get_file_as_string("res://localization/en-US.json")
	var parsed := I18nScript.parse_catalog_text(text)
	assert_false(parsed.is_empty())
	var entries := parsed["entries"] as Dictionary
	var expected := _expected_catalog()
	var expected_keys: Array = expected.keys()
	expected_keys.sort()
	assert_eq(entries.keys(), expected_keys)
	assert_eq(entries.size(), 137)
	for key: Variant in expected_keys:
		assert_eq(entries[key], expected[key], "catalog value %s" % key)
	var i18n := I18nScript.new()
	assert_true(i18n.reload_catalog())
	assert_eq(i18n.catalog_keys(), PackedStringArray(expected_keys))
	i18n.free()


func test_duplicate_safe_parser_rejects_every_malformed_root_and_entry_shape() -> void:
	var malformed: Array[String] = [
		'{"locale":"en-US","locale":"en-US","entries":{}}',
		'{"locale":"en-US","entries":{"a":"A","a":"B"}}',
		'{"entries":{},"locale":"en-US"}',
		'{"locale":"fr-FR","entries":{}}',
		'{"locale":"en-US","entries":{},"extra":true}',
		'{"locale":"en-US","entries":{"a":""}}',
		'{"locale":"en-US","entries":{"a":null}}',
		'{"locale":"en-US","entries":[]}',
		'[]',
		'not-json',
	]
	for source: String in malformed:
		assert_eq(I18nScript.parse_catalog_text(source), {}, source)


func test_named_formatting_accepts_exact_types_and_rejects_every_shape_error() -> void:
	var i18n := I18nScript.new()
	assert_true(i18n.reload_catalog())
	assert_eq(
		i18n.format_text(
			&"ui.staging.next_detail", "NEXT: {index}. {title}",
			{&"index": 1, &"title": "First Stand"},
		),
		"NEXT: 1. First Stand",
	)
	var fallback := "{selected}/{limit} selected"
	assert_eq(
		i18n.format_text(
			&"ui.squad.selected_count", fallback,
			{&"selected": 2, &"limit": 3},
		),
		"2/3 selected",
	)
	assert_eq(
		i18n.format_text(
			&"ui.squad.selected_count", fallback, {&"selected": 2},
		),
		fallback,
	)
	assert_push_error("I18n.format_text:")
	assert_eq(
		i18n.format_text(
			&"ui.squad.selected_count", fallback,
			{&"selected": 2, &"limit": 3, &"extra": 4},
		),
		fallback,
	)
	assert_push_error("I18n.format_text:")
	assert_eq(
		i18n.format_text(
			&"ui.squad.selected_count", fallback,
			{&"selected": "2", &"limit": 3},
		),
		fallback,
	)
	assert_push_error("I18n.format_text:")
	assert_eq(i18n.format_text(&"missing.key", "{value}", {&"value": 3}), "{value}")
	assert_push_error("I18n.format_text:")
	i18n.free()


func test_ui_copy_dynamic_helpers_preserve_resource_fallbacks() -> void:
	for stage_id: StringName in STAGE_IDS:
		var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
		assert_eq(UiCopy.stage_title(stage), stage.title)
		assert_eq(UiCopy.stage_hint(stage), stage.intro_hint)
	for record: StageNarrativeDefType in NARRATIVE_CATALOG.records:
		for field: StageNarrativeDefType.Field in _narrative_fields():
			assert_eq(UiCopy.stage_narrative_text(record, field), record.fallback_for(field))
	for operator_id: StringName in OPERATOR_IDS:
		var definition := load(
			"res://data/operators/%s.tres" % operator_id,
		) as OperatorDef
		assert_eq(UiCopy.operator_name(definition), definition.display_name)
	for trap_id: StringName in TRAP_IDS:
		var trap := load("res://data/traps/%s.tres" % trap_id) as TrapDef
		assert_eq(UiCopy.trap_name(trap), trap.display_name)
	for spell_id: StringName in SPELL_IDS:
		var spell := load("res://data/spells/%s.tres" % spell_id) as SpellDef
		assert_eq(UiCopy.spell_name(spell), spell.display_name)


func test_every_catalog_fallback_and_formatted_codepoint_exists_in_active_font() -> void:
	var expected := _expected_catalog()
	var corpus := ""
	for value: Variant in expected.values():
		corpus += String(value)
	for value: Variant in UiCopy.static_fallbacks().values():
		corpus += String(value)
	corpus += "seed 42NEXT 8: The Gatecrasher\n3/3 selected"
	var checked: Dictionary = {}
	for index: int in corpus.length():
		var codepoint := corpus.unicode_at(index)
		if codepoint == 10 or checked.has(codepoint):
			continue
		checked[codepoint] = true
		assert_true(
			ThemeDB.fallback_font.has_char(codepoint),
			"fallback font lacks U+%04X" % codepoint,
		)
	assert_gt(checked.size(), 40)


func test_locale_sources_are_excluded_from_deterministic_model_surfaces() -> void:
	for root_path: String in ["res://sim", "res://playtests", "res://bots"]:
		for path: String in _gd_files(root_path):
			var source := FileAccess.get_file_as_string(path)
			assert_false(source.contains("I18n"), path)
			assert_false(source.contains("UiCopy"), path)
			assert_false(source.contains("locale"), path)
			assert_false(source.contains("translation"), path)


func test_project_and_title_source_use_canonical_identity_seam() -> void:
	var project_name := str(ProjectSettings.get_setting("application/config/name", ""))
	assert_eq(project_name, TITLE_FALLBACK)
	var source := FileAccess.get_file_as_string("res://scripts/ui/title.gd")
	assert_true(source.contains('UiCopyType.text(&"ui.game_title", "Protos")'))
	assert_false(source.contains('label.text = "Prototype TD"'))


func _expected_catalog() -> Dictionary:
	var expected: Dictionary = {}
	var static_fallbacks := UiCopy.static_fallbacks()
	for raw_key: Variant in static_fallbacks:
		expected[String(raw_key)] = static_fallbacks[raw_key]
	for stage_id: StringName in STAGE_IDS:
		var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
		expected["data.stage.%s.title" % stage_id] = stage.title
		expected["data.stage.%s.hint" % stage_id] = stage.intro_hint
	for record: StageNarrativeDefType in NARRATIVE_CATALOG.records:
		for field: StageNarrativeDefType.Field in _narrative_fields():
			expected["data.stage.%s.narrative.%s" % [record.id, record.field_slug(field)]] = record.fallback_for(field)
	for operator_id: StringName in OPERATOR_IDS:
		var definition := load(
			"res://data/operators/%s.tres" % operator_id,
		) as OperatorDef
		expected["data.operator.%s.name" % operator_id] = (
			definition.display_name
		)
	for trap_id: StringName in TRAP_IDS:
		var trap := load("res://data/traps/%s.tres" % trap_id) as TrapDef
		expected["data.trap.%s.name" % trap_id] = trap.display_name
	for spell_id: StringName in SPELL_IDS:
		var spell := load("res://data/spells/%s.tres" % spell_id) as SpellDef
		expected["data.spell.%s.name" % spell_id] = spell.display_name
	return expected


func _gd_files(root_path: String) -> Array[String]:
	var output: Array[String] = []
	var directory := DirAccess.open(root_path)
	if directory == null:
		return output
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if directory.current_is_dir():
			if not entry.begins_with("."):
				output.append_array(_gd_files("%s/%s" % [root_path, entry]))
		elif entry.ends_with(".gd"):
			output.append("%s/%s" % [root_path, entry])
		entry = directory.get_next()
	directory.list_dir_end()
	return output


func _narrative_fields() -> Array[StageNarrativeDefType.Field]:
	return [
		StageNarrativeDefType.Field.OBJECTIVE, StageNarrativeDefType.Field.THREAT,
		StageNarrativeDefType.Field.HUMAN_REASON, StageNarrativeDefType.Field.CLUE,
		StageNarrativeDefType.Field.CORE_SERVICE, StageNarrativeDefType.Field.CLEAR_DEBRIEF,
		StageNarrativeDefType.Field.DEFEAT_DEBRIEF,
	]
