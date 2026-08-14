extends RefCounted

const INVENTORY_PATH := "res://test/test_ui_components.gd.inventory.json"
const CONTRACT_PATH := "res://selftest/scenarios/ui_shell_floor.gd.contract.json"
const THEME_PATH := "res://data/presentation/ui/threshold_theme.tres"
const VIEWPORTS := [
	Vector2i(1920, 1080), Vector2i(1280, 720),
	Vector2i(960, 720), Vector2i(720, 1280),
]
const MODES: Array[StringName] = [&"standard", &"text200", &"expand135"]
const SCREENS: Array[StringName] = [&"title", &"staging", &"campaign", &"squad", &"results"]
const INVENTORY_STATES := {
	&"title": "title",
	&"staging": "staging",
	&"campaign": "campaign_initial",
	&"squad": "squad_s1_empty",
	&"results": "results_campaign_clear",
}
const FLAVOR_LABEL_SPECS := {
	&"staging": {
		&"CompanyCommandBody": &"AuiDenseDetailLabel",
		&"NextOperationObjective": &"AuiDenseDetailLabel",
	},
	&"squad": {
		&"BriefingObjective": &"AuiDenseDetailLabel",
		&"BriefingThreat": &"AuiDenseDetailLabel",
		&"BriefingHumanReason": &"AuiDenseDetailLabel",
		&"BriefingClue": &"AuiDenseDetailLabel",
	},
	&"results": {
		&"ConsequenceLine": &"AuiDenseBodyLabel",
	},
}
const EXPANSION_TOKEN := " PROTOS"
const TEXT_COLOR_FLOOR := 0.10
const BASE_FONT_SIZES := {
	&"AuiTitleLabel": 64, &"AuiHeadingLabel": 48,
	&"AuiBodyLabel": 44, &"AuiDetailLabel": 44,
	&"AuiDenseHeadingLabel": 34, &"AuiDenseBodyLabel": 34,
	&"AuiDenseDetailLabel": 34,
	&"AuiLocaleLabel": 44, &"AuiLocaleList": 44,
	&"AuiPrimaryButton": 44, &"AuiSecondaryButton": 44,
	&"AuiSelectedButton": 44, &"AuiDestructiveButton": 44,
	&"AuiDisabledButton": 44, &"AuiClassBadge": 44, &"AuiCostBadge": 44,
	&"AuiCooldownBadge": 44, &"AuiLockedBadge": 44, &"AuiCompletedBadge": 44,
}

var _inventory: Dictionary = {}
var _contract: Dictionary = {}
var _inventory_reports: Array[Dictionary] = []
var _active_mode: StringName = &"standard"
var _release_challenge := ""


func run(h: SelfTestHarness) -> void:
	h.max_frames = 2700
	h.expect_done()
	_release_challenge = _parse_release_challenge()
	_inventory = JSON.parse_string(FileAccess.get_file_as_string(INVENTORY_PATH)) as Dictionary
	_contract = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH)) as Dictionary
	h.check("ui inventory contract loaded", not _inventory.is_empty())
	h.check("ui shell scenario contract loaded", not _contract.is_empty())
	h.check("text200 baseline map exact", _baseline_map_exact())
	if _inventory.is_empty() or _contract.is_empty():
		return
	await _capture_component_gallery(h)
	await _capture_text_style_probes(h)
	for mode: StringName in MODES:
			for screen: StringName in SCREENS:
				for viewport: Vector2i in VIEWPORTS:
					await _capture_screen_state(h, screen, viewport, mode)
	_write_supplemental_report(h)
	h.check("ui_shell_floor inventory state count", _inventory_reports.size() == 60)
	h.check("ui_shell_floor required report fields", _reports_have_required_fields())
	h.done()


func _parse_release_challenge() -> String:
	var matcher := RegEx.new()
	if matcher.compile("^[0-9a-f]{64}$") != OK:
		return ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--release-challenge="):
			var value := argument.trim_prefix("--release-challenge=")
			if matcher.search(value) != null:
				return value
	return ""


func _capture_component_gallery(h: SelfTestHarness) -> void:
	h.root.size = Vector2i(1280, 720)
	var fixture := _fixture_root(h, &"ComponentGallery")
	var panel := AetheriaPanel.new()
	panel.name = "GalleryPanel"
	panel.apply_role(&"reading")
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 32)
	fixture.add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 20)
	grid.add_theme_constant_override(&"v_separation", 18)
	panel.add_child(grid)
	for role: StringName in [&"primary", &"secondary", &"selected", &"destructive", &"disabled"]:
		var button := AetheriaButton.new()
		button.text = String(role).capitalize()
		button.apply_role(role)
		grid.add_child(button)
	for role: StringName in [
		&"reading", &"hud", &"card", &"modal", &"inspector", &"reward", &"focus",
	]:
		var sample_panel := AetheriaPanel.new()
		sample_panel.custom_minimum_size = Vector2(320.0, 80.0)
		sample_panel.apply_role(role)
		var label := AetheriaLabel.new()
		label.text = String(role).capitalize() + " panel"
		label.apply_role(&"body")
		sample_panel.add_child(label)
		grid.add_child(sample_panel)
	var locale_scene := load(
		"res://scenes/ui/components/aetheria_locale_selector.tscn"
	) as PackedScene
	grid.add_child(locale_scene.instantiate())
	await h.frames(4)
	var image := await h.shot_grab("component_gallery")
	if image != null:
		h.check("component gallery image size", image.get_size() == Vector2i(1280, 720))


