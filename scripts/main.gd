extends Node
## Game loop: spawns mobs by cloning mob.tscn, tracks the score,
## and restarts on demand.

@export var mob_scene: PackedScene

var score := 0


func new_game() -> void:
	score = 0
	get_tree().call_group("mobs", "queue_free")
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready!")


func game_over() -> void:
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()


func _on_score_timer_timeout() -> void:
	score += 1
	$HUD.update_score(score)


func _on_mob_timer_timeout() -> void:
	# Clone the mob scene rather than building nodes in code.
	var mob: RigidBody2D = mob_scene.instantiate()

	# Pick a random point along the path that rings the screen edge.
	var spawn: PathFollow2D = $MobPath/MobSpawnLocation
	spawn.progress_ratio = randf()
	mob.position = spawn.position

	# Aim roughly toward the middle of the screen, with some spread.
	var direction := spawn.rotation + PI / 2 + randf_range(-PI / 4, PI / 4)
	mob.rotation = direction
	mob.linear_velocity = Vector2(randf_range(150.0, 250.0), 0.0).rotated(direction)

	add_child(mob)
