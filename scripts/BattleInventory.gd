extends Node2D
# sinal emitido quando o menu é fechado
signal closed
# 'cursor' é o cursor de selecionar items na batalha
@onready var cursor = $Cursor

# BattleInventory é basicamente uma versão compacta do inventario que aparece
# na batalha

# Ainda está com alguns bugs para ser resolvido e algumas funções faltam

# todas essas variaveis são as mesmas do inventário
@onready var item_container = $Inventorymargin/InventoryContainer/ItemContainer/ItemList
@onready var item_info = $Inventorymargin/InventoryContainer/InfoBoxContainer/ItemDescriptionContainer/ItemInfoContainer/ItemInfoLabel
@onready var item_menu = $"../ItemMenu"

var item_pos = []
# Lista de itens com alguns itens de teste
var items : Array[ITEM] = [load("res://scenes/itens/repo/potion.tres"),
							load("res://scenes/itens/repo/armadura_ferro.tres"),
							load("res://scenes/itens/repo/armadura_couro.tres")]
# 'item_index' marca o item selecionado
var item_index = 0
# Como a posição dos itens varia conforme o tamanho da tela, ele precisa pegar
# a posição em que eles ficam na primeira vez que o menu abre, para isso essa variavel
var position_got = false
var item_list

# Called when the node enters the scene tree for the first time.
func _ready():
	# item_list guarda as celulas do inventario que mostram os itens 
	item_list = item_container.get_children()
	# inserir função para importar items do inventario principal
	# Se tem itens no inventario ele posiciona o cursor
	if items.size() > 0:
		cursor.set_position(Vector2(281, 132))
	display_items()
	aparecer()
	esconder()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_input()
	
	
# Se o menu estiver visivel ele consegue receber comandos
func process_input():
	if visible:
		if Input.is_action_just_pressed("up"):
			item_index -= 1
			update_index()
		elif Input.is_action_just_pressed("down"):
			item_index += 1
			update_index()
		
# Atualiza o index para dar a volta se estiver com o primeiro item selecionado
# e apertar pra cima ou o ultimo item selecionado e apertar para baixo
func update_index():
	if item_index < 0:
		item_index = 0
	elif item_index == items.size():
		item_index = items.size() - 1
	if items.size() > 0:
		cursor.set_position(item_pos[item_index])

#Coloca itens nas celulas até o maximo de itens se for menos de 10
# ou os primeiros dez itens caso contrario
func display_items():
	if items.size() < 10:
		for i in range(0, items.size(), 1):
			item_list[i].set_item(items[i])
		for i in range (items.size(), 10, 1):
			item_list[i].hide()
	else:
		for i in range(0, 9, 1):
			item_list[i].set_item(items[i])

# 'aparecer' alem de fazer os componentes aparecerem
# reinicia a posição do cursor e pega as posições de todos os itens
# e coloca eles na lista de posições
func aparecer():
	item_pos = []
	items = item_menu.get_items()
	for i in range(item_list.size()):
		item_pos.append((item_list[i].get_position() + Vector2(281, 132)))
	if items.size() > 0:
		cursor.show()
		cursor.set_position(Vector2(281, 132))
	else:
		cursor.hide()
	show()
	print(item_pos)


func esconder():
	hide()
	closed.emit()

# Retorna o tipo de seleção que esse item possui, para ser usado na batalha
# (Aliados, inimigos, todos, etc.)
func get_item_selected():
	return items[item_index].get_selection()


func get_item_index():
	return item_index