func _capture_text_style_probes(h: SelfTestHarness) -> void:
	h.root.size = Vector2i(1280, 720)
	var fixture := _fixture_root(h, &"TextStyleProbes")
	fixture.add_child(_backdrop())
	var grid := GridContainer.new()
	grid.name = "ProbeGrid"
	grid.columns = 4
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.offset_left = 32.0
	grid.offset_top = 32.0
	grid.offset_right = -32.0
	grid.offset_bottom = -32.0
	grid.add_theme_constant_override(&"h_separation", 12)
	grid.add_theme_constant_override(&"v_separation", 8)
	fixture.add_child(grid)
	var probes: Array[Dictionary] = []
	var probe_size := Vector2(280.0, 120.0)
	for role: StringName in [
		&"title", &"heading", &"body", &"detail", &"dense_heading", &"dense_body",
		&"dense_detail", &"locale", &"class_badge",
		&"cost_badge", &"cooldown_badge", &"locked_badge", &"completed_badge",
	]:
		var label := AetheriaLabel.new()
		label.name = "%sProbe" % String(role).to_pascal_case()
		label.text = "Mg %s" % String(role).left(4).capitalize()
		label.apply_role(role)
		label.custom_minimum_size = probe_size
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		grid.add_child(label)
		probes.append({"control": label, "item": &"font_color"})
	for role: StringName in [&"primary", &"secondary", &"selected", &"destructive", &"disabled"]:
		var button := AetheriaButton.new()
		button.name = "%sButtonProbe" % String(role).to_pascal_case()
		button.text = "Mg %s" % String(role).left(4).capitalize()
		button.apply_role(role)
		button.custom_minimum_size = probe_size
		grid.add_child(button)
		probes.append({"control": button, "item": &"font_color"})
	var item_list := ItemList.new()
	item_list.name = "LocaleListProbe"
	item_list.theme_type_variation = &"AuiLocaleList"
	item_list.custom_minimum_size = probe_size
	item_list.add_item("Mg List")
	item_list.select(0)
	grid.add_child(item_list)
	probes.append({"control": item_list, "item": &"font_selected_color"})
	await h.frames(4)
	var image := await h.shot_grab("text_style_probes")
	if image != null:
		var image_rect := Rect2(Vector2.ZERO, Vector2(image.get_size()))
		for probe: Dictionary in probes:
			var control := probe["control"] as Control
			var item := probe["item"] as StringName
			var color := control.get_theme_color(item)
			h.check(
				"text style probe in frame %s" % control.name,
				image_rect.encloses(control.get_global_rect()),
				"control=%s image=%s" % [control.get_global_rect(), image_rect],
			)
			var height := _rendered_text_height(image, control.get_global_rect(), color)
			h.check(
				"rendered glyph floor %s" % control.name,
				height >= 32,
				"rendered_height=%d floor=32" % height,
			)


func _capture_screen_state(
		h: SelfTestHarness, screen: StringName, viewport: Vector2i, mode: StringName,
	) -> void:
	h.root.size = viewport
	await h.frames(2)
	var content := await _open_screen(h, screen)
	if content == null:
		h.check("%s %s %s content" % [screen, viewport, mode], false)
		return
	var stress_evidence := _apply_stress_mode(content, mode, screen)
	await h.frames(4)
	if mode == &"standard":
		_check_responsive_shell(h, content, screen, viewport)
	var state_name := String(INVENTORY_STATES[screen])
	var report := await _inventory_report(
		h, content, state_name, viewport, mode, screen, stress_evidence,
	)
	_inventory_reports.append(report)
	h.check(
		"inventory %s %s %s" % [screen, viewport, mode],
		bool(report["ok"]),
		JSON.stringify(report),
	)
	var shot_name := "ui_%s_%dx%d_%s" % [screen, viewport.x, viewport.y, mode]
	var image := await h.shot_grab(shot_name)
	if image != null:
		h.check(
			"shot geometry %s" % shot_name,
			image.get_size() == viewport,
			"image=%s viewport=%s" % [image.get_size(), viewport],
		)
	if (
		screen == &"results" and viewport == Vector2i(1920, 1080)
		and mode == &"standard"
	):
		await _capture_results_flavor(h, content, viewport)


func _capture_results_flavor(
		h: SelfTestHarness, content: Control, viewport: Vector2i,
		) -> void:
	var scroll := content.find_child("ResultsScroll", true, false) as ScrollContainer
	var flavor := content.find_child("ConsequenceLine", true, false) as Control
	h.check(
		"results flavor capture controls exist",
		scroll != null and flavor != null,
		"scroll=%s flavor=%s" % [scroll, flavor],
	)
	if scroll == null or flavor == null:
		return
	scroll.ensure_control_visible(flavor)
	await h.frames(3)
	var image := await h.shot_grab("ui_results_1920x1080_flavor")
	if image != null:
		h.check(
			"results flavor shot geometry",
			image.get_size() == viewport,
			"image=%s viewport=%s" % [image.get_size(), viewport],
		)


func _open_screen(h: SelfTestHarness, screen: StringName) -> Control:
	var game := h.autoload("Game")
	match screen:
		&"title":
			game.call("open_title")
		&"staging":
			game.call("start_campaign", true)
		&"campaign":
			game.call("start_campaign", false)
			game.call("open_stage_select")
		&"squad":
			game.call("start_campaign", false)
			game.set("selected_stage_id", &"s1")
			game.call("open_squad_select")
		&"results":
			game.call("start_campaign", false)
			game.set("selected_stage_id", &"s1")
			game.set("last_result", {
				"stage_id": &"s1",
				"result": BattleModel.Result.CLEAR,
				"stars": 3,
				"kills": 12,
				"leaks": 0,
				"rewards_granted": [{"kind": &"operator", "id": &"caster_2"}],
			})
			game.call("open_results")
	await h.frames(5)
	var content := game.get("content") as Control
	if screen == &"results" and content != null:
		var consequence := content.find_child("ConsequenceLine", true, false) as Label
		h.check(
			"ui_shell_floor exact S1 clear consequence",
			consequence != null and consequence.text == "Holding the line gives investigators time to recover a damaged evacuation seal. The pumps stay in service, and Company 33 confirms that the old order never ended.",
			consequence.text if consequence != null else "missing",
		)
	return content


