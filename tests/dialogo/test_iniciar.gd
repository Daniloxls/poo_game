extends SceneTree

var passou := 0
var falhou := 0
var dialogo: Node
var dm: Node
var terminou := false
var em_ended := {}


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


func _rodar() -> void:
	await process_frame
	dialogo = root.get_node_or_null("Dialogo")
	dm = root.get_node("DialogueManager")
	var ps: Node = root.get_node("PlayerState")
	checar("Dialogo existe", dialogo != null)
	if dialogo == null:
		_fim()
		return
	checar("pode_iniciar de início", dialogo.pode_iniciar())

	var rec = dm.create_resource_from_text("~ a\nKath: Um.\nKath: Dois.\n=> END")
	var ao_terminar := func(_r):
		em_ended["ativo"] = dialogo.ativo
		em_ended["on"] = ps.is_on_dialogue()
	dm.dialogue_ended.connect(ao_terminar)
	_iniciar_e_marcar(rec)
	for i in 60:
		await process_frame
		if not _baloes().is_empty() and _baloes()[0].get_node("%Texto").dialogue_line != null:
			break
	checar("ativo durante", dialogo.ativo)
	checar("on_dialogue durante", ps.is_on_dialogue())
	checar("pode_iniciar falso", not dialogo.pode_iniciar())
	var n := _baloes().size()
	dialogo.iniciar(rec)
	await process_frame
	checar("segundo iniciar não cria balão", _baloes().size() == n and n == 1, _baloes().size())

	# E não abre o inventário
	var inv: Node = root.get_node("Inventory")
	Input.action_press("e")
	await process_frame
	await process_frame
	Input.action_release("e")
	checar("inventário não abre em diálogo", not inv.visible)

	var b: Node = _baloes()[0]
	for i in 4:
		b.avancar()
		await process_frame
		if em_ended.has("ativo"):
			break
	for i in 60:
		if em_ended.has("ativo"):
			break
		await process_frame
	checar("no dialogue_ended ainda ativo", em_ended.get("ativo", false) and em_ended.get("on", false), em_ended)
	checar("saindo: ainda ativo e travado", is_instance_valid(b) and b.is_inside_tree() and dialogo.ativo and ps.is_on_dialogue())
	for i in 120:
		await process_frame
		if terminou:
			break
	checar("iniciar retornou", terminou)
	checar("balão saiu da árvore", not is_instance_valid(b) or not b.is_inside_tree())
	checar("ativo liberado", not dialogo.ativo)
	checar("on_dialogue liberado", not ps.is_on_dialogue())
	dm.dialogue_ended.disconnect(ao_terminar)

	# Balão liberado à força (troca de cena etc.): iniciar volta e solta o jogador.
	terminou = false
	var rec2 = dm.create_resource_from_text("~ a
Kath: Um.
Kath: Dois.
=> END")
	_iniciar_e_marcar(rec2)
	for i in 60:
		await process_frame
		if not _baloes().is_empty():
			break
	checar("forçado: abriu", _baloes().size() == 1 and dialogo.ativo)
	_baloes()[0].queue_free()
	for i in 30:
		await process_frame
		if terminou:
			break
	checar("forçado: iniciar retornou", terminou)
	checar("forçado: flags soltas", not dialogo.ativo and not ps.is_on_dialogue())
	checar("iniciar recusado devolve false", await _recusa())

	# NPC
	var npc_gd = load("res://entities/npc/npc_script.gd")
	var npc = npc_gd.new()
	var textbox: Node = root.get_node("Textbox")
	npc.texto = ["oi"] as Array[String]
	npc.interaction()
	await process_frame
	await process_frame
	checar("sem dialogo usa Textbox", textbox.get_state() != "Ready", textbox.get_state())
	textbox.change_state(0)
	ps.set_on_dialogue(false)
	npc.free()

	em_ended.clear()
	terminou = false
	npc = npc_gd.new()
	npc.dialogo = dm.create_resource_from_text("~ a\nKath: Oi.\n=> END")
	npc.interaction()
	for i in 60:
		await process_frame
		if not _baloes().is_empty():
			break
	checar("com dialogo abre balão", _baloes().size() == 1 and dialogo.ativo)
	for b2 in _baloes():
		b2.queue_free()
	textbox.change_state(0)
	ps.set_on_dialogue(false)
	npc.free()
	_fim()


func _recusa() -> bool:
	dialogo.ativo = true
	var r: bool = await dialogo.iniciar(dm.create_resource_from_text("~ a
Kath: Um.
=> END"))
	dialogo.ativo = false
	return r == false


func _iniciar_e_marcar(rec) -> void:
	await dialogo.iniciar(rec)
	terminou = true


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
