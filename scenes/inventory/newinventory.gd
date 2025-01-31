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

@onready var held_item_panel = $TabContainer/Personagens/HeldItemPanel

enum Inventory_State{
	NORMAL,
	HEALING
}


var equipment : Array[EQUIP_ITEM] = [load("res://scenes/itens/repo/armadura_ferro.tres"),
									load("res://scenes/itens/repo/armadura_couro.tres")]


var char_container = preload("res://scenes/inventory/char_container.tscn")
var held_item
var current_state : Inventory_State = Inventory_State.NORMAL
# Called when the node enters the scene tree for the first time.
func _ready():
	tab_container.set_tab_disabled(1, true)
	tab_container.set_tab_disabled(3, true)
	tab_container.set_tab_disabled(5, true)
	tab_container.set_tab_hidden(6, true)
	tab_container.set_tab_hidden(7, true)
	item_menu.connect("item_use", _on_item_use)
	for char in party.get_children():
		var instance = char_container.instantiate()
		instance.call_deferred("set_char", char)
		instance.connect("pressed", _on_character_click)
		party_container.add_child(instance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_input()

func get_items():
	return item_menu.get_items()

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

func get_personagem(nome : String):
	return party.get_node(nome)
	
	
func _on_tab_container_tab_changed(tab):
	if tab == 2:
		equipamento.add_item_buttons(equipment)
		
		


func _on_character_click(char_container):
	match (current_state):
		Inventory_State.NORMAL:
			audio_click.play()
			tab_container.set_tab_hidden(6, false)
			tab_container.set_current_tab(6)
			char_info.set_personagem(get_personagem(char_container.get_char_name()))
		Inventory_State.HEALING:
			char_container.heal_char(held_item.get_health_restore(), get_personagem(char_container.get_char_name()))
			get_personagem(char_container.get_char_name()).gain_health(held_item.get_health_restore())
			item_menu.spend_item(held_item)
			held_item = null
			current_state = Inventory_State.NORMAL
			held_item_panel.hide()

func _on_item_use(item : ITEM):
	match(item.get_type()):
		ITEM.Item_type.HEALTH:
			current_state = Inventory_State.HEALING
			held_item = item
			tab_container.set_current_tab(0)
			held_item_panel.show()
			held_item_panel.set_item_name(item.get_item_name())
