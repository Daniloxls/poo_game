extends "res://scenes/itens/classes/item_class.gd"

class_name EQUIP_ITEM
enum Slot{
	HAND,
	TWO_HAND,
	FEET,
	BODY,
	HEAD,
	ACESSORY
}

@export var HP : int
@export var PP : int
@export var DEFENSE : int
@export var ATTACK : int
@export var VELOCITY : int
@export var SLOT : Slot

func get_slot():
	return SLOT
