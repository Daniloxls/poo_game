extends "res://scenes/itens/classes/item_class.gd"

class_name HEALTH_ITEM

@export var HEALTH_RESTORE : int


func get_type():
	return ItemClass.Item_type.HEALTH

func get_health_restore():
	return HEALTH_RESTORE