func _check_responsive_shell(
		h: SelfTestHarness, content: Control, screen: StringName, viewport: Vector2i,
		) -> void:
	var shell: AetheriaScreenShell = null
	for node: Node in _all_nodes(content):
		if node is AetheriaScreenShell:
			shell = node as AetheriaScreenShell
			break
	h.check(
		"%s %s responsive shell exists" % [screen, viewport], shell != null,
		"viewport=%s" % viewport,
	)
	if shell == null:
		return
	var expected_scale := 1.5 if viewport == Vector2i(1920, 1080) else 1.0
	h.check(
		"%s %s responsive scale" % [screen, viewport],
		is_equal_approx(shell.content_scale(), expected_scale),
		"scale=%.3f expected=%.3f" % [shell.content_scale(), expected_scale],
	)
	var plate := shell.reading_plate()
	var plate_rect := plate.get_global_rect()
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport))
	if shell.content_scale() > 1.0:
		h.check(
			"%s scaled plate inside viewport" % screen,
			viewport_rect.encloses(plate_rect),
			"plate=%s viewport=%s" % [plate_rect, viewport_rect],
		)
		var center_delta := plate_rect.get_center() - viewport_rect.get_center()
		h.check(
			"%s scaled plate centered" % screen,
			absf(center_delta.x) <= 0.5 and absf(center_delta.y) <= 0.5,
			"plate_center=%s viewport_center=%s" % [
				plate_rect.get_center(), viewport_rect.get_center(),
			],
		)
		h.check(
			"%s large viewport grows actual plate" % screen,
			plate_rect.size.is_equal_approx(plate.size * shell.content_scale()),
			"rendered=%s layout=%s scale=%.3f" % [
				plate_rect.size, plate.size, shell.content_scale(),
			],
		)
	if viewport == Vector2i(1920, 1080) and FLAVOR_LABEL_SPECS.has(screen):
		var mismatches: Array[String] = []
		var specifications := FLAVOR_LABEL_SPECS[screen] as Dictionary
		for raw_selector: Variant in specifications:
			var selector := StringName(raw_selector)
			var label := content.find_child(String(selector), true, false) as Label
			if label == null:
				mismatches.append("%s:missing" % selector)
				continue
			var expected_variation := StringName(specifications[raw_selector])
			var scaled_size := roundi(
				float(label.get_theme_font_size(&"font_size")) * shell.content_scale(),
			)
			if label.theme_type_variation != expected_variation or scaled_size != 51:
				mismatches.append("%s:%s/%d" % [
					selector, label.theme_type_variation, scaled_size,
				])
		h.check(
			"%s large viewport flavor typography" % screen,
			mismatches.is_empty(),
			"mismatches=" + str(mismatches) + " expected_size=51",
		)
	if screen == &"results" and viewport == Vector2i(1920, 1080):
		var actions := content.find_child("ActionRow", true, false) as GridContainer
		var all_expand := actions != null
		var measured_widths: Array[float] = []
		if actions != null:
			for child: Node in actions.get_children():
				if child is Button:
					var button := child as Button
					all_expand = all_expand and button.size_flags_horizontal == Control.SIZE_EXPAND_FILL
					measured_widths.append(button.get_global_rect().size.x)
		h.check(
			"results large viewport actions expand horizontally",
			all_expand and measured_widths.size() == 3,
			"widths=" + str(measured_widths),
		)
	if screen != &"title":
		_check_dialog_scrollbar_gutter(h, content, shell, screen, viewport)


func _check_dialog_scrollbar_gutter(
		h: SelfTestHarness, content: Control, shell: AetheriaScreenShell,
		screen: StringName, viewport: Vector2i,
		) -> void:
	var scroll: ScrollContainer = null
	for node: Node in _all_nodes(content):
		if node is ScrollContainer:
			scroll = node as ScrollContainer
			break
	h.check(
		"%s %s dialog scroll exists" % [screen, viewport], scroll != null,
	)
	if scroll == null:
		return
	var gutter := scroll.get_child(0) as MarginContainer
	var body := gutter.get_child(0) as Control
	var bar := scroll.get_v_scroll_bar()
	var panel_right := shell.reading_plate().get_global_rect().end.x
	var scroll_right := scroll.get_global_rect().end.x
	h.check(
		"%s %s scrollbar reaches dialog right edge" % [screen, viewport],
		absf(scroll_right - panel_right) <= 0.5,
		"scroll_right=%.2f panel_right=%.2f" % [scroll_right, panel_right],
	)
	if bar.visible:
		var bar_rect := bar.get_global_rect()
		var text_gap := bar_rect.position.x - body.get_global_rect().end.x
		h.check(
			"%s %s visible scrollbar at dialog right edge" % [screen, viewport],
			absf(bar_rect.end.x - panel_right) <= 0.5,
			"bar=%s panel_right=%.2f" % [bar_rect, panel_right],
		)
		h.check(
			"%s %s scrollbar clears dialog content" % [screen, viewport],
			text_gap >= 35.0 * shell.content_scale(),
			"gap=%.2f scale=%.2f" % [text_gap, shell.content_scale()],
		)


func _baseline_map_exact() -> bool:
	var raw := _contract.get("text200_contract", {}) as Dictionary
	var contract_map := raw.get("baseline_font_sizes", {}) as Dictionary
	if contract_map.size() != BASE_FONT_SIZES.size():
		return false
	for variation: StringName in BASE_FONT_SIZES:
		if int(contract_map.get(String(variation), -1)) != int(BASE_FONT_SIZES[variation]):
			return false
	return true


func _reports_have_required_fields() -> bool:
	var required := _contract["required_report"] as Dictionary
	var fields := required["per_inventory_state_fields"] as Array
	var empty_fields := required.get("per_inventory_state_empty_fields", []) as Array
	for report: Dictionary in _inventory_reports:
		for field: String in fields:
			if not report.has(field):
				return false
		for field: String in empty_fields:
			if not report.has(field) or not (report[field] as Array).is_empty():
				return false
	return true


