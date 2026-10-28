extends SceneTree

const BALAO := "res://ui/dialogue/Balao.tscn"

var passou := 0
var falhou := 0
var dm: Node
var opcoes: Node
var elenco: Node
var ctx: Node


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func _initialize() -> void:
	_rodar()


## Abre um balão e espera a primeira fala começar.
func _abrir(texto: String) -> Node:
	var b: Node = dm.show_dialogue_balloon_scene(BALAO, dm.create_resource_from_text(texto), "", [ctx])
	for i in 120:
		await process_frame
		if is_instance_valid(b) and b.is_inside_tree() and b.get_node("%Texto").dialogue_line != null:
			return b
	return b


func _fechar(b) -> void:
	if is_instance_valid(b):
		b.queue_free()
	opcoes.velocidade_texto = opcoes.Velocidade.NORMAL
	opcoes.avanco_automatico = false
	ctx.escolha = ""
	await process_frame


func _esperar_digitar(b: Node) -> void:
	for i in 600:
		if not b.get_node("%Texto").is_typing:
			return
		await process_frame


func _rodar() -> void:
	await process_frame
	dm = root.get_node("DialogueManager")
	opcoes = root.get_node("Opcoes")
	elenco = root.get_node("Elenco")
	var s := GDScript.new()
	s.source_code = "extends Node\nvar escolha := \"\"\n"
	s.reload()
	ctx = Node.new()
	ctx.set_script(s)
	root.add_child(ctx)

	if not ResourceLoader.exists(BALAO):
		checar("Balao.tscn existe", false)
		_fim()
		return

	# Personagem com retrato
	var b := await _abrir("~ a\nKath: Oi!\n=> END")
	checar("Kath: nome", b.get_node("%NomeTag").text == "Kath", b.get_node("%NomeTag").text)
	checar("Kath: cor da etiqueta", b.get_node("%NomeTag").get_parent().self_modulate == Color("#2ec4d6"), b.get_node("%NomeTag").get_parent().self_modulate)
	checar("Kath: retrato", b.get_node("%Retrato").personagem != null and b.get_node("%Retrato").personagem.nome == "Kath")
	checar("Kath: sem faixa", not b.get_node("%Faixa").visible)
	await create_timer(0.4).timeout
	var r: Control = b.get_node("%Retrato")
	var caixa: Control = b.get_node("%Caixa")
	checar("busto embaixo à esquerda, por cima da borda da caixa",
		r.position.x < 60 and r.get_rect().position.y < caixa.get_rect().position.y and r.get_rect().end.y > caixa.get_rect().position.y + 100, r.get_rect())
	# O corte de baixo do busto encosta na borda da caixa (4 px) e a moldura corta o que descer.
	var fundo_img: float = r.get_node("%Imagem").get_global_rect().end.y
	checar("busto termina na borda de baixo da caixa", absf(fundo_img - (caixa.get_global_rect().end.y - 4)) <= 1.0, [fundo_img, caixa.get_global_rect().end.y])
	checar("moldura corta o busto que descer", r.get_parent().clip_contents)
	checar("texto à direita do busto", b.get_node("%Texto").get_global_rect().position.x >= r.get_rect().end.x + 4, b.get_node("%Texto").get_global_rect())
	await _fechar(b)

	# Rótulo de exibição: Vulto aparece como "???"
	b = await _abrir("~ a
Vulto: Hm...
=> END")
	checar("Vulto: etiqueta mostra ???", b.get_node("%NomeTag").text == "???", b.get_node("%NomeTag").text)
	checar("Vulto: etiqueta visível", b.get_node("%NomeTag").get_parent().visible)
	await _fechar(b)

	# Sem retrato
	b = await _abrir("~ a\nGrande Montanha: Hah!\n=> END")
	checar("Montanha: faixa visível", b.get_node("%Faixa").visible)
	checar("Montanha: cor da faixa", b.get_node("%Faixa").color == Color("#e8463a"), b.get_node("%Faixa").color)
	checar("Montanha: sem retrato", b.get_node("%Retrato").personagem == null)
	await _fechar(b)

	b = await _abrir("~ a\nFulano: oi\n=> END")
	checar("Fulano: faixa com cor padrão", b.get_node("%Faixa").visible and b.get_node("%Faixa").color == elenco.COR_PADRAO)
	await _fechar(b)

	# Expressões por tag
	b = await _abrir("~ a\nCmdzinho: [#surpreso] Uau\n=> END")
	var img: TextureRect = b.get_node("%Retrato").get_node("%Imagem")
	checar("Cmdzinho: tag de expressão", img.texture != null and img.texture.resource_path.get_file().begins_with("cmd_surpreso"), img.texture)
	await create_timer(0.4).timeout
	r = b.get_node("%Retrato")
	var t_tam: Vector2 = img.texture.get_size()
	var i_ret := img.get_global_rect()
	checar("Cmdzinho: arte quadrada encosta no pé do busto",
		absf(i_ret.end.y - r.get_global_rect().end.y) <= 2.0 and absf(i_ret.size.x / i_ret.size.y - t_tam.x / t_tam.y) < 0.02,
		[i_ret, r.get_global_rect()])
	await _fechar(b)

	# Troca de personagem numa fala com animação: a textura nova não pode se perder
	b = await _abrir("~ a\nKath: Oi.\nCmdzinho: [#hop] Uau\n=> END")
	await _esperar_digitar(b)
	await create_timer(0.4).timeout
	b.avancar()
	await create_timer(0.8).timeout
	r = b.get_node("%Retrato")
	img = r.get_node("%Imagem")
	checar("troca + hop: personagem novo", r.personagem != null and r.personagem.nome == "Cmdzinho")
	checar("troca + hop: textura nova", img.texture != null and img.texture.resource_path.get_file().begins_with("cmd_neutro"), img.texture)
	checar("troca + hop: visível e em repouso", r.visible and r.modulate.a == 1.0 and r.rotation == 0.0 and r.scale == Vector2.ONE and r.position.x < 60, [r.visible, r.modulate.a, r.position])
	await _fechar(b)
	b = await _abrir("~ a\nCmdzinho: [#bravo] hm\n=> END")
	img = b.get_node("%Retrato").get_node("%Imagem")
	checar("Cmdzinho: tag desconhecida usa a padrão", img.texture != null and img.texture.resource_path.get_file().begins_with("cmd_neutro"), img.texture)
	await _fechar(b)

	# Avançar: completa, depois próxima fala
	b = await _abrir("~ a\nKath: Primeira fala bem comprida para digitar devagar.\nKath: Segunda.\n=> END")
	var texto: RichTextLabel = b.get_node("%Texto")
	checar("começa digitando", texto.is_typing)
	checar("indicador escondido ao digitar", not b.get_node("%Indicador").visible)
	b.avancar()
	checar("avancar completa a fala", texto.visible_characters == texto.get_total_character_count(), texto.visible_characters)
	checar("indicador aparece", b.get_node("%Indicador").visible)
	b.avancar()
	for i in 30:
		await process_frame
	checar("avancar vai para a segunda", texto.dialogue_line.text == "Segunda.", texto.dialogue_line.text)
	await _fechar(b)

	# Escolhas
	b = await _abrir("~ a\nKath: Escolhe.\n- A\n\tset escolha = \"a\"\n- B\n\tset escolha = \"b\"\n=> END")
	await _esperar_digitar(b)
	checar("escolhas visíveis", b.get_node("%Escolhas").visible)
	var itens: Array = b.get_node("%Escolhas").get_menu_items()
	checar("duas escolhas", itens.size() == 2, itens.size())
	if itens.size() == 2:
		checar("primeira focada e marcada", itens[0].has_focus() and itens[0].text.begins_with("▶ ") and not itens[1].text.begins_with("▶"), [itens[0].text, itens[1].text])
		await process_frame
		await process_frame
		checar("focada inclina e cresce", absf(itens[0].rotation_degrees + 1.5) < 0.1 and absf(itens[0].scale.x - 1.06) < 0.01, [itens[0].rotation_degrees, itens[0].scale])
	b.avancar()
	await process_frame
	checar("avancar com escolhas não faz nada", b.get_node("%Escolhas").visible and ctx.escolha == "")
	var terminou := {"ok": false}
	var ao_terminar := func(_r): terminou.ok = true
	dm.dialogue_ended.connect(ao_terminar)
	b.escolher(1)
	for i in 30:
		await create_timer(0.05).timeout
		if not is_instance_valid(b):
			break
	checar("escolher(1) define escolha = b", ctx.escolha == "b", ctx.escolha)
	checar("fim: balão liberado", not is_instance_valid(b))
	checar("fim: dialogue_ended", terminou.ok)
	dm.dialogue_ended.disconnect(ao_terminar)
	await _fechar(b)

	# Velocidade instantânea
	opcoes.velocidade_texto = opcoes.Velocidade.INSTANTANEA
	b = await _abrir("~ a\nKath: Isso aparece de uma vez só.\n=> END")
	await process_frame
	texto = b.get_node("%Texto")
	checar("instantânea: tudo visível", texto.visible_characters == texto.get_total_character_count() and texto.visible_characters > 0, texto.visible_characters)
	await _fechar(b)

	# Avanço automático
	opcoes.avanco_automatico = true
	b = await _abrir("~ a\nKath: Um.\nKath: Dois.\n=> END")
	texto = b.get_node("%Texto")
	await _esperar_digitar(b)
	await create_timer(opcoes.atraso_avanco(texto.get_parsed_text().length()) + 0.2).timeout
	checar("automático: segunda fala sozinha", is_instance_valid(b) and texto.dialogue_line.text == "Dois.", texto.dialogue_line.text if is_instance_valid(b) else "liberado")
	await _fechar(b)
	opcoes.avanco_automatico = true
	b = await _abrir("~ a\nKath: Escolhe.\n- A\n- B\n=> END")
	await create_timer(3.0).timeout
	checar("automático: escolhas esperam", is_instance_valid(b) and b.get_node("%Escolhas").visible)
	await _fechar(b)

	# Fala longa (com retrato: a área de texto mais estreita)
	b = await _abrir("~ a\nKath: " + "palavra ".repeat(50) + "\n=> END")
	b.avancar()
	await process_frame
	texto = b.get_node("%Texto")
	caixa = b.get_node("%Caixa")
	checar("fala longa: texto dentro da caixa", caixa.get_global_rect().encloses(texto.get_global_rect()), [caixa.get_global_rect(), texto.get_global_rect()])
	checar("fala longa: conteúdo cabe sem rolar", texto.get_content_height() <= texto.size.y, [texto.get_content_height(), texto.size.y])
	var vp := Rect2(Vector2.ZERO, Vector2(1152, 648))
	checar("fala longa: indicador na tela", vp.encloses(b.get_node("%Indicador").get_global_rect()), b.get_node("%Indicador").get_global_rect())
	await _fechar(b)

	# Animação no meio da fala
	opcoes.velocidade_texto = opcoes.Velocidade.LENTA
	b = await _abrir("~ a\nKath: Oi.\nKath: Oi [do animar(\"hop\")]tudo bem?\n=> END")
	await _esperar_digitar(b)
	await create_timer(0.5).timeout
	b.avancar()
	r = b.get_node("%Retrato")
	texto = b.get_node("%Texto")
	for i in 30:
		await process_frame
		if texto.dialogue_line.text.begins_with("Oi tudo"):
			break
	var antes := false
	var durante := false
	for i in 300:
		if texto.visible_characters < 3:
			antes = antes or r.em_animacao
		else:
			durante = durante or r.em_animacao
		if not texto.is_typing:
			break
		await process_frame
	checar("animar no meio: parado antes", not antes)
	checar("animar no meio: anima durante", durante)
	await _fechar(b)

	# Fim por avancar
	terminou.ok = false
	dm.dialogue_ended.connect(ao_terminar)
	b = await _abrir("~ a\nKath: Tchau.\n=> END")
	b.avancar()
	b.avancar()
	await create_timer(0.6).timeout
	checar("fim por avancar: liberado", not is_instance_valid(b))
	checar("fim por avancar: dialogue_ended", terminou.ok)
	await _fechar(b)

	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
