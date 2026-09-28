extends SceneTree
## Headless end-to-end playthrough of the real map (scenes/main.tscn):
## click/box selection, move orders, camera zoom, placing every building
## through the tech tree, selecting and upgrading a tower (with the Workshop
## gate), collecting gems, raising the Grand Totem for victory, and restarting.
##
## Exists to exercise main.gd/hud.gd code paths the unit tests never touch —
## vital when running on a stripped custom engine, where a compiled-out class
## or method only fails at the moment the code path actually executes.
## Run: godot --headless -s tools/e2e_smoke_test.gd

var frames := 0
var step := 0
var wait_until := 0
var main: Node3D
var main_id := 0
var state: Node


func _init() -> void:
	change_scene_to_file.call_deferred("res://scenes/main.tscn")
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	frames += 1
	if frames > 3000:
		return _fail("timed out at step %d" % step)
	if frames < wait_until:
		return
	match step:
		0: _check_start()
		1: _test_selection_and_orders()
		2: _test_camera()
		3: _build_first_tier()
		4: _test_tower_upgrades_before_workshop()
		5: _build_second_tier()
		6: _test_tower_upgrade_after_workshop()
		7: _test_totem_gate_and_victory()
		8: _check_victory()
		9: _check_restart()


func _next(delay_frames := 2) -> void:
	step += 1
	wait_until = frames + delay_frames


# --- Steps ------------------------------------------------------------------

func _check_start() -> void:
	main = current_scene as Node3D
	if main == null or main.name != "Main":
		return  # Scene still loading.
	state = root.get_node("GameState")
	main_id = main.get_instance_id()
	var units := _blue_units().size()
	var camps := get_nodes_in_group("camps").size()
	if units != 3 or camps != 4:
		return _fail("expected 3 starter units and 4 camps, got %d/%d" % [units, camps])
	print("start OK: 3 units, 4 camps")
	_next(60)  # Let the fog reveal around the base.


func _test_selection_and_orders() -> void:
	var cam := root.get_viewport().get_camera_3d()
	var unit: Unit = _blue_units()[0]
	var screen := cam.unproject_position(unit.global_position + Vector3.UP * 0.7)

	# Click-select via real input events.
	_mouse(MOUSE_BUTTON_LEFT, screen, true)
	_mouse(MOUSE_BUTTON_LEFT, screen, false)
	if main.selected.size() != 1:
		return _fail("click-select picked %d units, expected 1" % main.selected.size())

	# Drag-box across the whole screen selects every blue unit.
	_mouse(MOUSE_BUTTON_LEFT, Vector2(2, 2), true)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(1270, 710)
	main._unhandled_input(motion)
	_mouse(MOUSE_BUTTON_LEFT, Vector2(1270, 710), false)
	if main.selected.size() != _blue_units().size():
		return _fail("box-select got %d of %d units" % [main.selected.size(), _blue_units().size()])

	# Right-click the ground issues a move order.
	var ground := cam.unproject_position(Vector3(18, 0, 17))
	_mouse(MOUSE_BUTTON_RIGHT, ground, true)
	if not main.selected.all(func(u): return u.has_move_target):
		return _fail("right-click move order not applied")
	print("selection/orders OK: click, box (%d), move" % main.selected.size())
	_next()


func _test_camera() -> void:
	var rig := main.get_node("CameraRig")
	var before: Vector3 = rig.camera.position
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	rig._unhandled_input(wheel)
	if not rig.camera.position.y > before.y:
		return _fail("zoom out did not raise the camera")
	print("camera zoom OK")
	_next()


func _build_first_tier() -> void:
	if not _place("watchtower", Vector3(24, 0, 18)):
		return
	if not _place("archery_range", Vector3(16, 0, 18)):
		return
	print("tier 1 OK: watchtower + archery range placed")
	_next()


