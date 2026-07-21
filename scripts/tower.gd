class_name Tower
extends Destructible
## Defensive building: automatically shoots the nearest enemy unit in range.
## Upgradeable in place through three tiers, each boosting damage, range,
## and fire rate. The highest tier is gated behind the Workshop (enforced by
## main.gd, which owns the tech state).

const LEVELS := [
	{"name": "Arrow", "damage": 10.0, "range": 7.0, "cooldown": 1.2, "scale": 1.5, "accent": Color(0.45, 0.7, 1.0)},
	{"name": "Reinforced", "damage": 17.0, "range": 8.5, "cooldown": 1.0, "scale": 1.6, "accent": Color(0.4, 1.0, 0.55)},
	{"name": "Ballista", "damage": 26.0, "range": 10.0, "cooldown": 0.8, "scale": 1.7, "accent": Color(1.0, 0.82, 0.3)},
]
const MAX_LEVEL := 3

var level := 1
var attack_range := 7.0
var attack_damage := 10.0


func _setup() -> void:
	_apply_level()
	$AttackTimer.start()


func level_name() -> String:
	return LEVELS[level - 1]["name"]


func can_upgrade() -> bool:
	return level < MAX_LEVEL


func upgrade() -> bool:
	if not can_upgrade():
		return false
	level += 1
	_apply_level()
	return true


func set_selected(value: bool) -> void:
	var ring := get_node_or_null("SelectionRing")
	if ring:
		ring.visible = value


func _apply_level() -> void:
	var data: Dictionary = LEVELS[level - 1]
	attack_damage = data["damage"]
	attack_range = data["range"]
	$AttackTimer.wait_time = data["cooldown"]
	var model := get_node_or_null("Model")
	if model:
		model.scale = Vector3.ONE * float(data["scale"])
	var accent := get_node_or_null("Accent")
	if accent:
		accent.visible = level > 1
		var mat := accent.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = data["accent"]


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
