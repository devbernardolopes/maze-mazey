@tool
class_name Box
extends Area2D

@export var data: BoxData = null:
	set(v):
		data = v
		_refresh_visual()

var visual: AnimatedSprite2D = null
var collision: CollisionShape2D = null
var is_moving: bool = false

var _tween: Tween = null


func _ready() -> void:
	visual = AnimatedSprite2D.new()
	add_child(visual)
	collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	(collision.shape as RectangleShape2D).size = Vector2.ONE * Helper.TILE_SIZE
	collision_layer = Helper.BOXES
	collision_mask = Helper.ENTITIES | Helper.WALLS | Helper.BOXES
	add_child(collision)
	_refresh_visual()


## True when the adjacent cell in `direction` holds neither a wall, an
## entity nor another box (and this box is not already sliding).
func can_move(direction: Vector2) -> bool:
	if is_moving:
		return false
	var destination: Vector2 = global_position + direction * Helper.TILE_SIZE
	return Helper.get_grid_occupant(destination, get_rid()) == null


## Slides exactly one tile in `direction` over `duration` seconds.
## The caller must have validated the move with `can_move` (for chains, every
## box in the chain must pass before any of them start).
func start_move(direction: Vector2, duration: float) -> void:
	start_move_to(global_position + direction * Helper.TILE_SIZE, duration)


## Slides to an exact destination cell over `duration` seconds. Used by swaps,
## where the box travels more than one tile.
func start_move_to(destination: Vector2, duration: float) -> void:
	if is_moving:
		return
	is_moving = true
	_tween = create_tween()
	_tween.tween_property(self, "global_position", destination, duration)
	_tween.tween_callback(_on_move_finished)


func _on_move_finished() -> void:
	is_moving = false
	_tween = null


func _refresh_visual() -> void:
	if not data:
		return
	if not data.visual:
		return
	if not visual:
		return
	visual.sprite_frames = data.visual
	visual.self_modulate = data.color
