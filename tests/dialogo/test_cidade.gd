extends SceneTree

var passou := 0
var falhou := 0
var terminou := false
var vistos: Array = []        # nomes que apareceram na última _jogar
var conversas := 0
var retrato_do_cmd := false   # o Cmdzinho apareceu com retrato


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func _initialize() -> void:
	_rodar()


func _baloes() -> Array:
	return root.find_children("*", "", true, false).filter(func(n): return n.has_method("escolher") and n.has_method("avancar"))


func _conversar(no: Node) -> void:
	await no.interaction()
	terminou = true


# Abre a conversa do nó, confere o 1º nome e avança até o fim.
func _conversa_simples(rotulo: String, no: Node) -> void:
	terminou = false
	_conversar(no)
	var nome := ""
	for i in 300:
		await process_frame
		var bs := _baloes()
		if not bs.is_empty() and bs[0].get_node("%Texto").dialogue_line != null:
			nome = bs[0].get_node("%NomeTag").text
			break
	checar("%s: abre balão" % rotulo, root.get_node("Dialogo").ativo)
	checar("%s: NomeTag preenchido" % rotulo, nome != "", nome)
	for i in 1500:
		await process_frame
		if terminou:
			break
		var bs := _baloes()
		if bs.is_empty():
			continue
		if bs[0].get_node("%Escolhas").visible:
			bs[0].escolher(0)
		else:
			bs[0].avancar()
	checar("%s: termina" % rotulo, terminou and not root.get_node("Dialogo").ativo)


# Roda uma corrotina de conversa escolhendo sempre a opção `indice`.
func _jogar(rotulo: String, c: Callable, indice: int) -> void:
	terminou = false
	vistos = []
	retrato_do_cmd = false
	var envelope := func():
		await c.call()
		terminou = true
	envelope.call()
	for i in 1500:
		await process_frame
		if terminou:
			break
		var bs := _baloes()
		if bs.is_empty():
			continue
		var nome_atual: String = bs[0].get_node("%NomeTag").text
		if nome_atual != "" and not vistos.has(nome_atual):
			vistos.append(nome_atual)
		if nome_atual == "Cmdzinho" and bs[0].get_node("%Retrato").visible:
			retrato_do_cmd = true
		if bs[0].get_node("%Escolhas").visible:
			bs[0].escolher(indice)
		else:
			bs[0].avancar()
	checar("%s: termina" % rotulo, terminou and not root.get_node("Dialogo").ativo)


class Contador:
	var n := 0
	var ultimo := ""
	func play() -> void:
		n += 1
	func start_battle(caminho: String) -> void:
		n += 1
		ultimo = caminho
	func hide() -> void:
		pass
	func show() -> void:
		pass


func _excalibur_e_tatame(cidade: Node) -> void:
	var tickets = cidade.find_child("Tickets")
	var exc = cidade.get_node("ExcaliburNPC")
	var espada := Contador.new()
	exc.sword_scene = espada
	await _jogar("excalibur 0 tickets", exc.interaction, 0)
	checar("excalibur sem tickets: cutscene não toca", espada.n == 0 and not exc.espada_tirada)
	tickets.recieve_tickets(30)
	await _jogar("excalibur 30 tickets", exc.interaction, 0)
	checar("excalibur com tickets: cutscene toca", espada.n == 1 and exc.espada_tirada, espada.n)

	var tat = cidade.get_node("TatameNPC")
	var luta := Contador.new()
	tat.battle = luta
	await _jogar("tatame sim", tat.interaction, 0)
	checar("tatame sim: inicia a batalha", luta.n == 1 and luta.ultimo == "res://scenes/encounters/muscleguy.tscn", luta.ultimo)
	await _jogar("tatame não", tat.interaction, 1)
	checar("tatame não: não inicia", luta.n == 1)

	var antes: int = tickets.get_tickets()
	await _jogar("tatame vitória", tat._on_city_battle_won, 1)
	checar("vitória: mentor", root.get_node("Historia").montanha == "mentor", root.get_node("Historia").montanha)
	checar("vitória: +10 tickets", tickets.get_tickets() == antes + 10)
	await _jogar("tatame descansando", tat.interaction, 0)
	checar("descansando não inicia luta", luta.n == 1)

	var heroi = root.get_node("Party").get_children()[0]
	heroi.set_hp(1)
	await _jogar("tatame derrota", tat._on_city_battle_lost, 0)
	checar("derrota: cura o grupo", heroi.get_hp() == heroi.get_max_hp())


