extends Resource

class_name ITEM
@export var ITEM_NAME : String
@export var QUANTITY: int
@export var ITEM_ICON : Texture
@export_multiline var ITEM_TEXT : String


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
