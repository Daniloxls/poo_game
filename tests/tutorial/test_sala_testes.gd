extends "res://tests/battle/battle_test.gd"
## Sala de testes em tiles: cada item do checklist abre a parede da sala certa.


func _apertar(acao: String) -> void:
	Input.action_press(acao)
	await process_frame
	await process_frame
	Input.action_release(acao)
	await process_frame


# Encosta o jogador na parede de cima, embaixo do objeto, e vê se a caixa de interação o alcança.
func _alcanca(cena, objeto) -> bool:
	var p = cena.player
	p.global_position = Vector2(objeto.global_position.x - 80, objeto.global_position.y + 1200)
	Input.action_press("up")
	for i in 20:
		await physics_frame
	Input.action_release("up")
	await physics_frame
	return p.interact_box.get_overlapping_areas().has(objeto.get_node("Area2D"))


func _initialize() -> void:
	await process_frame
	var cena = load("res://scenes/chapter_one/tutorial/Tutorial.tscn").instantiate()
	root.add_child(cena)
	await process_frame
	var hud: ChecklistHud = cena.hud
	var saidas = cena.get_node("Saidas")
	check("hud criado", hud != null)
	check("interface liberada", not root.get_node("PlayerState").is_on_interface())

	for acao in ["up", "down", "left"]:
		await _apertar(acao)
	check("3 direções não bastam", not hud.marcado("andar"))
	await _apertar("right")
	check("andar marcado", hud.marcado("andar"))
	await create_timer(0.6).timeout
	check("parede 1->2 abriu", saidas.get_node("Sala1").shape.disabled)
	check("parede 2->3 fechada", not saidas.get_node("Sala2").shape.disabled)

	cena.get_node("Bau").interaction()
	root.get_node("Textbox").text_queue.clear()
	check("só o baú não basta", not hud.marcado("interagir"))
	cena.get_node("Alavanca").interaction()
	check("interagir marcado", hud.marcado("interagir"))
	await create_timer(0.6).timeout
	check("parede 2->3 abriu", saidas.get_node("Sala2").shape.disabled)

	cena.get_node("PortaoTemporizado").atravessou.emit()
	check("correr marcado", hud.marcado("correr"))

	root.get_node("Battle").battle_won.emit()
	check("lutar e usarItem", hud.marcado("lutar") and hud.marcado("usarItem"))
	check("checklist completo", hud.completo())
	check("boneco sumiu", not cena.get_node("Dummy/DummySprite").visible)
	await create_timer(0.6).timeout
	check("parede 4->5 abriu", saidas.get_node("Sala4").shape.disabled)

	# as alavancas ficam na parede de cima: o jogador encostado tem que alcançá-las
	check("alcança a alavanca da sala 2", await _alcanca(cena, cena.get_node("Alavanca")))
	check("alcança a alavanca do portão", await _alcanca(cena, cena.get_node("PortaoTemporizado")))

	cena.player.global_position = cena.get_node("Saida/Gatilho").global_position
	for i in 3:
		await physics_frame
	check("chegou na saída", cena.chegou_na_saida)
	finish()
