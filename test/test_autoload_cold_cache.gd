extends GutTest

const MUSIC_PATH := "res://autoloads/music.gd"
const COLD_BOOT_CHECK_PATH := "res://scripts/cold_boot_check.sh"


func test_music_autoload_does_not_depend_on_global_class_cache() -> void:
	var source := FileAccess.get_file_as_string(MUSIC_PATH)
	assert_false(source.is_empty(), MUSIC_PATH)
	for token: String in [": MusicCatalog", " as MusicCatalog"]:
		assert_false(
			source.contains(token), "%s forbids cache-backed syntax %s" % [MUSIC_PATH, token]
		)


func test_music_pins_catalog_script_by_path() -> void:
	var source := FileAccess.get_file_as_string(MUSIC_PATH)
	assert_true(source.contains('preload("res://assets/music/music_catalog.gd")'))
	assert_true(source.contains("loaded.get_script() != MUSIC_CATALOG_SCRIPT"))


func test_cold_boot_gate_removes_only_music_catalog_and_scans_output() -> void:
	var source := FileAccess.get_file_as_string(COLD_BOOT_CHECK_PATH)
	assert_false(source.is_empty(), COLD_BOOT_CHECK_PATH)
	assert_true(source.contains('"class": &"MusicCatalog"'))
	assert_true(source.contains('"class": &"BattleModel"'))
	assert_true(source.contains("SCRIPT ERROR:"))
	assert_true(source.contains("Failed to instantiate an autoload"))
	assert_true(source.contains("Loading resource: res://autoloads/music.gd"))
	assert_true(source.contains("music_autoload=1"))
	assert_true(source.contains("music_catalog_registry_entry=0"))


func test_stale_music_catalog_cache_boots_without_parser_errors() -> void:
	var output: Array = []
	var code := OS.execute(
		"/bin/bash", [ProjectSettings.globalize_path(COLD_BOOT_CHECK_PATH)], output, true
	)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_true(combined.contains("[cold-boot] ALL GREEN"), combined)
