@tool
class_name Box
extends BaseScene

var is_moving: bool = false
var _move_target: Vector2 = Vector2.ZERO
var _move_speed_px: float = 0.0


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
