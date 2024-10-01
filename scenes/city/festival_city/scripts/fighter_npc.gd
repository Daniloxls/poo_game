extends "res://scripts/interact.gd"

var direction : Vector2 = Vector2()
@onready var _animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer

enum State{
	DOWN,
	LEFT,
	RIGHT,
	UP
}

var current_state = State.DOWN

func _ready():
	set_sprite("fighter")
	nome = "Lutador"
	texto = ["Ei garotinho, você acha que pode me derrotar ?",
	 "Fale com meu gerente, prometo pegar leve com você"]
	codigo = {}
	metodos = {
	"1" : ["void atacar(Personagem jogador){"],
	"0" : ["\tjogador.receber_dano(jogador.get_hp())", 19, 13],
	"3" : ["\treturn\n}"]
	}

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
	textbox.queue_text(texto)

	
func name():
	return nome
