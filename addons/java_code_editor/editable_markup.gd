class_name JavaEditableMarkup
extends RefCounted
## Lê a marcação que o level designer usa para dizer o que o jogador pode editar.
##
##   {| ... |}   trecho editável (dentro de uma linha):
##               while ({|!temParedeNaFrente()|}) {
##               Só o que está entre {| e |} pode ser mudado, e ali não cabe
##               quebra de linha.
##
##   {|          quando o marcador está SOZINHO na linha, vira um bloco: as
##   ...         linhas entre {| e |} são editáveis e o jogador pode criar
##   |}          ou apagar linhas ali dentro. As linhas dos marcadores somem.
##
##   Um trecho que abre numa linha e fecha em outra também vale como bloco.
##   Sem nenhum marcador, o código todo fica livre para editar.
##
## parse() devolve {"text": código sem marcadores, "regions": [...], "error": ""}.
## Cada região é {"start": int, "end": int, "multiline": bool}, com posições
## (índices de caractere) no texto já limpo. O fim é exclusivo.

const ABRE := "{|"
const FECHA := "|}"


static func parse(template: String) -> Dictionary:
	var out := ""
	var regions: Array = []
	var aberta := -1          # posição em `out` onde a região aberta começa
	var aberta_bloco := false
	var indent_bloco := ""
	var linha_aberta := 0
	var linhas := template.split("\n")
	for li in linhas.size():
		var linha: String = linhas[li]
		var limpa := linha.strip_edges()
		if limpa == ABRE:
			if aberta >= 0:
				return _erro("Linha %d: '{|' dentro de outra região editável (aberta na linha %d)" % [li + 1, linha_aberta])
			aberta = out.length()
			aberta_bloco = true
			indent_bloco = linha.substr(0, linha.find(ABRE))
			linha_aberta = li + 1
			continue
		if limpa == FECHA:
			if aberta < 0:
				return _erro("Linha %d: '|}' sem um '{|' antes" % (li + 1))
			var fim: int
			if out.length() > aberta:
				fim = out.length() - 1   # antes da quebra de linha da última linha
			else:
				# bloco vazio: cria uma linha (só com o recuo) para o jogador escrever
				out += indent_bloco + "\n"
				fim = out.length() - 1
			regions.append({"start": aberta, "end": fim, "multiline": true})
			aberta = -1
			continue
		var i := 0
		while i < linha.length():
			var pa := linha.find(ABRE, i)
			var pf := linha.find(FECHA, i)
			var p := pa
			if p < 0 or (pf >= 0 and pf < p):
				p = pf
			if p < 0:
				out += linha.substr(i)
				break
			out += linha.substr(i, p - i)
			if p == pa:
				if aberta >= 0:
					return _erro("Linha %d: '{|' dentro de outra região editável (aberta na linha %d)" % [li + 1, linha_aberta])
				aberta = out.length()
				aberta_bloco = false
				linha_aberta = li + 1
			else:
				if aberta < 0:
					return _erro("Linha %d: '|}' sem um '{|' antes" % (li + 1))
				var trecho := out.substr(aberta)
				regions.append({"start": aberta, "end": out.length(),
						"multiline": aberta_bloco or trecho.contains("\n")})
				aberta = -1
			i = p + 2
		out += "\n"
	if aberta >= 0:
		return _erro("Linha %d: a região editável aberta com '{|' não foi fechada com '|}'" % linha_aberta)
	out = out.left(-1)   # tira o "\n" extra da última linha
	return {"text": out, "regions": regions, "error": ""}


static func _erro(msg: String) -> Dictionary:
	return {"text": "", "regions": [], "error": msg}
