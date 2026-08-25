extends Control

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const DialogType := preload("res://scripts/ui/components/lunaris_dialog_sheet.gd")
const ClassDefType := preload("res://data/class_def.gd")
const ResonanceStarType := preload("res://scripts/ui/components/resonance_star.gd")
const CinematicPlayerType := preload("res://scripts/ui/components/gacha_cinematic_player.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const LUNARIS_BACKDROP := preload("res://assets/loading/lunaris_reliquary_loading.png")

const HARD_PITY_WINDOW := 10
const FIVE_STAR_RARITY := 5
const CINEMATIC_FINAL_PLATE_SECONDS := 7.44
const CINEMATIC_RESULT_RISE_SECONDS := 0.32
const CINEMATIC_RESULT_SETTLE_SECONDS := 0.24

@export var reduced_motion := false

var _game: Node
var _marks_label: Label
var _pull_button: Button
var _back_button: Button
var _status_label: Label
var _hero_grid: GridContainer
var _header_grid: GridContainer
var _action_grid: GridContainer
var _screen_margin: MarginContainer
var _pity_label: Label
var _pity_segments: HBoxContainer
var _pull_confirmation: Dictionary = {}

var _reveal_layer: Control
var _reveal_shade: ColorRect
var _cinematic_player: GachaCinematicPlayer
var _reveal_burst: Control
var _reveal_panel: PanelContainer
var _reveal_content_grid: GridContainer
var _reveal_eyebrow: Label
var _reveal_title: Label
var _reveal_portrait: TextureRect
var _reveal_stars: HBoxContainer
var _reveal_result: Label
var _reveal_lives: Label
var _reveal_pity: Label
var _skip_button: Button
var _reveal_tween: Tween
var _is_revealing := false
var _pending_pull: Dictionary = {}


func _ready() -> void:
	_game = get_node_or_null("/root/Game")
	if _game != null:
		_game.set("content", self)
	Style.add_backdrop(self, LUNARIS_BACKDROP)
	_build_screen()
	_build_pull_confirmation()
	_build_reveal_layer()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_refresh()


func _exit_tree() -> void:
	_kill_reveal_tween()
	_stop_cinematic()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if _is_revealing and (event.is_action(&"ui_accept") or event.is_action(&"ui_cancel")):
		get_viewport().set_input_as_handled()
		_finish_reveal()
		return
	var confirmation_overlay := _pull_confirmation.get(&"overlay") as Control
	if confirmation_overlay != null and confirmation_overlay.visible and event.is_action(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_pull_cancelled()
		return
	if event.is_action(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _build_screen() -> void:
	_screen_margin = MarginContainer.new()
	_screen_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_margin.add_theme_constant_override(&"margin_left", 42)
	_screen_margin.add_theme_constant_override(&"margin_top", 30)
	_screen_margin.add_theme_constant_override(&"margin_right", 42)
	_screen_margin.add_theme_constant_override(&"margin_bottom", 30)
	add_child(_screen_margin)

	var shell := PanelContainer.new()
	Style.apply_panel(shell, &"screen")
	_screen_margin.add_child(shell)

	var content := VBoxContainer.new()
	content.add_theme_constant_override(&"separation", 18)
	shell.add_child(content)

	_header_grid = GridContainer.new()
	_header_grid.columns = 3
	_header_grid.add_theme_constant_override(&"h_separation", 16)
	_header_grid.add_theme_constant_override(&"v_separation", 10)
	content.add_child(_header_grid)
	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = _copy(&"ui.gacha.back", "← COMMAND DECK")
	_back_button.pressed.connect(_on_back_pressed)
	Style.apply_button(_back_button, &"quiet")
	_header_grid.add_child(_back_button)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_grid.add_child(title_box)
	title_box.add_child(_label(_copy(&"ui.gacha.eyebrow", "LUNARIS RELIQUARY"), &"eyebrow"))
	title_box.add_child(_label(_copy(&"ui.gacha.title", "Premium Resonance"), &"title"))
	_marks_label = _label("0 MARKS", &"metric")
	_marks_label.name = "MarksLabel"
	_marks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_grid.add_child(_marks_label)

	var intro := PanelContainer.new()
	Style.apply_panel(intro, &"quiet")
	content.add_child(intro)
	var intro_box := VBoxContainer.new()
	intro_box.add_theme_constant_override(&"separation", 10)
	intro.add_child(intro_box)
	var intro_text := _label(
		_copy(&"ui.gacha.intro", "Every resonance grants one life. Premium heroes keep fixed elite kits and cannot be trained. 5-star base rate: 5% • guaranteed within ten pulls."),
		&"body",
	)
	intro_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_box.add_child(intro_text)
	var pity_row := HBoxContainer.new()
	pity_row.add_theme_constant_override(&"separation", 12)
	intro_box.add_child(pity_row)
	_pity_label = _label(_copy(&"ui.gacha.guarantee", "5-STAR GUARANTEE"), &"detail")
	_pity_label.name = "PityLabel"
	_pity_label.custom_minimum_size.x = 210
	pity_row.add_child(_pity_label)
	_pity_segments = HBoxContainer.new()
	_pity_segments.name = "PitySegments"
	_pity_segments.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pity_segments.add_theme_constant_override(&"separation", 5)
	pity_row.add_child(_pity_segments)
	for index: int in HARD_PITY_WINDOW:
		var segment := ColorRect.new()
		segment.name = "Pity_%02d" % (index + 1)
		segment.custom_minimum_size = Vector2(24, 8)
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pity_segments.add_child(segment)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var hero_stage := CenterContainer.new()
	hero_stage.name = "PremiumHeroStage"
	hero_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(hero_stage)
	_hero_grid = GridContainer.new()
	_hero_grid.name = "PremiumHeroGrid"
	_hero_grid.columns = 3
	_hero_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hero_grid.add_theme_constant_override(&"h_separation", 16)
	_hero_grid.add_theme_constant_override(&"v_separation", 16)
	hero_stage.add_child(_hero_grid)

	_action_grid = GridContainer.new()
	_action_grid.columns = 2
	_action_grid.add_theme_constant_override(&"h_separation", 18)
	_action_grid.add_theme_constant_override(&"v_separation", 10)
	content.add_child(_action_grid)
	_status_label = _label(_copy(&"ui.gacha.ready", "The pool is ready."), &"detail")
	_status_label.name = "PullStatusLabel"
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_grid.add_child(_status_label)
	_pull_button = Button.new()
	_pull_button.name = "PremiumPullButton"
	_pull_button.custom_minimum_size = Vector2(280, 60)
	_pull_button.pressed.connect(_on_pull_pressed)
	_pull_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_grid.add_child(_pull_button)


func _build_pull_confirmation() -> void:
	_pull_confirmation = DialogType.create(
		self,
		"PullConfirmationLayer",
		_copy(&"ui.gacha.confirm_title", "CONFIRM RESONANCE"),
		_copy(&"ui.gacha.confirm_intro", "Align one signal through the random premium pool."),
		_copy(&"ui.gacha.resonate", "RESONATE"),
		_copy(&"ui.common.cancel", "CANCEL"),
	)
	var confirm := _pull_confirmation.get(&"confirm") as Button
	var cancel := _pull_confirmation.get(&"cancel") as Button
	confirm.name = "ConfirmPremiumPull"
	cancel.name = "CancelPremiumPull"
	confirm.pressed.connect(_on_confirm_pull)
	cancel.pressed.connect(_on_pull_cancelled)


func _build_reveal_layer() -> void:
	_reveal_layer = Control.new()
	_reveal_layer.name = "PullRevealLayer"
	_reveal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_reveal_layer.visible = false
	_reveal_layer.modulate.a = 0.0
	add_child(_reveal_layer)

	_reveal_shade = ColorRect.new()
	_reveal_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_shade.color = Color(0.004, 0.008, 0.016, 1.0)
	_reveal_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_reveal_layer.add_child(_reveal_shade)

	_cinematic_player = CinematicPlayerType.new()
	_cinematic_player.name = "GachaCinematicPlayer"
	_reveal_layer.add_child(_cinematic_player)

	_reveal_burst = Control.new()
	_reveal_burst.name = "SignalFilaments"
	_reveal_burst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_layer.add_child(_reveal_burst)
	for index: int in 12:
		var ray := ColorRect.new()
		ray.set_anchors_preset(Control.PRESET_CENTER)
		ray.offset_left = -360.0
		ray.offset_right = 360.0
		ray.offset_top = -1.0
		ray.offset_bottom = 1.0
		ray.pivot_offset = Vector2(360, 1)
		ray.rotation = deg_to_rad(float(index) * 15.0)
		ray.color = Color(Style.CYAN.r, Style.CYAN.g, Style.CYAN.b, 0.16)
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_reveal_burst.add_child(ray)

	var safe_margin := MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_theme_constant_override(&"margin_left", 24)
	safe_margin.add_theme_constant_override(&"margin_top", 20)
	safe_margin.add_theme_constant_override(&"margin_right", 24)
	safe_margin.add_theme_constant_override(&"margin_bottom", 24)
	_reveal_layer.add_child(safe_margin)
	var overlay_box := VBoxContainer.new()
	overlay_box.add_theme_constant_override(&"separation", 14)
	safe_margin.add_child(overlay_box)
	var top_row := HBoxContainer.new()
	overlay_box.add_child(top_row)
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	_skip_button = Button.new()
	_skip_button.name = "SkipRevealButton"
	_skip_button.text = _copy(&"ui.gacha.skip_reveal", "SKIP REVEAL")
	_skip_button.pressed.connect(_finish_reveal)
	Style.apply_button(_skip_button, &"quiet")
	top_row.add_child(_skip_button)
	var vertical_spacer := Control.new()
	vertical_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_box.add_child(vertical_spacer)
	_reveal_panel = PanelContainer.new()
	_reveal_panel.name = "RevealCard"
	_reveal_panel.custom_minimum_size = Vector2(760, 236)
	_reveal_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Style.apply_panel(_reveal_panel, &"screen")
	overlay_box.add_child(_reveal_panel)
	_reveal_content_grid = GridContainer.new()
	_reveal_content_grid.columns = 2
	_reveal_content_grid.add_theme_constant_override(&"h_separation", 22)
	_reveal_content_grid.add_theme_constant_override(&"v_separation", 10)
	_reveal_panel.add_child(_reveal_content_grid)
	_reveal_portrait = TextureRect.new()
	_reveal_portrait.name = "RevealPortrait"
	_reveal_portrait.custom_minimum_size = Vector2(220, 190)
	_reveal_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_reveal_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_reveal_portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reveal_content_grid.add_child(_reveal_portrait)
	var info_margin := MarginContainer.new()
	info_margin.add_theme_constant_override(&"margin_top", 8)
	info_margin.add_theme_constant_override(&"margin_right", 14)
	info_margin.add_theme_constant_override(&"margin_bottom", 28)
	_reveal_content_grid.add_child(info_margin)
	var reveal_box := VBoxContainer.new()
	reveal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	reveal_box.add_theme_constant_override(&"separation", 8)
	info_margin.add_child(reveal_box)
	_reveal_eyebrow = _label(_copy(&"ui.gacha.signal_lock", "SIGNAL LOCK"), &"eyebrow")
	_reveal_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_box.add_child(_reveal_eyebrow)
	_reveal_title = _label(_copy(&"ui.gacha.reveal_title", "RESONANCE"), &"title")
	_reveal_title.name = "RevealTitle"
	_reveal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_box.add_child(_reveal_title)
	_reveal_stars = HBoxContainer.new()
	_reveal_stars.name = "RarityStars"
	_reveal_stars.alignment = BoxContainer.ALIGNMENT_CENTER
	_reveal_stars.add_theme_constant_override(&"separation", 8)
	reveal_box.add_child(_reveal_stars)
	for index: int in FIVE_STAR_RARITY:
		var star := ResonanceStarType.new()
		star.name = "Star_%d" % (index + 1)
		star.set_state(Style.GOLD, false)
		_reveal_stars.add_child(star)
	_reveal_result = _label(_copy(&"ui.gacha.signal_acquired", "SIGNAL ACQUIRED"), &"heading")
	_reveal_result.name = "RevealResult"
	_reveal_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reveal_box.add_child(_reveal_result)
	_reveal_lives = _label(_copy(&"ui.gacha.one_life_ready", "1 LIFE READY"), &"metric")
	_reveal_lives.name = "RevealLives"
	_reveal_lives.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_box.add_child(_reveal_lives)
	_reveal_pity = _label(_copy(&"ui.gacha.guarantee_default", "5-star guaranteed within 10 pulls"), &"detail")
	_reveal_pity.name = "RevealPity"
	_reveal_pity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_box.add_child(_reveal_pity)


func _refresh() -> void:
	if _game == null or not bool(_game.get("campaign_active")) or _game.get("campaign") == null:
		_marks_label.text = _copy(&"ui.gacha.campaign_offline", "CAMPAIGN OFFLINE")
		_pull_button.text = _copy(&"ui.gacha.pull_unavailable", "PULL UNAVAILABLE")
		_pull_button.disabled = true
		_back_button.disabled = _is_revealing
		Style.apply_button(_pull_button, &"disabled")
		_status_label.text = _copy(&"ui.gacha.campaign_required", "Start or continue a campaign to access premium resonance.")
		return
	var projection: Dictionary = _game.get("campaign").runtime_projection()
	var marks := int(projection["marks"])
	var cost := int(projection["premium_pull_cost"])
	var pity_streak := int(projection.get("premium_pity_streak", 0))
	var guarantee_in := int(projection.get("premium_guarantee_in", HARD_PITY_WINDOW))
	_marks_label.text = _format(&"ui.gacha.marks", "{count} MARKS", {&"count": marks})
	_pull_button.text = _format(&"ui.gacha.pull_action", "RESONATE • {cost} MARKS", {&"cost": cost})
	var attempt_pending := bool(projection.get("attempt_pending", false))
	_pull_button.disabled = marks < cost or attempt_pending or _is_revealing
	_back_button.disabled = _is_revealing
	Style.apply_button(_pull_button, &"disabled" if _pull_button.disabled else &"gold")
	_pity_label.text = _format(&"ui.gacha.guarantee_in", "5-STAR GUARANTEED IN {count} {unit}", {
		&"count": guarantee_in, &"unit": _pull_unit(guarantee_in).to_upper(),
	})
	for index: int in _pity_segments.get_child_count():
		var segment := _pity_segments.get_child(index) as ColorRect
		segment.color = Style.GOLD if index < pity_streak else Color(Style.CYAN.r, Style.CYAN.g, Style.CYAN.b, 0.16)
	var confirm_body := _pull_confirmation.get(&"body") as Label
	if confirm_body != null:
		confirm_body.text = _format(&"ui.gacha.confirm_body", "One random signal • {cost} Marks\nBalance  {before} → {after} Marks\n5-star guarantee in {count} {unit}. Every accepted resonance grants exactly one life.", {
			&"cost": cost, &"before": marks, &"after": maxi(0, marks - cost),
			&"count": guarantee_in, &"unit": _pull_unit(guarantee_in),
		})
	if attempt_pending:
		_status_label.text = _copy(&"ui.gacha.attempt_pending", "Resolve the active operation before using premium resonance.")
	elif marks < cost:
		_status_label.text = _format(&"ui.gacha.marks_needed", "Earn {count} more Marks for another resonance pull.", {&"count": cost - marks})
	_rebuild_cards(projection)


func _rebuild_cards(projection: Dictionary) -> void:
	for child: Node in _hero_grid.get_children():
		child.queue_free()
	var owned := {}
	for hero: Dictionary in projection["premium_heroes"]:
		owned[String(hero["premium_id"])] = hero
	var pool: Array = projection["premium_pool"].duplicate(true)
	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("rarity", 4)) > int(b.get("rarity", 4))
	)
	for row: Dictionary in pool:
		_hero_grid.add_child(_hero_card(row, owned.get(String(row["premium_id"]), {})))


func _hero_card(catalog: Dictionary, hero: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Premium_%s" % catalog["premium_id"]
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var rarity := int(catalog.get("rarity", 4))
	panel.custom_minimum_size = Vector2(460 if rarity == FIVE_STAR_RARITY else 250, 430 if rarity == FIVE_STAR_RARITY else 350)
	Style.apply_panel(panel, &"danger" if not hero.is_empty() and hero["life_status"] == "dead" else (&"result" if rarity == FIVE_STAR_RARITY else &"quiet"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 9)
	panel.add_child(box)
	var rarity_label := _label(_format(&"ui.gacha.rarity", "{rarity}-STAR PREMIUM", {&"rarity": rarity}), &"eyebrow")
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_color_override(&"font_color", Style.GOLD if rarity == FIVE_STAR_RARITY else Style.CYAN)
	box.add_child(rarity_label)
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture = Art.texture(StringName(catalog["portrait_asset_id"]))
	portrait.custom_minimum_size = Vector2(340 if rarity == FIVE_STAR_RARITY else 190, 270 if rarity == FIVE_STAR_RARITY else 190)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(portrait)
	var name := _label(String(catalog["callsign"]), &"heading")
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name)
	var display_class := _class_name(String(catalog["class_id"]))
	var role := _label(display_class.to_upper(), &"detail")
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(role)
	var status := _copy(&"ui.gacha.unacquired", "UNACQUIRED")
	var detail := _copy(&"ui.gacha.pull_to_recruit", "Pull to recruit • Fixed elite kit")
	if not hero.is_empty():
		var lives := int(hero["premium_lives"])
		status = _format(&"ui.gacha.lives", "{count} {unit}", {&"count": lives, &"unit": _life_unit(lives)})
		detail = _format(&"ui.gacha.total_copies", "{count} total copies • Fixed elite kit", {&"count": int(hero["premium_pull_count"])})
		if lives == 0:
			status = _copy(&"ui.gacha.locked_lives", "LOCKED • 0 LIVES")
			detail = _copy(&"ui.gacha.restore_hint", "Pull this hero again to restore deployment")
	var status_label := _label(status, &"metric")
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override(
		&"font_color", Style.DANGER if status.begins_with("LOCKED") else Style.CYAN,
	)
	box.add_child(status_label)
	var detail_label := _label(detail, &"detail")
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(detail_label)
	return panel


func _apply_responsive_layout() -> void:
	if _hero_grid == null or _header_grid == null or _action_grid == null:
		return
	var portrait := get_viewport_rect().size.x < 900.0
	_hero_grid.columns = 1 if portrait else 3
	_header_grid.columns = 1 if portrait else 3
	_action_grid.columns = 1 if portrait else 2
	_marks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
	var side_margin := 18 if portrait else 42
	_screen_margin.add_theme_constant_override(&"margin_left", side_margin)
	_screen_margin.add_theme_constant_override(&"margin_right", side_margin)
	_pull_button.custom_minimum_size.x = 0 if portrait else 280
	if _reveal_content_grid != null:
		_reveal_content_grid.columns = 1 if portrait else 2
	if _reveal_panel != null:
		_reveal_panel.custom_minimum_size.x = 0
		_reveal_panel.custom_minimum_size.y = 450 if portrait else 270
	if _reveal_portrait != null:
		_reveal_portrait.custom_minimum_size.x = 0 if portrait else 220
		_reveal_portrait.custom_minimum_size.y = 150 if portrait else 190


func _on_pull_pressed() -> void:
	if _is_revealing:
		_finish_reveal()
		return
	if _pull_button.disabled:
		return
	Sfx.play("ui_click")
	DialogType.show_dialog(_pull_confirmation, _pull_button)


func _on_pull_cancelled() -> void:
	Sfx.play("ui_back")
	DialogType.hide_dialog(_pull_confirmation)


func _on_confirm_pull() -> void:
	var overlay := _pull_confirmation.get(&"overlay") as Control
	if overlay == null or not overlay.visible:
		return
	DialogType.set_pending(_pull_confirmation, true, _copy(&"ui.gacha.aligning_short", "ALIGNING…"))
	_pull_button.disabled = true
	_status_label.text = _copy(&"ui.gacha.aligning", "Aligning the reliquary signal…")
	var committed: Dictionary = _game.call("pull_premium_hero")
	if not committed.get("accepted", false):
		DialogType.set_pending(_pull_confirmation, false)
		DialogType.hide_dialog(_pull_confirmation)
		_status_label.text = _error_copy(StringName(committed.get("error_code", &"unknown_error")))
		_refresh()
		return
	DialogType.set_pending(_pull_confirmation, false)
	DialogType.hide_dialog(_pull_confirmation)
	var result: Dictionary = committed.get("result", {})
	var pull: Dictionary = result.get("premium_pull", {})
	_refresh()
	_begin_reveal(pull)


func _begin_reveal(pull: Dictionary) -> void:
	_pending_pull = pull.duplicate(true)
	_is_revealing = true
	_pull_button.disabled = true
	_back_button.disabled = true
	var premium_id := String(pull.get("premium_id", ""))
	var row := _pool_row(premium_id)
	var callsign := String(row.get("callsign", pull.get("premium_id", "Unknown Signal")))
	var rarity := int(pull.get("rarity", row.get("rarity", 4)))
	var accent := Style.GOLD if rarity == FIVE_STAR_RARITY else Style.CYAN
	_reveal_layer.visible = true
	_reveal_layer.modulate.a = 0.0
	_reveal_shade.color = Color(0.035, 0.025, 0.01, 0.96) if rarity == FIVE_STAR_RARITY else Color(0.01, 0.025, 0.05, 0.94)
	_reveal_panel.scale = Vector2(0.96, 0.96)
	_reveal_panel.modulate = Color(1, 1, 1, 0)
	_reveal_portrait.texture = Art.texture(StringName(row.get("portrait_asset_id", "")))
	_reveal_portrait.modulate = Color.WHITE
	_reveal_eyebrow.text = _copy(&"ui.gacha.guarantee_fulfilled", "GUARANTEE FULFILLED") if bool(pull.get("pity_forced", false)) else _copy(&"ui.gacha.signal_acquired", "SIGNAL ACQUIRED")
	_reveal_eyebrow.add_theme_color_override(&"font_color", accent)
	_reveal_title.text = _format(&"ui.gacha.resonance_rarity", "{rarity}-STAR RESONANCE", {&"rarity": rarity})
	_reveal_title.add_theme_color_override(&"font_color", accent)
	_reveal_result.text = "%s — %s" % [callsign, _result_kind(pull)]
	_reveal_result.add_theme_color_override(&"font_color", accent)
	var lives_after := int(pull.get("lives_after", 1))
	_reveal_lives.text = _format(&"ui.gacha.lives_ready", "{count} {unit} READY", {&"count": lives_after, &"unit": _life_unit(lives_after)})
	var guarantee_after := int(pull.get("guarantee_in_after", HARD_PITY_WINDOW))
	_reveal_pity.text = _format(&"ui.gacha.next_guarantee", "Next 5-star guaranteed in {count} {unit}", {&"count": guarantee_after, &"unit": _pull_unit(guarantee_after)})
	for index: int in _reveal_stars.get_child_count():
		var star := _reveal_stars.get_child(index) as ResonanceStar
		star.set_state(accent, false)
	_reveal_burst.modulate = Color(accent.r, accent.g, accent.b, 0.8)
	_reveal_burst.rotation = -0.08
	call_deferred("_center_reveal_pivot")
	_kill_reveal_tween()
	_stop_cinematic()
	var motion_reduced := reduced_motion or bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))
	var motion_started := _cinematic_player.play_cinematic(premium_id, motion_reduced)
	if motion_started:
		var cue_id := _cinematic_player.music_id()
		if not cue_id.is_empty():
			Music.play_cue(cue_id)
	if motion_reduced:
		_reveal_layer.modulate.a = 1.0
		_cinematic_player.show_final_plate()
		_reveal_panel.modulate.a = 1.0
		_reveal_panel.scale = Vector2.ONE
		_ignite_stars(rarity)
		_skip_button.grab_focus()
		return
	_reveal_tween = create_tween()
	_reveal_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(_reveal_layer, "modulate:a", 1.0, 0.18)
	_reveal_tween.parallel().tween_property(_reveal_burst, "rotation", 0.08, 0.56)
	_reveal_tween.tween_callback(_ignite_stars.bind(rarity))
	_reveal_tween.tween_interval(CINEMATIC_FINAL_PLATE_SECONDS - 0.56)
	_reveal_tween.tween_callback(_cinematic_player.show_final_plate)
	_reveal_tween.tween_property(_reveal_panel, "modulate:a", 1.0, 0.16)
	_reveal_tween.parallel().tween_property(
		_reveal_panel, "scale", Vector2.ONE, CINEMATIC_RESULT_RISE_SECONDS,
	).set_trans(Tween.TRANS_BACK)
	_reveal_tween.tween_interval(CINEMATIC_RESULT_SETTLE_SECONDS)
	_reveal_tween.tween_callback(_skip_button.grab_focus)


