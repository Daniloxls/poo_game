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
	root.get_node("PlayerState").set_on_interface(false)  # já passou da tela de título
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

	# sem o menu lateral: a navegação é a barra de cima
	checar("sem menu lateral no resumo", r.find_child("Opcoes", true, false) == null)
	var barra: Control = inv.get_node("Menu/Barra")
	var classe: Button = barra.find_child("Classe", true, false)
	checar("Classe escondido antes de desbloquear", not classe.visible)
	prog.desbloquear("classes")
	await process_frame
	checar("Classe aparece na barra com !", classe.visible and classe.get_node("Badge").visible)
	var badge = classe.get_node("Badge")
	checar("badge é o emote de !", badge is TextureRect and badge.texture != null and badge.texture.resource_path.ends_with("exclamacao.png"), badge)
	prog.resetar()
	inv.trocar("resumo")
	await process_frame

	var itens_cmd: Button = barra.find_child("Itens", true, false)
	var status_cmd: Button = barra.find_child("Status", true, false)
	status_cmd.grab_focus()
	await process_frame
	checar("seta no comando com foco", status_cmd.icon != null and status_cmd.icon.resource_path.ends_with("seta.png"), status_cmd.icon)
	checar("sem seta nos outros", itens_cmd.icon == null, itens_cmd.icon)
	checar("divisor entre o grupo e a trilha", r.find_child("Divisor", true, false) is HBoxContainer and r.find_child("Divisor", true, false).get_child_count() == 2)

	# no lugar do menu: uma prévia da mochila
	inv.mochila.adicionar(load("res://scenes/items/repo/potion.tres"), 6)
	inv.dinheiro = 1250
	r.abrir_tela(null)
	checar("dinheiro com a moeda", r.texto_dinheiro().contains("1250") and r.texto_dinheiro().contains("bits"), r.texto_dinheiro())
	var previa: Button = r.find_child("PreviaMochila", true, false)
	checar("prévia da mochila mostra a poção", previa != null and previa.find_children("*", "Label", true, false).any(func(l): return l.text.contains("Poção")))
	previa.pressed.emit()
	checar("prévia abre a mochila", inv.tela_atual().name == "Itens", inv.tela_atual().name)
	inv.voltar()
	r.linhas()[0].pressed.emit()
	checar("clicar no personagem abre o Status", inv.tela_atual().name == "Status", inv.tela_atual().name)
	inv.mochila.itens.clear()
	inv.dinheiro = 0
	inv.fechar()
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
