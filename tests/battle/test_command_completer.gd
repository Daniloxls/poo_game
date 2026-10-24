extends "res://tests/battle/battle_test.gd"

var ctx: BattleContext

func _labels(text: String) -> Array:
	var r := []
	for s in CommandCompleter.suggest(text, ctx):
		r.append(s.label)
	return r

func _initialize() -> void:
	var F = load("res://tests/battle/fake_combatant.gd")
	var turin = F.new("Turin", 5, true)
	turin.skills = [load("res://rpg_classes/skills/attack.tres"), load("res://rpg_classes/skills/use_item.tres")]
	turin.classe = "Nada"
	var kath = F.new("Kath", 4, true)
	var montanha = F.new("Montanha", 3, false)
	montanha.hp = 32
	montanha.max_hp = 32
	montanha.classe = "Lutador"
	var boneco = F.new("Boneco", 2, false)
	boneco.alive = false
	var pocao := HEALTH_ITEM.new()
	pocao.ITEM_NAME = "Poção_Pequena"
	pocao.QUANTITY = 2
	ctx = BattleContext.new()
	ctx.combatants = [turin, kath, montanha, boneco]
	ctx.active = turin
	ctx.items = [pocao]

	eq("objetos", _labels(""), ["Turin", "Kath", "Montanha"])
	var s := CommandCompleter.suggest("", ctx)
	check("Kath desabilitado", s[0].enabled and not s[1].enabled and s[0].detail == "Nada · turno atual"
		and s[1].detail == "⏸ pausado" and s[2].detail == "inimigo")
	eq("prefixo", CommandCompleter.suggest("Tu", ctx)[0].result_text, "Turin.")
	eq("métodos", _labels("Turin."), ["atacar", "usarItem"])
	eq("método prefixo", CommandCompleter.suggest("Turin.at", ctx)[0].result_text, "Turin.atacar(")
	s = CommandCompleter.suggest("Turin.atacar(", ctx)
	eq("alvos", _labels("Turin.atacar("), ["Montanha"])
	eq("detalhe", s[0].detail, "inimigo · HP 32/32")
	eq("resultado", s[0].result_text, "Turin.atacar(Montanha)")
	eq("item", CommandCompleter.suggest("Turin.usarItem(", ctx)[0].result_text, "Turin.usarItem(Poção_Pequena, ")
	eq("item detalhe", CommandCompleter.suggest("Turin.usarItem(", ctx)[0].detail, "x2")
	eq("2o arg resultado", CommandCompleter.suggest("Turin.usarItem(Poção_Pequena, Tu", ctx)[0].result_text, "Turin.usarItem(Poção_Pequena, Turin)")
	eq("pausado", _labels("Kath."), [])
	eq("pronto", _labels("Turin.atacar(Montanha)"), [])
	ctx.combatants = [kath, turin, montanha]
	eq("ativo primeiro", _labels(""), ["Turin", "Kath", "Montanha"])
	finish()
