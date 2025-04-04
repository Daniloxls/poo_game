extends "res://scenes/main/scripts/interact.gd"

var unlocked = false

func interaction():
	if unlocked:
		LevelWarp.change_level("res://scenes/chapter_one/deep_code/anti_poo_cutscene/AntiPooRoom.tscn")
		return texto
	else:
		return ["Está trancada"]

func unlock():
	unlocked = true
