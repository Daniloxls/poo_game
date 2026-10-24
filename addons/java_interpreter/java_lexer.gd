class_name JavaLexer
extends RefCounted
## Etapa 1: transforma o texto do código Java em uma lista de tokens.
##
## Cada token é um Dictionary: { "t": tipo, "v": valor, "line": linha, "col": coluna }
## Tipos: "id" (identificador), "kw" (palavra reservada), "int", "double",
## "str", "char", "op" (operador/pontuação) e "eof" (fim do arquivo).

const KEYWORDS := {
	"class": true, "interface": true, "extends": true, "implements": true,
	"public": true, "private": true, "protected": true, "static": true,
	"final": true, "abstract": true, "native": true, "void": true, "int": true, "long": true,
	"double": true, "float": true, "boolean": true, "char": true, "byte": true,
	"short": true, "if": true, "else": true, "while": true, "do": true,
	"for": true, "return": true, "break": true, "continue": true, "new": true,
	"this": true, "super": true, "null": true, "true": true, "false": true,
	"instanceof": true, "import": true, "package": true,
	# reservadas mas não suportadas (geram erro claro no parser)
	"switch": true, "case": true, "try": true, "catch": true, "throw": true,
	"throws": true, "finally": true, "enum": true,
}

# Do mais longo para o mais curto: o lexer sempre pega o maior operador possível.
# Não existem ">>" e "<<" de propósito, para não quebrar generics como List<List<X>>.
const OPERATORS := [
	"...", "++", "--", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=",
	"==", "!=", "<=", ">=", "&&", "||", "->", "::",
	"+", "-", "*", "/", "%", "=", "<", ">", "!", "?", ":", ";", ",", ".",
	"(", ")", "{", "}", "[", "]", "&", "|", "^", "@", "~",
]

## Preenchido quando a análise falha: { "message", "line", "col" }
var error: Dictionary = {}

var _src: String
var _i := 0
var _line := 1
var _col := 1


func tokenize(src: String) -> Array:
	_src = src
	_i = 0
	_line = 1
	_col = 1
	error = {}
	var tokens: Array = []
	var n := src.length()
	while _i < n:
		var c := src[_i]
		# espaços e quebras de linha
		if c == "\n":
			_advance()
			continue
		if c == " " or c == "\t" or c == "\r":
			_advance()
			continue
		# comentários
		if c == "/" and _peek(1) == "/":
			while _i < n and src[_i] != "\n":
				_advance()
			continue
		if c == "/" and _peek(1) == "*":
			var sl := _line
			var sc := _col
			_advance()
			_advance()
			while _i < n and not (src[_i] == "*" and _peek(1) == "/"):
				_advance()
			if _i >= n:
				return _fail("Comentário /* ... */ não foi fechado", sl, sc)
			_advance()
			_advance()
			continue

		var line := _line
		var col := _col
		# identificadores e palavras reservadas
		if _is_ident_start(c):
			var start := _i
			while _i < n and _is_ident_part(src[_i]):
				_advance()
			var word := src.substr(start, _i - start)
			tokens.append(_tok("kw" if KEYWORDS.has(word) else "id", word, line, col))
			continue
		# números
		if _is_digit(c) or (c == "." and _is_digit(_peek(1))):
			var tk = _read_number(line, col)
			if tk == null:
				return []
			tokens.append(tk)
			continue
		# textos
		if c == "\"":
			var s = _read_string(line, col)
			if s == null:
				return []
			tokens.append(_tok("str", s, line, col))
			continue
		# caracteres
		if c == "'":
			var ch = _read_char(line, col)
			if ch == null:
				return []
			tokens.append(_tok("char", ch, line, col))
			continue
		# operadores
		var found := ""
		for op in OPERATORS:
			if src.substr(_i, op.length()) == op:
				found = op
				break
		if found == "":
			return _fail("Caractere inesperado '%s'" % c, line, col)
		for _k in found.length():
			_advance()
		tokens.append(_tok("op", found, line, col))

	tokens.append(_tok("eof", "", _line, _col))
	return tokens


