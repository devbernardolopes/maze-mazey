@tool
class_name Entity
extends BaseScene
## Grid-bound entity. Moves one tile at a time (see `Helper.TILE_SIZE`) at a
## constant speed (`EntityData.move_speed`, tiles/second) on the physics
## clock, chaining steps without a gap while input is held, and resolves box
## interactions through its `Helper.ABILITY` list.

## A buffered direction *change* is honoured on arrival only while it is
## fresher than this fraction of the current step's duration. Same-direction
## input is never latched: it is re-polled live on arrival, so a brief tap
## (released before arrival) moves exactly one tile.
const BUFFER_FRACTION: float = 0.5

@export var playable: bool = false:
	set(v):
		playable = v
		if not Engine.is_editor_hint():
			if v:
				GameManager.register_entity(self)
			else:
				GameManager.unregister_entity(self)

@export var level: int = 1
## Maximum natural hit points (health) is determined by the class and the 
## constitution. Updated every new level gained.
@export var max_natural_hit_points: int = 1
## Maximum total hit points (health) is the sum of 
## [member max_natural_hit_points] and any other hit pointts modifier such as an
## item, an active spell, a condition, and so on. It can be less or greater than
## [member max_natural_hit_points].
@export var max_total_hit_points: int = 1
## Current hit points (health).
@export var hit_points: int = 1
@export var xp: int = 1

var controller: EntityController = null
## Last attempted cardinal direction (kept when idle, for animation/camera).
var facing: Vector2 = Vector2.DOWN
var is_moving: bool = false
var _move_target: Vector2 = Vector2.ZERO
var _move_speed_px: float = 0.0
## Latest direction *change* pressed while a step is in progress, consumed on
## arrival if still fresh (see `BUFFER_FRACTION`).
var _queued_direction: Vector2 = Vector2.ZERO
var _queued_age_s: float = 0.0
## Fog of war: tiles this entity has already revealed. Keys are fog layer map
## coordinates (Vector2i); erased tiles stay revealed forever.
var _revealed_tiles: Dictionary = {}


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		if not GameManager.current_entity_changed.is_connected(_on_current_entity_changed):
			GameManager.current_entity_changed.connect(_on_current_entity_changed)
		if not controller:
			controller = Static.find_control(self, "PlayerController")
		if playable:
			GameManager.register_entity(self)
	## In-game, game-related rules and stuff.
	_init_hit_points()


## Initialize the hit points variables considering level 1
func _init_hit_points() -> void:
	if data == null:
		return
	var base_class_hit_points: int = 0
	if data.entity_class:
		base_class_hit_points = data.entity_class.base_hit_points
	max_natural_hit_points = base_class_hit_points + data.constitution
	max_total_hit_points = max_natural_hit_points


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		GameManager.unregister_entity(self)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_fog_of_war()
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
	if not controller:
		return
	if not GameManager.is_current(self):
		return
	var intent: Vector2 = controller.get_move_intent()
	if intent != Vector2.ZERO:
		try_step(intent)

## Reveals tiles inside this entity's field of view that it has not seen before,
## and dispels the fog over them on the fog layer while it is the active player.
## Revealed tiles are remembered per entity forever; only the currently active
## playable entity dispels fog (non-playable entities just build perception).
func _update_fog_of_war() -> void:
	if Engine.is_editor_hint():
		return
	if data == null:
		return
	var fog_of_war: TileMapLayer = GameManager.fog_of_war
	if fog_of_war == null:
		return
	for tile: Vector2i in _get_fog_reveal_tiles(fog_of_war):
		if not _revealed_tiles.has(tile):
			_revealed_tiles[tile] = true
	_erase_revealed_tiles(fog_of_war)


## Dispel the fog over every tile this entity has revealed so far. Only the
## currently active playable entity dispels fog.
func _erase_revealed_tiles(fog_of_war: TileMapLayer) -> void:
	if not (playable and GameManager.is_current(self)):
		return
	for tile: Vector2i in _revealed_tiles.keys():
		fog_of_war.erase_cell(tile)


## When this entity becomes the active player, dispel the fog over every tile
## it has revealed but never got to dispel while it was not active.
func _on_current_entity_changed(entity: Entity) -> void:
	if entity != self:
		return
	_erase_revealed_tiles(GameManager.fog_of_war)


## Whether the tile `delta` tiles away from this entity is in line of sight:
## nothing standing on the `Helper.WALLS` physics layer may be between the
## entity and the tile, so the sight cone cannot reach through walls. The tile
## itself counts as visible when the ray reaches its near edge unobstructed, so
## wall tiles inside the cone are revealed while anything behind them is not.
func _has_line_of_sight(delta: Vector2) -> bool:
	var from: Vector2 = global_position
	var to: Vector2 = global_position + delta * Helper.TILE_SIZE
	if to == from:
		return true
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	query.from = from
	query.to = to
	query.collision_mask = Helper.WALLS
	query.exclude = [get_rid()]
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var hit_distance: float = (hit["position"] - from).length()
	var near_edge: float = (to - from).length() - Helper.TILE_HALF_LENGTH
	return hit_distance >= near_edge


