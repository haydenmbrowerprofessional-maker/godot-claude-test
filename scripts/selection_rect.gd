extends Control
## Draws the drag-selection rectangle.

var _rect := Rect2()
var _active := false


func set_drag(rect: Rect2) -> void:
	_rect = rect
	_active = true
	queue_redraw()


func clear() -> void:
	_active = false
	queue_redraw()


func _draw() -> void:
	if _active:
		draw_rect(_rect, Color(0.4, 0.9, 0.5, 0.12), true)
		draw_rect(_rect, Color(0.4, 0.9, 0.5, 0.9), false, 2.0)
