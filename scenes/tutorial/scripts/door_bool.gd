extends Node2D

@onready var area = $Area2D
@onready var colision = $StaticBody2D
@onready var player = get_node("../Player")
@onready var textbox = get_node("../Textbox")
@onready var codebox = get_node("../Codebox")
@onready var map = get_node("../TileMap")
@onready var sprite = $AnimatedSprite2D
var nome = "Porta"
var texto = ["Está trancada.", "Parece que você ainda não consegue abrir essa porta.", "Tente interagir com o terminal lá atrás."]
var portraits = ["", "res://assets/portraits/silhueta.png", "res://assets/portraits/silhueta.png"]
var codigo = {"1boolean trancado": true, "Material material": "barreira"}
var depuring = false
var dialogue = true

func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func interaction():
	if player.get_sudo() and len(texto) > 1:
		texto.pop_back()
		portraits.pop_back()
	textbox.queue_char_text(texto, portraits)

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


func _on_codebox_code_closed():
	colision.set_collision_layer_value(1, codigo["1boolean trancado"])
	depuring = false
	if !codigo["1boolean trancado"]:
		set_texto([])
		set_portraits([])
		sprite.set_frame_and_progress(1, 0)
	else:
		set_texto(["Está trancada."])
		set_portraits([""])
		sprite.set_frame_and_progress(0, 0)


func _on_codebox_code_open():
	if dialogue and area.has_overlapping_areas():
		dialogue = false
		textbox.queue_char_text(["Veja, essas são as propriedades da porta.",
		"Ela tem uma linha de código que diz se ela está trancada e por sorte você consegue editar ela.",
		"Por ser uma variável booleana ela só pode verdadeira ou falsa.",
		"Use as setas para cima e para baixo para selecionar a propriedade trancado e as setas esquerda e direita para altera-la.",
		"Mude a variável trancado para falso(false).",
		"E para sair da tela de código basta apertar X."],
		["res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png"])
