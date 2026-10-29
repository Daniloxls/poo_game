extends "res://tests/battle/battle_test.gd"
## Luta do tutorial: piso de dano, glitch que deixa Turin em 3, Atacar travado até a Poção.

const LUTA := "res://scenes/encounters/tutorial_dummy.tscn"
var boneco  # script do boneco: carregado depois dos autoloads

var battle
var inv
var turin
var won := 0
var hps := []  # HP de Turin a cada início de turno


func _initialize() -> void:
	await process_frame
	battle = root.get_node("Battle")
	inv = root.get_node("Inventory")
	boneco = load("res://scenes/encounters/tutorial_dummy.gd")
	turin = root.get_node("Party/Turin")
	battle.pacing.instant = true
	battle.battle_won.connect(func(): won += 1)
	battle.turn_started.connect(func(_w): hps.append(turin.hp))
	var hint: Label = battle.get_node("UI/Root/Hint").get_child(0)
	var use_item: SKILL = load("res://rpg_classes/skills/use_item.tres")

	eq("limitado 27-16 piso 13", boneco.dano_limitado(27, 16, 13), 14)
	eq("limitado no piso", boneco.dano_limitado(13, 16, 13), 0)
	eq("limitado 3-5 piso 1", boneco.dano_limitado(3, 5, 1), 2)
	eq("limitado em 1", boneco.dano_limitado(1, 4, 1), 0)

	inv.mochila.itens.clear()
	turin.hp = turin.get_max_hp()
	battle.start_battle(LUTA, false)
	check("turno de Turin", await turin_turn())
	eq("sem_pocao: ganha uma", pocoes(), 1)
	var dummy = battle.context().find_combatant("Boneco_de_Teste")

	eq("dica atacar", hint.text, "Escolha atacar()")
	check("dica visível", hint.get_parent().visible)
	await battle.run_command(cmd("Turin.atacar(Boneco_de_Teste)"), false)
	eq("boneco no limiar", dummy.hp, 13)

	check("turno de Turin 2", await turin_turn())
	eq("glitch deixa Turin em 3", turin.hp, 3)
	check("atacar travado", battle.action_menu.buttons()[0].disabled)
	eq("dica item", hint.text, "Atacar está fora do ar! Use usarItem() → Poção")

	# cancelar_item: a mochila fecha com Esc e o menu volta igual
	battle._on_skill_chosen(use_item)
	check("mochila aberta", await wait_until(func(): return battle.item_picker.visible))
	await press("ui_cancel")
	check("menu volta", await wait_until(func(): return battle.action_menu.visible))
	check("ainda travado", battle.action_menu.buttons()[0].disabled)
	eq("poção intacta", pocoes(), 1)

	await battle.run_command(cmd("Turin.usarItem(Poção, Turin)"), false)
	check("pocao_usada", dummy.pocao_usada)
	check("turno de Turin 3", await turin_turn())
	eq("destravado", battle.locked_skills, [])

	for i in 20:
		if won > 0 or not await wait_until(func(): return battle._acting == turin or won > 0):
			break
		if won > 0:
			break
		await battle.run_command(cmd("Turin.atacar(Boneco_de_Teste)"), false)
	await wait_until(func(): return won > 0)
	check("venceu", won > 0)
	check("Turin nunca caiu", hps.all(func(h): return h >= 1), hps)
	finish()


func pocoes() -> int:
	var n := 0
	for i in inv.mochila.itens:
		if i.ITEM_NAME == "Poção":
			n += i.QUANTITY
	return n


func turin_turn() -> bool:
	return await wait_until(func(): return battle._acting == turin)


func press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	await process_frame


func wait_until(cond: Callable, secs := 10.0) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return false


func cmd(text: String) -> ResolvedCommand:
	var r := CommandResolver.resolve(CommandParser.parse(text), battle.context())
	check("comando válido: " + text, r.ok, r.error.message if r.error else "")
	return r
