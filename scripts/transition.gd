extends "res://scripts/interact.gd"


@onready var map = get_node("../TileMap")

#Extende interact, faz alguma coisa quando alguma coisa entra em sua area
# Todos objetos que fazem alguma coisa ao serem 'pisados' extedem essa classe
# Talvez seja a mesma coisa que event, tenho de rever isso

func _ready():
	area.monitoring = true


func _process(delta):
	pass

#Essa função acontece sempre que alguma coisa entra na colisão da Area2D desse obejto
func _on_area_2d_area_entered(area):
	pass
