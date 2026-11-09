@tool
class_name Entity
extends Area2D
## Grid-bound entity. Moves one tile at a time (see `Helper.TILE_SIZE`) at a
## constant speed (`EntityData.move_speed`, tiles/second) on the physics
## clock, chaining steps without a gap while input is held, and resolves box
## interactions through its `Helper.ABILITY` list.

## A buffered direction *change* is honoured on arrival only while it is
## fresher than this fraction of the current step's duration. Same-direction
## input is never latched: it is re-polled live on arrival, so a brief tap
## (released before arrival) moves exactly one tile.
const BUFFER_FRACTION: float = 0.5

@export var data: EntityData = null:
	set(v):
		data = v
		_refresh_visual()

var controller: EntityController = null
var visual: AnimatedSprite2D = null
var collision: CollisionShape2D = null
var occluder: LightOccluder2D = null
## Last attempted cardinal direction (kept when idle, for animation/camera).
var facing: Vector2 = Vector2.DOWN
var is_moving: bool = false

var _move_target: Vector2 = Vector2.ZERO
var _move_speed_px: float = 0.0
## Latest direction *change* pressed while a step is in progress, consumed on
## arrival if still fresh (see `BUFFER_FRACTION`).
var _queued_direction: Vector2 = Vector2.ZERO
var _queued_age_s: float = 0.0


func _ready() -> void:
	visual = AnimatedSprite2D.new()
	add_child(visual)
	collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	(collision.shape as RectangleShape2D).size = Vector2.ONE * Helper.TILE_SIZE
	collision_layer = Helper.ENTITIES
	collision_mask = Helper.ENTITIES | Helper.WALLS | Helper.BOXES
	add_child(collision)
	if not occluder:
		var _occluder: LightOccluder2D = _find_occluder()
		if not _occluder:
			occluder = LightOccluder2D.new()
			occluder.occluder = OccluderPolygon2D.new()
			occluder.occluder.polygon = [ 
					Vector2.ZERO - Helper.TILE_HALF_SIZE, 
					Vector2(Helper.TILE_HALF_LENGTH, Helper.TILE_HALF_LENGTH * -1.0), 
					Vector2.ONE * Helper.TILE_HALF_SIZE, 
					Vector2(Helper.TILE_HALF_LENGTH * -1.0, Helper.TILE_HALF_LENGTH), 
					]
			add_child(occluder)
	_refresh_visual()
	if not Engine.is_editor_hint():
		if controller == null:
			controller = _find_controller()
		GameManager.register_entity(self)


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		GameManager.unregister_entity(self)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if is_moving:
		# Buffer only direction *changes* (turns), with an expiry age, so the
		# next step can start on arrival in the same tick with no dead time.
		# Same-direction input is deliberately not latched here: it is polled
		# live on arrival, which is what makes a brief tap a single step.
		if _queued_direction != Vector2.ZERO:
			_queued_age_s += delta
		if controller != null and GameManager.is_current(self):
			var buffered: Vector2 = controller.get_move_intent()
			if buffered != Vector2.ZERO and buffered != facing:
				if buffered != _queued_direction:
					_queued_age_s = 0.0
				_queued_direction = buffered
			elif buffered == facing:
				_queued_direction = Vector2.ZERO
				_queued_age_s = 0.0
		_advance(delta)
		return
	if controller == null:
		return
	if not GameManager.is_current(self):
		return
	var intent: Vector2 = controller.get_move_intent()
	if intent != Vector2.ZERO:
		try_step(intent)


## Attempts one grid step in `direction`. Returns true when a move started.
## Resolution order: push/swap with an adjacent box, swap with a distant box
## in line of sight, pull a box from behind, otherwise a plain step. Walls,
## entities and unpushable boxes block the step (facing still updates).
func try_step(direction: Vector2) -> bool:
	if is_moving or direction == Vector2.ZERO:
		return false
	facing = direction
	var destination: Vector2 = global_position + direction * Helper.TILE_SIZE
	var occupant: Object = Helper.get_grid_occupant(destination, get_rid())
	if occupant is Box:
		var box: Box = occupant as Box
		if _has_ability(Helper.ABILITY.PUSH_ONE):
			return _try_push_one(box, direction)
		if _has_ability(Helper.ABILITY.PUSH_ANY):
			return _try_push_any(direction)
		if _has_ability(Helper.ABILITY.SWAP):
			return _start_swap(box)
		_set_idle_animation()
		return false
	if occupant != null:
		_set_idle_animation()
		return false
	# Destination cell is free.
	if _has_ability(Helper.ABILITY.SWAP):
		var swap_target: Box = _find_swap_target(direction)
		if swap_target != null:
			return _start_swap(swap_target)
	if _has_ability(Helper.ABILITY.PULL_ONE):
		var behind: Object = Helper.get_grid_occupant(
			global_position - direction * Helper.TILE_SIZE, get_rid())
		if behind is Box:
			return _start_pull(behind as Box, direction)
	_start_move(destination)
	return true


