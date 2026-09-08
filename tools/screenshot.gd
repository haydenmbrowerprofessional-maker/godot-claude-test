extends SceneTree
## Dev tool: boots the real game scene, lets it settle, and saves a
## full-resolution PNG so visuals can be reviewed outside the editor.
## Run: godot --path . -s tools/screenshot.gd

var frames := 0


func _init() -> void:
	change_scene_to_file.call_deferred("res://scenes/main.tscn")
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	frames += 1
	if frames < 150:
		return
	var img := root.get_texture().get_image()
	var out := "user://shot.png"
	img.save_png(out)
	print("SAVED: ", ProjectSettings.globalize_path(out))
	quit()