func _stress_evidence(
		content: Control, owners: Array[Control], theme: Theme,
		mode: StringName, screen: StringName,
		) -> Dictionary:
	var owner_paths: Array[String] = []
	var replaced_paths: Array[String] = []
	var owner_mismatches: Array[String] = []
	for owner: Control in owners:
		var path := "." if owner == content else String(content.get_path_to(owner))
		owner_paths.append(path)
		if owner.theme == theme:
			replaced_paths.append(path)
		else:
			owner_mismatches.append(path)
	owner_paths.sort()
	replaced_paths.sort()
	owner_mismatches.sort()

	var used_variations: Array[String] = []
	for node: Node in _all_nodes(content):
		if not node is Control or not (node as Control).is_visible_in_tree():
			continue
		var variation := (node as Control).theme_type_variation
		if BASE_FONT_SIZES.has(variation) and not used_variations.has(String(variation)):
			used_variations.append(String(variation))
	used_variations.sort()
	var font_mismatches: Array[String] = []
	var scale := 2 if mode == &"text200" else 1
	for variation_text: String in used_variations:
		var variation := StringName(variation_text)
		var actual := theme.get_font_size(&"font_size", variation)
		var expected := int(BASE_FONT_SIZES[variation]) * scale
		if actual != expected:
			font_mismatches.append("%s:%d!=%d" % [variation_text, actual, expected])

	var source_theme := load(THEME_PATH) as Theme
	var base_mismatches: Array[String] = []
	for variation: StringName in BASE_FONT_SIZES:
		var actual := source_theme.get_font_size(&"font_size", variation)
		var expected := int(BASE_FONT_SIZES[variation])
		if actual != expected:
			base_mismatches.append("%s:%d!=%d" % [variation, actual, expected])

	var reflow_mismatches := _reflow_mismatches(content, mode, screen)
	var locale := _locale_evidence(content, mode)
	var ok := (
		owner_mismatches.is_empty() and font_mismatches.is_empty()
		and base_mismatches.is_empty() and reflow_mismatches.is_empty()
		and (screen != &"title" or bool(locale["ok"]))
	)
	return {
		"theme_owner_paths": owner_paths,
		"theme_replaced_owner_paths": replaced_paths,
		"theme_owner_mismatches": owner_mismatches,
		"used_font_variations": used_variations,
		"font_size_mismatches": font_mismatches,
		"base_resource_mismatches": base_mismatches,
		"reflow_mismatches": reflow_mismatches,
		"locale": locale,
		"ok": ok,
	}


func _reflow_mismatches(
		content: Control, mode: StringName, screen: StringName,
		) -> Array[String]:
	var mismatches: Array[String] = []
	if mode != &"text200":
		return mismatches
	var text_contract := _contract["text200_contract"] as Dictionary
	var screen_map := text_contract["reflow_by_screen"] as Dictionary
	var expected := screen_map[String(screen)] as Dictionary
	for node_name: String in expected["columns_one"]:
		var grid := content.find_child(node_name, true, false) as GridContainer
		if grid == null or grid.columns != 1:
			mismatches.append("%s.columns" % node_name)
	for node_name: String in expected["vertical"]:
		var box := content.find_child(node_name, true, false) as BoxContainer
		if box == null or not box.vertical:
			mismatches.append("%s.vertical" % node_name)
	return mismatches


func _locale_evidence(content: Control, mode: StringName) -> Dictionary:
	var mismatches: Array[String] = []
	var selector := content.find_child(
		"LocaleSelector", true, false,
	) as AetheriaLocaleSelector
	if selector == null:
		return {
			"item_count": 0, "item_text": "", "metadata_type": "", "metadata": "",
			"selected_indices": [], "focus_identity": "", "overlay_color": "",
			"selected_fill": "", "contrast": 0.0, "geometry_mismatches": [], "ok": true,
		}
	var item_list := selector.get_node("LocaleList") as ItemList
	var presented := item_list.get_node("PresentationLabel") as AetheriaLabel
	var metadata: Variant = item_list.get_item_metadata(0) if item_list.item_count > 0 else null
	var selected: Array[int] = []
	for index: int in item_list.get_selected_items():
		selected.append(index)
	if item_list.item_count != 1:
		mismatches.append("item_count")
	if item_list.item_count > 0 and item_list.get_item_text(0) != "English (US)":
		mismatches.append("item_text")
	if typeof(metadata) != TYPE_STRING_NAME or metadata != &"en-US":
		mismatches.append("metadata")
	if selected != [0]:
		mismatches.append("selected_indices")
	if item_list.custom_minimum_size.x < 360.0 or item_list.custom_minimum_size.y < 72.0:
		mismatches.append("minimum_target")
	if item_list.size.x < 44.0 or item_list.size.y < 44.0:
		mismatches.append("visible_target")
	if not item_list.get_global_rect().encloses(presented.get_global_rect()):
		mismatches.append("overlay_enclosure")
	var expected_presentation := (
		_expanded_text("English (US)") if mode == &"expand135" else "English (US)"
	)
	if presented.text != expected_presentation:
		mismatches.append("overlay_text")
	if presented.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		mismatches.append("overlay_mouse_filter")
	if presented.autowrap_mode != TextServer.AUTOWRAP_ARBITRARY or not presented.clip_text:
		mismatches.append("overlay_wrap_clip")
	var overlay_color := presented.get_theme_color(&"font_color")
	var expected_color := AetheriaTheme.COLORS[&"dark_ink"] as Color
	if overlay_color != expected_color:
		mismatches.append("overlay_color")
	var selected_style := item_list.get_theme_stylebox(&"selected") as StyleBoxFlat
	var selected_fill := selected_style.bg_color if selected_style != null else Color.TRANSPARENT
	var contrast := _contrast_ratio(overlay_color, selected_fill)
	if selected_fill != AetheriaTheme.COLORS[&"selected"] or contrast < 4.5:
		mismatches.append("overlay_contrast")
	return {
		"item_count": item_list.item_count,
		"item_text": item_list.get_item_text(0) if item_list.item_count > 0 else "",
		"metadata_type": type_string(typeof(metadata)),
		"metadata": String(metadata) if metadata != null else "",
		"selected_indices": selected,
		"focus_identity": String(item_list.name),
		"overlay_color": overlay_color.to_html(false),
		"selected_fill": selected_fill.to_html(false),
		"contrast": contrast,
		"geometry_mismatches": mismatches,
		"ok": mismatches.is_empty(),
	}


func _contrast_ratio(first: Color, second: Color) -> float:
	var first_luminance := _relative_luminance(first)
	var second_luminance := _relative_luminance(second)
	return (maxf(first_luminance, second_luminance) + 0.05) / (
		minf(first_luminance, second_luminance) + 0.05
	)


