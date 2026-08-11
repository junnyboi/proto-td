extends RefCounted

## P12.0 floor scenario (td-phase-12 §Phase 12.0). Proves the projection
## actually moved (road stand-in present at the ISO center, absent at the
## OLD square-grid center), that placement input picks through the new
## seam end-to-end, and that the deploy highlights render ABOVE tiles (the
## z-band regression probe — plan-lint finding 3). Frame budget pinned at
## 900 (td-phase-12 §Pinned Parameters).

const ROAD_PROBE := Vector2i(16, 8)
const TARGET_CELL := Vector2i(3, 2)
const ELEV_CELL := Vector2i(2, 1)


func run(h: SelfTestHarness) -> void:
	h.max_frames = 900
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null)
	if model == null:
		return
	var view := game.get("content") as Node2D
	var stage: StageDef = model.stage
	h.expect_done()

	# --- seam round-trip through the live view (model-side, both lanes) ---
	for cell: Vector2i in [Vector2i(0, 0), TARGET_CELL, ELEV_CELL]:
		var picked: Vector2i = view.call("cell_at", view.call("cell_center", cell))
		h.check("cell_at(cell_center(%s)) round-trips" % cell, picked == cell, "got %s" % picked)

	# --- pick a road cell whose OLD square-grid center now lies off-road ---
	# old projection: origin = (viewport - grid*64)/2, center = origin +
	# (cell + 0.5)*64. The derivation is loud: no qualifying cell = FAIL.
	var viewport := (view as Node2D).get_viewport_rect().size
	var old_origin := (viewport - Vector2(stage.grid_size()) * 64.0) * 0.5
	var road_cells: Dictionary = {}
	for cell: Vector2i in stage.path_cells(0):
		if stage.tile_at(cell) != StageDef.Tile.GROUND:
			continue
		# skip cells under a cliff's cast shade (the NW neighbor is
		# ELEVATED): the shade polygon darkens the face colors and the
		# road-material probe needs an unshaded sample
		if stage.tile_at(cell - Vector2i(1, 1)) == StageDef.Tile.ELEVATED:
			continue
		road_cells[cell] = true
	var road_cell := Vector2i(-1, -1)
	var old_pt := Vector2.ZERO
	for cell: Vector2i in road_cells:
		var pt := old_origin + (Vector2(cell) + Vector2.ONE * 0.5) * 64.0
		var covering: Vector2i = view.call("cell_at", pt)
		if not road_cells.has(covering):
			road_cell = cell
			old_pt = pt
			break
	h.check("derived a road cell with off-road old center", road_cell.x >= 0)
	if road_cell.x < 0:
		return

	# road material = the palette actually present in the road art's face
	# interior (P12.1 re-baseline: the road is a multi-color dirt texture,
	# not one stand-in color; the fallback lane still uses the stand-in)
	var road_set: Dictionary = {}
	var road_tex := Art.texture(&"tile_road")
	if road_tex != null:
		var road_img := road_tex.get_image()
		for ay: int in range(6, 10):
			for ax: int in range(12, 20):
				road_set[road_img.get_pixelv(Vector2i(ax, ay)).to_html(false)] = true
	else:
		road_set[IsoGridBuilder.ROAD_STANDIN_COLOR.to_html(false)] = true
	var count_road := func(im: Image, at: Vector2) -> int:
		var n := 0
		for dy: int in ROAD_PROBE.y:
			for dx: int in ROAD_PROBE.x:
				var px := im.get_pixel(int(at.x) - 8 + dx, int(at.y) - 4 + dy)
				if road_set.has(px.to_html(false)):
					n += 1
		return n
	var new_center: Vector2 = view.call("cell_center", road_cell)
	var img_flat := await h.shot_grab("iso_grid")
	h.check_pixels(
		"road material present at the iso face center", img_flat,
		func(im: Image) -> bool:
			return int(count_road.call(im, new_center)) > 80,
	)
	h.check_pixels(
		"road material ABSENT at the old square-grid center", img_flat,
		func(im: Image) -> bool:
			return int(count_road.call(im, old_pt)) < 10,
	)

	# --- deploy through the raw-input path on the iso projection ---
	var bar := view.find_child("DeployBar", true, false)
	var vg_slot := bar.find_child("Slot_vanguard_1", true, false) as Button
	h.check("vanguard slot present", vg_slot != null)
	if vg_slot == null:
		return
	await h.press_mouse_at(vg_slot.get_global_rect().get_center())
	await h.frames(3)
	# z-band probe: a valid-cell highlight must CHANGE pixels over its tile
	# (a highlight sunk below the grid leaves the tile untouched)
	var img_drag := await h.shot_grab("iso_placement_highlights")
	var probe_center: Vector2 = view.call("cell_center", TARGET_CELL)
	h.check_pixels(
		"deploy highlight renders above the tile", img_drag,
		func(im: Image) -> bool:
			if img_flat == null:
				return false
			var changed := 0
			for dy: int in ROAD_PROBE.y:
				for dx: int in ROAD_PROBE.x:
					var px := Vector2i(
						int(probe_center.x) - 8 + dx, int(probe_center.y) - 4 + dy
					)
					if im.get_pixelv(px) != img_flat.get_pixelv(px):
						changed += 1
			return changed > 40,
	)
	h.move_mouse_to_view(view.call("cell_center", TARGET_CELL))
	await h.frames(3)
	await h.release_mouse_at(view.call("cell_center", TARGET_CELL))
	await h.frames(3)
	var right_btn := bar.find_child("FacingRight", true, false) as Button
	h.check("facing chooser visible", right_btn != null and right_btn.visible)
	if right_btn != null:
		await h.click_view(right_btn.get_global_rect().get_center())
	await h.frames(3)
	var unit: UnitState = model.alive_unit_at(TARGET_CELL)
	h.check("iso-picked deploy landed on the model", unit != null)
	await h.shot("iso_deployed")
	h.done()
