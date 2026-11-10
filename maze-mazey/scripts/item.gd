@tool
class_name Item
extends BaseScene


func _ready() -> void:
	super._ready()
	collision_layer = Helper.ITEMS
	collision_mask = 0
