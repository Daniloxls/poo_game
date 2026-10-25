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
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
