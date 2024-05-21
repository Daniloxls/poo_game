extends "res://scripts/interact.gd"

var direction : Vector2 = Vector2()
@onready var _animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var battle = $"../../../Battle"
@onready var inventory = $"../../../Inventory"
@onready var tickets = $"../Tickets"
@onready var lutador = $"../LutadorNPC"
enum State{
	DOWN,
	LEFT,
	RIGHT,
	UP
}
enum Victory{
	PLAYER,
	NPC,
	NEITHER
}
var current_state = State.DOWN
var victory_state = Victory.NEITHER
var triggered = false;
var start_battle = false
func _ready():
	nome = ""
	texto = []
	codigo = [""]
	portraits = [""]
	depuring = false

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
	if victory_state == Victory.PLAYER:
		textbox.queue_text(["Desculpe garoto, o montanha vai descansar um pouco agora."])
		return
	textbox.display_choice("Olá garoto, você quer tentar enfrentar nosso lutador o Grande Montanha para tentar ganhar alguns tickets ?", ["Sim", "Não"])
	triggered = true

func name():
	return nome


func _on_textbox_choise_closed():
	if triggered:
		match(textbox.get_choice()):
			0:
				start_battle = true
				textbox.queue_text(["Então que comece a luta!"])
				
			1:
				start_battle = false
				textbox.queue_text(["Certo, quem sabe depois então."])


func _on_textbox_text_finish():
	if triggered:
		triggered = false
		match(victory_state):
			Victory.NEITHER:
				if start_battle:
					battle.start_battle("res://scenes/encounters/muscleguy.tscn")
					tickets.hide()
				
			Victory.PLAYER:
				tickets.show()
				textbox.queue_text(["Eu estou impressionado!",
					"Montanha! Você deixou esse garotinho vencer ?",
					"De qualquer forma tome seus tickets.",
					"Aproveite o festival."])
				tickets.recieve_tickets(10)
				lutador.set_texto(["Como perdi pra um garotinho que nem você ?",
				 "Acho que vou ter de malhar mais."])
			Victory.NPC:
				tickets.show()
				textbox.queue_text(["Não fique triste rapaz, deixe-me curar seus machucados",
					 "E não se esqueça que você pode tentar de novo qualquer hora"])
				victory_state = Victory.NEITHER
				inventory.full_heal()
				


func _on_city_battle_won():
	triggered = true
	victory_state = Victory.PLAYER



func _on_city_battle_lost():
	triggered = true
	victory_state = Victory.NPC
	
