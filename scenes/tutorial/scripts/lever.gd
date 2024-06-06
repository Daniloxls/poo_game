extends "res://scripts/interact.gd"

@onready var sprite = $Sprite
@onready var porta_sprite = $Porta/PortaSprite
@onready var map = get_node("../TileMap")

const UP_POSITION = 0
const DOWN_POSITION = 1


func _ready():
	colision = $Porta/PortaShape
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func interaction():
	colision.set_disabled(true)
	sprite.set_frame(DOWN_POSITION)
	porta_sprite.set_frame(DOWN_POSITION)

func set_texto(new_texto):
	texto = new_texto
	
func get_portraits():
	return portraits
	
func set_portraits(new_portraits):
	portraits = new_portraits
	
func set_codigo(new_nome, new_codigo):
	nome = new_nome
	codigo = new_codigo

func update_codigo(new_codigo):
	codigo = new_codigo
	
func depure():
	depuring = true
	return codigo
	
func name():
	return nome
