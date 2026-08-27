class_name GachaHistoryDrawer
extends Control

signal close_requested
signal closed

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const PremiumPortraitEntranceType := preload("res://scripts/ui/components/premium_portrait_entrance.gd")
const ASTRAL_STAR := preload("res://assets/ui/gacha/astral_star.png")
const HISTORY_ICON_ID := &"ui_gacha_moon_archive"
const MAX_DRAWER_WIDTH := 430.0
const OPEN_SECONDS := 0.24
const CLOSE_SECONDS := 0.18
const PREMIUM_PORTRAITS := {
	"archive_caster": &"portrait_archive_caster",
	"lunaris_vessel": &"portrait_lunaris_vessel",
	"reliquary_duelist": &"portrait_reliquary_duelist",
}

var reduced_motion := false
var _projection: Dictionary = {}
var _scrim: ColorRect
var _drawer: PanelContainer
var _header: BoxContainer
var _header_icon: TextureRect
var _title_stack: VBoxContainer
var _title: Label
var _summary: Label
var _close_button: Button
var _scroll: ScrollContainer
var _rows: VBoxContainer
var _empty_state: VBoxContainer
var _empty_title: Label
var _empty_detail: Label
var _transition: Tween
var _open := false
var _closing := false


func _ready() -> void:
	_build()
	visible = false
	focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()


func present(projection: Dictionary) -> void:
	_projection = projection.duplicate(true)
	_rebuild_rows()
	_open = true
	_closing = false
	visible = true
	focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED
	_apply_layout()
	_kill_transition()
	modulate.a = 1.0 if reduced_motion else 0.0
	_drawer.offset_transform_position.x = 0.0 if reduced_motion else _drawer_transition_distance()
	if reduced_motion:
		_close_button.grab_focus.call_deferred()
		return
	_transition = create_tween()
	_transition.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_transition.tween_property(self, "modulate:a", 1.0, OPEN_SECONDS)
	_transition.parallel().tween_property(
		_drawer, "offset_transform_position:x", 0.0, OPEN_SECONDS,
	)
	_transition.finished.connect(_close_button.grab_focus, CONNECT_ONE_SHOT)


func dismiss() -> void:
	if not _open or _closing:
		return
	_closing = true
	focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	_kill_transition()
	if reduced_motion:
		_finish_close()
		return
	_transition = create_tween()
	_transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_transition.tween_property(self, "modulate:a", 0.0, CLOSE_SECONDS)
	_transition.parallel().tween_property(
		_drawer, "offset_transform_position:x", _drawer_transition_distance(), CLOSE_SECONDS,
	)
	_transition.finished.connect(_finish_close, CONNECT_ONE_SHOT)


func force_hide() -> void:
	_kill_transition()
	_open = false
	_closing = false
	visible = false
	modulate.a = 0.0
	focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED


func refresh(projection: Dictionary) -> void:
	_projection = projection.duplicate(true)
	_rebuild_rows()


func refresh_copy() -> void:
	_title.text = _copy(&"ui.gacha.history_title", "RESONANCE HISTORY")
	_close_button.text = _copy(&"ui.gacha.close_history", "CLOSE")
	_empty_title.text = _copy(&"ui.gacha.history_empty", "NO RESONANCE RECORDS")
	_empty_detail.text = _copy(
		&"ui.gacha.history_empty_detail",
		"Completed soul-reconnection operations will appear here.",
	)
	_rebuild_rows()


func is_open() -> bool:
	return _open and not _closing


func focus_target() -> Control:
	return _close_button


