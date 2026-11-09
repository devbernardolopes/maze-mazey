class_name EntityController
extends Node

## Discrete grid intent: one of the four cardinal directions, or Vector2.ZERO.
func get_move_intent() -> Vector2:
	return Vector2.ZERO


## Consumes a move intent that an instant action (such as a swap) has just
## handled, so a single input activation does not chain a follow-up step.
func consume_move_intent() -> void:
	pass
