class_name Unit
extends CharacterBody3D
## A single soldier. Handles movement orders, auto-aggro, melee combat,
## selection highlight, and its own health bar.

signal died(unit: Unit)

@export var team := 0
@export var move_speed := 3.5
@export var max_health := 100.0
@export var attack_damage := 12.0
@export var attack_range := 1.5
@export var attack_cooldown := 1.0
@export var aggro_radius := 5.0

var health: float
var selected := false
var move_target := Vector3.ZERO
var has_move_target := false
var attack_target: Unit = null

var _cooldown := 0.0
var _anim: AnimationPlayer = null


func _ready() -> void:
	health = max_health
	add_to_group("units")
	var model := get_node_or_null("Model")
	if model:
		var players := model.find_children("*", "AnimationPlayer", true, false)
		if not players.is_empty():
			_anim = players[0]
	_play("idle")


func _physics_process(delta: float) -> void:
	if health <= 0.0:
		return
	_cooldown = maxf(0.0, _cooldown - delta)

	if attack_target and (not is_instance_valid(attack_target) or attack_target.health <= 0.0):
		attack_target = null

	if attack_target:
		var offset := attack_target.global_position - global_position
		offset.y = 0.0
		if offset.length() > attack_range:
			_step_toward(attack_target.global_position)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			_face(attack_target.global_position)
			if _cooldown == 0.0:
				_cooldown = attack_cooldown
				_play("attack-melee-right")
				attack_target.take_damage(attack_damage)
	elif has_move_target:
		var offset := move_target - global_position
		offset.y = 0.0
		if offset.length() < 0.25:
			has_move_target = false
			velocity.x = 0.0
			velocity.z = 0.0
			_play("idle")
		else:
			_step_toward(move_target)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= 20.0 * delta
	move_and_slide()


func command_move(pos: Vector3) -> void:
	attack_target = null
	move_target = pos
	has_move_target = true


func command_attack(target: Unit) -> void:
	has_move_target = false
	attack_target = target


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	_update_health_bar()
	if health <= 0.0:
		remove_from_group("units")
		died.emit(self)
		queue_free()


func set_selected(value: bool) -> void:
	selected = value
	$SelectionRing.visible = value


func _step_toward(pos: Vector3) -> void:
	var direction := pos - global_position
	direction.y = 0.0
	direction = direction.normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	_face(pos)
	_play("walk")


func _face(pos: Vector3) -> void:
	var direction := pos - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.001:
		rotation.y = atan2(direction.x, direction.z)


func _play(anim_name: String) -> void:
	if _anim == null or not _anim.has_animation(anim_name):
		return
	# Let a started attack swing finish before switching clips.
	if _anim.current_animation.begins_with("attack") and _anim.is_playing() and not anim_name.begins_with("attack"):
		return
	if _anim.current_animation != anim_name:
		_anim.play(anim_name)


func _update_health_bar() -> void:
	$HealthBar/FillPivot.scale.x = clampf(health / max_health, 0.0, 1.0)


func _on_scan_timer_timeout() -> void:
	# Auto-aggro: idle units pick the nearest enemy in range.
	if attack_target != null or has_move_target:
		return
	var nearest: Unit = null
	var nearest_dist := aggro_radius
	for other: Unit in get_tree().get_nodes_in_group("units"):
		if other.team == team or not is_instance_valid(other):
			continue
		var dist := global_position.distance_to(other.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = other
	if nearest:
		attack_target = nearest
