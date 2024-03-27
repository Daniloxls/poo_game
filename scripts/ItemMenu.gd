extends Node2D

@onready var selected = $SelectedItem
@onready var left_container = $Inventorymargin/InventoryContainer/ItemContainer/LeftItemList
@onready var right_container = $Inventorymargin/InventoryContainer/ItemContainer/RightItemList
@onready var item_info = $Inventorymargin/InventoryContainer/InfoBoxContainer/ItemDescriptionContainer/ItemInfoContainer/ItemInfoLabel
var item_pos = []
var items : Array[ITEM] = [load("res://scenes/itens/repo/potion.tres"),
							load("res://scenes/itens/repo/armadura_ferro.tres"),
							load("res://scenes/itens/repo/armadura_couro.tres")]
var item_index = 0
var position_got = false
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
		for i in range(left_list.size()):
			item_pos.append((left_list[i].get_position() + Vector2(343, 69)))
			item_pos.append((right_list[i].get_position() + Vector2(714, 69)))
			
			
	process_input()
	
	
func process_input():
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

func update_info_text():
	if items.size() > 0:
		item_info.set_text(items[item_index].get_item_text())
	
func get_items():
	return items
	
func add_item(item):
	items.append(item)
