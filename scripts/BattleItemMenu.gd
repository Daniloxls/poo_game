extends Node2D
signal closed
@onready var cursor = $Cursor
@onready var item_container = $Inventorymargin/InventoryContainer/ItemContainer/ItemList
@onready var item_info = $Inventorymargin/InventoryContainer/InfoBoxContainer/ItemDescriptionContainer/ItemInfoContainer/ItemInfoLabel
@onready var item_menu = $"../ItemMenu"
var item_pos = []
var items : Array[ITEM] = [load("res://scenes/itens/repo/potion.tres"),
							load("res://scenes/itens/repo/armadura_ferro.tres"),
							load("res://scenes/itens/repo/armadura_couro.tres")]
var item_index = 0
var position_got = false
var item_list
# Called when the node enters the scene tree for the first time.
func _ready():
	item_list = item_container.get_children()
	if items.size() > 0:
		cursor.set_position(Vector2(281, 132))
	display_items()
	aparecer()
	esconder()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_input()
	
	
func process_input():
	if visible:
		if Input.is_action_just_pressed("up"):
			item_index -= 1
			update_index()
		elif Input.is_action_just_pressed("down"):
			item_index += 1
			update_index()
		
func update_index():
	if item_index < 0:
		item_index = 0
	elif item_index == items.size():
		item_index = items.size() - 1
	if items.size() > 0:
		cursor.set_position(item_pos[item_index])

func display_items():

	if items.size() < 10:
		for i in range(0, items.size(), 1):
			item_list[i].set_item(items[i])
		for i in range (items.size(), 10, 1):
			item_list[i].hide()
	else:
		for i in range(0, 9, 1):
			item_list[i].set_item(items[i])

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

func get_item_selected():
	return items[item_index].get_selection()

func get_item_index():
	return item_index
