extends "res://scenes/main/scripts/interact.gd"

# JavaInteract é a base para objetos cujo código é Java de verdade.
# Em vez de 'codigo' e 'metodos', o objeto define 'codigo_java': o código da
# classe, com as partes que o jogador pode editar entre {| e |}.
# O menu "Depurar" abre o painel de código (JavaRuntime) em vez da Codebox.
#
# Exemplo (no _ready do objeto):
#     nome = "Porta"
#     classe_java = "Porta"
#     codigo_java = """public class Porta {
#         private native void abrir();     // feito em GDScript: func abrir()
#         public void tentar(String senha) {
#             if ({|senha.equals("1234")|}) {
#                 abrir();
#             }
#         }
#     }"""
#     ready_drop_menu()
#
# E para rodar o código do jogador:
#     executar_java("tentar", ["1234"])
#
# Métodos 'native' no Java chamam o método GDScript de mesmo nome neste script.

# Código Java da classe, com as marcas {| |} das partes editáveis.
var codigo_java := ""
# Nome da classe Java que este objeto usa (padrão: o mesmo de 'nome').
var classe_java := ""
# Dica que aparece no topo do painel de código.
var dica_java := ""

# Estado interno (preenchido pelo JavaRuntime).
var codigo_editado := ""      # código atual do jogador (sem as marcas)
var codigo_compilado := ""    # último código compilado com sucesso
var estado_editor := {}       # travas e texto do editor, para reabrir igual
var instancia_java: JObject = null
var ultimo_erro := ""


func ready_drop_menu():
	if classe_java == "":
		classe_java = nome
	if codigo_java != "":
		popup = menu_button.get_popup()
		return
	super.ready_drop_menu()


# Abre o painel de código (chamado pelo item "Depurar" do menu).
func depure(_index):
	if codigo_java == "":
		super.depure(_index)
		return
	JavaRuntime.editar(self)


# Código Java atual (o editado pelo jogador ou o original, sem as marcas).
func get_codigo_java_atual() -> String:
	if codigo_editado != "":
		return codigo_editado
	return JavaEditableMarkup.parse(codigo_java).text


# Executa um método da classe Java deste objeto. Devolve null se der erro.
func executar_java(metodo: String, args: Array = []):
	ultimo_erro = ""
	return JavaRuntime.executar(self, metodo, args)


# Volta o código ao original.
func resetar_codigo_java() -> void:
	codigo_editado = ""
	estado_editor = {}
	instancia_java = null
	codigo_compilado = ""


# Ganchos para os objetos sobrescreverem.
func ao_abrir_codigo() -> void:
	pass

# O jogador apertou Executar e o código compilou. Rode o código aqui
# (executar_java) para os erros de execução aparecerem no painel.
func ao_executar_codigo() -> void:
	pass

func ao_fechar_codigo() -> void:
	pass
