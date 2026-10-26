extends SceneTree
## Carrega a cidade e falha se algum script der erro (SCRIPT ERROR).
## No editor, um erro de script para o jogo no depurador; headless ele só é impresso.
## godot --headless --path . --script res://tests/dialogo/test_carregar_cidade.gd

var passou := 0
var falhou := 0


class Coletor extends Logger:
	var erros: Array[String] = []

	func _log_error(function: String, file: String, line: int, _code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			erros.append("%s:%d %s: %s" % [file, line, function, rationale])


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func _initialize() -> void:
	var coletor := Coletor.new()
	OS.add_logger(coletor)
	var cidade = load("res://scenes/chapter_one/festival_city/City.tscn").instantiate()
	root.add_child(cidade)
	for i in 10:
		await process_frame
	checar("a cidade carrega sem erros de script", coletor.erros.is_empty(), "\n    ".join(coletor.erros))
	OS.remove_logger(coletor)
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
