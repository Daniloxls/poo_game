class_name JavaRegionHighlighter
extends SyntaxHighlighter
## Cores de Java para o LockedCodeEdit. O que está travado aparece apagado
## (acinzentado) e o que o jogador pode editar aparece com as cores normais.

const KEYWORDS := ["class", "interface", "extends", "implements", "public", "private",
		"protected", "static", "final", "abstract", "native", "if", "else", "while", "do", "for",
		"return", "break", "continue", "new", "this", "super", "null", "true", "false",
		"instanceof", "import", "package", "switch", "case", "default", "try", "catch",
		"throw", "throws", "enum"]
const TYPES := ["void", "int", "long", "double", "float", "boolean", "char", "byte",
		"short", "String", "Object", "var"]

var cores := {
	"texto": Color("d4d4d4"),
	"keyword": Color("569cd6"),
	"tipo": Color("4ec9b0"),
	"numero": Color("b5cea8"),
	"string": Color("ce9178"),
	"comentario": Color("6a9955"),
	"funcao": Color("dcdcaa"),
	"membro": Color("9cdcfe"),
	"simbolo": Color("d4d4d4"),
}
## Cor para onde o texto travado é puxado, e o quanto (0 = igual, 1 = só essa cor).
var cor_travado := Color("6b7280")
var forca_travado := 0.55

var _tokens: Array = []      # por linha: Array de [coluna, tipo]
var _versao := -1
var _linhas := -1
var _sujo := true


func _clear_highlighting_cache() -> void:
	_sujo = true


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var te := get_text_edit()
	if te == null:
		return {}
	if _sujo or _versao != te.get_version() or _linhas != te.get_line_count():
		_tokenizar(te.text)
		_versao = te.get_version()
		_linhas = te.get_line_count()
		_sujo = false
	if line >= _tokens.size():
		return {}
	var toks: Array = _tokens[line]
	var cortes := {}   # coluna -> true onde começa um pedaço novo
	for t in toks:
		cortes[t[0]] = true
	var travas: Array = []
	if te.has_method("locked_ranges_on_line"):
		travas = te.locked_ranges_on_line(line)   # [[col_ini, col_fim, travado], ...]
		for r in travas:
			cortes[r[0]] = true
	var cols := cortes.keys()
	cols.sort()
	var res := {}
	var ti := 0
	var ri := 0
	for c in cols:
		while ti + 1 < toks.size() and toks[ti + 1][0] <= c:
			ti += 1
		var tipo: String = toks[ti][1] if not toks.is_empty() and toks[ti][0] <= c else "texto"
		var cor: Color = cores[tipo]
		while ri + 1 < travas.size() and travas[ri + 1][0] <= c:
			ri += 1
		if not travas.is_empty() and travas[ri][0] <= c and travas[ri][2]:
			cor = cor.lerp(cor_travado, forca_travado)
		res[c] = {"color": cor}
	return res


func _tokenizar(src: String) -> void:
	_tokens = [[]]
	var linha := 0
	var col := 0
	var i := 0
	var n := src.length()
	while i < n:
		var c := src[i]
		if c == "\n":
			_tokens.append([])
			linha += 1
			col = 0
			i += 1
			continue
		var ini := i
		var tipo := "simbolo"
		if c == " " or c == "\t":
			while i < n and (src[i] == " " or src[i] == "\t"):
				i += 1
			tipo = "texto"
		elif c == "/" and i + 1 < n and src[i + 1] == "/":
			while i < n and src[i] != "\n":
				i += 1
			tipo = "comentario"
		elif c == "/" and i + 1 < n and src[i + 1] == "*":
			# comentário de bloco: pode atravessar linhas
			_tokens[linha].append([col, "comentario"])
			i += 2
			col += 2
			while i < n and not (src[i] == "*" and i + 1 < n and src[i + 1] == "/"):
				if src[i] == "\n":
					_tokens.append([[0, "comentario"]])
					linha += 1
					col = 0
				else:
					col += 1
				i += 1
			i = mini(i + 2, n)
			col += 2
			continue
		elif c == "\"" or c == "'":
			i += 1
			while i < n and src[i] != c and src[i] != "\n":
				if src[i] == "\\":
					i += 1
				i += 1
			if i < n and src[i] == c:
				i += 1
			tipo = "string"
		elif _eh_digito(c):
			while i < n and (_eh_letra(src[i]) or _eh_digito(src[i]) or src[i] == "."):
				i += 1
			tipo = "numero"
		elif _eh_letra(c):
			while i < n and (_eh_letra(src[i]) or _eh_digito(src[i])):
				i += 1
			var palavra := src.substr(ini, i - ini)
			if palavra in KEYWORDS:
				tipo = "keyword"
			elif palavra in TYPES:
				tipo = "tipo"
			else:
				var j := i
				while j < n and src[j] == " ":
					j += 1
				if j < n and src[j] == "(":
					tipo = "funcao"
				elif palavra[0] == palavra[0].to_upper() and palavra[0] != "_" and palavra[0] != "$":
					tipo = "tipo"
				elif ini > 0 and src[ini - 1] == ".":
					tipo = "membro"
				else:
					tipo = "texto"
		else:
			i += 1
		_tokens[linha].append([col, tipo])
		col += i - ini


static func _eh_letra(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_" or c == "$" \
			or c.unicode_at(0) > 127   # letras acentuadas (ç, ã...)


static func _eh_digito(c: String) -> bool:
	return c >= "0" and c <= "9"
