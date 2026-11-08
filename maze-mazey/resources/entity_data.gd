class_name EntityData
extends Resource

@export var id: StringName = &""
@export var name: String = ""
@export var color: Color = Color.WHITE
@export var abilities: Array[Helper.ABILITY] = [ Helper.ABILITY.PUSH_ONE ]
## Movement speed in tiles per second. One step covers exactly one tile.
@export var move_speed: float = 3.0
@export var visual: SpriteFrames = null
