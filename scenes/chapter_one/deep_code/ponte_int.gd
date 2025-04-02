extends "res://scenes/main/scripts/interact.gd"

@onready var map = get_node("../TileMap")
@onready var pit = get_node("../Pit")
var dialogue = true

# Called when the node enters the scene tree for the first time.
func _ready():
	colision.set_collision_layer_value(1, false)
	nome = "Ponte"
	texto = ["Está quebrada."]
	codigo = {"1int tamanho" : 1}
	ready_drop_menu()
	Codebox.connect("codebox_open", _on_codebox_code_open)
	Codebox.connect("codebox_close", _on_codebox_code_closed)


func update_code():
	pit.set_size(codigo["1int tamanho"])


func _on_codebox_code_open(name):
	if dialogue and (name == self.get_name()):
		dialogue = false
		Textbox.queue_char_text(["Ótimo, essa ponte tem uma variável que controla o tamanho dela.",
		"Uma variável do tipo int tem um valor numérico que podemos aumentar ou diminuir.",
		"Basta selecionar a variável e digitar o valor para colocar nela.",
		"Selecione a variável tamanho e tente aumentar ela para conseguir cruzar esse penhasco.",
		"Quando você fechar o menu de código o valor dela deve se atualizar"],
		["res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png"])


func _on_codebox_code_closed(name):
	update_code()
