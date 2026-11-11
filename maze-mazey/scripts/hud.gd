@tool
class_name Hud
extends CanvasLayer

const PLAYER_SLOT = preload("res://scenes/hud/player_slot.tscn")
const ITEM_UI = preload("res://scenes/hud/item_ui.tscn")

@export var margin: float = 6.00

@onready var player_entities_node: Node2D = $PlayerEntitiesNode

var bottom_left: Vector2 = Vector2.ZERO


func _ready() -> void:
	#print(get_viewport().get_window().size)
	if not Engine.is_editor_hint():
		bottom_left = Vector2(0, Helper.get_game_size().y)
		if not GameManager.current_entity_changed.is_connected(_on_current_entity_changed):
			GameManager.current_entity_changed.connect(_on_current_entity_changed)
		_refresh_visual()


func _on_current_entity_changed(entity: Entity) -> void:
	if not Engine.is_editor_hint():
		if entity and not entity.is_queued_for_deletion():
			_refresh_visual()


func _refresh_visual() -> void:
	if not player_entities_node:
		return
	for child in player_entities_node.get_children():
		child.queue_free()
	var player_entities: Array[Entity] = GameManager.player_entities
	if player_entities and not player_entities.is_empty():
		for i in player_entities.size():
			var player_entity: Entity = player_entities[i]
			if player_entity.playable:
				var slot: Slot = PLAYER_SLOT.instantiate()
				player_entities_node.add_child(slot)
				# Had to put this if here because when exiting the game just 
				# after switching the player entity it crashed in the
				# slot.visual.self_modulate = player_entity.data.color line
				if slot and slot.visual:
					slot.visual.self_modulate = player_entity.data.color
					print(player_entity.data.color)
					slot.overlay.visible = player_entity == GameManager.current_player_entity
					slot.position = bottom_left
					slot.position.x = margin + (i * Helper.TILE_LENGTH)
					slot.position.y -= Helper.TILE_LENGTH
