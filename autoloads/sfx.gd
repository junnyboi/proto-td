extends Node

## SFX seam, audio intentionally disabled. The placeholder synth beeps
## (Phase 9 gen_sfx.gd) were removed pending real sound assets; the wiring
## contract stays: play(id) emits the sfx_played Telemetry event
## UNCONDITIONALLY with the raw id (§1.4 C1: event counts equal call counts
## exactly — six scenarios gate on this). Re-enabling audio means adding
## playback behind this seam, never a parallel code path.


func play(id: String) -> void:
	Telemetry.event("sfx_played", {"id": id})
