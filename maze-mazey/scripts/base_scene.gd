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
	visual = Static.find_control(self, "AnimatedSprite2D")
	if not visual:
		visual = AnimatedSprite2D.new()
		add_child(visual)
	collision = Static.find_control(self, "CollisionShape2D")
	if not collision:
		collision = CollisionShape2D.new()
		collision.shape = RectangleShape2D.new()
		(collision.shape as RectangleShape2D).size = Vector2.ONE * Helper.TILE_SIZE
		add_child(collision)
	occluder = Static.find_control(self, "LightOccluder2D")
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


func _refresh_visual() -> void:
	if not data:
		return
	if not data.visual:
		return
	if not visual:
		return
	visual.sprite_frames = data.visual
	visual.self_modulate = data.color