func _relative_luminance(color: Color) -> float:
	return (
		0.2126 * _linear_color(color.r) + 0.7152 * _linear_color(color.g)
		+ 0.0722 * _linear_color(color.b)
	)


func _linear_color(channel: float) -> float:
	if channel <= 0.04045:
		return channel / 12.92
	return pow((channel + 0.055) / 1.055, 2.4)


func _apply_stress_mode(
		content: Control, mode: StringName, screen: StringName,
		) -> Dictionary:
	var owners: Array[Control] = [content]
	for node: Node in _all_nodes(content):
		if node is Control and (node as Control).theme != null:
			owners.append(node as Control)
	var theme := (load(THEME_PATH) as Theme).duplicate(true) as Theme
	var target_scale := 1.0
	if mode == &"text200":
		target_scale = 2.0
		for base: StringName in [&"Button", &"PanelContainer", &"Label", &"ItemList"]:
			for variation: StringName in theme.get_type_variation_list(base):
				if theme.has_font_size(&"font_size", variation):
						var size := theme.get_font_size(&"font_size", variation)
						theme.set_font_size(&"font_size", variation, size * 2)
	for owner: Control in owners:
		owner.theme = theme
	if mode == &"text200":
		for node: Node in _all_nodes(content):
			if node is Control:
				var control := node as Control
				if control.has_theme_font_size_override(&"font_size"):
					var local_size := control.get_theme_font_size(&"font_size")
					control.add_theme_font_size_override(&"font_size", local_size * 2)
		_apply_text200_reflow(content)
	if mode == &"expand135":
		target_scale = 1.35
		_expand_visible_text(content)
	if target_scale > 1.0:
		for node: Node in _all_nodes(content):
			if node is AetheriaButton:
				var button := node as AetheriaButton
				button.custom_minimum_size.y = ceilf(button.custom_minimum_size.y * target_scale)
			elif node is ItemList:
				var item_list := node as ItemList
				item_list.custom_minimum_size.y = ceilf(
					item_list.custom_minimum_size.y * target_scale
				)
	_fit_locale_selector(content)
	return _stress_evidence(content, owners, theme, mode, screen)


func _apply_text200_reflow(content: Control) -> void:
	for node_name: String in [
		"BriefingRow", "OperationGrid", "CampaignHeader", "StageRows",
		"MissionBriefingPanel", "OperatorGrid", "SquadFooter", "ActionRow",
	]:
		var grid := content.find_child(node_name, true, false) as GridContainer
		if grid != null:
			grid.columns = 1
	for node_name: String in ["SquadHeader"]:
		var box := content.find_child(node_name, true, false) as BoxContainer
		if box != null:
			box.vertical = true


func _fit_locale_selector(content: Control) -> void:
	var selector := content.find_child(
		"LocaleSelector", true, false,
	) as AetheriaLocaleSelector
	if selector == null:
		return
	var item_list := selector.find_child("LocaleList", true, false) as ItemList
	var label := selector.find_child("LocaleLabel", true, false) as Label
	if item_list == null or label == null:
		return
	var needed_width := _item_list_required_width(item_list)
	var content_host := _ancestor_named(selector, &"ContentHost") as Control
	var available := content.get_viewport_rect().size.x - 96.0
	if content_host != null:
		available = content_host.size.x
	var horizontal_needed := needed_width + label.get_combined_minimum_size().x + 16.0
	var vertical := horizontal_needed > available
	selector.set_vertical_layout(vertical)
	item_list.custom_minimum_size.x = maxf(360.0, minf(needed_width, available))
	if vertical:
		var font := item_list.get_theme_font(&"font")
		var font_size := item_list.get_theme_font_size(&"font_size")
		var line_count := ceili(needed_width / item_list.custom_minimum_size.x)
		item_list.custom_minimum_size.y = maxf(
			item_list.custom_minimum_size.y,
			font.get_height(font_size) * line_count + 32.0,
		)


func _expand_visible_text(root: Node) -> void:
	for node: Node in _all_nodes(root):
		if not node is Control or not (node as Control).is_visible_in_tree():
			continue
		if node is AetheriaLocaleSelector:
			var locale_list := node.get_node("LocaleList") as ItemList
			var locale_label := locale_list.get_node("PresentationLabel") as Label
			locale_label.text = _expanded_text(locale_list.get_item_text(0))
		elif node is AetheriaButton:
			var button := node as AetheriaButton
			var presented := button.get_node_or_null("PresentationLabel") as Label
			if presented != null:
				button.set_presentation_text(
					_expanded_text(button.text), _expanded_text(presented.text),
				)
			else:
				button.text = _expanded_text(button.text)
		elif node is Button:
			(node as Button).text = _expanded_text((node as Button).text)
		elif node is Label and node.name != &"PresentationLabel":
			(node as Label).text = _expanded_text((node as Label).text)
		elif node is ItemList:
			var item_list := node as ItemList
			if item_list.get_parent() is AetheriaLocaleSelector:
				continue
			for index: int in item_list.item_count:
				item_list.set_item_text(index, _expanded_text(item_list.get_item_text(index)))


func _expanded_text(original: String) -> String:
	var expanded := original
	var target := ceili(original.length() * 1.35)
	while expanded.length() < target:
		expanded += EXPANSION_TOKEN
	return expanded


