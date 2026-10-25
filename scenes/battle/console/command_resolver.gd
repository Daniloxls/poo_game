class_name CommandResolver
extends RefCounted
## Confere o comando já analisado contra a batalha; devolve erro que ensina ou o comando pronto.

const NAO_EXISTE := "Não existe ninguém chamado '%s' nesta batalha"


static func _fail(msg: String, span: Vector2i, hint := "") -> ResolvedCommand:
	var r := ResolvedCommand.new()
	r.error = ConsoleError.make(msg, span, hint)
	return r


static func resolve(p: ParsedCommand, ctx: BattleContext) -> ResolvedCommand:
	if p.error != null:
		var r := ResolvedCommand.new()
		r.error = p.error
		return r
	var actor = ctx.find_combatant(p.object_name)
	if actor == null:
		return _fail(NAO_EXISTE % p.object_name, p.object_span)
	if not actor.is_party_member():
		return _fail("%s é um inimigo: você só controla o seu grupo" % actor.get_nome(), p.object_span)
	if actor != ctx.active:
		if ctx.active == null and actor == ctx.running:  # a ação dele está rodando
			return _fail("%s.turno() ainda está executando: espere o retorno" % actor.get_nome(), p.object_span)
		var dono = ctx.active if ctx.active != null else ctx.running
		var vez: String = dono.get_nome() if dono != null else "ninguém"
		return _fail("%s.turno() está pausado: é o turno de %s" % [actor.get_nome(), vez], p.object_span)

	var skill := ctx.find_skill(actor, p.method_name)
	if skill == null:
		var nomes := PackedStringArray()
		for s in actor.get_skills():
			nomes.append(BattleContext.method_name(s))
		return _fail("A classe %s não tem o método '%s'" % [actor.get_class_name(), p.method_name],
			p.method_span, "Métodos de %s: %s" % [actor.get_nome(), ", ".join(nomes)])

	if p.stage != ParsedCommand.Stage.DONE:
		var fim: int = p.arg_spans[-1].y if not p.arg_spans.is_empty() else p.method_span.y + 1
		return _fail("Comando incompleto: falta ')'", Vector2i(fim, fim + 1))

	var params := BattleContext.params_of(skill)
	if p.args.size() != params.size():
		return _fail("%s espera %d %s (%s), recebeu %d" % [p.method_name, params.size(),
			"argumento" if params.size() == 1 else "argumentos", ", ".join(params), p.args.size()],
			p.method_span)

	var kinds := BattleContext.param_kinds(skill)

	var res := ResolvedCommand.new()
	res.actor = actor
	res.skill = skill
	for i in p.args.size():
		var nome: String = p.args[i]
		var sp: Vector2i = p.arg_spans[i]
		if kinds[i] == SKILL.Targets.ITE:
			var item := ctx.find_item(nome)
			if item == null:
				return _fail("Você não tem %s na mochila" % nome, sp)
			res.targets.append(item)
			continue
		var alvo = ctx.find_combatant(nome)
		if alvo == null:
			return _fail(NAO_EXISTE % nome, sp)
		var n: String = alvo.get_nome()
		if kinds[i] == SKILL.Targets.ENEMY and alvo.is_party_member():
			return _fail("%s espera um inimigo, mas %s é do seu grupo" % [p.method_name, n], sp)
		if kinds[i] == SKILL.Targets.ALLY and not alvo.is_party_member():
			return _fail("%s espera alguém do seu grupo, mas %s é inimigo" % [p.method_name, n], sp)
		if not alvo.is_alive():
			var msg := "%s está fora de combate (HP 0)" if alvo.is_party_member() else "%s é null: já foi destruído"
			return _fail(msg % n, sp)
		res.targets.append(alvo)
	res.ok = true
	return res
