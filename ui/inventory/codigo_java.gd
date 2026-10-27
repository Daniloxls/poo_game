class_name CodigoJava
extends RefCounted
## O Java que o menu mostra para cada ação. Texto puro; colorir() faz o BBCode.

const SLOTS := {"head_slot": "cabeca", "body_slot": "corpo", "feet_slot": "pes",
		"lhand_slot": "maoE", "rhand_slot": "maoD", "acessory_slot": "acessorio"}
# atributo -> [campo do equipamento, getter]
const ATRIBUTOS := {"atk": ["ATTACK", "get_atk"], "def": ["DEFENSE", "get_def"], "vel": ["VELOCITY", "get_vel"]}
const ACENTOS := {"á": "a", "à": "a", "â": "a", "ã": "a", "é": "e", "ê": "e", "í": "i",
		"ó": "o", "ô": "o", "õ": "o", "ú": "u", "ü": "u", "ç": "c"}
const PALAVRAS_CHAVE := ["new", "int", "void", "return", "null", "private"]
const C_CHAVE := "#ff9a4d"
const C_TIPO := "#56c7e8"
const C_TEXTO := "#9bd36a"
const C_NUMERO := "#ffd23f"
const C_COMENTARIO := "#7d8597"


## "Poção Pequena" -> "pocaoPequena"
static func nome_variavel(texto: String) -> String:
	var limpo := texto.to_lower()
	for a in ACENTOS:
		limpo = limpo.replace(a, ACENTOS[a])
	var partes := limpo.replace("_", " ").split(" ", false)
	var out := ""
	for i in partes.size():
		out += partes[i] if i == 0 else partes[i].capitalize()
	return out


static func linha_usar(item: ITEM, alvo, estagio: int) -> Array[String]:
	var i := nome_variavel(item.ITEM_NAME)
	var a := nome_variavel(alvo.get_nome())
	var direto := "%s.hp = %s.hp + %s.cura;" % [a, a, i]
	var metodo := "%s.usar(%s);" % [i, a]
	match estagio:
		Progresso.Estagio.OBJETO:
			return [direto]
		Progresso.Estagio.METODOS:
			return [metodo]
	return ["✗ " + direto + "  // hp é private", metodo]


static func linha_descartar(item: ITEM) -> String:
	return "mochila.remove(%s);" % nome_variavel(item.ITEM_NAME)


static func linha_equipar(p, slot: String, item) -> String:
	var valor: String = nome_variavel(item.ITEM_NAME) if item else "null"
	return "%s.%s = %s;" % [nome_variavel(p.get_nome()), slot, valor]


static func linha_classe(p, classe: RPG_CLASS) -> String:
	var n := nome_variavel(p.get_nome())
	return "%s = new %s(%s);" % [n, classe.CLASS_NAME, n]


## O verso da carta de status: o personagem como objeto Java.
static func verso(p, _estagio: int, metodos: bool) -> Array[String]:
	var n := nome_variavel(p.get_nome())
	var classe: String = p.get_class_name()
	var argumento: String = "\"%s\"" % p.get_nome() if classe == "Personagem" else n
	var out: Array[String] = [
		"Personagem %s;" % n,
		"%s = new %s(%s);" % [n, classe, argumento],
		"%s.nome = \"%s\";" % [n, p.get_nome()],
		"%s.hp = %d;" % [n, p.get_hp()],
		"%s.pp = %d;" % [n, p.get_pp()],
	]
	for atr in ATRIBUTOS:
		var soma := "%sBase + classe.%s" % [atr, atr]
		for slot in SLOTS:
			var e = p.get_equip(slot)
			if e and e.get(ATRIBUTOS[atr][0]) != 0:
				soma += " + %s.%s" % [SLOTS[slot], atr]
		var valor: int = p.call(ATRIBUTOS[atr][1])
		if metodos:
			out.append("int get%s() { return %s; }  // %d" % [atr.capitalize(), soma, valor])
		else:
			out.append("%s.%s = %s;  // %d" % [n, atr, soma, valor])
	if not metodos:
		out.append("// métodos 🔒 ???")
		return out
	for h in p.get_habilidades():
		var params := PackedStringArray()
		for tipo in h.get_target_argument():
			params.append(tipo + " alvo")
		out.append("void %s(%s) {}" % [BattleContext.method_name(h), ", ".join(params)])
	return out


## Uma linha de Java em BBCode. "✗ " no começo = linha riscada.
static func colorir(linha: String) -> String:
	if linha.begins_with("✗ "):
		return "[s][color=%s]%s[/color][/s]" % [C_COMENTARIO, _escapar(linha.substr(2))]
	var re := RegEx.create_from_string("(//.*$)|(\"[^\"]*\")|(\\b\\d+\\b)|([A-Za-z_][A-Za-z0-9_]*)")
	var out := ""
	var fim := 0
	for m in re.search_all(linha):
		out += _escapar(linha.substr(fim, m.get_start() - fim))
		var t := m.get_string()
		var cor := ""
		if m.get_string(1) != "":
			cor = C_COMENTARIO
		elif m.get_string(2) != "":
			cor = C_TEXTO
		elif m.get_string(3) != "":
			cor = C_NUMERO
		elif t in PALAVRAS_CHAVE:
			cor = C_CHAVE
		elif t[0] == t[0].to_upper():
			cor = C_TIPO
		out += "[color=%s]%s[/color]" % [cor, _escapar(t)] if cor else _escapar(t)
		fim = m.get_end()
	return out + _escapar(linha.substr(fim))


static func _escapar(t: String) -> String:
	return t.replace("[", "[lb]")
