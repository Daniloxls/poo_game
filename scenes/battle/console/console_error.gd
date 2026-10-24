class_name ConsoleError
extends RefCounted

# Erro mostrado no console; span = colunas [início, fim) do trecho sublinhado.
var message := ""
var hint := ""
var span := Vector2i.ZERO

static func make(msg: String, sp: Vector2i, h := "") -> ConsoleError:
	var e := ConsoleError.new()
	e.message = msg
	e.span = sp
	e.hint = h
	return e
