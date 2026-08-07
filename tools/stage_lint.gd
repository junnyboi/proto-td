extends SceneTree

## Stage data lint (verify.sh rung R2.5). Phase 1 checks: path contiguity
## (4-connected, unit steps), starts on SPAWN, ends on BASE, every path cell
## enemy-walkable, wave enemy ids resolve, path_idx in range, sane limits.
## Phase 10 adds: reward id resolution, difficulty monotonicity,
## teach-before-use.

const STAGES_DIR := "res://data/stages"
const ENEMIES_DIR := "res://data/enemies"


func _initialize() -> void:
	var failures: Array[String] = []
	var stage_files := _list_tres(STAGES_DIR)
	if stage_files.is_empty():
		failures.append("no stages found under %s" % STAGES_DIR)
	for path: String in stage_files:
		_lint_stage(path, failures)
	if failures.is_empty():
		print("[stage-lint] OK (%d stages)" % stage_files.size())
		quit(0)
	else:
		for f: String in failures:
			printerr("[stage-lint] FAIL: " + f)
		quit(1)


func _list_tres(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f: String in dir.get_files():
		if f.ends_with(".tres"):
			out.append(dir_path + "/" + f)
	out.sort()
	return out


func _lint_stage(path: String, failures: Array[String]) -> void:
	var stage := load(path) as StageDef
	if stage == null:
		failures.append("%s: not a StageDef" % path)
		return
	var tag := String(stage.id)
	if stage.grid_rows.is_empty():
		failures.append("%s: empty grid" % tag)
		return
	var width := stage.grid_rows[0].length()
	for row: String in stage.grid_rows:
		if row.length() != width:
			failures.append("%s: ragged grid rows" % tag)
	if stage.paths.is_empty():
		failures.append("%s: no paths" % tag)
	for i: int in stage.paths.size():
		_lint_path(stage, i, failures, tag)
	for w: Dictionary in stage.waves:
		var enemy_path := "%s/%s.tres" % [ENEMIES_DIR, w.get("enemy_id", "")]
		if not ResourceLoader.exists(enemy_path):
			failures.append("%s: wave enemy id has no def: %s" % [tag, enemy_path])
		var pi := int(w.get("path_idx", -1))
		if pi < 0 or pi >= stage.paths.size():
			failures.append("%s: wave path_idx out of range: %d" % [tag, pi])
		if int(w.get("tick", -1)) < 0:
			failures.append("%s: wave tick < 0" % tag)
	if stage.leak_limit < 0:
		failures.append("%s: leak_limit < 0" % tag)


func _lint_path(stage: StageDef, idx: int, failures: Array[String], tag: String) -> void:
	var cells := stage.path_cells(idx)
	if cells.size() < 2:
		failures.append("%s path %d: fewer than 2 cells" % [tag, idx])
		return
	if stage.tile_at(cells[0]) != StageDef.Tile.SPAWN:
		failures.append("%s path %d: does not start on SPAWN (%s)" % [tag, idx, cells[0]])
	if stage.tile_at(cells[cells.size() - 1]) != StageDef.Tile.BASE:
		failures.append("%s path %d: does not end on BASE (%s)" % [tag, idx, cells[cells.size() - 1]])
	for i: int in cells.size():
		if not stage.is_enemy_walkable(cells[i]):
			failures.append("%s path %d: cell %s not walkable" % [tag, idx, cells[i]])
		if i > 0:
			var d: Vector2i = (cells[i] - cells[i - 1]).abs()
			if d.x + d.y != 1:
				failures.append(
					"%s path %d: not contiguous at %s -> %s" % [tag, idx, cells[i - 1], cells[i]]
				)
