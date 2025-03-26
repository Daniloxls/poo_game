extends "res://scripts/interact.gd"


@onready var map = get_node("../TileMap")
@onready var sprite = $AnimatedSprite2D
var dialogue = true
func _ready():
	nome = "Porta"
	texto = ["Está trancada.", "Parece que você ainda não consegue abrir essa porta.", "Tente interagir com o terminal lá atrás."]
	portraits = ["", "res://assets/portraits/silhueta.png", "res://assets/portraits/silhueta.png"]
	codigo = {"1boolean trancado": true, "Material material": "barreira"}
	ready_drop_menu()
	codebox.connect("codebox_open", _on_codebox_code_open)
	codebox.connect("codebox_close", _on_codebox_code_closed)

func interaction():
	if player.get_sudo() and len(texto) > 1:
		texto.pop_back()
		portraits.pop_back()
	textbox.queue_char_text(texto, portraits)


func _on_codebox_code_closed(name):
	if (name == self.get_name()):
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


func _on_codebox_code_open(name):
	if dialogue and (name == self.get_name()):
		print("coiso")
		dialogue = false
		textbox.queue_char_text(["Veja, essas são as propriedades da porta.",
		"Ela tem uma linha de código que diz se ela está trancada e por sorte você consegue editar ela.",
		"Por ser uma variável booleana ela só pode verdadeira ou falsa.",
		"Aperte em cima do valor true para muda-lo para false e vice-versa",
		"Mude a variável trancado para falso(false).",
		"E para sair da tela de código basta apertar o botão Fechar."],
		["res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png"])