func _try_push_one(box: Box, direction: Vector2) -> bool:
	if not box.can_move(direction):
		_set_idle_animation()
		return false
	box.start_move(direction, _step_speed_px())
	_start_move(global_position + direction * Helper.TILE_SIZE)
	return true


func _try_push_any(direction: Vector2) -> bool:
	var chain: Array[Box] = []
	var cell: Vector2 = global_position + direction * Helper.TILE_SIZE
	while true:
		var occupant: Object = Helper.get_grid_occupant(cell, get_rid())
		if not (occupant is Box):
			break
		chain.append(occupant as Box)
		cell += direction * Helper.TILE_SIZE
	if chain.is_empty():
		return false
	# The cell past the chain must be free, and no box in the chain may
	# already be sliding; only then does the whole chain move at once.
	if Helper.get_grid_occupant(cell, get_rid()) != null:
		_set_idle_animation()
		return false
	for box: Box in chain:
		if box.is_moving:
			_set_idle_animation()
			return false
	for box: Box in chain:
		box.start_move(direction, _step_speed_px())
	_start_move(global_position + direction * Helper.TILE_SIZE)
	return true


func _start_pull(box: Box, direction: Vector2) -> bool:
	# The box slides into the cell the entity is vacating, so it is always
	# free unless the box itself is mid-slide.
	if box.is_moving:
		_set_idle_animation()
		return false
	box.start_move(direction, _step_speed_px())
	_start_move(global_position + direction * Helper.TILE_SIZE)
	return true


## Swaps this entity's cell with the box's cell. Steps on the way are not
## taken, so the swap target is the nearest box with a clear line of sight.
func _start_swap(box: Box) -> bool:
	if box.is_moving:
		_set_idle_animation()
		return false
	var box_origin: Vector2 = box.global_position
	var entity_origin: Vector2 = global_position
	# Constant tile speed over the whole distance, so a distant swap takes
	# proportionally longer than a one-tile step.
	box.start_move_to(entity_origin, _step_speed_px())
	_start_move(box_origin)
	return true


## Nearest box in the direction of travel until a wall or entity blocks the
## line of sight; null when there is no box to swap with.
func _find_swap_target(direction: Vector2) -> Box:
	var cell: Vector2 = global_position + direction * Helper.TILE_SIZE
	while true:
		var occupant: Object = Helper.get_grid_occupant(cell, get_rid())
		if occupant == null:
			cell += direction * Helper.TILE_SIZE
			continue
		if occupant is Box:
			return occupant as Box
		return null
	return null


func _start_move(destination: Vector2) -> void:
	is_moving = true
	_move_target = destination
	_move_speed_px = _step_speed_px()
	_play_walk_animation()


## Advances toward the target cell at constant speed; on arrival snaps exactly
## onto the cell and immediately starts the next buffered/polled step.
func _advance(delta: float) -> void:
	var remaining: Vector2 = _move_target - global_position
	var step: float = _move_speed_px * delta
	if remaining.length() <= step:
		global_position = _move_target
		is_moving = false
		_on_arrived()
		return
	global_position += remaining.normalized() * step


func _on_arrived() -> void:
	if controller != null and GameManager.is_current(self):
		var intent: Vector2 = Vector2.ZERO
		var step_duration: float = 1.0 / _step_speed_tiles()
		if _queued_direction != Vector2.ZERO and _queued_age_s <= BUFFER_FRACTION * step_duration:
			intent = _queued_direction
		else:
			intent = controller.get_move_intent()
		_queued_direction = Vector2.ZERO
		_queued_age_s = 0.0
		if intent != Vector2.ZERO and try_step(intent):
			return
	_queued_direction = Vector2.ZERO
	_queued_age_s = 0.0
	if visual != null:
		visual.pause()


func _step_speed_tiles() -> float:
	return maxf(data.move_speed if data != null else 3.0, 0.1)


func _step_speed_px() -> float:
	return Helper.TILE_SIZE.x * _step_speed_tiles()


func _has_ability(ability: Helper.ABILITY) -> bool:
	return data != null and data.abilities.has(ability)


func _animation_for(direction: Vector2) -> StringName:
	if direction == Vector2.UP:
		return &"walk_up"
	if direction == Vector2.DOWN:
		return &"walk_down"
	if direction == Vector2.LEFT:
		return &"walk_left"
	return &"walk_right"


func _play_walk_animation() -> void:
	if visual == null or visual.sprite_frames == null:
		return
	var animation: StringName = _animation_for(facing)
	if not visual.sprite_frames.has_animation(animation):
		return
	# Keep the cycle running across chained steps; only (re)start it when the
	# direction changes or the sprite was paused after coming to rest.
	if visual.animation == animation and visual.is_playing():
		return
	# One walk cycle per tile: rescale the authored 5 fps to the step rate.
	visual.speed_scale = _step_speed_tiles() / 5.0
	visual.play(animation)


func _set_idle_animation() -> void:
	if visual == null or visual.sprite_frames == null:
		return
	var animation: StringName = _animation_for(facing)
	if visual.sprite_frames.has_animation(animation):
		visual.animation = animation
		visual.stop()


func _find_controller() -> EntityController:
	for child: Node in get_children():
		if child is EntityController:
			return child as EntityController
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
