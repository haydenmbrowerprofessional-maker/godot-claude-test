extends SceneTree
## Headless smoke test for unit variety:
## 1. Each variant carries its distinct stats (ranged flag, range, health).
## 2. A ranged archer damages an enemy from beyond melee range.
## Run: godot --headless -s tools/units_smoke_test.gd

var frames := 0
var archer: Unit
var dummy: Unit


func _init() -> void:
	_build()


func _build() -> void:
	var soldier: Unit = (load("res://scenes/unit_blue.tscn") as PackedScene).instantiate()
	var a: Unit = (load("res://scenes/unit_archer_blue.tscn") as PackedScene).instantiate()
	var knight: Unit = (load("res://scenes/unit_knight_blue.tscn") as PackedScene).instantiate()

	if a.ranged != true or soldier.ranged != false:
		return _fail("ranged flags wrong (archer=%s soldier=%s)" % [a.ranged, soldier.ranged])
	if not a.attack_range > soldier.attack_range:
		return _fail("archer range (%s) should exceed soldier (%s)" % [a.attack_range, soldier.attack_range])
	if not knight.max_health > soldier.max_health:
		return _fail("knight hp (%s) should exceed soldier (%s)" % [knight.max_health, soldier.max_health])
	if not knight.move_speed < soldier.move_speed:
		return _fail("knight should be slower than soldier")
	soldier.free()
	knight.free()
	print("stats OK: archer ranged & long-range, knight tanky & slow")

	# Functional: archer shoots a frozen enemy dummy from range.
	var ground := StaticBody3D.new()
	ground.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 0.5, 40)
	shape.shape = box
	shape.position = Vector3(0, -0.25, 0)
	ground.add_child(shape)
	root.add_child(ground)

	archer = a
	archer.position = Vector3(0, 0.1, 0)
	root.add_child(archer)

	dummy = (load("res://scenes/unit_red.tscn") as PackedScene).instantiate()
	dummy.position = Vector3(6, 0.1, 0)
	root.add_child(dummy)
	# Freeze the dummy so it can't close distance or fight back.
	dummy.set_physics_process.call_deferred(false)

	process_frame.connect(_on_frame)


func _on_frame() -> void:
	frames += 1
	if dummy.health < dummy.max_health:
		var dist := archer.global_position.distance_to(dummy.global_position)
		if dist < 3.0:
			return _fail("archer closed to melee (%.1f) instead of shooting" % dist)
		print("SMOKE TEST PASS: archer hit enemy from range %.1f at frame %d" % [dist, frames])
		quit(0)
	if frames >= 400:
		return _fail("archer never damaged the dummy")


func _fail(message: String) -> void:
	print("SMOKE TEST FAIL: ", message)
	quit(1)
