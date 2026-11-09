@tool
class_name Slot
extends Node2D

var visual: AnimatedSprite2D = null
var overlay: Sprite2D = null
var is_selected: bool = false:
	set(v):
		is_selected = v
		if overlay:
			overlay.visible = v


func _ready() -> void:
	visual = _find_visual()
	if not visual:
		visual = AnimatedSprite2D.new()
		visual.sprite_frames = SpriteFrames.new()
		add_child(visual)
	if not overlay:
		overlay = Sprite2D.new()
		overlay.texture = Helper.SLOT_OUTLINE
		add_child(overlay)
	visual.centered = false
	overlay.centered = false
	overlay.visible = is_selected


func _find_visual() -> AnimatedSprite2D:
	for child: Node in get_children():
		if child is AnimatedSprite2D:
			return child as AnimatedSprite2D
	return null
