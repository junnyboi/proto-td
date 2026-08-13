class_name S1SliceFixtureManifest
extends Resource

## Presentation-only fixture selector for the Poseidon-approved AUI-20 S1
## slice. Fail closed: every mismatch leaves incumbent Art/EnemyAnimator in
## charge, and this resource never writes BattleModel state.

const CELL_SIZE := Vector2i(192, 192)
const ATLAS_SIZE := Vector2i(768, 384)
const GRID_SIZE := Vector2i(4, 2)
const FOOT_ROW := 180
const RUNTIME_CANVAS_PX := 144.0
const DISPLAY_PX := 72.0
const REST_FPS := 5.5
const ATTACK_FPS := 8.0
const FRAME_COUNT := 4
const RESERVED_COLORS: Array[String] = ["#F4F4F4", "#41A6F6"]
const STATES: Array[StringName] = [&"rest_movement", &"attack_skill"]
const KINDS: Array[StringName] = [&"operator", &"enemy"]

@export var schema_version: int = 1
@export var manifest_id: StringName = &""
@export var stage_id: StringName = &""
@export var fixture_contract_sha256: String = ""
@export var approval_record_id: String = ""
@export var entries: Dictionary = {}


func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != 1:
		errors.append("schema_version: expected 1")
	if manifest_id == &"":
		errors.append("manifest_id: required")
	if stage_id != &"s1":
		errors.append("stage_id: expected s1")
	if not _sha_valid(fixture_contract_sha256):
		errors.append("fixture_contract_sha256: expected lowercase SHA-256")
	if approval_record_id.is_empty():
		errors.append("approval_record_id: required")
	for kind: StringName in KINDS:
		if not entries.has(kind):
			errors.append("entries: missing %s" % kind)
	for raw_kind: Variant in entries:
		if typeof(raw_kind) != TYPE_STRING_NAME or not KINDS.has(raw_kind):
			errors.append("entries: unexpected key %s" % raw_kind)
			continue
		_validate_entry(raw_kind, entries[raw_kind], errors)
	return errors


func selects_operator(stage: StageDef, op_id: StringName) -> bool:
	return stage != null and stage.id == stage_id and _entry_ready(&"operator", op_id)


func selects_enemy(stage: StageDef, enemy: EnemyState) -> bool:
	return (
		stage != null
		and stage.id == stage_id
		and enemy != null
		and enemy.def_id == &"grunt"
		and enemy.faction == EnemyState.Faction.ENEMY
		and not enemy.aerial
		and _entry_ready(&"enemy", enemy.def_id)
	)


func atlas_texture(kind: StringName) -> Texture2D:
	var entry := _entry(kind)
	if entry.is_empty():
		return null
	var path := String(entry[&"path"])
	if not ResourceLoader.exists(path):
		return null
	var texture := load(path) as Texture2D
	if (
		texture == null
		or texture.get_width() != ATLAS_SIZE.x
		or texture.get_height() != ATLAS_SIZE.y
	):
		return null
	return texture


func frame_texture(kind: StringName, state: StringName, frame: int) -> Texture2D:
	if not STATES.has(state) or frame < 0 or frame >= FRAME_COUNT:
		return null
	var source := atlas_texture(kind)
	if source == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	var row := 1 if state == &"attack_skill" else 0
	atlas.region = Rect2i(frame * CELL_SIZE.x, row * CELL_SIZE.y, CELL_SIZE.x, CELL_SIZE.y)
	atlas.filter_clip = true
	return atlas


func frame_index(state: StringName, seconds: float, phase_offset: int = 0) -> int:
	if not STATES.has(state):
		return 0
	var fps := ATTACK_FPS if state == &"attack_skill" else REST_FPS
	return posmod(floori(maxf(seconds, 0.0) * fps) + phase_offset, FRAME_COUNT)


func entry_path(kind: StringName) -> String:
	return String(_entry(kind).get(&"path", ""))


func entry_sha256(kind: StringName) -> String:
	return String(_entry(kind).get(&"sha256", ""))


func entry_id(kind: StringName) -> StringName:
	return StringName(_entry(kind).get(&"subject_id", &""))


func _entry_ready(kind: StringName, subject_id: StringName) -> bool:
	var entry := _entry(kind)
	return (
		not entry.is_empty()
		and StringName(entry.get(&"subject_id", &"")) == subject_id
		and _entry_errors(kind, entry).is_empty()
		and atlas_texture(kind) != null
	)


func _entry(kind: StringName) -> Dictionary:
	var raw: Variant = entries.get(kind)
	return raw if raw is Dictionary else {}


func _validate_entry(kind: StringName, raw: Variant, errors: PackedStringArray) -> void:
	if not raw is Dictionary:
		errors.append("entries.%s: expected Dictionary" % kind)
		return
	for error: String in _entry_errors(kind, raw):
		errors.append(error)


