extends "res://scripts/npc_script.gd"
#scrip de um npc, deriva do script de um objeto interagivel
# todos os scrips de npc devem extender esse

func _ready():
	set_sprite("campones_3")
	pass

func interaction():
	textbox.queue_text(["Eu gosto muito das atividades do festival.",
	 "Mas nunca consigo ganhar nenhuma."])

