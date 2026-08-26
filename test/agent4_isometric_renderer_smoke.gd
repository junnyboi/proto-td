extends SceneTree

const TERRAIN_SCRIPT := preload("res://scripts/view/proto_isometric_terrain.gd")
const THEME_SCRIPT := preload("res://data/presentation/stage_art_theme.gd")

const EXPECTED_BIOMES := {
	&"s1": &"desert",
	&"s2": &"wetland",
	&"s3": &"frozen",
	&"s4": &"lava",
	&"s5": &"desert",
	&"s6": &"wetland",
	&"s7": &"frozen",
	&"s8": &"lava",
}

const LEGACY_TILE_PATHS := [
	"res://assets/sprites/tile_ground.png",
	"res://assets/sprites/tile_road.png",
	"res://assets/sprites/tile_elevated.png",
	"res://assets/world/act1/ground.png",
	"res://assets/world/act1/route.png",
	"res://assets/world/act1/raised.png",
	"res://assets/world/s1/s1-elevated.png",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures := PackedStringArray()
	for path: String in TERRAIN_SCRIPT.required_texture_paths():
		if not ResourceLoader.exists(path):
			failures.append("missing source asset: %s" % path)
	for path: String in LEGACY_TILE_PATHS:
		if FileAccess.file_exists(path):
			failures.append("legacy tile asset still present: %s" % path)
	for stage_id: StringName in EXPECTED_BIOMES:
		var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
		if stage == null:
			failures.append("stage failed to load: %s" % stage_id)
			continue
		var theme := THEME_SCRIPT.load_for(stage)
		var root_node := Node2D.new()
		root.add_child(root_node)
		if not IsoGridBuilder.build_stage_with_theme(root_node, stage, theme, false):
			failures.append("grid build failed: %s" % stage_id)
		else:
			var terrain := root_node.get_node_or_null("ProtoIsometricTerrain")
			if terrain == null:
				failures.append("terrain node missing: %s" % stage_id)
			elif terrain.call("biome") != EXPECTED_BIOMES[stage_id]:
				failures.append("wrong biome for %s" % stage_id)
			elif terrain.has_method("_draw_elevated_obstacle"):
				failures.append("platform-top obstacle renderer still exists: %s" % stage_id)
			for y: int in stage.grid_size().y:
				for x: int in stage.grid_size().x:
					var cell := Vector2i(x, y)
					var terrain_id: StringName = terrain.call("terrain_id_at", cell)
					if terrain_id == &"":
						failures.append("empty terrain id at %s %s" % [stage_id, cell])
			var endpoint_count := 0
			for child: Node in root_node.get_children():
				if child is BattleEndpointLandmark:
					endpoint_count += 1
					if (child as BattleEndpointLandmark).frame_count() <= 1:
						failures.append("endpoint is not animated: %s %s" % [stage_id, child.name])
				elif child.name.begins_with("EnvProp_") or child.name.begins_with("ProceduralFallback_"):
					failures.append("platform-top prop remains: %s %s" % [stage_id, child.name])
			var expected_endpoints := _tile_count(stage, StageDef.Tile.SPAWN)
			expected_endpoints += _tile_count(stage, StageDef.Tile.BASE)
			if endpoint_count != expected_endpoints:
				failures.append(
					"endpoint count mismatch %s: %d != %d"
					% [stage_id, endpoint_count, expected_endpoints]
				)
		root.remove_child(root_node)
		root_node.free()
	if failures.is_empty():
		print("AGENT4_ISOMETRIC_RENDERER_SMOKE_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _tile_count(stage: StageDef, tile: StageDef.Tile) -> int:
	var count := 0
	var size := stage.grid_size()
	for y: int in size.y:
		for x: int in size.x:
			if stage.tile_at(Vector2i(x, y)) == tile:
				count += 1
	return count
