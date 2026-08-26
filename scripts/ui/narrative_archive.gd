extends Control

## Progression-gated canon archive. Unlocks derive from authoritative stage stars;
## no parallel story save state is introduced.

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaScreenShellType := preload("res://scripts/ui/components/aetheria_screen_shell.gd")
const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const NarrativeArchiveUnlocksType := preload("res://scripts/ui/components/narrative_archive_unlocks.gd")
const ArchiveAudioLogPlayerType := preload(
	"res://scripts/ui/components/archive_audio_log_player.gd"
)
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")

const PROTOS_ART := preload("res://assets/narrative/mercy-equation/protos-ai-avatar.jpg")
const CHOIR_ART := preload("res://assets/narrative/mercy-equation/custodian-machine-castes.jpg")
const EQUATION_ART := preload("res://assets/narrative/mercy-equation/mercy-equation-key-art.jpg")
const GARDEN_ART := preload("res://assets/narrative/mercy-equation/the-first-garden.jpg")

const ENTRIES: Array[Dictionary] = [
	{&"id": &"stewardship", &"unlock_stage": 0, &"texture": PROTOS_ART},
	{&"id": &"choir", &"unlock_stage": 2, &"texture": CHOIR_ART},
	{&"id": &"equation", &"unlock_stage": 5, &"texture": EQUATION_ART},
	{&"id": &"garden", &"unlock_stage": 7, &"texture": GARDEN_ART},
]

var _shell: AetheriaScreenShellType = null
var _header: GridContainer = null
var _body: GridContainer = null
var _record_panel: PanelContainer = null
var _detail_panel: PanelContainer = null
var _record_list: VBoxContainer = null
var _progress: AetheriaLabelType = null
var _art: TextureRect = null
var _eyebrow: AetheriaLabelType = null
var _title: AetheriaLabelType = null
var _subtitle: AetheriaLabelType = null
var _body_copy: AetheriaLabelType = null
var _quote: AetheriaLabelType = null
var _audio_log: ArchiveAudioLogPlayer = null
var _back: AetheriaButtonType = null
var _record_buttons: Array[Button] = []
var _selected_index := 0


func _ready() -> void:
	Game.content = self
	Style.add_backdrop(self, GARDEN_ART)
	_shell = SHELL_SCENE.instantiate() as AetheriaScreenShellType
	_shell.name = "MercyArchiveShell"
	_shell.full_safe_area = true
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)

	var column := VBoxContainer.new()
	column.name = "MercyArchiveColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 14)
	_shell.content_host().add_child(column)
	_build_header(column)
	_build_body(column)
	_populate_records()
	_on_layout_mode_changed(_shell.layout_mode())


