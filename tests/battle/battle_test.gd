extends SceneTree
## Base dos testes da batalha. Rode com:
## godot --headless --path . --script res://tests/battle/<arquivo>.gd

var passed := 0
var failed := 0


func check(nome: String, ok: bool, detail = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("FALHOU: %s %s" % [nome, str(detail)])


func eq(nome: String, got, expected) -> void:
	check(nome, got == expected, "esperado %s, veio %s" % [str(expected), str(got)])


func finish() -> void:
	print("%d ok, %d falharam" % [passed, failed])
	quit(1 if failed > 0 else 0)
