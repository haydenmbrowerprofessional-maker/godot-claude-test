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
	# Called dynamically: get_texture() is declared to return ViewportTexture,
	# which the size-optimized engine compiles out (the game never uses it),
	# and GDScript rejects unknown native types at parse time.
	var tex: Texture2D = root.call("get_texture")
	var img := tex.get_image()
	var out := "user://shot.png"
	img.save_png(out)
	print("SAVED: ", ProjectSettings.globalize_path(out))
	quit()
