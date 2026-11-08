extends Node

## Sokoban abilities (extended).
## Defines how an entity interacts with in-game objects that are in the BOXES
## physics layer.
enum ABILITY {
	## The entity can push one of this object in the direction it is moving if
	## the object can move in that direction.
	PUSH_ONE = 10,
	## The entity can push more than one of this object at the same time in the
	## direction it is moving if the object can move in that direction.
	PUSH_ANY = 11,
	## The entity can pull one of this object in the direction opposite it is
	## moving.
	PULL_ONE = 20,
	## The entity swaps places with the first of this object that is in the
	## unobstructed line of sight in the direction it is moving.
	SWAP = 30,
}

const TILE_LENGTH: float = 64.0
const TILE_HALF_LENGTH: float = TILE_LENGTH / 2.0
const TILE_SIZE: Vector2 = Vector2.ONE * TILE_LENGTH
## Because the default [member offset] for the AnimatedSprite2D is centered.
const TILE_HALF_SIZE: Vector2 = TILE_SIZE / 2.0

# Bit masks for the named 2D physics layers in Project Settings.
const WALLS: int = 1
const BOXES: int = 2
const GOALS: int = 4
const ENTITIES: int = 8

## Returns the collider occupying the cell centred on `world_position`, or
## null when the cell is free. `exclude_rid` lets the caller ignore itself.
## Must be called during the physics step (direct space state access).
func get_grid_occupant(world_position: Vector2, exclude_rid: RID) -> Object:
	var space_state: PhysicsDirectSpaceState2D = get_tree().root.get_world_2d().direct_space_state
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collision_mask = WALLS | BOXES | ENTITIES
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [exclude_rid]
	var hits: Array[Dictionary] = space_state.intersect_point(query, 1)
	if hits.is_empty():
		return null
	return hits[0].get("collider") as Object
