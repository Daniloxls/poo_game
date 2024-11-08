extends Node2D

@onready var area = $Area2D
@onready var colision = $StaticBody2D
@onready var player = get_node("../Player")
@onready var codebox = get_node("../Codebox")
var nome = ""
var texto = []
var codigo = [""]
var portraits = [""]
var depuring = false
var unlocked = false

func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func interaction():
	if unlocked:
		var root = get_node("../../../..")
		var next_level = load("res://scenes/tutorial/anti_poo_room.tscn")
		var instance = next_level.instantiate()
		root.change_level(instance)
		return texto
	else:
		return ["Está trancada"]

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
	
func unlock():
	unlocked = true
