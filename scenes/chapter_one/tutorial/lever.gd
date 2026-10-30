extends "res://scenes/main/scripts/interact.gd"
## Alavanca da sala 2: só avisa que foi puxada; quem abre a parede é o tutorial.gd.

signal puxada

@onready var sprite = $Sprite

const DOWN_POSITION = 1

var puxou := false


func _ready():
	ready_drop_menu()

func interaction():
	if puxou:
		return
	puxou = true
	sprite.set_frame(DOWN_POSITION)
	puxada.emit()
