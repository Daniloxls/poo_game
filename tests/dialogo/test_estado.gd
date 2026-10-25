extends SceneTree

var passou := 0
var falhou := 0


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func _initialize() -> void:
	var historia := root.get_node_or_null("Historia")
	var opcoes := root.get_node_or_null("Opcoes")
	checar("Historia existe", historia != null)
	checar("Opcoes existe", opcoes != null)
	if historia == null or opcoes == null:
		_fim()
		return

	checar("tritomos começa vazio", historia.tritomos == "")
	checar("montanha começa vazio", historia.montanha == "")
	historia.tritomos = "verdade"
	historia.montanha = "mentor"
	historia.resetar()
	checar("resetar limpa tritomos", historia.tritomos == "")
	checar("resetar limpa montanha", historia.montanha == "")

	var esperado := {0: 0.05, 1: 0.03, 2: 0.015, 3: 0.0}
	for v in esperado:
		opcoes.velocidade_texto = v
		checar("segundos_por_letra %d" % v, is_equal_approx(opcoes.segundos_por_letra(), esperado[v]), opcoes.segundos_por_letra())
	checar("avanco_automatico começa falso", opcoes.avanco_automatico == false)
	checar("atraso_avanco(0) == 1.2", is_equal_approx(opcoes.atraso_avanco(0), 1.2))
	checar("atraso_avanco(100) ~ 4.7", is_equal_approx(opcoes.atraso_avanco(100), 4.7), opcoes.atraso_avanco(100))
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
