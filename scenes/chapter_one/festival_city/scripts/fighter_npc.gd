extends "res://scenes/main/scripts/java_interact.gd"

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
# Dano calculado pela última execução de atacar() no código Java.
var dano_calculado := 0

func _ready():
	nome = "Lutador"
	classe_java = "Lutador"
	dica_java = "Você só pode mudar o dano que o lutador causa."
	codigo_java = """public class Lutador {

    // Métodos native são feitos pelo jogo (veja causarDano no fighter_npc.gd)
    private native void causarDano(int dano);

    public void atacar(Personagem jogador) {
        this.causarDano({|jogador.getHp()|});
    }
}
"""
	glifos.show()

# Chamado pelo Java: private native void causarDano(int dano);
func causarDano(dano: int) -> void:
	dano_calculado = maxi(dano, 0)


# Roda atacar(jogador) do código Java. Devolve o dano, ou -1 se o código tem erro.
func calcular_dano(alvo) -> int:
	dano_calculado = 0
	executar_java("atacar", [JavaRuntime.personagem(alvo)])
	return -1 if ultimo_erro != "" else dano_calculado