func _read_number(line: int, col: int):
	var start := _i
	var n := _src.length()
	var is_double := false
	while _i < n and (_is_digit(_src[_i]) or _src[_i] == "_"):
		_advance()
	if _i < n and _src[_i] == "." and _is_digit(_peek(1)):
		is_double = true
		_advance()
		while _i < n and _is_digit(_src[_i]):
			_advance()
	elif _i < n and _src[_i] == "." and not _is_ident_start(_peek(1)):
		# "1." também é um double em Java
		is_double = true
		_advance()
	if _i < n and (_src[_i] == "e" or _src[_i] == "E"):
		is_double = true
		_advance()
		if _i < n and (_src[_i] == "+" or _src[_i] == "-"):
			_advance()
		while _i < n and _is_digit(_src[_i]):
			_advance()
	var text := _src.substr(start, _i - start).replace("_", "")
	var t := "double" if is_double else "int"
	if _i < n:
		var s := _src[_i].to_lower()
		if s == "d" or s == "f":
			t = "double"
			_advance()
		elif s == "l":
			_advance()
	if _i < n and _is_ident_part(_src[_i]):
		_fail("Número inválido '%s%s'" % [text, _src[_i]], line, col)
		return null
	if t == "double":
		return _tok("double", text.to_float(), line, col)
	return _tok("int", text.to_int(), line, col)


func _read_escape() -> String:
	# chamado com _i apontando para o caractere depois da barra
	var e := _src[_i]
	_advance()
	match e:
		"n": return "\n"
		"t": return "\t"
		"r": return "\r"
		"0": return char(0)
		"\\": return "\\"
		"'": return "'"
		"\"": return "\""
	return "\\" + e


func _read_string(line: int, col: int):
	_advance() # aspas de abertura
	var out := ""
	var n := _src.length()
	while true:
		if _i >= n or _src[_i] == "\n":
			_fail("Texto (String) não foi fechado com \"", line, col)
			return null
		var c := _src[_i]
		if c == "\"":
			_advance()
			break
		if c == "\\":
			_advance()
			if _i >= n:
				continue
			out += _read_escape()
			continue
		out += c
		_advance()
	return out


func _read_char(line: int, col: int):
	_advance() # aspas simples de abertura
	var n := _src.length()
	if _i >= n:
		_fail("Caractere (char) não foi fechado com '", line, col)
		return null
	var value := ""
	if _src[_i] == "\\":
		_advance()
		if _i >= n:
			_fail("Caractere (char) inválido", line, col)
			return null
		value = _read_escape()
	elif _src[_i] == "'":
		_fail("Caractere (char) vazio ''", line, col)
		return null
	else:
		value = _src[_i]
		_advance()
	if _i >= n or _src[_i] != "'":
		_fail("Um char deve ter apenas um caractere entre aspas simples. Para textos use aspas duplas \"...\"", line, col)
		return null
	_advance()
	return value.unicode_at(0)


func _tok(t: String, v, line: int, col: int) -> Dictionary:
	return {"t": t, "v": v, "line": line, "col": col}


func _advance() -> void:
	if _src[_i] == "\n":
		_line += 1
		_col = 1
	else:
		_col += 1
	_i += 1


func _peek(off: int) -> String:
	var j := _i + off
	return _src[j] if j < _src.length() else ""


func _fail(msg: String, line: int, col: int) -> Array:
	error = {"message": msg, "line": line, "col": col}
	return []


static func _is_digit(c: String) -> bool:
	return c != "" and c >= "0" and c <= "9"


static func _is_ident_start(c: String) -> bool:
	if c == "":
		return false
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_" or c == "$" or c.unicode_at(0) > 127


static func _is_ident_part(c: String) -> bool:
	return _is_ident_start(c) or _is_digit(c)
