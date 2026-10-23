extends SceneTree
## Testa a ligação do interpretador com os objetos da cidade do festival.
## godot --headless --path . --script res://tests/test_integracao_java.gd

var falhas := 0


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if not ok:
		falhas += 1


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

	print("\n%s" % ("TUDO OK" if falhas == 0 else "%d falha(s)" % falhas))
	quit(falhas)
