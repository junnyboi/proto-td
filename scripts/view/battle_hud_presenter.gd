extends RefCounted

## Presentation-only Battle HUD helper. BattleView owns model observation and
## lifecycle; this helper owns only Label construction, responsive geometry,
## and text formatting.

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const GameTypographyType := preload("res://scripts/ui/game_typography.gd")


static func create(font_size: int, z_index: int, viewport: Vector2) -> Label:
	var hud := Label.new()
	hud.name = "BattleHud"
	hud.position = Vector2(16, 8)
	hud.autowrap_mode = TextServer.AUTOWRAP_OFF
	hud.clip_text = true
	hud.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Style.apply_label(hud, &"body")
	hud.add_theme_font_size_override(&"font_size", font_size)
	hud.add_theme_font_size_override(&"outline_size", 2)
	hud.add_theme_color_override(&"font_color", Style.IVORY)
	hud.add_theme_color_override(&"font_outline_color", Color(Style.INK_DEEP, 0.94))
	hud.add_theme_stylebox_override(&"normal", Style.panel_style(&"hud"))
	hud.z_index = z_index
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relayout(hud, viewport)
	return hud


static func relayout(hud: Label, viewport: Vector2) -> void:
	if hud == null:
		return
	var compact := _uses_compact_layout(viewport)
	hud.position = Vector2(12, 8) if compact else Vector2(16, 8)
	hud.size = (
		Vector2(viewport.x * 0.50, 82.0)
		if compact
		else Vector2(viewport.x - 32.0, 50.0)
	)


static func text_for(snapshot: Dictionary, viewport: Vector2) -> String:
	var result_text: String = ["ACTIVE", "CLEAR", "DEFEAT"][int(snapshot["result"])]
	if _uses_compact_layout(viewport):
		return "CORE %d   DP %d\nELIMS %d   TICK %d   %s" % [
			snapshot["base_hp"], snapshot["dp"], snapshot["killed"],
			snapshot["tick"], result_text,
		]
	return "CORE  %d    DP  %d    ELIMINATIONS  %d    TICK  %d    %s" % [
		snapshot["base_hp"], snapshot["dp"], snapshot["killed"],
		snapshot["tick"], result_text,
	]


static func _uses_compact_layout(viewport: Vector2) -> bool:
	return viewport.x < viewport.y or viewport.x < 1100.0