func _ignite_stars(rarity: int) -> void:
	for index: int in _reveal_stars.get_child_count():
		var star := _reveal_stars.get_child(index) as ResonanceStar
		var lit := index < rarity
		var color := Style.GOLD if rarity == FIVE_STAR_RARITY else Style.CYAN
		star.set_state(color, lit)


func _finish_reveal() -> void:
	if not _is_revealing:
		return
	_kill_reveal_tween()
	_stop_cinematic()
	var final_copy := _result_copy(_pending_pull)
	_is_revealing = false
	_reveal_layer.visible = false
	_reveal_layer.modulate.a = 0.0
	_pending_pull = {}
	_refresh()
	_status_label.text = final_copy
	_pull_button.grab_focus()


func _kill_reveal_tween() -> void:
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	_reveal_tween = null


func _stop_cinematic() -> void:
	if _cinematic_player != null:
		_cinematic_player.stop()
	if String(Music.current_id()).begins_with("gacha_"):
		Music.stop()
		Music.play_staging(&"lunaris")


func _center_reveal_pivot() -> void:
	if _reveal_panel != null:
		_reveal_panel.pivot_offset = _reveal_panel.size * 0.5


func _result_kind(pull: Dictionary) -> String:
	if bool(pull.get("new_hero", false)):
		return _copy(&"ui.gacha.result_new", "NEW HERO")
	if bool(pull.get("revived", false)):
		return _copy(&"ui.gacha.result_revived", "REVIVED")
	return _copy(&"ui.gacha.result_life", "LIFE +1")