## Tiles inside this entity's field of view that it has not revealed yet. The
## field of view is the sector of circle configured by `data.fov` (see
## [FovData]): it starts on the entity, grows to `fov_size` tiles in the
## direction of `facing`, and spans `fov_angle` degrees (full width) around that
## direction, and is blocked by walls. The entity's own tile is always part of the
## field of view.
func _get_fog_reveal_tiles(fog_of_war: TileMapLayer) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if data == null:
		return tiles
	var fov_data: FovData = data.fov
	if fov_data == null:
		fov_data = FovData.new()
	var reach: int = int(roundf(fov_data.fov_size))
	var origin_tile: Vector2i = fog_of_war.local_to_map(fog_of_war.to_local(global_position))
	for x in range(int(origin_tile.x) - reach, int(origin_tile.x) + reach + 1):
		for y in range(int(origin_tile.y) - reach, int(origin_tile.y) + reach + 1):
			var delta: Vector2 = Vector2(float(x - origin_tile.x), float(y - origin_tile.y))
			if not _is_tile_in_fov(delta, fov_data):
				continue
			if not _has_line_of_sight(delta):
				continue
			tiles.append(Vector2i(x, y))
	return tiles


## Whether the tile offset `delta` (in tiles away from this entity's tile) is
## inside the field of view: a sector of circle narrowed by the full width
## `fov_angle` around the `facing` and reaching up to the sight length
## `fov_size`, a rectangle of size `fov_size` x `fov_size` centered on the
## entity, or the literal polygon shape `fov_shape` when one is set.
func _is_tile_in_fov(delta: Vector2, fov_data: FovData) -> bool:
	var shape: Shape2D = fov_data.fov_shape
	if shape is CircleShape2D or shape == null:
		var forward: float = delta.dot(facing)
		# Behind the entity or past the end of the sight.
		if forward < 0.0 or forward > fov_data.fov_size:
			return false
		# Sector half angle: half of the full width, in radians.
		var half_angle: float = deg_to_rad(fov_data.fov_angle) * 0.5
		var cos_half_angle: float = cos(half_angle)
		var cos_angle: float = 1.0
		if delta.length() > 0.0:
			cos_angle = delta.dot(facing) / (delta.length() * facing.length())
		return cos_angle >= cos_half_angle
	if shape is RectangleShape2D:
		# Rectangular shape: `fov_size` is the size of the square along both
		# axes, centered on the entity, facing and behind.
		var half_extent: float = fov_data.fov_size * 0.5
		var square_forward: float = delta.dot(facing)
		var square_lateral: float = delta.dot(facing.rotated(90.0))
		return absf(square_forward) <= half_extent and absf(square_lateral) <= half_extent
	if shape is ConvexPolygonShape2D:
		return _is_point_in_polygon(delta, (shape as ConvexPolygonShape2D).get_points())
	if shape is ConcavePolygonShape2D:
		var segments: PackedVector2Array = (shape as ConcavePolygonShape2D).get_segments()
		var polygon: PackedVector2Array = PackedVector2Array()
		for i in range(0, segments.size(), 2):
			polygon.append(segments[i])
		return _is_point_in_polygon(delta, polygon)
	return false


## Whether the tile offset `delta` lies inside the polygon the field of view
## shape describes, rotated to face `facing` from this entity's position.
func _is_point_in_polygon(delta: Vector2, polygon: PackedVector2Array) -> bool:
	var shape_transform := Transform2D(facing.angle(), Vector2.ZERO)
	var world_polygon := PackedVector2Array()
	for i in polygon.size():
		world_polygon.append(shape_transform * polygon[i])
	return Geometry2D.is_point_in_polygon(delta * Helper.TILE_SIZE, world_polygon)


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


## Swaps this entity's cell with the box's cell. The swap is instant: both
## teleport to the other's origin instead of sliding toward each other along
## the path. Steps on the way are not taken, so the swap target is the nearest
## box with a clear line of sight. Like a plain step, a swap consumes the input
## that triggered it: no follow-up step is chained for a mere tap.
func _start_swap(box: Box) -> bool:
	if box.is_moving:
		_set_idle_animation()
		return false
	var box_origin: Vector2 = box.global_position
	# Teleport both tiles at once; there is no intermediate step to advance.
	box.teleport_to(global_position)
	global_position = box_origin
	is_moving = false
	_move_target = Vector2.ZERO
	_move_speed_px = 0.0
	_set_idle_animation()
	if controller != null:
		controller.consume_move_intent()
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
