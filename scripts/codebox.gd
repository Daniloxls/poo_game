extends CanvasLayer

# codebox é a caixa de codigo que serve pra editar as propiedades do mundo
# uma das principais mecanicas do jogo

#Sinais emitidos ao abrir e fechar caixa de codigo
signal code_closed
signal code_open

# Como a codebox foi feita como uma copia da textbox, muita coisa foi reaproveitada
# como é o caso do container e da label
@onready var textbox_container = $TextboxContainer
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label2
@onready var method_label = $TextboxContainer/MarginContainer/HBoxContainer/Metodos
# 'cursor' é o cursor utilizado para selecionar as variaveis
@onready var cursor = $Cursor
# 'sair' é apenas o texto na parte de baixo da caixa de codigo
@onready var sair = $Sair
@onready var edit = $Editar
@onready var stop_edit = $Deseditar

@onready var indicator = $Indicator
# codebox tem acesso ao player e a caixa de texto
@onready var player = get_node("../Player")
@onready var textbox = get_node("../Textbox")

# Estado 'READY' é quando não está mostrando e 'FINISH' é quando está na tela
enum State{
	READY,
	FINISH
}

enum Editing{
	PROPS,
	METHODS
}
# Mesmo para o estado do cursor
enum Cursor{
	SHOWING,
	HIDDEN
}
var cursor_state = Cursor.HIDDEN
var cursor_pos
var cursor_id
# 'prop_positions' guarda todas as posições de variaveis editaveis
var prop_positions = []
var method_positions = []
var current_state = State.READY

var current_edit = Editing.PROPS
# 'prop' guarda as propiedades do objeto que está sendo editado em um dicionario
var prop = {}

var self_methods = {}
var selected_text = []
# 'cursor_dict' guarda apenas as propiedades editaveis
var cursor_dict = {}
# 'classname' guarda o nome do objeto
var classname
var text_queue = []
# 'typing' é o estado em que o jogador está editando uma string
var typing = false
func _ready():
	hide_textbox()

# Quando a caixa se esconde reinicia todas as variaveis
func hide_textbox():
	label.text = ""
	method_label.set_text("")
	textbox_container.hide()
	cursor.hide()
	sair.hide()
	prop = {}
	self_methods = {}
	cursor_dict = {}
	prop_positions = []
	method_positions = []
	selected_text = []
func show_textbox():
	textbox_container.show()
	sair.show()

# Função para mostrar codigo de um objeto, recebe uma string de nome e um dicionario de propiedades
func queue_text(nome, props, methods = {}):
	# Se o nome do objeto é uma string vazia, ele não tem codigo editavel
	if nome == "":
		return
	# Cria uma string vazia
	var next_text = ""
	code_open.emit()
	classname = nome
	next_text += classname+"\n"
	prop = props
	self_methods = methods
	# Itera sobre cada chave do dicionario recebido colocando as propiedades no
	# texto que vai aparecer na caixa de codigo
	for p in prop.keys():
		# Se tem o numero 1 no nome da variavel, quer dizer que ela pode ser editada
		# então adiciona ela 'cursor_dict' e sua posição no 'prop_positions' 
		if "1" in p:
			show_cursor()
			if "String" in p:
				next_text +=  p.right(len(p) - 1) + " = " + "'" + str(prop[p]) + "'" + "\n" 
			else:
				next_text += p.right(len(p) - 1) + " = "+ str(prop[p]) + "\n"
			prop_positions.append(prop.keys().find(p))
			cursor_dict[prop.keys().find(p)] = p
		# Caso contrario só mostra ela como texto
		else:
			next_text += p + " = "+ str(prop[p]) + "\n"
	text_queue.push_back(next_text)
	if self_methods:
		var line_skip = 2
		method_label.clear()
		method_label.append_text("//Metodos")
		#var metodos = "//Metodos"
		for key in methods.keys():
			#metodos = metodos + "\n" + methods[key][0]
			if "\n" in methods[key][0]:
				line_skip += 1
			if key[0] == "0":
				show_cursor()
				method_positions.append(len(props.keys()) + methods.keys().find(key) + line_skip)
				cursor_dict[len(props.keys()) + methods.keys().find(key) + line_skip] = key
				method_label.append_text("\n" + methods[key][0].substr(0, methods[key][1]))
				method_label.push_bgcolor(Color.WHITE_SMOKE)
				method_label.push_color(Color("#00004e"))
				method_label.append_text(methods[key][0].substr(methods[key][1], methods[key][2]))
				method_label.pop()
				method_label.pop() 
				method_label.append_text(methods[key][0].substr(methods[key][1] + methods[key][2],
				len(methods[key][0]) - 1 ))
			else:
				method_label.append_text("\n" + methods[key][0])
		#method_label.set_text(metodos)
	if cursor_state == Cursor.SHOWING:
		cursor_id = 0
		if prop_positions:
			cursor_pos = prop_positions[0]
		else:
			cursor_pos = method_positions[0]
			current_edit = Editing.METHODS
			edit.show()
		update_cursor_pos()
	
