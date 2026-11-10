class_name EntityRaceData
extends BaseResource

@export_category("Body")
@export var body: BodyData = null
@export_category("Race Modifiers")
@export var strength: int = 0
@export var dexterity: int = 0
@export var constitution: int = 0
@export var intelligence: int = 0
@export var wisdom: int = 0
@export var charisma: int = 0
@export_category("Social")
@export var enemy_races: Array[EntityRaceData] = []
@export var enemy_entities: Array[EntityData] = []
