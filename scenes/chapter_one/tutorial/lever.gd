extends "res://scenes/main/scripts/interact.gd"

@onready var sprite = $Sprite
@onready var porta_sprite = $Porta/PortaSprite

const UP_POSITION = 0
const DOWN_POSITION = 1


func _ready():
	ready_drop_menu()
	colision = $Porta/PortaShape

func interaction():
	colision.set_disabled(true)
	sprite.set_frame(DOWN_POSITION)
	porta_sprite.set_frame(DOWN_POSITION)
