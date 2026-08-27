class_name MissionCinematicStreamMetadata
extends Resource

## Typed immutable-by-convention media metadata. Phase 3 conversion fills bytes
## and SHA-256 without changing stage IDs or runtime paths.

@export var path: String = ""
@export_range(0, 2147483647, 1) var bytes: int = 0
@export var sha256: String = ""
@export_range(0.0, 8.0, 0.01) var duration_seconds: float = 0.0


func is_valid(allow_placeholders: bool = true) -> bool:
	if path.is_empty() or duration_seconds < 0.0 or duration_seconds > 8.0:
		return false
	if not allow_placeholders and (bytes <= 0 or sha256.length() != 64):
		return false
	return bytes >= 0 and (sha256.is_empty() or sha256.length() == 64)
