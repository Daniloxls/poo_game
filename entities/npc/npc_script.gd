extends CharacterBody2D

#scrip de um npc, deriva do script de um objeto interagivel
# todos os scrips de npc devem extender esse
var direction : Vector2 = Vector2()

@onready var _animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var player = get_node("../Player")
@onready var sprite_2d: Sprite2D = $Sprite2D



@export var nome : String
@export var SPRITE : SpriteFrames
@export var texto : Array[String]

enum State{
	DOWN,
	LEFT,
	RIGHT,
	UP
}
var codigo = [""]
var portraits = [""]
var depuring = false
var metodos = {}
var current_state = State.DOWN

func _ready():
	if SPRITE:
		_animated_sprite.set_sprite_frames(SPRITE)

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
	Textbox.queue_text(texto)

func name():
	return nome

func get_methods():
	return metodos
