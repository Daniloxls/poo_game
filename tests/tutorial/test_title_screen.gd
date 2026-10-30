extends SceneTree
## Tela de título: quatro botões, desabilitados pulados pelo cursor, Novo Jogo troca de cena uma vez.

var passou := 0
var falhou := 0


func check(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func eq(titulo: String, a, b) -> void:
	check(titulo, a == b, [a, b])


func _initialize() -> void:
	await process_frame  # autoloads só ficam prontos após o primeiro frame
	await process_frame
	var t: Control = load("res://ui/title_screen/TitleScreen.tscn").instantiate()
	root.add_child(t)
	await process_frame
	await process_frame
	eq("4 botões", t.botoes().size(), 4)
	eq("textos", t.botoes().map(func(b): return b.text.trim_prefix("▶ ")), ["Novo Jogo", "Continuar", "Opções", "Créditos"])
	check("continuar desabilitado", t.botoes()[1].disabled)
	check("créditos desabilitado", t.botoes()[3].disabled)
	check("foco em Novo Jogo", t.botoes()[0].has_focus())
	var ev := InputEventAction.new()
	ev.action = "ui_down"
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await process_frame
	check("pula desabilitado", t.botoes()[2].has_focus())

	# Opções: abre o painel, esconde o menu, foco em Velocidade; ui_cancel volta
	t.botoes()[2].pressed.emit()
	await process_frame
	await process_frame
	var opc: Control = t.get_node("%Opcoes")
	check("opções visível", opc.visible)
	check("menu escondido", not t.get_node("%Menu").visible)
	check("foco em Velocidade", opc.get_node("%Velocidade").has_focus())
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	Input.parse_input_event(cancel)
	Input.flush_buffered_events()
	await process_frame
	check("opções some", not opc.visible)
	check("menu volta", t.get_node("%Menu").visible)
	check("foco em Opções", t.botoes()[2].has_focus())

	var chamadas := [0]  # lambda captura int por valor
	t.trocar = func(_p): chamadas[0] += 1
	t.novo_jogo()
	t.novo_jogo()
	eq("troca uma vez", chamadas[0], 1)
	print("%d ok, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
