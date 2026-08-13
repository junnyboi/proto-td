extends RefCounted

## Presentation-only Battle HUD helper. BattleView owns model observation and
## lifecycle; this helper owns only Label construction, responsive geometry,
## and text formatting.


static func create(font_size: int, z_index: int, viewport: Vector2) -> Label:
	var hud := Label.new()
	hud.name = "BattleHud"
	hud.position = Vector2(16, 8)
	hud.autowrap_mode = TextServer.AUTOWRAP_OFF
	hud.clip_text = true
	hud.add_theme_font_size_override("font_size", font_size)
	hud.z_index = z_index
	relayout(hud, viewport)
	return hud


static func relayout(hud: Label, viewport: Vector2) -> void:
	if hud == null:
		return
	hud.size = (
		Vector2(viewport.x * 0.46, 84.0)
		if viewport.x < viewport.y
		else Vector2(viewport.x - 32.0, 48.0)
	)


static func text_for(snapshot: Dictionary, viewport: Vector2) -> String:
	var result_text: String = ["RUNNING", "CLEAR", "DEFEAT"][int(snapshot["result"])]
	if viewport.x < viewport.y:
		return "HP %d  DP %d\nK %d  T %d  %s" % [
			snapshot["base_hp"], snapshot["dp"], snapshot["killed"],
			snapshot["tick"], result_text,
		]
	return "Base HP %d   DP %d   kills %d   tick %d   %s" % [
		snapshot["base_hp"], snapshot["dp"], snapshot["killed"],
		snapshot["tick"], result_text,
	]
