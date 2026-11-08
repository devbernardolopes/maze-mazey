@tool
class_name Goal
extends Area2D

@export var data: GoalData = null:
	set(v):
		data = v
		_refresh_visual()

var visual: AnimatedSprite2D = null
var collision: CollisionShape2D = null


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


func _refresh_visual() -> void:
	if not data:
		return
	if not data.visual:
		return
	if not visual:
		return
	visual.sprite_frames = data.visual
	visual.self_modulate = data.color
