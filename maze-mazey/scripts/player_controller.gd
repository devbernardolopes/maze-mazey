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
