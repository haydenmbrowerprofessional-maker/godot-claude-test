extends Node3D
## Game root: spawns both armies by cloning the unit scenes, routes
## mouse input into selection and orders, and tracks win/lose.

@export var blue_unit_scene: PackedScene
@export var red_unit_scene: PackedScene
@export var units_per_team := 6

const RAY_LENGTH := 300.0
const LAYER_GROUND := 1
const LAYER_UNITS := 2
const CLICK_DRAG_THRESHOLD := 8.0

var selected: Array[Unit] = []
var _blue_alive := 0
var _red_alive := 0
var _drag_start := Vector2.ZERO
var _dragging := false
var _game_over := false


func _ready() -> void:
	_spawn_army(blue_unit_scene, 0, Vector3(0, 0.1, 12))
	_spawn_army(red_unit_scene, 1, Vector3(0, 0.1, -12))
	_update_hud()


func _spawn_army(scene: PackedScene, team: int, center: Vector3) -> void:
	for i in units_per_team:
		# Clone the team's unit scene rather than building nodes in code.
		var unit: Unit = scene.instantiate()
		var column := i % 3 - 1
		var row := floori(i / 3.0)
		unit.position = center + Vector3(column * 1.6, 0.0, row * 1.6 * signf(center.z))
		unit.died.connect(_on_unit_died)
		$Units.add_child(unit)
		if team == 0:
			_blue_alive += 1
		else:
			_red_alive += 1


func _unhandled_input(event: InputEvent) -> void:
	if _game_over:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag_start = event.position
				_dragging = true
			elif _dragging:
				_dragging = false
				$HUD.clear_drag()
				if _drag_start.distance_to(event.position) < CLICK_DRAG_THRESHOLD:
					_click_select(event.position, event.shift_pressed)
				else:
					_box_select(_drag_rect(event.position), event.shift_pressed)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_issue_order(event.position)
	elif event is InputEventMouseMotion and _dragging:
		$HUD.set_drag_rect(_drag_rect(event.position))


func _drag_rect(current: Vector2) -> Rect2:
	return Rect2(_drag_start, current - _drag_start).abs()


func _click_select(screen_pos: Vector2, additive: bool) -> void:
	var hit := _raycast(screen_pos, LAYER_UNITS)
	if not additive:
		_clear_selection()
	var unit := hit.get("collider") as Unit
	if unit and unit.team == 0:
		_add_to_selection(unit)
	_update_hud()


func _box_select(rect: Rect2, additive: bool) -> void:
	if not additive:
		_clear_selection()
	var camera := get_viewport().get_camera_3d()
	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit.team != 0 or not is_instance_valid(unit):
			continue
		if camera.is_position_behind(unit.global_position):
			continue
		if rect.has_point(camera.unproject_position(unit.global_position + Vector3.UP * 0.7)):
			_add_to_selection(unit)
	_update_hud()


func _issue_order(screen_pos: Vector2) -> void:
	if selected.is_empty():
		return
	selected = selected.filter(is_instance_valid)
	var hit := _raycast(screen_pos, LAYER_GROUND | LAYER_UNITS)
	if hit.is_empty():
		return
	var target := hit.get("collider") as Unit
	if target and target.team != 0:
		for unit in selected:
			unit.command_attack(target)
	else:
		var point: Vector3 = hit["position"] if target == null else target.global_position
		# Spread destinations into a small grid so units don't stack.
		for i in selected.size():
			var offset := Vector3((i % 3 - 1) * 1.1, 0.0, floori(i / 3.0) * 1.1)
			selected[i].command_move(point + offset)
	_update_hud()


func _raycast(screen_pos: Vector2, mask: int) -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	var origin := camera.project_ray_origin(screen_pos)
	var target := origin + camera.project_ray_normal(screen_pos) * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(origin, target, mask)
	return get_world_3d().direct_space_state.intersect_ray(query)


func _add_to_selection(unit: Unit) -> void:
	if unit in selected:
		return
	selected.append(unit)
	unit.set_selected(true)


func _clear_selection() -> void:
	for unit in selected:
		if is_instance_valid(unit):
			unit.set_selected(false)
	selected.clear()


func _on_unit_died(unit: Unit) -> void:
	if unit.team == 0:
		_blue_alive -= 1
	else:
		_red_alive -= 1
	selected.erase(unit)
	_update_hud()
	if _red_alive == 0:
		_end_game("Victory!")
	elif _blue_alive == 0:
		_end_game("Defeat")


func _end_game(message: String) -> void:
	_game_over = true
	_clear_selection()
	$HUD.show_end(message)


func _update_hud() -> void:
	$HUD.set_selected_count(selected.size())
