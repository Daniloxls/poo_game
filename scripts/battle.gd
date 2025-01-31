extends CanvasLayer
#Sinais da batalha

#Sinal de que uma animação terminou e que pode seguir a logica da batalha
signal animation_end
#Sinal que a batalha terminou é usado para que outros nós saibam e façam sua logica pós-batalha
#Como sumir uma barreira depois que o inimigo é derrotado
signal battle_won

signal battle_lost

# 'party' é o nó que contem todos os personagens
@onready var party = get_node("../Inventory/Party")
# 'char_list' é uma lista com todos os nós dos personagens
@onready var char_list = get_node("../Inventory/Party").get_children()
# 'inventory' é a versão para batalha do inventario
@onready var inventory = get_node("../Inventory/BattleItemMenu")
# 'player' é somente usado para bloquear o movimento do jogador no mapa
@onready var player = get_node("../Level").get_child(0).find_child("Player")

@onready var game_audio = $"../AudioPlayer"

# 'menu' é todo o painel de baixo
@onready var menu = $BattleMenu
# 'cursor' esse é o cursor que serve para mirar ataques
@onready var cursor = $Cursor
# 'turn_cursor' esse é o cursor que marca de quem é a vez
@onready var turn_cursor = $TurnCursor
# 'debug' são informações de debug que podem ser vistas apertando 'A'
@onready var debug = $Debug
 
@onready var background = $Background

@onready var audio_player = $AudioStreamPlayer

@onready var textbox = $"../Textbox"

# Os sprites começam fora da tela e entram com uma transição no começo da batalha
# esses offsets são o quanto eles se movem para chegar nos seus lugares certos
const ENEMY_POS_OFFSET = Vector2(128, 0)
const CHARACTER_POS_OFFSET = Vector2(300,0)

# possiveis estados da batalha, talvez possa ser reduzido.
enum Selecting{
	ITEM_ALLIE,
	ITEM_ENEMY,
	ITEM_ALL_ALLIES,
	ITEM_ALL_ENEMIES,
	ITEM_ALL,
	NONE,
	STARTING,
	ACTION,
	ENEMY,
	ALLIE,
	ALL_ALLIES,
	ALL_ENEMIES,
	MENU,
	ANIMATION,
	ENEMY_PHASE,
	VICTORY,
	DEFEAT,
	OTHER
}
# 'current_selection' estado atual da batalha
var current_selection = Selecting.STARTING
# lista que guarda cordenadas da frente dos personagens, para o cursor poder 
# apontar para eles
var character_coords = []
# mesma coisa mas é a parte de trás, para o uso do cursor de turno dessa vez
var character_back_coords = []
# personagem aliado que está sendo apontado pelo cursor
var char_index = 0
# 'char_turn' qual personagem está agindo agora
var char_turn = -1
# 'in_battle' setado como true quando a batalha começa e como false assim que o
# ultimo inimigo morre, se in_battle == false, nenhuma logica da batalha acontece  
var in_battle = false
# lista de cordenadas dos inimigos para serem apontados pelo cursor
var enemy_coords = []
var enemy_names = []
var enemy_index = 0

# 'enemies' e 'enemy_list' mesma logica do party e char_list, só que para os inimigos.
var enemies 
var enemy_list

# Called when the node enters the scene tree for the first time.
func _ready():
	#Como está sempre instanciada a batalha começa escondida
	hide()
	textbox.connect("text_finish", _on_text_finish)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	read_input()
	debug.text = str(Selecting.keys()[current_selection]) + "\n"
	# checa se todos os personagens agiram, para dar a vez para os inimigos
	if current_selection == Selecting.ACTION and char_turn >= len(char_list):
		set_selection(Selecting.ENEMY_PHASE)
		char_turn = -1
		char_turn = update_char_turn()
		enemy_turn()
		
# Função que reinicia as variaveis já que batalha sai de cena nunca
func reset_variables():
	current_selection = Selecting.ANIMATION
	character_coords = []
	character_back_coords = []
	char_index = 0
	char_turn =  -1
	enemy_coords = []
	enemy_names = []
	enemy_index = 0
	
