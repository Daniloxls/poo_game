extends Node2D
@onready var sword_scene = $Cutscene
@onready var player = $Player

signal battle_won
signal battle_lost

# Called when the node enters the scene tree for the first time.
func _ready():
	var bg = load("res://assets/battle/background/tatame.png")
	Battle.connect("battle_lost", _on_battle_lost)
	Battle.connect("battle_won", _on_battle_won)
	Battle.set_background(bg)
	MusicPlayer.set_stream(load("res://assets/bgm/Enchanted-Festival-Loop.mp3"))
	#MusicPlayer.play()


# Atalho de teste: F9 toca a cutscene da espada (só em build de debug, ex.: F5/F6 no editor).
func _unhandled_input(event):
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		sword_scene.play()


func _on_battle_lost():
	battle_lost.emit()
	
func _on_battle_won():
	battle_won.emit()
