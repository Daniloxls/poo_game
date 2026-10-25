extends "res://entities/npc/npc_script.gd"
# Cmdzinho se afogando na fonte. Só segue o Turin depois que ele corrige o código.

const CIDADE = preload("res://scenes/chapter_one/festival_city/dialogos/cidade.dialogue")

@onready var codigo_java: Node = $CodigoCmdzinho


func interaction():
	if not codigo_java.esta_salvo():
		await Dialogo.iniciar(CIDADE, "cmdzinho_afogando", [self])
		return
	await Dialogo.iniciar(CIDADE, "cmdzinho_resgate", [self])
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED
	get_node("../Cmdzinho_Follower").aparecer(position)