func _result_copy(pull: Dictionary) -> String:
	var callsign := _callsign_for(String(pull.get("premium_id", "")))
	var rarity := int(pull.get("rarity", 4))
	var guarantee := int(pull.get("guarantee_in_after", HARD_PITY_WINDOW))
	var prefix := _format(&"ui.gacha.rarity_short", "{rarity}-STAR", {&"rarity": rarity})
	if bool(pull.get("new_hero", false)):
		return _format(&"ui.gacha.receipt_new", "{rarity} SIGNAL — {callsign} joins with 1 life. Next 5-star in {guarantee} pulls.", {&"rarity": prefix, &"callsign": callsign, &"guarantee": guarantee})
	if bool(pull.get("revived", false)):
		return _format(&"ui.gacha.receipt_restored", "{rarity} RESTORED — {callsign} returns with 1 life. Next 5-star in {guarantee} pulls.", {&"rarity": prefix, &"callsign": callsign, &"guarantee": guarantee})
	return _format(&"ui.gacha.receipt_duplicate", "{rarity} DUPLICATE — {callsign} gains +1 life ({lives} total). Next 5-star in {guarantee} pulls.", {&"rarity": prefix, &"callsign": callsign, &"lives": int(pull.get("lives_after", 0)), &"guarantee": guarantee})


