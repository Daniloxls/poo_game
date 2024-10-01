extends "res://scripts/interact.gd"

var triggered = false

@onready var bridged = $Bridge

func _ready():
	nome = "Ponte"
	codigo = {}
	metodos = {
		"1": ["boolean reparar_ponte(int quantidade_madeira){"],
		"2": ["\tboolean sucesso;"],
		"3": ["\tif (quantidade_madeira >= 4){"],
		"4": ["\t\tsucesso = true;\n\t}"],
		"5": ["\telse{"],
		"6": ["\t\tsucesso = false;\n\t}"],
		"7": ["\treturn sucesso;\n"]
	}

func interaction():
	player.set_movement(false)
	textbox.queue_text(["Parece que essa ponte pode ser consertada."])
	triggered = true

func _on_textbox_text_finish():
	if triggered:
		textbox.display_choice("Você quer consertar?", ["Sim", "Não"])

func _on_textbox_choise_closed():
	if triggered:
		match(textbox.get_choice()):
			0:
				bridged.visible = true
