extends "res://scripts/npc_script.gd"

var scene:bool = false

func interaction():
	if !scene:
		textbox.queue_text(["Para abrir a porta, deverá ativar os totens."])
	else:
		textbox.queue_text(["Parabéns. você liberou o caminho!"])
