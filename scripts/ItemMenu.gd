extends Node2D
# ItemMenu é a parte do menu que guarda os itens

@onready var item_menu = $"."
# 'selected' é o cursor que mostra qual item está selecionado
@onready var selected = $SelectedItem
# o inventario é divido em duas partes com 'left_container' e 'right_container'
@onready var left_container = $Inventorymargin/InventoryContainer/ItemContainer/LeftItemList
@onready var right_container = $Inventorymargin/InventoryContainer/ItemContainer/RightItemList
# 'item_info' é a parte de baixo do menu que mostra a descrição do item
@onready var item_info = $Inventorymargin/InventoryContainer/InfoBoxContainer/ItemDescriptionContainer/ItemInfoContainer/ItemInfoLabel
# 'item_pos' lista que guarda posições que o cursor pode tomar no inventario 
var item_pos = []

enum options {VISUALIZANDO, ITEM_SELECIONADO, FECHADO, TRANSICAO_MENU}
@onready var visualizando = options.FECHADO

# Lista de items com alguns itens para teste
var items : Array[ITEM] = [load("res://scenes/itens/repo/potion.tres"),
							load("res://scenes/itens/repo/armadura_ferro.tres"),
							load("res://scenes/itens/repo/armadura_couro.tres")]
# Index que o cursor inicia
var item_index = 0
# 'positions_got' é a variavel que diz se as posições das celulas de item foram
# salvas na lista item_pos
# Como podemos ter varios tamanhos de tela, as posições são pegadas quando o menu está aberto
var position_got = false
# Listas que guardam as celulas de cada container do inventario
var left_list
var right_list

# Called when the node enters the scene tree for the first time.
func _ready():
	left_list = left_container.get_children()
	right_list = right_container.get_children()
	if items.size() > 0:
		selected.set_position(Vector2(343, 69))
		item_info.set_text(items[item_index].get_item_text())
	display_items()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not position_got:
		position_got = true
		# salva a posição de cada celula em item_pos
		for i in range(left_list.size()):
			item_pos.append((left_list[i].get_position() + Vector2(343, 69)))
			item_pos.append((right_list[i].get_position() + Vector2(714, 69)))
			
			
	process_input()
	
	
# Por equanto essa função só lida com o movimento do cursor usando as setas

func process_input():
	if visualizando == options.VISUALIZANDO:
		if Input.is_action_just_pressed("right"):
			item_index += 1
			update_index()
		elif Input.is_action_just_pressed("left"):
			item_index -= 1
			update_index()
		elif Input.is_action_just_pressed("up"):
			item_index -= 2
			update_index()
		elif Input.is_action_just_pressed("down"):
			item_index += 2
			update_index()
		elif Input.is_action_just_pressed("z"):
			visualizando = options.ITEM_SELECIONADO
			#Irá abrir outro menu
		elif Input.is_action_just_pressed("x"):
			visualizando = options.FECHADO
			get_parent().visualizando = get_parent().OPTIONS.PRINCIPAL
			get_parent().cursor.show()
			item_menu.hide()
	elif visualizando == options.ITEM_SELECIONADO:
		if Input.is_action_just_pressed("x"):
			visualizando = options.VISUALIZANDO
	elif visualizando == options.TRANSICAO_MENU: 
		if Input.is_action_just_pressed("z"):
			visualizando = options.VISUALIZANDO
			print("Aqui")

# Garante que o cursor não vá alem da quantida de itens
func update_index():
	if item_index < 0:
		item_index = 0
	elif item_index == items.size():
		item_index = items.size() - 2
	elif item_index == items.size() + 1:
		item_index = items.size() - 1
	if items.size() > 0:
		selected.set_position(item_pos[item_index])
		update_info_text()

# Distribui os itens igualmente entre as duas listas
func display_items():
	if items.size() % 2 == 0:
		for i in range(0, items.size(), 2):
			left_list[i/2].set_item(items[i])
			right_list[i/2].set_item(items[i+1])
		for i in range (items.size(), 20, 2):
			left_list[i/2].hide()
			right_list[i/2].hide()
	else:
		for i in range(0, items.size()-1, 2):
			left_list[i/2].set_item(items[i])
			right_list[i/2].set_item(items[i+1])
		left_list[items.size()/2].set_item(items[items.size()-1])
		right_list[items.size()/2].hide()
		for i in range (items.size()+1, 20, 2):
			left_list[i/2].hide()
			right_list[i/2].hide()

# Quando um item está selecionado essa função mostra a descrição dele no painel de baixo
func update_info_text():
	if items.size() > 0:
		item_info.set_text(items[item_index].get_item_text())
		
func aparecer(): 
	item_menu.show()
	visualizando = options.TRANSICAO_MENU
	
func get_items():
	return items
	
func add_item(item):
	items.append(item)
