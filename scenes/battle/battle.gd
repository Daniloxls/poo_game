extends CanvasLayer
#Sinais da batalha

#Sinal de que uma animação terminou e que pode seguir a logica da batalha
signal animation_end
#Sinal que a batalha terminou é usado para que outros nós saibam e façam sua logica pós-batalha
#Como sumir uma barreira depois que o inimigo é derrotado
signal battle_won

signal battle_lost

# 'char_list' é uma lista com todos os nós dos personagens
@onready var char_list = Party.get_children()

@onready var game_audio = $"../Game/AudioPlayer"

# 'menu' é todo o painel de baixo
@onready var menu = $BattleMenu

# 'debug' são informações de debug que podem ser vistas apertando 'A'
@onready var debug = $Debug
 
@onready var background = $Background

@onready var audio_player = $AudioStreamPlayer
@onready var tooltip = $TooltipContiner

@onready var party_menu = $"BattleMenu/PartyContainer/Personagem[ ]/BattleCharContainer"
@onready var inventory = $"../Inventory/BattleInventory"
@onready var battle_inventory = $"../Inventory/BattleInventory/BattleInventoryTabs/Mochila"

@onready var screen_lock: CanvasLayer = $ScreenLock


# Os sprites começam fora da tela e entram com uma transição no começo da batalha
# esses offsets são o quanto eles se movem para chegar nos seus lugares certos
const ENEMY_POS_OFFSET = Vector2(128, 0)
const CHARACTER_POS_OFFSET = Vector2(-300,0)

# 'current_state' estado atual da batalha
var current_state = States.Battle_States.STARTING
# lista que guarda cordenadas da frente dos personagens, para o cursor poder 
# apontar para eles
var character_coords = []
# mesma coisa mas é a parte de trás, para o uso do cursor de turno dessa vez
var character_back_coords = []

var char_index = 0
# 'in_battle' setado como true quando a batalha começa e como false assim que o
# ultimo inimigo morre, se in_battle == false, nenhuma logica da batalha acontece  
var in_battle = false
# lista de cordenadas dos inimigos para serem apontados pelo cursor
var enemy_names = []
# 'enemies' e 'enemy_list' mesma logica do party e char_list, só que para os inimigos.
var enemies 
var enemy_list

# requested_skill_targets guarda quais personagens o jogador deve escolher para usar certa habilidade
var requested_skill_targets = []
# skill_targets são os atuais alvos da skill que está sendo usada
var skill_targets = []

var current_character
var skill_button_id

var held_item : ITEM
# Called when the node enters the scene tree for the first time.
func _ready():
	#Como está sempre instanciada a batalha começa escondida
	hide()
	Textbox.connect("text_finish", _on_text_finish)
	menu.connect("animation_end", on_menu_animation_end)
	battle_inventory.connect("item_use", on_inventory_item_click)
	battle_inventory.connect("close", on_inventory_close)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	debug.text = str(States.Battle_States.keys()[current_state]) + "\n"

# Função que reinicia as variaveis já que batalha sai de cena nunca
func reset_variables():
	current_state = States.Battle_States.ANIMATION
	character_coords = []
	character_back_coords = []
	enemy_names = []
	
