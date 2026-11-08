class_name BoxData
extends Resource

@export var id: StringName = &""
@export var name: String = ""
@export var color: Color = Color.WHITE
@export var visual: SpriteFrames = null
## What goals accept this box
@export var goals: Array[GoalData] = []
