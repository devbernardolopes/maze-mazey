class_name PlayerController
extends EntityController

func get_move_vector() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")


func get_direction_h() -> float:
	return Input.get_axis("left", "right")
