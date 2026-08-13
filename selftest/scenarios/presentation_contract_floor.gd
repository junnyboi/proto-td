extends RefCounted

const DARK := Color("242836")
const LIGHT := Color("e8e3d5")
const INK := Color("1a1c2c")
const PALE := Color("c7d6e8")
const CELL := Vector2(88, 88)


func run(h: SelfTestHarness) -> void:
	h.max_frames = 600
	h.expect_done()
	await h.frames(3)
	var manifest := load("res://assets/manifest.tres") as AssetManifest
	var registry := load(
		"res://data/presentation/probe_color_owners.tres"
	) as ProbeColorOwnerRegistry
	h.check("manifest v2 loads", manifest != null)
	h.check("probe owner registry loads", registry != null)
	if manifest == null or registry == null:
		h.done()
		return
	h.check(
		"manifest contract is exact",
		manifest.validate_contract().is_empty(),
		"errors=%s" % manifest.validate_contract(),
	)
	h.check(
		"probe owner contract has exact 20 rows",
		registry.validate_contract().is_empty() and registry.entries.size() == 20,
		"rows=%d errors=%s" % [registry.entries.size(), registry.validate_contract()],
	)

	await _asset_state(
		h,
		"terrain_traps_dark",
		DARK,
		PALE,
		[
			&"tile_void", &"tile_ground", &"tile_road", &"tile_elevated", &"tile_spawn",
			&"tile_base", &"tile_blocked", &"tile_backdrop", &"trap_spike_armed",
			&"trap_spike_sprung", &"trap_tar",
		],
	)
	await _asset_state(
		h,
		"terrain_traps_light",
		LIGHT,
		INK,
		[
			&"tile_void", &"tile_ground", &"tile_road", &"tile_elevated", &"tile_spawn",
			&"tile_base", &"tile_blocked", &"tile_backdrop", &"trap_spike_armed",
			&"trap_spike_sprung", &"trap_tar",
		],
	)
	await _operator_state(h)
	await _enemy_state(h)
	await _portrait_icon_state(h)
	await _cue_state(h, false)
	await _cue_state(h, true)

	var game := h.autoload("Game")
	game.call("open_title")
	h.root.size = Vector2i(1920, 1080)
	await h.frames(4)
	var title := game.get("content") as Control
	var start := title.find_child("StartButton", true, false) as Button if title != null else null
	h.check("title root exists at 1920x1080", title != null, "viewport=%s" % h.root.size)
	h.check("title start control exists", start != null)
	var title_measure := _measure_control(title, h.root.size)
	await h.shot("title_1920x1080")

	game.call("start_campaign")
	await h.frames(4)
	h.root.size = Vector2i(960, 720)
	await h.frames(4)
	var staging := game.get("content") as Control
	h.check("staging root exists at 960x720", staging != null, "viewport=%s" % h.root.size)
	var staging_measure := _measure_control(staging, h.root.size)
	await h.shot("staging_960x720")

	game.call("open_title")
	h.root.size = Vector2i(720, 1280)
	await h.frames(4)
	var portrait_title := game.get("content") as Control
	h.check("title root exists at 720x1280", portrait_title != null, "viewport=%s" % h.root.size)
	var summary := _summary_overlay(title_measure, staging_measure)
	h.root.add_child(summary)
	await h.frames(3)
	await h.shot("title_staging_portrait_summary_720x1280")
	summary.queue_free()

	h.root.size = Vector2i(1280, 720)
	await h.frames(3)
	h.check("viewport restored", h.root.size == Vector2i(1280, 720), "viewport=%s" % h.root.size)
	h.done()


func _asset_state(
	h: SelfTestHarness, shot_name: String, background: Color, ink: Color,
	ids: Array[StringName]
) -> void:
	var sheet := _sheet(background, ink, shot_name.replace("_", " ").to_upper())
	var grid := GridContainer.new()
	grid.columns = 6
	grid.position = Vector2(48, 88)
	sheet.add_child(grid)
	for id: StringName in ids:
		grid.add_child(_asset_card(id, ink))
	h.root.add_child(sheet)
	await h.frames(3)
	await h.shot(shot_name)
	sheet.queue_free()
	await h.frames(1)


