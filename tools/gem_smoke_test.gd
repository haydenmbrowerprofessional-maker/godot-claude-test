extends SceneTree
## Headless smoke test: a unit ordered onto a gem collects it.
## Run: godot --headless -s tools/gem_smoke_test.gd

var frames := 0


func _init() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 0.5, 40)
	shape.shape = box
	shape.position = Vector3(0, -0.25, 0)
	ground.add_child(shape)
	root.add_child(ground)

	var gem := (load("res://scenes/gem.tscn") as PackedScene).instantiate()
	gem.position = Vector3(5, 0, 0)
	root.add_child(gem)

	var unit: Unit = (load("res://scenes/unit_blue.tscn") as PackedScene).instantiate()
	unit.position = Vector3(0, 0.1, 0)
	root.add_child(unit)
	unit.command_move.call_deferred(Vector3(5, 0, 0))

	process_frame.connect(_on_frame)


func _on_frame() -> void:
	frames += 1
	# Resolve the same node gem.gd talks to (the autoload when present).
	var state := root.get_node_or_null("GameState")
	if state == null:
		if frames == 1:
			state = (load("res://scripts/game_state.gd") as GDScript).new()
			state.name = "GameState"
			root.add_child(state)
		return
	if state.gems >= 1:
		print("SMOKE TEST PASS: gem collected at frame ", frames)
		quit(0)
	if frames >= 600:
		print("SMOKE TEST FAIL: gem not collected after ", frames, " frames")
		quit(1)
