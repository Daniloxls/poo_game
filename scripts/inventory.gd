extends CanvasLayer

# invetory é o script da tela principal do inventario
# 'party' é o nó que guarda todos os personagens como filhos
@onready var party = $Party
# 'party_container' é o painel que guarda as informaçoes dos personagens

#Cursores 
@onready var cursor = $Cursor
@onready var char_cursor = $Character_Cursor

#Labels das opções do menu
@onready var personagens_label = $MenuContents/HBoxContainer/MenuLeft/MenuOptions/PersonagensLabel
@onready var items_label = $MenuContents/HBoxContainer/MenuLeft/MenuOptions/ItemsLabel
@onready var options_label = $MenuContents/HBoxContainer/MenuLeft/MenuOptions/OptionsLabel
@onready var item_menu = get_node("ItemMenu")
@onready var all_options = [personagens_label, items_label, options_label]
@onready var count = 0 
@onready var char_count = 0 
@onready var equipsnpowers = $EquipsNPowers 
enum OPTIONS {PRINCIPAL, PERSONAGENS, INFO_PERSONAGENS, ITENS, OPCOES, FECHADO}
@onready var visualizando = OPTIONS.PRINCIPAL

@onready var party_container = $MenuContents/HBoxContainer/PartyContainer
# 'background' é o painel preto que fica atrás
@onready var background = $MenuBackground
# 'content' são todas as informações do menu
@onready var content = $MenuContents
@onready var player = get_node("../Level").get_child(0).find_child("Player")
@onready var old_cursor_pos = cursor.position
@onready var old_char_cursor_pos = char_cursor.position


# Lista de itens com alguns itens para teste
var items : Array[ITEM] = [load("res://scenes/itens/repo/potion.tres"),
							load("res://scenes/itens/repo/armadura_ferro.tres"),
							load("res://scenes/itens/repo/armadura_couro.tres")]

# Called when the node enters the scene tree for the first time.
func _ready():
	update_group()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_input()
	pass

func get_items():
	return items

# Função que atualiza as informações de todos os personagens no grupo
func update_group():
	# Primeiro esconde todos os nós do party_container
	for i in party_container.get_children():
		i.hide()
	# Depois mostra somente os personagens que estão na party
	var party_ui = party_container.get_children()
	for i in len(party.get_children()):
		party_ui[i].show()
		party_ui[i].update_char(party.get_children()[i])
		
func full_heal():
	for i in party.get_children():
		i.set_hp(i.get_max_hp())
		
func get_party():
	return party

# Quando o menu aparece, atualiza as informações e bloqueia o movimento do jogador
func aparecer():
	update_group()
	visualizando = OPTIONS.PRINCIPAL
	background.show()
	content.show()
	char_cursor.show()
	cursor.position.y = all_options[count].position.y + all_options[count].get_size().y
	cursor.z_index = 1 
	player.set_movement(false)

func menu_visivel():
	if background.is_visible() and content.is_visible():
		return true

func esconder():
	background.hide()
	content.hide()
	char_cursor.hide()
	player.set_movement(true)
	
func process_input():
	if menu_visivel() && visualizando != OPTIONS.ITENS:
		if Input.is_action_just_pressed("down"):
			if visualizando == OPTIONS.PRINCIPAL && count < len(all_options) - 1:
				count += 1 
			elif visualizando == OPTIONS.PERSONAGENS && \
			char_count < len(party.get_children()) - 1\
			:
				char_count += 1
				char_cursor.position.y = party_container.get_children()[char_count].position.y + 10
		if Input.is_action_just_pressed("up"):
			if visualizando == OPTIONS.PRINCIPAL && count > 0 :
				count -= 1
			elif visualizando == OPTIONS.PERSONAGENS && char_count > 0:
				char_count -= 1
				char_cursor.position.y = party_container.get_children()[char_count].position.y + 10
		if Input.is_action_just_pressed("z"):
			cursor.hide()
			if visualizando == OPTIONS.PRINCIPAL:
				if cursor.hovering == personagens_label:
					visualizando = OPTIONS.PERSONAGENS
					char_cursor.position.y = party_container.get_children()[char_count].position.y + 10
				elif cursor.hovering == items_label:
					visualizando = OPTIONS.ITENS
					item_menu.aparecer()
				elif cursor.hovering == options_label:
					visualizando = OPTIONS.OPCOES
			elif visualizando == OPTIONS.PERSONAGENS:
				char_cursor.hovering = (party_container.get_child(char_count).get_child(1).get_child(0).text.strip_edges(true, true))
				equipsnpowers.show() 
				visualizando = OPTIONS.INFO_PERSONAGENS
		cursor.position.y = all_options[count].position.y + all_options[count].get_size().y
		cursor.set_hovering(all_options[count])
	if Input.is_action_just_pressed("x"):
		if visualizando == OPTIONS.PRINCIPAL:
			visualizando = OPTIONS.FECHADO
			cursor.position = old_cursor_pos
			cursor.z_index = 0
			count = 0 
			esconder()
		elif visualizando == OPTIONS.INFO_PERSONAGENS: 
			equipsnpowers.hide()
			visualizando = OPTIONS.PERSONAGENS
		else:
			visualizando = OPTIONS.PRINCIPAL
			char_cursor.position = old_char_cursor_pos
			cursor.show()

func set_player(player_node):
	player = player_node

