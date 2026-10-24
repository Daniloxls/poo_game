class_name JObject
extends RefCounted
## Uma instância de uma classe (escrita pelo aluno ou nativa do jogo).

var cls: JClass
var fields := {}   ## nome do campo -> valor
## Objeto do Godot ligado a esta instância (ex.: o Node da porta na cena).
## Os métodos nativos usam this.host para agir no jogo.
var host = null


func get_class_name() -> String:
	return cls.name if cls else "?"


func _to_string() -> String:
	return "%s@%x" % [get_class_name(), get_instance_id()]
