class_name AetheriaLocaleSelector
extends BoxContainer

signal locale_selected(locale_id: StringName)

var _presentation: AetheriaLabel = null

@onready var _label: Label = $LocaleLabel
@onready var _list: ItemList = $LocaleList


func _ready() -> void:
	add_theme_constant_override(&"separation", 16)
	_list.custom_minimum_size = Vector2(360.0, 72.0)
	_list.focus_mode = Control.FOCUS_ALL
	_list.select_mode = ItemList.SELECT_SINGLE
	for color_name: StringName in [
		&"font_color", &"font_hovered_color", &"font_selected_color",
		&"font_hovered_selected_color",
	]:
		_list.add_theme_color_override(color_name, Color.TRANSPARENT)
	_presentation = AetheriaLabel.new()
	_presentation.name = "PresentationLabel"
	_presentation.apply_role(&"body")
	_presentation.add_theme_color_override(
		&"font_color", AetheriaTheme.COLORS[&"dark_ink"],
	)
	_presentation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_presentation.clip_text = true
	_presentation.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_presentation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_presentation.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_list.add_child(_presentation)
	_list.item_selected.connect(_on_item_selected)
	refresh()


func set_vertical_layout(enabled: bool) -> void:
	vertical = enabled


func refresh() -> bool:
	var locales := I18n.supported_locales()
	var active := I18n.locale()
	if locales.is_empty() or not locales.has(String(active)):
		return false
	_label.text = UiCopy.text(&"ui.locale.label", "Language")
	_list.clear()
	var active_display := ""
	for locale_text: String in locales:
		var locale_id := StringName(locale_text)
		var display := locale_text
		if locale_id == &"en-US":
			display = UiCopy.text(&"ui.locale.en_us", "English (US)")
		_list.add_item(display)
		_list.set_item_metadata(_list.item_count - 1, locale_id)
		if locale_id == active:
			_list.select(_list.item_count - 1)
			active_display = display
	_presentation.text = active_display
	return true


func select_locale(locale_id: StringName) -> bool:
	var previous := I18n.locale()
	if not I18n.set_locale(locale_id):
		return false
	refresh()
	if locale_id != previous:
		locale_selected.emit(locale_id)
	return true


func _on_item_selected(index: int) -> void:
	var locale_id: Variant = _list.get_item_metadata(index)
	if typeof(locale_id) != TYPE_STRING_NAME:
		return
	select_locale(locale_id)
