class_name JuiceConfig
extends Resource

## Every juice timing/magnitude (rule 4: juice tuning is data edits, same as
## balance — td-phase-9.md §2.1). Durations are integer RENDER frames,
## matching the view's transient convention; known limitation: visual
## duration halves at 120 Hz vs 60 Hz (logged in JUICE_VERDICT.md; switching
## to seconds is a schema-level data edit reserved for human-round verdicts).
## The view is the only consumer — the model never sees this resource
## (rule 6: juice can never change outcomes).

@export var deploy_drag_time_scale: float = 0.3
@export var deploy_crouch_frames: int = 6
@export var deploy_dust_frames: int = 10

@export var skill_flash_frames: int = 24
@export var skill_burst_frames: int = 8
@export var damage_flash_frames: int = 6
@export var damage_flash_white: Color = Color("ffffff")
@export var damage_flash_red: Color = Color("ff3b30")
@export var heal_burst_frames: int = 16
@export var heal_burst_particles: int = 8
@export var heal_burst_size_px: float = 8.0
@export var heal_burst_speed_px: float = 4.0
@export var heal_burst_color: Color = Color("88ffcc")

@export var kill_spark_frames: int = 4
@export var kill_spark_cap: int = 12

@export var leak_vignette_frames: int = 12
@export var leak_shake_amplitude_px: float = 6.0
@export var leak_shake_frames: int = 8
@export var leak_hit_stop_frames: int = 0

@export var wave_banner_frames: int = 45
@export var star_burst_stagger_frames: int = 10

@export var trap_sprung_frames: int = 8
@export var tar_shimmer_period_frames: int = 16

@export var charm_swirl_frames: int = 16
@export var charm_beat_time_scale: float = 0.5
@export var charm_beat_frames: int = 12
@export var charm_shake_amplitude_px: float = 0.0
@export var charm_shake_frames: int = 0
@export var charm_hit_stop_frames: int = 0

@export var tracer_frames: int = 4

# shake/hit-stop whitelist (parent plan: reserved for boss hits, leaks and
# the charm beat ONLY); boss_hit stays unwired until a boss-attack model
# record exists (Phase 10)
@export var shake_events: PackedStringArray = ["leak", "charm_beat", "boss_hit"]
