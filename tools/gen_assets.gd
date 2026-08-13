extends SceneTree

## Lane A asset generator: compiles the hand-authored pixel art into
## shipped PNGs + the asset manifest. Deterministic and idempotent — same
## art tables, byte-identical output (verified by the assets_floor gate).
## Run: godot --headless --path . -s tools/gen_assets.gd
## Every image passes the generator lint (palette membership, hard alpha,
## exact canvas) before it is written; any violation aborts with exit 1.

const Palette := preload("res://tools/pixel/palette.gd")
const Pix := preload("res://tools/pixel/pix.gd")
const ArtOperators := preload("res://tools/pixel/art_operators.gd")
const ArtEnemies := preload("res://tools/pixel/art_enemies.gd")
const ArtTiles := preload("res://tools/pixel/art_tiles.gd")
const ArtPortraits := preload("res://tools/pixel/art_portraits.gd")
const ArtProps := preload("res://tools/pixel/art_props.gd")

const OUT_SPRITES := "res://assets/sprites"
const OUT_PORTRAITS := "res://assets/portraits"
const OUT_SHEET := "res://artifacts/lane_a"
const ROUND5_IMPORTER := "res://tools/art_pipeline/characters/import_round5_sheets.py"
const PROVENANCE_TOOL := "res://tools/presentation_qa/provenance.py"
const PROVENANCE_INVENTORY := "user://aui00_provenance_inventory.json"
const ROUND5_CHARACTER_PLACEHOLDER := false

var _failed := false
var _manifest := AssetManifest.new()


func _initialize() -> void:
	for dir: String in [OUT_SPRITES, OUT_PORTRAITS, OUT_SHEET]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var sheet_cells: Array[Image] = []
	var portrait_cells: Array[Image] = []

	# Probe reservation is a hard lint across EVERY sprite class (P14.2):
	# exact WHITE (sprung-flash probe) and SKY (charm probe) are banned from
	# tiles, props, operators, portraits, and enemy frames. Two sanctioned
	# exemptions: icon_* chips keep the full palette (UI-only, never
	# probed) and charmed variants keep SKY (it IS the probed charm signal).
	var reserved_free: Array[Color] = []
	for c: Color in Palette.ALL:
		if c != Palette.WHITE and c != Palette.SKY:
			reserved_free.append(c)
	var charm_allowed: Array[Color] = []
	for c: Color in Palette.ALL:
		if c != Palette.WHITE:
			charm_allowed.append(c)

	# tiles (32x16 iso diamonds; elevated 32x24)
	var tiles := ArtTiles.build()
	for tile_id: StringName in tiles:
		var img: Image = tiles[tile_id]
		var tile_size := ArtTiles.size_of(tile_id)
		_lint_and_save(img, tile_size, "%s/%s.png" % [OUT_SPRITES, tile_id], reserved_free)
		_record(tile_id, "%s/%s.png" % [OUT_SPRITES, tile_id], 1, tile_size)
		sheet_cells.append(Pix.upscale(img, 4))

	# operators: battle frames + portrait bust
	for op_id: StringName in ArtOperators.OPERATOR_SHEETS:
		var def := load("res://data/operators/%s.tres" % op_id) as OperatorDef
		var frames := ArtOperators.build(op_id, def.op_class)
		for i: int in frames.size():
			_lint_and_save(
				frames[i], ArtOperators.SIZE, "%s/%s_%d.png" % [OUT_SPRITES, op_id, i],
				reserved_free
			)
		_record(
			def.sprite_id, "%s/%s_%%d.png" % [OUT_SPRITES, op_id], frames.size(),
			ArtOperators.SIZE, ROUND5_CHARACTER_PLACEHOLDER
		)
		for i: int in [0, 2, 4]:
			sheet_cells.append(Pix.upscale(frames[i], 4))
		var portrait := ArtPortraits.build(
			op_id, def.op_class, ArtOperators.OPERATOR_SHEETS[op_id]
		)
		_lint_and_save(
			portrait,
			ArtPortraits.SIZE * ArtPortraits.UPSCALE,
			"%s/%s.png" % [OUT_PORTRAITS, op_id],
			reserved_free
		)
		# fidelity pass (art v2) signed off: card backdrop + glint/blush on
		# the roster-spread archetypes — placeholder flag retired (§6.3)
		_record(
			StringName("portrait_%s" % def.portrait_id),
			"%s/%s.png" % [OUT_PORTRAITS, op_id],
			1,
			ArtPortraits.SIZE * ArtPortraits.UPSCALE,
			ROUND5_CHARACTER_PLACEHOLDER
		)
		portrait_cells.append(portrait)

	# enemies + derived charmed variants
	for enemy_id: StringName in ArtEnemies.ENEMY_ART:
		var frames := ArtEnemies.build(enemy_id)
		var art: Dictionary = ArtEnemies.ENEMY_ART[enemy_id]
		var enemy_size: Vector2i = art["size"]
		for i: int in frames.size():
			_lint_and_save(
				frames[i], enemy_size, "%s/%s_%d.png" % [OUT_SPRITES, enemy_id, i],
				reserved_free
			)
		var def := load("res://data/enemies/%s.tres" % enemy_id) as EnemyDef
		_record(
			def.sprite_id, "%s/%s_%%d.png" % [OUT_SPRITES, enemy_id], frames.size(), enemy_size,
			ROUND5_CHARACTER_PLACEHOLDER
		)
		sheet_cells.append(Pix.upscale(frames[0], 4))
		if not def.charm_immune:
			var charmed := Pix.charmed_variant(frames[0])
			_lint_and_save(
				charmed, enemy_size, "%s/%s_charmed_0.png" % [OUT_SPRITES, enemy_id],
				charm_allowed
			)
			_lint_and_save(
				Pix.shifted(charmed, Vector2i(0, 1)),
				enemy_size,
				"%s/%s_charmed_1.png" % [OUT_SPRITES, enemy_id],
				charm_allowed
			)
			_record(
				StringName("%s_charmed" % def.sprite_id),
				"%s/%s_charmed_%%d.png" % [OUT_SPRITES, enemy_id],
				2,
				enemy_size,
				ROUND5_CHARACTER_PLACEHOLDER
			)
			sheet_cells.append(Pix.upscale(charmed, 4))

	# Production character art: the procedural pixels above remain a deterministic
	# fallback, then the approved Round-5 source sheets replace the exact legacy
	# runtime paths and frame counts. Gameplay/UI code stays manifest-only.
	if not _import_round5_character_art():
		quit(1)
		return

	# traps + spell icons: traps carry the reservation lint, icon chips
	# keep the full palette (sanctioned exemption above)
	var props := ArtProps.build()
	for prop_id: StringName in props:
		var img: Image = props[prop_id]
		var is_icon := String(prop_id).begins_with("icon_")
		var size: Vector2i = ArtProps.ICON_SIZE if is_icon else ArtProps.TRAP_SIZE
		_lint_and_save(
			img, size, "%s/%s.png" % [OUT_SPRITES, prop_id],
			Palette.ALL if is_icon else reserved_free
		)
		_record(prop_id, "%s/%s.png" % [OUT_SPRITES, prop_id], 1, size)
		sheet_cells.append(Pix.upscale(img, 4))

	# AUI-10R uses its own deterministic Python pipeline. Import its
	# contract-backed runtime inventory before canonical provenance/manifest save.
	_record_s1_world_assets()

	_write_sheet(sheet_cells, "calibration.png")
	_write_sheet(portrait_cells, "portraits.png")
	_write_stage_collage(tiles)
	if _failed:
		quit(1)
		return
	if not _generate_provenance():
		quit(1)
		return
	var err := ResourceSaver.save(_manifest, "res://assets/manifest.tres")
	if err != OK:
		push_error("[gen_assets] manifest save failed: %s" % err)
		quit(1)
		return
	print("[gen_assets] OK — %d manifest entries" % _manifest.entries.size())
	quit(0)


