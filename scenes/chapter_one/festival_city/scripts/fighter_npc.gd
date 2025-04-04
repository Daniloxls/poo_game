extends "res://scenes/main/scripts/interact.gd"

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
	nome = "Lutador"
	codigo = {}
	metodos = {
	"1" : ["void atacar(Personagem jogador){"],
	"0" : ["\tthis.causar_dano(jogador.get_hp())", 18, 16],
	"3" : ["\treturn\n}"]
	}
	shader_rect.show()