# Função usada pra começar a batalha, como argumento é passado uma string com o
# caminho para o grupo de inimigos que está na batalha
func start_battle(enemy_group_path):
	# Carrega o nó com os inimigos, instancia ele e adiciona como filho de Batalha
	#var enemy_group = load(enemy_group_path)
	var enemy_group = load(enemy_group_path)
	var instance = enemy_group.instantiate()
	# Bloqueia movimento do jogador
	PlayerState.set_on_interface(true)
	
	game_audio.stop()
	audio_player.play()
	add_child(instance)
	# Pega variaveis que apontam para o grupo de inimigos e faz a lista com os
	# inimigos
	for char in Party.get_children():
		char.connect("select_targets", on_char_skill_pressed)
		char.connect("button_mouse_in", on_skill_button_mouse_in)
		char.connect("button_mouse_out", on_skill_button_mouse_out)
		char.connect("sprite_clicked", on_char_sprite_clicked)
		char.connect("mouse_in", on_char_sprite_mouse_in)
		char.connect("mouse_out", on_char_sprite_mouse_out)
		char.connect("animation_end", _on_enemy_animation_end)
		char.connect("death", _on_char_death)
		
	enemies = $Enemies
	enemy_list = $Enemies.get_children()
	# liga os sinais de "animation_end" e "death" dos inimigos com as respectivas
	# funções da batalha
	for enemy in enemy_list:
		enemy.connect("animation_end", _on_enemy_animation_end)
		enemy.connect("death", _on_enemy_death)
		enemy_names.append(enemy.get_nome())
		enemy.connect("sprite_clicked", on_enemy_sprite_clicked)
		enemy.connect("mouse_in", on_enemy_sprite_mouse_in)
		enemy.connect("mouse_out", on_enemy_sprite_mouse_out)
		enemy.enemy_ready()
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
	menu.set_characters(Party.get_children())

	menu.add_enemies(enemy_list)
	
	for char in Party.get_children():
		tween.tween_property(char, "position", char.position + CHARACTER_POS_OFFSET, 0.1).set_trans(Tween.TRANS_LINEAR)
		
	# O mesmo para os inimigos
	for enemy in enemy_list:
		tween.tween_property(enemy, "position", enemy.position + ENEMY_POS_OFFSET, 0.1).set_trans(Tween.TRANS_LINEAR)
		
	# delisga o paralelo do tween, então todas as transições ocorrem uma por vez
	tween.set_parallel(false)

	# No final da transição dos personagens o menu aparece
	tween.tween_callback(menu.show)
	tween.tween_callback(player_turn)
# Toda vez que um inimigo morre, ele emite um sinal, quando esse sinal é recebido
# Essa função ocorre
func _on_enemy_death():
	#Percorre a lista de inimigos e remove todos que tem vida 0 ou menor
	for enemy in enemy_list:
		if enemy.get_hp() <= 0:
			var id = enemy_list.find(enemy)
			enemy_list.pop_at(id)
			enemy_names.pop_at(id)
			menu.pop_enemy_button(id)
			#menu.set_monster_names(enemy_names)
			# Se não tem mais inimigos a batalha acaba
			if len(enemy_list) == 0:
				# Emite sinal do final da batalha
				current_state = States.Battle_States.VICTORY
				Textbox.queue_text(["Você venceu!"])
				screen_lock.show()
				battle_won.emit()


# quando uma animação do inimigo acaba ele emite um sinal, quando recebe esse sinal
# Se ainda existem inimigos continua a batalha, caso contrario entra no estado de vitoria
func _on_enemy_animation_end():
	for enemy in enemy_list:
		if enemy.get_state() == 1:
			return
	for char in Party.get_children():
		if char.get_state() == 0:
			char.show_options()
			current_state = States.Battle_States.PLAYER_TURN
			return
	enemy_turn()

# Quando um personagem toma dano o menu transiciona a vida dele como uma animação
# quando essa animação acaba ele executa essa função
func _on_battle_menu_animation_end():
	if current_state == States.Battle_States.DEFEAT:
		lost()
		return
	# Checa se todos os personagens estão mortos, se algum estiver vivo
	# sai da função
	for char in char_list:
		if char.get_hp() > 0:
			current_state = States.Battle_States.PLAYER_TURN
			menu.show_cursor()
			animation_end.emit()
			return
	# Se todos foram derrotados coloca a batalha no estado de derrota
	current_state = States.Battle_States.DEFEAT
	menu.hide()
	animation_end.emit()
	Textbox.queue_text(["Você foi derrotado."])
	screen_lock.show()
	battle_lost.emit()


func player_turn():
	if !in_battle:
		return
	for enemy in enemy_list:
		enemy.reset_state()
	#checa os personagens vivos
	for char in char_list:
		if char.get_state() != 3:
			char.default_state()
	current_state = States.Battle_States.PLAYER_TURN
	for char in char_list:
		if char.get_state() != 3:
			char_index = char_list.find(char)
			char.show_options()
			menu.clear_method_text()
			menu.add_to_method_text(char.get_name())
			break
			
# Cada inimigo deve ter uma função logic() o turno do inimigo é basicamente
# todos os inimigos usando sua logica e com um pequeno intervalo para animações
func enemy_turn():
	
	var tween = create_tween()
	for enemy in enemy_list:
		if enemy.get_state() != 2:
			tween.tween_callback(enemy.logic.bind(char_list, menu))
			tween.tween_interval(2)
	
	tween.tween_callback(player_turn)

