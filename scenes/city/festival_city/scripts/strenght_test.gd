extends "res://scripts/interact.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	nome = "TesteDeForca"
	codigo = {}
	metodos = {
	"1" : ["boolean teste_de_forca(Personagem jogador){"],
	"2" : ["\tboolean sucesso;"] ,
	"3" : ["\tint forca = jogador.get_forca()"],
	"0": ["\tif (forca > 10){", 5, 10] ,
	"4" : ["\t\tsucesso = true\n\t}"],
	"5" : ["\telse{"],
	"6" : ["\t\tsucesso = false;\n\t}"],
	"7" : ["\treturn sucesso;\n}"]
	}

# Called every frame. 'delta' is the elapsed time since the previous frame.
