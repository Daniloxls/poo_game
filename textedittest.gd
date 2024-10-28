extends Node2D

@onready var var_container = $Panel/FlowContainer2
@onready var method_container = $Panel/FlowContainer

var tema
var intregex = RegEx.new()
var nome = "TesteDeForca"
var codigo = {"1String senha" : "senha123",
	"1int" : 5,
	"boolean": true
	}
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
	tema = load("res://scenes/styles/theme.tres")
	test()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func test():
	var name = TextEdit.new()
	name.text = nome
	name.set_fit_content_height_enabled(true)
	name.set_editable(false)
	name.set_custom_minimum_size(Vector2(478,0))
	name.theme = tema
	method_container.add_child(name)
	
	for p in codigo.keys():
		var text = TextEdit.new()
		text.set_fit_content_height_enabled(true)
		text.theme = tema
		# Se tem o numero 1 no nome da variavel, quer dizer que ela pode ser editada
		# então adiciona ela 'cursor_dict' e sua posição no 'prop_positions' 
		if "1" in p:
			var edit_text = TextEdit.new()
			var close_text = TextEdit.new()
			text.text =  p.right(len(p) - 1) + " = "
			text.set_custom_minimum_size(Vector2(len(p)* 13,0))
			if "String" in p:
				edit_text.text = "'" + str(codigo[p]) + "'"
				edit_text.set_fit_content_height_enabled(true)
			elif "int" in p:
				edit_text = SpinBox.new()
				edit_text.value = codigo[p]
				text.set_custom_minimum_size(Vector2(len(p)* 18,0))
			elif "boolean" in p:
				edit_text.text = str(codigo[p])
				edit_text.set_fit_content_height_enabled(true)
			
			text.set_editable(false)
			method_container.add_child(text)
			
			edit_text.set_editable(true)
			edit_text.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			edit_text.set_custom_minimum_size(Vector2(478,0) - Vector2(len(p)* 18,0))
			edit_text.theme = tema
			
			
			close_text.set_fit_content_height_enabled(true)
			close_text.set_editable(false)
			close_text.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			close_text.set_custom_minimum_size(Vector2(10,0))
			close_text.theme = tema
			method_container.add_child(edit_text)
		else:
			if "String" in p:
				text.text =  p + " = " + "'" + str(codigo[p]) + "'" + "" 
			else:
				text.text = p + " = "+ str(codigo[p]) + ""
			text.set_editable(false)
			text.set_custom_minimum_size(Vector2(478,0))
			method_container.add_child(text)
				
	for key in metodos.keys():
		var text = TextEdit.new()
		text.text = metodos[key][0]
		text.set_fit_content_height_enabled(true)
		text.theme = tema
		if "0" in key:
			var edit_text = TextEdit.new()
			var close_text = TextEdit.new()
			edit_text.set_fit_content_height_enabled(true)
			close_text.set_fit_content_height_enabled(true)
			
			text.set_editable(false)
			text.set_custom_minimum_size(Vector2(len(metodos[key][0].substr(0, metodos[key][1]))* 20,0))
			
			edit_text.set_editable(true)
			edit_text.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			edit_text.set_custom_minimum_size(Vector2(10,0))
			edit_text.theme = tema
			
			close_text.set_editable(false)
			close_text.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			close_text.set_custom_minimum_size(Vector2(len(metodos[key][0].substr(metodos[key][1], metodos[key][2])) * 10,0))
			close_text.theme = tema
			
			text.text = metodos[key][0].substr(0, metodos[key][1])
			method_container.add_child(text)
			edit_text.text = metodos[key][0].substr(metodos[key][1], metodos[key][2])
			method_container.add_child(edit_text)
			close_text.text = metodos[key][0].substr(metodos[key][1] + metodos[key][2],
				len(metodos[key][0]) - 1 )
			method_container.add_child(close_text)
		else:
			text.set_editable(false)
			text.set_custom_minimum_size(Vector2(478,0))
			method_container.add_child(text)
