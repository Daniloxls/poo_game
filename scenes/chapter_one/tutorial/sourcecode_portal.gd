extends "res://scenes/main/scripts/interact.gd"


func interaction():
	var root = get_node("../../../..")
	var next_level = load("res://scenes/chapter_one/deep_code/DeepCode.tscn")
	var instance = next_level.instantiate()
	root.change_level(instance)
