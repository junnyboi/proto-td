extends SceneTree

## Scratch: pin editor/export/convert_text_resources_to_binary=false — the
## The original 4.7.1 export converter dropped StageDef.grid_rows (PackedStringArray) while
## a runtime ResourceSaver round-trip keeps it (probe_binres.gd).


func _initialize() -> void:
	ProjectSettings.set_setting("editor/export/convert_text_resources_to_binary", false)
	ProjectSettings.save()
	print("[set] convert_text_resources_to_binary=false saved")
	quit(0)
