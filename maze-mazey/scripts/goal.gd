@tool
class_name Goal
extends BaseScene

func _ready() -> void:
	visual = AnimatedSprite2D.new()
	add_child(visual)
	collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	(collision.shape as RectangleShape2D).size = Vector2.ONE * Helper.TILE_SIZE
	collision_layer = Helper.GOALS
	collision_mask = Helper.ENTITIES | Helper.BOXES
	add_child(collision)
	_refresh_visual()
