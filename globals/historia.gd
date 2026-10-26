extends Node
## Escolhas da história que mudam falas depois.

var tritomos: String = ""  # "verdade" | "acreditou"
var montanha: String = ""  # "respeito" | "mentor"
var cmdzinho_resgatado: bool = false


func resetar() -> void:
	tritomos = ""
	montanha = ""
	cmdzinho_resgatado = false
