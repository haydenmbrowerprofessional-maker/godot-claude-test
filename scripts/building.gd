class_name Building
extends StaticBody3D
## A production building: spawns units on a timer, capped at
## [member max_units] living units per building. A slot frees up when
## one of this building's units dies. Destructible.

signal died(building: Building)
signal unit_spawned(unit: Unit)

@export var team := 0
@export var unit_scene: PackedScene
@export var max_units := 3
@export var spawn_interval := 6.0
@export var max_health := 300.0
## Where spawned units appear, relative to the building (global axes).
@export var rally_offset := Vector3(3, 0, 0)
## Footprint radius; attackers add this to their melee reach.
@export var radius := 1.0

var health: float
var _alive_units: Array[Unit] = []


func _ready() -> void:
	health = max_health
	add_to_group("buildings")
	$SpawnTimer.wait_time = spawn_interval
	$SpawnTimer.start()


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	$HealthBar/FillPivot.scale.x = clampf(health / max_health, 0.0, 1.0)
	if health <= 0.0:
		remove_from_group("buildings")
		died.emit(self)
		queue_free()


func _on_spawn_timer_timeout() -> void:
	if health <= 0.0 or unit_scene == null:
		return
	_alive_units = _alive_units.filter(is_instance_valid)
	if _alive_units.size() >= max_units:
		return
	# Clone the unit scene; the game root parents it and wires signals.
	var unit: Unit = unit_scene.instantiate()
	var jitter := Vector3((_alive_units.size() - 1) * 0.9, 0.0, 0.0)
	unit.position = global_position + rally_offset + jitter
	unit.position.y = 0.1
	_alive_units.append(unit)
	unit.died.connect(_on_spawned_unit_died)
	unit_spawned.emit(unit)


func _on_spawned_unit_died(unit: Unit) -> void:
	_alive_units.erase(unit)
