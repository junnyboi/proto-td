extends RefCounted

## Lane A gate (parent plan §6): the asset floor. Machine half of the
## contact-sheet checklist — the manifest resolves every def's art at the
## pinned formats, charmed variants exist exactly for charmables, class
## sprites are pairwise distinct (pixel-diff proxy for the silhouette
## check), and a live contact sheet shots for the code-blind L5 review.
## Runs both lanes; the shot is windowed-only like every shot.

const CELL := 72.0


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	# P12.1: previous budget (the 3600 default) + 120 for the added checks
	h.max_frames = 3720
	var manifest := load("res://assets/manifest.tres") as AssetManifest
	h.check("manifest loads", manifest != null)
	if manifest == null:
		h.done()
		return
	h.check(
		"manifest carries the full inventory",
		manifest.entries.size() >= 40,
		"entries=%d" % manifest.entries.size()
	)

	# manifest schema (P12.1): every entry carries a nonzero native size
	var missing_size := 0
	for id: StringName in manifest.entries:
		var stored: Variant = manifest.entries[id].get("size")
		if not (stored is Vector2i) or stored == Vector2i.ZERO:
			missing_size += 1
	h.check(
		"every manifest entry carries a size", missing_size == 0, "missing=%d" % missing_size
	)

	# every entry's every frame loads at a sane native size
	var bad_frames := 0
	for id: StringName in manifest.entries:
		for frame: int in int(manifest.entries[id]["frames"]):
			var tex := Art.texture(id, frame)
			if tex == null or tex.get_width() < 16:
				bad_frames += 1
	h.check("every manifest frame loads", bad_frames == 0, "bad=%d" % bad_frames)

	# operators: 5 battle frames + portrait each
	var op_ids := _scan("res://data/operators")
	h.check("twelve operators on disk", op_ids.size() == 12)
	var op_ok := true
	for op_id: StringName in op_ids:
		var def := load("res://data/operators/%s.tres" % op_id) as OperatorDef
		op_ok = (
			op_ok
			and Art.frame_count(def.sprite_id) == 5
			and Art.texture(StringName("portrait_%s" % def.portrait_id)) != null
		)
	h.check("every operator has 5 frames + a portrait", op_ok)

	# enemies: 2 walk frames; charmed variants exactly for the charmables
	var charm_ok := true
	for enemy_id: StringName in _scan("res://data/enemies"):
		var def := load("res://data/enemies/%s.tres" % enemy_id) as EnemyDef
		var has_charmed := Art.frame_count(StringName("%s_charmed" % def.sprite_id)) == 2
		charm_ok = (
			charm_ok and Art.frame_count(def.sprite_id) == 2 and has_charmed != def.charm_immune
		)
	h.check("enemy frames + charmed variants match charm_immune", charm_ok)

	# tiles: every StageDef.Tile value + the road overlay + the P12.1
	# backdrop ring, each resolving with a nonzero manifest size
	var tile_names: Array[String] = [
		"void", "ground", "road", "elevated", "spawn", "base", "blocked", "backdrop"
	]
	var tile_ok := true
	for tile_name: String in tile_names:
		var tile_id := StringName("tile_%s" % tile_name)
		var sized := Art.texture(tile_id) != null and Art.size(tile_id) != Vector2i.ZERO
		tile_ok = tile_ok and sized
	h.check("all eight tile arts resolve with a size", tile_ok)
	var icon_ok := true
	for spell_id: StringName in _scan("res://data/spells"):
		icon_ok = icon_ok and Art.texture(StringName("icon_%s" % spell_id)) != null
	h.check("spell icons resolve", icon_ok)

	# distinctness proxy: class representatives pairwise differ substantially
	var reps: Array[Image] = []
	for rep_id: StringName in [
		&"vanguard_1", &"guard_1", &"defender_1", &"sniper_1", &"caster_1",
		&"witch_doctor_1",
	]:
		reps.append(Art.texture(rep_id, 0).get_image())
	var min_diff := 1 << 30
	for i: int in reps.size():
		for j: int in range(i + 1, reps.size()):
			min_diff = mini(min_diff, _diff(reps[i], reps[j]))
	h.check("class sprites pairwise distinct", min_diff > 120, "min_diff=%d" % min_diff)
	var grunt := Art.texture(&"grunt", 0).get_image()
	var grunt_charmed := Art.texture(&"grunt_charmed", 0).get_image()
	h.check(
		"charmed variant differs from base",
		_diff(grunt, grunt_charmed) > 150,
		"diff=%d" % _diff(grunt, grunt_charmed)
	)

	# live contact sheet for the L5 review shot (drawn over the title scene)
	var sheet := Node2D.new()
	sheet.name = "AssetsFloorSheet"
	h.root.add_child(sheet)
	var i := 0
	var ids: Array = manifest.entries.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	for id: StringName in ids:
		var tex := Art.texture(id, 0)
		if tex == null:
			continue
		var cell := TextureRect.new()
		cell.texture = tex
		cell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.size = Vector2.ONE * (CELL - 8.0)
		cell.position = Vector2(16 + (i % 16) * CELL, 16 + (i / 16) * CELL)
		sheet.add_child(cell)
		i += 1
	await h.frames(2)
	await h.shot("assets_contact_sheet")
	sheet.queue_free()
	h.done()


func _scan(dir_path: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for file: String in DirAccess.open(dir_path).get_files():
		if file.ends_with(".tres"):
			ids.append(StringName(file.trim_suffix(".tres")))
	return ids


func _diff(a: Image, b: Image) -> int:
	if a.get_size() != b.get_size():
		return 1 << 20
	var count := 0
	for y: int in a.get_height():
		for x: int in a.get_width():
			if a.get_pixel(x, y).to_html() != b.get_pixel(x, y).to_html():
				count += 1
	return count
