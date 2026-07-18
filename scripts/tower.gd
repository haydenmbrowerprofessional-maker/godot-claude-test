class_name Tower
extends Destructible
## Defensive building: automatically shoots the nearest enemy unit in range.


@export var attack_range := 7.0
@export var attack_damage := 10.0


func _setup() -> void:
	$AttackTimer.start()


func _on_attack_timer_timeout() -> void:
	if health <= 0.0:
		return
	var nearest: Unit = null
	var nearest_dist := attack_range
	for other: Unit in get_tree().get_nodes_in_group("units"):
		if other.team == team or not is_instance_valid(other) or other.health <= 0.0:
			continue
		var dist := global_position.distance_to(other.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = other
	if nearest:
		nearest.take_damage(attack_damage)
