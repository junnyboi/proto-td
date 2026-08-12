class_name MusicCatalog
extends Resource

## Logical music id -> generated cue metadata. Runtime playback resolves cues
## through this catalog rather than hardcoding file paths. Each entry carries:
## act, role, title, path, BPM/meter/key, loop treatment, measured duration,
## generation/provenance hashes, and the human-owned placeholder flag.

@export var entries: Dictionary = {}
