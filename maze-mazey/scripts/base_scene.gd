@tool
class_name BaseScene
extends Area2D

@export var data: BaseResource = null:
	set(v):
		data = v
		_refresh_visual()

#@export_flags_2d_physics var physics_collision_layer: int
#@export_flags_2d_physics var physics_collision_mask: int

var visual: AnimatedSprite2D = null
var collision: CollisionShape2D = null
var occluder: LightOccluder2D = null


func _ready() -> void:
	visual = _find_visual()
	if not visual:
		visual = AnimatedSprite2D.new()
		add_child(visual)
	collision = _find_collision()
	if not collision:
		collision = CollisionShape2D.new()
		collision.shape = RectangleShape2D.new()
		(collision.shape as RectangleShape2D).size = Vector2.ONE * Helper.TILE_SIZE
		add_child(collision)
	occluder = _find_occluder()
	if not occluder:
		occluder = LightOccluder2D.new()
		occluder.occluder = OccluderPolygon2D.new()
		occluder.occluder.polygon = [ 
				Vector2.ZERO - Helper.TILE_HALF_SIZE, 
				Vector2(Helper.TILE_HALF_LENGTH, Helper.TILE_HALF_LENGTH * -1.0), 
				Vector2.ONE * Helper.TILE_HALF_SIZE, 
				Vector2(Helper.TILE_HALF_LENGTH * -1.0, Helper.TILE_HALF_LENGTH), 
				]
		add_child(occluder)
	occluder.show_behind_parent = true
	occluder.occluder.cull_mode = OccluderPolygon2D.CULL_COUNTER_CLOCKWISE
	_refresh_visual()


func _find_visual() -> AnimatedSprite2D:
	for child: Node in get_children():
		if child is AnimatedSprite2D:
			return child as AnimatedSprite2D
	return null


func _find_collision() -> CollisionShape2D:
	for child: Node in get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null


func _find_occluder() -> LightOccluder2D:
	for child: Node in get_children():
		if child is LightOccluder2D:
			return child as LightOccluder2D
	return null


func _refresh_visual() -> void:
	if not data:
		return
	if not data.visual:
		return
	if not visual:
		return
	visual.sprite_frames = data.visual
	visual.self_modulate = data.color
