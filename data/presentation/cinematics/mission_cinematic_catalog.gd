class_name MissionCinematicCatalog
extends RefCounted

const RecordType := preload("res://data/presentation/cinematics/mission_cinematic_record.gd")
const StreamMetadataType := preload("res://data/presentation/cinematics/mission_cinematic_stream_metadata.gd")

## Runtime carrier metadata is pinned to the accepted Phase 3 conversion
## manifest. Stable stage IDs and paths remain independent of generator masters.
const MEDIA := {
	&"s1": {
		"duration": 8.0,
		"video_bytes": 13462958,
		"video_sha256": "fafaa9a27991d40ab418ea1d3ad23dd193decb5dc92bd889dc609697a81c3707",
		"audio_bytes": 145768,
		"audio_sha256": "d65869feb3990e01542665c8dfb70ebf140c9d93b964ce960aead01ad3ad4f9d",
	},
	&"s2": {
		"duration": 8.0,
		"video_bytes": 19290094,
		"video_sha256": "8bb0753ca7558082f294c2106af376dcc397f5a07bef1a91c9f7d8ffb754e8a7",
		"audio_bytes": 143484,
		"audio_sha256": "475459164d1c7cda363ffb6a5e674e8708f1491d14fda59ce1714d4eb06ec9e2",
	},
	&"s3": {
		"duration": 8.0,
		"video_bytes": 3886978,
		"video_sha256": "9e7b5819afc01d690e876f4814dd80fb8733b7c67f13e2acb8fb8825dcfde095",
		"audio_bytes": 105601,
		"audio_sha256": "0b3a86de0f595d4aff7ae3b01f0b7e616c78fb108306e4145b3f6655cbd67edf",
	},
	&"s4": {
		"duration": 8.0,
		"video_bytes": 3001351,
		"video_sha256": "1e7ed9386c0eefc79fe7f796dfca4aa7c4c42bf9f37c7033c6723583e5d37ef4",
		"audio_bytes": 110051,
		"audio_sha256": "1a265fa37ae6a8a4f0b5cc882342c08f5368e6efa9f81f2ffa82c9d1f7355c2e",
	},
	&"s5": {
		"duration": 8.0,
		"video_bytes": 3533909,
		"video_sha256": "257e9c9b7fb7d739b385711b04c772ed49398906bbabdb2d73cb2e1d09f21260",
		"audio_bytes": 106157,
		"audio_sha256": "72ef39bc8c72f049f47d32b572829ef004e6ce761416cccafb1e25c34cc68363",
	},
	&"s6": {
		"duration": 8.0,
		"video_bytes": 2273015,
		"video_sha256": "d362be143cb5642cc03d68b6f85655a1127c7302093ddcbc79c13a30ba066a24",
		"audio_bytes": 106955,
		"audio_sha256": "c4dd27d767acae10fbc5923280d37522250d59142df3fe8b6527c76a8cdd3caa",
	},
	&"s7": {
		"duration": 8.0,
		"video_bytes": 2388451,
		"video_sha256": "8958b6d5bc06615627d7936acfe53d032ac92779a7ec899399f7725ceb707036",
		"audio_bytes": 109691,
		"audio_sha256": "15e8614523c9b4c902ad52e057204c733361ca0509508a948f66bbe07b376430",
	},
	&"s8": {
		"duration": 8.0,
		"video_bytes": 2027192,
		"video_sha256": "8c53ca4103ae6dd990244a82a01966ff7bf884c24d699500897ff494feacb81c",
		"audio_bytes": 101293,
		"audio_sha256": "70e89d10f0050c3f7babba8e47e07e5abee137b711860dc5a5c1baa199f2392b",
	},
	&"s9": {
		"duration": 8.0,
		"video_bytes": 5243779,
		"video_sha256": "8037b1f2b7a86bdac19268916e6fdeb54cd94ab400221e60c6c8075545e474d8",
		"audio_bytes": 111896,
		"audio_sha256": "2a7fda2f267012ef9655ef9272326d7fe442655d1d735eff5157621d63c707d9",
	},
	&"s10": {
		"duration": 8.0,
		"video_bytes": 4566613,
		"video_sha256": "07e03296fcd81b3f3a69853b2123b43f087517baa8d7360db2cee33fca7f10ba",
		"audio_bytes": 108706,
		"audio_sha256": "500fbbb572568848c8f812e850bba8683302d2f51b296618ec09f0dd8e3f824c",
	},
	&"s11": {
		"duration": 8.0,
		"video_bytes": 5973658,
		"video_sha256": "b278c821f0749da45f8cc68b51e0a50b22b29cb613411775dfe13843ab16368f",
		"audio_bytes": 106421,
		"audio_sha256": "68ed594b60cd0c93b2083e2f46d2d66285c92a6b52ecbec8a71092e3048ea097",
	},
	&"s12": {
		"duration": 8.0,
		"video_bytes": 1617928,
		"video_sha256": "8344abc04edd804ea378ba1dc98a9c02eff82b8678728e55f7dea0eddb0a7095",
		"audio_bytes": 113974,
		"audio_sha256": "02e447004107ce6c4e1f8b9e58b7e631fc089be100039f014388822366ebe1c8",
	},
	&"s13": {
		"duration": 8.0,
		"video_bytes": 3021216,
		"video_sha256": "9a8c20fd995ea8fd2e616aacfef9dcb19872c23abe421fee98b40708353c2a8e",
		"audio_bytes": 110309,
		"audio_sha256": "8915bcd8de7a6c74be176f7b518883825cc9cb84e505ba8fc5cbe401b8a8bbe6",
	},
	&"s14": {
		"duration": 8.0,
		"video_bytes": 3049304,
		"video_sha256": "80ebfc13366b8d32a30eee0ee003c8ab562434f5e9b069f3b1adea4a632e73db",
		"audio_bytes": 107995,
		"audio_sha256": "06b1a7d5d2699bab5d9c69741d732572a27191ab275e9ff5b08e26b9806a41f4",
	},
	&"s15": {
		"duration": 8.0,
		"video_bytes": 2144721,
		"video_sha256": "a54f61526e865451ca3a66c705b0ac9684308eeba5501515ef642af9d3139e55",
		"audio_bytes": 109521,
		"audio_sha256": "fc7ccdecba02ba207e3c3054cbcb846e501ca44e671380b0821be15058b8ad66",
	},
	&"s16": {
		"duration": 8.0,
		"video_bytes": 2906782,
		"video_sha256": "f21bfb09a45dedd89afbd6de78c2bf8ac5c41aa99c5bcb74023ffb6e6fdb52e4",
		"audio_bytes": 113421,
		"audio_sha256": "2246c8f35c7139c5b1e97a3fa66ba5904b9a24bbdadb0b0e3194a6e28bb75665",
	},
}