func _operator_state(h: SelfTestHarness) -> void:
	var sheet := _sheet(DARK, PALE, "OPERATOR IDLE / ATTACK / DEPLOY")
	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(84, 90)
	sheet.add_child(grid)
	for id: StringName in [&"vanguard_1", &"guard_1", &"defender_1", &"caster_1"]:
		var column := VBoxContainer.new()
		column.custom_minimum_size = Vector2(250, 330)
		column.add_child(_label(String(id), PALE, 20))
		for animation: StringName in [&"idle", &"attack", &"deploy"]:
			var row := HBoxContainer.new()
			row.add_child(_label(String(animation), PALE, 16))
			var tex := Art.animation_texture(id, animation, 0)
			row.add_child(_texture(tex, Vector2(64, 64)))
			column.add_child(row)
		grid.add_child(column)
	h.root.add_child(sheet)
	await h.frames(3)
	await h.shot("operator_regions")
	sheet.queue_free()
	await h.frames(1)


func _enemy_state(h: SelfTestHarness) -> void:
	var sheet := _sheet(DARK, PALE, "ENEMY BASE / CHARMED DIFFERENTIAL")
	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(92, 110)
	sheet.add_child(grid)
	for id: StringName in [&"grunt", &"heavy", &"runner", &"spellcaster"]:
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(250, 250)
		card.add_child(_label(String(id), PALE, 20))
		var pair := HBoxContainer.new()
		pair.add_child(_texture(Art.texture(id, 0), CELL))
		pair.add_child(_texture(Art.texture(StringName("%s_charmed" % id), 0), CELL))
		card.add_child(pair)
		grid.add_child(card)
	h.root.add_child(sheet)
	await h.frames(3)
	await h.shot("enemy_charmed_differential")
	sheet.queue_free()
	await h.frames(1)


func _portrait_icon_state(h: SelfTestHarness) -> void:
	var sheet := _sheet(LIGHT, INK, "PORTRAITS / ICON LEGACY EXCEPTIONS")
	var grid := GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(48, 92)
	sheet.add_child(grid)
	for id: StringName in [
		&"portrait_vanguard_1", &"portrait_guard_1", &"portrait_defender_1",
		&"portrait_sniper_1", &"portrait_caster_1", &"icon_bolt", &"icon_charm",
	]:
		grid.add_child(_asset_card(id, INK))
	grid.add_child(_label("WHITE icons are registered legacy exceptions", INK, 18))
	h.root.add_child(sheet)
	await h.frames(3)
	await h.shot("portrait_icon_inventory")
	sheet.queue_free()
	await h.frames(1)


func _cue_state(h: SelfTestHarness, high_contrast: bool) -> void:
	var background := Color.BLACK if high_contrast else DARK
	var foreground := Color.WHITE if high_contrast else PALE
	var sheet := _sheet(
		background,
		foreground,
		"TACTICAL CUES — HIGH CONTRAST" if high_contrast else "TACTICAL CUES — STANDARD",
	)
	var names := ["LEGAL", "INVALID", "RANGE", "SKILL", "ROUTE", "WARNING", "LETHAL"]
	var colors := [
		Color("6abe30"), Color("d95763"), Color("5b6ee1"), Color("df7126"),
		Color("8f974a"), Color("fbf236"), Color("ac3232"),
	]
	for index: int in names.size():
		var card := Control.new()
		card.position = Vector2(68 + index * 165, 240)
		card.custom_minimum_size = Vector2(140, 220)
		card.add_child(_cue_symbol(index, foreground if high_contrast else colors[index]))
		var text := _label(names[index], foreground, 18)
		text.position = Vector2(15, 140)
		card.add_child(text)
		sheet.add_child(card)
	h.root.add_child(sheet)
	await h.frames(3)
	await h.shot("cue_tokens_high_contrast" if high_contrast else "cue_tokens_standard")
	sheet.queue_free()
	await h.frames(1)


