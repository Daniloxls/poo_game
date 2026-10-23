class_name JArray
extends RefCounted
## Um array Java (ex.: int[], Porta[], double[][]).

var type: String      ## tipo completo, ex.: "int[]"
var data: Array = []


func _init(t: String = "", values: Array = []) -> void:
	type = t
	data = values


## Tipo dos elementos, ex.: "int[]" -> "int"
func element_type() -> String:
	return type.substr(0, type.length() - 2)