func _inventory_report(
		h: SelfTestHarness, content: Control, state_name: String, viewport: Vector2i,
		mode: StringName, screen: StringName, stress_evidence: Dictionary,
		) -> Dictionary:
	_active_mode = mode
	var state := _inventory["states"][state_name] as Dictionary
	var target_nodes := _discover_targets(content)
	var text_nodes := _discover_text(content)
	var target_result := _compare_rows(target_nodes, state["targets"] as Array, true)
	var text_result := _compare_rows(text_nodes, state["text"] as Array, false)
	var focus_result := _check_focus_order(content, state.get("focus_order", []) as Array)
	var marker := content.find_child(String(state["screen_marker"]), true, false)
	var locale := stress_evidence["locale"] as Dictionary
	var scroll_reachability_mismatches := await _scroll_reachability_mismatches(
		h, target_nodes, text_nodes,
	)
	var ok := (
		marker != null and bool(target_result["ok"])
		and bool(text_result["ok"]) and bool(focus_result["ok"])
		and bool(stress_evidence["ok"])
		and scroll_reachability_mismatches.is_empty()
	)
	return {
		"screen": String(screen),
		"state": state_name,
		"mode": String(mode),
		"viewport": "%dx%d" % [viewport.x, viewport.y],
		"target_expected_count": int(state["target_count"]),
		"target_discovered_count": int(target_result["count"]),
		"target_missing_ids": target_result["missing"],
		"target_unexpected_ids": target_result["unexpected"],
		"target_mismatched_ids": target_result["mismatched"],
		"text_expected_count": int(state["text_count"]),
		"text_discovered_count": int(text_result["count"]),
		"text_missing_ids": text_result["missing"],
		"text_unexpected_ids": text_result["unexpected"],
		"text_mismatched_ids": text_result["mismatched"],
		"focus_failures": focus_result["failures"],
		"marker_present": marker != null,
		"theme_owner_paths": stress_evidence["theme_owner_paths"],
		"theme_replaced_owner_paths": stress_evidence["theme_replaced_owner_paths"],
		"theme_owner_mismatches": stress_evidence["theme_owner_mismatches"],
		"used_font_variations": stress_evidence["used_font_variations"],
		"font_size_mismatches": stress_evidence["font_size_mismatches"],
		"base_resource_mismatches": stress_evidence["base_resource_mismatches"],
		"reflow_mismatches": stress_evidence["reflow_mismatches"],
		"scroll_reachability_mismatches": scroll_reachability_mismatches,
		"locale_item_count": locale["item_count"],
		"locale_item_text": locale["item_text"],
		"locale_item_metadata_type": locale["metadata_type"],
		"locale_item_metadata_value": locale["metadata"],
		"locale_selected_indices": locale["selected_indices"],
		"locale_focus_identity": locale["focus_identity"],
		"locale_overlay_color": locale["overlay_color"],
		"locale_selected_fill": locale["selected_fill"],
		"locale_contrast": locale["contrast"],
		"locale_geometry_mismatches": locale["geometry_mismatches"],
		"ok": ok,
	}


func _scroll_reachability_mismatches(
		h: SelfTestHarness, target_nodes: Array[Control], text_nodes: Array[Control],
		) -> Array[String]:
	var controls: Array[Control] = []
	var seen_controls: Dictionary = {}
	for node: Control in target_nodes + text_nodes:
		var instance_id := node.get_instance_id()
		if _nearest_scroll(node) != null and not seen_controls.has(instance_id):
			seen_controls[instance_id] = true
			controls.append(node)
	controls.sort_custom(func(first: Control, second: Control) -> bool:
		return String(first.get_path()) < String(second.get_path())
	)

	var scroll_states: Array[Dictionary] = []
	var seen_scrolls: Dictionary = {}
	for control: Control in controls:
		var scroll := _nearest_scroll(control)
		var scroll_id := scroll.get_instance_id()
		if not seen_scrolls.has(scroll_id):
			seen_scrolls[scroll_id] = true
			scroll_states.append({
				"scroll": scroll,
				"horizontal": scroll.scroll_horizontal,
				"vertical": scroll.scroll_vertical,
			})

	var mismatches: Array[String] = []
	for control: Control in controls:
		var scroll := _nearest_scroll(control)
		var before := Vector2i(scroll.scroll_horizontal, scroll.scroll_vertical)
		scroll.ensure_control_visible(control)
		await h.frames(2)
		var after := Vector2i(scroll.scroll_horizontal, scroll.scroll_vertical)
		var control_rect := control.get_global_rect()
		var viewport_rect := scroll.get_global_rect()
		var visible_rect := control_rect.intersection(viewport_rect)
		var horizontal_enclosed := _axis_encloses(
			viewport_rect.position.x, viewport_rect.end.x,
			control_rect.position.x, control_rect.end.x,
		)
		var vertical_enclosed := _axis_encloses(
			viewport_rect.position.y, viewport_rect.end.y,
			control_rect.position.y, control_rect.end.y,
		)
		var issues: Array[String] = []
		if not control.is_visible_in_tree() or control_rect.size.x <= 0.0 or control_rect.size.y <= 0.0:
			issues.append("nonzero_control_rect")
		if visible_rect.size.x <= 0.0 or visible_rect.size.y <= 0.0:
			issues.append("nonzero_visible_rect")
		var horizontal_disabled := (
			scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED
		)
		if horizontal_disabled:
			if not horizontal_enclosed:
				issues.append("horizontal_overflow_disabled")
		elif control_rect.size.x <= viewport_rect.size.x and not horizontal_enclosed:
			issues.append("horizontal_not_enclosed")
		elif control_rect.size.x > viewport_rect.size.x and visible_rect.size.x <= 0.0:
			issues.append("horizontal_not_intersecting")
		if control_rect.size.y <= viewport_rect.size.y and not vertical_enclosed:
			issues.append("vertical_not_enclosed")
		elif control_rect.size.y > viewport_rect.size.y and visible_rect.size.y <= 0.0:
			issues.append("vertical_not_intersecting")

		var horizontal_bar := scroll.get_h_scroll_bar()
		var vertical_bar := scroll.get_v_scroll_bar()
		var horizontal_max := _scroll_max_offset(horizontal_bar)
		var vertical_max := _scroll_max_offset(vertical_bar)
		if not _scroll_offset_valid(after.x, horizontal_bar):
			issues.append("horizontal_offset_invalid")
		if not _scroll_offset_valid(after.y, vertical_bar):
			issues.append("vertical_offset_invalid")
		if horizontal_disabled and after.x != int(horizontal_bar.min_value):
			issues.append("horizontal_disabled_offset")
		if not horizontal_enclosed and (
			is_equal_approx(float(after.x), horizontal_bar.min_value)
			or is_equal_approx(float(after.x), horizontal_max)
		):
			issues.append("horizontal_clamped_unreachable")
		if not vertical_enclosed and control_rect.size.y <= viewport_rect.size.y and (
			is_equal_approx(float(after.y), vertical_bar.min_value)
			or is_equal_approx(float(after.y), vertical_max)
		):
			issues.append("vertical_clamped_unreachable")
		if not issues.is_empty():
			issues.sort()
			mismatches.append(
				"%s@%s:%s offsets=%d,%d->%d,%d ranges=%.0f,%.0f" % [
					control.name, scroll.name, ",".join(issues),
					before.x, before.y, after.x, after.y, horizontal_max, vertical_max,
				]
			)

	for state: Dictionary in scroll_states:
		var scroll := state["scroll"] as ScrollContainer
		scroll.scroll_horizontal = int(state["horizontal"])
		scroll.scroll_vertical = int(state["vertical"])
	if not scroll_states.is_empty():
		await h.frames(2)
	for state: Dictionary in scroll_states:
		var scroll := state["scroll"] as ScrollContainer
		var expected := Vector2i(int(state["horizontal"]), int(state["vertical"]))
		var restored := Vector2i(scroll.scroll_horizontal, scroll.scroll_vertical)
		if restored != expected:
			mismatches.append(
				"%s:restore offsets=%d,%d->%d,%d" % [
					scroll.name, expected.x, expected.y, restored.x, restored.y,
				]
			)
	mismatches.sort()
	return mismatches


