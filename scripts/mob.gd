extends RigidBody2D
## A creep. Picks a random animation on spawn and frees itself
## once it drifts off screen.


func _ready() -> void:
	var types: PackedStringArray = $AnimatedSprite2D.sprite_frames.get_animation_names()
	$AnimatedSprite2D.play(types[randi() % types.size()])


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
