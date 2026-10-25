class_name Personagem
extends Resource

@export var nome: String
## Nome mostrado na etiqueta, quando difere do nome usado no .dialogue (ex.: "???").
@export var rotulo: String = ""
@export var cor: Color = Color.WHITE
@export var retratos: Dictionary[String, Texture2D] = {}
@export var expressao_padrao: String = ""


func tem_retrato() -> bool:
	return not retratos.is_empty()


func retrato(expressao: String = "") -> Texture2D:
	if retratos.has(expressao):
		return retratos[expressao]
	return retratos.get(expressao_padrao)


func nome_exibido() -> String:
	return rotulo if not rotulo.is_empty() else nome
