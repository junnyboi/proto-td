class_name MissionCinematicRecord
extends Resource

const StreamMetadataType := preload("res://data/presentation/cinematics/mission_cinematic_stream_metadata.gd")

@export var stage_id: StringName = &""
@export var poster_path: String = ""
@export var video: StreamMetadataType
@export var ambience: StreamMetadataType


func is_valid() -> bool:
	return (
		not stage_id.is_empty()
		and poster_path == "res://assets/cinematics/missions/posters/%s.webp" % stage_id
		and video != null
		and ambience != null
		and video.path == "res://assets/cinematics/missions/video/%s.ogv" % stage_id
		and ambience.path == "res://assets/cinematics/missions/audio/%s.ogg" % stage_id
		and video.is_valid(true)
		and ambience.is_valid(true)
		and is_equal_approx(video.duration_seconds, ambience.duration_seconds)
	)
