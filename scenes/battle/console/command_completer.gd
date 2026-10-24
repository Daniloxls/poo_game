class_name CommandCompleter
extends RefCounted
## Sugestões que se estreitam a cada etapa: quem age -> qual método -> qual argumento.


# Início do token sendo digitado (o cursor está no fim do texto).
static func _token_start(text: String, p: ParsedCommand) -> int:
	match p.stage:
		ParsedCommand.Stage.OBJECT:
			return p.object_span.x if p.object_name != "" else text.length()
		ParsedCommand.Stage.METHOD:
			return p.method_span.x if p.method_name != "" else text.length()
	var i := maxi(text.rfind(","), text.find("(")) + 1
	while i < text.length() and text[i] in " \t":
		i += 1
	return i


static func suggest(text: String, ctx: BattleContext) -> Array[ConsoleSuggestion]:
	var out: Array[ConsoleSuggestion] = []
	var p := CommandParser.parse(text)
	if p.stage == ParsedCommand.Stage.DONE:
		return out
	var start := _token_start(text, p)
	var head := text.substr(0, start)
	var prefix := BattleContext.normalize(text.substr(start))

	if p.stage == ParsedCommand.Stage.OBJECT:
		for c in ctx.combatants:
			if not c.is_alive():
				continue
			var n: String = c.get_nome()
			var detail := "inimigo"
			if c == ctx.active:
				detail = "%s · turno atual" % c.get_class_name()
			elif c.is_party_member():
				detail = "⏸ pausado"
			_add(out, n, detail, c == ctx.active, head, ".", prefix)
		return _enabled_first(out)

	var actor = ctx.find_combatant(p.object_name)
	if actor == null or actor != ctx.active:
		return out
	if p.stage == ParsedCommand.Stage.METHOD:
		for s in actor.get_skills():
			_add(out, BattleContext.method_name(s), s.DESCRIPTION, true, head, "(", prefix)
		return out

	# ARGS: o parâmetro atual é o número de vírgulas já digitadas
	var skill := ctx.find_skill(actor, p.method_name)
	if skill == null:
		return out
	var kinds := BattleContext.param_kinds(skill)
	var idx := text.count(",", text.find("("))
	if idx >= kinds.size():
		return out
	var suffix := ", " if idx < kinds.size() - 1 else ")"
	var kind: int = kinds[idx]
	if kind == SKILL.Targets.ITE:
		for it in ctx.items:
			if it.QUANTITY > 0:
				_add(out, it.ITEM_NAME, "x%d" % it.QUANTITY, true, head, suffix, prefix)
		return out
	for c in ctx.combatants:
		if not c.is_alive():
			continue
		var ally: bool = c.is_party_member()
		if (kind == SKILL.Targets.ENEMY and ally) or (kind == SKILL.Targets.ALLY and not ally):
			continue
		_add(out, c.get_nome(), "%s · HP %d/%d" % ["aliado" if ally else "inimigo", c.get_hp(), c.get_max_hp()],
			true, head, suffix, prefix)
	return out


static func _add(out: Array, label: String, detail: String, enabled: bool, head: String, suffix: String, prefix: String) -> void:
	if BattleContext.normalize(label).begins_with(prefix):
		out.append(ConsoleSuggestion.make(label, detail, enabled, head + label + suffix))


# Habilitadas primeiro, mantendo a ordem da lista.
static func _enabled_first(l: Array[ConsoleSuggestion]) -> Array[ConsoleSuggestion]:
	var r: Array[ConsoleSuggestion] = []
	for s in l:
		if s.enabled:
			r.append(s)
	for s in l:
		if not s.enabled:
			r.append(s)
	return r
