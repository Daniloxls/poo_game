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

	for pg in d.paginas:
		if pg.TEXTO != "Em breve.":
			checar("exemplo de %s preenchido" % pg.TITULO, pg.EXEMPLO.strip_edges() != "")
			checar("texto de %s curto" % pg.TITULO, pg.TEXTO.split(" ", false).size() <= 120, pg.TEXTO.split(" ", false).size())

	d.abrir_pagina(d.pagina("objeto"))
	checar("exemplo de objeto usa new", d.exemplo.get_parsed_text().contains("new"), d.exemplo.get_parsed_text())

	inv.voltar()
	prog.desbloquear("metodos")
	inv.ir("documentacao")
	await create_timer(0.5).timeout
	checar("chip novo revelado", d.trilha.chip_texto("metodos") == "Métodos", d.trilha.chip_texto("metodos"))
	checar("métodos marcado como visto", not prog.novo("metodos"))
	checar("página de métodos liberada", not d.botao("metodos").disabled and d.botao("metodos").text == "Métodos")

	prog.resetar()
	inv.fechar()
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