static func stage_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for index: int in range(1, 17):
		ids.append(StringName("s%d" % index))
	return ids


static func all() -> Array[MissionCinematicRecord]:
	var records: Array[MissionCinematicRecord] = []
	for stage_id: StringName in stage_ids():
		records.append(_make_record(stage_id))
	return records


static func record_for(stage_id: StringName) -> MissionCinematicRecord:
	return _make_record(stage_id) if MEDIA.has(stage_id) else null


static func _make_record(stage_id: StringName) -> MissionCinematicRecord:
	var spec: Dictionary = MEDIA[stage_id]
	var duration := float(spec["duration"])
	var record := RecordType.new()
	record.stage_id = stage_id
	record.poster_path = "res://assets/cinematics/missions/posters/%s.webp" % stage_id
	record.video = _stream(
		"res://assets/cinematics/missions/video/%s.ogv" % stage_id,
		int(spec["video_bytes"]),
		String(spec["video_sha256"]),
		duration,
	)
	record.ambience = _stream(
		"res://assets/cinematics/missions/audio/%s.ogg" % stage_id,
		int(spec["audio_bytes"]),
		String(spec["audio_sha256"]),
		duration,
	)
	return record


static func _stream(path: String, bytes: int, sha256: String, duration_seconds: float) -> MissionCinematicStreamMetadata:
	var metadata := StreamMetadataType.new()
	metadata.path = path
	metadata.bytes = bytes
	metadata.sha256 = sha256
	metadata.duration_seconds = duration_seconds
	return metadata
