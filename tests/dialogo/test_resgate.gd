extends SceneTree

var passou := 0
var falhou := 0
var terminou := false


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


# Avança falas e escolhe a única resposta até o balão sumir.
func _terminar_conversa() -> void:
	for i in 1500:
		await process_frame
		if terminou:
			return
		var bs := _baloes()
		if bs.is_empty():
			continue
		var b = bs[0]
		if b.get_node("%Escolhas").visible if b.has_node("%Escolhas") else false:
			b.escolher(0)
		else:
			b.avancar()


func _rodar() -> void:
	var cidade = load("res://scenes/chapter_one/festival_city/City.tscn").instantiate()
	root.add_child(cidade)
	await process_frame
	var historia = root.get_node("Historia")
	var cmd = cidade.get_node("Cmdzinho")
	var codigo = cmd.get_node_or_null("CodigoCmdzinho")
	var seguidor = cidade.get_node("Cmdzinho_Follower")
	checar("CodigoCmdzinho existe", codigo != null)
	if codigo == null:
		_fim()
		return

	# Turin sobe até a borda da fonte e a caixa de cima alcança o Cmdzinho.
	for i in 3:
		await physics_frame
	var turin: CharacterBody2D = get_first_node_in_group("Player")
	var p_antes := turin.global_position
	turin.global_position = cmd.global_position + Vector2(0, 2500)
	for i in 400:
		if turin.move_and_collide(Vector2.UP * 10):
			break
	var caixa_de: Callable = func(cs: CollisionShape2D): return cs.global_transform * cs.shape.get_rect()
	var caixa: Rect2 = caixa_de.call(turin.get_node("Collision_interact/Box_up"))
	var alcanca := [cmd.get_node("Area2D/CollisionShape2D"), codigo.get_node("Area2D/CollisionShape2D")].any(func(cs): return caixa_de.call(cs).intersects(caixa))
	checar("Turin alcança o Cmdzinho da borda da fonte", alcanca, caixa)
	turin.global_position = p_antes

	checar("seguidor começa escondido", not seguidor.visible)
	var p0: Vector2 = seguidor.position
	for i in 5:
		await physics_frame
	checar("seguidor não se mexe", seguidor.position == p0, seguidor.position)

	checar("código original: não está salvo", codigo.esta_salvo() == false, codigo.ultimo_erro)
	codigo.codigo_editado = codigo.get_codigo_java_atual().replace("this.afundar();", "this.voar();")
	checar("código com erro: não salvo", codigo.esta_salvo() == false)
	checar("e guarda o erro", codigo.ultimo_erro != "")
	codigo.codigo_editado = codigo.get_codigo_java_atual().replace("this.voar();", "this.nadar();")
	checar("nadar(): salvo", codigo.esta_salvo() == true, codigo.ultimo_erro)

	codigo.resetar_codigo_java()
	_conversar(cmd)
	for i in 120:
		await process_frame
		if not _baloes().is_empty() and _baloes()[0].get_node("%Texto").dialogue_line != null:
			break
	checar("afogando: balão abre com ???", not _baloes().is_empty() and _baloes()[0].get_node("%NomeTag").text == "???")
	await _terminar_conversa()
	checar("afogando não resgata", not historia.cmdzinho_resgatado and cmd.visible)

	# Space cai na área grande do CodigoCmdzinho: ela repassa ao NPC.
	terminou = false
	_conversar(codigo)
	for i in 120:
		await process_frame
		if not _baloes().is_empty() and _baloes()[0].get_node("%Texto").dialogue_line != null:
			break
	checar("CodigoCmdzinho.interaction abre a conversa do Cmdzinho", not _baloes().is_empty() and _baloes()[0].get_node("%NomeTag").text == "???")
	await _terminar_conversa()

	codigo.codigo_editado = codigo.get_codigo_java_atual().replace("this.afundar();", "this.nadar();")
	terminou = false
	_conversar(cmd)
	await _terminar_conversa()
	checar("resgatado na história", historia.cmdzinho_resgatado)
	checar("afogado escondido", not cmd.visible)
	checar("afogado sem interação", cmd.process_mode == Node.PROCESS_MODE_DISABLED)
	checar("seguidor visível", seguidor.visible)
	checar("seguidor apareceu onde o afogado estava", seguidor.position.distance_to(cmd.position) < 300 and seguidor.position != p0, seguidor.position)
	checar("seguidor abre ~ cmdzinho", seguidor.dialogo != null and seguidor.cue_dialogo == "cmdzinho")

	# Tritomos: a janela segue aberta (e o Turin travado) depois da 1ª conversa.
	var tenda = cidade.get_node("TendaVidente")
	var ps = root.get_node("PlayerState")
	terminou = false
	_conversar(tenda)
	await _terminar_conversa()
	checar("tritomos: janela aberta mantém o jogador travado", tenda.interface.visible and ps.is_on_interface())
	tenda.close_window()
	checar("tritomos: close_window destrava", not ps.is_on_interface())

	# Voltar à cidade depois do resgate: afogado escondido, seguidor visível.
	cidade.queue_free()
	await process_frame
	historia.cmdzinho_resgatado = true
	var cidade2 = load("res://scenes/chapter_one/festival_city/City.tscn").instantiate()
	root.add_child(cidade2)
	await process_frame
	checar("reentrada: afogado escondido e desligado", not cidade2.get_node("Cmdzinho").visible and cidade2.get_node("Cmdzinho").process_mode == Node.PROCESS_MODE_DISABLED)
	checar("reentrada: seguidor visível", cidade2.get_node("Cmdzinho_Follower").visible)
	historia.cmdzinho_resgatado = false
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
