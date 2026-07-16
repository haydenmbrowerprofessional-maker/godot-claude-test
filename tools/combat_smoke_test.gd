extends SceneTree
## Headless smoke test: 2 blue units vs 1 red near each other.
## Auto-aggro should trigger and blue should win within ~20 seconds.
## Run: godot --headless -s tools/combat_smoke_test.gd

var frames := 0
var units: Array = []


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

	var blue_scene: PackedScene = load("res://scenes/unit_blue.tscn")
	var red_scene: PackedScene = load("res://scenes/unit_red.tscn")
	for config in [[blue_scene, Vector3(-1, 0.1, 2)], [blue_scene, Vector3(1, 0.1, 2)], [red_scene, Vector3(0, 0.1, -2)]]:
		var unit: Unit = config[0].instantiate()
		unit.position = config[1]
		root.add_child(unit)
		units.append(unit)

	process_frame.connect(_on_frame)


func _on_frame() -> void:
	frames += 1
	if frames % 240 == 0:
		print("frame ", frames, ": ", units.map(func(u): return u.health if is_instance_valid(u) else "dead"))

	var blue_alive := is_instance_valid(units[0]) or is_instance_valid(units[1])
	var red_alive := is_instance_valid(units[2])

	if not red_alive and blue_alive:
		print("SMOKE TEST PASS: red defeated at frame ", frames, ", blue survives")
		quit(0)
	elif not blue_alive:
		print("SMOKE TEST FAIL: blue wiped out")
		quit(1)
	elif frames >= 2400:
		print("SMOKE TEST FAIL: stalemate after ", frames, " frames — combat never resolved")
		quit(1)
