extends Node2D

@onready var area = $Area2D
@onready var colision = $StaticBody2D
@onready var player = get_node("../Player")
@onready var textbox = get_node("../Textbox")
@onready var codebox = get_node("../Codebox")
@onready var map = get_node("../TileMap")
var nome
var texto
var portraits
var codigo
var depuring = false
var dialogue = true

func _ready():
	set_texto(["Está trancada.", "Parece que você ainda não consegue abrir essa porta,
	tente usar aquele terminal interaja com ele."])
	set_portraits(["", "res://assets/portraits/silhueta.png"])
	set_codigo("Porta", {"1int idade": 15, "1boolean trancado": true, "Material material": "madeira"})

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("exit") and depuring:
		colision.set_collision_layer_value(1, codigo["1boolean trancado"])
		map.set_layer_enabled(4, codigo["1boolean trancado"])
		depuring = false
	if Input.is_action_just_pressed("depure"):
		if dialogue and area.has_overlapping_areas():
			dialogue = false
			textbox.queue_char_text(["Veja, esssas são as propiedades da porta.",
			"Ela tem uma linha de codigo que diz se ela está trancada, por sorte conseguimos editar ela.",
			"Por ser uma variavel booleana ela só pode verdadeiro ou falso",
			"Use as setas para cima e para baixo para selecionar a propiedade trancado e as setas esquerda e direita para altera-la",
			"Mude a variavel trancado para falso(false)",
			"E para sair da tela de codigo basta apertar X"],
			["res://assets/portraits/silhueta.png",
			"res://assets/portraits/silhueta.png",
			"res://assets/portraits/silhueta.png",
			"res://assets/portraits/silhueta.png",
			"res://assets/portraits/silhueta.png",
			"res://assets/portraits/silhueta.png"])
			
	pass


func interaction():
	if player.get_sudo() and len(texto) > 1:
		texto.pop_back()
		portraits.pop_back()
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
