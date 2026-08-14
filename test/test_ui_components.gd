extends GutTest

const CONTRACT_PATH := "res://test/test_ui_components.gd.component-contract.json"
const INVENTORY_PATH := "res://test/test_ui_components.gd.inventory.json"
const SCREEN_SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const SIDE_NAMES: Array[StringName] = [&"left", &"top", &"right", &"bottom"]
const SIDE_VALUES: Array[int] = [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]

var _contract: Dictionary = {}
var _inventory: Dictionary = {}


func before_all() -> void:
	_contract = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH)) as Dictionary
	_inventory = JSON.parse_string(FileAccess.get_file_as_string(INVENTORY_PATH)) as Dictionary


func test_contract_fixtures_have_exact_schema_and_cardinality() -> void:
	assert_eq(int(_contract.get("schema_version")), 2)
	assert_eq((_contract["theme"]["variations"] as Dictionary).size(), 26)
	assert_eq((_contract["styleboxes"] as Dictionary).size(), 31)
	assert_eq((_contract["components"] as Array).size(), 5)
	assert_eq(int(_inventory.get("schema_version")), 1)
	assert_eq((_inventory["states"] as Dictionary).size(), 12)
	assert_eq(int(_inventory["states"]["title"]["target_count"]), 2)
	assert_eq(int(_inventory["states"]["staging"]["target_count"]), 7)
	assert_eq(int(_inventory["states"]["staging"]["text_count"]), 13)
	assert_eq(int(_inventory["states"]["campaign_initial"]["target_count"]), 9)
	assert_eq(int(_inventory["states"]["squad_s1_empty"]["target_count"]), 7)
	assert_eq(int(_inventory["states"]["squad_s1_empty"]["text_count"]), 15)
	assert_eq(int(_inventory["states"]["squad_s2_expanded"]["text_count"]), 16)
	assert_eq(int(_inventory["states"]["results_campaign_clear"]["text_count"]), 9)
	assert_eq(int(_inventory["states"]["results_standalone_defeat"]["text_count"]), 5)


func test_theme_resource_has_exact_variations_items_and_values() -> void:
	var theme_path := String(_contract["theme"]["resource"])
	var theme := load(theme_path) as Theme
	assert_not_null(theme)
	assert_true(theme is AetheriaTheme)
	assert_true(theme.default_font is FontVariation)
	var composite := theme.default_font as FontVariation
	assert_eq(composite.base_font, ThemeDB.fallback_font)
	assert_eq(composite.fallbacks.size(), 1)
	assert_eq(
		(composite.fallbacks[0] as Font).resource_path,
		"res://assets/fonts/ProtosSansSC-Subset.otf",
	)
	assert_eq(theme.default_font_size, int(_contract["theme"]["default_font_size"]))
	var expected_variations := _contract["theme"]["variations"] as Dictionary
	var actual_variations: Array[String] = []
	for base: StringName in [&"Button", &"PanelContainer", &"Label", &"ItemList"]:
		for variation: StringName in theme.get_type_variation_list(base):
			actual_variations.append(String(variation))
	actual_variations.sort()
	var expected_names: Array[String] = []
	for raw_name: Variant in expected_variations:
		expected_names.append(String(raw_name))
	expected_names.sort()
	assert_eq(actual_variations, expected_names)
	for raw_name: Variant in expected_variations:
		var variation := StringName(raw_name)
		var specification := expected_variations[raw_name] as Dictionary
		assert_eq(
			theme.get_type_variation_base(variation),
			StringName(specification["base"]),
			"base %s" % variation,
		)
		if specification.has("font_size"):
			assert_true(theme.has_font_size(&"font_size", variation), String(variation))
			assert_eq(
				theme.get_font_size(&"font_size", variation),
				int(specification["font_size"]), String(variation),
			)
		if specification.has("font_color"):
			_assert_theme_color(
				theme, variation, &"font_color", String(specification["font_color"]),
			)
		for raw_state: Variant in (specification.get("font_colors", {}) as Dictionary):
			_assert_theme_color(
				theme, variation, _font_item(String(raw_state)),
				String(specification["font_colors"][raw_state]),
			)
		for raw_state: Variant in (specification.get("styleboxes", {}) as Dictionary):
			var style_name := StringName(raw_state)
			var style_id := String(specification["styleboxes"][raw_state])
			_assert_theme_stylebox(theme, variation, style_name, style_id)
		for raw_constant: Variant in (specification.get("constants", {}) as Dictionary):
			var constant_name := StringName(raw_constant)
			assert_true(theme.has_constant(constant_name, variation))
			assert_eq(
				theme.get_constant(constant_name, variation),
				int(specification["constants"][raw_constant]),
				"%s/%s" % [variation, constant_name],
			)


