class_name SelfTestInputShield
extends Node

## Eats REAL (untagged) mouse AND keyboard events for the lifetime of a
## harness run. A human on the machine races injected input (CLAUDE.md
## environment race), two ways: (a) a real zero-button-mask mouse motion
## arriving while a synthetic press is held makes the Viewport drop its GUI
## mouse focus, so the synthetic release never fires the button
## (deploy_flow Phase 3, battle_controls Phase 13); (b) the game window
## takes keyboard focus when the windowed lane opens it, so a human typing
## lands real keystrokes in the game — fatal once gameplay hotkeys exist
## (Phase 13's Space pause toggled mid-measurement). Synthetic events carry
## device == SelfTestHarness.SYNTHETIC_DEVICE and pass through untouched.
## Node._input runs before Control GUI routing and _unhandled_input, so
## marking the event handled here shields every button, drag, and hotkey in
## every scenario. Window-manager effects (hiding/occluding the window
## stops draws and stalls shot_grab) cannot be shielded — that stays a
## re-run-when-idle case.


func _input(event: InputEvent) -> void:
	if event.device == SelfTestHarness.SYNTHETIC_DEVICE:
		return
	if event is InputEventMouse or event is InputEventKey:
		get_viewport().set_input_as_handled()
