extends "res://entities/npc/npc_script.gd"


@onready var sword_scene = get_node("../Cutscene")
@onready var tickets = $"../Tickets"

# Lidas e escritas por excalibur.dialogue.
var vai_seguir := false
var espada_tirada := false
var ja_conversou := false


func tickets_atuais() -> int:
	return tickets.get_tickets()


func interaction():
	vai_seguir = false
	await Dialogo.iniciar(load("res://scenes/chapter_one/festival_city/dialogos/excalibur.dialogue"), "conversa", [self])
	if vai_seguir:
		tickets.hide()
		espada_tirada = true
		sword_scene.play()
