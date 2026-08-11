extends SceneTree

## Scratch probe: does a ResourceSaver binary round-trip keep grid_rows?


func _initialize() -> void:
	var stage := load("res://data/stages/test_lane.tres") as StageDef
	print("[probe] source rows=", stage.grid_rows.size())
	ResourceSaver.save(stage, "/tmp/tl.res")
	var re := ResourceLoader.load("/tmp/tl.res", "", ResourceLoader.CACHE_MODE_IGNORE) as StageDef
	print("[probe] binary round-trip rows=", re.grid_rows.size())
	quit(0)
