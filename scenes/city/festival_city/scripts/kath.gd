extends "res://scripts/npc_script.gd"
#scrip de um npc, deriva do script de um objeto interagivel
# todos os scrips de npc devem extender esse

func _ready():
	set_sprite("idle_down")
	pass

func interaction():
	textbox.queue_text(["Finalmente! Aquele bigodudo disse que a gente consegue ganhar tickets nas atrações."])

