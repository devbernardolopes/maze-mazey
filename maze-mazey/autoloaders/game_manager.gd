extends Node

## Owns the roster of player-controllable entities and which one is active.
## Entities register themselves on entering the tree; the follow camera
## listens to `current_entity_changed` to retarget.

signal current_entity_changed(entity: Entity)

var current_player_entity: Entity = null
var player_entities: Array[Entity] = []

var _current_index: int = -1


func register_entity(entity: Entity) -> void:
	if entity == null or player_entities.has(entity):
		return
	player_entities.append(entity)
	if current_player_entity == null:
		set_current_entity(entity)


func unregister_entity(entity: Entity) -> void:
	var index: int = player_entities.find(entity)
	if index == -1:
		return
	player_entities.remove_at(index)
	if entity != current_player_entity:
		return
	if player_entities.is_empty():
		current_player_entity = null
		_current_index = -1
		current_entity_changed.emit(null)
		return
	set_current_entity(player_entities[mini(index, player_entities.size() - 1)])


func set_current_entity(entity: Entity) -> void:
	if entity == current_player_entity:
		return
	if entity != null and not player_entities.has(entity):
		return
	current_player_entity = entity
	_current_index = player_entities.find(entity) if entity != null else -1
	current_entity_changed.emit(entity)


func cycle_entities() -> void:
	if player_entities.size() <= 1:
		return
	var next_index: int = (_current_index + 1) % player_entities.size()
	set_current_entity(player_entities[next_index])


func is_current(entity: Entity) -> bool:
	return entity != null and entity == current_player_entity


func _input(event: InputEvent) -> void:
	if event.is_action("escape"):
		get_tree().quit()
	if event.is_action("switch"):
		cycle_entities()
