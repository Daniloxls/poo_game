extends Node2D

@onready var area = $Area2D
@onready var colision = $StaticBody2D
@onready var player = get_node("../Player")
@onready var codebox = get_node("../Codebox")
@onready var map = get_node("../TileMap")
@onready var battle = get_node("../../../Battle")
var nome
var texto = []
var codigo = [""]
var portraits = [""]
var depuring = false


func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func interaction():
	battle.start_battle()
	player.set_movement(false)
	return texto

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
