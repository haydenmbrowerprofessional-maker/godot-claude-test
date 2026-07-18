class_name Destructible
extends StaticBody3D
## Base for every building: team, health, health bar, footprint radius.
## Subclasses add behavior in _setup().

signal died(building: Destructible)

@export var team := 0
@export var max_health := 300.0
## Footprint radius; attackers add this to their melee reach.
@export var radius := 1.0
## How far this building lifts the fog.
@export var vision_radius := 8.0

var health: float


func _ready() -> void:
	health = max_health
	add_to_group("buildings")
	_setup()


func _setup() -> void:
	pass


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	$HealthBar/FillPivot.scale.x = clampf(health / max_health, 0.0, 1.0)
	if health <= 0.0:
		remove_from_group("buildings")
		died.emit(self)
		queue_free()
