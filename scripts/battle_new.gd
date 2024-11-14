extends CanvasLayer
#
#class_name Battle
#
##Sinal de que uma animação terminou e que pode seguir a logica da batalha
#signal animation_end
##Sinal que a batalha terminou é usado para que outros nós saibam e façam sua logica pós-batalha
##Como sumir uma barreira depois que o inimigo é derrotado
#signal battle_won
#
#signal battle_lost
#
## 'party' é o nó que contem todos os personagens
#@onready var party = get_node("../Inventory/Party")
## 'char_list' é uma lista com todos os nós dos personagens
#@onready var char_list = get_node("../Inventory/Party").get_children()
## 'inventory' é a versão para batalha do inventario
#@onready var inventory = get_node("../Inventory/BattleItemMenu")
## 'player' é somente usado para bloquear o movimento do jogador no mapa
#@onready var player = get_node("../Level").get_child(0).find_child("Player")
#
#@onready var game_audio = $"../AudioPlayer"
#
#@onready var textbox
## 'menu' é todo o painel de baixo
#@onready var menu = $BattleMenu
## 'cursor' esse é o cursor que serve para mirar ataques
#@onready var cursor = $Cursor
## 'turn_cursor' esse é o cursor que marca de quem é a vez
#@onready var turn_cursor = $TurnCursor
## 'debug' são informações de debug que podem ser vistas apertando 'A'
#@onready var debug = $Debug
 #
#@onready var background = $Background
#
#@onready var audio_player = $AudioStreamPlayer
## Os sprites começam fora da tela e entram com uma transição no começo da batalha
## esses offsets são o quanto eles se movem para chegar nos seus lugares certos
#const ENEMY_POS_OFFSET = Vector2(128, 0)
#const CHARACTER_POS_OFFSET = Vector2(300,0)
#
#enum Selecting{
	#ITEM_ALLIE,
	#ITEM_ENEMY,
	#ITEM_ALL_ALLIES,
	#ITEM_ALL_ENEMIES,
	#ITEM_ALL,
	#NONE,
	#STARTING,
	#ACTION,
	#ENEMY,
	#ALLIE,
	#ALL_ALLIES,
	#ALL_ENEMIES,
	#MENU,
	#ANIMATION,
	#ENEMY_PHASE,
	#VICTORY,
	#DEFEAT,
	#OTHER
#}
## 'current_selection' estado atual da batalha
#var current_selection = Selecting.STARTING
## lista que guarda cordenadas da frente dos personagens, para o cursor poder 
## apontar para eles
#var character_coords = []
## mesma coisa mas é a parte de trás, para o uso do cursor de turno dessa vez
#var character_back_coords = []
## personagem aliado que está sendo apontado pelo cursor
#var char_index = 0
#
#var char_turn = -1
  #
#var in_battle = false
#
#var enemy_coords = []
#var enemy_names = []
#var enemy_index = 0
#
#var enemies 
#var enemy_list
#
#@onready var enemy_sprite:Sprite2D = get_node("Enemy")
#
#func start_battle(enemy_group_path) ->void:
	#self.show()
	#get_tree().paused = true
	## Carrega o nó com os inimigos, instancia ele e adiciona como filho de Batalha
	#var enemy_group = load(enemy_group_path)
	#var instance = enemy_group.instantiate()
	## Bloqueia movimento do jogador
	#player.set_on_battle(true)
	#
	#game_audio.stop()
	#audio_player.play()
	#add_child(instance)
	## Pega variaveis que apontam para o grupo de inimigos e faz a lista com os
	## inimigos
	#enemies = $Enemies
	#enemy_list = $Enemies.get_children()
	## liga os sinais de "animation_end" e "death" dos inimigos com as respectivas
	## funções da batalha
	#for enemy in enemy_list:
		#pass
	## aparece o cenario da batalha
	#show()
	#
	#textbox = get_node("../Level").get_child(0).find_child("Textbox")
	##textbox.text_finish.connect(_on_text_finish)
	## cria um tween para fazer as transições de começo
	#var tween = create_tween()
	#in_battle = true
	## esconde o menu
	#menu.hide()
	## coloca todas as transições a seguir para ocorrer em paralelo
	#tween.set_parallel()
	## Seta todas as informações dos personagens no menu e transiciona os sprites
	## para dentro do cenario
	#for char in char_list:
		#tween.tween_property(char, "position", char.position - CHARACTER_POS_OFFSET, 0.1).set_trans(Tween.TRANS_LINEAR)
		#menu.set_character_name(char_index, char.get_nome())
		#menu.update_health_instant(char_index, char.get_health_percentage())
		#menu.update_mana_slow(char_index, char.get_mp())
		#menu.show_char_status(char_index)
		#char_index +=1
	## O mesmo para os inimigos
	#for enemy in enemy_list:
		#tween.tween_property(enemy, "position", enemy.position + ENEMY_POS_OFFSET, 0.1).set_trans(Tween.TRANS_LINEAR)
		#enemy_names.append(enemy.get_nome())
	## delisga o paralelo do tween, então todas as transições ocorrem uma por vez
	#tween.set_parallel(false)
	## Seta o nome dos inimigos no menu
	#menu.set_monster_names(enemy_names)
	## No final da transição dos personagens o menu aparece
	#tween.tween_callback(menu.show)
