extends Node

# TODO: I don't know where or how to track the current player entity
var current_player_entity: Entity = null
# TODO: We need to find a way to know which entities are available to the player
var player_entities: Array[Entity] = []

func _input(event: InputEvent) -> void:
	if event.is_action("escape"):
		get_tree().quit()
	# This action should cycle the player's entities
	# This should also switch the target of the follow camera
	if event.is_action("switch"):
		pass
