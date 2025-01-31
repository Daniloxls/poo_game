extends CanvasLayer

#Signals são emitidos e captados por outros objetos que estão conectados com esse
# e ouvindo pelo sinal

# 'text_finish' é emitido quando todo o texto da caixa de texto foi exibido
signal text_finish

# 'choice_closed' é emitido quando uma escolha é feita
signal choise_closed

#Velocidade base que o texto é exibido
const CHAR_READ_RATE = 0.03

# Posição inicial do curor de escolha
const CURSOR_POSITION = Vector2(946,340)

# 'textbox_container' guarda todo conteudo da caixa de texto
@onready var textbox_container = $TextboxContainer
# 'label' é o que contem o texto da caixa de texto
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label2
# 'choice_container'  guarda todo conteudo da caixa de escolha
@onready var choice_container = $ChoiceContainer
# 'choice_label' é o que contem o texto da caixa de escolha
@onready var choice_label = $ChoiceContainer/MarginContainer/HBoxContainer/Label2
# 'portrait' é a imagem de algum personagem que esteja falando o dialogo
@onready var portrait = $Portrait
# 'cursor' é o sprite de cursor que aparece nas escolhas
@onready var cursor = $Cursor
# 'player' é o acesso que a caixa de texto possui do personagem para poder afeta-lo
@onready var player = get_node("../Level").get_child(0).find_child("Player")
# 'codebox' é o acesso que a caixa de texto tem da caixa de codigo, usado para evitar conflitos
@onready var codebox = get_node("../Codebox")

# 'tween' é um classe muito usada para fazer transições
# recomendo olhar bem as funções desse objeto
@onready var tween = create_tween()

# Possiveis estados da caixa de texto
enum State{
	READY,
	READING,
	FINISH,
	CHOICE
}
# 'current_state' é o estado atual da caixa de texto
var current_state = State.READY

# 'text_queue' é a fila de texto que deve ser exibido pela caixa de texto
var text_queue = []
# 'sprite_queue' fila de sprites que acompanha o texto caso aja algum retrato
# para ser mostrado junto com o texto
var sprite_queue = []

# 'choice_id' variavel que guarda a escolha que o jogador fez
var choice_id = 0

# 'choices' lista de strings que são as escolhas que aparecerão para o jogador
var choices = []

# no ready a caixa só se esconde
func _ready():
	hide_textbox()

#Funcão que limpa o texto e esconde todos os componentes da caixa de textp
func hide_textbox():
	label.text = ""
	textbox_container.hide()
	choice_container.hide()
	cursor.hide()
	
#Chamada quando se quer saber se pode aparecer um novo dialogo,
# se a caixa não estiver ready retorna string vazia
func get_state():
	if current_state == State.READY:
		return "Ready"
	else:
		return ""
	
func show_textbox():
	textbox_container.show()
	
#funcão que funciona como sinal de que o tween terminou de transicionar o texto
func on_tween_finished():
	change_state(State.FINISH)

#mesma coisa mas muda o estado para o jogador poder escolher uma opção antes de fechar
func on_choice_tween_finished():
	change_state(State.CHOICE)
	choice_container.show()
	cursor.show()
	
#Função que recebe uma lista de strings e coloca todos na fila da caixa de texto
# para serem mostrados
func queue_text(next_text):
	for i in next_text:
		text_queue.push_back(i)
		sprite_queue.push_back("")
	
#Mesma função mas tambem recebe sprites de retrato para colocar na fila de sprites
func queue_char_text(next_text, next_sprite):
	for i in next_text:
		text_queue.push_back(i)
	for i in next_sprite:
		sprite_queue.push_back(i)

#Como fica relativamente dificil colocar escolhas na fila.
# a escolha é somente uma string text e uma lista de strings com escolhas
# A caixa de texto mostra o texto como qualquer outro e mostara a escolha
func display_choice(text, choices):
	var next_text =  text
	tween = create_tween()
	tween.tween_property(label, "visible_ratio",1.0, len(next_text) * CHAR_READ_RATE)
	label.text = next_text
	change_state(State.READING)
	if player.get_state() == States.Player_State.FREE:
		player.set_state(States.Player_State.ON_DIALOGUE)
	show_textbox()
	portrait.hide()
	label.visible_ratio = 0.0
	tween.play()
	tween.tween_callback(on_choice_tween_finished)
	set_choices(choices)

