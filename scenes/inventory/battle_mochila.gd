extends MarginContainer

signal item_use
signal close

@onready var item_list_container = $InventoryContainer/ScrollContainer/ItemContainer/ItemList

@onready var mochila = $"../../../TabContainer/Mochila"

var items

var item_container = preload("res://scenes/inventory/item_container.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	items =  mochila.get_items()
	for item in items:
		var instance = item_container.instantiate()
		instance.call_deferred("set_item", item)
		instance.connect("click", _on_item_click)
		instance.name = item.get_item_name()
		item_list_container.add_child(instance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

	
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
