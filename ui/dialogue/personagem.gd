class_name Personagem
extends Resource

@export var nome: String
@export var cor: Color = Color.WHITE
@export var retratos: Dictionary[String, Texture2D] = {}
@export var expressao_padrao: String = ""


func tem_retrato() -> bool:
	return not retratos.is_empty()


func retrato(expressao: String = "") -> Texture2D:
	if retratos.has(expressao):
		return retratos[expressao]
	return retratos.get(expressao_padrao)
