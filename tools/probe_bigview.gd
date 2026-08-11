extends SceneTree

## Scratch probe (web-export terrain bug): boot a battle, print the stage's
## grid/art fields, screenshot. Run against source AND against the exported
## pck (--main-pack) to localize where grid data is lost.


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.call("start_battle", game.get("default_stage_id"))
	for _i: int in 30:
		await process_frame
	var stage: StageDef = game.get("current_battle").stage
	print("[probe] stage id=", stage.id, " rows=", stage.grid_rows.size(),
		" grid_size=", stage.grid_size(), " paths=", stage.paths.size(),
		" waves=", stage.waves.size())
	print("[probe] tile_ground tex null=", Art.texture(&"tile_ground") == null,
		" manifest size=", Art.size(&"tile_ground"))
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png("/tmp/pckview.png")
		print("[probe] saved /tmp/pckview.png")
	quit(0)
