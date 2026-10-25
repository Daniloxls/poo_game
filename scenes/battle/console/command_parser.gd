class_name CommandParser
extends RefCounted

# Parser sintático de "objeto.metodo(arg, arg)". Um único scanner da esquerda para a direita.

static func _is_ident(c: String) -> bool:
	return c == "_" or (c >= "0" and c <= "9") or c.to_upper() != c.to_lower()

static func _skip(t: String, i: int) -> int:
	while i < t.length() and t[i] in " \t":
		i += 1
	return i

# Fim do identificador em i; se não houver, consome 1 caractere (token ofensor).
static func _tok_end(t: String, i: int) -> int:
	var e := i
	while e < t.length() and _is_ident(t[e]):
		e += 1
	return e if e > i else i + 1

static func parse(text: String) -> ParsedCommand:
	var p := ParsedCommand.new()
	var n := text.length()
	var i := _skip(text, 0)
	if i >= n:
		return p
	var e := _tok_end(text, i)
	p.object_name = text.substr(i, e - i)
	p.object_span = Vector2i(i, e)
	i = _skip(text, e)
	if i >= n:
		return p
	if text[i] != ".":
		e = _tok_end(text, i)
		p.error = ConsoleError.make("Esperava '.' depois de %s" % p.object_name, Vector2i(i, e))
		return p
	p.stage = ParsedCommand.Stage.METHOD
	i = _skip(text, i + 1)
	if i >= n:
		return p
	if not _is_ident(text[i]):
		p.error = ConsoleError.make("Esperava o nome de um método depois de '.'", Vector2i(i, i + 1))
		return p
	e = _tok_end(text, i)
	p.method_name = text.substr(i, e - i)
	p.method_span = Vector2i(i, e)
	i = _skip(text, e)
	if i >= n:
		return p
	if text[i] != "(":
		e = _tok_end(text, i)
		p.error = ConsoleError.make("Esperava '(' depois de %s" % p.method_name, Vector2i(i, e))
		return p
	p.stage = ParsedCommand.Stage.ARGS
	i += 1
	while true:
		# um argumento: texto até ',' ou ')', sem espaços nas pontas
		var start := _skip(text, i)
		var stop := start
		while stop < n and text[stop] != "," and text[stop] != ")":
			stop += 1
		var end := stop
		while end > start and text[end - 1] in " \t":
			end -= 1
		if end == start:
			if stop >= n:
				return p   # "x(a, " ainda digitando
			if text[stop] == "," or p.args.size() > 0:
				p.error = ConsoleError.make("Argumento vazio", Vector2i(stop, stop + 1))
				return p
		else:
			p.args.append(text.substr(start, end - start))
			p.arg_spans.append(Vector2i(start, end))
		if stop >= n:
			return p
		i = stop + 1
		if text[stop] == ")":
			break
	p.stage = ParsedCommand.Stage.DONE
	i = _skip(text, i)
	if i < n:
		var last := n
		while text[last - 1] in " \t":
			last -= 1
		p.error = ConsoleError.make("Texto sobrando depois de ')'", Vector2i(i, last))
	return p
