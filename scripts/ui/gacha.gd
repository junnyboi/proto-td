class_name PremiumGachaScreen
extends Control

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const ClassDefType := preload("res://data/class_def.gd")

var _game: Node
var _marks_label: Label
var _pull_button: Button
var _status_label: Label
var _hero_grid: GridContainer
var _header_grid: GridContainer
var _action_grid: GridContainer
var _screen_margin: MarginContainer


func _ready() -> void:
	_game = get_node_or_null("/root/Game")
	if _game != null:
		_game.set("content", self)
	Style.add_backdrop(self)
	_build_screen()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_refresh()


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
	var back := Button.new()
	back.name = "BackButton"
	back.text = "← COMMAND DECK"
	back.pressed.connect(_on_back_pressed)
	Style.apply_button(back, &"quiet")
	_header_grid.add_child(back)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_grid.add_child(title_box)
	title_box.add_child(_label("LUNARIS RELIQUARY", &"eyebrow"))
	title_box.add_child(_label("Premium Resonance", &"title"))
	_marks_label = _label("0 MARKS", &"metric")
	_marks_label.name = "MarksLabel"
	_marks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_grid.add_child(_marks_label)

	var intro := PanelContainer.new()
	Style.apply_panel(intro, &"quiet")
	content.add_child(intro)
	var intro_text := _label(
		"Every successful resonance pull grants one life to the selected premium hero. "
		+ "Premium heroes keep fixed elite kits and cannot be trained. When their last life "
		+ "is spent, they remain unavailable until another copy is pulled.",
		&"body",
	)
	intro_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_child(intro_text)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_hero_grid = GridContainer.new()
	_hero_grid.name = "PremiumHeroGrid"
	_hero_grid.columns = 3
	_hero_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hero_grid.add_theme_constant_override(&"h_separation", 16)
	_hero_grid.add_theme_constant_override(&"v_separation", 16)
	scroll.add_child(_hero_grid)

	_action_grid = GridContainer.new()
	_action_grid.columns = 2
	_action_grid.add_theme_constant_override(&"h_separation", 18)
	_action_grid.add_theme_constant_override(&"v_separation", 10)
	content.add_child(_action_grid)
	_status_label = _label("The pool is ready.", &"detail")
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


func _refresh() -> void:
	if _game == null or not bool(_game.get("campaign_active")) or _game.get("campaign") == null:
		_marks_label.text = "CAMPAIGN OFFLINE"
		_pull_button.text = "PULL UNAVAILABLE"
		_pull_button.disabled = true
		Style.apply_button(_pull_button, &"disabled")
		_status_label.text = "Start or continue a campaign to access premium resonance."
		return
	var projection: Dictionary = _game.get("campaign").runtime_projection()
	var marks := int(projection["marks"])
	var cost := int(projection["premium_pull_cost"])
	_marks_label.text = "%d MARKS" % marks
	_pull_button.text = "RESONATE • %d MARKS" % cost
	var attempt_pending := bool(projection.get("attempt_pending", false))
	_pull_button.disabled = marks < cost or attempt_pending
	Style.apply_button(_pull_button, &"disabled" if _pull_button.disabled else &"gold")
	if attempt_pending:
		_status_label.text = "Resolve the active operation before using premium resonance."
	elif marks < cost:
		_status_label.text = "Earn %d more Marks for another resonance pull." % (cost - marks)
	_rebuild_cards(projection)


func _rebuild_cards(projection: Dictionary) -> void:
	for child: Node in _hero_grid.get_children():
		child.queue_free()
	var owned := {}
	for hero: Dictionary in projection["premium_heroes"]:
		owned[String(hero["premium_id"])] = hero
	for row: Dictionary in projection["premium_pool"]:
		_hero_grid.add_child(_hero_card(row, owned.get(String(row["premium_id"]), {})))


func _hero_card(catalog: Dictionary, hero: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Premium_%s" % catalog["premium_id"]
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(280, 360)
	Style.apply_panel(panel, &"danger" if not hero.is_empty() and hero["life_status"] == "dead" else &"quiet")
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 9)
	panel.add_child(box)
	var portrait := TextureRect.new()
	portrait.texture = Art.texture(StringName(catalog["portrait_asset_id"]))
	portrait.custom_minimum_size = Vector2(220, 210)
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
	var status := "UNACQUIRED"
	var detail := "Pull to recruit • Fixed elite kit"
	if not hero.is_empty():
		var lives := int(hero["premium_lives"])
		status = "%d %s" % [lives, "LIFE" if lives == 1 else "LIVES"]
		detail = "%d total copies • Fixed elite kit" % int(hero["premium_pull_count"])
		if lives == 0:
			status = "LOCKED • 0 LIVES"
			detail = "Pull this hero again to restore deployment"
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
	_marks_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
	)
	var side_margin := 18 if portrait else 42
	_screen_margin.add_theme_constant_override(&"margin_left", side_margin)
	_screen_margin.add_theme_constant_override(&"margin_right", side_margin)
	_pull_button.custom_minimum_size.x = 0 if portrait else 280


func _on_pull_pressed() -> void:
	_pull_button.disabled = true
	_status_label.text = "Aligning the reliquary signal…"
	var committed: Dictionary = _game.call("pull_premium_hero")
	if not committed.get("accepted", false):
		_status_label.text = _error_copy(StringName(committed.get("error_code", &"unknown_error")))
		_refresh()
		return
	var result: Dictionary = committed.get("result", {})
	var pull: Dictionary = result.get("premium_pull", {})
	var callsign := _callsign_for(String(pull.get("premium_id", "")))
	if bool(pull.get("new_hero", false)):
		_status_label.text = "SIGNAL ACQUIRED — %s joins with 1 life." % callsign
	elif bool(pull.get("revived", false)):
		_status_label.text = "RESONANCE RESTORED — %s returns with 1 life." % callsign
	else:
		_status_label.text = "DUPLICATE RESONANCE — %s gains +1 life (%d total)." % [
			callsign, int(pull.get("lives_after", 0)),
		]
	_refresh()


func _callsign_for(premium_id: String) -> String:
	if _game == null or _game.get("campaign") == null:
		return premium_id
	for row: Dictionary in _game.get("campaign").runtime_projection()["premium_pool"]:
		if row["premium_id"] == premium_id:
			return String(row["callsign"])
	return premium_id


func _class_name(class_id: String) -> String:
	var path := "res://data/classes/%s.tres" % class_id
	var definition := load(path) as ClassDefType if ResourceLoader.exists(path) else null
	return definition.name if definition != null else class_id.replace("_", " ").capitalize()


func _error_copy(code: StringName) -> String:
	match code:
		&"insufficient_marks": return "Not enough Marks for another resonance pull."
		&"attempt_pending": return "Resolve the active operation before using the reliquary."
		&"premium_life_cap": return "This hero has reached the maximum stored-life count."
		&"campaign_inactive": return "No active campaign is available."
		_: return "The resonance failed safely (%s). Please try again." % String(code)


func _on_back_pressed() -> void:
	if _game != null and _game.has_method("open_staging"):
		_game.call("open_staging")


func _label(text: String, role: StringName) -> Label:
	var label := Label.new()
	label.text = text
	Style.apply_label(label, role)
	return label
