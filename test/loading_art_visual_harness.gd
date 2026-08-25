extends SceneTree

var _loading: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("LOADING_ART_VISUAL_HARNESS_READY")
	_loading = load("res://scenes/loading.tscn").instantiate() as Control
	root.add_child(_loading)
	_loading.set_process(false)
	var progress := _loading.find_child("Progress", true, false) as ProgressBar
	var status := _loading.find_child("StatusLabel", true, false) as Label
	var percentage := _loading.find_child("PercentageLabel", true, false) as Label
	if progress != null:
		progress.value = 62.0
	if status != null:
		status.text = "ALIGNING LUNAR GEOMETRY"
	if percentage != null:
		percentage.text = "62%"