func _build() -> void:
	name = "PremiumPullHistoryLayer"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 90
	mouse_filter = Control.MOUSE_FILTER_STOP
	accessibility_name = _copy(&"ui.gacha.history_title", "RESONANCE HISTORY")

	_scrim = ColorRect.new()
	_scrim.name = "PullHistoryScrim"
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim.color = Color(0.0, 0.015, 0.03, 0.72)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.gui_input.connect(_on_scrim_input)
	add_child(_scrim)

	_drawer = PanelContainer.new()
	_drawer.name = "MoonArchiveDrawer"
	_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	Style.apply_panel(_drawer, &"screen")
	var drawer_style := _drawer.get_theme_stylebox(&"panel").duplicate() as StyleBox
	drawer_style.content_margin_left = 22.0
	drawer_style.content_margin_top = 22.0
	drawer_style.content_margin_right = 22.0
	drawer_style.content_margin_bottom = 22.0
	_drawer.add_theme_stylebox_override(&"panel", drawer_style)
	add_child(_drawer)

	var stack := VBoxContainer.new()
	stack.name = "MoonArchiveContent"
	stack.add_theme_constant_override(&"separation", 14)
	_drawer.add_child(stack)

	_header = BoxContainer.new()
	_header.name = "MoonArchiveHeader"
	_header.vertical = false
	_header.add_theme_constant_override(&"separation", 12)
	stack.add_child(_header)
	_header_icon = TextureRect.new()
	_header_icon.name = "MoonArchiveGlyph"
	_header_icon.texture = Art.texture(HISTORY_ICON_ID)
	_header_icon.custom_minimum_size = Vector2(68, 68)
	_header_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_header_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_header_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(_header_icon)
	_title_stack = VBoxContainer.new()
	_title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	_title_stack.add_theme_constant_override(&"separation", 0)
	_header.add_child(_title_stack)
	_title = _label(_copy(&"ui.gacha.history_title", "RESONANCE HISTORY"), &"heading")
	_title.name = "MoonArchiveTitle"
	_title.add_theme_font_size_override(&"font_size", 36)
	_title_stack.add_child(_title)
	_summary = _label("", &"detail")
	_summary.name = "MoonArchiveSummary"
	_summary.add_theme_font_size_override(&"font_size", 21)
	_summary.accessibility_live = AccessibilityServer.LIVE_POLITE
	_title_stack.add_child(_summary)
	_close_button = Button.new()
	_close_button.name = "ClosePullHistoryButton"
	_close_button.text = _copy(&"ui.gacha.close_history", "CLOSE")
	_close_button.custom_minimum_size = Vector2(116, 58)
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.autowrap_mode = TextServer.AUTOWRAP_OFF
	_close_button.clip_text = false
	_close_button.pressed.connect(_request_close)
	Style.apply_button(_close_button, &"quiet")
	_close_button.add_theme_font_size_override(&"font_size", 24)
	_header.add_child(_close_button)
	var close_path := NodePath(".")
	_close_button.focus_next = close_path
	_close_button.focus_previous = close_path
	_close_button.focus_neighbor_left = close_path
	_close_button.focus_neighbor_top = close_path
	_close_button.focus_neighbor_right = close_path
	_close_button.focus_neighbor_bottom = close_path

	var rule := ColorRect.new()
	rule.name = "MoonArchiveRule"
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = Color(Style.GOLD, 0.74)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(rule)

	_scroll = ScrollContainer.new()
	_scroll.name = "PullHistoryScroll"
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.follow_focus = true
	stack.add_child(_scroll)
	_rows = VBoxContainer.new()
	_rows.name = "PullHistoryRows"
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override(&"separation", 10)
	_scroll.add_child(_rows)

	_empty_state = VBoxContainer.new()
	_empty_state.name = "PullHistoryEmptyState"
	_empty_state.alignment = BoxContainer.ALIGNMENT_CENTER
	_empty_state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_empty_state.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty_state.custom_minimum_size.y = 320.0
	_empty_state.add_theme_constant_override(&"separation", 12)
	_rows.add_child(_empty_state)
	var empty_icon := TextureRect.new()
	empty_icon.texture = Art.texture(HISTORY_ICON_ID)
	empty_icon.custom_minimum_size = Vector2(96, 96)
	empty_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	empty_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	empty_icon.modulate = Color(1, 1, 1, 0.55)
	empty_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_empty_state.add_child(empty_icon)
	_empty_title = _label(_copy(&"ui.gacha.history_empty", "NO RESONANCE RECORDS"), &"heading")
	_empty_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_title.add_theme_font_size_override(&"font_size", 27)
	_empty_state.add_child(_empty_title)
	_empty_detail = _label(
		_copy(&"ui.gacha.history_empty_detail", "Completed soul-reconnection operations will appear here."),
		&"detail",
	)
	_empty_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty_state.add_child(_empty_detail)


