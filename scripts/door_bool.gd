extends Node2D

@onready var area = $Area2D
@onready var colision = $StaticBody2D
@onready var player = get_node("../Player")
@onready var codebox = get_node("../Codebox")
@onready var map = get_node("../TileMap")
var nome
var texto
var portraits
var codigo
var depuring = false


func _ready():
	set_texto(["Está trancada.", "Parece que você ainda não consegue abrir essa porta,
	tente usar aquele terminal interaja com ele."])
	set_portraits(["", "res://assets/portraits/silhueta.png"])
	set_codigo("Porta", {"1boolean trancado": true})

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("exit") and depuring:
		colision.set_collision_layer_value(1, codigo["1boolean trancado"])
		map.set_layer_enabled(2, codigo["1boolean trancado"])
		depuring = false
			
		
	pass


func interaction():
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
