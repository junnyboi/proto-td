extends GutTest

const I18nScript := preload("res://autoloads/i18n.gd")
const TITLE_KEY := &"ui.game_title"
const TITLE_FALLBACK := "Aetheria Tactics"


func test_en_us_catalog_resolves_exact_product_title() -> void:
	var i18n := I18nScript.new()
	assert_true(i18n.reload_catalog())
	assert_eq(i18n.t(TITLE_KEY, TITLE_FALLBACK), TITLE_FALLBACK)
	assert_eq(i18n.supported_locales(), PackedStringArray(["en-US"]))
	assert_eq(i18n.locale(), &"en-US")


func test_missing_or_blank_key_returns_exact_english_fallback() -> void:
	var i18n := I18nScript.new()
	assert_true(i18n.reload_catalog())
	assert_eq(i18n.t(&"missing.key", "Fallback"), "Fallback")
	assert_eq(i18n.t(&"missing.blank", ""), "")


func test_unsupported_locale_rejects_without_state_change() -> void:
	var i18n := I18nScript.new()
	assert_true(i18n.reload_catalog())
	assert_false(i18n.set_locale(&"fr-FR"))
	assert_eq(i18n.locale(), &"en-US")
	assert_true(i18n.set_locale(&"en-US"))


func test_catalog_has_exact_key_set_and_nonblank_values() -> void:
	var text := FileAccess.get_file_as_string("res://localization/en-US.json")
	var parsed: Variant = JSON.parse_string(text)
	assert_true(parsed is Dictionary)
	var catalog := parsed as Dictionary
	var entries := catalog.get("entries", {}) as Dictionary
	assert_eq(entries.keys(), ["ui.game_title"])
	assert_eq(entries["ui.game_title"], TITLE_FALLBACK)


func test_project_and_title_source_use_canonical_identity_seam() -> void:
	var project_name := str(ProjectSettings.get_setting("application/config/name", ""))
	assert_eq(project_name, TITLE_FALLBACK)
	var source := FileAccess.get_file_as_string("res://scripts/ui/title.gd")
	assert_true(source.contains('I18n.t(&"ui.game_title", "Aetheria Tactics")'))
	assert_false(source.contains('label.text = "Prototype TD"'))
