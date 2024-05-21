extends "res://scripts/npc_script.gd"
#scrip de um npc, deriva do script de um objeto interagivel
# todos os scrips de npc devem extender esse

func _ready():
	set_sprite("campones_2")

func interaction():
	textbox.queue_text(["Você já sonhou com uma sala branca com desenhos na parede ?",
	 "Pra mim o sonho sempre acaba depois que eu bato em um boneco feio."])