func select_enemy():
	current_selection = Selecting.ENEMY

# Função usada pra começar a batalha, como argumento é passado uma string com o
# caminho para o grupo de inimigos que está na batalha
func start_battle(enemy_group_path):
	# Carrega o nó com os inimigos, instancia ele e adiciona como filho de Batalha
	var enemy_group = load(enemy_group_path)
	var instance = enemy_group.instantiate()
	# Bloqueia movimento do jogador
	player.set_state(States.Player_State.ON_BATTLE)
	
	game_audio.stop()
	audio_player.play()
	add_child(instance)
	# Pega variaveis que apontam para o grupo de inimigos e faz a lista com os
	# inimigos
	enemies = $Enemies
	enemy_list = $Enemies.get_children()
	# liga os sinais de "animation_end" e "death" dos inimigos com as respectivas
	# funções da batalha
	for enemy in enemy_list:
		enemy.connect("animation_end", _on_enemy_animation_end)
		enemy.connect("death", _on_enemy_death)
	# aparece o cenario da batalha
	show()
	# cria um tween para fazer as transições de começo
	var tween = create_tween()
	in_battle = true
	# esconde o menu
	menu.hide()
	# coloca todas as transições a seguir para ocorrer em paralelo
	tween.set_parallel()
	# Seta todas as informações dos personagens no menu e transiciona os sprites
	# para dentro do cenario
	for char in char_list:
		tween.tween_property(char, "position", char.position - CHARACTER_POS_OFFSET, 0.1).set_trans(Tween.TRANS_LINEAR)
		menu.set_character_name(char_index, char.get_nome())
		menu.update_health_instant(char_index, char.get_health_percentage())
		menu.update_mana_slow(char_index, char.get_mp())
		menu.show_char_status(char_index)
		char_index +=1
	# O mesmo para os inimigos
	for enemy in enemy_list:
		tween.tween_property(enemy, "position", enemy.position + ENEMY_POS_OFFSET, 0.1).set_trans(Tween.TRANS_LINEAR)
		enemy_names.append(enemy.get_nome())
	# delisga o paralelo do tween, então todas as transições ocorrem uma por vez
	tween.set_parallel(false)
	# Seta o nome dos inimigos no menu
	menu.set_monster_names(enemy_names)
	# No final da transição dos personagens o menu aparece
	tween.tween_callback(menu.show)
	# E quando os personagens estivem em suas posições pega as coordenadas deles
	tween.tween_callback(get_entity_positions)
	# Volta o index ao inicial
	char_index = -1
	char_index = update_char_index_down()
	char_turn = update_char_turn()
	# Coloca o cursor de turno na posição do personagem que vai agir primeiro
	tween.tween_callback(update_turn_cursor_position)
	
	