func _axis_encloses(
		outer_start: float, outer_end: float, inner_start: float, inner_end: float,
		) -> bool:
	const GEOMETRY_EPSILON := 0.5
	return (
		inner_start >= outer_start - GEOMETRY_EPSILON
		and inner_end <= outer_end + GEOMETRY_EPSILON
	)


func _scroll_max_offset(scroll_bar: ScrollBar) -> float:
	return maxf(scroll_bar.min_value, scroll_bar.max_value - scroll_bar.page)


func _scroll_offset_valid(offset: int, scroll_bar: ScrollBar) -> bool:
	const OFFSET_EPSILON := 0.5
	var maximum := _scroll_max_offset(scroll_bar)
	return (
		is_finite(scroll_bar.min_value) and is_finite(maximum)
		and float(offset) >= scroll_bar.min_value - OFFSET_EPSILON
		and float(offset) <= maximum + OFFSET_EPSILON
	)


func _compare_rows(nodes: Array[Control], rows: Array, targets: bool) -> Dictionary:
	var missing: Array[String] = []
	var mismatched: Array[String] = []
	var matched_instances: Dictionary = {}
	for raw_row: Variant in rows:
		var row := raw_row as Dictionary
		var selector := String(row["selector"])
		var matches: Array[Control] = []
		for node: Control in nodes:
			if _selector_matches(selector, String(node.name)):
				matches.append(node)
		var expected_count := int(row.get("expected_count", 1))
		if matches.size() < expected_count:
			missing.append("%s:%d/%d" % [selector, matches.size(), expected_count])
		if matches.size() > expected_count:
			mismatched.append("%s count %d/%d" % [selector, matches.size(), expected_count])
		for node: Control in matches:
			matched_instances[node.get_instance_id()] = true
			var issues := _row_issues(node, row, targets)
			if not issues.is_empty():
				mismatched.append("%s:%s" % [node.name, ",".join(issues)])
	var unexpected: Array[String] = []
	for node: Control in nodes:
		if not matched_instances.has(node.get_instance_id()):
			unexpected.append(String(node.name))
	missing.sort()
	unexpected.sort()
	mismatched.sort()
	return {
		"ok": missing.is_empty() and unexpected.is_empty() and mismatched.is_empty(),
		"count": nodes.size(),
		"missing": missing,
		"unexpected": unexpected,
		"mismatched": mismatched,
	}


func _row_issues(node: Control, row: Dictionary, targets: bool) -> Array[String]:
	var issues: Array[String] = []
	var expected_type := String(row["type"])
	if not _is_expected_type(node, expected_type):
		issues.append("type=%s" % node.get_class())
	if row.has("enabled") and targets:
		var enabled := not _target_disabled(node)
		if enabled != bool(row["enabled"]):
			issues.append("enabled=%s" % enabled)
	var allowed: Array = row.get("variation", []) as Array
	if not allowed.has(String(node.theme_type_variation)):
		issues.append("variation=%s" % node.theme_type_variation)
	if _active_mode == &"text200" and BASE_FONT_SIZES.has(node.theme_type_variation):
		var expected_size := int(BASE_FONT_SIZES[node.theme_type_variation]) * 2
		var actual_size := node.get_theme_font_size(&"font_size")
		if actual_size != expected_size:
			issues.append("font_size=%d expected=%d" % [actual_size, expected_size])
	var owner := _ancestor_named(node, StringName(row["owner"]))
	if owner == null:
		issues.append("owner=%s" % String(row["owner"]))
	elif owner is Control and not (
			(owner as Control).get_global_rect().encloses(node.get_global_rect())
		):
		issues.append("outside_owner=%s" % String(row["owner"]))
	if targets and (node.size.x < 44.0 or node.size.y < 44.0):
		issues.append("target=%s" % node.size)
	if not targets and _logical_text(node).is_empty():
		issues.append("empty_text")
	var landscape := node.get_viewport_rect().size.x >= node.get_viewport_rect().size.y
	if _active_mode == &"standard" and landscape:
		var scroll := _nearest_scroll(node)
		if scroll == null:
			var viewport_rect := Rect2(Vector2.ZERO, node.get_viewport_rect().size)
			if not viewport_rect.encloses(node.get_global_rect()):
				issues.append("outside_viewport")
	if node is ItemList and not _item_list_text_fits(node as ItemList):
		issues.append("item_text_clipped")
	if node is AetheriaButton:
		var presented := node.get_node_or_null("PresentationLabel") as Label
		if presented != null and not node.get_global_rect().encloses(presented.get_global_rect()):
			issues.append("presentation_outside_button")
	return issues


func _discover_targets(root: Node) -> Array[Control]:
	var nodes: Array[Control] = []
	for node: Node in _all_nodes(root):
		if node is Control and (node as Control).is_visible_in_tree():
			if node is BaseButton or node is ItemList:
				nodes.append(node as Control)
	return nodes


