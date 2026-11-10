class_name EntityData
extends BaseResource

@export_category("ID")
@export var entity_race: EntityRaceData = null
@export var entity_class: EntityClassData = null
@export var base_xp: int = 1
@export_category("Visual")
@export var abilities: Array[Helper.ABILITY] = [ Helper.ABILITY.PUSH_ONE ]
## Movement speed in tiles per second. One step covers exactly one tile.
@export var move_speed: float = 6.0
## Field of view of the entity: shape, size, and angle, see `FovData`.
@export var fov: FovData = null
@export_category("Abilities")
## Physical might
@export_range(0, 30, 1) var strength: int = 10
## Agility, reflexes, and balance
@export var dexterity: int = 10
## Health and stamina
@export var constitution: int = 10
## Reasoning and memory
@export var intelligence: int = 10
## Perceptiveness and mental fortitude
@export var wisdom: int = 10
## Confidence, poise, and charm
@export var charisma: int = 10
