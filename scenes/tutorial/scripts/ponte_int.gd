extends Node2D

@onready var colision = $StaticBody2D
@onready var area = $Area2D
@onready var player = get_node("../Player")
@onready var textbox = get_node("../Textbox")
@onready var codebox = get_node("../Codebox")
@onready var map = get_node("../TileMap")
@onready var pit = get_node("../Pit")

var nome
var texto
var codigo 
var portraits
var dialogue = true
# Called when the node enters the scene tree for the first time.
func _ready():
	colision.set_collision_layer_value(1, false)
	set_texto(["Está quebrada"])
	set_portraits([""])
	set_codigo("Ponte", {"1int tamanho" : 1})
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("exit"):
		pit.set_size(codigo["1int tamanho"])
		
	if Input.is_action_just_pressed("depure"):
		if dialogue and area.has_overlapping_areas():
			dialogue = false
			textbox.queue_char_text(["Ótimo, essa ponte tem uma variavel que controla o tamanho dela",
			"Uma variavel do tipo int tem um valor numérico que podemos controlar",
			"Basta apertar a seta para a direita para aumentar e a seta esquerda para diminuir a variavel selecionada",
			"Selecione a variavel tamanho e tente aumentar ela para conseguir cruzar esse penhasco"],
			["res://assets/portraits/silhueta.png",
			"res://assets/portraits/silhueta.png",
			"res://assets/portraits/silhueta.png",
			"res://assets/portraits/silhueta.png"])
	pass

func set_texto(new_texto):
	texto = new_texto
	
func set_codigo(new_nome, new_codigo):
	nome = new_nome
	codigo = new_codigo

func update_codigo(new_codigo):
	codigo = new_codigo
	
func interaction():
	return texto
	
func get_portraits():
	return portraits
	
func set_portraits(new_portraits):
	portraits = new_portraits
	
func depure():
	return codigo
	
func name():
	return nome