func _discover_text(root: Node) -> Array[Control]:
	var nodes: Array[Control] = []
	for node: Node in _all_nodes(root):
		if not node is Control or not (node as Control).is_visible_in_tree():
			continue
		if node is Label and node.name != &"PresentationLabel":
			nodes.append(node as Control)
		elif node is BaseButton and not (node as BaseButton).text.is_empty():
			nodes.append(node as Control)
		elif node is ItemList and (node as ItemList).item_count > 0:
			nodes.append(node as Control)
	return nodes


func _check_focus_order(content: Control, raw_order: Array) -> Dictionary:
	var failures: Array[String] = []
	var order: Array[Control] = []
	for raw_name: Variant in raw_order:
		var node := content.find_child(String(raw_name), true, false) as Control
		if node == null:
			failures.append("missing:%s" % raw_name)
		else:
			order.append(node)
	for index: int in order.size():
		var current := order[index]
		var expected_previous := order[(index - 1 + order.size()) % order.size()]
		var expected_next := order[(index + 1) % order.size()]
		if current.get_node_or_null(current.focus_previous) != expected_previous:
			failures.append("%s.previous" % current.name)
		if current.get_node_or_null(current.focus_next) != expected_next:
			failures.append("%s.next" % current.name)
	return {"ok": failures.is_empty(), "failures": failures}


func _target_disabled(node: Control) -> bool:
	if node is BaseButton:
		return (node as BaseButton).disabled
	if node is ItemList:
		return (node as ItemList).item_count == 0
	return true


func _logical_text(node: Control) -> String:
	if node is Label:
		return (node as Label).text
	if node is BaseButton:
		return (node as BaseButton).text
	if node is ItemList:
		var item_list := node as ItemList
		var selected := item_list.get_selected_items()
		if not selected.is_empty():
			return item_list.get_item_text(selected[0])
		if item_list.item_count > 0:
			return item_list.get_item_text(0)
	return ""


func _selector_matches(selector: String, node_name: String) -> bool:
	if selector.ends_with("*"):
		return node_name.begins_with(selector.trim_suffix("*"))
	return selector == node_name


func _is_expected_type(node: Control, expected: String) -> bool:
	match expected:
		"Button":
			return node is Button
		"Label":
			return node is Label
		"ItemList":
			return node is ItemList
	return false


func _has_ancestor_named(node: Node, expected: StringName) -> bool:
	return _ancestor_named(node, expected) != null


func _ancestor_named(node: Node, expected: StringName) -> Node:
	var current: Node = node.get_parent()
	while current != null:
		if current.name == expected:
			return current
		current = current.get_parent()
	return null


func _nearest_scroll(node: Node) -> ScrollContainer:
	var current: Node = node.get_parent()
	while current != null:
		if current is ScrollContainer:
			return current as ScrollContainer
		current = current.get_parent()
	return null


func _item_list_text_fits(item_list: ItemList) -> bool:
	var required := _item_list_required_width(item_list)
	if required <= item_list.size.x:
		return true
	var presented := item_list.get_node_or_null("PresentationLabel") as Label
	if presented == null or presented.text.is_empty():
		return false
	var line_count := ceili(required / item_list.size.x)
	var font := item_list.get_theme_font(&"font")
	var font_size := item_list.get_theme_font_size(&"font_size")
	return font.get_height(font_size) * line_count + 32.0 <= item_list.size.y


func _item_list_required_width(item_list: ItemList) -> float:
	var font := item_list.get_theme_font(&"font")
	var font_size := item_list.get_theme_font_size(&"font_size")
	var required := 0.0
	for index: int in item_list.item_count:
		var width := font.get_string_size(
			item_list.get_item_text(index), HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size,
		).x
		required = maxf(required, width + 32.0)
	return required


func _all_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	for child: Node in root.get_children():
		nodes.append(child)
		nodes.append_array(_all_nodes(child))
	return nodes


func _fixture_root(h: SelfTestHarness, fixture_name: StringName) -> Control:
	var game := h.autoload("Game")
	var current := game.get("content") as Node
	if current != null and is_instance_valid(current):
		current.queue_free()
	var fixture := Control.new()
	fixture.name = fixture_name
	fixture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fixture.theme = load(THEME_PATH) as Theme
	h.root.add_child(fixture)
	game.set("content", fixture)
	return fixture


func _backdrop() -> ColorRect:
	var background := ColorRect.new()
	background.color = Color.html("111827FF")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return background


func _rendered_text_height(image: Image, rect: Rect2, font_color: Color) -> int:
	var left := clampi(floori(rect.position.x), 0, image.get_width() - 1)
	var right := clampi(ceili(rect.end.x), 1, image.get_width())
	var top := clampi(floori(rect.position.y), 0, image.get_height() - 1)
	var bottom := clampi(ceili(rect.end.y), 1, image.get_height())
	var first := -1
	var last := -1
	for y: int in range(top, bottom):
		var row_has_text := false
		for x: int in range(left, right):
			var pixel := image.get_pixel(x, y)
			var delta := maxf(
				absf(pixel.r - font_color.r), maxf(
					absf(pixel.g - font_color.g), absf(pixel.b - font_color.b),
				),
			)
			if delta < TEXT_COLOR_FLOOR:
				row_has_text = true
				break
		if row_has_text:
			if first < 0:
				first = y
			last = y
	return 0 if first < 0 else last - first + 1


func _write_supplemental_report(h: SelfTestHarness) -> void:
	var failures := 0
	for report: Dictionary in _inventory_reports:
		if not bool(report["ok"]):
			failures += 1
	var report := {
		"schema_version": 1,
		"scenario": "ui_shell_floor",
		"seed": h.seed_value,
		"inventory_states": _inventory_reports.size(),
		"inventory_failures": failures,
		"completion_sentinel": true,
		"inventory": _inventory_reports,
	}
	if not _release_challenge.is_empty():
		report["release_challenge"] = _release_challenge
	var directory := String(h.get("_shots_dir"))
	var file := FileAccess.open("%s/ui-shell-report.json" % directory, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  ", false) + "\n")
		file.close()