func read_input():
	# Mostra informações de debug
	if Input.is_action_just_pressed("a"):
		#debug.show()
		pass
	if in_battle:
		# 'Selecting.ACTION' o jogador está escolhendo uma opção entre
		# Lutar, Item, Função, etc.
		if current_selection == Selecting.ACTION:
			if Input.is_action_just_pressed("up"):
				menu.move_cursor_up()
			elif Input.is_action_just_pressed("down"):
				menu.move_cursor_down()
			# Quando o jogador aperta 'Z', confere onde está o cursor e muda para
			# o estado apropiado
			elif Input.is_action_just_pressed("interact"):
					match(menu.get_cursor_pos()):
						# Lutar
						0:
							menu.hide_cursor()
							current_selection = Selecting.ENEMY
							cursor.set_flip_h(true)
							cursor.show()
							cursor.set_position(enemy_coords[0])
						# Provisorio: aqui vão ser as magias, no jogo chamadas de funções
						1:
							menu.hide_cursor()
							current_selection = Selecting.ALLIE
							cursor.set_flip_h(false)
							cursor.show()
							cursor.set_position(character_coords[char_index])
						# Item
						2:
							pass
							#menu.hide_cursor()
							#current_selection = Selecting.MENU
							#inventory.aparecer()
		
		
		# Se selecionou atacar deve escolher um inimigo
		elif current_selection == Selecting.ENEMY:
			if Input.is_action_just_pressed("up"):
				if enemy_index == 0:
					enemy_index = len(enemy_coords) - 1
				else:
					enemy_index -= 1
				cursor.set_position(enemy_coords[enemy_index])
			elif Input.is_action_just_pressed("down"):
				if enemy_index == (len(enemy_coords) - 1):
					enemy_index = 0
				else:
					enemy_index += 1
				cursor.set_position(enemy_coords[enemy_index])
			# Quando escolhe o inimigo
			elif Input.is_action_just_pressed("interact"):
				#Aqui deve entrar a função de ataque do personagem atual
				enemy_list[enemy_index].lose_health(randi_range(8, 12))
				#Muda para animação
				current_selection = Selecting.ANIMATION
				cursor.hide()
				char_turn = update_char_turn()
				update_turn_cursor_position()
			# Se o jogador apertar 'X' ele volta para seleção de ação 
			elif Input.is_action_just_pressed("exit"):
				current_selection = Selecting.ACTION
				cursor.hide()
				menu.show_cursor()
		
		
		#Você vem parar aqui se escolher a segunda opção na batalha
		# A maior parte aqui é teste para ver se a logica está funcionando
		elif current_selection == Selecting.ALLIE:
			if Input.is_action_just_pressed("up"):
				char_index = update_char_index_up()
				cursor.set_position(character_coords[char_index])
			elif Input.is_action_just_pressed("down"):
				char_index = update_char_index_down()
				cursor.set_position(character_coords[char_index])
			elif Input.is_action_just_pressed("interact"):
				menu.update_health_slow(char_index, char_list[char_index].lose_health(randi_range(8, 12)))
				current_selection = Selecting.ANIMATION
			elif Input.is_action_just_pressed("exit"):
				current_selection = Selecting.ACTION
				cursor.hide()
				menu.show_cursor()
		
		# Aqui é quando o jogador está no inventario
		elif current_selection == Selecting.MENU:
			if Input.is_action_just_pressed("exit"):
				current_selection = Selecting.ACTION
				inventory.esconder()
				menu.show_cursor()
			# Quando um item é escolhido, ele retorna em qual tipo de personagem
			# esse item pode ser usado e então ele vai para o Selecting apropiado
			elif Input.is_action_just_pressed("interact"):
				current_selection = inventory.get_item_selected()
				inventory.esconder()
				if current_selection == Selecting.NONE:
					current_selection =Selecting.MENU
					inventory.aparecer()
					#Tocar som de não pode
		
		# Se o item só pode ser usado em aliados, um alido deve ser selecionado
		elif current_selection == Selecting.ITEM_ALLIE:
			if Input.is_action_just_pressed("up"):
				char_index = update_char_index_up()
				cursor.set_position(character_coords[char_index])
			elif Input.is_action_just_pressed("down"):
				char_index = update_char_index_down()
				cursor.set_position(character_coords[char_index])
			elif Input.is_action_just_pressed("interact"):
				# Usar o item no aliado que está sendo selecionado
				pass
			elif Input.is_action_just_pressed("exit"):
				current_selection = Selecting.MENU
				inventory.aparecer()
				cursor.hide()
				
# Função que pega as coordenadas dos sprites dos personagens e dos inimigos
# E salva elas nas listas apropiadas
# Faz uns calculos com o tamanho do sprite e a posição onde ele está
func get_entity_positions():
	for char in char_list:
		character_coords.append(Vector2(party.get_position().x*0.94,party.get_position().y) + char.get_cursor_pos())
		character_back_coords.append(Vector2(party.get_position().x*1.02,party.get_position().y) + char.get_turn_cursor_pos())


# Toda vez que um inimigo morre, ele emite um sinal, quando esse sinal é recebido
# Essa função ocorre
func _on_enemy_death():
	#Percorre a lista de inimigos e remove todos que tem vida 0 ou menor
	for enemy in enemy_list:
		if enemy.get_hp() <= 0:
			var id = enemy_list.find(enemy)
			enemy_list.pop_at(id)
			enemy_names.pop_at(id)
			enemy_coords.pop_at(id)
			menu.set_monster_names(enemy_names)
			# Se não tem mais inimigos a batalha acaba
			if len(enemy_list) == 0:
				# Emite sinal do final da batalha
				current_selection = Selecting.VICTORY
				textbox.queue_text(["Você venceu!"])
				battle_won.emit()

