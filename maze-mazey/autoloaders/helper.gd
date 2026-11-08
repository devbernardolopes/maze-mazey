extends Node

## Sokoban abilities (extended).
## Defines how an entity interacts with in-game objects that have the  
enum ABILITY {
	
	PUSH_ONE = 10,
	PUSH_ANY = 11,
	PULL_ONE = 20,
	PULL_ANY = 21,
	## The entity swaps place with 
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
