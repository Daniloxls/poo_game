extends "res://entities/npc/npc_script.gd"
#scrip de um npc, deriva do script de um objeto interagivel
# todos os scrips de npc devem extender esse


func interaction():
	#faz aparecer o cmdzinho
	Textbox.queue_text(["A cidade fica bem animada para o festival.", "Todo mundo sai de casa e tranca suas portas."])
