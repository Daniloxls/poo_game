extends "res://scripts/npc_script.gd"


@onready var sword_scene = get_node("../Cutscene")
@onready var tickets = $"../Tickets"

var triggered = false
var scene = false
var finished = false

func _ready():
	set_sprite("campones_4")
	texto = ["Ah olá, Turin.",
	 "Por aqui fica o evento principal.",
	 "O rei deixou exibirmos a espada protetora, então fizemos uma atração com ela."]

func set_sprite(sprite):
	_animated_sprite.play(sprite)

func play_animation(animation):
	animation_player.play(animation)
	
func set_texto(new_texto):
	texto = new_texto
	
func get_portraits():
	return portraits
	
func set_portraits(new_portraits):
	portraits = new_portraits
	
func set_codigo(new_nome, new_codigo):
	nome = new_nome
	codigo = new_codigo

func update_codigo(new_codigo):
	codigo = new_codigo
	
func depure():
	depuring = true
	return codigo


func interaction():
	triggered = true
	textbox.queue_text(texto)
	if !finished:
		set_texto(["Está pronto para tentar ir agora ?"])
	

func name():
	return nome


func _on_textbox_text_finish():
	if !finished:
		if triggered:
			textbox.display_choice(	"Por 30 tickets você pode tentar tirar ela dá pedra, quer tentar?"
			, ["Sim", "Não"])
		elif scene:
			scene = false
			finished = true
			set_texto([])
			sword_scene.play()


func _on_textbox_choise_closed():
	if triggered:
		triggered = false
		match(textbox.get_choice()):
			0:
				if tickets.get_tickets() >= 30:
					textbox.queue_text(["Certo, me siga então."])
					tickets.hide()
					scene = true
				else:
					textbox.queue_text(["Parece que você não tem tickets suficientes.",
					"Tente ir nas atrações que estão espalhadas na praça, todas elas dão premios em tickets."])
			1:
				textbox.queue_text(["Ok, talvez depois."])
			
