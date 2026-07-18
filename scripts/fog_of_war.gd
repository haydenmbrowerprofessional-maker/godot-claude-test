class_name FogOfWar
extends MeshInstance3D
## Totem Tribe-style exploration fog: the map starts dark and is revealed
## permanently around friendly units and buildings. A dark plane hangs above
## the map; its shader samples a reveal mask that this script paints into.
## Enemy units and buildings are hidden until their spot is revealed.

## World-space width the fog plane (and mask) covers, centered on origin.
@export var world_size := 90.0

const RES := 160

var _img: Image
var _tex: ImageTexture
var _dirty := false


func _ready() -> void:
	_img = Image.create(RES, RES, false, Image.FORMAT_R8)
	_tex = ImageTexture.create_from_image(_img)
	var mat := material_override as ShaderMaterial
	mat.set_shader_parameter("mask", _tex)


func reveal_circle(world_pos: Vector3, reveal_radius: float) -> void:
	var cx := int((world_pos.x / world_size + 0.5) * RES)
	var cy := int((world_pos.z / world_size + 0.5) * RES)
	var pr := int(reveal_radius / world_size * RES) + 1
	for y in range(maxi(0, cy - pr), mini(RES, cy + pr + 1)):
		for x in range(maxi(0, cx - pr), mini(RES, cx + pr + 1)):
			if Vector2(x - cx, y - cy).length() <= pr and _img.get_pixel(x, y).r < 0.9:
				_img.set_pixel(x, y, Color.WHITE)
				_dirty = true


func is_revealed(world_pos: Vector3) -> bool:
	var x := clampi(int((world_pos.x / world_size + 0.5) * RES), 0, RES - 1)
	var y := clampi(int((world_pos.z / world_size + 0.5) * RES), 0, RES - 1)
	return _img.get_pixel(x, y).r > 0.5


func _on_tick_timeout() -> void:
	for node: Unit in get_tree().get_nodes_in_group("units"):
		if node.team == 0:
			reveal_circle(node.global_position, node.vision_radius)
		else:
			node.visible = is_revealed(node.global_position)
	for node: Destructible in get_tree().get_nodes_in_group("buildings"):
		if node.team == 0:
			reveal_circle(node.global_position, node.vision_radius)
		else:
			node.visible = is_revealed(node.global_position)
	if _dirty:
		_tex.update(_img)
		_dirty = false
