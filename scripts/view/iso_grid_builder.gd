class_name IsoGridBuilder
extends RefCounted

## Builds the static iso terrain under GridRoot (P12.1): manifest-sized
## diamond tile textures with a flat-color Polygon2D fallback lane, cliff
## walls + cast shade for ELEVATED cells, and the out-of-bounds backdrop
## ring. Pure scene construction — no model reads, no state; battle_view
## owns dynamic projection and relayout.

const TILE_COLORS := {
	StageDef.Tile.VOID: Color("1a1c2c"),
	StageDef.Tile.GROUND: Color("566c86"),
	StageDef.Tile.ELEVATED: Color("94b0c2"),
	StageDef.Tile.SPAWN: Color("b13e53"),
	StageDef.Tile.BASE: Color("3b5dc9"),
	StageDef.Tile.BLOCKED: Color("333c57"),
}
## Fallback-lane stand-in for the road material (TILE_COLORS has no road
## key — road is an art-id swap on GROUND). TD32 warm dirt; not probe-reserved.
const ROAD_STANDIN_COLOR := Color("b86f50")
const BACKDROP_TILE_COLOR := Color("232634")
## Filler ring beyond the stage bounds (dynamic-fit requirement): no bare
## canvas around the playfield.
const BACKDROP_RING := 10
## 32px-native art on the 64px face grid (pinned 2x integer, same pin as
## battle_view.SPRITE_SCALE)
const SPRITE_SCALE := 2

const TILE_ART := {
	StageDef.Tile.VOID: &"tile_void",
	StageDef.Tile.GROUND: &"tile_ground",
	StageDef.Tile.ELEVATED: &"tile_elevated",
	StageDef.Tile.SPAWN: &"tile_spawn",
	StageDef.Tile.BASE: &"tile_base",
	StageDef.Tile.BLOCKED: &"tile_blocked",
}


static func build_stage(
	grid_root: Node2D,
	stage: StageDef,
	theme_resolver: Callable = Callable(),
	report_error: bool = true,
) -> bool:
	var result := StageArtTheme.resolve_for(stage, theme_resolver)
	var error := String(result["error"])
	if not error.is_empty():
		if report_error:
			push_error("iso_grid_builder: %s" % error)
		return false
	var theme := result["theme"] as StageArtTheme
	_build_backdrop_ring(grid_root, stage.grid_size(), theme)
	_build_terrain(grid_root, stage, theme)
	return true


static func _build_terrain(
	grid_root: Node2D, stage: StageDef, theme: StageArtTheme
) -> void:
	var size := stage.grid_size()
	var path_cells: Dictionary = {}
	for i: int in stage.paths.size():
		for cell: Vector2i in stage.path_cells(i):
			path_cells[cell] = true
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var tile := stage.tile_at(cell)
			var lifted := tile == StageDef.Tile.ELEVATED
			var is_road := tile == StageDef.Tile.GROUND and path_cells.has(cell)
			var art_id: StringName = theme.tile_id(tile, path_cells.has(cell)) if theme != null else &""
			if art_id == &"":
				art_id = &"tile_road" if is_road else TILE_ART[tile]
			if _add_tile_sprite(grid_root, stage, cell, art_id, lifted):
				continue
			var color: Color = ROAD_STANDIN_COLOR if is_road else TILE_COLORS[tile]
			if lifted:
				_add_tile_walls(grid_root, stage, cell, color)
			var poly := Polygon2D.new()
			poly.name = "Tile_%d_%d" % [x, y]
			poly.color = color
			poly.polygon = IsoProjection.cell_polygon(cell, lifted)
			poly.z_index = IsoProjection.tile_z(cell)
			grid_root.add_child(poly)
	if theme != null:
		_add_theme_decor(grid_root, stage, theme)