func _entry_errors(kind: StringName, entry: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var prefix := "entries.%s" % kind
	var expected_keys: Array[StringName] = [
		&"subject_id",
		&"path",
		&"sha256",
		&"atlas_size",
		&"cell_size",
		&"grid_size",
		&"foot_row",
		&"display_px",
		&"reserved_colors",
	]
	if entry.size() != expected_keys.size():
		errors.append("%s: expected exact nine fields" % prefix)
	for key: StringName in expected_keys:
		if not entry.has(key):
			errors.append("%s: missing %s" % [prefix, key])
	for raw_key: Variant in entry:
		if typeof(raw_key) != TYPE_STRING_NAME or not expected_keys.has(raw_key):
			errors.append("%s: unexpected key %s" % [prefix, raw_key])
	var expected_id := &"vanguard_1" if kind == &"operator" else &"grunt"
	if (
		typeof(entry.get(&"subject_id")) != TYPE_STRING_NAME
		or entry.get(&"subject_id") != expected_id
	):
		errors.append("%s.subject_id: expected %s" % [prefix, expected_id])
	var path_value: Variant = entry.get(&"path")
	if (
		typeof(path_value) != TYPE_STRING
		or not String(path_value).begins_with("res://assets/sprites/")
	):
		errors.append("%s.path: expected sprite res path" % prefix)
	elif not ResourceLoader.exists(String(path_value)):
		errors.append("%s.path: missing resource" % prefix)
	if not _sha_valid(String(entry.get(&"sha256", ""))):
		errors.append("%s.sha256: expected lowercase SHA-256" % prefix)
	if entry.get(&"atlas_size") != ATLAS_SIZE:
		errors.append("%s.atlas_size: expected 768x384" % prefix)
	if entry.get(&"cell_size") != CELL_SIZE:
		errors.append("%s.cell_size: expected 192x192" % prefix)
	if entry.get(&"grid_size") != GRID_SIZE:
		errors.append("%s.grid_size: expected 4x2" % prefix)
	if entry.get(&"foot_row") != FOOT_ROW:
		errors.append("%s.foot_row: expected 180" % prefix)
	if not is_equal_approx(float(entry.get(&"display_px", 0.0)), DISPLAY_PX):
		errors.append("%s.display_px: expected 72" % prefix)
	if Array(entry.get(&"reserved_colors", [])) != RESERVED_COLORS:
		errors.append("%s.reserved_colors: mismatch" % prefix)
	return errors


func _sha_valid(value: String) -> bool:
	if value.length() != 64:
		return false
	for character: String in value:
		if not "0123456789abcdef".contains(character):
			return false
	return true


static func load_valid(
	path := "res://data/presentation/s1_slice_fixture_manifest.tres"
) -> S1SliceFixtureManifest:
	var manifest := load(path) as S1SliceFixtureManifest
	if manifest == null or not manifest.validate_contract().is_empty():
		return null
	return manifest


static func hash_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var digest := HashingContext.new()
	if digest.start(HashingContext.HASH_SHA256) != OK:
		return ""
	while file.get_position() < file.get_length():
		if (
			digest.update(file.get_buffer(mini(65536, file.get_length() - file.get_position())))
			!= OK
		):
			return ""
	return digest.finish().hex_encode()


func files_match_hashes() -> bool:
	for kind: StringName in KINDS:
		if hash_file(entry_path(kind)) != entry_sha256(kind):
			return false
	return true


func atlas_has_reserved_color(kind: StringName) -> bool:
	var texture := atlas_texture(kind)
	if texture == null:
		return true
	var image := texture.get_image()
	if image == null or image.get_size() != ATLAS_SIZE:
		return true
	var reserved: Array[Color] = [Color("f4f4f4"), Color("41a6f6")]
	for y: int in image.get_height():
		for x: int in image.get_width():
			var pixel := image.get_pixel(x, y)
			for color: Color in reserved:
				if pixel.a > 0.0 and pixel.is_equal_approx(color):
					return true
	return false


func foot_rows_match(kind: StringName) -> bool:
	var texture := atlas_texture(kind)
	if texture == null:
		return false
	var image := texture.get_image()
	if image == null or image.get_size() != ATLAS_SIZE:
		return false
	for row: int in GRID_SIZE.y:
		for column: int in GRID_SIZE.x:
			var last_opaque := -1
			for y: int in CELL_SIZE.y:
				for x: int in CELL_SIZE.x:
					if image.get_pixel(column * CELL_SIZE.x + x, row * CELL_SIZE.y + y).a > 0.0:
						last_opaque = maxi(last_opaque, y)
			if last_opaque != FOOT_ROW:
				return false
	return true