# Função que pega fim da fila de texto e mostra na caixa de texto
func display_text():
	# Pega string e sprite do proximo dialogo
	var next_text =  text_queue.pop_front()
	var next_sprite = sprite_queue.pop_front()
	
	# instancia o tween para transições
	tween = create_tween()
	
	# faz o texto aparecer aos poucos
	tween.tween_property(label, "visible_ratio",1.0, len(next_text) * CHAR_READ_RATE)
	
	# muda o texto da label para o texto recebido
	label.text = next_text
	
	# se não tem sprite, esconde o retrato de personagem
	# caso contrario carrega e mostra ele
	if next_sprite == "":
		portrait.hide()
	else:
		portrait.texture = load(next_sprite)
		portrait.show()
	
	# enquanto o tween não acabar ou o player não apertar 'Z' ela fica no estado Reading
	# e o player fica parado enquanto estiver em um dialogo
	change_state(State.READING)
	if player.current_state == States.Player_State.FREE:
		print("entrou no diálogo")
		player.current_state = States.Player_State.ON_DIALOGUE
		print(player.current_state)
	show_textbox()
	#Esconde o texto e faz o tween transicionar ele até ficar todo mostrado
	label.visible_ratio = 0.0
	tween.play()
	tween.tween_callback(on_tween_finished)
	
func change_state(next_state):
	current_state = next_state

# Formata a lista de string que são as escolhas para que fiquem em uma string só
# e coloca esa na label da caixa de escolhas
func set_choices(choice_list):
	choices = choice_list
	var escolhas = ""
	for i in choices:
		escolhas += i + "\n"
	choice_label.text = escolhas

# Atualiza a posição do cursor de escolha
func set_cursor_pos(pos):
	cursor.set_position(pos)
	
# Retorna escolha que o jogador fez
func get_choice():
	var id = choice_id
	choice_id = 0
	return id
	

func _process(delta):
	#Comportamento da caixa de texto depende do seu estado
	match current_state:
		State.READY:
			# Se estiver ready e com textos na sua fila ela mostra esse texto
			if !text_queue.is_empty():
				display_text()
		State.READING:
			# Reading é o estado que ela fica quando o texto está aparecendo
			# Se o jogador apertar 'Z' encerra a transição
			# e coloca o estado em finish ou choice se tiver uma escolha a ser feita
			if Input.is_action_just_pressed("interact"):
				if len(choices) == 0:
					label.visible_ratio = 1.0
					tween.stop()
					change_state(State.FINISH)
				else:
					label.visible_ratio = 1.0
					tween.stop()
					choice_container.show()
					cursor.show()
					change_state(State.CHOICE)
		State.FINISH:
		#Estado que todo o texto está mostrado se apertar 'Z' e ainda tiver textos
		# na fila mostra o proximo, caso contrario esconde a caixa e muda o estado para ready
			if Input.is_action_just_pressed("interact"):
				if !text_queue.is_empty():
					display_text()
				else:
					change_state(State.READY)
					if player.get_state() == States.Player_State.ON_DIALOGUE:
						player.call_deferred("set_state", States.Player_State.FREE)
					textbox_container.hide()
					portrait.hide()
					text_finish.emit()
					#if player.current_state != Player.State.ON_INTERFACE and player.current_state != Player.State.ON_SCENE:
						#player.current_state = Player.State.FREE
		#Se o estado é Choice o jogador pode mover o cursor para cima ou para baixo
		#Apertando 'Z' o jogador escolhe, então a caixa de texto fecha
		# e o sinal de escolha é emitido
		State.CHOICE:
			if Input.is_action_just_pressed("down"):
				choice_id += 1
				if choice_id >= len(choices):
					choice_id = 0
				set_cursor_pos(CURSOR_POSITION + Vector2(0, 36) * choice_id)
			if Input.is_action_just_pressed("up"):
				choice_id -= 1
				if choice_id < 0:
					choice_id = len(choices) - 1
				set_cursor_pos(CURSOR_POSITION + Vector2(0, 36) * choice_id)
			if Input.is_action_just_pressed("interact"):
				change_state(State.READY)
				if player.get_state() == States.Player_State.ON_DIALOGUE:
					player.set_state(States.Player_State.FREE)
				textbox_container.hide()
				choice_container.hide()
				set_cursor_pos(CURSOR_POSITION)
				cursor.hide()
				portrait.hide()
				choise_closed.emit()
				choices = []