static func _build_backdrop_ring(
	grid_root: Node2D, size: Vector2i, theme: StageArtTheme
) -> void:
	if theme != null and theme.backdrop_panorama_id != &"":
		_add_backdrop_panorama(grid_root, size, theme.backdrop_panorama_id)
		return
	for y: int in range(-BACKDROP_RING, size.y + BACKDROP_RING):
		for x: int in range(-BACKDROP_RING, size.x + BACKDROP_RING):
			if x >= 0 and x < size.x and y >= 0 and y < size.y:
				continue
			var cell := Vector2i(x, y)
			var backdrop_id := _backdrop_art_id(cell, size, theme)
			if backdrop_id == &"":
				continue
			var tex := Art.texture(backdrop_id)
			var art_size := Art.size(backdrop_id)
			if art_size == Vector2i.ZERO and tex != null:
				art_size = Vector2i(tex.get_width(), tex.get_height())
			if tex != null:
				var top: Vector2 = IsoProjection.cell_polygon(cell)[0]
				var sprite := TextureRect.new()
				sprite.name = "Backdrop_%d_%d" % [x, y]
				sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
				sprite.texture = tex
				sprite.stretch_mode = TextureRect.STRETCH_SCALE
				sprite.size = Vector2(art_size) * SPRITE_SCALE
				var rise := float(art_size.y - 16) * SPRITE_SCALE
				sprite.position = Vector2(top.x - IsoProjection.TILE_W * 0.5, top.y - rise)
				sprite.z_index = -10 - _backdrop_distance(cell, size)
				grid_root.add_child(sprite)
				continue
			var poly := Polygon2D.new()
			poly.color = BACKDROP_TILE_COLOR
			poly.polygon = IsoProjection.cell_polygon(cell)
			poly.z_index = -2
			grid_root.add_child(poly)


static func _add_backdrop_panorama(
	grid_root: Node2D, size: Vector2i, art_id: StringName
) -> void:
	var tex := Art.texture(art_id)
	var art_size := Art.size(art_id)
	if tex == null or art_size == Vector2i.ZERO:
		return
	var stage_center := IsoProjection.project(Vector2(size) * 0.5)
	var sprite := TextureRect.new()
	sprite.name = "BackdropPanorama"
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = tex
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.size = Vector2(art_size) * SPRITE_SCALE
	sprite.position = stage_center - sprite.size * 0.5
	# BattleView's flat canvas lives at -20; panorama must sit above it while
	# every terrain tile remains in the non-negative grid bands.
	sprite.z_index = -10
	grid_root.add_child(sprite)


static func _backdrop_distance(cell: Vector2i, size: Vector2i) -> int:
	var dx := maxi(maxi(-cell.x, cell.x - size.x + 1), 0)
	var dy := maxi(maxi(-cell.y, cell.y - size.y + 1), 0)
	return maxi(dx, dy)


static func _backdrop_art_id(
	cell: Vector2i, size: Vector2i, theme: StageArtTheme
) -> StringName:
	if theme == null:
		return &"tile_backdrop"
	var distance := _backdrop_distance(cell, size)
	var variants: Array[StringName] = [theme.backdrop_id]
	variants.append_array(theme.backdrop_variant_ids)
	if cell == Vector2i(-1, -1):
		return variants[0]
	if cell == Vector2i(-3, -3):
		return variants[1]
	if cell == Vector2i(-6, -6):
		return variants[2]
	if cell == Vector2i(size.x + 1, size.y + 1):
		return variants[3]
	var pools: Array[Array] = [
		[variants[0], variants[0], variants[3]],
		[variants[0], variants[1], variants[3]],
		[variants[1], variants[2], variants[2], variants[3]],
	]
	var hashed: int = absi(cell.x * 374761393 + cell.y * 668265263 + distance * 1274126177)
	# A complete low foothill/mist rim sells the platform edge. Mid and far
	# layers deliberately contain ravine gaps; peaks are sparse horizon marks,
	# not one sprite per coordinate.
	if distance == 2 and hashed % 4 == 0:
		return &""
	if distance >= 3 and distance <= 5 and hashed % 3 == 0:
		return &""
	if distance >= 6 and hashed % 4 != 0:
		return &""
	var band := 0 if distance <= 1 else (1 if distance <= 5 else 2)
	var pool: Array = pools[band]
	return StringName(pool[hashed % pool.size()])


## Manifest-sized tile sprite anchored at the face's TOP corner (the canvas
## is the face plus optional baked wall rows below, drawn at the pinned 2x).
## Returns false when the id has no art — the flat-color fallback lane runs.
static func _add_tile_sprite(
	grid_root: Node2D, stage: StageDef, cell: Vector2i, art_id: StringName, lifted: bool
) -> bool:
	var tex := Art.texture(art_id)
	if tex == null:
		return false
	var top: Vector2 = IsoProjection.cell_polygon(cell, lifted)[0]
	var sprite := TextureRect.new()
	sprite.name = "Tile_%d_%d" % [cell.x, cell.y]
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = tex
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	var art_size := Art.size(art_id)
	if art_size == Vector2i.ZERO:
		art_size = Vector2i(tex.get_width(), tex.get_height())
	sprite.size = Vector2(art_size) * SPRITE_SCALE
	sprite.position = Vector2(top.x - IsoProjection.TILE_W * 0.5, top.y)
	sprite.z_index = IsoProjection.tile_z(cell)
	grid_root.add_child(sprite)
	if lifted:
		_add_cliff_shade(grid_root, stage, cell)
	return true


