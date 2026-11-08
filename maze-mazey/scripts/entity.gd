@tool
class_name Entity
extends Area2D
## [member Entity] can be...

@export var data: EntityData = null:
	set(v):
		data = v
		_refresh_visual()

var controller: EntityController = null
var visual: AnimatedSprite2D = null
var collision: CollisionShape2D = null


func _ready() -> void:
	visual = AnimatedSprite2D.new()
	add_child(visual)
	collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	(collision.shape as RectangleShape2D).size = Vector2.ONE * Helper.TILE_SIZE
	collision_layer = Helper.ENTITIES
	collision_mask = Helper.ENTITIES | Helper.WALLS | Helper.BOXES
	add_child(collision)
	_refresh_visual()
	if not Engine.is_editor_hint():
		if controller == null:
			controller = _find_controller()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if controller:
		# TODO: This needs fixing because it is supposed to be a fixed length movement
		var movement: Vector2 = controller.get_move_vector()
		position += movement * delta


func _find_controller() -> EntityController:
	for child: Node in get_children():
		if child is EntityController:
			return child as EntityController
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
