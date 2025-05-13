extends "res://entities/npc/npc_script.gd"


@onready var sword_scene = get_node("../Cutscene")
@onready var tickets = $"../Tickets"

var triggered = false
var scene = false
var finished = false

func _ready():
	_animated_sprite.set_sprite_frames(SPRITE)
	texto = ["Ah olá, Turin.",
	 "Por aqui fica o evento principal.",
	 "O rei deixou exibirmos a espada protetora, então fizemos uma atração com ela."]
	Textbox.connect("choice_closed", _on_textbox_choise_closed)
	Textbox.connect("text_finish", _on_textbox_text_finish)


func interaction():
	triggered = true
	Textbox.queue_text(texto)
	if !finished:
		var novo_texto : Array[String]
		novo_texto.append("Está pronto para tentar ir agora ?")
		set_texto(novo_texto)
	

func _on_textbox_text_finish():
	if !finished:
		if triggered:
			Textbox.display_choice(	"Por 30 tickets você pode tentar tirar ela dá pedra, quer tentar?"
			, ["Sim", "Não"])
		elif scene:
			scene = false
			finished = true
			var novo_texto : Array[String]
			set_texto(novo_texto)
			sword_scene.play()


func _on_textbox_choise_closed(escolha):
	if triggered:
		triggered = false
		match(escolha):
			"Sim":
				if tickets.get_tickets() >= 30:
					Textbox.queue_text(["Certo, me siga então."])
					tickets.hide()
					scene = true
				else:
					Textbox.queue_text(["Parece que você não tem tickets suficientes.",
					"Tente ir nas atrações que estão espalhadas na praça, todas elas dão premios em tickets."])
			"Não":
				Textbox.queue_text(["Ok, talvez depois."])
			
