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

const TILE_SIZE: Vector2 = Vector2(64.0, 64.0)

# Bit masks for the named 2D physics layers in Project Settings.
const WALLS: int = 1
const BOXES: int = 2
const GOALS: int = 4
const ENTITIES: int = 8


func has_property(node: Object, property: StringName) -> bool:
	if not node:
		return false
	if not property:
		return false
	var properties: Array[Dictionary] = node.get_property_list()
	if not properties:
		return false
	if properties.is_empty():
		return false
	for i in properties.size():
		var _p: Dictionary = properties[i]
		var _v = _p.find_key("name")
		if not _v:
			return false
		if _v == property:
			return true
	return false
