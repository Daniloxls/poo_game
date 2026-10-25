extends "res://tests/battle/battle_test.gd"

func _err(text: String, msg: String, span: Vector2i) -> void:
	var p := CommandParser.parse(text)
	check("erro '%s'" % text, p.error != null and p.error.message == msg and p.error.span == span,
		"%s %s" % [p.error.message if p.error else "null", p.error.span if p.error else ""])

func _initialize() -> void:
	var p := CommandParser.parse("Turin.atacar(Montanha)")
	eq("stage", p.stage, ParsedCommand.Stage.DONE)
	eq("objeto", p.object_name, "Turin")
	eq("método", p.method_name, "atacar")
	eq("args", p.args, PackedStringArray(["Montanha"]))
	eq("object_span", p.object_span, Vector2i(0, 5))
	eq("method_span", p.method_span, Vector2i(6, 12))
	eq("arg_span", p.arg_spans[0], Vector2i(13, 21))
	check("sem erro", p.error == null)

	p = CommandParser.parse(" Turin . usarItem ( Poção_Pequena , Turin ) ")
	eq("args 2", p.args, PackedStringArray(["Poção_Pequena", "Turin"]))
	eq("stage 2", p.stage, ParsedCommand.Stage.DONE)
	check("sem erro 2", p.error == null)

	eq("OBJECT", CommandParser.parse("Tur").stage, ParsedCommand.Stage.OBJECT)
	eq("METHOD ponto", CommandParser.parse("Turin.").stage, ParsedCommand.Stage.METHOD)
	eq("METHOD parcial", CommandParser.parse("Turin.at").stage, ParsedCommand.Stage.METHOD)
	eq("ARGS (", CommandParser.parse("Turin.atacar(").stage, ParsedCommand.Stage.ARGS)
	eq("ARGS parcial", CommandParser.parse("Turin.atacar(Mon").stage, ParsedCommand.Stage.ARGS)
	eq("ARGS vírgula", CommandParser.parse("x.m(a, ").stage, ParsedCommand.Stage.ARGS)
	check("prefixo sem erro", CommandParser.parse("Turin.atacar(Mon").error == null)
	eq("arg parcial", CommandParser.parse("Turin.atacar(Mon").args, PackedStringArray(["Mon"]))

	_err("Turin atacar", "Esperava '.' depois de Turin", Vector2i(6, 12))
	_err("Turin.(", "Esperava o nome de um método depois de '.'", Vector2i(6, 7))
	_err("Turin.atacar Montanha", "Esperava '(' depois de atacar", Vector2i(13, 21))
	_err("Turin.atacar(,)", "Argumento vazio", Vector2i(13, 14))
	_err("Turin.atacar() x", "Texto sobrando depois de ')'", Vector2i(15, 16))

	p = CommandParser.parse("")
	eq("vazio", p.stage, ParsedCommand.Stage.OBJECT)
	check("vazio sem erro", p.error == null)
	finish()
