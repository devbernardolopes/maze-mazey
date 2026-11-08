@tool
class_name FollowCamera
extends Camera2D
## Follows the active player entity. Retargets (with an instant snap) when
## GameManager switches the current entity.

@export var target: Node2D = null:
	set(v):
		if target == v:
			return
		target = v
		if not Engine.is_editor_hint():
			snap_to_target()

## Fixed framing zoom applied on entering the tree.
@export var base_zoom: float = 1.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	visible = true
	enabled = true
	zoom = Vector2.ONE * base_zoom
	position_smoothing_enabled = false
	if not GameManager.current_entity_changed.is_connected(_on_current_entity_changed):
		GameManager.current_entity_changed.connect(_on_current_entity_changed)
	if GameManager.current_player_entity != null:
		target = GameManager.current_player_entity
	snap_to_target()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if target == null or not is_instance_valid(target):
		return
	global_position = target.global_position


func snap_to_target() -> void:
	if Engine.is_editor_hint():
		return
	if target == null or not is_instance_valid(target):
		return
	global_position = target.global_position
	reset_smoothing()


func _on_current_entity_changed(entity: Entity) -> void:
	target = entity
