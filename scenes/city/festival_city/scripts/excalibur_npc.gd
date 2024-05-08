extends CharacterBody2D

var direction : Vector2 = Vector2()
@onready var _animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var player = get_node("../Player")
@onready var textbox = get_node("../Textbox")
@onready var codebox = get_node("../Codebox")
@onready var sword_scene = get_node("../Cutscene")
enum State{
	DOWN,
	LEFT,
	RIGHT,
	UP
}
var nome
var texto = []
var codigo = [""]
var portraits = [""]
var depuring = false
var triggered = false
var scene = false

var current_state = State.DOWN

func _ready():
	pass

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
	textbox.queue_text(["Você finalmente chegou Turin, a Kath me fez esperar você chegar para começar o envento principal"])
	

func name():
	return nome


func _on_textbox_text_finish():
	if triggered:
		textbox.display_choice("Você está pronto para ver os herois do reino tentarem o desafio da espada na pedra ?", ["Sim", "Não"])
	elif scene:
		scene = false
		sword_scene.play()


func _on_textbox_choise_closed():
	if triggered:
		triggered = false
		match(textbox.get_choice()):
			0:
				textbox.queue_text(["Certo, me siga então."])
				scene = true
			1:
				textbox.queue_text(["Ok, talvez depois"])
			
