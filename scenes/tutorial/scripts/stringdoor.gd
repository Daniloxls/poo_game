extends Node2D
@onready var area = $Area2D
@onready var player = get_node("../Player")
@onready var textbox = get_node("../Textbox")
@onready var codebox = get_node("../Codebox")
@onready var map = get_node("../TileMap")
@onready var sprite = $AnimatedSprite2D
@onready var porta = $Porta
var nome = "Teclado Numerico"
var texto = ["Esse teclado deve ser para colocar a senha.", "Estão faltando as teclas 'a' e 's'."]
var codigo = {"1String senha" : "senha123"}
var portraits
var good_password = false
var depuring = false
var dialogue = true
var interacted = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func interaction():
	interacted = true
	if good_password:
		sprite.set_frame_and_progress(1, 0)
		porta.unlock()
	textbox.queue_text(texto)

func set_texto(new_texto):
	texto = new_texto
	
func set_codigo(new_nome, new_codigo):
	nome = new_nome
	codigo = new_codigo

func update_codigo(new_codigo):
	codigo = new_codigo
	
func depure():
	depuring = true
	return codigo
	
func get_portraits():
	return portraits
	
func set_portraits(new_portraits):
	portraits = new_portraits
	
func name():
	return nome


func _on_codebox_code_open():
	if dialogue and area.has_overlapping_areas():
		dialogue = false
		textbox.queue_char_text(["Parece que o tolo que projetou essa sala deixou a senha da porta salva em uma string.",
		"Uma que podemos editar ainda por cima.",
		"Variáveis String são formadas por conjuntos de caracteres",
		"Para editar essa string você precisa selecionar ela e apertar Enter, então você entrará no modo de edição.",
		"A partir daí você pode digitar o que quiser para ser a String e para sair do modo de edição basta apertar Enter novamente.",
		"Tente editar a senha dessa porta para alguma coisa que você consiga digitar sem 'a' nem 's' e depois tente interagir com esse teclado novamente."],
		["res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png"])
				



func _on_codebox_code_closed():
	if !("a" in codigo["1String senha"]) and !("s" in codigo["1String senha"]):
		set_texto(["Parece que a senha funcionou!"])
		good_password = true
	elif interacted:
		set_texto(["Não consigo digitar essa senha, o teclado não tem as teclas 'a' nem 's'."])
		good_password = false
