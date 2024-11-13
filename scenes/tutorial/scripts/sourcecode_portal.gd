extends "res://scripts/interact.gd"


func interaction():
	var root = get_node("../../../..")
	var next_level = load("res://scenes/tutorial/codigofont.tscn")
	var instance = next_level.instantiate()
	root.change_level(instance)
