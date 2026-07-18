extends SceneTree
## Headless smoke test for production buildings:
## 1. Building spawns units on its timer.
## 2. Spawning stops at max_units (3).
## 3. Killing a spawned unit frees a slot and a replacement spawns.
## 4. Building dies when damaged to zero.
## Run: godot --headless -s tools/building_smoke_test.gd

var frames := 0
var spawned: Array = []
var building: Spawner
var building_died := false
var killed_one := false


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

	building = (load("res://scenes/buildings/hut.tscn") as PackedScene).instantiate()
	building.spawn_interval = 0.5
	building.rally_offset = Vector3(3, 0, 0)
	building.unit_spawned.connect(_on_unit_spawned)
	building.died.connect(func(_b): building_died = true)
	root.add_child(building)

	process_frame.connect(_on_frame)


func _on_unit_spawned(unit: Unit) -> void:
	spawned.append(unit)
	root.add_child(unit)


func _fail(message: String) -> void:
	print("SMOKE TEST FAIL: ", message)
	quit(1)


func _on_frame() -> void:
	frames += 1

	# ~4s in (8 timer ticks at 0.5s): cap must hold at 3.
	if frames == 240:
		if spawned.size() != 3:
			return _fail("expected 3 spawns at cap, got %d" % spawned.size())
		print("cap held: 3 units spawned, further ticks skipped")
		spawned[0].take_damage(9999.0)
		killed_one = true

	# After the kill, a replacement should arrive within ~2s.
	if killed_one and frames == 420:
		if spawned.size() != 4:
			return _fail("expected replacement spawn after death, total 4, got %d" % spawned.size())
		print("slot freed on death: replacement spawned")
		building.take_damage(9999.0)

	if frames == 480:
		if not building_died:
			return _fail("building did not die from damage")
		print("SMOKE TEST PASS: cap, respawn, and destructibility all work")
		quit(0)
