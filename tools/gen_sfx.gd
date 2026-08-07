extends SceneTree

## Placeholder SFX synthesizer (Phase 9, td-phase-9.md §3.2 — parent §6.7's
## audio pass scoped to the juice rows). Run:
##   ~/bin/godot --headless --path . -s tools/gen_sfx.gd
## Deterministic and idempotent: noise comes from a fixed-seed RNG per sound
## (the model's no-RNG rule doesn't bind tools), so two runs are
## byte-identical — verified by shasum in the session log. Output WAVs are
## committed; Lane A later folds this into gen_assets.gd + the manifest.

enum Wave { SINE, SQUARE, NOISE }

const RATE := 22050
const OUT_DIR := "res://assets/sfx"
const TAU_F := TAU

var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_write("deploy", _gen_deploy())
	_write("sting", _gen_sting())
	_write("kill", _gen_kill())
	_write("leak", _gen_leak())
	_write("wave", _gen_wave())
	_write("victory", _gen_victory())
	_write("defeat", _gen_defeat())
	_write("trap_snap", _gen_trap_snap())
	_write("bolt_zap", _gen_bolt_zap())
	_write("charm_chime", _gen_charm_chime())
	_write("ui_click", _gen_ui_click())
	print("[GEN-SFX] done")
	quit(0)


## deploy thump: low sine body + a short noise burst on the attack
func _gen_deploy() -> PackedFloat32Array:
	var buf := _buffer(0.2)
	_tone(buf, 0.0, 0.2, 90.0, 60.0, Wave.SINE, 0.8)
	_tone(buf, 0.0, 0.04, 0.0, 0.0, Wave.NOISE, 0.4)
	return buf


## skill sting: rising square arp
func _gen_sting() -> PackedFloat32Array:
	var buf := _buffer(0.2)
	_tone(buf, 0.0, 0.06, 440.0, 440.0, Wave.SQUARE, 0.25)
	_tone(buf, 0.06, 0.06, 660.0, 660.0, Wave.SQUARE, 0.25)
	_tone(buf, 0.12, 0.08, 880.0, 880.0, Wave.SQUARE, 0.25)
	return buf


## kill tick: short noise blip
func _gen_kill() -> PackedFloat32Array:
	var buf := _buffer(0.06)
	_tone(buf, 0.0, 0.06, 0.0, 0.0, Wave.NOISE, 0.5)
	return buf


## leak alarm: bass drop + two low pulses
func _gen_leak() -> PackedFloat32Array:
	var buf := _buffer(0.4)
	_tone(buf, 0.0, 0.2, 220.0, 70.0, Wave.SINE, 0.8)
	_tone(buf, 0.22, 0.06, 120.0, 120.0, Wave.SQUARE, 0.4)
	_tone(buf, 0.32, 0.06, 120.0, 120.0, Wave.SQUARE, 0.4)
	return buf


## wave horn: two-tone
func _gen_wave() -> PackedFloat32Array:
	var buf := _buffer(0.35)
	_tone(buf, 0.0, 0.15, 196.0, 196.0, Wave.SQUARE, 0.3)
	_tone(buf, 0.15, 0.2, 247.0, 247.0, Wave.SQUARE, 0.3)
	return buf


## victory fanfare: 3 rising notes
func _gen_victory() -> PackedFloat32Array:
	var buf := _buffer(0.45)
	_tone(buf, 0.0, 0.12, 523.0, 523.0, Wave.SQUARE, 0.3)
	_tone(buf, 0.12, 0.12, 659.0, 659.0, Wave.SQUARE, 0.3)
	_tone(buf, 0.24, 0.2, 784.0, 784.0, Wave.SQUARE, 0.3)
	return buf


## defeat: 3 descending notes
func _gen_defeat() -> PackedFloat32Array:
	var buf := _buffer(0.55)
	_tone(buf, 0.0, 0.15, 392.0, 392.0, Wave.SQUARE, 0.3)
	_tone(buf, 0.15, 0.15, 330.0, 330.0, Wave.SQUARE, 0.3)
	_tone(buf, 0.3, 0.25, 262.0, 262.0, Wave.SQUARE, 0.3)
	return buf


## trap snap: sharp noise transient
func _gen_trap_snap() -> PackedFloat32Array:
	var buf := _buffer(0.05)
	_tone(buf, 0.0, 0.05, 0.0, 0.0, Wave.NOISE, 0.7)
	return buf


## bolt zap: falling square sweep
func _gen_bolt_zap() -> PackedFloat32Array:
	var buf := _buffer(0.15)
	_tone(buf, 0.0, 0.15, 880.0, 220.0, Wave.SQUARE, 0.35)
	return buf


## charm chime: major-3rd bell pair
func _gen_charm_chime() -> PackedFloat32Array:
	var buf := _buffer(0.4)
	_tone(buf, 0.0, 0.4, 523.0, 523.0, Wave.SINE, 0.4)
	_tone(buf, 0.0, 0.4, 659.0, 659.0, Wave.SINE, 0.3)
	return buf


## ui click: tiny high blip
func _gen_ui_click() -> PackedFloat32Array:
	var buf := _buffer(0.02)
	_tone(buf, 0.0, 0.02, 1000.0, 1000.0, Wave.SQUARE, 0.3)
	return buf


func _buffer(duration_s: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(int(duration_s * RATE))
	return buf


## Accumulate a linearly-swept tone with a linear decay envelope + 5ms attack.
func _tone(
	buf: PackedFloat32Array,
	start_s: float,
	dur_s: float,
	freq_from: float,
	freq_to: float,
	kind: Wave,
	gain: float,
) -> void:
	_rng.seed = hash("%f-%f-%f" % [start_s, freq_from, gain])
	var start := int(start_s * RATE)
	var n := int(dur_s * RATE)
	var attack := int(0.005 * RATE)
	var phase := 0.0
	for i: int in n:
		var idx := start + i
		if idx >= buf.size():
			break
		var t := float(i) / float(n)
		var freq := lerpf(freq_from, freq_to, t)
		phase += freq / RATE
		var sample := 0.0
		match kind:
			Wave.SINE:
				sample = sin(phase * TAU_F)
			Wave.SQUARE:
				sample = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			Wave.NOISE:
				sample = _rng.randf_range(-1.0, 1.0)
		var env := 1.0 - t
		if i < attack:
			env *= float(i) / float(attack)
		buf[idx] = clampf(buf[idx] + sample * env * gain, -1.0, 1.0)


func _write(sfx_name: String, buf: PackedFloat32Array) -> void:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i: int in buf.size():
		var v := int(clampf(buf[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	var path := "%s/%s.wav" % [OUT_DIR, sfx_name]
	var err := wav.save_to_wav(path)
	print("[GEN-SFX] %s -> %s" % [sfx_name, "ok" if err == OK else ("err %d" % err)])