func _cue_symbol(index: int, color: Color) -> Node2D:
	var symbol := Node2D.new()
	var diamond := PackedVector2Array([
		Vector2(70, 0), Vector2(130, 60), Vector2(70, 120), Vector2(10, 60), Vector2(70, 0),
	])
	if index == 0:
		var fill := Polygon2D.new()
		fill.polygon = diamond.slice(0, 4)
		fill.color = color
		symbol.add_child(fill)
	elif index == 1:
		for segment: PackedVector2Array in [
			PackedVector2Array([Vector2(70, 0), Vector2(98, 28)]),
			PackedVector2Array([Vector2(130, 60), Vector2(102, 88)]),
			PackedVector2Array([Vector2(70, 120), Vector2(42, 92)]),
			PackedVector2Array([Vector2(10, 60), Vector2(38, 32)]),
		]:
			symbol.add_child(_line(segment, color, 8.0))
	elif index == 2:
		symbol.add_child(_line(diamond, color, 4.0))
		for tick: PackedVector2Array in [
			PackedVector2Array([Vector2(70, -12), Vector2(70, 14)]),
			PackedVector2Array([Vector2(142, 60), Vector2(116, 60)]),
			PackedVector2Array([Vector2(70, 132), Vector2(70, 106)]),
			PackedVector2Array([Vector2(-2, 60), Vector2(24, 60)]),
		]:
			symbol.add_child(_line(tick, color, 7.0))
	elif index == 3:
		var ring := PackedVector2Array()
		for point: int in 25:
			var angle := TAU * float(point) / 24.0
			ring.append(Vector2(70, 60) + Vector2(cos(angle), sin(angle)) * 52.0)
		symbol.add_child(_line(ring, color, 6.0))
		symbol.add_child(_line(PackedVector2Array([Vector2(70, 18), Vector2(70, 42)]), color, 5.0))
		symbol.add_child(_line(PackedVector2Array([Vector2(70, 78), Vector2(70, 102)]), color, 5.0))
	elif index == 4:
		for offset: float in [20.0, 55.0, 90.0]:
			symbol.add_child(
				_line(
					PackedVector2Array([
						Vector2(offset, 22), Vector2(offset + 32, 60), Vector2(offset, 98),
					]),
					color,
					7.0,
				)
			)
	elif index == 5:
		var warning := Polygon2D.new()
		warning.polygon = PackedVector2Array([Vector2(70, 0), Vector2(135, 118), Vector2(5, 118)])
		warning.color = color
		symbol.add_child(warning)
		var cutout := _line(PackedVector2Array([Vector2(70, 36), Vector2(70, 78)]), INK, 8.0)
		symbol.add_child(cutout)
	else:
		symbol.add_child(
			_line(PackedVector2Array([Vector2(5, 18), Vector2(55, 60), Vector2(5, 102)]), color, 9.0)
		)
		symbol.add_child(
			_line(PackedVector2Array([Vector2(135, 18), Vector2(85, 60), Vector2(135, 102)]), color, 9.0)
		)
	return symbol


func _line(points: PackedVector2Array, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.points = points
	line.default_color = color
	line.width = width
	line.antialiased = false
	return line


func _sheet(background: Color, ink: Color, title: String) -> Control:
	var sheet := Control.new()
	sheet.name = "PresentationContractSheet"
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = background
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.add_child(backdrop)
	var heading := _label(title, ink, 28)
	heading.position = Vector2(48, 28)
	sheet.add_child(heading)
	return sheet


func _asset_card(id: StringName, ink: Color) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(190, 160)
	card.add_child(_texture(Art.texture(id, 0), CELL))
	card.add_child(_label(String(id), ink, 16))
	return card


func _texture(texture: Texture2D, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = size
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect


func _label(text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	return label


func _measure_control(control: Control, viewport: Vector2i) -> String:
	if control == null:
		return "missing at %s" % viewport
	var rect := control.get_global_rect()
	return "viewport=%s rect=(%.1f,%.1f %.1fx%.1f)" % [
		viewport, rect.position.x, rect.position.y, rect.size.x, rect.size.y,
	]


func _summary_overlay(title_measure: String, staging_measure: String) -> Control:
	var panel := ColorRect.new()
	panel.name = "PresentationMeasuredSummary"
	panel.color = Color(0.05, 0.06, 0.09, 0.94)
	panel.position = Vector2(32, 900)
	panel.size = Vector2(656, 300)
	var title := _label("CURRENT RESPONSIVE BASELINE", Color.WHITE, 22)
	title.position = Vector2(24, 20)
	panel.add_child(title)
	var body := _label(
		"Title landscape: %s\nStaging compact: %s\nPortrait: 720x1280\n"
		+ "Measurement only — no future AUI target is claimed.",
		Color("c7d6e8"),
		16,
	)
	body.position = Vector2(24, 70)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size = Vector2(608, 200)
	body.text = body.text % [title_measure, staging_measure]
	panel.add_child(body)
	return panel
