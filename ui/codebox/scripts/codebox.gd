extends CanvasLayer

signal codebox_open
signal codebox_close

@onready var var_container = $Panel/FlowContainer2
@onready var method_container = $Panel/FlowContainer
var tema
var intregex = RegEx.new()
var nome
var codigo
var	metodos
var node 
# Called when the node enters the scene tree for the first time.
func _ready():
	tema = load("res://scenes/common/styles/code_theme.tres")
	hide()


	
func depure(selected_node):
	var name = CodeEdit.new()
	show()
	PlayerState.set_on_interface(true)
	name.text = selected_node.get_nome()
	codigo = selected_node.get_codigo()
	metodos = selected_node.get_metodos()
	node = selected_node
	
	for child in method_container.get_children():
		child.free()
		
	name.set_fit_content_height_enabled(true)
	name.set_editable(false)
	name.set_custom_minimum_size(Vector2(478,0))
	name.theme = tema
	method_container.add_child(name)
	
	for p in codigo.keys():
		var text = CodeEdit.new()
		text.set_fit_content_height_enabled(true)
		text.theme = tema
		# Se tem o numero 1 no nome da variavel, quer dizer que ela pode ser editada
		# então adiciona ela 'cursor_dict' e sua posição no 'prop_positions' 
		if "1" in p:
			var edit_text = CodeEdit.new()
			var close_text = CodeEdit.new()
			text.text =  p.right(len(p) - 1) + " = "
			text.set_custom_minimum_size(Vector2(len(p)* 13,0))
			if "String" in p:
				edit_text.text = str(codigo[p])
				edit_text.set_fit_content_height_enabled(true)
			elif "int" in p:
				edit_text = SpinBox.new()
				edit_text.value = codigo[p]
				text.set_custom_minimum_size(Vector2(len(p)* 15,0))
				
			
			text.set_editable(false)
			method_container.add_child(text)
			edit_text.set_editable(true)
			edit_text.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			edit_text.set_custom_minimum_size(Vector2(478,0) - Vector2(len(p)* 18,0))
			
			if "boolean" in p:
				edit_text = Button.new()
				edit_text.set_script(load("res://ui/codebox/scripts/boolean_toggle.gd"))
				edit_text.set_value(codigo[p])
				
			edit_text.theme = tema
			edit_text.set_name(p);
			
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
		var text = CodeEdit.new()
		text.text = metodos[key][0]
		text.set_fit_content_height_enabled(true)
		text.theme = tema
		if "0" in key:
			var edit_text = CodeEdit.new()
			edit_text.set_name(key);
			var close_text = CodeEdit.new()
			edit_text.set_fit_content_height_enabled(true)
			close_text.set_fit_content_height_enabled(true)
			
			text.set_editable(false)
			text.set_custom_minimum_size(Vector2(len(metodos[key][0].substr(0, metodos[key][1]))* 13,0))
			
			edit_text.set_editable(true)
			edit_text.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			edit_text.set_custom_minimum_size(Vector2(10,0))
			edit_text.theme = tema
			
			close_text.set_editable(false)
			close_text.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			close_text.set_custom_minimum_size(Vector2(len(metodos[key][0].substr(metodos[key][1], metodos[key][2])) * 14,0))
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
	codebox_open.emit(node.get_name())

func _on_button_button_up():
	for p in codigo.keys():
		if "1" in p:
			if "int" in p:
				codigo[p] = method_container.get_node(p).get_value()
			elif "String" in p:
				codigo[p] = method_container.get_node(p).get_text()
			elif "boolean" in p:
				codigo[p] = method_container.get_node(p).is_pressed()
	for key in metodos.keys():
		if "0" in key:
			var str_len = len(method_container.get_node(key).get_text())
			var str_code = metodos[key][0].substr(0, metodos[key][1])
			str_code += method_container.get_node(key).get_text()
			str_code += metodos[key][0].substr(metodos[key][1] + metodos[key][2],
				len(metodos[key][0]) - 1 )
			metodos[key][0] = str_code
			metodos[key][2] = str_len
			
	node.set_codigo(codigo)
	node.set_metodos(metodos)
	for child in method_container.get_children():
		child.free()
	hide()
	codebox_close.emit(node.get_name())
	PlayerState.set_on_interface(false)
