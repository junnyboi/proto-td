# Tower Placement Feedback

Tower deployment now has two presentation-only feedback profiles selected from the authoritative stage tile at the placed unit’s cell. The simulation and deployment rules are unchanged.

| Placement surface | SFX event | Game-ready asset | Particle emitter |
|---|---|---|---|
| Normal ground | `deploy_ground` | `assets/sfx/combat/deploy_ground.wav` | Eight warm amber dust/grit particles expanding radially along the tile face |
| Elevated platform | `deploy_elevated` | `assets/sfx/combat/deploy_elevated.wav` | Eight rising cyan-white shards, one expanding isometric energy ring, and one contracting vertical beam |

The legacy logical event `deploy` remains an alias of `deploy_ground`, but the superseded generic WAV was removed. New BattleView placements choose the terrain-specific event and emitter before applying the existing unit crouch animation.

## Generated audio provenance

Both effects originated as audio embedded in dedicated three-second, 16:9 carrier videos generated with the built-in video model. The ground carrier requested one dry stone-and-earth landing thunk, granular dust, and a restrained amber lock-in chime. The elevated carrier requested one resonant stone-and-metal clack, an upward airy pulse, and a crystalline confirmation shimmer. Neither carrier requested dialogue, ambience, or background music.

The embedded tracks were extracted as 48 kHz stereo PCM, trimmed around their placement envelopes, tightened, filtered, faded, and normalized with a `-1.5 dBFS` true-peak ceiling. The shipped ground cue is approximately `0.861 s` at `-15.5 LUFS`; the elevated cue is approximately `1.209 s` at `-15.8 LUFS`, retaining a deliberately longer crystalline tail.

## Validation

Run the focused contract test with:

```bash
tools/run_godot_test.sh test/placement_feedback_smoke.gd
```

The test validates catalog resolution, legacy aliasing, audio loading and duration, BattleView routing, ground particle count, and the elevated shards/ring/beam composition. The deterministic visual scene `res://test/placement_feedback_visual_harness.tscn` accepts `PLACEMENT_PROFILE=ground` or `PLACEMENT_PROFILE=elevated` for production-renderer captures.