# Função para mudar o estado da batalha
func set_selection(select):
	if current_state != States.Battle_States.DEFEAT and current_state != States.Battle_States.VICTORY:
		current_state = select


	
func set_background(bg : CompressedTexture2D):
	background.set_texture(bg)

func _on_text_finish():
	if current_state == States.Battle_States.DEFEAT or current_state == States.Battle_States.VICTORY:
		in_battle = false
		for char in char_list:
			char.reset_position()
			char.set_animation("default")
		enemies.queue_free()
		PlayerState.set_on_interface(false)
		reset_variables()
		screen_lock.hide()
		hide()
		audio_player.stop()
		game_audio.play()
		Textbox.text_finish.disconnect(_on_text_finish)
		menu.hide()

func _on_char_death():
	for char in char_list:
		if char.get_hp() > 0:
			return
	# Se todos foram derrotados coloca a batalha no estado de derrota
	current_state = States.Battle_States.DEFEAT
	menu.hide()
	Textbox.queue_text(["Você foi derrotado."])
	
	
func on_char_skill_pressed(targets, id, char_node):
	current_character = char_node
	skill_button_id = id
	if targets[0] == 4:
		inventory.show()
		current_state = States.Battle_States.BACKPACK
		char_list[char_index].hide_options()
		return
	requested_skill_targets = targets
	current_state = States.Battle_States.SELECTING_TARGET
	tooltip.show()
	tooltip.set_tooltip_label("Selecione " + str(len(targets))
	+ " alvo" + ("s" if len(targets) > 1 else ""))

func on_char_sprite_clicked(id):
	if current_state == States.Battle_States.USING_ITEM:
		if held_item.get_type() == ITEM.Item_type.HEALTH:
			menu.change_char_health(id, char_list[id].gain_health(held_item.HEALTH_RESTORE))
			Party.get_node(str(current_character)).set_acted(true)
			current_state = States.Battle_States.ANIMATION
			skill_targets.clear()
			menu.clear_method_text()
			tooltip.hide()
			battle_inventory.spend_item(held_item)

func on_char_sprite_mouse_in(char_name):
	if current_state == States.Battle_States.USING_ITEM:
		menu.add_to_method_text(char_name)
	
func on_char_sprite_mouse_out():
	if current_state == States.Battle_States.USING_ITEM:
		menu.pop_method_text()
	
func on_skill_button_mouse_in(skill_name):
	if current_state == States.Battle_States.PLAYER_TURN:
		menu.add_to_method_text(skill_name)

func on_skill_button_mouse_out():
	if current_state == States.Battle_States.PLAYER_TURN:
		menu.pop_method_text()

func check_skill():
	if len(skill_targets) == len(requested_skill_targets):
		current_state = States.Battle_States.ANIMATION
		Party.get_node(str(current_character)).execute_skill(skill_button_id, skill_targets)
		tooltip.hide()
		char_list[char_index].hide_options()
		skill_targets.clear()
		menu.clear_method_text()

func on_inventory_item_click(item : ITEM):
	inventory.hide()
	held_item = item
	menu.add_to_method_text(item.ITEM_NAME)
	current_state = States.Battle_States.USING_ITEM
	tooltip.show()
	tooltip.set_tooltip_label("Selecione 1 alvo")
	
func on_inventory_close():
	current_state = States.Battle_States.PLAYER_TURN
	char_list[char_index].show_options()
	menu.pop_method_text()
	
func on_enemy_sprite_clicked(enemy_id):
	if current_state == States.Battle_States.SELECTING_TARGET:
		if requested_skill_targets[len(skill_targets)] == States.Skill_Targets.ENEMY:
			skill_targets.append(enemies.get_child(enemy_id))
			check_skill()

func on_enemy_sprite_mouse_in(enemy_name):
	if current_state == States.Battle_States.SELECTING_TARGET:
		menu.add_to_method_text(enemy_name)
	
func on_enemy_sprite_mouse_out():
	if current_state == States.Battle_States.SELECTING_TARGET:
		menu.pop_method_text()

func on_menu_animation_end():
	pass

func lost():
	in_battle = false
	for char in char_list:
		char.reset_position()
		char.set_animation("default")
	enemies.queue_free()
	PlayerState.set_on_interface(true)
	reset_variables()
	hide()
	audio_player.stop()
	game_audio.play()
	Textbox.text_finish.disconnect(_on_text_finish)
	menu.hide()
