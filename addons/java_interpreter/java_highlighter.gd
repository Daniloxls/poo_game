class_name JavaHighlighter
extends RefCounted
## Cria um CodeHighlighter com as cores do Java para usar em um CodeEdit:
##     $CodeEdit.syntax_highlighter = JavaHighlighter.create()


static func create() -> CodeHighlighter:
	var h := CodeHighlighter.new()
	h.number_color = Color("b5cea8")
	h.symbol_color = Color("d4d4d4")
	h.function_color = Color("dcdcaa")
	h.member_variable_color = Color("9cdcfe")
	var kw := Color("569cd6")
	for w in ["class", "interface", "extends", "implements", "public", "private", "protected",
			"static", "final", "abstract", "native", "if", "else", "while", "do", "for", "return",
			"break", "continue", "new", "this", "super", "null", "true", "false", "instanceof",
			"import", "package"]:
		h.add_keyword_color(w, kw)
	var types := Color("4ec9b0")
	for w in ["void", "int", "long", "double", "float", "boolean", "char", "String", "Object"]:
		h.add_keyword_color(w, types)
	h.add_color_region("\"", "\"", Color("ce9178"), true)
	h.add_color_region("'", "'", Color("ce9178"), true)
	h.add_color_region("//", "", Color("6a9955"), true)
	h.add_color_region("/*", "*/", Color("6a9955"), false)
	return h
