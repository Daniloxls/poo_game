extends Node2D

@onready var area = $Area2D
@onready var sprite = $Sprite
@onready var colision = $Porta/PortaShape
@onready var player = get_node("../Player")
@onready var codebox = get_node("../Codebox")
@onready var map = get_node("../TileMap")

const OPEN_FRAME = 2
const CLOSED_FRAME = 1

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
	map.set_layer_enabled(3, false)
	colision.set_disabled(true)
	sprite.set_frame_and_progress(OPEN_FRAME,0)
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
