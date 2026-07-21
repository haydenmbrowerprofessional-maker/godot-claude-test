extends SceneTree
## Headless smoke test for upgradeable towers:
## 1. Fresh tower is level 1 with base stats.
## 2. upgrade() raises level, damage, and range through 3 tiers, then caps.
## 3. The tower shoots an enemy in range.
## Run: godot --headless -s tools/tower_smoke_test.gd

var frames := 0
var tower: Tower
var dummy: Unit


func _init() -> void:
	_build()


func _build() -> void:
	tower = (load("res://scenes/buildings/watchtower.tscn") as PackedScene).instantiate()
	root.add_child(tower)

	if tower.level != 1 or tower.attack_damage != 10.0 or tower.attack_range != 7.0:
		return _fail("bad base stats: lvl=%d dmg=%s rng=%s" % [tower.level, tower.attack_damage, tower.attack_range])

	if not tower.upgrade() or tower.level != 2 or tower.attack_damage != 17.0:
		return _fail("upgrade to Lv2 failed: lvl=%d dmg=%s" % [tower.level, tower.attack_damage])
	if not tower.attack_range > 7.0:
		return _fail("Lv2 range did not increase")

	if not tower.upgrade() or tower.level != 3 or tower.attack_damage != 26.0:
		return _fail("upgrade to Lv3 failed: lvl=%d dmg=%s" % [tower.level, tower.attack_damage])

	if tower.can_upgrade() or tower.upgrade() or tower.level != 3:
		return _fail("tower upgraded past max level")
	print("upgrade tiers OK: Lv1→2→3 stats scaled, capped at 3")

	# Functional: the tower should shoot a frozen enemy in range.
	dummy = (load("res://scenes/unit_red.tscn") as PackedScene).instantiate()
	dummy.position = Vector3(5, 0.1, 0)
	root.add_child(dummy)
	dummy.set_physics_process.call_deferred(false)

	process_frame.connect(_on_frame)


func _on_frame() -> void:
	frames += 1
	if dummy.health < dummy.max_health:
		print("SMOKE TEST PASS: tower shot enemy in range at frame ", frames)
		quit(0)
	if frames >= 300:
		return _fail("tower never damaged an enemy in range")


func _fail(message: String) -> void:
	print("SMOKE TEST FAIL: ", message)
	quit(1)
