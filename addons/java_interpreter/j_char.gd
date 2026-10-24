class_name JChar
extends RefCounted
## Valor do tipo primitivo char. Fica separado de int para que
## "" + 'a' dê "a" e 'a' + 1 dê 98, como em Java.

var code: int


func _init(c: int = 0) -> void:
	code = c


func _to_string() -> String:
	return char(code)
