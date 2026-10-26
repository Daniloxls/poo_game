class_name DialogoBBCode


## Intervalos [inicio, fim) de letras visiveis dentro de [tag]...[/tag]; toda tag BBCode conta zero letras.
static func intervalos(texto: String, tag: String) -> Array[Vector2i]:
	var saida: Array[Vector2i] = []
	var abertas: Array[int] = []
	var letras := 0
	var i := 0
	while i < texto.length():
		var fecha := texto.find("]", i) if texto[i] == "[" else -1
		if fecha == -1:
			letras += 1
			i += 1
			continue
		var nome := texto.substr(i + 1, fecha - i - 1).split(" ")[0].split("=")[0]
		if nome == tag:
			abertas.append(letras)
		elif nome == "/" + tag and not abertas.is_empty():
			saida.append(Vector2i(abertas.pop_back(), letras))
		i = fecha + 1
	return saida


static func expandir_code(texto: String) -> String:
	return texto.replace("[code]", "[bgcolor=#1b1b1b][color=#ffd23f][code]").replace("[/code]", "[/code][/color][/bgcolor]")
