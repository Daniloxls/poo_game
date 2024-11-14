extends "res://scripts/interact.gd"

var unlocked = false

func interaction():
	if unlocked:
		var root = get_node("../../../..")
		var next_level = load("res://scenes/tutorial/anti_poo_room.tscn")
		var instance = next_level.instantiate()
		root.change_level(instance)
		return texto
	else:
		return ["Está trancada"]

func unlock():
	unlocked = true
