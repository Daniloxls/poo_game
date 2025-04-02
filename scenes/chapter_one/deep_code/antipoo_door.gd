extends "res://scenes/main/scripts/interact.gd"

var unlocked = false

func interaction():
	if unlocked:
		var root = get_node("../../../..")
		var next_level = load("res://scenes/chapter_one/deep_code/anti_poo_cutscene/AntiPooRoom.tscn")
		var instance = next_level.instantiate()
		root.change_level(instance)
		return texto
	else:
		return ["Está trancada"]

func unlock():
	unlocked = true
