extends RefCounted

const BACKGROUND := Color("151923")
const FOREGROUND := Color("e8e3d5")
const DIRECTIONS: Array[StringName] = [&"se", &"ne", &"nw", &"sw"]
const CLASSES: Array[StringName] = [
	&"caster_1", &"caster_2", &"defender_1", &"defender_2",
	&"guard_1", &"guard_2", &"sniper_1", &"sniper_2",
	&"vanguard_1", &"vanguard_2",
]


func run(h: SelfTestHarness) -> void:
	h.max_frames = 900
	h.expect_done()
	await h.frames(2)
	Art._reset_manifests_for_test()
	h.check(
		"admitted operator catalog validates",
		OperatorVisualCatalog.validate_all().is_empty(),
		"errors=%s" % OperatorVisualCatalog.validate_all(),
	)
	h.check(
		"Shock Trooper is admitted without placeholders",
		OperatorVisualCatalog.get_animation(&"vanguard_1") != null
		and not OperatorVisualCatalog.get_animation(&"vanguard_1").placeholder,
	)
	h.check(
		"Sword Saint is admitted without placeholders",
		OperatorVisualCatalog.get_animation(&"guard_2") != null
		and not OperatorVisualCatalog.get_animation(&"guard_2").placeholder,
	)
	h.check(
		"Witch Doctor resolves exact Mage Apprentice visual resource",
		OperatorVisualCatalog.get_animation(&"witch_doctor_1")
		== OperatorVisualCatalog.get_animation(&"caster_1"),
	)
	var swordmaster := OperatorVisualCatalog.get_animation(&"guard_1")
	h.check(
		"Swordmaster declares exactly attack NE from SE",
		swordmaster != null
		and swordmaster.placeholder
		and swordmaster.placeholder_source_by_logical_id
		== {&"op_anim_guard_1_attack_ne": &"se"},
	)
	for template_id: StringName in CLASSES:
		var animation := OperatorVisualCatalog.get_animation(template_id)
		h.check("%s animation resource exists" % template_id, animation != null)
		if animation == null:
			continue
		await _family(h, template_id, &"idle", animation)
		await _family(h, template_id, &"attack", animation)
	Art._reset_manifests_for_test()
	h.done()


func _family(
	h: SelfTestHarness,
	template_id: StringName,
	family: StringName,
	animation: OperatorAnimationDef,
) -> void:
	var screen := ColorRect.new()
	screen.name = "OperatorAnimationCatalog"
	screen.color = BACKGROUND
	screen.size = h.root.size
	h.root.add_child(screen)
	var title := Label.new()
	title.text = "%s  %s  —  SE / NE / NW / SW" % [template_id, family]
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", FOREGROUND)
	title.position = Vector2(40, 24)
	screen.add_child(title)
	var mapping := (
		animation.idle_by_direction if family == &"idle" else animation.attack_by_direction
	)
	var frame_count := (
		animation.idle_frame_count if family == &"idle" else animation.attack_frame_count
	)
	var sample_frames: Array[int] = [0, floori(float(frame_count) / 2.0), frame_count - 1]
	var texture_count := 0
	var frame_hashes: Dictionary = {}
	for direction_index: int in DIRECTIONS.size():
		var direction := DIRECTIONS[direction_index]
		var logical_id := StringName(mapping[direction])
		var direction_label := Label.new()
		direction_label.text = String(direction).to_upper()
		direction_label.position = Vector2(52 + direction_index * 300, 90)
		direction_label.add_theme_font_size_override("font_size", 22)
		direction_label.add_theme_color_override("font_color", FOREGROUND)
		screen.add_child(direction_label)
		for sample_index: int in sample_frames.size():
			var frame := sample_frames[sample_index]
			var texture := Art.texture(logical_id, frame)
			if texture == null:
				continue
			texture_count += 1
			var frame_hash: int = hash(texture.get_image().get_data())
			frame_hashes[frame_hash] = true
			var view := TextureRect.new()
			view.texture = texture
			view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			view.size = Vector2(88, 88)
			view.position = Vector2(42 + direction_index * 300 + sample_index * 92, 142)
			screen.add_child(view)
	h.check(
		"%s %s exposes twelve sampled textures" % [template_id, family],
		texture_count == 12,
		"textures=%d" % texture_count,
	)
	h.check(
		"%s %s sampled pixels are not all identical" % [template_id, family],
		frame_hashes.size() > 4,
		"hashes=%d" % frame_hashes.size(),
	)
	await h.frames(3)
	await h.shot("operator_%s_%s" % [template_id, family])
	screen.queue_free()
	await h.frames(1)
