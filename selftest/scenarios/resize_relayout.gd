extends RefCounted

## P14.1 scenario: viewport resize mid-battle relayouts EVERYTHING that
## derives from viewport or grid scale. Falsifiable pairs: the projection
## seam round-trips at every size (and actually MOVED between sizes); a
## shake decays back to the POST-resize origin (the stale-base teleport
## regression); the battle-controls strip stays inside the viewport; the
## placement cursor's diamond footprint re-derives from the live scale.
## Budget: ~tick 200 of activity = 400 render frames @60, x2 for 120 Hz =
## 800, + resize settle waits and drag ritual ~= 1100 -> 1400 pinned.

const CELLS := [Vector2i(0, 0), Vector2i(3, 2), Vector2i(2, 1)]


func run(h: SelfTestHarness) -> void:
	h.max_frames = 1400
	h.expect_done()
	await h.frames(10)
	var game := h.autoload("Game")
	game.call("start_battle", game.get("default_stage_id"))
	await h.frames(10)
	var model: BattleModel = game.get("current_battle")
	h.check("battle model exists", model != null)
	if model == null:
		return
	var view := game.get("content") as Node2D

	var centers_before: Array = []
	for cell: Vector2i in CELLS:
		centers_before.append(view.call("cell_center", cell))
		h.check(
			"round-trip at 1280x720 for %s" % cell,
			view.call("cell_at", view.call("cell_center", cell)) == cell,
		)

	# --- resize down: everything re-derives ---
	h.root.size = Vector2i(960, 640)
	await h.frames(4)
	var moved := 0
	for i: int in CELLS.size():
		var cell: Vector2i = CELLS[i]
		var center: Vector2 = view.call("cell_center", cell)
		if center != centers_before[i]:
			moved += 1
		h.check(
			"round-trip at 960x640 for %s" % cell,
			view.call("cell_at", center) == cell,
			"center %s" % center,
		)
	h.check("projection actually moved on resize", moved == CELLS.size())

	# --- shake decays to the POST-resize origin (stale-base regression) ---
	var grid := view.find_child("GridRoot", true, false) as Node2D
	var juice := view.find_child("JuiceLayer", true, false)
	var origin_after_resize := grid.position
	juice.call("shake", "leak", 6.0, 8)
	await h.frames(3)
	var shaken := grid.position != origin_after_resize
	await h.frames(12)
	h.check("shake displaced the grid", shaken)
	h.check(
		"shake restored the post-resize origin",
		grid.position == origin_after_resize,
		"pos %s vs %s" % [grid.position, origin_after_resize],
	)

	# --- battle controls strip stays inside the viewport ---
	var controls_box := view.find_child("ControlsBox", true, false) as HBoxContainer
	h.check("controls box present", controls_box != null)
	if controls_box != null:
		var right := controls_box.global_position.x + controls_box.get_combined_minimum_size().x
		h.check(
			"controls strip inside the resized viewport",
			right <= 960.0 and controls_box.global_position.x >= 0.0,
			"right edge %f" % right,
		)

	# --- placement cursor footprint re-derives from the live scale ---
	var bar := view.find_child("DeployBar", true, false)
	var slot := bar.find_child("Slot_vanguard_1", true, false) as Button
	h.check("vanguard slot present", slot != null)
	if slot == null:
		return
	await h.press_mouse_at(slot.get_global_rect().get_center())
	h.move_mouse_to_view(view.call("cell_center", Vector2i(3, 2)))
	await h.frames(3)
	var cursor := bar.find_child("CursorRect", true, false) as Polygon2D
	var scale_now: float = view.call("grid_scale")
	h.check("cursor present in placement", cursor != null and cursor.visible)
	if cursor != null:
		var width := cursor.polygon[1].x - cursor.polygon[3].x
		h.check(
			"cursor diamond width == 64 x live grid scale",
			absf(width - 64.0 * scale_now) < 0.01,
			"width %f scale %f" % [width, scale_now],
		)
	h.press("ui_cancel")
	await h.frames(2)
	h.release("ui_cancel")
	await h.frames(2)

	# --- resize back up: seam still exact ---
	h.root.size = Vector2i(1280, 720)
	await h.frames(4)
	for cell: Vector2i in CELLS:
		h.check(
			"round-trip restored at 1280x720 for %s" % cell,
			view.call("cell_at", view.call("cell_center", cell)) == cell,
		)
	h.done()
