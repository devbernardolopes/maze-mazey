@tool
extends Node2D

@export var unit_size: int = 32
@onready var fog_of_war: TileMapLayer = $FogOfWar


func _ready() -> void:
	if not Engine.is_editor_hint():
		MusicPlayer.play_music(Helper.UNIVERSE_MUSIC)
		if fog_of_war:
			GameManager.register_fog_of_war(fog_of_war)
			fog_of_war.visible = true
