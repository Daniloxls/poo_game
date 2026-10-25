extends "res://scenes/main/scripts/java_interact.gd"

# Código Java do Cmdzinho: o jogador troca a chamada em reagirAgua() para salvá-lo.
var ultima_chamada := ""


func _ready():
	shader_rect.show()
	nome = "Cmdzinho"
	classe_java = "Cmdzinho"
	dica_java = "Você só pode mudar a chamada dentro de reagirAgua()."
	codigo_java = """public class Cmdzinho {

    private native void afundar();
    private native void nadar();

    public void reagirAgua() {
        {|this.afundar();|}
    }
}
"""
	ready_drop_menu()


func afundar() -> void:
	ultima_chamada = "afundar"


func nadar() -> void:
	ultima_chamada = "nadar"


# Roda reagirAgua(). Salvo só se o código compilou e chamou nadar().
func esta_salvo() -> bool:
	ultima_chamada = ""
	executar_java("reagirAgua")
	return ultimo_erro == "" and ultima_chamada == "nadar"
