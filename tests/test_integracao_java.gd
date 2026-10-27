extends SceneTree
## Testa a ligação do interpretador com os objetos da cidade do festival.
## godot --headless --path . --script res://tests/test_integracao_java.gd

var falhas := 0


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if not ok:
		falhas += 1


# Abre o painel do Tritomos, troca o que vem depois do 'return' e aperta Executar.
func _trocar_retorno(rt, tenda, novo: String) -> void:
	rt.editar(tenda)
	var ed: LockedCodeEdit = rt.painel.editor
	for l in ed.get_line_count():
		var texto := ed.get_line(l)
		if texto.contains("return "):
			ed.select(l, texto.find("return ") + 7, l, texto.find(";"))
			ed.insert_text_at_caret(novo)
	await process_frame
	await process_frame
	rt._on_executar(rt.painel.get_code())


func _initialize() -> void:
	var cidade = load("res://scenes/chapter_one/festival_city/City.tscn").instantiate()
	root.add_child(cidade)
	await process_frame
	var rt = root.get_node("JavaRuntime")
	var teste = cidade.find_child("TesteDeForca", true, false)
	var lutador = cidade.find_child("LutadorInteract", true, false)

	print("== Teste de força ==")
	checar("código original compila e o teste falha com força 4", teste.testar(4) == false, teste.ultimo_erro)
	checar("com força 11 passa", teste.testar(11) == true, teste.ultimo_erro)

	# jogador abre o painel, edita a condição e aperta Executar
	rt.editar(teste)
	checar("painel abre e trava o jogador", rt._camada.visible and root.get_node("PlayerState").is_on_interface())
	var ed: LockedCodeEdit = rt.painel.editor
	var linha := -1
	for i in ed.get_line_count():
		if ed.get_line(i).contains("forca > 10"):
			linha = i
	ed.select(linha, ed.get_line(linha).find("10"), linha, ed.get_line(linha).find("10") + 2)
	ed.insert_text_at_caret("3")
	await process_frame
	await process_frame
	checar("editor aceita mudar só a condição", rt.painel.get_code().contains("if (forca > 3)"), rt.painel.get_code())
	ed.select(0, 0, 0, 6)
	ed.insert_text_at_caret("private")
	await process_frame
	await process_frame
	checar("editor recusa mudar parte travada", rt.painel.get_code().begins_with("public class"), rt.painel.get_code().substr(0, 20))
	rt._on_executar(rt.painel.get_code())
	checar("Executar compila sem erro", teste.ultimo_erro == "" and teste.codigo_compilado.contains("forca > 3"))
	rt.fechar()
	await create_timer(0.5).timeout
	checar("fechar libera o jogador", not root.get_node("PlayerState").is_on_interface() and not rt._camada.visible)
	checar("código editado faz passar no teste com força 4", teste.testar(4) == true, teste.ultimo_erro)

	# reabrir mantém a edição
	rt.editar(teste)
	checar("reabrir mostra o código editado", rt.painel.get_code().contains("forca > 3"))
	rt.fechar()
	await create_timer(0.5).timeout

	# código com erro
	teste.codigo_editado = teste.get_codigo_java_atual().replace("forca > 3", "forca > \"3\"")
	checar("condição com tipo errado conta como falha", teste.testar(4) == false)
	checar("e guarda a mensagem de erro", teste.ultimo_erro.contains("não pode ser usado entre int e String"), teste.ultimo_erro)
	teste.resetar_codigo_java()
	checar("resetar volta ao original", teste.testar(4) == false and teste.ultimo_erro == "", teste.ultimo_erro)

	print("== Lutador ==")
	var turin := {"nome": "Turin", "hp": 30, "atk": 5}
	checar("original: dano = hp do jogador", lutador.calcular_dano(turin) == 30, lutador.ultimo_erro)
	lutador.codigo_editado = lutador.get_codigo_java_atual().replace("jogador.getHp()", "1")
	checar("editado para 1", lutador.calcular_dano(turin) == 1, lutador.ultimo_erro)
	lutador.codigo_editado = lutador.get_codigo_java_atual().replace("this.causarDano(1)", "this.causarDano(jogador.getHp() / 10)")
	checar("expressão com o personagem", lutador.calcular_dano(turin) == 3, lutador.ultimo_erro)
	lutador.codigo_editado = lutador.get_codigo_java_atual().replace("jogador.getHp() / 10", "jogador.getVida()")
	checar("método inexistente vira erro (-1)", lutador.calcular_dano(turin) == -1 and lutador.ultimo_erro.contains("getVida"), lutador.ultimo_erro)

	print("== Tritomos ==")
	var tenda = cidade.get_node("TendaVidente")
	checar("original: bola mostra o pensamento", tenda.ler_pensamento("lua") == "lua", tenda.ultimo_erro)
	tenda.codigo_editado = tenda.get_codigo_java_atual().replace("return resposta;", "return \"sol\";")
	checar("retorna String literal", tenda.ler_pensamento("lua") == "sol", tenda.ultimo_erro)
	tenda.codigo_editado = tenda.get_codigo_java_atual().replace("return \"sol\";", "return 5;")
	checar("retornar int dá erro de tipo", tenda.ler_pensamento("lua") == null and tenda.ultimo_erro.contains("esperado String"), tenda.ultimo_erro)
	tenda.codigo_editado = tenda.get_codigo_java_atual().replace("return 5;", "return sol;")
	checar("sem aspas dá erro", tenda.ler_pensamento("lua") == null and tenda.ultimo_erro != "", tenda.ultimo_erro)
	tenda.codigo_editado = tenda.get_codigo_java_atual().replace("return sol;", "return null;")
	checar("retornar null dá erro", tenda.ler_pensamento("lua") == null and tenda.ultimo_erro != "", tenda.ultimo_erro)
	tenda.resetar_codigo_java()
	# Erros do Tritomos aparecem no painel de código ao apertar Executar, não na tela dele.
	for caso in [["null", "não null"], ["5", "esperado String"]]:
		await _trocar_retorno(rt, tenda, caso[0])
		var saida: String = rt.painel.console.get_parsed_text()
		checar("Executar com return %s mostra o erro no painel" % caso[0], saida.contains(caso[1]) and not saida.contains("sem erros"), saida)
		rt.fechar()
		await create_timer(0.5).timeout
	tenda.first_interaction = false
	tenda.interaction()
	await process_frame
	checar("abrir com erro não mostra erro na tela", tenda.linha.visible and not tenda.bolha.visible)
	tenda.close_window()
	await _trocar_retorno(rt, tenda, "resposta")
	checar("código certo: Executar diz que compilou", rt.painel.console.get_parsed_text().contains("sem erros"), rt.painel.console.get_parsed_text())
	rt.fechar()
	await create_timer(0.5).timeout
	tenda.resetar_codigo_java()

	# Tela: balão ao lado da bola com o que ela mostrou; palavra comprida cabe na moldura.
	tenda.interaction()
	tenda._mostrar_palavra("sol")
	checar("balão mostra a palavra", tenda.bolha.visible and tenda.get_node("VidenteInterface/%Palavra").text == "sol")
	tenda._mostrar_palavra("paralelepipedo-gigante-demais")
	checar("palavra comprida cabe na moldura", tenda.bolha.size.x <= tenda.LARGURA_MAXIMA_BOLHA, tenda.bolha.size.x)
	tenda._mostrar_nevoa()
	checar("névoa troca o balão", tenda.nevoa.visible and not tenda.bolha.visible)
	tenda.close_window()
	checar("fechar limpa a bola", not tenda.nevoa.visible and not tenda.bolha.visible)

	# digitar "e" no pensamento não abre o inventário
	var inv: Node = root.get_node("Inventory")
	tenda.interface.show()
	tenda.pensamento_field.grab_focus()
	Input.action_press("e")
	await process_frame
	await process_frame
	Input.action_release("e")
	checar("'e' no campo de texto não abre o inventário", not inv.visible)
	tenda.close_window()

	print("== Glifos dos objetos depuráveis ==")
	var glifos = teste.glifos
	checar("glifos visíveis no objeto depurável", glifos.is_visible_in_tree())
	await create_timer(0.8).timeout
	checar("glifos sobem do objeto", glifos._glifos.size() > 0, glifos._glifos.size())
	teste.cor_glifos = Color.RED
	checar("cor dos glifos vem do objeto", glifos.cor() == Color.RED, glifos.cor())

	print("\n%s" % ("TUDO OK" if falhas == 0 else "%d falha(s)" % falhas))
	quit(falhas)