func test_material_resource_maps_every_exact_role_and_validates() -> void:
	var material := load(String(_contract["theme"]["material"])) as UiMaterialTier
	assert_not_null(material)
	assert_eq(material.validate_contract(), PackedStringArray())
	var expected := _contract["theme"]["required_material_roles"] as Dictionary
	assert_eq(material.type_variations.size(), expected.size())
	for raw_role: Variant in expected:
		var role := StringName(raw_role)
		assert_eq(material.type_variations[role], StringName(expected[raw_role]), String(role))
	assert_eq(material.panel_opacity, 1.0)
	assert_eq(material.ambient_emission_scale, 0.0)


func test_every_contrast_pair_matches_wcag_expected_and_floor() -> void:
	for raw_pair: Variant in _contract["contrast_pairs"]:
		var pair := raw_pair as Dictionary
		var foreground := _token_color(String(pair["foreground"]))
		var background := _token_color(String(pair["background"]))
		var ratio := _contrast(foreground, background)
		assert_gte(ratio, float(pair["minimum"]), String(pair["id"]))
		assert_almost_eq(ratio, float(pair["expected"]), 0.002, String(pair["id"]))
	var bindings := _contract["render_contrast_bindings"] as Dictionary
	var variations := _contract["theme"]["variations"] as Dictionary
	assert_eq(bindings.size(), variations.size())
	for raw_variation: Variant in variations:
		assert_true(bindings.has(raw_variation), String(raw_variation))
		assert_false((bindings[raw_variation] as Dictionary).is_empty(), String(raw_variation))


func test_component_scenes_have_exact_roots_children_and_defaults() -> void:
	for raw_component: Variant in _contract["components"]:
		var specification := raw_component as Dictionary
		var scene := load(String(specification["scene"])) as PackedScene
		assert_not_null(scene, String(specification["scene"]))
		var root := scene.instantiate()
		assert_eq(root.name, StringName(specification["root"]))
		assert_true(root.is_class(StringName(specification["base"])))
		assert_eq(
			root.get_script().get_global_name(), StringName(specification["class_name"]),
		)
		var expected_children: Array[String] = []
		for raw_child: Variant in specification["children"]:
			expected_children.append(String(raw_child))
		var actual_children := _descendant_names(root)
		assert_eq(actual_children, expected_children, String(specification["class_name"]))
		root.free()


func test_component_roles_fail_closed_and_preserve_prior_state() -> void:
	var button := AetheriaButton.new()
	assert_eq(button.role, &"secondary")
	assert_eq(button.focus_mode, Control.FOCUS_ALL)
	assert_eq(button.custom_minimum_size, Vector2(44.0, 52.0))
	assert_true(button.apply_role(&"primary"))
	assert_eq(button.theme_type_variation, &"AuiPrimaryButton")
	assert_false(button.apply_role(&"unknown"))
	assert_eq(button.role, &"primary")
	assert_eq(button.theme_type_variation, &"AuiPrimaryButton")
	var panel := AetheriaPanel.new()
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_false(panel.apply_role(&"unknown"))
	assert_eq(panel.role, &"reading")
	var label := AetheriaLabel.new()
	assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
	assert_true(label.apply_role(&"dense_detail"))
	assert_eq(label.theme_type_variation, &"AuiDenseDetailLabel")
	assert_false(label.apply_role(&"unknown"))
	assert_eq(label.role, &"dense_detail")
	button.free()
	panel.free()
	label.free()


