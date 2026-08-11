extends RefCounted

## Phase 13b scenario (td-phase-13.md §4): the in-battle QoL controls drive
## only the ticks_per_frame_scale seam + the resign verb. The battle is
## pinned open with one never-reached wave entry (Q16, the CLAUDE.md
## pure-economy pin) so the whole run is a quiet window: no spawns, no
## kills, no hit-stop, no leak race — pause/speed exactness cannot be
## contaminated.
## Paper derivation (td-phase-13.md §4, corrected as-built): physics 60 Hz,
## tps 30 => scale s adds 0.5s ticks per stepped frame. Between two reads
## separated by `await physics_frames(40)` the view executes 39-40 physics
## frames (await-boundary alignment costs up to one frame), and the
## accumulator carries a < 1.0 residue — so dtick lands in
## [floor(19.5s), 20s]: 1x -> [19, 21] (residue can round up), 4x -> [78, 80]
## (integer 2/frame, residue inert). Paused is exact: the accumulator gains
## 0, so dtick == 0 over any window.
## Falsifiable shot checklist:
##   controls_idle     — pause/speed/resign row right-aligned under the spell
##                       bar, clear of the HUD status line and the spell
##                       buttons (as-built D5: top-center belongs to the HUD)
##   paused            — ">" on the pause button + amber PAUSED indicator
##   speed_4x          — speed button reads 4x
##   resign_confirm    — centered panel: "Resign this battle?", two buttons
##   terminal_continue — DEFEAT stamp + Continue visibly the largest button
## Watchdog: 150 measurement physics frames + ~40 click/settle frames +
## 2 x <=120-frame swap polls + shots ~= 500 worst case -> 1200 keeps 2x.

const PAUSED_COLOR := Color("f4b41b")
const LABEL_TEXT_COLOR := Color(0.875, 0.875, 0.875)


