@tool
extends Node2D

func _ready() -> void:
	if not Engine.is_editor_hint():
		MusicPlayer.play_music(Helper.UNIVERSE_MUSIC)
