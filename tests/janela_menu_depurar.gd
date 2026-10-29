extends SceneTree
## Menu "Depurar" com cliques de verdade. Precisa de janela (move o cursor):
## godot --path . --script res://tests/janela_menu_depurar.gd

var falhas := 0


func checar(titulo: String, ok: bool) -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo)
	if not ok:
		falhas += 1


func _clique(pos: Vector2, botao := MOUSE_BUTTON_RIGHT) -> void:
	Input.warp_mouse(pos)
	await process_frame
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	Input.parse_input_event(m)
	Input.flush_buffered_events()
	await physics_frame
	await process_frame
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = botao
		e.pressed = pressed
		e.position = pos
		e.global_position = pos
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await process_frame
	for i in 3:
		await process_frame


func _initialize() -> void:
	var cidade = load("res://scenes/chapter_one/festival_city/City.tscn").instantiate()
	root.add_child(cidade)
	for i in 10:
		await process_frame
	var turin = get_first_node_in_group("Player")
	var teste = cidade.get_node("TesteDeForcaNPC/TesteDeForca")
	turin.global_position = teste.global_position + Vector2(0, 2500)
	for i in 20:
		await process_frame
	var p: PopupMenu = teste.menu_button.get_popup()
	var alvo: Vector2 = teste.menu_button.get_global_transform_with_canvas() * (teste.menu_button.size / 2)

	await _clique(alvo)
	checar("direito no objeto abre", p.visible)
	await _clique(Vector2(100, 550))
	checar("direito longe fecha", not p.visible)
	await _clique(Vector2(1000, 100))
	checar("direito longe de novo não abre", not p.visible)
	await _clique(alvo + Vector2(60, 30))
	checar("abre onde clicou", p.visible and Vector2(p.position).distance_to(alvo + Vector2(60, 30)) < 2)
	await _clique(alvo + Vector2(-80, 10))
	checar("direito no objeto com menu aberto só fecha", not p.visible)
	await _clique(alvo)
	turin.global_position += Vector2(0, 300)
	for i in 5:
		await process_frame
	checar("câmera andou: menu fecha", not p.visible)
	alvo = teste.menu_button.get_global_transform_with_canvas() * (teste.menu_button.size / 2)
	await _clique(alvo)
	await _clique(Vector2(p.position) + Vector2(p.size) / 2, MOUSE_BUTTON_LEFT)
	checar("Depurar abre o painel de código", root.get_node("JavaRuntime")._camada.visible and not p.visible)

	print("\n%s" % ("TUDO OK" if falhas == 0 else "%d falha(s)" % falhas))
	quit(falhas)
