class_name BattleContext
extends RefCounted
## Estado da batalha visto pelo console: quem está em campo, quem age, itens.

var combatants: Array = []
var active = null          # entidade no topo da pilha que aceita comando agora
var running = null         # entidade no topo da pilha, mesmo com a ação dela rodando
var items: Array = []      # ITEM com QUANTITY > 0

const _ACENTOS := {"á": "a", "à": "a", "â": "a", "ã": "a", "ä": "a", "é": "e", "ê": "e",
	"í": "i", "ó": "o", "ô": "o", "õ": "o", "ú": "u", "ü": "u", "ç": "c"}


static func normalize(s: String) -> String:
	var r := s.to_lower()
	for k in _ACENTOS:
		r = r.replace(k, _ACENTOS[k])
	return r


# "Atacar" -> "atacar", "Usar Item" / "UsarItem" -> "usarItem"
static func method_name(skill: SKILL) -> String:
	var words := skill.SKLL_NAME.replace("_", " ").split(" ", false)
	var r := ""
	for i in words.size():
		var w: String = words[i]
		r += (w[0].to_lower() if i == 0 else w[0].to_upper()) + w.substr(1)
	return r


# Os TARGET da habilidade que viram parâmetro, na ordem.
static func param_kinds(skill: SKILL) -> Array:
	var r := []
	for t in skill.TARGET:
		if t in [SKILL.Targets.ITE, SKILL.Targets.ALLY, SKILL.Targets.ENEMY, SKILL.Targets.EVERYONE]:
			r.append(t)
	return r


static func params_of(skill: SKILL) -> PackedStringArray:
	var r := PackedStringArray()
	for t in param_kinds(skill):
		r.append("item" if t == SKILL.Targets.ITE else "alvo")
	return r


func find_combatant(nome: String):
	for c in combatants:
		if normalize(c.get_nome()) == normalize(nome):
			return c
	return null


func find_skill(combatant, method: String) -> SKILL:
	for s in combatant.get_skills():
		if normalize(method_name(s)) == normalize(method):
			return s
	return null


func find_item(nome: String) -> ITEM:
	for i in items:
		if i.QUANTITY > 0 and normalize(i.ITEM_NAME) == normalize(nome):
			return i
	return null
