extends Node3D
## Game root: exploration map with fog of war, building placement with a
## tech tree, enemy camps, and hidden gems. Win by building the Grand Totem;
## lose if every friendly unit and building is gone.

const GHOST_SCENE := preload("res://scenes/ghost.tscn")
const BUILDINGS := {
	"hut": {"scene": preload("res://scenes/buildings/hut.tscn"), "spacing": 2.8},
	"archery_range": {"scene": preload("res://scenes/buildings/archery_range.tscn"), "spacing": 2.8},
	"watchtower": {"scene": preload("res://scenes/buildings/watchtower.tscn"), "spacing": 3.0},
	"barracks": {"scene": preload("res://scenes/buildings/barracks.tscn"), "spacing": 3.0},
	"workshop": {"scene": preload("res://scenes/buildings/workshop.tscn"), "spacing": 3.0},
	"grand_totem": {"scene": preload("res://scenes/buildings/grand_totem.tscn"), "spacing": 3.2},
}

const RAY_LENGTH := 300.0
const LAYER_GROUND := 1
const LAYER_UNITS := 2
const CLICK_DRAG_THRESHOLD := 8.0
const GEMS_NEEDED := 3
const BUILD_LIMIT := 27.0

@export var starter_unit_scene: PackedScene
@export var starter_units := 3
@export var base_center := Vector3(20, 0.1, 20)

var selected: Array[Unit] = []
var _selected_tower: Tower = null
var _built_counts := {}
var _blue_units := 0
var _blue_buildings := 0
var _camps_left := 0
var _placing := ""
var _ghost: Node3D = null
var _drag_start := Vector2.ZERO
var _dragging := false
var _game_over := false


func _ready() -> void:
	var state := get_node_or_null("/root/GameState")
	if state:
		state.reset()
		state.gems_changed.connect(func(_count):
			_update_objectives()
			_update_build_bar())
		state.totem_built.connect(func(): _end_game("Victory! The Grand Totem stands."))
	$HUD.build_requested.connect(_on_build_requested)
	$HUD.upgrade_requested.connect(_on_upgrade_requested)
	for building in $Buildings.get_children():
		_register_building(building)
	for i in starter_units:
		var unit: Unit = starter_unit_scene.instantiate()
		unit.position = base_center + Vector3((i - 1) * 1.5, 0.0, 2.5)
		_register_unit(unit)
	_update_build_bar()
	_update_objectives()
	_update_hud()


func _process(_delta: float) -> void:
	if _placing == "" or _ghost == null:
		return
	var hit := _raycast(get_viewport().get_mouse_position(), LAYER_GROUND)
	if hit.is_empty():
		_ghost.visible = false
		return
	_ghost.visible = true
	var pos: Vector3 = hit["position"]
	_ghost.position = Vector3(pos.x, 0.06, pos.z)
	_ghost.set_valid(_placement_valid(pos))


# --- Registration -----------------------------------------------------------

func _register_unit(unit: Unit) -> void:
	unit.died.connect(_on_unit_died)
	$Units.add_child(unit)
	if unit.team == 0:
		_blue_units += 1


func _register_building(building: Destructible) -> void:
	building.died.connect(_on_building_died)
	if building is Spawner:
		building.unit_spawned.connect(_register_unit)
	if building.team == 0:
		_blue_buildings += 1
		var id := _building_id(building)
		if id != "":
			_built_counts[id] = _built_counts.get(id, 0) + 1
	else:
		_camps_left += 1


func _building_id(building: Destructible) -> String:
	for id in BUILDINGS:
		if building.scene_file_path == BUILDINGS[id].scene.resource_path:
			return id
	return ""


# --- Building placement -----------------------------------------------------

func _on_build_requested(id: String) -> void:
	if _game_over:
		return
	_cancel_placement()
	_placing = id
	_ghost = GHOST_SCENE.instantiate()
	add_child(_ghost)


func _placement_valid(pos: Vector3) -> bool:
	if absf(pos.x) > BUILD_LIMIT or absf(pos.z) > BUILD_LIMIT:
		return false
	if not $FogOfWar.is_revealed(pos):
		return false
	var spacing: float = BUILDINGS[_placing].spacing
	for building in get_tree().get_nodes_in_group("buildings"):
		var d: Vector3 = building.global_position - pos
		d.y = 0.0
		if d.length() < spacing + building.radius:
			return false
	return true


func _place_building(pos: Vector3) -> void:
	# Clone the building's scene; scripts never assemble buildings node-by-node.
	var building: Destructible = BUILDINGS[_placing].scene.instantiate()
	building.position = Vector3(pos.x, 0.0, pos.z)
	$Buildings.add_child(building)
	_register_building(building)
	_cancel_placement()
	_update_build_bar()
	_update_objectives()
	# A new Workshop may unlock the top tower tier for a selected tower.
	if is_instance_valid(_selected_tower):
		_refresh_upgrade_panel()


func _cancel_placement() -> void:
	_placing = ""
	if _ghost:
		_ghost.queue_free()
		_ghost = null


# --- Input ------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _game_over:
		return

	if _placing != "":
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var hit := _raycast(event.position, LAYER_GROUND)
				if not hit.is_empty() and _placement_valid(hit["position"]):
					_place_building(hit["position"])
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_cancel_placement()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_cancel_placement()
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


