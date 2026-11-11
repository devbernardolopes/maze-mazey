@tool
class_name TextLabel
extends Control

@export var title_color: Color = Color.YELLOW
@export var content_color: Color = Color.WHITE
@export var title: String = "":
	set(v):
		title = v
		_refresh_visual()
@export var content: String = "":
	set(v):
		content = v
		_refresh_visual()

var title_label: Label = null
var content_label: Label = null


func _ready() -> void:
	title_label = Static.find_control(self.find_child("Container"), "Label", &"Title")
	content_label = Static.find_control(self.find_child("Container"), "Label", &"Content")
	_refresh_visual()


func _refresh_visual() -> void:
	if not title_label:
		return
	if not content_label:
		return
	title_label.text = title
	content_label.text = content