func _build_header(column: VBoxContainer) -> void:
	_header = GridContainer.new()
	_header.name = "MercyArchiveHeader"
	_header.columns = 3
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_theme_constant_override(&"h_separation", 16)
	_header.add_theme_constant_override(&"v_separation", 10)
	column.add_child(_header)

	var identity := HBoxContainer.new()
	identity.name = "ArchiveIdentity"
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override(&"separation", 12)
	identity.add_child(FactionHeraldryType.make_symbol(FactionHeraldryType.ACTIVE_FACTION, 48.0))
	var headings := VBoxContainer.new()
	headings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	headings.add_child(_label(
		"ArchiveEyebrow",
		UiCopyType.text(&"ui.archive.eyebrow", "LUNARIS RELIQUARY · RESTRICTED HISTORY"),
		&"dense_detail",
	))
	headings.add_child(_label(
		"ArchiveTitle",
		UiCopyType.text(&"ui.archive.title", "Mercy Archive").to_upper(),
		&"title",
	))
	identity.add_child(headings)
	_header.add_child(identity)

	_progress = _label("ArchiveProgress", "", &"dense_heading")
	_progress.name = "ArchiveProgress"
	_progress.custom_minimum_size.x = 250.0
	_progress.autowrap_mode = TextServer.AUTOWRAP_OFF
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header.add_child(_progress)

	_back = AetheriaButtonType.new()
	_back.name = "BackToCompanyCommand"
	_back.custom_minimum_size = Vector2(240.0, 64.0)
	_back.apply_role(&"secondary")
	_back.text = UiCopyType.text(&"ui.archive.back", "Return to Company Command")
	_back.set_presentation_text(_back.text, UiCopyType.text(&"ui.common.back", "Back").to_upper())
	_back.apply_compact_action_layout()
	_back.tooltip_text = _back.text
	_back.pressed.connect(_on_back)
	_header.add_child(_back)

	var rule := ColorRect.new()
	rule.name = "ArchiveRule"
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	rule.color = Color(Style.CYAN, 0.52)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rule)
	var intro := _label(
		"ArchiveIntro",
		UiCopyType.text(
			&"ui.archive.intro",
			"Recovered records explain why PROTOS calls extinction mercy. Clear operations to decrypt the complete history.",
		),
		&"body",
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(intro)


func _build_body(column: VBoxContainer) -> void:
	_body = GridContainer.new()
	_body.name = "MercyArchiveBody"
	_body.columns = 2
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override(&"h_separation", 16)
	_body.add_theme_constant_override(&"v_separation", 14)
	column.add_child(_body)

	_record_panel = PanelContainer.new()
	_record_panel.name = "ArchiveRecordPanel"
	_record_panel.custom_minimum_size.x = 380.0
	_record_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_record_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Style.apply_panel(_record_panel, &"quiet")
	_body.add_child(_record_panel)
	var record_scroll := ScrollContainer.new()
	record_scroll.name = "ArchiveRecordScroll"
	record_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	record_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	record_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_record_panel.add_child(record_scroll)
	_record_list = VBoxContainer.new()
	_record_list.name = "ArchiveRecordList"
	_record_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_record_list.add_theme_constant_override(&"separation", 9)
	record_scroll.add_child(_record_list)

	_detail_panel = PanelContainer.new()
	_detail_panel.name = "ArchiveDetailPanel"
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_panel.size_flags_stretch_ratio = 2.0
	_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Style.apply_panel(_detail_panel, &"result")
	_body.add_child(_detail_panel)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.name = "ArchiveDetailScroll"
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.follow_focus = true
	_detail_panel.add_child(detail_scroll)
	var detail := VBoxContainer.new()
	detail.name = "ArchiveDetailContent"
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override(&"separation", 9)
	detail_scroll.add_child(detail)

	_art = TextureRect.new()
	_art.name = "ArchiveConceptArt"
	_art.custom_minimum_size = Vector2(0.0, 300.0)
	_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(_art)
	_eyebrow = _label("RecordEyebrow", "", &"dense_detail")
	_title = _label("RecordTitle", "", &"title")
	_subtitle = _label("RecordSubtitle", "", &"heading")
	_body_copy = _label("RecordBody", "", &"body")
	_quote = _label("RecordQuote", "", &"detail")
	for label: AetheriaLabelType in [_eyebrow, _title, _subtitle, _body_copy, _quote]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_child(label)
	_audio_log = ArchiveAudioLogPlayerType.new() as ArchiveAudioLogPlayer
	detail.add_child(_audio_log)


func _populate_records() -> void:
	var unlocked_count := 0
	for index: int in ENTRIES.size():
		var entry := ENTRIES[index]
		var unlocked := _is_unlocked(entry)
		if unlocked:
			unlocked_count += 1
		var button := AetheriaButtonType.new()
		button.name = "ArchiveRecord_%02d" % (index + 1)
		button.custom_minimum_size = Vector2(0.0, 72.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not unlocked
		button.focus_mode = Control.FOCUS_ALL if unlocked else Control.FOCUS_NONE
		var title_text := _entry_text(entry, &"title", "Record")
		button.text = (
			"%02d · %s" % [index + 1, title_text]
			if unlocked
			else "%02d · %s" % [index + 1, UiCopyType.text(&"ui.archive.locked", "ENCRYPTED RECORD")]
		)
		var presentation := button.text.to_upper()
		if not unlocked:
			presentation += "\n" + UiCopyType.format_text(
				&"ui.archive.unlock_requirement",
				"CLEAR OPERATION {index} TO DECRYPT",
				{&"index": int(entry[&"unlock_stage"])},
			)
		button.apply_role(&"secondary" if unlocked else &"disabled")
		button.set_presentation_text(button.text, presentation)
		button.apply_compact_action_layout()
		button.tooltip_text = button.text
		if unlocked:
			button.focus_entered.connect(_show_record.bind(index))
			button.mouse_entered.connect(_show_record.bind(index))
			button.pressed.connect(_show_record.bind(index))
		_record_list.add_child(button)
		_record_buttons.append(button)
	_progress.text = UiCopyType.format_text(
		&"ui.archive.records",
		"{unlocked} / {total} RECORDS DECRYPTED",
		{&"unlocked": unlocked_count, &"total": ENTRIES.size()},
	)
	_show_record(0)
	_wire_focus()


func _show_record(index: int) -> void:
	if index < 0 or index >= ENTRIES.size() or not _is_unlocked(ENTRIES[index]):
		return
	_selected_index = index
	var entry := ENTRIES[index]
	_art.texture = entry[&"texture"] as Texture2D
	_art.tooltip_text = _entry_text(entry, &"title", "Archive concept")
	_eyebrow.text = _entry_text(entry, &"eyebrow", "ARCHIVE RECORD")
	_title.text = _entry_text(entry, &"title", "Record").to_upper()
	_subtitle.text = _entry_text(entry, &"subtitle", "")
	_body_copy.text = _entry_text(entry, &"body", "")
	_quote.text = _entry_text(entry, &"quote", "")
	if _audio_log != null:
		_audio_log.set_entry(entry[&"id"])
	for button_index: int in _record_buttons.size():
		var button := _record_buttons[button_index] as AetheriaButtonType
		if not button.disabled:
			button.apply_role(&"selected" if button_index == _selected_index else &"secondary")


func _entry_text(entry: Dictionary, field: StringName, fallback: String) -> String:
	return UiCopyType.text(
		StringName("ui.archive.entry.%s.%s" % [entry[&"id"], field]),
		fallback,
	)


func _is_unlocked(entry: Dictionary) -> bool:
	var stars: Dictionary = Game.campaign_projection().get("stage_stars", {})
	return NarrativeArchiveUnlocksType.record_unlocked(int(entry[&"unlock_stage"]), stars)


func _wire_focus() -> void:
	var focusable: Array[Control] = []
	for button: Button in _record_buttons:
		if not button.disabled:
			focusable.append(button)
	if _audio_log != null:
		focusable.append_array(_audio_log.focus_controls())
	focusable.append(_back)
	for index: int in focusable.size():
		var current := focusable[index]
		var previous := focusable[(index - 1 + focusable.size()) % focusable.size()]
		var following := focusable[(index + 1) % focusable.size()]
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(following)
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_neighbor_bottom = current.get_path_to(following)
	if not focusable.is_empty():
		focusable[0].grab_focus.call_deferred()


func _on_layout_mode_changed(mode: StringName) -> void:
	var portrait := mode == &"portrait"
	var short_landscape := not portrait and get_viewport_rect().size.y <= 800.0
	if _header != null:
		_header.columns = 1 if portrait else 3
	if _body != null:
		_body.columns = 1 if portrait else 2
	if _record_panel != null:
		_record_panel.custom_minimum_size = Vector2(0.0 if portrait else 380.0, 260.0 if portrait else 0.0)
	if _detail_panel != null:
		_detail_panel.custom_minimum_size = Vector2(0.0, 520.0 if portrait else 0.0)
	if _art != null:
		_art.custom_minimum_size.y = 230.0 if portrait else (190.0 if short_landscape else 300.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()


func _on_back() -> void:
	Sfx.play("ui_back")
	Game.open_staging()


func _label(node_name: String, text_value: String, role: StringName) -> AetheriaLabelType:
	var label := AetheriaLabelType.new()
	label.name = node_name
	label.text = text_value
	label.apply_role(role)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
