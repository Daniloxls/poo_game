extends SceneTree
## Documentação: páginas por conceito, trancadas como ??? e o chip novo revelado.

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
	inv.abrir()
	inv.ir("documentacao")
	await process_frame
	var d: Control = inv.tela_atual()
	checar("cena de documentação", d.has_method("abrir_pagina"), d)
	if not d.has_method("abrir_pagina"):
		_fim()
		return
	checar("dez páginas", d.paginas.size() == 10, d.paginas.size())
	checar("bool liberado", not d.botao("bool").disabled)
	checar("classe liberada", not d.botao("classe").disabled)
	checar("métodos trancado como ???", d.botao("metodos").disabled and d.botao("metodos").text == "???", d.botao("metodos").text)
	checar("trancado não recebe foco", d.botao("metodos").focus_mode == Control.FOCUS_NONE)
	d.abrir_pagina(d.pagina("metodos"))
	checar("página trancada não abre", d.find_children("*", "Label", true, false).all(func(l): return l.text != "Métodos"))

	for pg in d.paginas:
		if pg.TEXTO != "Em breve.":
			checar("exemplo de %s preenchido" % pg.TITULO, pg.EXEMPLO.strip_edges() != "")
			checar("texto de %s curto" % pg.TITULO, pg.TEXTO.split(" ", false).size() <= 120, pg.TEXTO.split(" ", false).size())

	# clique do mouse não funciona headless: confere que nada numa camada acima do menu
	# pega o mouse em cima dos botões (o retrato vazio do Textbox antigo pegava)
	await create_timer(0.3).timeout
	for id in ["bool", "classe", "objeto"]:
		var centro: Vector2 = d.botao(id).get_global_rect().get_center()
		var tampa := []
		for c in root.find_children("*", "Control", true, false):
			var camada: CanvasLayer = c.get_canvas_layer_node()
			if c.is_visible_in_tree() and c.mouse_filter != Control.MOUSE_FILTER_IGNORE \
					and camada and camada.layer > inv.layer and c.get_global_rect().has_point(centro):
				tampa.append(c.get_path())
		checar("nada cobre o botão %s" % id, tampa.is_empty(), tampa)

	d.abrir_pagina(d.pagina("objeto"))
	checar("página aberta marcada", d.botao("objeto").button_pressed and not d.botao("bool").button_pressed)
	checar("exemplo de objeto usa new", d.exemplo.get_parsed_text().contains("new"), d.exemplo.get_parsed_text())

	inv.voltar()
	prog.desbloquear("metodos")
	inv.ir("documentacao")
	await create_timer(0.5).timeout
	checar("chip novo revelado", d.trilha.chip_texto("metodos") == "Métodos", d.trilha.chip_texto("metodos"))
	var tam: int = d.trilha.get_node("classe/Texto").get_theme_font_size("font_size")
	checar("chips grandes na documentação", tam >= 18, tam)
	checar("métodos marcado como visto", not prog.novo("metodos"))
	checar("página de métodos liberada", not d.botao("metodos").disabled and d.botao("metodos").text == "Métodos")

	prog.resetar()
	inv.fechar()
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
