extends "res://scenes/main/scripts/java_interact.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	glifos.show()
	nome = "TesteDeForca"
	classe_java = "TesteDeForca"
	dica_java = "Você só pode mudar a condição do if."
	codigo_java = """public class TesteDeForca {

    public boolean testeDeForca(Personagem jogador) {
        boolean sucesso;
        int forca = jogador.getForca();
        if ({|forca > 10|}) {
            sucesso = true;
        } else {
            sucesso = false;
        }
        return sucesso;
    }
}
"""
	ready_drop_menu()


# Roda o código do jogador. Código com erro conta como falha no teste.
func testar(forca: int) -> bool:
	var jogador := JavaRuntime.personagem({"nome": "Turin", "forca": forca})
	return executar_java("testeDeForca", [jogador]) == true
