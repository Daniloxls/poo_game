extends Node
## Roda todos os testes headless (um processo por arquivo) e imprime o resumo.
## Abra tests/run_all_tests.tscn e aperte F6, ou rode pelo MCP do Godot.

const GODOT := "C:/Godot/Godot_v4.7.2-stable_win64_console.exe"


func _ready() -> void:
	var testes: Array[String] = []
	for f in DirAccess.get_files_at("res://tests/battle"):
		if f.begins_with("test_") and f.ends_with(".gd"):
			testes.append("res://tests/battle/" + f)
	for f in DirAccess.get_files_at("res://tests/dialogo"):
		if f.begins_with("test_") and f.ends_with(".gd"):
			testes.append("res://tests/dialogo/" + f)
	testes.append("res://tests/run_tests_java.gd")
	testes.append("res://tests/test_integracao_java.gd")

	var falhas := 0
	for t in testes:
		var saida := []
		var code := OS.execute(GODOT, ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", t], saida, true)
		var texto: String = "\n".join(saida)
		var resumo := ""
		for linha in texto.split("\n"):
			if "falharam" in linha or "TUDO OK" in linha or "testes passaram" in linha:
				resumo = linha.strip_edges()
		print("RESULT %s exit=%d %s" % [t.get_file(), code, resumo])
		if code != 0:
			falhas += 1
			for linha in texto.split("\n"):
				if "FALHOU" in linha or "SCRIPT ERROR" in linha or "Parse Error" in linha:
					print("    ", linha.strip_edges())
	print("RESULT TOTAL %d arquivos, %d falharam" % [testes.size(), falhas])
	get_tree().quit(1 if falhas else 0)
