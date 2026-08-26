# Premium Resonance Reveal Audio

## Scope

All three current Premium Resonance heroes—**Lunaris Vessel**, **Reliquary Duelist**, and **Archive Caster**—share one presentation contract. When a hero cinematic ends, the final plate appears, the character name and astral stars use the universal gold treatment, a ceremonial identity sting plays, and the hero-specific cinematic cue crossfades over **0.75 seconds** into `lunaris_staging_archive_command`. Each star then plays one moon-glass bloom cue when its spin decelerates into the pulse loop. Early Skip uses a shorter **0.35-second** staging crossfade.

Reduced-motion presentation immediately exposes the identity plate, plays the identity sting and one consolidated star-bloom cue, and keeps the staging score active.

## Mirelo-style production chain

The two cues follow the required **sound brief → GPT Image 2 anchor → audio-enabled video carrier → extracted runtime WAV** workflow. Production sources are stored outside the source repository under the Manus project folder `gacha-audio-polish/`; only optimized runtime WAV files and Godot import metadata ship in the repository.

| Cue ID | Runtime path | Duration | Format | Purpose |
|---|---|---:|---|---|
| `gacha_identity_reveal` | `res://assets/sfx/gacha/gacha_identity_reveal.wav` | 3.000 s | 48 kHz, stereo, PCM 16-bit | Name/final-plate reveal and BGM handoff |
| `gacha_star_bloom` | `res://assets/sfx/gacha/gacha_star_bloom.wav` | 1.158 s | 48 kHz, stereo, PCM 16-bit | Per-star deceleration, stop, and pulse entry |

## Runtime checksums

| Asset | SHA-256 |
|---|---|
| `gacha_identity_reveal.wav` | `d310e775aae8cd9d167b7a6b885182c05b610658e14f1c31cc905f567cb4848f` |
| `gacha_star_bloom.wav` | `a6309e5adf88e33e80b16e4d992f7c190df5ab3b76c5b5fd6a49c5682c2f19ab` |

## Runtime ownership

`Sfx` remains the sole SFX owner and resolves both cue IDs through `assets/sfx/catalog.tres`. `Music` remains the sole BGM owner and exposes `transition_to_cue()` plus `transition_to_staging()` for explicit crossfades. `scripts/ui/gacha.gd` triggers identity audio exactly once per completed reveal, one star bloom per sequentially settled star, and restores staging BGM without entering deterministic campaign state.

The focused contracts live in `tests/premium_gacha_ui_test.gd`, `tests/ui_audio_direction_test.gd`, and `tests/music_redesign_test.gd`.
