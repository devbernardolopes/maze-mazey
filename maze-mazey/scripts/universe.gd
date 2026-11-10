@tool
extends Node2D


@export var unit_size: int = 32


func _ready() -> void:
	if not Engine.is_editor_hint():
		MusicPlayer.play_music(Helper.UNIVERSE_MUSIC)
