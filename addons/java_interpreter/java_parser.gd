class_name JavaParser
extends RefCounted
## Etapa 2: transforma os tokens em uma AST (árvore sintática).
##
## Parser descendente recursivo. Cada nó da árvore é um Dictionary com a chave
## "k" (o tipo do nó) e "line" (linha no código, usada nas mensagens de erro).
## O resultado de parse() é um Array de declarações de classe.

const PRIMITIVES := ["int", "long", "double", "float", "boolean", "char", "byte", "short", "void"]
const MODIFIERS := ["public", "private", "protected", "static", "final", "abstract", "native"]
const ASSIGN_OPS := ["=", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^="]
# Precedência dos operadores binários, da menor para a maior.
const BIN_PREC := [
	["||"], ["&&"], ["|"], ["^"], ["&"], ["==", "!="],
	["<", ">", "<=", ">=", "instanceof"], ["+", "-"], ["*", "/", "%"],
]
const UNSUPPORTED := {
	"switch": "O comando switch ainda não é suportado. Use if / else if.",
	"case": "O comando switch/case ainda não é suportado. Use if / else if.",
	"try": "Exceções (try/catch) ainda não são suportadas.",
	"catch": "Exceções (try/catch) ainda não são suportadas.",
	"throw": "Exceções (throw) ainda não são suportadas.",
	"throws": "Exceções (throws) ainda não são suportadas.",
	"finally": "Exceções (finally) ainda não são suportadas.",
	"enum": "enum ainda não é suportado.",
}

## Preenchido quando há erro de sintaxe: { "message", "line", "col" }
var error: Dictionary = {}

var _tokens: Array = []
var _pos := 0
var _failed := false


func parse(src: String) -> Array:
	error = {}
	_failed = false
	_pos = 0
	var lx := JavaLexer.new()
	_tokens = lx.tokenize(src)
	if not lx.error.is_empty():
		error = lx.error
		_failed = true
		return []
	var classes := []
	while not _failed and not _check_t("eof"):
		if _check_kw("import") or _check_kw("package"):
			while not _check_op(";") and not _check_t("eof"):
				_advance()
			_expect_op(";")
			continue
		if _match_op(";"):
			continue
		var c = _parse_class()
		if _failed:
			return []
		classes.append(c)
	return [] if _failed else classes


# ---------------------------------------------------------------- tokens

func _tok_at(p: int) -> Dictionary:
	return _tokens[mini(p, _tokens.size() - 1)]


func _peek(off := 0) -> Dictionary:
	return _tok_at(_pos + off)


func _advance() -> Dictionary:
	var t := _peek()
	if _pos < _tokens.size() - 1:
		_pos += 1
	return t


func _check_t(t: String) -> bool:
	return _peek().t == t


func _check_op(v: String) -> bool:
	var t := _peek()
	return t.t == "op" and t.v == v


func _check_kw(v: String) -> bool:
	var t := _peek()
	return t.t == "kw" and t.v == v


func _match_op(v: String) -> bool:
	if _check_op(v):
		_advance()
		return true
	return false


func _match_kw(v: String) -> bool:
	if _check_kw(v):
		_advance()
		return true
	return false


func _describe(t: Dictionary) -> String:
	match t.t:
		"eof": return "o fim do código"
		"str": return "o texto \"%s\"" % t.v
		"char": return "o caractere '%s'" % char(t.v)
	return "'%s'" % str(t.v)


func _expect_op(v: String, hint := "") -> bool:
	if _match_op(v):
		return true
	var msg := "Esperado '%s' mas encontrado %s" % [v, _describe(_peek())]
	if v == ";" and hint == "":
		# o ';' faltando normalmente é no fim da linha anterior
		var prev := _tok_at(_pos - 1)
		if prev.line < _peek().line:
			_fail("Faltou ';' no fim da linha %d" % prev.line, prev)
			return false
	if hint != "":
		msg += " (%s)" % hint
	_fail(msg)
	return false


func _expect_ident(what := "um nome") -> Dictionary:
	var t := _peek()
	if t.t == "id":
		return _advance()
	if t.t == "kw":
		_fail("'%s' é uma palavra reservada do Java e não pode ser usada como %s" % [t.v, what])
	else:
		_fail("Esperado %s mas encontrado %s" % [what, _describe(t)])
	return {"t": "id", "v": "?", "line": t.line, "col": t.col}


func _fail(msg: String, tok = null) -> void:
	if _failed:
		return
	_failed = true
	var t: Dictionary = tok if tok != null else _peek()
	error = {"message": msg, "line": t.line, "col": t.col}


func _check_unsupported() -> bool:
	var t := _peek()
	if t.t == "kw" and UNSUPPORTED.has(t.v):
		_fail(UNSUPPORTED[t.v])
		return true
	return false


# ---------------------------------------------------------------- classes

func _parse_modifiers() -> Array:
	var mods := []
	while not _failed:
		var t := _peek()
		if t.t == "kw" and t.v in MODIFIERS:
			if t.v in mods:
				_fail("Modificador '%s' repetido" % t.v)
			mods.append(t.v)
			_advance()
		elif t.t == "op" and t.v == "@":
			# anotações como @Override são aceitas e ignoradas
			_advance()
			_expect_ident("o nome da anotação")
			if _check_op("("):
				var depth := 0
				while not _check_t("eof"):
					if _check_op("("):
						depth += 1
					elif _check_op(")"):
						depth -= 1
						if depth == 0:
							_advance()
							break
					_advance()
		elif t.t == "id" and t.v == "default" and _tok_at(_pos + 1).t != "op":
			_advance()
		else:
			break
	return mods


func _access_of(mods: Array) -> String:
	if "private" in mods:
		return "private"
	if "protected" in mods:
		return "protected"
	return "public"


func _parse_class() -> Dictionary:
	var start := _peek()
	var mods := _parse_modifiers()
	if _check_unsupported():
		return {}
	var is_interface := false
	if _match_kw("interface"):
		is_interface = true
	elif not _match_kw("class"):
		_fail("Esperado 'class' ou 'interface' mas encontrado %s" % _describe(_peek()))
		return {}
	var name_tok := _expect_ident("o nome da classe")
	var cls := {
		"name": name_tok.v, "line": start.line, "super": "", "interfaces": [],
		"is_interface": is_interface, "is_abstract": is_interface or "abstract" in mods,
		"fields": [], "methods": [], "ctors": [],
	}
	if _check_op("<"):
		_fail("Classes genéricas (com <T>) ainda não são suportadas")
		return cls
	if _match_kw("extends"):
		if is_interface:
			cls.interfaces = _parse_name_list()
		else:
			cls.super = _parse_type_name_only()
	if _match_kw("implements"):
		if is_interface:
			_fail("Uma interface usa 'extends' para herdar de outra interface, não 'implements'")
			return cls
		cls.interfaces = _parse_name_list()
	if not _expect_op("{", "abrindo o corpo da classe " + name_tok.v):
		return cls
	while not _failed and not _check_op("}"):
		if _check_t("eof"):
			_fail("Faltou '}' para fechar a classe %s" % name_tok.v, start)
			break
		if _match_op(";"):
			continue
		_parse_member(cls)
	_expect_op("}")
	return cls


func _parse_name_list() -> Array:
	var names := [_parse_type_name_only()]
	while not _failed and _match_op(","):
		names.append(_parse_type_name_only())
	return names


func _parse_type_name_only() -> String:
	var t := _parse_type()
	if t in PRIMITIVES or t.ends_with("[]"):
		_fail("Esperado o nome de uma classe ou interface")
	return t


func _parse_member(cls: Dictionary) -> void:
	var start := _peek()
	var mods := _parse_modifiers()
	if _failed or _check_unsupported():
		return
	if _check_kw("class") or _check_kw("interface"):
		_fail("Classes dentro de classes ainda não são suportadas. Declare a classe separadamente.")
		return
	if _check_op("{"):
		_fail("Blocos de inicialização { } soltos na classe não são suportados. Use o construtor.")
		return
	var access := _access_of(mods)
	var is_static := "static" in mods
	var is_final := "final" in mods

	# construtor: NomeDaClasse(
	if _check_t("id") and _peek().v == cls.name and _tok_at(_pos + 1).t == "op" and _tok_at(_pos + 1).v == "(":
		if cls.is_interface:
			_fail("Interfaces não têm construtor")
			return
		_advance()
		var params := _parse_params()
		_skip_throws()
		var body := _parse_block()
		var ctor := {
			"name": cls.name, "params": params, "body": body, "access": access,
			"line": start.line, "owner": cls.name, "ret": "void", "static": false,
			"abstract": false, "is_ctor": true, "explicit": null,
		}
		# this(...) ou super(...) como primeira instrução
		if not _failed and body.body.size() > 0:
			var first = body.body[0]
			if first.k == "expr" and first.e.k == "ctorcall":
				ctor.explicit = first.e
				body.body.remove_at(0)
		cls.ctors.append(ctor)
		return

	var type_tok := _peek()
	var type := _parse_type()
	if _failed:
		return
	if _check_op("("):
		if type == "void" or type in PRIMITIVES:
			_fail("Faltou o nome do método")
		else:
			_fail("O construtor '%s' precisa ter o mesmo nome da classe '%s'. Se for um método, faltou o tipo de retorno (ex.: void)." % [type, cls.name], type_tok)
		return
	var name_tok := _expect_ident("o nome do campo ou método")
	if _failed:
		return

	if _check_op("("):
		var params := _parse_params()
		_skip_throws()
		var m := {
			"name": name_tok.v, "ret": type, "params": params, "static": is_static,
			"abstract": false, "access": access, "body": null, "line": name_tok.line,
			"owner": cls.name, "is_ctor": false,
		}
		if cls.is_interface and not is_static and not _check_op("{"):
			m.abstract = true
		if "native" in mods:
			# implementado pelo jogo: o interpretador chama o método de mesmo nome no host
			if not _match_op(";"):
				_fail("Um método native não tem corpo. Termine a declaração com ';'", name_tok)
				return
			if is_static:
				_fail("Métodos native não podem ser static", name_tok)
				return
			m["host_call"] = true
			cls.methods.append(m)
			return
		if _match_op(";"):
			if not (cls.is_interface or "abstract" in mods):
				_fail("O método '%s' precisa de um corpo { ... } (ou ser declarado abstract)" % name_tok.v, name_tok)
				return
			if "abstract" in mods and not cls.is_abstract:
				_fail("A classe %s tem o método abstrato '%s', então ela também precisa ser abstract" % [cls.name, name_tok.v], name_tok)
				return
			m.abstract = true
		else:
			if "abstract" in mods:
				_fail("Um método abstract não pode ter corpo. Termine a declaração com ';'", name_tok)
				return
			m.abstract = false
			m.body = _parse_block()
		cls.methods.append(m)
		return

	if type == "void":
		_fail("Um campo não pode ser do tipo void", type_tok)
		return
	if cls.is_interface:
		is_static = true
		is_final = true
	# um ou mais campos: int a = 1, b;
	while not _failed:
		var ftype := type
		while _check_op("[") and _tok_at(_pos + 1).t == "op" and _tok_at(_pos + 1).v == "]":
			_advance()
			_advance()
			ftype += "[]"
		var init = null
		if _match_op("="):
			init = _parse_var_init(ftype)
		cls.fields.append({
			"name": name_tok.v, "type": ftype, "init": init, "value": null, "static": is_static,
			"final": is_final, "access": access, "line": name_tok.line, "owner": cls.name,
		})
		if not _match_op(","):
			break
		name_tok = _expect_ident("o nome do campo")
	_expect_op(";")


func _skip_throws() -> void:
	if _check_kw("throws"):
		_fail(UNSUPPORTED["throws"])


func _parse_params() -> Array:
	var params := []
	_expect_op("(")
	if _match_op(")"):
		return params
	while not _failed:
		_match_kw("final")
		var t := _parse_type()
		if _check_op("..."):
			_fail("Parâmetros variáveis (...) não são suportados. Use um array.")
			return params
		var n := _expect_ident("o nome do parâmetro")
		while _check_op("[") and _tok_at(_pos + 1).t == "op" and _tok_at(_pos + 1).v == "]":
			_advance()
			_advance()
			t += "[]"
		for p in params:
			if p.n == n.v:
				_fail("Parâmetro '%s' repetido" % n.v, n)
		params.append({"type": t, "n": n.v})
		if not _match_op(","):
			break
	_expect_op(")", "fechando a lista de parâmetros")
	return params


# ---------------------------------------------------------------- tipos

## Lê um tipo: int, String, Porta, int[], ArrayList<Porta>, java.util.List<X>...
## Os parâmetros genéricos (<...>) são lidos e descartados.
func _parse_type() -> String:
	var t := _peek()
	var tname := ""
	if t.t == "kw" and t.v in PRIMITIVES:
		_advance()
		tname = t.v
	elif t.t == "id":
		_advance()
		tname = t.v
		while _check_op(".") and _tok_at(_pos + 1).t == "id":
			_advance()
			tname = _advance().v # java.util.List -> List
		if _check_op("<"):
			var end := _scan_generics(_pos)
			if end < 0:
				_fail("Parâmetro genérico <...> inválido")
				return tname
			_pos = end
	else:
		_fail("Esperado um tipo (int, double, boolean, String, nome de classe...) mas encontrado %s" % _describe(t))
		return "?"
	match tname:
		"float": tname = "double"
		"byte", "short": tname = "int"
		"Integer": tname = "int"
		"Double", "Float": tname = "double"
		"Boolean": tname = "boolean"
		"Character": tname = "char"
		"Long": tname = "long"
	while _check_op("[") and _tok_at(_pos + 1).t == "op" and _tok_at(_pos + 1).v == "]":
		_advance()
		_advance()
		tname += "[]"
	return tname


## A partir de um '<', devolve a posição depois do '>' correspondente, ou -1.
func _scan_generics(p: int) -> int:
	var depth := 0
	while true:
		var tk := _tok_at(p)
		if tk.t == "op" and tk.v == "<":
			depth += 1
		elif tk.t == "op" and tk.v == ">":
			depth -= 1
			if depth == 0:
				return p + 1
		elif tk.t == "id" or (tk.t == "op" and tk.v in [",", ".", "?", "[", "]"]) or (tk.t == "kw" and (tk.v in PRIMITIVES or tk.v == "extends" or tk.v == "super")):
			pass
		else:
			return -1
		p += 1
	return -1


## Versão "só olhar" de _parse_type: devolve a posição depois do tipo, ou -1.
func _scan_type(p: int) -> int:
	var t := _tok_at(p)
	if t.t == "kw" and t.v in PRIMITIVES:
		p += 1
	elif t.t == "id":
		p += 1
		while _tok_at(p).t == "op" and _tok_at(p).v == "." and _tok_at(p + 1).t == "id":
			p += 2
		if _tok_at(p).t == "op" and _tok_at(p).v == "<":
			p = _scan_generics(p)
			if p < 0:
				return -1
	else:
		return -1
	while _tok_at(p).t == "op" and _tok_at(p).v == "[" and _tok_at(p + 1).t == "op" and _tok_at(p + 1).v == "]":
		p += 2
	return p


## Verdadeiro se o que vem a seguir é uma declaração de variável local (Tipo nome ...).
func _looks_like_decl() -> bool:
	var p := _pos
	if _tok_at(p).t == "kw" and _tok_at(p).v == "final":
		p += 1
	var e := _scan_type(p)
	if e < 0:
		return false
	if _tok_at(e).t == "kw" and _tok_at(p).t == "kw":
		return true # ex.: "int class = 1;" -> deixa _expect_ident explicar o erro
	return _tok_at(e).t == "id"


# ---------------------------------------------------------------- comandos

func _parse_block() -> Dictionary:
	var start := _peek()
	var block := {"k": "block", "body": [], "line": start.line}
	if not _expect_op("{"):
		return block
	while not _failed and not _check_op("}"):
		if _check_t("eof"):
			_fail("Faltou '}' para fechar o bloco aberto na linha %d" % start.line, start)
			return block
		block.body.append(_parse_statement())
	_expect_op("}")
	return block


func _parse_statement() -> Dictionary:
	var t := _peek()
	var line: int = t.line
	if _failed:
		return {"k": "empty", "line": line}
	if _check_op("{"):
		return _parse_block()
	if _match_op(";"):
		return {"k": "empty", "line": line}
	if _check_unsupported():
		return {"k": "empty", "line": line}
	if t.t == "kw":
		match t.v:
			"if":
				_advance()
				_expect_op("(", "depois do if")
				var cond = _parse_expr()
				_expect_op(")", "fechando a condição do if")
				var then_s := _parse_statement()
				var else_s = null
				if _match_kw("else"):
					else_s = _parse_statement()
				return {"k": "if", "cond": cond, "then": then_s, "else": else_s, "line": line}
			"while":
				_advance()
				_expect_op("(", "depois do while")
				var cond = _parse_expr()
				_expect_op(")", "fechando a condição do while")
				var body := _parse_statement()
				return {"k": "while", "cond": cond, "body": body, "line": line}
			"do":
				_advance()
				var body := _parse_statement()
				if not _match_kw("while"):
					_fail("Esperado 'while' depois do bloco do 'do'")
				_expect_op("(")
				var cond = _parse_expr()
				_expect_op(")")
				_expect_op(";")
				return {"k": "dowhile", "cond": cond, "body": body, "line": line}
			"for":
				return _parse_for()
			"return":
				_advance()
				var e = null
				if not _check_op(";"):
					e = _parse_expr()
				_expect_op(";")
				return {"k": "return", "e": e, "line": line}
			"break", "continue":
				_advance()
				if _check_t("id"):
					_fail("break/continue com rótulo não são suportados")
				_expect_op(";")
				return {"k": t.v, "line": line}
			"else":
				_fail("'else' sem um 'if' antes")
				return {"k": "empty", "line": line}
			"class", "interface":
				_fail("Classes dentro de métodos não são suportadas")
				return {"k": "empty", "line": line}
	if _looks_like_decl():
		var d := _parse_local_decl()
		_expect_op(";")
		return d
	var e = _parse_expr()
	if _failed:
		return {"k": "empty", "line": line}
	if not (e.k in ["assign", "call", "incdec", "new", "ctorcall"]):
		_fail("Isto não é um comando válido. Talvez você quis atribuir (=) ou chamar um método?", t)
	_expect_op(";")
	return {"k": "expr", "e": e, "line": line}


func _parse_local_decl() -> Dictionary:
	var line: int = _peek().line
	var is_final := _match_kw("final")
	var type := _parse_type()
	if type == "void":
		_fail("Uma variável não pode ser do tipo void")
	var decls := []
	while not _failed:
		var n := _expect_ident("o nome da variável")
		var vtype := type
		while _check_op("[") and _tok_at(_pos + 1).t == "op" and _tok_at(_pos + 1).v == "]":
			_advance()
			_advance()
			vtype += "[]"
		var init = null
		if _match_op("="):
			init = _parse_var_init(vtype)
		decls.append({"n": n.v, "type": vtype, "init": init, "line": n.line})
		if not _match_op(","):
			break
	return {"k": "var", "final": is_final, "decls": decls, "line": line}


func _parse_var_init(type: String):
	if _check_op("{"):
		if not type.ends_with("[]"):
			_fail("Chaves { } só podem inicializar arrays")
			return null
		return _parse_array_init(type)
	return _parse_expr()


func _parse_array_init(type: String) -> Dictionary:
	var line: int = _peek().line
	_expect_op("{")
	var elem := type.substr(0, type.length() - 2)
	var items := []
	while not _failed and not _check_op("}"):
		if _check_op("{"):
			if not elem.ends_with("[]"):
				_fail("Chaves { } a mais: o array não tem tantas dimensões")
				break
			items.append(_parse_array_init(elem))
		else:
			items.append(_parse_expr())
		if not _match_op(","):
			break
	_expect_op("}", "fechando a lista de valores do array")
	return {"k": "arrlit", "type": type, "items": items, "line": line}


func _parse_for() -> Dictionary:
	var line: int = _advance().line
	_expect_op("(", "depois do for")
	var init := []
	if _looks_like_decl():
		var p := _pos
		if _tok_at(p).t == "kw" and _tok_at(p).v == "final":
			p += 1
		var e := _scan_type(p)
		if _tok_at(e + 1).t == "op" and _tok_at(e + 1).v == ":":
			# for (Tipo x : colecao)
			_match_kw("final")
			var type := _parse_type()
			var n := _expect_ident("o nome da variável")
			_expect_op(":")
			var iter = _parse_expr()
			_expect_op(")")
			var body := _parse_statement()
			return {"k": "foreach", "type": type, "n": n.v, "iter": iter, "body": body, "line": line}
		init.append(_parse_local_decl())
	elif not _check_op(";"):
		while not _failed:
			var e = _parse_expr()
			init.append({"k": "expr", "e": e, "line": line})
			if not _match_op(","):
				break
	_expect_op(";", "no for(inicio; condição; passo)")
	var cond = null
	if not _check_op(";"):
		cond = _parse_expr()
	_expect_op(";", "no for(inicio; condição; passo)")
	var update := []
	if not _check_op(")"):
		while not _failed:
			update.append(_parse_expr())
			if not _match_op(","):
				break
	_expect_op(")", "fechando o for")
	var body := _parse_statement()
	return {"k": "for", "init": init, "cond": cond, "update": update, "body": body, "line": line}


# ---------------------------------------------------------------- expressões

func _parse_expr():
	return _parse_assign()


func _parse_assign():
	var left = _parse_ternary()
	var t := _peek()
	if not _failed and t.t == "op" and t.v in ASSIGN_OPS:
		_advance()
		if not (left.k in ["name", "field", "index"]):
			_fail("O lado esquerdo de '%s' precisa ser uma variável" % t.v, t)
			return left
		var right = _parse_assign()
		return {"k": "assign", "op": t.v, "target": left, "value": right, "line": t.line}
	if not _failed and t.t == "op" and t.v == "->":
		_fail("Expressões lambda (->) não são suportadas")
	return left


func _parse_ternary():
	var c = _parse_binary(0)
	if not _failed and _check_op("?"):
		var t := _advance()
		var a = _parse_ternary()
		_expect_op(":", "no operador ternário  condição ? a : b")
		var b = _parse_ternary()
		return {"k": "ternary", "cond": c, "a": a, "b": b, "line": t.line}
	return c


func _parse_binary(level: int):
	if level >= BIN_PREC.size():
		return _parse_unary()
	var left = _parse_binary(level + 1)
	while not _failed:
		var t := _peek()
		var opv := ""
		if t.t == "op" or (t.t == "kw" and t.v == "instanceof"):
			opv = t.v
		if opv == "" or not (opv in BIN_PREC[level]):
			break
		_advance()
		if opv == "instanceof":
			var ty := _parse_type()
			left = {"k": "instanceof", "e": left, "type": ty, "line": t.line}
			continue
		var right = _parse_binary(level + 1)
		left = {"k": "bin", "op": opv, "l": left, "r": right, "line": t.line}
	return left


func _parse_unary():
	var t := _peek()
	if t.t == "op":
		if t.v == "-" or t.v == "+" or t.v == "!" or t.v == "~":
			_advance()
			var e = _parse_unary()
			if t.v == "-" and e is Dictionary and e.k == "lit" and (typeof(e.v) == TYPE_INT or typeof(e.v) == TYPE_FLOAT):
				return {"k": "lit", "v": -e.v, "line": t.line}
			return {"k": "un", "op": t.v, "e": e, "line": t.line}
		if t.v == "++" or t.v == "--":
			_advance()
			var e = _parse_unary()
			if not _failed and not (e.k in ["name", "field", "index"]):
				_fail("'%s' só pode ser usado em variáveis" % t.v, t)
			return {"k": "incdec", "op": t.v, "prefix": true, "target": e, "line": t.line}
		if t.v == "(" and _is_cast():
			_advance()
			var ty := _parse_type()
			_expect_op(")")
			var e = _parse_unary()
			return {"k": "cast", "type": ty, "e": e, "line": t.line}
	return _parse_postfix()


func _is_cast() -> bool:
	var nt := _tok_at(_pos + 1)
	var e := _scan_type(_pos + 1)
	if e < 0 or not (_tok_at(e).t == "op" and _tok_at(e).v == ")"):
		return false
	if nt.t == "kw":
		return nt.v in PRIMITIVES
	var after := _tok_at(e + 1)
	if after.t in ["id", "str", "char", "int", "double"]:
		return true
	if after.t == "kw" and after.v in ["this", "new", "super", "true", "false", "null"]:
		return true
	return after.t == "op" and (after.v == "(" or after.v == "!")


func _parse_postfix():
	var e = _parse_primary()
	while not _failed:
		var t := _peek()
		if _match_op("."):
			var nm := _expect_ident("o nome do campo ou método depois do '.'")
			if _check_op("("):
				var args := _parse_args()
				e = {"k": "call", "obj": e, "n": nm.v, "args": args, "line": nm.line}
			else:
				e = {"k": "field", "obj": e, "n": nm.v, "line": nm.line}
		elif _match_op("["):
			var idx = _parse_expr()
			_expect_op("]")
			e = {"k": "index", "arr": e, "idx": idx, "line": t.line}
		elif _check_op("++") or _check_op("--"):
			_advance()
			if not (e.k in ["name", "field", "index"]):
				_fail("'%s' só pode ser usado em variáveis" % t.v, t)
			e = {"k": "incdec", "op": t.v, "prefix": false, "target": e, "line": t.line}
		elif _check_op("::"):
			_fail("Referências de método (::) não são suportadas")
		else:
			break
	return e


func _parse_args() -> Array:
	var args := []
	_expect_op("(")
	if _match_op(")"):
		return args
	while not _failed:
		args.append(_parse_expr())
		if not _match_op(","):
			break
	_expect_op(")", "fechando os argumentos da chamada")
	return args


func _parse_primary():
	var t := _peek()
	var line: int = t.line
	match t.t:
		"int", "double", "str":
			_advance()
			return {"k": "lit", "v": t.v, "line": line}
		"char":
			_advance()
			return {"k": "lit", "v": JChar.new(t.v), "line": line}
		"id":
			_advance()
			if _check_op("("):
				var args := _parse_args()
				return {"k": "call", "obj": null, "n": t.v, "args": args, "line": line}
			return {"k": "name", "n": t.v, "line": line}
		"kw":
			match t.v:
				"true":
					_advance()
					return {"k": "lit", "v": true, "line": line}
				"false":
					_advance()
					return {"k": "lit", "v": false, "line": line}
				"null":
					_advance()
					return {"k": "lit", "v": null, "line": line}
				"this":
					_advance()
					if _check_op("("):
						return {"k": "ctorcall", "sup": false, "args": _parse_args(), "line": line}
					return {"k": "this", "line": line}
				"super":
					_advance()
					if _check_op("("):
						return {"k": "ctorcall", "sup": true, "args": _parse_args(), "line": line}
					_expect_op(".", "depois de super")
					var nm := _expect_ident("o nome do método ou campo")
					if _check_op("("):
						return {"k": "call", "obj": {"k": "super", "line": line}, "n": nm.v, "args": _parse_args(), "line": line}
					return {"k": "field", "obj": {"k": "this", "line": line}, "n": nm.v, "line": line}
				"new":
					return _parse_new()
		"op":
			if t.v == "(":
				_advance()
				var e = _parse_expr()
				_expect_op(")", "fechando o parêntese")
				return e
	if not _check_unsupported():
		_fail("Expressão inválida: não esperava %s aqui" % _describe(t))
	_advance()
	return {"k": "lit", "v": null, "line": line}


func _parse_new() -> Dictionary:
	var line: int = _advance().line
	var t := _peek()
	var base := ""
	if t.t == "kw" and t.v in PRIMITIVES and t.v != "void":
		_advance()
		base = t.v
		if base == "float":
			base = "double"
		elif base == "byte" or base == "short":
			base = "int"
	elif t.t == "id":
		_advance()
		base = t.v
		while _check_op(".") and _tok_at(_pos + 1).t == "id":
			_advance()
			base = _advance().v
		if _check_op("<"):
			var end := _scan_generics(_pos)
			if end < 0:
				_fail("Parâmetro genérico <...> inválido")
			else:
				_pos = end
	else:
		_fail("Esperado o nome de uma classe depois de 'new'")
		return {"k": "lit", "v": null, "line": line}
	if _check_op("["):
		var sizes := []
		var dims := 0
		while not _failed and _match_op("["):
			dims += 1
			if _match_op("]"):
				continue
			if sizes.size() < dims - 1:
				_fail("Tamanho de array inválido")
			sizes.append(_parse_expr())
			_expect_op("]")
		var type := base
		for _i in dims:
			type += "[]"
		if sizes.is_empty():
			if not _check_op("{"):
				_fail("Informe o tamanho do array, ex.: new %s[10]" % base)
				return {"k": "lit", "v": null, "line": line}
			return _parse_array_init(type)
		return {"k": "newarr", "type": type, "sizes": sizes, "line": line}
	var args := _parse_args()
	if _check_op("{"):
		_fail("Classes anônimas não são suportadas")
	return {"k": "new", "cls": base, "args": args, "line": line}
