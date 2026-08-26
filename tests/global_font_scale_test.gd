extends SceneTree

const GameTypographyType := preload("res://scripts/ui/game_typography.gd")
const AetheriaThemeType := preload("res://scripts/ui/components/aetheria_theme.gd")
const LunarisOpsType := preload("res://scripts/ui/components/lunaris_ops_style.gd")

var _failures: Array[String] = []


func _init() -> void:
	_check_typography_constants()
	_check_aetheria_theme()
	_check_lunaris_roles()
	_check_title_multiplier()
	_finish()


func _check_typography_constants() -> void:
	var expected := {
		"CAPTION": 17,
		"MICRO_LABEL": 18,
		"STATUS": 20,
		"BADGE": 21,
		"DETAIL": 24,
		"BODY": 27,
		"ACTION": 30,
		"DENSE_HEADING": 30,
		"SECTION_HEADING": 36,
		"DISPLAY": 42,
		"SCREEN_TITLE": 48,
		"RESULT_DISPLAY": 54,
	}
	var constants: Dictionary = (GameTypographyType as Script).get_script_constant_map()
	for key: String in expected:
		_check(int(constants.get(key, -1)) == int(expected[key]), "%s is not at the exact 1.5x scale" % key)


func _check_aetheria_theme() -> void:
	var theme := AetheriaThemeType.new()
	_check(theme.default_font_size == 27, "Aetheria default body type is not 27px")
	_check(theme.get_font_size(&"font_size", &"AuiPrimaryButton") == 30, "Aetheria actions are not 30px")
	_check(theme.get_font_size(&"font_size", &"AuiTitleLabel") == 48, "Aetheria titles are not 48px")
	_check(theme.get_font_size(&"font_size", &"AuiHeadingLabel") == 36, "Aetheria headings are not 36px")
	_check(theme.get_font_size(&"font_size", &"AuiDetailLabel") == 24, "Aetheria detail type is not 24px")


func _check_lunaris_roles() -> void:
	var expected := {
		&"eyebrow": 24,
		&"title": 57,
		&"heading": 33,
		&"body": 27,
		&"detail": 24,
		&"metric": 32,
	}
	for role: StringName in expected:
		var label := Label.new()
		LunarisOpsType.apply_label(label, role)
		_check(label.get_theme_font_size(&"font_size") == int(expected[role]), "Lunaris %s role is not scaled" % role)
		label.free()
	var button := Button.new()
	LunarisOpsType.apply_button(button, &"secondary")
	_check(button.get_theme_font_size(&"font_size") == 27, "Lunaris button type is not 27px")
	button.free()


func _check_title_multiplier() -> void:
	for path: String in ["res://scripts/ui/title.gd", "res://scripts/ui/title_settings.gd"]:
		var source := FileAccess.get_file_as_string(path)
		_check(source.contains("const TITLE_FONT_SCALE := 3.0"), "%s title multiplier is not 3.0" % path)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("GLOBAL_FONT_SCALE_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