func _import_round5_character_art() -> bool:
	var output: Array = []
	var code := OS.execute(
		"/usr/bin/python3",
		[
			ProjectSettings.globalize_path(ROUND5_IMPORTER),
			"--repo", ProjectSettings.globalize_path("res://"),
			"--review-dir", ProjectSettings.globalize_path(OUT_SHEET + "/round5"),
		],
		output,
		true,
	)
	if code != 0:
		push_error("[gen_assets] Round-5 import failed (%d): %s" % [code, "\n".join(output)])
		return false
	return true


## Every entry carries its native size (P12.1 manifest schema pin) — a
## zero size is a generator red, so no asset ships unsized.
func _record(
	id: StringName, pattern: String, frames: int, size: Vector2i, placeholder := false
) -> void:
	if size == Vector2i.ZERO:
		push_error("[gen_assets] RECORD %s: missing size" % id)
		_failed = true
		return
	_manifest.entries[id] = {
		"pattern": pattern,
		"frames": frames,
		"size": size,
		"placeholder": placeholder,
		"pivot": AssetManifest.legacy_pivot(id, frames),
		"animations": AssetManifest.legacy_animations(frames),
		"provenance_sha256": "0".repeat(64),
	}


func _record_s1_world_assets() -> void:
	var contract_path := "res://art-src/world/s1/s1-world-asset-contract.json"
	var file := FileAccess.open(contract_path, FileAccess.READ)
	if file == null:
		push_error("[gen_assets] missing S1 world contract")
		_failed = true
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.has("assets") or not parsed["assets"] is Array:
		push_error("[gen_assets] malformed S1 world contract")
		_failed = true
		return
	for row: Variant in parsed["assets"]:
		if not row is Dictionary or not row.has("id") or not row.has("native_size"):
			push_error("[gen_assets] malformed S1 world asset row")
			_failed = true
			continue
		var id := StringName(row["id"])
		var native_size: Array = row["native_size"]
		if native_size.size() != 2:
			push_error("[gen_assets] invalid S1 native size for %s" % id)
			_failed = true
			continue
		var file_stem := String(id).trim_prefix("world.s1.").replace("_", "-")
		var path := "res://assets/world/s1/s1-%s.png" % file_stem
		if not FileAccess.file_exists(path):
			push_error("[gen_assets] missing S1 runtime asset %s" % path)
			_failed = true
			continue
		_record(id, path, 1, Vector2i(int(native_size[0]), int(native_size[1])), false)


