extends CharacterBody2D

var direction : Vector2 = Vector2()
@onready var _animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var player: CharacterBody2D = $"../../../Player"
@onready var path_follow_2d: PathFollow2D = $".."

var metodos = {}
enum State{
	DOWN,
	LEFT,
	RIGHT,
	UP
}
var nome = ""
var texto = []
var codigo = [""]
var portraits = [""]
var depuring = false
var seq = 0
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
	if seq == 1:
		seq = 2
		Textbox.queue_char_text(["Você vai ter de correr mais do que isso pra me acompanhar!"], [""])
		tween.tween_callback(self.set_sprite.bind("walk_up"))
		tween.tween_property(path_follow_2d, "progress_ratio", 0.65 , 1.5)
		tween.tween_callback(self.set_sprite.bind("walk_left"))
		tween.tween_property(path_follow_2d, "progress_ratio", 0.7375, 1.5)
		tween.tween_callback(self.set_sprite.bind("walk_up"))
		tween.tween_property(path_follow_2d, "progress_ratio",0.8635, 2.5)
		tween.tween_callback(self.set_sprite.bind("idle_down"))
	if seq == 2:
		seq = 3
		tween.tween_callback(self.set_seq.bind(3))
		Textbox.queue_char_text(["Te encontro lá dentro, vamos!"], [""])
		tween.tween_callback(self.set_sprite.bind("walk_up"))
		tween.tween_property(path_follow_2d, "progress_ratio", 1, 1.8)
		tween.tween_callback(self.set_process_mode.bind(PROCESS_MODE_DISABLED))

func name():
	return nome

func get_seq():
	return seq

func set_seq(event_seq):
	seq = event_seq

func get_methods():
	return metodos
