extends "res://tests/battle/battle_test.gd"
## Ganchos da batalha: habilidades travadas, dica e console desligável.

const DUMMY := "res://scenes/encounters/testdummy.tscn"

var battle
var turin
var won := 0


func _initialize() -> void:
	await process_frame
	battle = root.get_node("Battle")
	turin = root.get_node("Party/Turin")
	battle.pacing.instant = true
	battle.battle_won.connect(func(): won += 1)
	turin.hp = turin.get_max_hp()
	var attack: SKILL = load("res://rpg_classes/skills/attack.tres")
	var btn: Button = battle.get_node("UI/Root/ConsoleButton")
	var hint: Control = battle.get_node("UI/Root/Hint")

	battle.start_battle(DUMMY, false)
	check("turno de Turin", await wait_until(func(): return battle._acting == turin))
	eq("console desligado", battle.console.process_mode, Node.PROCESS_MODE_DISABLED)
	eq("botão escondido", btn.visible, false)

	battle.locked_skills = [attack]
	battle._open_menu()
	await process_frame
	check("atacar travado", battle.action_menu.buttons()[0].disabled)
	var dummy = battle.context().find_combatant("Boneco_de_Teste")
	var hp: int = dummy.get_hp()
	await battle.run_command(cmd("Turin.atacar(Boneco_de_Teste)"), false)
	eq("comando travado não age", battle._acting, turin)
	eq("comando travado: HP igual", dummy.get_hp(), hp)

	battle.show_hint("x")
	eq("dica visível", hint.visible, true)

	battle.locked_skills = []
	for i in 20:
		if won > 0 or not await wait_until(func(): return battle._acting == turin or won > 0):
			break
		if won > 0:
			break
		await battle.run_command(cmd("Turin.atacar(Boneco_de_Teste)"), true)
	await wait_until(func(): return won > 0)
	eq("trava zerada", battle.locked_skills, [])
	eq("dica some", hint.visible, false)
	eq("botão volta", btn.visible, true)

	turin.hp = turin.get_max_hp()
	battle.start_battle(DUMMY)
	eq("console volta", battle.console.process_mode, Node.PROCESS_MODE_INHERIT)
	finish()


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
