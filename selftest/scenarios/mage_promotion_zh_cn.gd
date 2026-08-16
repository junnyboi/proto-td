extends RefCounted

const SupportType := preload("res://selftest/recruit_promotion_support.gd")
const VIEWPORT := Vector2i(1280, 720)


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 1000
	h.root.size = VIEWPORT
	await h.frames(4)
	var i18n := h.autoload("I18n")
	var game := h.autoload("Game")
	h.check("zh-CN locale activates", bool(i18n.call("set_locale", &"zh-CN")))
	var support := SupportType.new()
	var prepared: Dictionary = await support.prepare_eligible_recruit(h, game)
	if prepared.is_empty():
		return
	var before := support.authority_facts(game)
	game.call("training_call", &"open", &"staging")
	var training := await support.await_screen(h, game, "TrainingRoot")
	h.check("Chinese v3 Training opens", training != null)
	if training == null:
		return
	var title := support.find(training, "TrainingTitleHeading") as Label
	var row := support.find(training, "Recruit_%s" % prepared["target_id"]) as Button
	var view_paths := support.find(training, "ViewPaths") as Button
	h.check("Chinese Training title is exact", title != null and title.text == "训练")
	h.check(
		"Chinese Recruit row presents class, XP, and readiness",
		row != null and row.text.contains("新兵")
		and row.text.contains("经验值 100 / 100")
		and row.text.contains("已满足晋升条件"),
		row.text if row != null else "missing",
	)
	await support.ensure_visible(h, row)
	await h.click_view(row.get_global_rect().get_center())
	view_paths = support.find(training, "ViewPaths") as Button
	await support.ensure_visible(h, view_paths)
	await h.click_view(view_paths.get_global_rect().get_center())
	await h.frames(3)
	var defender := support.find(training, "Path_defender") as Button
	var gunner := support.find(training, "Path_gunner") as Button
	var mage := support.find(training, "Path_mage_apprentice") as Button
	var shock := support.find(training, "Path_shock_trooper") as Button
	var sword := support.find(training, "Path_swordmaster") as Button
	var choose := support.find(training, "ChoosePath") as Button
	var warning := support.find(training, "PermanentWarning") as Label
	h.check(
		"Chinese board preserves all five standard class identities",
		defender != null and gunner != null and mage != null and shock != null and sword != null
		and defender.text.contains("守卫") and gunner.text.contains("枪手")
		and mage.text.contains("见习法师") and shock.text.contains("突击兵")
		and sword.text.contains("剑术大师"),
	)
	h.check(
		"Chinese permanence warning and draft action are exact",
		warning != null and warning.text == "此选择不可更改。"
		and choose != null and choose.text == "选择此项",
	)
	h.check("Chinese browsing remains state-equal", support.authority_facts(game) == before)
	await h.shot("training_recruit_paths_zh_cn")
	print("MAGE_PROMOTION_ZH_CN_COMPLETED")
	h.done()
