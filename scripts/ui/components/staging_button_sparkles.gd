class_name StagingButtonSparkles
extends Control

const SPARKLE_TEXTURE := preload(
	"res://assets/ui/staging/effects/lunaris_astral_sparkle.png"
)
const PARTICLE_POSITIONS := [
	Vector2(0.07, 0.20),
	Vector2(0.17, 0.78),
	Vector2(0.34, 0.12),
	Vector2(0.64, 0.88),
	Vector2(0.76, 0.14),
	Vector2(0.91, 0.34),
	Vector2(0.86, 0.78),
	Vector2(0.48, 0.92),
]
const SIZE_FACTORS := [0.76, 0.54, 0.88, 0.64, 0.58, 0.82, 0.52, 0.70]
const TWINKLE_CYCLE_SECONDS := 3.4
const GOLD_TINT := Color("ffe9b0")
const CYAN_TINT := Color("c6f7ff")

var _elapsed := 0.0
var _phase_offset := 0.0
var _reduced_motion := false
var _particles: Array[TextureRect] = []


func configure(phase_offset: float) -> void:
	_phase_offset = phase_offset


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	_reduced_motion = bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))
	_build_particles()
	resized.connect(_update_particle_field)
	set_process(not _reduced_motion)
	_update_particle_field()


func _process(delta: float) -> void:
	_elapsed = fmod(_elapsed + delta, TWINKLE_CYCLE_SECONDS)
	_update_particle_field()


func particle_count() -> int:
	return _particles.size()


func motion_reduced() -> bool:
	return _reduced_motion


func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	set_process(not _reduced_motion)
	_update_particle_field()


func texture_ready() -> bool:
	return SPARKLE_TEXTURE != null and not SPARKLE_TEXTURE.resource_path.is_empty()


func visible_particle_count() -> int:
	var count := 0
	for particle: TextureRect in _particles:
		if particle.modulate.a > 0.05:
			count += 1
	return count


func _build_particles() -> void:
	for index: int in PARTICLE_POSITIONS.size():
		var particle := TextureRect.new()
		particle.name = "Sparkle%02d" % (index + 1)
		particle.texture = SPARKLE_TEXTURE
		particle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		particle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.show_behind_parent = false
		add_child(particle)
		_particles.append(particle)


func _update_particle_field() -> void:
	if _particles.is_empty() or size.x <= 4.0 or size.y <= 4.0:
		return
	var base_size := clampf(size.y * 0.30, 24.0, 54.0)
	for index: int in _particles.size():
		var particle := _particles[index]
		var extent := base_size * float(SIZE_FACTORS[index])
		particle.size = Vector2(extent, extent)
		particle.pivot_offset = particle.size * 0.5
		var anchor: Vector2 = PARTICLE_POSITIONS[index]
		var drift := Vector2.ZERO
		var alpha := 0.0
		var particle_scale := 0.70
		var rotation_offset := 0.0
		if _reduced_motion:
			if index in [0, 3, 5]:
				alpha = 0.28 if index != 3 else 0.20
				particle_scale = 0.82
		else:
			var local_phase := fmod(
				_elapsed / TWINKLE_CYCLE_SECONDS + _phase_offset + float(index) * 0.173,
				1.0,
			)
			var twinkle := pow(maxf(0.0, sin(local_phase * TAU)), 4.0)
			alpha = twinkle * (0.68 if index % 3 == 0 else 0.48)
			particle_scale = lerpf(0.62, 1.0, twinkle)
			drift = Vector2(
				sin(_elapsed * 0.54 + float(index) * 1.7) * 1.8,
				cos(_elapsed * 0.42 + float(index) * 1.1) * 3.0,
			)
			rotation_offset = sin(_elapsed * 0.31 + float(index)) * 0.08
		var center := Vector2(anchor.x * size.x, anchor.y * size.y) + drift
		center.x = clampf(center.x, extent * 0.5, size.x - extent * 0.5)
		center.y = clampf(center.y, extent * 0.5, size.y - extent * 0.5)
		particle.position = center - particle.size * 0.5
		particle.scale = Vector2.ONE * particle_scale
		particle.rotation = rotation_offset
		var tint := GOLD_TINT if index % 2 == 0 else CYAN_TINT
		particle.modulate = Color(tint, alpha)