func run(h: SelfTestHarness) -> void:
	h.max_frames = 1200
	await h.frames(10)
	var game := h.autoload("Game")
	h.expect_done()

	# quick battle pinned open (seam start; StartButton raw input is already
	# validated by resign_flow — the new raw surfaces here are the controls)
	game.call("start_battle", game.get("default_stage_id"))
	var stage := (game.get("pending_stage") as StageDef).duplicate(true) as StageDef
	var waves: Array[Dictionary] = [{"tick": 100_000, "enemy_id": &"grunt", "path_idx": 0}]
	stage.waves = waves
	game.set("pending_stage", stage)
	var model := await _await_battle(h, game)
	h.check("battle started", model != null)
	if model == null:
		return
	var view := game.get("content") as Node2D

	# the controls row exists and sits top-center
	var controls := view.find_child("BattleControls", true, false) as Control
	h.check("controls attached to the battle", controls != null)
	if controls == null:
		return
	var box := controls.find_child("ControlsBox", true, false) as Control
	var pause_btn := controls.find_child("PauseButton", true, false) as Button
	var speed_btn := controls.find_child("SpeedButton", true, false) as Button
	var resign_btn := controls.find_child("ResignButton", true, false) as Button
	h.check(
		"row is populated",
		box != null and pause_btn != null and speed_btn != null and resign_btn != null,
	)
	await h.shot("controls_idle")

	# pause: exact freeze (accumulator gains 0 -> dtick == 0 over any window)
	await h.click_view(pause_btn.get_global_rect().get_center())
	h.check("pause readback is 0", float(view.get("ticks_per_frame_scale")) == 0.0)
	var paused_label := controls.find_child("PausedLabel", true, false) as Label
	h.check("PAUSED indicator on", paused_label != null and paused_label.text == "PAUSED")
	var frozen_tick: int = model.tick
	await h.physics_frames(30)
	h.check(
		"paused dtick == 0 exactly", model.tick == frozen_tick,
		"tick %d -> %d" % [frozen_tick, model.tick],
	)
	var img_paused := await h.shot_grab("paused")
	if paused_label != null:
		var label_rect := Rect2i(paused_label.get_global_rect())
		h.check_pixels(
			"PAUSED text pixels present", img_paused,
			func(im: Image) -> bool:
				return SelfTestProbes.color_in_rect(im, label_rect, PAUSED_COLOR, 0.1) > 50,
		)

	# resume: 40 frames at 1x -> 20 +/- 1 ticks
	await h.click_view(pause_btn.get_global_rect().get_center())
	h.check("resume readback is 1x", float(view.get("ticks_per_frame_scale")) == 1.0)
	var t0: int = model.tick
	await h.physics_frames(40)
	var d1: int = model.tick - t0
	h.check("1x dtick in [19, 21]", d1 >= 19 and d1 <= 21, "dtick=%d" % d1)

	# speed cycle: 1x -> 2x -> 4x (measured) -> wraps to 1x
	await h.click_view(speed_btn.get_global_rect().get_center())
	h.check("cycle to 2x", float(view.get("ticks_per_frame_scale")) == 2.0)
	await h.click_view(speed_btn.get_global_rect().get_center())
	h.check("cycle to 4x", float(view.get("ticks_per_frame_scale")) == 4.0)
	t0 = model.tick
	await h.physics_frames(40)
	var d4: int = model.tick - t0
	h.check("4x dtick in [78, 80]", d4 >= 78 and d4 <= 80, "dtick=%d" % d4)
	await h.frames(2)
	h.check("speed button reads 4x", speed_btn.text == "4x")
	await h.shot("speed_4x")
	await h.click_view(speed_btn.get_global_rect().get_center())
	h.check("cycle wraps to 1x", float(view.get("ticks_per_frame_scale")) == 1.0)

	# Space toggles pause (physical keycode, the debug.gd F12 precedent)
	_send_space()
	await h.frames(2)
	h.check("Space pauses", float(view.get("ticks_per_frame_scale")) == 0.0)
	_send_space()
	await h.frames(2)
	h.check("Space resumes to 1x", float(view.get("ticks_per_frame_scale")) == 1.0)

	# resign confirm: forces pause, Cancel restores and never resigns
	await h.click_view(resign_btn.get_global_rect().get_center())
	var confirm := controls.find_child("ResignConfirm", true, false) as PanelContainer
	h.check("confirm panel visible", confirm != null and confirm.visible)
	h.check("confirm forces pause", float(view.get("ticks_per_frame_scale")) == 0.0)
	h.check("still RUNNING under the panel", model.result == BattleModel.Result.RUNNING)
	var question := controls.find_child("ResignQuestion", true, false) as Label
	var img_confirm := await h.shot_grab("resign_confirm")
	if question != null:
		var q_rect := Rect2i(question.get_global_rect())
		h.check_pixels(
			"confirm question pixels present", img_confirm,
			func(im: Image) -> bool:
				return SelfTestProbes.color_in_rect(im, q_rect, LABEL_TEXT_COLOR, 0.12) > 100,
		)
	# freshly-shown panel: settle before reading button rects (unsettled
	# Control rects for 2-3 frames are a batch-only click-miss flake)
	await h.frames(3)
	var cancel_btn := controls.find_child("CancelResign", true, false) as Button
	await h.click_view(cancel_btn.get_global_rect().get_center())
	h.check("cancel hides the panel", not confirm.visible)
	h.check("cancel restores the scale", float(view.get("ticks_per_frame_scale")) == 1.0)
	h.check("cancel never resigns", model.result == BattleModel.Result.RUNNING)

	# resign for real: DEFEAT + the prominent focused Continue button
	await h.click_view(resign_btn.get_global_rect().get_center())
	await h.frames(3)
	var confirm_btn := controls.find_child("ConfirmResign", true, false) as Button
	await h.click_view(confirm_btn.get_global_rect().get_center())
	h.check("resign lands DEFEAT", model.result == BattleModel.Result.DEFEAT)
	await h.frames(4)
	var stamp_label := view.find_child("ResultStampLabel", true, false) as Label
	h.check("stamp shows DEFEAT", stamp_label != null and stamp_label.text == "DEFEAT")
	var continue_btn := view.find_child("ContinueButton", true, false) as Button
	h.check("Continue button exists", continue_btn != null)
	if continue_btn == null:
		return
	var btn_size := continue_btn.get_global_rect().size
	h.check(
		"Continue is prominent (>= 260x64)", btn_size.x >= 260.0 and btn_size.y >= 64.0,
		"size=%s" % btn_size,
	)
	h.check("Continue holds focus (Enter proceeds)", continue_btn.has_focus())
	await h.shot("terminal_continue")

	# -> results (the 13a flow, reached through the 13b button)
	await h.click_view(continue_btn.get_global_rect().get_center())
	var results := await _await_screen(h, game, "ResultsColumn")
	h.check("results reached", results != null)
	h.done()


func _send_space() -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.device = SelfTestHarness.SYNTHETIC_DEVICE
		ev.keycode = KEY_SPACE
		ev.physical_keycode = KEY_SPACE
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()


## Awaits the deferred battle swap and returns the live model (null on
## timeout).
func _await_battle(h: SelfTestHarness, game: Node) -> BattleModel:
	var budget := 120
	while budget > 0:
		var model: BattleModel = game.get("current_battle")
		var content := game.get("content") as Node
		if model != null and content != null and content is Node2D:
			await h.frames(3)
			return model
		budget -= 1
		await h.frames(1)
	return null


## Awaits the deferred content swap and returns the new screen (null on
## timeout).
func _await_screen(h: SelfTestHarness, game: Node, marker: String) -> Control:
	var budget := 120
	while budget > 0:
		var content := game.get("content") as Node
		if content != null and is_instance_valid(content) \
				and content is Control and content.find_child(marker, true, false) != null:
			await h.frames(3)
			return content
		budget -= 1
		await h.frames(1)
	return null
