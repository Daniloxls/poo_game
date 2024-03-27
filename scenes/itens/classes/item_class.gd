extends Resource
class_name ITEM

enum Selecting{
	ITEM_ALLIE,
	ITEM_ENEMY,
	ITEM_ALL_ALLIES,
	ITEM_ALL_ENEMIES,
	ITEM_ALL,
	NONE
}

@export var ITEM_NAME : String
@export var QUANTITY: int
@export var ITEM_ICON : Texture
@export_multiline var ITEM_TEXT : String
@export var SELECTION : Selecting

func spend_item(quantity):
	QUANTITY -= quantity
	
func get_quantity():
	return QUANTITY

func get_item_name():
	print(ITEM_NAME)
	return ITEM_NAME
	
func get_icon():
	return ITEM_ICON
	
func get_item_text():
	return ITEM_TEXT

func get_selection():
	return SELECTION
