class_name ParsedCommand
extends RefCounted

# Onde o texto termina (usado pelo autocomplete).
enum Stage { OBJECT, METHOD, ARGS, DONE }

var stage := Stage.OBJECT
var object_name := ""
var object_span := Vector2i.ZERO
var method_name := ""
var method_span := Vector2i.ZERO
var args := PackedStringArray()
var arg_spans: Array[Vector2i] = []
var error: ConsoleError = null   # null: comando completo ou prefixo válido
