extends "res://scenes/main/scripts/interact.gd"

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
var start_battle = false

func _ready():
	Textbox.connect("text_finish", _on_textbox_text_finish)
	Textbox.connect("choice_closed", _on_textbox_choise_closed)


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
	
#func set_codigo(new_nome, new_codigo):
	#nome = new_nome
	#codigo = new_codigo

func update_codigo(new_codigo):
	codigo = new_codigo
	
#func depure():
	#depuring = true
	#return codigo

func interaction():
	if victory_state == Victory.PLAYER:
		Textbox.queue_text(["Desculpe garoto, o montanha vai descansar um pouco agora."])
		return
	Textbox.display_choice("Olá garoto, você quer tentar enfrentar nosso lutador o Grande Montanha para tentar ganhar alguns tickets ?", ["Sim", "Não"])
	triggered = true

func name():
	return nome


func _on_textbox_choise_closed():
	if triggered:
		match(Textbox.get_choice()):
			0:
				start_battle = true
				Textbox.queue_text(["Então que comece a luta!"])
				player.set_state(States.Player_State.ON_BATTLE)
				
			1:
				start_battle = false
				Textbox.queue_text(["Certo, quem sabe depois então."])


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
				Textbox.queue_text(["Eu estou impressionado!",
					"Montanha! Você deixou esse garotinho vencer ?",
					"De qualquer forma tome seus tickets.",
					"Aproveite o festival."])
				tickets.recieve_tickets(10)
				lutador.set_texto(["Como perdi pra um garotinho que nem você ?",
				 "Acho que vou ter de malhar mais."])
			Victory.NPC:
				tickets.show()
				Textbox.queue_text(["Não fique triste rapaz, deixe-me curar seus machucados",
					 "E não se esqueça que você pode tentar de novo qualquer hora"])
				victory_state = Victory.NEITHER
				inventory.full_heal()
				


func _on_city_battle_won():
	triggered = true
	victory_state = Victory.PLAYER



func _on_city_battle_lost():
	triggered = true
	victory_state = Victory.NPC
	
