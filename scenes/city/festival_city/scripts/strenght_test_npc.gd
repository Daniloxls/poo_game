extends CharacterBody2D

var direction : Vector2 = Vector2()
@onready var _animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var player = get_node("../Player")
@onready var textbox = get_node("../Textbox")
@onready var codebox = get_node("../Codebox")

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
	textbox.queue_text(["Teste sua força para ganhar tickets!"])
	triggered = true

func _on_textbox_text_finish():
	if triggered:
		textbox.display_choice("Você quer tentar garoto ?", ["Sim", "Não"])
	elif scene:
		scene = false
		var tween = create_tween()
		var current_pos = player.get_position()
		tween.tween_callback(player.set_in_scene.bind(true))
		tween.tween_callback(player.set_sprite.bind("walk_right"))
		current_pos += Vector2(1200, 0)
		tween.tween_property(player, "position", current_pos, 2)
		tween.tween_callback(player.set_sprite.bind("idle_up"))
		tween.tween_interval(1.5)
		tween.tween_callback(player.set_sprite.bind("walk_right"))
		current_pos += Vector2(900, 0)
		tween.tween_property(player, "position", current_pos, 1.5)
		tween.tween_callback(player.set_sprite.bind("idle_up"))
		tween.tween_interval(1)
		tween.tween_property(player, "position", current_pos + Vector2(0, -300), 0.15)
		tween.tween_property(player, "position", current_pos, 0.1)


func _on_textbox_choise_closed():
	if triggered:
		triggered = false
		match(textbox.get_choice()):
			0:
				textbox.queue_text(["Certo, pegue o martelo e dê o seu melhor!"])
				scene = true
			1:
				textbox.queue_text(["Tudo bem, quem sabe depois"])
				
func name():
	return nome