func _rebuild_rows() -> void:
	if _rows == null:
		return
	for child: Node in _rows.get_children():
		if child != _empty_state:
			child.free()
	var history: Array = _projection.get("premium_pull_history", [])
	var total := int(_projection.get("premium_pull_history_total", history.size()))
	_summary.text = _format(
		&"ui.gacha.history_summary", "{count} COMPLETED RESONANCES", {&"count": total},
	)
	_empty_state.visible = history.is_empty()
	accessibility_description = _summary.text
	if history.is_empty():
		return
	for history_index: int in history.size():
		var raw: Variant = history[history_index]
		if raw is Dictionary:
			_rows.add_child(_history_row(raw as Dictionary, history_index))
	_rows.move_child(_empty_state, _rows.get_child_count() - 1)


func _history_row(receipt: Dictionary, entrance_index: int = 0) -> Control:
	var five_star := int(receipt.get("rarity", 4)) == 5
	var panel := PanelContainer.new()
	panel.name = "HistoryPull_%04d" % (int(receipt.get("pull_index", 0)) + 1)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 136.0
	Style.apply_panel(panel, &"selected" if five_star else &"quiet")
	var panel_style := panel.get_theme_stylebox(&"panel").duplicate() as StyleBox
	panel_style.content_margin_left = 12.0
	panel_style.content_margin_top = 12.0
	panel_style.content_margin_right = 12.0
	panel_style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override(&"panel", panel_style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	panel.add_child(row)
	var portrait := TextureRect.new()
	portrait.name = "HistoryPortrait"
	portrait.texture = Art.texture(_portrait_id(String(receipt.get("premium_id", ""))))
	portrait.custom_minimum_size = Vector2(76, 92)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	PremiumPortraitEntranceType.apply(
		portrait,
		_portrait_id(String(receipt.get("premium_id", ""))),
		entrance_index,
		reduced_motion,
	)

	var copy_stack := VBoxContainer.new()
	copy_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_stack.add_theme_constant_override(&"separation", 3)
	row.add_child(copy_stack)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override(&"separation", 8)
	copy_stack.add_child(title_row)
	var callsign := _callsign(String(receipt.get("premium_id", "")))
	var title := _label(callsign.to_upper(), &"heading")
	title.name = "HistoryCallsign"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.custom_minimum_size.x = 0.0
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override(&"font_size", 22)
	title_row.add_child(title)
	var ordinal := _label(
		_format(
			&"ui.gacha.history_pull", "PULL {index}",
			{&"index": int(receipt.get("pull_index", 0)) + 1},
		),
		&"detail",
	)
	ordinal.name = "HistoryPullOrdinal"
	ordinal.add_theme_font_size_override(&"font_size", 18)
	title_row.add_child(ordinal)

	var stars := HBoxContainer.new()
	stars.name = "HistoryRarityStars"
	stars.add_theme_constant_override(&"separation", 2)
	copy_stack.add_child(stars)
	for _index: int in int(receipt.get("rarity", 4)):
		var star := TextureRect.new()
		star.texture = ASTRAL_STAR
		star.custom_minimum_size = Vector2(20, 20)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.modulate = Style.GOLD
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars.add_child(star)

	var badge := _label(_history_badge(receipt), &"eyebrow")
	badge.name = "HistoryResultBadge"
	badge.add_theme_font_size_override(&"font_size", 18)
	badge.add_theme_color_override(
		&"font_color", Style.GOLD if five_star or bool(receipt.get("revived", false)) else Style.CYAN,
	)
	copy_stack.add_child(badge)
	var detail := _label(
		_format(
			&"ui.gacha.history_detail",
			"PREPARED BODIES {before} → {after} • GUARANTEE IN {guarantee}",
			{
				&"before": int(receipt.get("lives_before", 0)),
				&"after": int(receipt.get("lives_after", 0)),
				&"guarantee": int(receipt.get("guarantee_in_after", 10)),
			},
		),
		&"detail",
	)
	detail.name = "HistoryReceiptDetail"
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override(&"font_size", 18)
	copy_stack.add_child(detail)
	if bool(receipt.get("pity_forced", false)):
		var guarantee := _label(
			_copy(&"ui.gacha.history_badge_guarantee", "GUARANTEE"), &"eyebrow",
		)
		guarantee.name = "HistoryGuaranteeBadge"
		guarantee.add_theme_font_size_override(&"font_size", 16)
		guarantee.add_theme_color_override(&"font_color", Style.GOLD)
		copy_stack.add_child(guarantee)

	panel.accessibility_name = callsign
	panel.accessibility_description = "%s. %s" % [badge.text, detail.text]
	return panel


func _history_badge(receipt: Dictionary) -> String:
	if bool(receipt.get("new_hero", false)):
		return _copy(&"ui.gacha.history_badge_new", "SOUL RECONNECTED")
	if bool(receipt.get("revived", false)):
		return _copy(&"ui.gacha.history_badge_revived", "BODY RESTORED")
	return _copy(&"ui.gacha.history_badge_duplicate", "BODY PREPARED")


func _callsign(premium_id: String) -> String:
	var fallback := ""
	for raw: Variant in _projection.get("premium_pool", []):
		if raw is Dictionary and String((raw as Dictionary).get("premium_id", "")) == premium_id:
			fallback = String((raw as Dictionary).get("callsign", ""))
			break
	if fallback.is_empty():
		fallback = _copy(&"ui.gacha.unknown_signal", "Unknown soul anchor")
	return UiCopyType.premium_name(premium_id, fallback)


func _portrait_id(premium_id: String) -> StringName:
	return StringName(PREMIUM_PORTRAITS.get(premium_id, &""))


func _apply_layout() -> void:
	if _drawer == null:
		return
	var viewport_size := get_viewport_rect().size
	var portrait := viewport_size.y > viewport_size.x
	var full_width := portrait or viewport_size.x < 900.0
	var compact_header := viewport_size.x < 520.0
	var width := viewport_size.x if full_width else minf(MAX_DRAWER_WIDTH, viewport_size.x * 0.46)
	var responsive_style := Style.panel_style(&"screen")
	var content_margin := 14.0 if compact_header else 22.0
	responsive_style.content_margin_left = content_margin
	responsive_style.content_margin_top = content_margin
	responsive_style.content_margin_right = content_margin
	responsive_style.content_margin_bottom = content_margin
	_drawer.add_theme_stylebox_override(&"panel", responsive_style)
	_drawer.anchor_left = 1.0
	_drawer.anchor_top = 0.0
	_drawer.anchor_right = 1.0
	_drawer.anchor_bottom = 1.0
	_drawer.offset_left = -width
	_drawer.offset_top = 0.0
	_drawer.offset_right = 0.0
	_drawer.offset_bottom = 0.0
	if _open and not _closing:
		_drawer.offset_transform_position.x = 0.0
	_header.vertical = compact_header
	_header.alignment = BoxContainer.ALIGNMENT_CENTER if compact_header else BoxContainer.ALIGNMENT_BEGIN
	_header.add_theme_constant_override(&"separation", 8 if not compact_header else 10)
	_header_icon.custom_minimum_size = Vector2(54, 54) if compact_header else Vector2(48, 48)
	_close_button.custom_minimum_size = Vector2(0, 52) if compact_header else Vector2(82, 52)
	_close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact_header else Control.SIZE_SHRINK_END
	_close_button.add_theme_font_size_override(&"font_size", 20 if compact_header else 18)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if compact_header else HORIZONTAL_ALIGNMENT_LEFT
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if compact_header else HORIZONTAL_ALIGNMENT_LEFT
	_title.add_theme_font_size_override(&"font_size", 30 if compact_header else 27)
	_summary.add_theme_font_size_override(&"font_size", 19 if compact_header else 17)


func _drawer_transition_distance() -> float:
	return maxf(24.0, absf(_drawer.offset_left)) + 24.0


func _on_scrim_input(event: InputEvent) -> void:
	if not _open or _closing:
		return
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		_request_close()
	elif event is InputEventScreenTouch and event.pressed:
		accept_event()
		_request_close()


func _request_close() -> void:
	if _open and not _closing:
		close_requested.emit()


func _finish_close() -> void:
	_kill_transition()
	_open = false
	_closing = false
	visible = false
	modulate.a = 0.0
	focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	closed.emit()


func _kill_transition() -> void:
	if _transition != null and _transition.is_valid():
		_transition.kill()
	_transition = null


func _label(text: String, role: StringName) -> Label:
	var label := Label.new()
	label.text = text
	Style.apply_label(label, role)
	return label


func _copy(key: StringName, fallback: String) -> String:
	return UiCopyType.text(key, fallback)


func _format(key: StringName, fallback: String, args: Dictionary) -> String:
	return UiCopyType.format_text(key, fallback, args)