func _forca_e_tritomos(cidade: Node) -> void:
	var tickets = cidade.find_child("Tickets")
	var forca = cidade.get_node("TesteDeForcaNPC")
	var hist = root.get_node("Historia")
	hist.cmdzinho_resgatado = false
	Engine.time_scale = 20.0   # acelera as caminhadas (tweens) do teste
	await _jogar("força não", forca.interaction, 1)
	checar("força não: não tenta", forca.erros == 0 and not forca.game_won)
	await _jogar("força perde sem Cmdzinho", forca.interaction, 0)
	checar("perdeu sem dica do Cmdzinho", forca.erros == 0 and not vistos.has("Cmdzinho"), vistos)
	hist.cmdzinho_resgatado = true
	await _jogar("força perde com Cmdzinho", forca.interaction, 0)
	checar("perdeu e Cmdzinho dá dica com retrato", forca.erros == 1 and vistos.has("Cmdzinho") and retrato_do_cmd, vistos)
	for i in 3:
		await _jogar("força perde %d" % i, forca.interaction, 0)
	checar("erros param em 3", forca.erros == 3, forca.erros)
	hist.cmdzinho_resgatado = false

	var antes: int = tickets.get_tickets()
	forca.teste.codigo_editado = forca.teste.get_codigo_java_atual().replace("forca > 10", "forca > 3")
	await _jogar("força ganha", forca.interaction, 0)
	checar("ganhou: +10 tickets", forca.game_won and tickets.get_tickets() == antes + 10, tickets.get_tickets())
	await _jogar("força já ganhou", forca.interaction, 0)
	checar("já ganhou: sem novo teste", tickets.get_tickets() == antes + 10)
	checar("já ganhou: Apresentador fala", vistos.has("Apresentador"), vistos)

	Engine.time_scale = 1.0
	var tenda = cidade.get_node("TendaVidente")
	antes = tickets.get_tickets()
	# código com erro: Tritomos só diz que a bola está embaçada, sem tickets
	tenda.codigo_editado = tenda.get_codigo_java_atual().replace("return resposta;", "return 5;")
	tenda.pensamento_field.text = "lua"
	await _jogar("tritomos embaçada", tenda._on_button_pressed, 0)
	checar("embaçada: Tritomos fala, sem tickets, continua na tenda", vistos.has("Tritomos") and tickets.get_tickets() == antes and not tenda.bilhete.visible, [vistos, tickets.get_tickets() - antes])
	tenda.codigo_editado = tenda.get_codigo_java_atual().replace("return 5;", "return \"sol\";")
	tenda.pensamento_field.text = "lua"
	var duas_vezes := func():
		tenda._on_button_pressed()   # sem await: o 2º clique chega durante a conversa
		await tenda._on_button_pressed()
		while tenda.conversando:
			await process_frame
	await _jogar("tritomos errou (2 cliques)", duas_vezes, 0)
	checar("tritomos: escolha verdade", hist.tritomos == "verdade", hist.tritomos)
	checar("tritomos: +10 tickets uma vez só", tickets.get_tickets() == antes + 10, tickets.get_tickets() - antes)
	checar("tritomos: foi embora", tenda.bilhete.visible)


func _contar_fim(_r = null) -> void:
	conversas += 1


func _cutscene_espada(cidade: Node) -> void:
	var cena = cidade.get_node("Cutscene")
	# A camada "wall" (z 1) cobria tudo da cutscene com z 0: a pedra, o Runis e o vulto sumiam.
	var parede: Node2D = cidade.get_node("TileMap/wall")
	var z := func(n: String) -> int: return cena.z_index + cena.get_node(n).z_index   # z relativo ao Cutscene
	checar("espada: atores acima da camada wall", z.call("Stone") >= parede.z_index and z.call("NpcChutado") >= parede.z_index, [z.call("Stone"), parede.z_index])
	checar("espada: vulto e Kath escondidos até entrarem", not cena.get_node("AntiPOO").visible and not cena.get_node("Kath").visible)
	root.get_node("DialogueManager").dialogue_ended.connect(_contar_fim)
	var y0: float = cena.magic.position.y
	var y_na_cena_6 := -1.0
	var escuro_na_cena_1 := -1.0
	cena.play()
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < 40000 and not cena.continua.visible:
		await process_frame
		var bs := _baloes()
		if not bs.is_empty():
			if conversas == 0 and escuro_na_cena_1 < 0.0:
				escuro_na_cena_1 = cena.get_node("BlackScreen/ColorRect").color.a
			if conversas == 5 and y_na_cena_6 < 0.0:
				y_na_cena_6 = cena.magic.position.y - y0 + 1.0   # 1 + deslocamento da magia
			bs[0].avancar()
	checar("espada: tela limpa quando a cena_1 começa", is_zero_approx(escuro_na_cena_1), escuro_na_cena_1)
	checar("espada: cena_6 começa antes da magia terminar", y_na_cena_6 > 0.0 and y_na_cena_6 < 2000.0, y_na_cena_6)
	checar("espada: label continua visível", cena.continua.visible)
	checar("espada: sete conversas", conversas == 7, conversas)
	root.get_node("DialogueManager").dialogue_ended.disconnect(_contar_fim)


func _rodar() -> void:
	var cidade = load("res://scenes/chapter_one/festival_city/City.tscn").instantiate()
	root.add_child(cidade)
	await process_frame
	checar("tickets começam em 0", cidade.find_child("Tickets").get_tickets() == 0)
	for n in ["NPC1", "NPC2", "NPC3", "Kath", "TendaNPC", "LutadorNPC"]:
		await _conversa_simples(n, cidade.get_node(n))

	var trocador := CharacterBody2D.new()
	trocador.name = "Trocador"
	trocador.set_script(load("res://scenes/chapter_one/festival_city/scripts/ticket_trader.gd"))
	for filho in ["AnimatedSprite2D", "AnimationPlayer"]:
		var f: Node = ClassDB.instantiate(filho)
		f.name = filho
		trocador.add_child(f)
	cidade.add_child(trocador)
	await _conversa_simples("trocador", trocador)
	await _excalibur_e_tatame(cidade)
	await _forca_e_tritomos(cidade)
	await _cutscene_espada(cidade)
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
