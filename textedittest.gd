extends Node2D

@onready var flow_container = $FlowContainer

var nome = "TesteDeForca"
var	codigo = {}
var	metodos = {
	"1" : ["boolean teste_de_forca(Personagem jogador){"],
	"2" : ["\tboolean sucesso;"] ,
	"3" : ["\tint forca = jogador.get_forca()"],
	"0": ["\tif (forca > 10){", 5, 10] ,
	"4" : ["\t\tsucesso = true\n\t}"],
	"5" : ["\telse{"],
	"6" : ["\t\tsucesso = false;\n\t}"],
	"7" : ["\treturn sucesso;\n}"]
	}

# Called when the node enters the scene tree for the first time.
func _ready():
	test()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func test():
	for key in metodos.keys():
		var text = TextEdit.new()
		text.text = metodos[key][0]
		text.set_fit_content_height_enabled(true)
		if "0" in key:
			var edit_text = TextEdit.new()
			var close_text = TextEdit.new()
			edit_text.set_fit_content_height_enabled(true)
			close_text.set_fit_content_height_enabled(true)
			
			text.set_editable(false)
			text.set_custom_minimum_size(Vector2(len(metodos[key][0].substr(0, metodos[key][1]))* 10,0))
			
			edit_text.set_editable(true)
			edit_text.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			edit_text.set_custom_minimum_size(Vector2(10,0))
			
			close_text.set_editable(false)
			close_text.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			close_text.set_custom_minimum_size(Vector2(len(metodos[key][0].substr(metodos[key][1], metodos[key][2])) * 10,0))
			
			text.text = metodos[key][0].substr(0, metodos[key][1])
			flow_container.add_child(text)
			edit_text.text = metodos[key][0].substr(metodos[key][1], metodos[key][2])
			flow_container.add_child(edit_text)
			close_text.text = metodos[key][0].substr(metodos[key][1] + metodos[key][2],
				len(metodos[key][0]) - 1 )
			flow_container.add_child(close_text)
		else:
			text.set_editable(false)
			text.set_custom_minimum_size(Vector2(439,0))
			flow_container.add_child(text)
