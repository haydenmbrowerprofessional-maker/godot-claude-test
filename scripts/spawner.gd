class_name Spawner
extends Destructible
## A building that produces units on a timer, capped at [member max_units]
## living units. A slot frees when one of this building's units dies.
## Used by the player's Hut and by enemy camps.

signal unit_spawned(unit: Unit)

@export var unit_scene: PackedScene
@export var max_units := 3
@export var spawn_interval := 6.0
## Where spawned units appear, relative to the building (global axes).
@export var rally_offset := Vector3(3, 0, 0)

var _alive_units: Array[Unit] = []


func _setup() -> void:
	$SpawnTimer.wait_time = spawn_interval
	$SpawnTimer.start()


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
