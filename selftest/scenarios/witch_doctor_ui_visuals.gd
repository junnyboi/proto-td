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
	var campaign := game.get("campaign") as LegacyCampaignAdapter
	h.check("campaign exists", campaign != null)
	if campaign == null:
		return
	var campaign_before := {
		"operators": campaign.unlocked_operators.duplicate(),
		"traps": campaign.unlocked_traps.duplicate(),
		"spells": campaign.unlocked_spells.duplicate(),
		"stars": campaign.stage_stars.duplicate(true),
	}
	game.call("debug_unlock_all")
	game.set("selected_stage_id", &"s1")
	game.call("open_squad_select")
	await h.frames(8)
	var screen := game.get("content") as Control
	var witch_pick := screen.find_child("Pick_witch_doctor_1", true, false) as Button
	var mage_pick := screen.find_child("Pick_caster_1", true, false) as Button
	var expected := Art.texture(&"portrait_caster_1")
	var old_portrait := Art.texture(&"portrait_witch_doctor_1")
	h.check("Witch Doctor squad portrait exists", witch_pick != null and witch_pick.icon != null)
	h.check("Mage Apprentice squad portrait exists", mage_pick != null and mage_pick.icon != null)
	h.check(
		"Witch Doctor portrait is the exact Mage Apprentice portrait",
		witch_pick != null
		and mage_pick != null
		and witch_pick.icon == expected
		and witch_pick.icon == mage_pick.icon
		and witch_pick.icon != old_portrait,
	)
	h.check(
		"portrait remap preserves campaign state",
		campaign.unlocked_operators == campaign_before["operators"]
		and campaign.unlocked_traps == campaign_before["traps"]
		and campaign.unlocked_spells == campaign_before["spells"]
		and campaign.stage_stars == campaign_before["stars"],
	)
	var scroll := screen.find_child("SquadScroll", true, false) as ScrollContainer
	if scroll != null and witch_pick != null:
		scroll.ensure_control_visible(witch_pick)
		await h.frames(3)
		h.check(
			"Witch Doctor portrait card is visible",
			scroll.get_global_rect().intersects(witch_pick.get_global_rect()),
		)
	await h.shot("witch_doctor_mage_portrait")
	print("WITCH_DOCTOR_UI_VISUALS_COMPLETED")
	h.done()