func test_semantic_button_presentation_has_one_inventory_owner_and_exact_failure() -> void:
	var button := AetheriaButton.new()
	button.text = "Original"
	assert_false(button.set_presentation_text("", "Visible"))
	assert_eq(button.text, "Original")
	assert_null(button.get_node_or_null("PresentationLabel"))
	assert_false(button.set_presentation_text("Logical", ""))
	assert_eq(button.text, "Original")
	assert_true(button.set_presentation_text("Barracks — Unavailable", "Barracks\nUnavailable"))
	assert_eq(button.text, "Barracks — Unavailable")
	var presented := button.get_node("PresentationLabel") as AetheriaLabel
	assert_eq(presented.text, "Barracks\nUnavailable")
	assert_eq(presented.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(presented.theme_type_variation, &"AuiBodyLabel")
	assert_true(button.set_presentation_text("Recruit — Unavailable", "Recruit\nUnavailable"))
	assert_eq(button.text, "Recruit — Unavailable")
	assert_eq(button.get_children().filter(
		func(child: Node) -> bool: return child.name == &"PresentationLabel"
	).size(), 1)
	assert_eq((button.get_node("PresentationLabel") as Label).text, "Recruit\nUnavailable")
	button.free()


func test_screen_shell_exact_structure_modes_clamps_and_failure() -> void:
	var shell := SCREEN_SHELL_SCENE.instantiate() as AetheriaScreenShell
	add_child_autofree(shell)
	await get_tree().process_frame
	assert_eq(shell.content_host().name, &"ContentHost")
	assert_eq(shell.preferred_size, Vector2(720.0, 520.0))
	assert_eq(shell.content_scale(), 1.0)
	assert_false(shell.set_preferred_size(Vector2.ZERO))
	assert_eq(shell.preferred_size, Vector2(720.0, 520.0))
	assert_true(shell.set_preferred_size(Vector2(1080.0, 620.0)))
	for test_case: Array in [
		[Vector2i(1920, 1080), &"regular_landscape", 1.5],
		[Vector2i(1280, 720), &"regular_landscape", 1.0],
		[Vector2i(960, 720), &"compact_landscape", 1.0],
		[Vector2i(720, 1280), &"portrait", 1.0],
	]:
		shell.relayout(test_case[0])
		assert_eq(shell.layout_mode(), test_case[1])
		var plate := shell.reading_plate()
		assert_almost_eq(shell.content_scale(), float(test_case[2]), 0.001)
		assert_eq(plate.scale, Vector2.ONE * shell.content_scale())
		assert_lte(plate.custom_minimum_size.x, float(test_case[0].x))
		assert_lte(plate.custom_minimum_size.y, float(test_case[0].y))
	assert_true(shell.set_preferred_size(Vector2(640.0, 900.0)))
	shell.relayout(Vector2i(1440, 2560))
	assert_eq(shell.layout_mode(), &"portrait")
	assert_almost_eq(shell.content_scale(), 2.0, 0.001)


func test_screen_shell_dialog_scroll_uses_far_right_gutter() -> void:
	var shell := SCREEN_SHELL_SCENE.instantiate() as AetheriaScreenShell
	shell.preferred_size = Vector2(1080.0, 620.0)
	add_child_autofree(shell)
	await get_tree().process_frame
	shell.relayout(Vector2i(1280, 720))
	var scroll := ScrollContainer.new()
	scroll.name = "TestDialogScroll"
	var gutter := shell.add_dialog_scroll(scroll)
	assert_not_null(gutter)
	var body := Control.new()
	body.name = "TestDialogBody"
	body.custom_minimum_size = Vector2(600.0, 1200.0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gutter.add_child(body)
	var rejected_scroll := ScrollContainer.new()
	assert_null(shell.add_dialog_scroll(rejected_scroll))
	rejected_scroll.free()
	await get_tree().process_frame
	await get_tree().process_frame
	var bar := scroll.get_v_scroll_bar()
	assert_true(bar.visible)
	assert_almost_eq(
		bar.get_global_rect().end.x, shell.reading_plate().get_global_rect().end.x, 0.5,
	)
	assert_gte(bar.get_global_rect().position.x - body.get_global_rect().end.x, 35.0)


func test_locale_selector_exact_rows_selection_and_rejection() -> void:
	assert_true(I18n.set_locale(&"en-US"))
	var scene := load("res://scenes/ui/components/aetheria_locale_selector.tscn") as PackedScene
	var selector := scene.instantiate() as AetheriaLocaleSelector
	add_child_autofree(selector)
	await get_tree().process_frame
	assert_true(selector.refresh())
	var list := selector.get_node("LocaleList") as ItemList
	assert_eq(list.item_count, 2)
	assert_eq(list.get_item_text(0), "EN")
	assert_eq(list.get_item_text(1), "中文")
	assert_eq(typeof(list.get_item_metadata(0)), TYPE_STRING_NAME)
	assert_eq(list.get_item_metadata(0), &"en-US")
	assert_eq(typeof(list.get_item_metadata(1)), TYPE_STRING_NAME)
	assert_eq(list.get_item_metadata(1), &"zh-CN")
	assert_eq(list.get_selected_items(), PackedInt32Array([0]))
	assert_eq(list.max_columns, 2)
	assert_true(list.same_column_width)
	assert_eq(list.size_flags_horizontal, Control.SIZE_EXPAND_FILL)
	assert_null(list.get_node_or_null("PresentationLabel"))
	assert_gte(list.custom_minimum_size.x, 360.0)
	assert_gte(list.custom_minimum_size.y, 90.0)
	var selected_style := list.get_theme_stylebox(&"selected") as StyleBoxFlat
	assert_not_null(selected_style)
	assert_eq(selected_style.bg_color, AetheriaTheme.COLORS[&"selected"])
	assert_gte(
		_contrast(list.get_theme_color(&"font_selected_color"), selected_style.bg_color),
		4.5,
	)
	list.grab_focus()
	await get_tree().process_frame
	selector.set_vertical_layout(true)
	assert_true(selector.vertical)
	assert_true(selector.refresh())
	await get_tree().process_frame
	assert_eq(get_viewport().gui_get_focus_owner(), list)
	selector.set_vertical_layout(false)
	assert_false(selector.vertical)
	watch_signals(selector)
	assert_true(selector.select_locale(&"zh-CN"))
	assert_signal_emitted_with_parameters(selector, "locale_selected", [&"zh-CN"])
	assert_eq(I18n.locale(), &"zh-CN")
	assert_eq(list.get_selected_items(), PackedInt32Array([1]))
	assert_true(selector.select_locale(&"en-US"))
	assert_false(selector.select_locale(&"fr-FR"))
	assert_eq(I18n.locale(), &"en-US")


func test_source_and_scene_inventory_expansion_is_exact_and_bounded() -> void:
	var states := _inventory["states"] as Dictionary
	for raw_state: Variant in states:
		var state := states[raw_state] as Dictionary
		assert_eq(_expanded_count(state["targets"] as Array), int(state["target_count"]))
		assert_eq(_expanded_count(state["text"] as Array), int(state["text_count"]))
		assert_eq(_unique_ids(state["targets"] as Array), (state["targets"] as Array).size())
		assert_eq(_unique_ids(state["text"] as Array), (state["text"] as Array).size())
		_assert_explicit_focus_permutation(String(raw_state), state)
	var component_sources := DirAccess.get_files_at("res://scripts/ui/components")
	assert_true(component_sources.has("aetheria_button.gd"))
	assert_true(component_sources.has("aetheria_screen_shell.gd"))
	for path: String in [
		"res://scripts/ui/title.gd", "res://scripts/ui/staging.gd",
		"res://scripts/ui/stage_select.gd", "res://scripts/ui/squad_select.gd",
		"res://scripts/ui/results.gd",
	]:
		var source := FileAccess.get_file_as_string(path)
		assert_true(source.contains("AetheriaScreenShell"), path)
		assert_false(source.contains("Control.new()\n\troot.name = \"%s\"" % path), path)


func _assert_theme_color(
		theme: Theme, variation: StringName, item: StringName, token: String,
	) -> void:
	assert_true(theme.has_color(item, variation), "%s/%s" % [variation, item])
	assert_eq(
		theme.get_color(item, variation), _token_color(token),
		"%s/%s" % [variation, item],
	)


func _assert_theme_stylebox(
		theme: Theme, variation: StringName, item: StringName, style_id: String,
	) -> void:
	assert_true(theme.has_stylebox(item, variation), "%s/%s" % [variation, item])
	var actual := theme.get_stylebox(item, variation) as StyleBoxFlat
	assert_not_null(actual)
	var expected := _contract["styleboxes"][style_id] as Dictionary
	assert_eq(actual.bg_color, _token_color(String(expected["background"])))
	assert_eq(actual.border_color, _token_color(String(expected["border"])))
	for index: int in SIDE_NAMES.size():
		var side_name := SIDE_NAMES[index]
		var side := SIDE_VALUES[index]
		assert_eq(
			actual.get_border_width(side), int(expected["border_width"]),
			"%s/%s border %s" % [variation, item, side_name],
		)
		assert_eq(
			actual.get_content_margin(side), float(expected["content_margins"][index]),
			"%s/%s content %s" % [variation, item, side_name],
		)
		assert_eq(
			actual.get_expand_margin(side), float(expected["expand_margin"][index]),
			"%s/%s expand %s" % [variation, item, side_name],
		)
	for corner: int in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT]:
		assert_eq(actual.get_corner_radius(corner), int(expected["corner_radius"]))


func _font_item(state: String) -> StringName:
	if state == "normal":
		return &"font_color"
	return StringName("font_%s_color" % state)


func _token_color(token: String) -> Color:
	return Color.html(String(_contract["tokens"]["colors"][token]))


func _contrast(first: Color, second: Color) -> float:
	var first_luminance := _luminance(first)
	var second_luminance := _luminance(second)
	return (maxf(first_luminance, second_luminance) + 0.05) / (
		minf(first_luminance, second_luminance) + 0.05
	)


func _luminance(color: Color) -> float:
	return 0.2126 * _linear(color.r) + 0.7152 * _linear(color.g) + 0.0722 * _linear(color.b)


func _linear(channel: float) -> float:
	if channel <= 0.04045:
		return channel / 12.92
	return pow((channel + 0.055) / 1.055, 2.4)


func _unique_ids(rows: Array) -> int:
	var ids: Dictionary = {}
	for raw_row: Variant in rows:
		var row := raw_row as Dictionary
		var selector := String(row.get("selector", row.get("id", "")))
		assert_false(selector.is_empty())
		assert_false(ids.has(selector), selector)
		ids[selector] = true
	return ids.size()


func _expanded_count(rows: Array) -> int:
	var total := 0
	for raw_row: Variant in rows:
		var row := raw_row as Dictionary
		total += int(row.get("expected_count", 1))
	return total


func _assert_explicit_focus_permutation(state_name: String, state: Dictionary) -> void:
	var enabled: Array[String] = []
	var expansions := state.get("focus_expansions", {}) as Dictionary
	for raw_row: Variant in state["targets"]:
		var row := raw_row as Dictionary
		var selector := String(row["selector"])
		if selector.ends_with("*"):
			var domain := expansions.get(selector, []) as Array
			assert_eq(domain.size(), int(row["expected_count"]), "%s %s domain" % [state_name, selector])
			for raw_name: Variant in domain:
				enabled.append(String(raw_name))
			continue
		if bool(row.get("enabled", true)):
			enabled.append(selector)
	var focus: Array[String] = []
	for raw_name: Variant in state.get("focus_order", []):
		focus.append(String(raw_name))
	if focus.is_empty():
		return
	var unique: Dictionary = {}
	for node_name: String in focus:
		unique[node_name] = true
	assert_eq(unique.size(), focus.size(), "%s unique focus" % state_name)
	enabled.sort()
	focus.sort()
	assert_eq(focus, enabled, "%s enabled focus permutation" % state_name)


func _descendant_names(root: Node) -> Array[String]:
	var names: Array[String] = []
	for child: Node in root.get_children():
		names.append(String(child.name))
		names.append_array(_descendant_names(child))
	return names
