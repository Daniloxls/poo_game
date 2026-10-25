class_name ConsoleHighlighter
extends SyntaxHighlighter
## Colore objeto, método e pontuação da linha do console usando os spans do parser.

const C_OBJ := Color("#7cb3ff")
const C_METHOD := Color("#ffd54a")
const C_PUNCT := Color("#9aa3b2")
const C_TEXT := Color("#f2f2f2")


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var t := get_text_edit().get_line(line)
	var p := CommandParser.parse(t)
	var out := {}
	var cur := Color(0, 0, 0, 0)
	for i in t.length():
		var c := C_TEXT
		if i >= p.object_span.x and i < p.object_span.y:
			c = C_OBJ
		elif i >= p.method_span.x and i < p.method_span.y:
			c = C_METHOD
		elif t[i] in ".(),":
			c = C_PUNCT
		if c != cur:
			out[i] = {"color": c}
			cur = c
	return out