# Função que cria o texto para ser mostrado, depois que o jogador altera
# as variaveis
func update_prop_text(chave, valor):
	var next_text = ""
	next_text += classname+"\n"
	prop[chave] = valor
	for p in prop.keys():
		if "1" in p:
			if "String" in p:
				next_text +=  p.right(len(p) - 1) + " = " + "'" + str(prop[p]) + "'" + "\n" 
			# Se o 1 está na variavel ele corta ele da string antes de adicionar ela
			# no texto da codebox
			else:
				next_text += p.right(len(p) - 1) + " = "+ str(prop[p]) + "\n"
		else:
			next_text += p + " = "+ str(prop[p]) + "\n"
	text_queue.push_back(next_text)
	# Atualiza o texto que está aparecendo
	display_text()

func update_method_text(chave, valor):
	method_label.clear()
	method_label.append_text("//Metodos")
	self_methods[chave][0] = valor
	for key in self_methods.keys():
		if key[0] == "0":
			show_cursor()
			method_label.append_text("\n" + self_methods[key][0].substr(0, self_methods[key][1]))
			method_label.push_bgcolor(Color.WHITE_SMOKE)
			method_label.push_color(Color("#00004e"))
			method_label.append_text(self_methods[key][0].substr(self_methods[key][1], self_methods[key][2]))
			method_label.pop()
			method_label.pop() 
			method_label.append_text(self_methods[key][0].substr(self_methods[key][1] + self_methods[key][2],
			len(self_methods[key][0]) - 1 ))
		else:
			method_label.append_text("\n" + self_methods[key][0])
		#method_label.append_text("\n" + self_methods[key][0])
	
	
# Função que atuliza o texto que aparece na codebox
func display_text():
	var next_text =  text_queue.pop_front()
	label.text = next_text
	change_state(State.FINISH)
	player.set_movement(false)
	show_textbox()
	

	
func change_state(next_state):
	current_state = next_state

func show_cursor():
	cursor_state = Cursor.SHOWING
	cursor.show()
	
func get_props():
	return prop
	
func get_methods():
	return self_methods
	
func get_state():
	if current_state == State.READY:
		return "Ready"
	else:
		return ""

# Atualiza a posiçao do cursor com base na variavel 'cursor_pos'
func update_cursor_pos():
	cursor.set_pos_y(76 + (cursor_pos* 32.5))