# quando uma animação do inimigo acaba ele emite um sinal, quando recebe esse sinal
# Se ainda existem inimigos continua a batalha, caso contrario entra no estado de vitoria
func _on_enemy_animation_end():
	cursor.hide()
	if len(enemy_list) > 0:
		current_selection = Selecting.ACTION
		enemy_index = 0
		menu.show_cursor()
		cursor.set_position(enemy_coords[0])
	else:
		current_selection = Selecting.VICTORY
		menu.hide()

# Quando um personagem toma dano o menu transiciona a vida dele como uma animação
# quando essa animação acaba ele executa essa função
func _on_battle_menu_animation_end():
	# Checa se todos os personagens estão mortos, se algum estiver vivo
	# sai da função
	for char in char_list:
		if char.get_hp() > 0:
			cursor.hide()
			current_selection = Selecting.ACTION
			menu.show_cursor()
			animation_end.emit()
			return
	# Se todos foram derrotados coloca a batalha no estado de derrota
	current_selection = Selecting.DEFEAT
	menu.hide()
	animation_end.emit()
	textbox.queue_text(["Você foi derrotado."])
	battle_lost.emit()

# 'update_char_index_up' e 'update_char_index_down' servem para mover o cursor
# Ele pula os personagens que estão caidos, se só um personagem estiver vivo ele
# vai retornar o mesmo numero que estava
func update_char_index_up():
	var id = char_index - 1
	if id == -1:
		id = len(char_list)-1
	for i in range(4):
		if char_list[id].is_alive():
			break
		else:
			id -= 1
			if id == -1:
				id = len(char_list)-1
	return id
	
func update_char_index_down():
	var id = char_index + 1
	if id == len(char_list):
		id = 0
	for i in range(4):
		if char_list[id].is_alive():
			break
		else:
			id += 1
			if id == len(char_list):
				id = 0
	return id

# 'update_char_turn' faz o mesmo só que para o turno, ele passa o turno para o 
# proximo personagem que está vivo ainda
func update_char_turn():
	if !in_battle:
		return -1
	var id = char_turn + 1
	if id == len(char_list):
		return id
	for i in range(4):
		if char_list[id].is_alive():
			break
		else:
			id += 1
			if id == len(char_list):
				return id
	return id
	
# Cada inimigo deve ter uma função logic() o turno do inimigo é basicamente
# todos os inimigos usando sua logica e com um pequeno intervalo para animações
func enemy_turn():
	var tween = create_tween()
	for enemy in enemy_list:
		tween.tween_callback(enemy.logic.bind(char_list, menu))
		tween.tween_interval(0.9)
	#Talvez essa linha esteja no lugar errado, testar batalha com 2 ou mais inimigos
	tween.tween_callback(set_selection.bind(Selecting.ACTION))

# Função para mudar o estado da batalha
func set_selection(select):
	if current_selection != Selecting.DEFEAT and current_selection != Selecting.VICTORY:
		current_selection = select

# Função que atualiza posição do cursor de turno
func update_turn_cursor_position():
	if !in_battle:
		return
	if char_turn == len(char_list):
		return
	turn_cursor.set_position(character_back_coords[char_turn])
	
func set_player(player_node):
	player = player_node
	
func set_background(bg : CompressedTexture2D):
	background.set_texture(bg)

func _on_text_finish():
	if current_selection == Selecting.DEFEAT or current_selection == Selecting.VICTORY:
		in_battle = false
		for char in char_list:
			char.reset_position()
			char.set_animation("default")
		enemies.queue_free()
		player.set_on_battle(false)
		player.set_movement(true)
		reset_variables()
		hide()
		audio_player.stop()
		game_audio.play()
		textbox.text_finish.disconnect(_on_text_finish)
		
