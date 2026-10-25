extends "res://tests/battle/battle_test.gd"
## Fluxo completo da batalha com os autoloads reais (Battle, Party, Inventory).

var battle
var turin
var won := 0
var lost := 0
var pops := 0


func _initialize() -> void:
	await process_frame
	battle = root.get_node("Battle")
	turin = root.get_node("Party/Turin")
	battle.pacing.instant = true
	battle.battle_won.connect(func(): won += 1)
	battle.battle_lost.connect(func(): lost += 1)
	battle.stack.popped.connect(func(_f, _r): pops += 1)

	await dummy_fight()
	await second_battle()
	await two_dummies()
	await montanha()
	finish()


## Espera cond() virar true (tempo real, os painéis animam mesmo no modo instantâneo).
func wait_until(cond: Callable, secs := 10.0) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return false


func turin_turn() -> bool:
	return await wait_until(func(): return battle._acting == turin)


func cmd(text: String) -> ResolvedCommand:
	var r := CommandResolver.resolve(CommandParser.parse(text), battle.context())
	check("comando válido: " + text, r.ok, r.error.message if r.error else "")
	return r


func top_down() -> Array:
	var l: Array = battle.stack.frames().map(func(f): return f.label())
	l.reverse()
	return l


## Ataca o alvo até vencer (no máximo 20 turnos do jogador).
func fight_until_won(alvo: String) -> void:
	var antes := won
	for i in 20:
		if not await wait_until(func(): return battle._acting == turin or won > antes):
			break
		if won > antes:
			break
		await battle.run_command(cmd("Turin.atacar(%s)" % alvo), true)
	await wait_until(func(): return won > antes)


func check_clean(tag: String) -> void:
	eq(tag + ": escondida", battle.visible, false)
	eq(tag + ": time_scale", Engine.time_scale, 1.0)
	eq(tag + ": interface liberada", root.get_node("PlayerState").is_on_interface(), false)
	eq(tag + ": combo zerado", battle.combo.level, 0)
	eq(tag + ": pilha vazia", battle.stack.size(), 0)


func dummy_fight() -> void:
	turin.hp = turin.get_max_hp()
	battle.start_battle("res://scenes/encounters/testdummy.tscn")
	check("turno de Turin", await turin_turn())
	eq("pilha de cima para baixo", top_down(), ["Turin.turno()", "Boneco_de_Teste.turno()"])
	eq("contexto: Turin ativo", battle.context().active, turin)
	battle.console.text = "Turin.ata"  # texto pela metade que não pode vazar para a próxima
	await fight_until_won("Boneco_de_Teste")
	eq("battle_won uma vez", won, 1)
	eq("sem derrota", lost, 0)
	check_clean("vitória")


# Review Focus 1: a segunda batalha não herda nada da primeira.
func second_battle() -> void:
	turin.hp = turin.get_max_hp()
	battle.start_battle("res://scenes/encounters/testdummy.tscn")
	# console aberto antes do primeiro turno: contexto novo, sem texto velho
	battle.console.open()
	eq("2ª: console sem texto velho", battle.console.text, "")
	check("2ª: sugestões da batalha nova", "Boneco_de_Teste" in battle.console.suggestion_labels(),
		battle.console.suggestion_labels())
	battle.console.close()
	check("2ª: turno de Turin", await turin_turn())
	eq("2ª: pilha empilhada de novo", top_down(), ["Turin.turno()", "Boneco_de_Teste.turno()"])
	eq("2ª: sinais da pilha ligados uma vez", battle.stack.pushed.get_connections().size(), 1)
	var dummy = battle.context().find_combatant("Boneco_de_Teste")
	# comando digitado durante a própria ação: recusado, texto fica, nada se perde
	var ready := [0]
	var count := func(_c): ready[0] += 1
	battle.console.command_ready.connect(count)
	var typed := "Turin.atacar(Boneco_de_Teste)"
	var probe := func(_t):
		battle.console.text = typed
		battle.console.submit()
	battle.fx.hp_changed.connect(probe, CONNECT_ONE_SHOT)
	await battle.run_command(cmd("Turin.atacar(Boneco_de_Teste)"), true)
	battle.console.command_ready.disconnect(count)
	eq("durante a ação: comando não sai", ready[0], 0)
	check("durante a ação: erro visível", battle.console.error_label().visible)
	eq("durante a ação: texto fica", battle.console.text, typed)
	battle.console.text = ""
	check("2ª: comando causou dano", dummy.get_hp() < dummy.get_max_hp(), dummy.get_hp())
	eq("2ª: combo subiu", battle.combo.level, 1)
	await fight_until_won("Boneco_de_Teste")
	eq("2ª: battle_won", won, 2)
	check_clean("2ª")


# Review Focus 4: inimigo morto com o frame pausado sai da pilha; o último encerra na hora.
func two_dummies() -> void:
	turin.hp = turin.get_max_hp()
	battle.start_battle("res://tests/battle/fixtures/two_dummies.tscn")
	var b = battle.get_node("Field/Enemies/Boneco_B")
	b.nome = "Boneco_B"
	check("2 bonecos: turno de Turin", await turin_turn())
	eq("2 bonecos: pilha", top_down(), ["Turin.turno()", "Boneco_B.turno()", "Boneco_de_Teste.turno()"])
	var a = battle.context().find_combatant("Boneco_de_Teste")
	a.hp = 1
	await battle.run_command(cmd("Turin.atacar(Boneco_de_Teste)"), true)
	# o frame do pausado foi removido; o de Turin já retornou (pop no fim da ação)
	eq("frame do pausado sumiu", top_down(), ["Boneco_B.turno()"])
	check("2 bonecos: Turin de novo", await turin_turn())
	b.hp = 1
	pops = 0
	var at_win := [-1]
	var probe := func(): at_win[0] = pops
	battle.battle_won.connect(probe, CONNECT_ONE_SHOT)
	await battle.run_command(cmd("Turin.atacar(Boneco_B)"), true)
	check("2 bonecos: vitória", await wait_until(func(): return won == 3))
	eq("vitória antes de desempilhar", at_win[0], 0)
	check_clean("2 bonecos")


func montanha() -> void:
	var city = load("res://scenes/chapter_one/festival_city/City.tscn").instantiate()
	root.add_child(city)
	current_scene = city
	await process_frame
	turin.hp = 10
	battle.start_battle("res://scenes/encounters/muscleguy.tscn")
	check("Montanha: turno de Turin", await turin_turn())
	var m = battle.context().find_combatant("Montanha")
	m.max_hp = 1000  # nem um crítico encerra antes do turno dele
	m.hp = 1000
	await battle.run_command(cmd("Turin.atacar(Montanha)"), true)
	check("Montanha: derrota", await wait_until(func(): return lost > 0))
	eq("battle_lost uma vez", lost, 1)
	eq("Montanha: sem vitória extra", won, 3)
	eq("Montanha: escondida", battle.visible, false)
	eq("Montanha: time_scale", Engine.time_scale, 1.0)
