extends Area2D
## The player: moves with the arrow keys, clamped to the screen.
## Emits [signal hit] when a mob touches it.

signal hit

@export var speed := 400.0

var screen_size: Vector2


func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()


func _process(delta: float) -> void:
	var velocity := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * speed

	if velocity.length() > 0:
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0


func start(pos: Vector2) -> void:
	position = pos
	show()
	$CollisionShape2D.disabled = false


func _on_body_entered(_body: Node2D) -> void:
	hide()
	hit.emit()
	# Deferred so we don't change physics state during a collision callback.
	$CollisionShape2D.set_deferred("disabled", true)
