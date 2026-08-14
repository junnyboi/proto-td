class_name AetheriaLocaleSelector
extends BoxContainer

signal locale_selected(locale_id: StringName)

const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")

@onready var _label: Label = $LocaleLabel
@onready var _list: ItemList = $LocaleList


func _ready() -> void:
	add_theme_constant_override(&"separation", 16)
	_list.custom_minimum_size = Vector2(360.0, 90.0)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.focus_mode = Control.FOCUS_ALL
	_list.select_mode = ItemList.SELECT_SINGLE
	_list.max_columns = 2
	_list.same_column_width = true
	_list.item_selected.connect(_on_item_selected)
	refresh()


func set_vertical_layout(enabled: bool) -> void:
	vertical = enabled


func refresh() -> bool:
	var locales := I18n.supported_locales()
	var active := I18n.locale()
	if locales.is_empty() or not locales.has(String(active)):
		return false
	_label.text = UiCopyType.text(&"ui.locale.label", "Language")
	_list.clear()
	for locale_text: String in locales:
		var locale_id := StringName(locale_text)
		var display := locale_text
		if locale_id == &"en-US":
			display = UiCopyType.text(&"ui.locale.en_us", "EN")
		elif locale_id == &"zh-CN":
			display = UiCopyType.text(&"ui.locale.zh_cn", "中文")
		_list.add_item(display)
		_list.set_item_metadata(_list.item_count - 1, locale_id)
		if locale_id == active:
			_list.select(_list.item_count - 1)
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
