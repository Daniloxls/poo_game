extends CanvasLayer

@onready var audio_click:AudioStreamPlayer = get_node("Audio_Click")
# invetory é o script da tela principal do inventario
# 'party' é o nó que guarda todos os personagens como filhos
@onready var party = $Party
# 'party_container' é o painel que guarda as informaçoes dos personagens
@onready var item_menu = $TabContainer/Mochila

@onready var party_container = $TabContainer/Personagens/HBoxContainer/PartyContainer
@onready var party_buttons = $TabContainer/Personagens/PartyButtons
#@onready var player = get_node("../Level").get_child(0).find_child("Player")

@onready var tab_container = $TabContainer

@onready var equipamento = $TabContainer/PersonagemInfo/TabContainer/Equipamento

@onready var char_info = $TabContainer/PersonagemInfo


@onready var item_list_container = $TabContainer/Mochila/InventoryContainer/ScrollContainer/ItemContainer/ItemList
@onready var info_box_container = $TabContainer/Mochila/InventoryContainer/InfoBoxContainer

# Lista de itens com alguns itens para teste
var potion : ITEM = load("res://scenes/itens/repo/potion.tres")
var items : Array[ITEM] = [potion,potion,potion]

var equipment : Array[EQUIP_ITEM] = [load("res://scenes/itens/repo/armadura_ferro.tres"),
									load("res://scenes/itens/repo/armadura_couro.tres")]

var item_container = preload("res://scenes/inventory/item_container.tscn")
var char_container = preload("res://scenes/inventory/char_container.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
##	update_group()
	tab_container.set_tab_disabled(1, true)
	tab_container.set_tab_disabled(3, true)
	tab_container.set_tab_disabled(5, true)
	tab_container.set_tab_hidden(6, true)
	for char in party.get_children():
		var instance = char_container.instantiate()
		instance.call_deferred("update_char", char)
		party_container.add_child(instance)
	for item in items:
		var instance = item_container.instantiate()
		instance.call_deferred("set_item", item)
		instance.connect("mouseover", _on_item_mouseover)
		instance.connect("mouseout", _on_item_mouseout)
		item_list_container.add_child(instance)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_input()

func get_items():
	return items

# Função que atualiza as informações de todos os personagens no grupo
##func update_group():
##	# Primeiro esconde todos os nós do party_container
##	for i in party_container.get_children():
##		i.hide()
##	for i in party_buttons.get_children():
##		i.set_disabled(true)
##	# Depois mostra somente os personagens que estão na party
##	var party_ui = party_container.get_children()
##	var buttons_ui = party_buttons.get_children()
##	for i in len(party.get_children()):
##		party_ui[i].show()
##		party_ui[i].update_char(party.get_children()[i])
##		buttons_ui[i].set_disabled(false)
##		buttons_ui[i].show()
		
		
func full_heal():
	for i in party.get_children():
		i.set_hp(i.get_max_hp())
		
func get_party():
	return party

# Quando o menu aparece, atualiza as informações e bloqueia o movimento do jogador
func aparecer():
##	update_group()
	#player.set_movement(false)
	pass


func esconder():
	
	#player.set_movement(true)
	pass
	
func process_input():
	if Input.is_action_just_pressed("x"):
			esconder()

func set_player(player_node):
	#player = player_node
	pass



func _on_button_pressed():
	audio_click.play()
	tab_container.set_tab_hidden(6, false)
	tab_container.set_current_tab(6)
	var personagem = party.get_child(0)
	char_info.set_personagem(personagem)


func _on_button_2_pressed():
	audio_click.play()
	tab_container.set_tab_hidden(6, false)
	tab_container.set_current_tab(6)
	var personagem = party.get_child(1)
	char_info.set_personagem(personagem)


func _on_tab_container_tab_changed(tab):
	if tab == 2:
		equipamento.add_item_buttons(equipment)
		
		
func _on_item_mouseover(text):
	info_box_container.set_info_text(text)

func _on_item_mouseout():
	info_box_container.set_info_text("")
