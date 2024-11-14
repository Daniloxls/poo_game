extends "res://scripts/interact.gd"

func _ready():
	nome = "Arbusto"
	codigo = {}
	metodos = {
	"1" : ["boolean abrir_caminho(Obstaculo arbusto){"],
	"2" : ["\tboolean caminho;"] ,
	"3" : ["\t//Use o objeto arbusto para chamar seu método"],
	"0": ["\tif (){", 5, 0] ,
	"4" : ["\t\tcaminho = true\n\t}"],
	"5" : ["\telse{"],
	"6" : ["\t\tcaminho = false;\n\t}"],
	"7" : ["\treturn caminho;\n}"]
	}

func interaction():
	textbox.queue_text(["Você pode chamar métodos de objetos em outros objetos, para liberar o caminho use o método queimar()"])
