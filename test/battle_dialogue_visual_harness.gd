extends Node

const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")

var _mode := "start"
var _output_path := "/tmp/proto-td-battle-dialogue.png"


func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			_mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--out="):
			_output_path = argument.trim_prefix("--out=")
	call_deferred("_run")


func _run() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "BattlefieldBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color("07131f")
	get_tree().root.add_child(backdrop)

	var battlefield := Label.new()
	battlefield.name = "BattlefieldReadout"
	battlefield.set_anchors_preset(Control.PRESET_FULL_RECT)
	battlefield.offset_left = 28.0
	battlefield.offset_top = 28.0
	battlefield.offset_right = -28.0
	battlefield.offset_bottom = -28.0
	battlefield.text = "COMPANY MANUS // HEARTHCROSS\n\nWAVE 01 / 05\nLIVES 20     DP 30\n\n\n\n\n\n\n\n\nTACTICAL COMMANDS"
	battlefield.add_theme_color_override("font_color", Color(0.27, 0.64, 0.78, 0.54))
	battlefield.add_theme_font_size_override("font_size", 18)
	backdrop.add_child(battlefield)

	var dialogue := BattleDialoguePresenter.new()
	dialogue.name = "BattleDialogue"
	backdrop.add_child(dialogue)
	var record := NARRATIVE_CATALOG.get_record(&"s1")
	dialogue.setup(record, Vector2(get_viewport().size))
	var shown := false
	if _mode == "start":
		shown = dialogue.show_mission_start()
	elif _mode == "mid":
		shown = dialogue.show_mid_wave(2)
	else:
		push_error("Unknown battle dialogue visual mode: %s" % _mode)
		get_tree().quit(1)
		return
	if not shown:
		push_error("Battle dialogue visual harness could not show %s" % _mode)
		get_tree().quit(1)
		return
	for _frame: int in range(8):
		await get_tree().process_frame
	print(
		"BATTLE_DIALOGUE_RECT mode=%s position=%s size=%s minimum=%s anchors=%s" % [
			_mode, dialogue.position, dialogue.size, dialogue.get_combined_minimum_size(),
			Vector4(dialogue.anchor_left, dialogue.anchor_top, dialogue.anchor_right, dialogue.anchor_bottom),
		],
	)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(_output_path)
	if error != OK:
		push_error("Could not save battle dialogue capture: %s" % error)
		get_tree().quit(1)
		return
	backdrop.queue_free()
	var sfx := get_tree().root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	for _frame: int in range(12):
		await get_tree().process_frame
	print("BATTLE_DIALOGUE_VISUAL_OK mode=%s path=%s" % [_mode, _output_path])
	get_tree().quit(0)