static func _add_theme_decor(grid_root: Node2D, stage: StageDef, theme: StageArtTheme) -> void:
	for cell: Vector2i in theme.route_notch_cells:
		_add_face_overlay(grid_root, cell, theme.route_notch_id, "RouteNotch")
	_add_landmark(
		grid_root,
		stage,
		theme.spawn_cell,
		theme.spawn_landmark_id,
		theme.spawn_pivot,
		theme.spawn_offset,
		"SpawnLandmark",
	)
	_add_landmark(
		grid_root,
		stage,
		theme.core_cell,
		theme.core_landmark_id,
		theme.core_pivot,
		theme.core_offset,
		"CoreLandmark",
	)
	# world.s1.rain_measure intentionally remains manifest-backed but unplaced.


static func _add_face_overlay(
	grid_root: Node2D, cell: Vector2i, art_id: StringName, node_prefix: String
) -> void:
	var tex := Art.texture(art_id)
	if tex == null:
		return
	var art_size := Art.size(art_id)
	if art_size == Vector2i.ZERO:
		art_size = Vector2i(tex.get_width(), tex.get_height())
	var top: Vector2 = IsoProjection.cell_polygon(cell)[0]
	var sprite := TextureRect.new()
	sprite.name = "%s_%d_%d" % [node_prefix, cell.x, cell.y]
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = tex
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.size = Vector2(art_size) * SPRITE_SCALE
	sprite.position = Vector2(top.x - IsoProjection.TILE_W * 0.5, top.y)
	sprite.z_index = IsoProjection.tile_z(cell) + 1
	grid_root.add_child(sprite)


static func _add_landmark(
	grid_root: Node2D,
	stage: StageDef,
	cell: Vector2i,
	art_id: StringName,
	pivot: Vector2i,
	offset: Vector2i,
	node_name: String,
) -> void:
	var tex := Art.texture(art_id)
	if tex == null:
		return
	var art_size := Art.size(art_id)
	if art_size == Vector2i.ZERO:
		art_size = Vector2i(tex.get_width(), tex.get_height())
	var center := IsoProjection.face_center(cell, stage.tile_at(cell) == StageDef.Tile.ELEVATED)
	var sprite := TextureRect.new()
	sprite.name = node_name
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = tex
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.size = Vector2(art_size) * SPRITE_SCALE
	sprite.position = center - Vector2(pivot) * SPRITE_SCALE + Vector2(offset) * SPRITE_SCALE
	sprite.z_index = IsoProjection.tile_z(cell) + 1
	grid_root.add_child(sprite)


## Cliff walls for a lifted face in the FALLBACK lane (textured tiles bake
## their walls into the art): left and right side quads dropping
## ELEV_LIFT_PX to the flat footprint; the right wall one step darker.
static func _add_tile_walls(
	grid_root: Node2D, stage: StageDef, cell: Vector2i, face_color: Color
) -> void:
	var pts := IsoProjection.cell_polygon(cell, true)
	var drop := Vector2(0.0, IsoProjection.ELEV_LIFT_PX)
	var corners := [
		[pts[3], pts[2], face_color.darkened(0.35)],
		[pts[2], pts[1], face_color.darkened(0.5)],
	]
	for c: Array in corners:
		var a: Vector2 = c[0]
		var b: Vector2 = c[1]
		var wall := Polygon2D.new()
		wall.color = c[2]
		wall.polygon = PackedVector2Array([a, b, b + drop, a + drop])
		wall.z_index = IsoProjection.tile_z(cell)
		grid_root.add_child(wall)
	_add_cliff_shade(grid_root, stage, cell)


## Soft cast shade on the SE neighbor's upper face half (trim slot 1):
## sells the height without touching the neighbor's own tile art.
static func _add_cliff_shade(grid_root: Node2D, stage: StageDef, cell: Vector2i) -> void:
	var se := cell + Vector2i(1, 1)
	var se_tile := stage.tile_at(se)
	if se_tile == StageDef.Tile.VOID or se_tile == StageDef.Tile.ELEVATED:
		return
	var pts_se := IsoProjection.cell_polygon(se)
	var shade := Polygon2D.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.22)
	shade.polygon = PackedVector2Array([pts_se[0], pts_se[1], pts_se[3]])
	shade.z_index = IsoProjection.tile_z(se) + 1
	grid_root.add_child(shade)
