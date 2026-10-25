extends "res://tests/battle/battle_test.gd"

var ctx: BattleContext

func _r(text: String) -> ResolvedCommand:
	return CommandResolver.resolve(CommandParser.parse(text), ctx)

func _err(text: String, msg: String, span: Vector2i, hint := "") -> void:
	var r := _r(text)
	check("erro '%s'" % text, not r.ok and r.error != null and r.error.message == msg and r.error.span == span
		and (hint == "" or r.error.hint == hint),
		"%s %s %s" % [r.error.message if r.error else "null", r.error.span if r.error else "", r.error.hint if r.error else ""])

func _initialize() -> void:
	var F = load("res://tests/battle/fake_combatant.gd")
	var atk: SKILL = load("res://rpg_classes/skills/attack.tres")
	var uso: SKILL = load("res://rpg_classes/skills/use_item.tres")
	var curar := SKILL.new()
	curar.SKLL_NAME = "Curar"
	curar.TARGET = [SKILL.Targets.ALLY]
	var turin = F.new("Turin", 5, true)
	turin.skills = [atk, uso]
	turin.classe = "Nada"
	var kath = F.new("Kath", 4, true)
	var healer = F.new("Padre", 3, true)
	healer.skills = [curar]
	var montanha = F.new("Montanha", 3, false)
	var boneco = F.new("Boneco", 2, false)
	boneco.alive = false
	var pocao := HEALTH_ITEM.new()
	pocao.ITEM_NAME = "Poção_Pequena"
	pocao.QUANTITY = 2
	ctx = BattleContext.new()
	ctx.combatants = [turin, kath, healer, montanha, boneco]
	ctx.active = turin
	ctx.items = [pocao]

	eq("normalize", BattleContext.normalize("AÇÃO Poção"), "acao pocao")
	eq("method_name", BattleContext.method_name(atk), "atacar")
	eq("method_name 2", BattleContext.method_name(uso), "usarItem")
	var s2 := SKILL.new()
	s2.SKLL_NAME = "Usar Item"
	eq("method_name espaço", BattleContext.method_name(s2), "usarItem")
	eq("params_of", BattleContext.params_of(uso), PackedStringArray(["item", "alvo"]))

	var r := _r("Turin.atacar(Montanha)")
	check("atacar ok", r.ok and r.targets == [montanha] and r.actor == turin and r.skill == atk)
	check("normalização", _r("turin.ATACAR(montanha)").ok)
	r = _r("Turin.usarItem(pocao_pequena, Turin)")
	check("usarItem ok", r.ok and r.targets[0] == pocao and r.targets[1] == turin)

	_err("Zeca.atacar(Montanha)", "Não existe ninguém chamado 'Zeca' nesta batalha", Vector2i(0, 4))
	_err("Kath.atacar(Montanha)", "Kath.turno() está pausado: é o turno de Turin", Vector2i(0, 4))
	# a ação de Turin está rodando: ninguém aceita comando, mas o turno é dele
	ctx.active = null
	ctx.running = turin
	_err("Turin.atacar(Montanha)", "Turin.turno() ainda está executando: espere o retorno", Vector2i(0, 5))
	_err("Kath.atacar(Montanha)", "Kath.turno() está pausado: é o turno de Turin", Vector2i(0, 4))
	ctx.running = null
	_err("Kath.atacar(Montanha)", "Kath.turno() está pausado: é o turno de ninguém", Vector2i(0, 4))
	ctx.active = turin
	_err("Montanha.atacar(Turin)", "Montanha é um inimigo: você só controla o seu grupo", Vector2i(0, 8))
	_err("Turin.curar(Kath)", "A classe Nada não tem o método 'curar'", Vector2i(6, 11), "Métodos de Turin: atacar, usarItem")
	_err("Turin.atacar(Montanha", "Comando incompleto: falta ')'", Vector2i(21, 22))
	_err("Turin.atacar()", "atacar espera 1 argumento (alvo), recebeu 0", Vector2i(6, 12))
	_err("Turin.usarItem(a)", "usarItem espera 2 argumentos (item, alvo), recebeu 1", Vector2i(6, 14))
	_err("Turin.atacar(Kath)", "atacar espera um inimigo, mas Kath é do seu grupo", Vector2i(13, 17))
	_err("Turin.atacar(Boneco)", "Boneco é null: já foi destruído", Vector2i(13, 19))
	_err("Turin.atacar(Zeca)", "Não existe ninguém chamado 'Zeca' nesta batalha", Vector2i(13, 17))
	_err("Turin.usarItem(elixir, Turin)", "Você não tem elixir na mochila", Vector2i(15, 21))
	pocao.QUANTITY = 0
	_err("Turin.usarItem(Poção_Pequena, Turin)", "Você não tem Poção_Pequena na mochila", Vector2i(15, 28))
	ctx.active = healer
	r = _r("Padre.curar(Turin)")
	check("curar ok", r.ok and r.targets == [turin])
	_err("Padre.curar(Montanha)", "curar espera alguém do seu grupo, mas Montanha é inimigo", Vector2i(12, 20))
	kath.alive = false
	_err("Padre.curar(Kath)", "Kath está fora de combate (HP 0)", Vector2i(12, 16))
	_err("Padre atacar", "Esperava '.' depois de Padre", Vector2i(6, 12))
	finish()
