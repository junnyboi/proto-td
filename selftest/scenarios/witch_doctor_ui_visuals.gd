extends RefCounted


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 600
	await h.frames(6)
	var game := h.autoload("Game")
	h.check("Game autoload available", game != null)
	if game == null:
		return
	game.call("start_campaign", false)
	var campaign: CampaignStateV3 = game.get("campaign")
	h.check("v3 campaign exists", campaign != null)
	if campaign == null:
		return
	var save_before: String = campaign.encode_save()["text"]
	game.call("_debug_unlock_all")
	var mage := load("res://data/operators/caster_1.tres") as OperatorDef
	var witch_doctor := load("res://data/operators/witch_doctor_1.tres") as OperatorDef
	var expected: Texture2D = Art.texture(StringName("portrait_%s" % mage.portrait_id))
	var witch: Texture2D = Art.texture(StringName("portrait_%s" % witch_doctor.portrait_id))
	var old_portrait: Texture2D = Art.texture(&"portrait_witch_doctor_1")
	h.check("Witch Doctor portrait exists", witch != null)
	h.check(
		"Witch Doctor portrait is the exact Mage Apprentice portrait",
		witch == expected and witch != old_portrait,
	)
	h.check(
		"debug portrait inspection preserves CampaignSave v3 bytes",
		campaign.encode_save()["text"] == save_before,
	)
	var panel := HBoxContainer.new()
	panel.name = "DebugPortraitComparison"
	panel.position = Vector2(360.0, 220.0)
	panel.add_theme_constant_override(&"separation", 48)
	for texture: Texture2D in [expected, witch]:
		var preview := TextureRect.new()
		preview.texture = texture
		preview.custom_minimum_size = Vector2(192.0, 192.0)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		panel.add_child(preview)
	game.get_tree().root.add_child(panel)
	await h.frames(3)
	await h.shot("witch_doctor_mage_portrait")
	panel.queue_free()
	print("WITCH_DOCTOR_UI_VISUALS_COMPLETED")
	h.done()
