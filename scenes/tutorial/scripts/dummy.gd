extends "res://scripts/interact.gd"


@onready var porta_colision = $Porta/PortaShape
@onready var porta_sprite = $Porta/PortaSprite
@onready var sprite = $DummySprite
@onready var map = get_node("../TileMap")
@onready var battle = get_node("../../../Battle")

const UP_POSITION = 0
const DOWN_POSITION = 1

func _ready():
	area = $Area2D/CollisionShape2D
	colision = $StaticBody2D/Collision

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func interaction():
	battle.start_battle("res://scenes/encounters/testdummy.tscn")

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


func _on_tutorial_battle_tutorial_end():
	sprite.hide()
	colision.set_deferred("disabled", true)
	area.set_deferred("disabled", true)
	porta_colision.set_disabled(true)
	porta_sprite.set_frame(DOWN_POSITION)
