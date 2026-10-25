extends SceneTree

var passou := 0
var falhou := 0


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func _initialize() -> void:
	_rodar()


func _rodar() -> void:
	var elenco := root.get_node("Elenco")
	var kath: Personagem = elenco.buscar("Kath")
	var cmd: Personagem = elenco.buscar("Cmdzinho")
	var pai := Control.new()
	root.add_child(pai)
	var r: RetratoDialogo = load("res://ui/dialogue/Retrato.tscn").instantiate()
	pai.add_child(r)
	await process_frame
	r.position = Vector2(100, 200)
	var repouso := r.position
	var img: TextureRect = r.get_node("%Imagem")

	r.mostrar(kath, "neutra")
	await create_timer(0.4).timeout
	checar("mostrar: visível", r.visible)
	checar("mostrar: textura", img.texture == kath.retrato("neutra"))
	checar("mostrar: posição de repouso", r.position == repouso, r.position)

	r.mostrar(cmd, "neutro")
	await create_timer(0.7).timeout
	r.trocar_expressao("surpreso")
	checar("trocar: textura muda", img.texture == cmd.retrato("surpreso"))
	checar("trocar: em_animacao", r.em_animacao)
	await create_timer(0.5).timeout
	checar("trocar: termina", not r.em_animacao)
	checar("trocar: escala 1", r.scale == Vector2.ONE, r.scale)

	for nome in ["hop", "shake"]:
		r.animar(nome)
		await create_timer(1.0).timeout
		checar(nome + ": posição", r.position == repouso, r.position)
		checar(nome + ": rotação", r.rotation == 0.0, r.rotation)
		checar(nome + ": escala", r.scale == Vector2.ONE, r.scale)

	r.animar("slump")
	await create_timer(1.0).timeout
	checar("slump: afundou", r.position.y > repouso.y, r.position)
	r.resetar_pose()
	await create_timer(0.6).timeout
	checar("resetar_pose: repouso", r.position == repouso and r.rotation == 0.0, r.position)

	r.animar("inexistente")
	checar("animação inexistente: nada muda", r.position == repouso and r.scale == Vector2.ONE)

	r.esconder()
	await create_timer(0.4).timeout
	checar("esconder: personagem nulo", r.personagem == null)

	r.mostrar(kath, "neutra")
	await create_timer(0.4).timeout
	var parado := true
	for i in 10:
		await create_timer(0.1).timeout
		parado = parado and r.position == repouso
	checar("sem balanço ao falar", parado)

	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
