extends MarginContainer

signal item_use

@onready var item_list_container = $InventoryContainer/ScrollContainer/ItemContainer/ItemList
@onready var info_box_container = $InventoryContainer/InfoBoxContainer

# Lista de itens com alguns itens para teste
var potion : ITEM = load("res://scenes/itens/repo/small_potion.tres")
var items : Array[ITEM] = [potion]

var item_container = preload("res://scenes/inventory/item_container.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	for item in items:
		var instance = item_container.instantiate()
		instance.call_deferred("set_item", item)
		instance.connect("mouseover", _on_item_mouseover)
		instance.connect("mouseout", _on_item_mouseout)
		instance.connect("click", _on_item_click)
		instance.name = item.get_item_name()
		item_list_container.add_child(instance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_item_mouseover(text):
	info_box_container.set_info_text(text)

func _on_item_mouseout():
	info_box_container.set_info_text("")
	
func _on_item_click(container):
	item_use.emit(container.get_item())
	
func get_items():
	return items

func spend_item(item : ITEM):
	var item_index = items.find(item)
	items[item_index].QUANTITY -= 1
	item_list_container.get_node(item.get_item_name()).update_item_quantity(items[item_index].QUANTITY)
	if items[item_index].QUANTITY == 0:
		items.pop_at(item_index)
		item_list_container.get_node(item.get_item_name()).call_deferred("free")
