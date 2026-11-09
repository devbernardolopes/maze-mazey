@tool
class_name Box
extends Area2D

@export var data: BoxData = null:
	set(v):
		data = v
		_refresh_visual()

var visual: AnimatedSprite2D = null
var collision: CollisionShape2D = null
var occluder: LightOccluder2D = null
var is_moving: bool = false
var _move_target: Vector2 = Vector2.ZERO
var _move_speed_px: float = 0.0


func _ready() -> void:
	visual = AnimatedSprite2D.new()
	add_child(visual)
	collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	(collision.shape as RectangleShape2D).size = Vector2.ONE * Helper.TILE_SIZE
	collision_layer = Helper.BOXES
	collision_mask = Helper.ENTITIES | Helper.WALLS | Helper.BOXES
	add_child(collision)
	occluder = LightOccluder2D.new()
	occluder.occluder = OccluderPolygon2D.new()
	occluder.occluder.cull_mode = OccluderPolygon2D.CULL_COUNTER_CLOCKWISE
	occluder.occluder.polygon = [ 
			Vector2.ZERO - Helper.TILE_HALF_SIZE, 
			Vector2(Helper.TILE_HALF_LENGTH, Helper.TILE_HALF_LENGTH * -1.0), 
			Vector2.ONE * Helper.TILE_HALF_SIZE, 
			Vector2(Helper.TILE_HALF_LENGTH * -1.0, Helper.TILE_HALF_LENGTH), 
			]
	add_child(occluder)
	_refresh_visual()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not is_moving:
		return
	# Same physics-clock integration as Entity, so pushed boxes stay in
	# lockstep with the entity pushing them.
	var remaining: Vector2 = _move_target - global_position
	var step: float = _move_speed_px * delta
	if remaining.length() <= step:
		global_position = _move_target
		is_moving = false
		return
	global_position += remaining.normalized() * step


## True when the adjacent cell in `direction` holds neither a wall, an
## entity nor another box (and this box is not already sliding).
func can_move(direction: Vector2) -> bool:
	if is_moving:
		return false
	var destination: Vector2 = global_position + direction * Helper.TILE_SIZE
	return Helper.get_grid_occupant(destination, get_rid()) == null


## Slides exactly one tile in `direction` at `speed_px` pixels per second.
## The caller must have validated the move with `can_move` (for chains, every
## box in the chain must pass before any of them start).
func start_move(direction: Vector2, speed_px: float) -> void:
	is_moving = true
	_move_target = global_position + direction * Helper.TILE_SIZE
	_move_speed_px = speed_px


## Instantly repositions the box, cancelling any pending move. Used for swaps,
## which are a single instant teleport rather than a slide.
func teleport_to(destination: Vector2) -> void:
	global_position = destination
	is_moving = false
	_move_target = Vector2.ZERO
	_move_speed_px = 0.0


func _refresh_visual() -> void:
	if not data:
		return
	if not data.visual:
		return
	if not visual:
		return
	visual.sprite_frames = data.visual
	visual.self_modulate = data.color
