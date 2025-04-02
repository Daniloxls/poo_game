extends "res://scenes/items/classes/item_class.gd"

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

func get_hp_bonus():
	return HP
func get_pp_bonus():
	return PP
func get_def_bonus():
	return DEFENSE
func get_atk_bonus():
	return ATTACK
func get_vel_bonus():
	return VELOCITY
