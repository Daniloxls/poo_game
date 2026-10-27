extends SceneTree
## Tela de resumo: uma linha por membro, comandos, dinheiro e trilha de conceitos.

var passou := 0
var falhou := 0


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func _initialize() -> void:
	await process_frame  # autoloads só ficam prontos após o primeiro frame
	await process_frame
	var inv: Node = root.get_node("Inventory")
	var prog: Node = root.get_node("Progresso")
	var party: Node = root.get_node("Party")
	inv.abrir()
	await process_frame
	var r: Control = inv.tela_atual()
	checar("abre a cena do resumo", r != null and r.has_method("abrir_tela"), r)
	if r == null or not r.has_method("abrir_tela"):
		_fim()
		return
	checar("uma linha por membro", r.linhas().size() == party.get_child_count(), [r.linhas().size(), party.get_child_count()])

	var extra: Node = party.get_node("Turin").duplicate()
	extra.name = "Kath2"
	party.add_child(extra)
	await process_frame
	r.abrir_tela(null)
	checar("grupo de dois", r.linhas().size() == 2, r.linhas().size())
	party.remove_child(extra)
	extra.free()
	r.abrir_tela(null)

	var trilha: Node = r.find_child("TrilhaConceitos", true, false)
	checar("trilha existe", trilha != null)
	checar("chip de Classe com nome", trilha.chip_texto("classe") == "Classe", trilha.chip_texto("classe"))
	checar("chip de métodos escondido", trilha.chip_texto("metodos") == "???", trilha.chip_texto("metodos"))
	var vaza := false
	for c in trilha.get_children():
		vaza = vaza or c.find_child("*", true, false).text.contains("Métodos")
	checar("nome trancado não aparece", not vaza)

	var classe: Button = r.comando("Classe")
	checar("Classe escondido antes de desbloquear", not classe.visible)
	prog.desbloquear("classes")
	r.abrir_tela(null)
	checar("Classe aparece com badge", classe.visible and classe.get_node("Badge").visible)
	prog.resetar()
	r.abrir_tela(null)

	inv.dinheiro = 1250
	r.abrir_tela(null)
	checar("dinheiro com a moeda", r.texto_dinheiro().contains("1250") and r.texto_dinheiro().contains("bits"), r.texto_dinheiro())

	r.comando("Itens").pressed.emit()
	checar("Itens abre a mochila", inv.tela_atual().name == "Itens", inv.tela_atual().name)
	inv.voltar()
	r.comando("Status").pressed.emit()
	checar("com um membro, Status vai direto", inv.tela_atual().name == "Status", inv.tela_atual().name)
	inv.fechar()
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
