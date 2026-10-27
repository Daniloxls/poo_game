extends SceneTree
## Controle e teclado: toda tela abre com foco, ui_accept entra e ui_cancel volta.

var passou := 0
var falhou := 0


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func acao(nome: String) -> void:
	for apertado in [true, false]:
		var ev := InputEventAction.new()
		ev.action = nome
		ev.pressed = apertado
		Input.parse_input_event(ev)
		await process_frame
	await process_frame


func foco() -> Control:
	return root.get_viewport().gui_get_focus_owner()


func _initialize() -> void:
	await process_frame  # autoloads só ficam prontos após o primeiro frame
	await process_frame
	var inv: Node = root.get_node("Inventory")
	var prog: Node = root.get_node("Progresso")
	var turin = root.get_node("Party/Turin")
	prog.desbloquear_tudo()
	inv.mochila.adicionar(load("res://scenes/items/repo/potion.tres"), 2)
	inv.mochila.adicionar(load("res://scenes/items/repo/armadura_ferro.tres"))

	inv.abrir()
	await process_frame
	checar("resumo com foco", foco() != null and inv.tela_atual().is_ancestor_of(foco()), foco())
	for tela in ["itens", "status", "classe", "equipamento", "documentacao", "opcoes"]:
		inv.ir(tela, turin)
		await process_frame
		checar(tela + " abre com foco", foco() != null and inv.tela_atual().is_ancestor_of(foco()), foco())
		inv.voltar()
		await process_frame

	inv.tela_atual().comando("Itens").grab_focus()
	await acao("ui_accept")
	checar("ui_accept em Itens abre a mochila", inv.tela_atual().name == "Itens", inv.tela_atual().name)
	var itens: Control = inv.tela_atual()
	itens.grade_comuns.get_child(1).grab_focus()
	await process_frame
	checar("foco no item mostra o nome", itens.nome.text == "Armadura de Ferro", itens.nome.text)
	await acao("ui_cancel")
	checar("ui_cancel volta ao resumo", inv.esta_aberto() and inv.tela_atual().name == "Resumo", inv.tela_atual())
	await acao("ui_cancel")
	checar("ui_cancel no resumo fecha", not inv.esta_aberto())

	inv.mochila.itens.clear()
	prog.resetar()
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
