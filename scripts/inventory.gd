extends CanvasLayer

# invetory é o script da tela principal do inventario
# 'party' é o nó que guarda todos os personagens como filhos
@onready var party = $Party
# 'party_container' é o painel que guarda as informaçoes dos personagens
@onready var item_menu = get_node("ItemMenu")

enum OPTIONS {PRINCIPAL, PERSONAGENS, INFO_PERSONAGENS, ITENS, OPCOES, FECHADO}
@onready var visualizando = OPTIONS.PRINCIPAL

@onready var party_container = $MenuContents/HBoxContainer/PartyContainer
@onready var party_buttons = $MenuButtons/HBoxContainer/MenuLeft/PartyButtons
# 'background' é o painel preto que fica atrás
@onready var background = $MenuBackground
# 'content' são todas as informações do menu
@onready var content = $MenuContents
@onready var player = get_node("../Level").get_child(0).find_child("Player")


# Lista de itens com alguns itens para teste
var items : Array[ITEM] = [load("res://scenes/itens/repo/potion.tres"),
							load("res://scenes/itens/repo/armadura_ferro.tres"),
							load("res://scenes/itens/repo/armadura_couro.tres")]

# Called when the node enters the scene tree for the first time.
func _ready():
	update_group()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_input()

func get_items():
	return items

# Função que atualiza as informações de todos os personagens no grupo
func update_group():
	# Primeiro esconde todos os nós do party_container
	for i in party_container.get_children():
		i.hide()
	for i in party_buttons.get_children():
		i.set_disabled(true)
	# Depois mostra somente os personagens que estão na party
	var party_ui = party_container.get_children()
	var buttons_ui = party_buttons.get_children()
	for i in len(party.get_children()):
		party_ui[i].show()
		party_ui[i].update_char(party.get_children()[i])
		buttons_ui[i].set_disabled(false)
		buttons_ui[i].show()
		
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
	player.set_movement(false)

func menu_visivel():
	if background.is_visible() and content.is_visible():
		return true
	return false

func esconder():
	background.hide()
	content.hide()
	player.set_movement(true)
	
func process_input():
	if Input.is_action_just_pressed("x"):
		if visualizando == OPTIONS.PRINCIPAL:
			visualizando = OPTIONS.FECHADO
			esconder()
		elif visualizando == OPTIONS.INFO_PERSONAGENS: 
			visualizando = OPTIONS.PERSONAGENS
		else:
			visualizando = OPTIONS.PRINCIPAL

func set_player(player_node):
	player = player_node