func _generate_provenance() -> bool:
	var inventory: Dictionary = {}
	var ids: Array[StringName] = []
	for raw_id: Variant in _manifest.entries:
		ids.append(raw_id)
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	for id: StringName in ids:
		var entry: Dictionary = _manifest.entries[id]
		inventory[String(id)] = {
			"pattern": String(entry["pattern"]),
			"frames": int(entry["frames"]),
		}
	var file := FileAccess.open(PROVENANCE_INVENTORY, FileAccess.WRITE)
	if file == null:
		push_error("[gen_assets] failed to write provenance inventory")
		return false
	file.store_string(JSON.stringify({"entries": inventory}, "\t", true) + "\n")
	file.close()
	var output: Array = []
	var code := OS.execute(
		"/usr/bin/python3",
		[
			ProjectSettings.globalize_path(PROVENANCE_TOOL),
			"--repo",
			ProjectSettings.globalize_path("res://"),
			"--inventory",
			ProjectSettings.globalize_path(PROVENANCE_INVENTORY),
			"--write",
		],
		output,
		true,
	)
	if code != 0:
		push_error("[gen_assets] provenance failed (%d): %s" % [code, "\n".join(output)])
		return false
	for id: StringName in ids:
		var sidecar := "res://assets/provenance/%s.provenance.json" % id
		var digest := FileAccess.get_sha256(sidecar)
		if digest.length() != 64:
			push_error("[gen_assets] missing provenance digest for %s" % id)
			return false
		_manifest.entries[id]["provenance_sha256"] = digest
	return true


func _lint_and_save(
	img: Image, expected: Vector2i, path: String, allowed: Array[Color] = Palette.ALL
) -> void:
	var verdict := Pix.lint(img, expected, allowed)
	if verdict != "":
		push_error("[gen_assets] LINT %s: %s" % [path, verdict])
		_failed = true
		return
	img.save_png(ProjectSettings.globalize_path(path))


## One review sheet: cells on a checker card, 8 per row.
func _write_sheet(cells: Array[Image], file_name: String) -> void:
	if cells.is_empty():
		return
	var cell_px := 0
	for c: Image in cells:
		cell_px = maxi(cell_px, maxi(c.get_width(), c.get_height()))
	var pad := 8
	var columns := 8
	var row_count := ceili(float(cells.size()) / float(columns))
	var sheet := Image.create(
		columns * (cell_px + pad) + pad, row_count * (cell_px + pad) + pad, false,
		Image.FORMAT_RGBA8
	)
	sheet.fill(Color("242836"))
	for i: int in cells.size():
		var at := Vector2i(
			pad + (i % columns) * (cell_px + pad), pad + (i / columns) * (cell_px + pad)
		)
		# checker card behind each cell so silhouettes and holes both read
		for y: int in cell_px:
			for x: int in cell_px:
				if (x / 8 + y / 8) % 2 == 0:
					sheet.set_pixel(at.x + x, at.y + y, Color("2c3044"))
		Pix.blend(sheet, cells[i], at)
	sheet.save_png(ProjectSettings.globalize_path(OUT_SHEET + "/" + file_name))


## Mock-stage collage (P12.1): a 4x4 iso arrangement — an elevated cluster,
## a road strip from spawn gate to base, plus the backdrop/void/blocked
## fillers — so the human review sees composition, not isolated tiles.
func _write_stage_collage(tiles: Dictionary) -> void:
	var layout: Array[String] = ["ggEg", "gEEg", "srrb", "wvxg"]
	var ids := {
		"g": &"tile_ground", "E": &"tile_elevated", "r": &"tile_road",
		"s": &"tile_spawn", "b": &"tile_base", "w": &"tile_backdrop",
		"v": &"tile_void", "x": &"tile_blocked",
	}
	var pad := 4
	var origin := Vector2i(pad + 64, pad + 8)
	var sheet := Image.create(128 + 2 * pad, 72 + 2 * pad, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("242836"))
	# row-major blend = painter's order here (a tile only ever overdraws
	# strictly lower-depth neighbors)
	for cy: int in layout.size():
		for cx: int in layout[cy].length():
			var img: Image = tiles[ids[layout[cy][cx]]]
			var at := origin + Vector2i((cx - cy) * 16 - 16, (cx + cy) * 8)
			if layout[cy][cx] == "E":
				at.y -= 8
			Pix.blend(sheet, img, at)
	Pix.upscale(sheet, 4).save_png(
		ProjectSettings.globalize_path(OUT_SHEET + "/stage_collage.png")
	)
