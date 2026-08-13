extends GutTest

const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const CONTRACT_PATH := "res://data/presentation/narrative/canon_contract.json"


func test_contract_pins_exact_bible_authority_and_term_sets() -> void:
	var contract := _contract()
	assert_eq(contract["bible"]["version"], "3.3")
	assert_eq(contract["bible"]["sha256"], "da442ced518da9d4690e2dcb381120bb17aaf9d822ffc71b016ff74762e3e2aa")
	assert_eq((contract["required_terms"] as Array).size(), 7)
	assert_eq((contract["retired_terms"] as Array).size(), 7)
	assert_eq((contract["forbidden_charm_descriptions"] as Array).size(), 5)


func test_required_and_retired_terms_on_exact_active_copy_surfaces() -> void:
	var contract := _contract()
	var source_copy := _source_copy()
	var locale_copy := _locale_copy()
	for term: String in contract["required_terms"]:
		assert_true(_contains_term(source_copy, term), "source required %s" % term)
		assert_true(_contains_term(locale_copy, term), "locale required %s" % term)
	for term: String in contract["retired_terms"]:
		assert_false(_contains_term(source_copy, term), "source retired %s" % term)
		assert_false(_contains_term(locale_copy, term), "locale retired %s" % term)
	for term: String in contract["forbidden_charm_descriptions"]:
		assert_false(_contains_forbidden_description(source_copy, term), "source forbidden charm %s" % term)
		assert_false(_contains_forbidden_description(locale_copy, term), "locale forbidden charm %s" % term)


func test_s6_frames_charm_as_forced_override_resistance_and_no_consent() -> void:
	var record: StageNarrativeDefType = CATALOG.get_record(&"s6")
	var copy := " ".join([
		record.objective, record.threat, record.human_reason, record.clue,
		record.core_service, record.clear_debrief, record.defeat_debrief,
	]).to_lower()
	for term: String in _contract()["s6_required_terms"]:
		assert_true(copy.contains(term), term)


func test_command_body_directly_states_the_great_flare_proposition_in_both_sources() -> void:
	var fallback := String(UiCopy.static_fallbacks()[&"ui.staging.command_body"])
	var locale := String((_locale_entries())["ui.staging.command_body"])
	for copy: String in [fallback, locale]:
		assert_true(copy.contains("Great Flare"))
		assert_true(copy.contains("massive solar flare"))
		assert_true(copy.contains("two centuries"))
		assert_true(_contains_word_bounded(copy, "the Fall"))


func test_accessibility_copy_sources_do_not_reintroduce_retired_terms() -> void:
	var source := ""
	for path: String in [
		"res://scripts/ui/staging.gd", "res://scripts/ui/squad_select.gd", "res://scripts/ui/results.gd",
	]:
		source += FileAccess.get_file_as_string(path)
	for term: String in _contract()["retired_terms"]:
		assert_false(_contains_term(source, term), "%s in active screen source" % term)


func _source_copy() -> String:
	var values: Array[String] = []
	for value: Variant in UiCopy.static_fallbacks().values():
		values.append(String(value))
	for record: StageNarrativeDefType in CATALOG.records:
		for field: StageNarrativeDefType.Field in [
			StageNarrativeDefType.Field.OBJECTIVE, StageNarrativeDefType.Field.THREAT,
			StageNarrativeDefType.Field.HUMAN_REASON, StageNarrativeDefType.Field.CLUE,
			StageNarrativeDefType.Field.CORE_SERVICE, StageNarrativeDefType.Field.CLEAR_DEBRIEF,
			StageNarrativeDefType.Field.DEFEAT_DEBRIEF,
		]:
			values.append(record.fallback_for(field))
	return "\n".join(values)


func _locale_copy() -> String:
	var values: Array[String] = []
	for value: Variant in _locale_entries().values():
		values.append(String(value))
	return "\n".join(values)


func _contains_term(copy: String, term: String) -> bool:
	return _contains_word_bounded(copy, term) if term in ["the Fall", "tame", "pet", "willing turncoat", "willing defection", "friendship"] else copy.contains(term)


func _contains_forbidden_description(copy: String, term: String) -> bool:
	var regex := RegEx.new()
	var expression := "(?<![A-Za-z])%s(?![A-Za-z])" % term
	if term == "willing defection":
		expression = "(?<!not )(?<![A-Za-z])%s(?![A-Za-z])" % term
	assert_eq(regex.compile(expression), OK)
	return regex.search(copy) != null


func _contains_word_bounded(copy: String, term: String) -> bool:
	var regex := RegEx.new()
	assert_eq(regex.compile("(?<![A-Za-z])%s(?![A-Za-z])" % term), OK)
	return regex.search(copy) != null


func _contract() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH)) as Dictionary


func _locale_entries() -> Dictionary:
	var root := JSON.parse_string(FileAccess.get_file_as_string("res://localization/en-US.json")) as Dictionary
	return root["entries"] as Dictionary
