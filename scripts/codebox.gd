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
# 'cursor' é o cursor utilizado para selecionar as variaveis
@onready var cursor = $Cursor
# 'sair' é apenas o texto na parte de baixo da caixa de codigo
@onready var sair = $Sair

# codebox tem acesso ao player e a caixa de texto
@onready var player = get_node("../Player")
@onready var textbox = get_node("../Textbox")

# Estado 'READY' é quando não está mostrando e 'FINISH' é quando está na tela
enum State{
	READY,
	FINISH
}
# Mesmo para o estado do cursor
enum Cursor{
	SHOWING,
	HIDDEN
}
var cursor_state = Cursor.HIDDEN
var cursor_pos
# 'positions' guarda todas as posições de variaveis editaveis
var positions = []
var current_state = State.READY
# 'prop' guarda as propiedades do objeto que está sendo editado em um dicionario
var prop = {}
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
	textbox_container.hide()
	cursor.hide()
	sair.hide()
	prop = {}
	cursor_dict = {}
	positions = []
	
func show_textbox():
	textbox_container.show()
	sair.show()

# Função para mostrar codigo de um objeto, recebe uma string de nome e um dicionario de propiedades
func queue_text(nome, props):
	# Se o nome do objeto é uma string vazia, ele não tem codigo editavel
	if nome == "":
		return
	# Cria uma string vazia
	var next_text = ""
	classname = nome
	next_text += classname+"\n"
	prop = props
	# Itera sobre cada chave do dicionario recebido colocando as propiedades no
	# texto que vai aparecer na caixa de codigo
	for p in prop.keys():
		# Se tem o numero 1 no nome da variavel, quer dizer que ela pode ser editada
		# então adiciona ela 'cursor_dict' e sua posição no 'positions' 
		if "1" in p:
			show_cursor()
			next_text += p.right(len(p) - 1) + " = "+ str(prop[p]) + "\n"
			positions.append(prop.keys().find(p))
			cursor_dict[prop.keys().find(p)] = p
		# Caso contrario só mostra ela como texto
		else:
			next_text += p + " = "+ str(prop[p]) + "\n"
	text_queue.push_back(next_text)
	if cursor_state == Cursor.SHOWING:
		cursor_pos = positions[0]
	
# Função que cria o texto para ser mostrado, depois que o jogador altera
# as variaveis
func update_text(chave, valor):
	var next_text = ""
	next_text += classname+"\n"
	prop[chave] = valor
	for p in prop.keys():
		if "1" in p:
			# Se o 1 está na variavel ele corta ele da string antes de adicionar ela
			# no texto da codebox
			next_text += p.right(len(p) - 1) + " = "+ str(prop[p]) + "\n"
		else:
			next_text += p + " = "+ str(prop[p]) + "\n"
	text_queue.push_back(next_text)
	# Atualiza o texto que está aparecendo
	display_text()
	
	
# Função que atuliza o texto que aparece na codebox
func display_text():
	var next_text =  text_queue.pop_front()
	label.text = next_text
	change_state(State.FINISH)
	player.set_movement(false)
	show_textbox()
	code_open.emit()
	

	
func change_state(next_state):
	current_state = next_state

func show_cursor():
	cursor_state = Cursor.SHOWING
	cursor.show()

func get_props():
	return prop
	

func get_state():
	if current_state == State.READY:
		return "Ready"
	else:
		return ""

# Atualiza a posiçao do cursor com base na variavel 'cursor_pos'
func update_cursor_pos():
	cursor.set_pos_y(67 + (cursor_pos* 36))

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
			if cursor_state == Cursor.SHOWING and !typing:
				if Input.is_action_just_pressed("down"):
					cursor_pos += 1
					if cursor_pos == len(positions):
						cursor_pos = 0
					update_cursor_pos()
				if Input.is_action_just_pressed("up"):
					cursor_pos -= 1
					if cursor_pos == -1:
						cursor_pos = len(positions)-1
					update_cursor_pos()
				# Se tem uma variavel booleana selecionada e aperta para esquerda ou direita
				# ela muda para o inverso do que estava
				if "boolean" in cursor_dict[cursor_pos]:
					if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("left"):
						if prop[cursor_dict[cursor_pos]]:
							update_text(cursor_dict[cursor_pos],false)
						else:
							update_text(cursor_dict[cursor_pos],true)
				#A variavel int tambem é editada apertando para esquerda e direita
				# direita aumenta o valor da variavel e esquerda diminui
				if "int" in cursor_dict[cursor_pos]:
					if Input.is_action_just_pressed("right"):
						update_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]]+1)
					if Input.is_action_just_pressed("left"):
						update_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]]-1)
				# Se uma string está selecionada e aperta enter, entra no modo de digitar
				if "String" in cursor_dict[cursor_pos]:
					if Input.is_action_just_pressed("enter"):
						typing = true;
				# Se o jogador aperta 'X' ele fecha a caixa de codigo
				if Input.is_action_just_pressed("exit"):
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
					update_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]].left(len(prop[cursor_dict[cursor_pos]]) - 1))
				if Input.is_action_just_pressed("a"):
					update_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]] + "a")
				if Input.is_action_just_pressed("b"):
					update_text(cursor_dict[cursor_pos],prop[cursor_dict[cursor_pos]] + "b")
				
				if Input.is_action_just_pressed("c"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "c")

				if Input.is_action_just_pressed("d"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "d")

				if Input.is_action_just_pressed("e"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "e")

				if Input.is_action_just_pressed("f"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "f")

				if Input.is_action_just_pressed("g"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "g")

				if Input.is_action_just_pressed("h"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "h")

				if Input.is_action_just_pressed("i"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "i")

				if Input.is_action_just_pressed("j"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "j")

				if Input.is_action_just_pressed("k"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "k")

				if Input.is_action_just_pressed("l"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "l")

				if Input.is_action_just_pressed("m"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "m")

				if Input.is_action_just_pressed("n"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "n")

				if Input.is_action_just_pressed("o"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "o")

				if Input.is_action_just_pressed("p"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "p")

				if Input.is_action_just_pressed("q"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "q")

				if Input.is_action_just_pressed("r"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "r")

				if Input.is_action_just_pressed("s"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "s")

				if Input.is_action_just_pressed("t"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "t")

				if Input.is_action_just_pressed("u"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "u")

				if Input.is_action_just_pressed("v"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "v")

				if Input.is_action_just_pressed("w"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "w")

				if Input.is_action_just_pressed("x"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "x")

				if Input.is_action_just_pressed("y"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "y")

				if Input.is_action_just_pressed("z"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + "z")
				
				if Input.is_action_just_pressed("espaço"):
					update_text(cursor_dict[cursor_pos], prop[cursor_dict[cursor_pos]] + " ")
					
				if Input.is_action_just_pressed("enter"):
					typing = false

			
