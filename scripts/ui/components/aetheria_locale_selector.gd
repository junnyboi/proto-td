class_name AetheriaLocaleSelector
extends BoxContainer

signal locale_selected(locale_id: StringName)

const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const COMPACT_LABEL_MIN_HEIGHT := 72.0

var _draft_mode := false
var _selected_locale: StringName = &""
var _compact_mode := false

@onready var _label: Label = $LocaleLabel
@onready var _list: ItemList = $LocaleList


func _ready() -> void:
	add_theme_constant_override(&"separation", 8 if _compact_mode else 16)
	_label.clip_text = false
	_label.custom_minimum_size = Vector2(0.0, COMPACT_LABEL_MIN_HEIGHT if _compact_mode else 0.0)
	_list.custom_minimum_size = Vector2(0.0, 60.0 if _compact_mode else 90.0)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.focus_mode = Control.FOCUS_ALL
	_list.select_mode = ItemList.SELECT_SINGLE
	_list.max_columns = 2
	_list.same_column_width = true
	_list.item_selected.connect(_on_item_selected)
	refresh()


func set_vertical_layout(enabled: bool) -> void:
	vertical = enabled
	if _label != null:
		_label.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL if enabled else Control.SIZE_SHRINK_BEGIN
		)
		_label.autowrap_mode = TextServer.AUTOWRAP_OFF


func set_draft_mode(enabled: bool) -> void:
	_draft_mode = enabled
	if _selected_locale.is_empty():
		_selected_locale = I18n.locale()
	refresh()


func set_compact_mode(enabled: bool) -> void:
	_compact_mode = enabled
	if _label != null:
		_label.clip_text = false
		_label.custom_minimum_size = Vector2(0.0, COMPACT_LABEL_MIN_HEIGHT if enabled else 0.0)
	if is_node_ready():
		_list.custom_minimum_size = Vector2(0.0, 60.0 if enabled else 90.0)
		add_theme_constant_override(&"separation", 8 if enabled else 16)


func set_selected_locale(locale_id: StringName) -> bool:
	if not I18n.supported_locales().has(String(locale_id)):
		return false
	_selected_locale = locale_id
	return refresh()


func selected_locale() -> StringName:
	return _selected_locale if not _selected_locale.is_empty() else I18n.locale()


func locale_list() -> ItemList:
	return _list


func refresh() -> bool:
	if not is_node_ready():
		return false
	var locales := I18n.supported_locales()
	var active := selected_locale() if _draft_mode else I18n.locale()
	if locales.is_empty() or not locales.has(String(active)):
		return false
	_selected_locale = active
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
	var previous := selected_locale()
	if _draft_mode:
		if not I18n.supported_locales().has(String(locale_id)):
			return false
		_selected_locale = locale_id
		refresh()
	else:
		if not I18n.set_locale(locale_id):
			return false
		_selected_locale = I18n.locale()
		refresh()
	if locale_id != previous:
		locale_selected.emit(locale_id)
	return true


func _on_item_selected(index: int) -> void:
	var locale_id: Variant = _list.get_item_metadata(index)
	if typeof(locale_id) != TYPE_STRING_NAME:
		return
	select_locale(locale_id)
