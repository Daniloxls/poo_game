extends "res://tests/battle/battle_test.gd"
## Fluxo completo da batalha com os autoloads reais (Battle, Party, Inventory).

var battle
var turin
var won := 0
var lost := 0
var pops := 0


## Nó que roda no passo de física, como o jogador no mapa.
class PhysicsProbe extends Node:
	var cb: Callable

	func _physics_process(_d) -> void:
		cb.call()


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
	await controls()
	await end_panel(false)
	await end_panel(true)
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
	eq(tag + ": inventário processa", root.get_node("Inventory").process_mode, Node.PROCESS_MODE_INHERIT)


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
	eq("durante a ação: mensagem", battle.console.error_label().text,
		"Turin.turno() ainda está executando: espere o retorno")
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
	var vitorias := won
	turin.hp = 10
	battle.start_battle("res://scenes/encounters/muscleguy.tscn")
	check("Montanha: turno de Turin", await turin_turn())
	var m = battle.context().find_combatant("Montanha")
	m.max_hp = 1000  # nem um crítico encerra antes do turno dele
	m.hp = 1000
	await battle.run_command(cmd("Turin.atacar(Montanha)"), true)
	check("Montanha: derrota", await wait_until(func(): return lost > 0))
	eq("battle_lost uma vez", lost, 1)
	eq("Montanha: sem vitória extra", won, vitorias)
	eq("Montanha: escondida", battle.visible, false)
	eq("Montanha: time_scale", Engine.time_scale, 1.0)


func key(k: int, unicode := 0) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.unicode = unicode
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	await process_frame
	var up := ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func joy(button: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	await process_frame
	var up := ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


## Teclado, controle e o caminho pelos botões, numa batalha só.
func controls() -> void:
	turin.hp = turin.get_max_hp()
	var inv = root.get_node("Inventory")
	battle.start_battle("res://scenes/encounters/testdummy.tscn")
	check("controles: turno de Turin", await turin_turn())
	check("efeitos acima do grupo", battle.fx.overlay.layer > root.get_node("Party").layer)
	var dummy = battle.context().find_combatant("Boneco_de_Teste")
	dummy.max_hp = 1000
	dummy.hp = 1000
	await process_frame  # o menu pega o foco no fim do quadro em que o turno abre
	# "e" digitado no console não abre o inventário
	battle.console.open()
	await process_frame
	await key(KEY_E, 101)
	eq("console recebe o e", battle.console.text, "e")
	eq("inventário fica fechado", inv.esta_aberto(), false)
	battle.console.text = ""
	battle.console.close()
	# combo cheio pelo console, para o botão zerar depois
	await battle.run_command(cmd("Turin.atacar(Boneco_de_Teste)"), true)
	eq("controles: combo 1", battle.combo.level, 1)
	check("controles: Turin de novo", await turin_turn())
	await process_frame
	# Esc sai do console e o teclado volta ao menu
	var chosen := []
	var on_chosen := func(s): chosen.append(s)
	battle.action_menu.skill_chosen.connect(on_chosen)
	await key(KEY_F2)
	check("F2 abre o console", battle.console.is_typing())
	await key(KEY_ESCAPE)
	check("Esc sai do console", not battle.console.is_typing())
	await key(KEY_DOWN)
	await key(KEY_UP)
	await key(KEY_ENTER)
	battle.action_menu.skill_chosen.disconnect(on_chosen)
	eq("Esc devolve o foco ao menu", chosen.map(func(s): return BattleContext.method_name(s)), ["atacar"])
	# caminho do botão: seletor de alvo aceita e o comando roda, zerando o combo
	check("seletor de alvo aberto", battle.target_selector._active)
	var antes := pops
	await key(KEY_ENTER)
	check("botão: Turin de novo", await turin_turn())
	check("botão: o turno andou", pops > antes, pops)
	eq("botão zera o combo", battle.combo.level, 0)
	check("botão: console sem foco", not battle.console.is_typing())
	battle.console.close()
	await process_frame
	# controle: B com a linha vazia fecha o console e volta ao menu
	await joy(JOY_BUTTON_Y)
	check("controle abre o console", battle.console.visible)
	await joy(JOY_BUTTON_B)
	check("B fecha o console", not battle.console.visible)
	var f = root.gui_get_focus_owner()
	check("B devolve o foco ao menu", f in battle.action_menu.buttons(), f)
	# método sem implementação: bolha de erro e o turno não se perde
	var proteger := SKILL.new()
	proteger.SKLL_NAME = "Proteger"
	battle.pacing.instant = false  # para a bolha aparecer
	battle.action_menu.skill_chosen.emit(proteger)
	await process_frame
	var bolha: Array = battle.fx.overlay.get_children().filter(func(n): return n is PanelContainer)
	check("bolha de erro", not bolha.is_empty() and bolha[0].get_child(0).text == "proteger() ainda não tem implementação",
		bolha.map(func(b): return b.get_child(0).text))
	battle.pacing.instant = true
	eq("sem implementação (botão): turno fica", battle._acting, turin)
	check("sem implementação (botão): menu volta", battle.action_menu.visible)
	var r := ResolvedCommand.new()
	r.ok = true
	r.actor = turin
	r.skill = proteger
	await battle.run_command(r, true)
	eq("sem implementação (console): turno fica", battle._acting, turin)
	dummy.hp = 1
	await fight_until_won("Boneco_de_Teste")
	check_clean("controles")


## Fim de batalha: F2 não abre o console; o Espaço que fecha o painel não vira
## "interact" no mapa (no boneco do tutorial isso começaria outra luta).
func end_panel(same_frame: bool) -> void:
	var tag := "painel (mesmo quadro)" if same_frame else "painel"
	var ps = root.get_node("PlayerState")
	turin.hp = turin.get_max_hp()
	var antes := won
	battle.start_battle("res://scenes/encounters/testdummy.tscn")
	check(tag + ": turno de Turin", await turin_turn())
	battle.context().find_combatant("Boneco_de_Teste").hp = 1
	battle.pacing.instant = false  # o painel só aparece fora do modo instantâneo
	var end := Time.get_ticks_msec() + 30000
	while not battle.victory_panel.visible and Time.get_ticks_msec() < end:
		if battle._acting == turin:
			battle.run_command(cmd("Turin.atacar(Boneco_de_Teste)"), true)
		await process_frame
	check(tag + ": painel de vitória", battle.victory_panel.visible)
	await create_timer(0.5, true, false, true).timeout  # passa da trava de abertura
	await key(KEY_F2)
	check(tag + ": F2 não abre o console", not battle.console.visible)
	var hits := [0]
	var probe := PhysicsProbe.new()
	probe.cb = func():
		if Input.is_action_just_pressed("interact") and ps.is_able_to_move():
			hits[0] += 1
			battle.start_battle("res://scenes/encounters/testdummy.tscn")
	root.add_child(probe)
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.physical_keycode = KEY_SPACE
	ev.unicode = 32
	ev.pressed = true
	Input.parse_input_event(ev)
	if not same_frame:
		for i in 3:
			await physics_frame
		check(tag + ": apertar não fecha", battle.victory_panel.visible)
	var up := ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	for i in 6:
		await physics_frame
	await process_frame
	eq(tag + ": vitória", won, antes + 1)
	eq(tag + ": interact não vazou", hits[0], 0)
	eq(tag + ": nenhuma batalha nova", battle._running, false)
	probe.queue_free()
	battle.pacing.instant = true
	check_clean(tag)
