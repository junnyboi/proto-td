class_name SfxCatalog
extends Resource

## Logical SFX id -> accepted cue metadata. Raw presentation ids may resolve
## through aliases, while Telemetry always keeps the original raw id.

@export var entries: Dictionary = {}
@export var aliases: Dictionary = {}