func _test_tower_upgrades_before_workshop() -> void:
	var tower := _find_building(Tower) as Tower
	var cam := root.get_viewport().get_camera_3d()
	_mouse(MOUSE_BUTTON_LEFT, cam.unproject_position(tower.global_position + Vector3.UP * 1.5), true)
	_mouse(MOUSE_BUTTON_LEFT, cam.unproject_position(tower.global_position + Vector3.UP * 1.5), false)
	if main._selected_tower != tower or not main.get_node("HUD/UpgradePanel").visible:
		return _fail("clicking the tower did not open the upgrade panel")
	main.get_node("HUD/UpgradePanel/VBox/UpgradeButton").pressed.emit()
	if tower.level != 2:
		return _fail("first upgrade failed, level %d" % tower.level)
	main.get_node("HUD/UpgradePanel/VBox/UpgradeButton").pressed.emit()
	if tower.level != 2:
		return _fail("tower reached Lv3 without a Workshop")
	print("tower OK: Lv2 bought, Lv3 correctly gated")
	_next()


func _build_second_tier() -> void:
	if not _place("barracks", Vector3(20, 0, 16)):
		return
	if not _place("workshop", Vector3(24, 0, 24)):
		return
	print("tier 2 OK: barracks + workshop placed")
	_next()


func _test_tower_upgrade_after_workshop() -> void:
	var tower := main._selected_tower as Tower
	if tower == null:
		return _fail("tower selection lost after building")
	main.get_node("HUD/UpgradePanel/VBox/UpgradeButton").pressed.emit()
	if tower.level != 3:
		return _fail("Lv3 upgrade still blocked after Workshop")
	print("tower OK: Lv3 %s after Workshop" % tower.level_name())
	_next()


func _test_totem_gate_and_victory() -> void:
	var totem_button: Button = main.get_node("HUD/BuildBar/TotemButton")
	if not totem_button.disabled:
		return _fail("Grand Totem available without gems")
	for i in 3:
		state.collect_gem()
	if totem_button.disabled:
		return _fail("Grand Totem still locked with Workshop + 3 gems")
	totem_button.pressed.emit()
	if not _place_current(Vector3(15, 0, 25)):
		return
	_next()


func _check_victory() -> void:
	var msg: Label = main.get_node("HUD/CenterMessage")
	if not msg.visible or not msg.text.begins_with("Victory"):
		return _fail("no victory message after raising the totem (got '%s')" % msg.text)
	print("victory OK: '%s'" % msg.text)
	main.get_node("HUD/RestartButton").pressed.emit()
	_next(10)


func _check_restart() -> void:
	var fresh := current_scene
	if fresh == null or fresh.get_instance_id() == main_id or fresh.name != "Main":
		return  # Reload still in progress.
	if state.gems != 0 or _blue_units().size() != 3:
		return _fail("restart did not reset the game")
	print("SMOKE TEST PASS: full playthrough, victory, and restart")
	quit(0)


# --- Helpers ----------------------------------------------------------------

func _place(id: String, pos: Vector3) -> bool:
	main.get_node("HUD")._buttons[id].pressed.emit()
	return _place_current(pos)


func _place_current(pos: Vector3) -> bool:
	var id: String = main._placing
	if id == "":
		_fail("build button did not enter placement mode")
		return false
	if not main._placement_valid(pos):
		_fail("placement of %s at %s rejected" % [id, pos])
		return false
	var before: int = main._built_counts.get(id, 0)
	main._place_building(pos)
	if main._built_counts.get(id, 0) != before + 1:
		_fail("%s was not registered after placing" % id)
		return false
	return true


func _mouse(button: MouseButton, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.position = pos
	ev.pressed = pressed
	main._unhandled_input(ev)


func _blue_units() -> Array:
	return get_nodes_in_group("units").filter(func(u): return u.team == 0)


func _find_building(type: Variant) -> Node:
	for b in get_nodes_in_group("buildings"):
		if is_instance_of(b, type) and b.team == 0:
			return b
	return null


func _fail(message: String) -> void:
	print("SMOKE TEST FAIL: ", message)
	quit(1)
