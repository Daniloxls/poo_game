extends "res://scripts/npc_script.gd"
#scrip de um npc, deriva do script de um objeto interagivel
# todos os scrips de npc devem extender esse

func _ready():
	set_sprite("campones_1")

func interaction():
	textbox.queue_text(["A cidade fica bem animada para o festival.", "Todo mundo sai de casa e tranca suas portas."])
