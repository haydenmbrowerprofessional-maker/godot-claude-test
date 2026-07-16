extends Node3D
## RTS camera: WASD/arrow panning, mouse-wheel zoom.
## The rig sits at ground level; the camera hangs above and behind it.

@export var pan_speed := 14.0
@export var map_limit := 18.0

const ZOOM_NEAR := Vector3(0, 7, 4.5)
const ZOOM_FAR := Vector3(0, 24, 15)

var _zoom := 0.5

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	_apply_zoom()


func _process(delta: float) -> void:
	var input := Input.get_vector("camera_left", "camera_right", "camera_forward", "camera_back")
	if input != Vector2.ZERO:
		position += Vector3(input.x, 0.0, input.y) * pan_speed * (0.5 + _zoom) * delta
		position.x = clampf(position.x, -map_limit, map_limit)
		position.z = clampf(position.z, -map_limit, map_limit)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = maxf(0.0, _zoom - 0.1)
			_apply_zoom()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = minf(1.0, _zoom + 0.1)
			_apply_zoom()


func _apply_zoom() -> void:
	camera.position = ZOOM_NEAR.lerp(ZOOM_FAR, _zoom)
	camera.look_at(global_position)
