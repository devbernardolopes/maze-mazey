class_name PlayerController
extends EntityController

## Snaps the analog input to the dominant cardinal direction so movement
## stays grid-aligned. Holding a key repeats steps via the entity's polling.
func get_move_intent() -> Vector2:
	var input_vector: Vector2 = Input.get_vector("left", "right", "up", "down")
	if input_vector.is_zero_approx():
		return Vector2.ZERO
	if absf(input_vector.x) >= absf(input_vector.y):
		return Vector2(signf(input_vector.x), 0.0)
	return Vector2(0.0, signf(input_vector.y))


## Releases a held cardinal direction so an instant action (such as a swap)
## triggered by it does not immediately chain a follow-up step on the next
## physics frame.
func consume_move_intent() -> void:
	if Input.is_action_pressed(&"left") or Input.is_action_pressed(&"right") or Input.is_action_pressed(&"up") or Input.is_action_pressed(&"down"):
		Input.action_release(&"left")
		Input.action_release(&"right")
		Input.action_release(&"up")
		Input.action_release(&"down")
