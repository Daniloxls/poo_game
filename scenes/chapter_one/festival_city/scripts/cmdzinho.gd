extends "res://entities/npc/npc_script.gd"
# Cmdzinho se afogando na fonte. Só segue o Turin depois que ele corrige o código.

const CIDADE = preload("res://scenes/chapter_one/festival_city/dialogos/cidade.dialogue")

@onready var codigo_java: Node = $CodigoCmdzinho


func _ready():
	super()
	if Historia.cmdzinho_resgatado:
		_sumir()


func _sumir() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED


func interaction():
	if not codigo_java.esta_salvo():
		await Dialogo.iniciar(CIDADE, "cmdzinho_afogando", [self])
		return
	if not await Dialogo.iniciar(CIDADE, "cmdzinho_resgate", [self]) or not Historia.cmdzinho_resgatado:
		return
	_sumir()
	get_node("../Cmdzinho_Follower").aparecer(position)
