extends SceneTree

const ThemeType := preload("res://scripts/ui/components/aetheria_theme.gd")
const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")
const LunarisStyleType := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const SelectedSquadChipType := preload("res://scripts/ui/components/selected_squad_chip.gd")
const PromotionPathCardType := preload("res://scripts/ui/components/promotion_path_card.gd")
const StagingCommandTileType := preload("res://scripts/ui/components/staging_command_tile.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var theme := ThemeType.new()
	_check_focus(theme.get_stylebox(&"focus", &"Button"), "global Button")
	_check_focus(theme.get_stylebox(&"focus", &"AuiPrimaryButton"), "Aetheria primary")
	_check_focus(StagingSkinType.transparent_focus_style(Color.CYAN), "shared staging focus")

	var compact := Button.new()
	LunarisStyleType.apply_compact_rounded_button(compact, &"secondary")
	_check_focus(compact.get_theme_stylebox(&"focus"), "compact Lunaris button")
	compact.free()

	var chip := SelectedSquadChipType.new()
	root.add_child(chip)
	await process_frame
	_check_focus(chip.get_theme_stylebox(&"focus"), "selected squad chip")
	chip.queue_free()

	var promotion := PromotionPathCardType.new()
	root.add_child(promotion)
	await process_frame
	_check_focus(promotion.get_theme_stylebox(&"focus"), "promotion path card")
	promotion.queue_free()

	var tile := StagingCommandTileType.new()
	root.add_child(tile)
	await process_frame
	_check_focus(tile.get_theme_stylebox(&"focus"), "Command Center tile")
	tile.queue_free()
	await process_frame
	_finish()


func _check_focus(raw_style: StyleBox, context: String) -> void:
	var style := raw_style as StyleBoxFlat
	_check(style != null, "%s focus style is not inspectable" % context)
	if style == null:
		return
	_check(style.bg_color.a <= 0.01, "%s focus reintroduced a filled background" % context)
	_check(style.get_border_width(SIDE_LEFT) >= 2, "%s focus outline is too thin" % context)
	_check(style.border_color.a >= 0.5, "%s focus outline is not visible" % context)
	_check(style.border_color.r > style.border_color.b, "%s focus outline is not warm gold" % context)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("BUTTON_FOCUS_STYLE_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