func _pool_row(premium_id: String) -> Dictionary:
	if _game == null or _game.get("campaign") == null:
		return {}
	for row: Dictionary in _game.get("campaign").runtime_projection()["premium_pool"]:
		if row["premium_id"] == premium_id:
			return row
	return {}


func _callsign_for(premium_id: String) -> String:
	return String(_pool_row(premium_id).get("callsign", premium_id))


func _class_name(class_id: String) -> String:
	var path := "res://data/classes/%s.tres" % class_id
	var definition := load(path) as ClassDefType if ResourceLoader.exists(path) else null
	return definition.name if definition != null else class_id.replace("_", " ").capitalize()


func _error_copy(code: StringName) -> String:
	match code:
		&"insufficient_marks": return _copy(&"ui.gacha.error.insufficient_marks", "Not enough Marks for another resonance pull.")
		&"attempt_pending": return _copy(&"ui.gacha.error.attempt_pending", "Resolve the active operation before using the reliquary.")
		&"premium_life_cap": return _copy(&"ui.gacha.error.life_cap", "This hero has reached the maximum stored-life count.")
		&"campaign_inactive": return _copy(&"ui.gacha.error.campaign_inactive", "No active campaign is available.")
		_: return _format(&"ui.gacha.error.unknown", "The resonance failed safely ({code}). Please try again.", {&"code": String(code)})


func _pull_unit(count: int) -> String:
	return _copy(&"ui.gacha.pull_singular", "pull") if count == 1 else _copy(&"ui.gacha.pull_plural", "pulls")


func _life_unit(count: int) -> String:
	return _copy(&"ui.gacha.life_singular", "LIFE") if count == 1 else _copy(&"ui.gacha.life_plural", "LIVES")


func _copy(key: StringName, fallback: String) -> String:
	return UiCopyType.text(key, fallback)


func _format(key: StringName, fallback: String, args: Dictionary) -> String:
	return UiCopyType.format_text(key, fallback, args)


func _on_back_pressed() -> void:
	if _is_revealing:
		_finish_reveal()
		return
	if _game != null and _game.has_method("open_staging"):
		_game.call("open_staging")


func _label(text: String, role: StringName) -> Label:
	var label := Label.new()
	label.text = text
	Style.apply_label(label, role)
	return label
