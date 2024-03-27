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
	var tween = create_tween()
	textbox.queue_char_text(["Você vai ter de correr mais do que isso pra me acompanhar!"], [""])
	tween.tween_callback(self.set_sprite.bind("idle_up"))
	tween.tween_property(self, "position",Vector2(4500, -21800), 5)
	tween.tween_property(self, "position",Vector2(900, -21800), 1)

func name():
	return nome
