extends "res://scripts/interact.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	nome = "TesteDeForca"
	codigo = {"1boolean trancado": true, "1Material material": "barreira"}
	metodos = {
	"boolean teste_de_forca(int: forca){": [0,0],
	"\tboolean sucesso;": [6,2],
	"\tif (forca > 10){": [5,10],
	"\t\tsucesso = true\n\t}": [0,0],
	"\telse{": [0,0],
	"\t\tsucesso = false;\n\t}" : [0,0],
	"\treturn sucesso;\n}": [1,0]
	}
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