# --- Selection and orders ---------------------------------------------------

func _click_select(screen_pos: Vector2, additive: bool) -> void:
	var collider: Object = _raycast(screen_pos, LAYER_UNITS).get("collider")
	# A friendly tower opens the upgrade panel instead of joining a squad.
	if collider is Tower and collider.team == 0:
		_clear_selection()
		_select_tower(collider)
		_update_hud()
		return
	_deselect_tower()
	if not additive:
		_clear_selection()
	var unit := collider as Unit
	if unit and unit.team == 0:
		_add_to_selection(unit)
	_update_hud()


func _box_select(rect: Rect2, additive: bool) -> void:
	_deselect_tower()
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
	var collider: Object = hit.get("collider")
	var is_target := collider is Unit or collider is Destructible
	if is_target and collider.team != 0:
		for unit in selected:
			unit.command_attack(collider)
	else:
		var point: Vector3 = hit["position"]
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


# --- Tower selection and upgrades -------------------------------------------

func _select_tower(tower: Tower) -> void:
	_deselect_tower()
	_selected_tower = tower
	tower.set_selected(true)
	_refresh_upgrade_panel()


func _deselect_tower() -> void:
	if is_instance_valid(_selected_tower):
		_selected_tower.set_selected(false)
	_selected_tower = null
	$HUD.hide_upgrade()


func _refresh_upgrade_panel() -> void:
	var t := _selected_tower
	if not is_instance_valid(t):
		return
	var info := "%s Tower — Lv %d\nDamage %d · Range %d" % [
		t.level_name(), t.level, int(t.attack_damage), int(t.attack_range)]
	if not t.can_upgrade():
		$HUD.show_upgrade(info + "\n(max level)", "Maxed", false)
	elif not _upgrade_allowed(t):
		$HUD.show_upgrade(info + "\nNext tier needs a Workshop", "Upgrade", false)
	else:
		var next_name: String = Tower.LEVELS[t.level]["name"]
		$HUD.show_upgrade(info, "Upgrade → %s" % next_name, true)


func _upgrade_allowed(t: Tower) -> bool:
	# The top tier (Lv2 → Lv3) is gated behind the Workshop.
	if t.level >= 2:
		return _built_counts.get("workshop", 0) > 0
	return true


func _on_upgrade_requested() -> void:
	var t := _selected_tower
	if is_instance_valid(t) and t.can_upgrade() and _upgrade_allowed(t):
		t.upgrade()
		_refresh_upgrade_panel()


# --- Progression ------------------------------------------------------------

func _on_unit_died(unit: Unit) -> void:
	if unit.team == 0:
		_blue_units -= 1
	selected.erase(unit)
	_update_hud()
	_check_end()


func _on_building_died(building: Destructible) -> void:
	if building.team == 0:
		_blue_buildings -= 1
		var id := _building_id(building)
		if id != "":
			_built_counts[id] = _built_counts.get(id, 1) - 1
	else:
		_camps_left -= 1
	if building == _selected_tower:
		_deselect_tower()
	elif is_instance_valid(_selected_tower):
		# Losing a Workshop can re-lock the top tower tier.
		_refresh_upgrade_panel()
	_update_build_bar()
	_update_objectives()
	_check_end()


func _gems() -> int:
	var state := get_node_or_null("/root/GameState")
	return state.gems if state else 0


func _update_build_bar() -> void:
	var have_hut: bool = _built_counts.get("hut", 0) > 0
	var have_tower: bool = _built_counts.get("watchtower", 0) > 0
	var have_workshop: bool = _built_counts.get("workshop", 0) > 0
	$HUD.set_build_state("hut", true,
		"Trains Soldiers — balanced melee (max 3 alive).")
	$HUD.set_build_state("archery_range", have_hut,
		"Trains Archers — ranged, fragile." if have_hut else "Requires a Hut.")
	$HUD.set_build_state("watchtower", have_hut,
		"Shoots nearby enemies; upgradeable." if have_hut else "Requires a Hut.")
	$HUD.set_build_state("barracks", have_tower,
		"Trains Knights — tanky, hard-hitting." if have_tower else "Requires a Watchtower.")
	$HUD.set_build_state("workshop", have_tower,
		"+30% unit damage; unlocks top tower tier." if have_tower else "Requires a Watchtower.")
	$HUD.set_build_state("grand_totem", have_workshop and _gems() >= GEMS_NEEDED,
		"Build to win the game!" if have_workshop and _gems() >= GEMS_NEEDED
		else "Requires a Workshop and %d gems." % GEMS_NEEDED)


func _update_objectives() -> void:
	$HUD.set_objectives("Gems: %d/%d    Camps left: %d" % [_gems(), GEMS_NEEDED, _camps_left])


func _check_end() -> void:
	if _game_over:
		return
	if _blue_units <= 0 and _blue_buildings <= 0:
		_end_game("Defeat — your tribe is lost.")


func _end_game(message: String) -> void:
	_game_over = true
	_cancel_placement()
	_clear_selection()
	_deselect_tower()
	$HUD.show_end(message)


func _update_hud() -> void:
	$HUD.set_selected_count(selected.size())