# Função que roda o tempo todo
func _process(delta):
	match current_state:
		# Se a caixa não está aparecendo e tem codigo para ser mostrado ela aparece
		State.READY:
			if !text_queue.is_empty():
				display_text()
		# Se está aparecendo a caixa e o cursor aparece, então ele pode mexer o cursor
		# para cima e baixo para escolher a variavel que vai ser editada
		State.FINISH:
			if current_edit == Editing.PROPS:
				if cursor_state == Cursor.SHOWING and !typing:
					if Input.is_action_just_pressed("down"):
						cursor_id += 1
						if cursor_id == len(prop_positions):
							cursor_id = 0
							if method_positions:
								edit.show()
								current_edit = Editing.METHODS
								cursor_pos = method_positions[cursor_id]
							else:
								cursor_pos = prop_positions[cursor_id]
						else:
							cursor_pos = prop_positions[cursor_id]
						update_cursor_pos()
					if Input.is_action_just_pressed("up"):
						cursor_id -= 1
						if cursor_id == -1:
							if method_positions:
								edit.show()
								cursor_id = len(method_positions) - 1
								current_edit = Editing.METHODS
								cursor_pos = method_positions[cursor_id]
							else:
								cursor_id = len(prop_positions) - 1
								cursor_pos = prop_positions[cursor_id]
						else:
							cursor_pos = prop_positions[cursor_id]
						update_cursor_pos()
					# Se tem uma variavel booleana selecionada e aperta para esquerda ou direita
					# ela muda para o inverso do que estava
					if "boolean" in cursor_dict[cursor_pos]:
						if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("left"):
							if prop[cursor_dict[cursor_pos]]:
								update_prop_text(cursor_dict[cursor_pos],false)
							else:
								update_prop_text(cursor_dict[cursor_pos],true)
					#A variavel int tambem é editada apertando para esquerda e direita
					# direita aumenta o valor da variavel e esquerda diminui
					if "int" in cursor_dict[cursor_pos]:
						if Input.is_action_just_pressed("right"):
							update_prop_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]]+1)
						if Input.is_action_just_pressed("left"):
							update_prop_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]]-1)
					# Se uma string está selecionada e aperta enter, entra no modo de digitar
					if "String" in cursor_dict[cursor_pos]:
						edit.show()
						if Input.is_action_just_pressed("enter"):
							typing = true;
							edit.hide()
							stop_edit.show()
					# Se o jogador aperta 'X' ele fecha a caixa de codigo
					if Input.is_action_just_pressed("exit"):
						edit.hide()
						cursor_pos = 0
						update_cursor_pos()
						change_state(State.READY)
						code_closed.emit()
						if textbox.get_state() == "Ready":
							player.set_movement(true)
						hide_textbox()
				# Se o jogador está editando uma string ele vai poder digitar o que quiser
				# E só sai do modo de edição de string quando apertar Enter
				elif typing:
					if Input.is_action_just_pressed("backspace"):
						update_prop_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]].left(len(prop[cursor_dict[cursor_pos]]) - 1))
					if Input.is_action_just_pressed("a"):
						update_prop_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]] + "a")
					if Input.is_action_just_pressed("b"):
						update_prop_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]] + "b")
					
					if Input.is_action_just_pressed("c"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "c")

					if Input.is_action_just_pressed("d"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "d")

					if Input.is_action_just_pressed("e"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "e")

					if Input.is_action_just_pressed("f"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "f")

					if Input.is_action_just_pressed("g"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "g")

					if Input.is_action_just_pressed("h"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "h")

					if Input.is_action_just_pressed("i"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "i")

					if Input.is_action_just_pressed("j"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "j")

					if Input.is_action_just_pressed("k"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "k")

					if Input.is_action_just_pressed("l"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "l")

					if Input.is_action_just_pressed("m"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "m")

					if Input.is_action_just_pressed("n"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "n")

					if Input.is_action_just_pressed("o"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "o")

					if Input.is_action_just_pressed("p"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "p")

					if Input.is_action_just_pressed("q"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "q")

					if Input.is_action_just_pressed("r"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "r")

					if Input.is_action_just_pressed("s"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "s")

					if Input.is_action_just_pressed("t"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "t")

					if Input.is_action_just_pressed("u"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "u")

					if Input.is_action_just_pressed("v"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "v")

					if Input.is_action_just_pressed("w"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "w")

					if Input.is_action_just_pressed("x"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "x")

					if Input.is_action_just_pressed("y"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "y")

					if Input.is_action_just_pressed("z"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "z")
					
					if Input.is_action_just_pressed("espaço"):
						update_prop_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + " ")
						
					if Input.is_action_just_pressed("enter"):
						typing = false
						edit.show()
						stop_edit.hide()
			elif current_edit == Editing.METHODS:
				if cursor_state == Cursor.SHOWING and !typing:
					# Se o jogador aperta 'X' ele fecha a caixa de codigo
					if Input.is_action_just_pressed("exit"):
						cursor_pos = 0
						edit.hide()
						update_cursor_pos()
						change_state(State.READY)
						code_closed.emit()
						if textbox.get_state() == "Ready":
							player.set_movement(true)
						hide_textbox()
						
					if Input.is_action_just_pressed("down"):
						cursor_id += 1
						if cursor_id == len(method_positions):
							cursor_id = 0
							if prop_positions:
								edit.hide()
								current_edit = Editing.PROPS
								cursor_pos = prop_positions[cursor_id]
							else:
								cursor_pos = method_positions[cursor_id]
						else:
							cursor_pos = method_positions[cursor_id]
						update_cursor_pos()
					if Input.is_action_just_pressed("up"):
						cursor_id -= 1
						if cursor_id == -1:
							if prop_positions:
								edit.hide()
								cursor_id = len(prop_positions) - 1
								current_edit = Editing.PROPS
								cursor_pos = prop_positions[cursor_id]
							else:
								cursor_id = len(method_positions) - 1
								cursor_pos = method_positions[cursor_id]
						else:
							cursor_pos = method_positions[cursor_id]
						update_cursor_pos()
					
					if Input.is_action_just_pressed("enter"):
						typing = true;
						edit.hide()
						stop_edit.show()
						selected_text = []
						selected_text.append(self_methods[cursor_dict[cursor_pos]][0].substr(0,
						self_methods[cursor_dict[cursor_pos]][1]))
						selected_text.append(self_methods[cursor_dict[cursor_pos]][0].substr(
						self_methods[cursor_dict[cursor_pos]][1],
						self_methods[cursor_dict[cursor_pos]][2]))
						selected_text.append(self_methods[cursor_dict[cursor_pos]][0].substr(
						self_methods[cursor_dict[cursor_pos]][1] + self_methods[cursor_dict[cursor_pos]][2],
						len(self_methods[cursor_dict[cursor_pos]][0]) - 1))
						
				elif typing:
					if Input.is_action_just_pressed("backspace"):
						if self_methods[cursor_dict[cursor_pos]][2] > 0:
							selected_text[1] = selected_text[1].left(len(selected_text[1]) - 1)
							self_methods[cursor_dict[cursor_pos]][2] -= 1
					if Input.is_action_just_pressed("a"):
						selected_text[1] += "a"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("b"):
						selected_text[1] += "b"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("c"):
						selected_text[1] += "c"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("d"):
						selected_text[1] += "d"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("e"):
						selected_text[1] += "e"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("f"):
						selected_text[1] += "f"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("g"):
						selected_text[1] += "g"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("h"):
						selected_text[1] += "h"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("i"):
						selected_text[1] += "i"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("j"):
						selected_text[1] += "j"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("k"):
						selected_text[1] += "k"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("l"):
						selected_text[1] += "l"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("m"):
						selected_text[1] += "m"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("n"):
						selected_text[1] += "n"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("o"):
						selected_text[1] += "o"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("p"):
						selected_text[1] += "p"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("q"):
						selected_text[1] += "q"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("r"):
						selected_text[1] += "r"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("s"):
						selected_text[1] += "s"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("t"):
						selected_text[1] += "t"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("u"):
						selected_text[1] += "u"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("v"):
						selected_text[1] += "v"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("w"):
						selected_text[1] += "w"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("x"):
						selected_text[1] += "x"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("y"):
						selected_text[1] += "y"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("z"):
						selected_text[1] += "z"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("0") and !(Input.is_action_pressed("run")):
						selected_text[1] += "0"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("1"):
						selected_text[1] += "1"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("2"):
						selected_text[1] += "2"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("3"):
						selected_text[1] += "3"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("4"):
						selected_text[1] += "4"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("5"):
						selected_text[1] += "5"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("6"):
						selected_text[1] += "6"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("7"):
						selected_text[1] += "7"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("8"):
						selected_text[1] += "8"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("9") and !(Input.is_action_pressed("run")):
						selected_text[1] += "9"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					
					if Input.is_action_just_pressed("dot"):
						selected_text[1] += "."
						self_methods[cursor_dict[cursor_pos]][2] += 1
					
					if Input.is_action_just_pressed("<"):
						selected_text[1] += "<"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed(">"):
						selected_text[1] += ">"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("("):
						selected_text[1] += "("
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed(")"):
						selected_text[1] += ")"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("+"):
						selected_text[1] += "+"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("-"):
						selected_text[1] += "-"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("*"):
						selected_text[1] += "*"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("divide"):
						selected_text[1] += "/"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("espaço"):
						selected_text[1] += " "
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_action_just_pressed("'"):
						selected_text[1] += "'"
						self_methods[cursor_dict[cursor_pos]][2] += 1
					if Input.is_anything_pressed():
						update_method_text(cursor_dict[cursor_pos], selected_text[0] + selected_text[1] + selected_text[2])
					if Input.is_action_just_pressed("enter"):
						typing = false
						edit.show()
						stop_edit.hide()
					pass

			
