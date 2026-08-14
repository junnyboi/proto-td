extends SceneTree

const EXPECTED := {
	&"world.act1.ground": ["ground.png", Vector2i(64, 32)],
	&"world.act1.route": ["route.png", Vector2i(64, 32)],
	&"world.act1.raised": ["raised.png", Vector2i(64, 80)],
	&"world.act1.blocked": ["blocked.png", Vector2i(64, 32)],
	&"world.act1.spawn": ["spawn.png", Vector2i(64, 32)],
	&"world.act1.core": ["core.png", Vector2i(128, 128)],
	&"world.act1.panorama": ["panorama.png", Vector2i(512, 256)],
	&"world.act1.env.boulder": ["env-boulder.png", Vector2i(64, 64)],
	&"world.act1.env.barrel": ["env-barrel.png", Vector2i(64, 64)],
	&"world.act1.env.wall": ["env-wall.png", Vector2i(64, 64)],
	&"world.act1.env.crate": ["env-crate.png", Vector2i(64, 64)],
}
const COUNTS := {&"s1": 49, &"s2": 59, &"s3": 68}
var errors := PackedStringArray()


func _initialize() -> void:
	var base := load("res://assets/manifest.tres") as AssetManifest
	var supplement := load("res://assets/act1_shared_manifest.tres") as AssetManifest
	if base == null or supplement == null:
		_fail("manifest load failed")
	else:
		for detail: String in base.validate_contract():
			_fail("base.%s" % detail)
		for detail: String in supplement.validate_contract():
			_fail("supplement.%s" % detail)
		if supplement.entries.size() != 11:
			_fail("supplement must contain exactly eleven entries")
		for id: StringName in supplement.entries:
			if base.entries.has(id):
				_fail("manifest overlap: %s" % id)
			if not EXPECTED.has(id):
				_fail("unexpected ID: %s" % id)
		_validate_assets(supplement)
	_validate_themes()
	if errors.is_empty():
		print("ACT1_SHARED_CONTRACT_OK S1=49 S2=59 S3=68")
		quit(0)
		return
	for detail: String in errors:
		push_error("[act1_shared_contract] %s" % detail)
	quit(1)


func _validate_assets(supplement: AssetManifest) -> void:
	for id: StringName in EXPECTED:
		if not supplement.entries.has(id):
			_fail("missing ID: %s" % id)
			continue
		var filename: String = EXPECTED[id][0]
		var size: Vector2i = EXPECTED[id][1]
		var runtime := "res://assets/world/act1/%s" % filename
		var staging := "res://staging/assets/world/act1/%s" % filename
		var fragment := (
			"res://assets/provenance/fragments/act1/%s.provenance.json"
			% String(id).replace(".", "_")
		)
		var entry: Dictionary = supplement.entries[id]
		if entry.get("pattern") != runtime or entry.get("size") != size:
			_fail("entry contract mismatch: %s" % id)
		if not bool(entry.get("placeholder", false)):
			_fail("entry is not placeholder: %s" % id)
		if FileAccess.get_sha256(runtime) != FileAccess.get_sha256(staging):
			_fail("runtime/staging mismatch: %s" % id)
		if String(entry.get("provenance_sha256", "")) != FileAccess.get_sha256(fragment):
			_fail("fragment hash mismatch: %s" % id)
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(fragment))
		if data is not Dictionary:
			_fail("fragment parse failed: %s" % id)
		elif (
			data.get("logical_id") != String(id)
			or data.get("approval", {}).get("token") != "ACT-I-S1-S3-VISUAL-PASS-V3"
			or bool(data.get("human_final_art", true))
		):
			_fail("fragment truth mismatch: %s" % id)
		if Art.size(id) != size or Art.texture(id) == null:
			_fail("Art resolution failed: %s" % id)


func _validate_themes() -> void:
	for id: StringName in [&"s1", &"s2", &"s3"]:
		var stage := load("res://data/stages/%s.tres" % id) as StageDef
		var theme := load("res://data/presentation/%s_world_theme.tres" % id) as StageArtTheme
		if stage == null or theme == null:
			_fail("%s stage/theme load failed" % id)
			continue
		for detail: String in theme.validation_errors(stage):
			_fail("%s.%s" % [id, detail])
		var root := Node2D.new()
		if not IsoGridBuilder.build_stage_with_theme(root, stage, theme, false):
			_fail("%s render failed" % id)
		if root.get_child_count() != COUNTS[id]:
			_fail("%s node count %d != %d" % [id, root.get_child_count(), COUNTS[id]])
		var cadence := 0
		for child: Node in root.get_children():
			if child.name.begins_with("Cadence_"):
				cadence += 1
			if cadence != 0:
				_fail("%s cadence nodes present" % id)
			var props := 0
			for prop_child: Node in root.get_children():
				if prop_child.name.begins_with("EnvProp_"):
					props += 1
			if props != theme.env_prop_cells.size():
				_fail(
					"%s environment prop count %d != %d" % [id, props, theme.env_prop_cells.size()]
				)
		root.free()


func _fail(detail: String) -> void:
	errors.append(detail)
