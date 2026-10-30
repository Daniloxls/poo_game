extends "res://tests/battle/battle_test.gd"
## Sala do tutorial: baú dá a Poção uma vez; portão temporizado fecha sozinho (ou ao liberar o vão).

const POCAO := preload("res://scenes/items/repo/potion.tres")
var abertos := [0]


func _quantidade() -> int:
	for i in root.get_node("Inventory").mochila.itens:
		if i.ITEM_NAME == POCAO.ITEM_NAME:
			return i.QUANTITY
	return 0


func _initialize() -> void:
	await process_frame
	var antes := _quantidade()

	var bau = load("res://scenes/chapter_one/tutorial/Bau.tscn").instantiate()
	root.add_child(bau)
	bau.aberto.connect(func(): abertos[0] += 1)
	bau.interaction()
	bau.interaction()
	eq("poção ganha uma vez", _quantidade(), antes + 1)
	eq("aberto emitido uma vez", abertos[0], 1)
	check("foi_aberto", bau.foi_aberto)
	root.get_node("Textbox").text_queue.clear()

	var g = load("res://scenes/chapter_one/tutorial/PortaoTemporizado.tscn").instantiate()
	g.tempo_aberto = 0.2
	root.add_child(g)
	await process_frame
	g.interaction()
	check("aberto", g.shape.disabled)
	await create_timer(0.1).timeout
	g.interaction()
	check("timer não reiniciou", g.timer.time_left < 0.15, g.timer.time_left)
	await create_timer(0.3).timeout
	check("fechou", not g.shape.disabled)

	# jogador parado no vão: continua aberto até sair
	var p := CharacterBody2D.new()
	p.add_to_group("Player")
	var cs := CollisionShape2D.new()
	cs.shape = RectangleShape2D.new()
	p.add_child(cs)
	root.add_child(p)
	p.global_position = g.ocupado.global_position
	await physics_frame
	await physics_frame
	g.interaction()
	await create_timer(0.3).timeout
	check("ocupado segue aberto", g.shape.disabled)
	p.global_position = Vector2(-99999, -99999)
	for i in 4:
		await physics_frame
	await process_frame
	check("fechou ao sair", not g.shape.disabled)

	# atravessar: sinal uma vez, fica aberto
	var cruzou := [0]
	g.atravessou.connect(func(): cruzou[0] += 1)
	g.interaction()
	p.global_position = g.passagem.global_position
	await physics_frame
	await physics_frame
	await create_timer(0.4).timeout
	eq("atravessou uma vez", cruzou[0], 1)
	check("segue aberto", g.shape.disabled)
	finish()
