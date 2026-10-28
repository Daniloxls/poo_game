extends "res://scenes/items/classes/item_class.gd"

class_name HEALTH_ITEM

@export var HEALTH_RESTORE : int


func get_type():
	return ITEM.Item_type.HEALTH

func get_health_restore():
	return HEALTH_RESTORE

func pode_usar() -> bool:
	return true

func usar(alvo) -> int:
	return alvo.apply_heal(HEALTH_RESTORE)
