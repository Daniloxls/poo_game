extends SceneTree

const PASTA := "res://scenes/chapter_one/festival_city/dialogos/"
const CUES := {
	"excalibur": ["conversa"],
	"tatame": ["desafio", "vitoria", "derrota", "descansando", "montanha"],
	"teste_forca": ["convite", "ganhou", "perdeu", "dica", "ja_ganhou"],
	"tritomos": ["boas_vindas", "acertou", "errou"],
	"espada": ["cena_1", "cena_2", "cena_3", "cena_4", "cena_5", "cena_6", "cena_7"],
	"cidade": ["cmdzinho", "kath", "tenda", "npc1", "npc2", "npc3", "trocador"],
}
const PROIBIDOS := [" ?", "advinh", "trás lembr", "Enquanto a você", "premios"]

var passou := 0
var falhou := 0
var dm: Node
var historia: Node


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func _initialize() -> void:
	_rodar()


## Um NPC falso com todos os membros que os arquivos da cidade leem e escrevem.
func _stub(tickets: int = 0) -> Node:
	var s := GDScript.new()
	s.source_code = """extends Node
var tickets := 0
var vai_seguir := false
var espada_tirada := false
var quer_lutar := false
var quer_tentar := false
var erros := 1
var palavra := "banana"
func tickets_atuais() -> int:
	return tickets
"""
	s.reload()
	var n := Node.new()
	n.set_script(s)
	n.tickets = tickets
	root.add_child(n)
	return n


## Percorre uma cue até o fim; em cada escolha pega o próximo índice de `escolhas`.
func _andar(recurso: DialogueResource, cue: String, stub: Node, escolhas: Array = []) -> Array:
	var linhas := []
	var linha: DialogueLine = await dm.get_next_dialogue_line(recurso, cue, [stub])
	while linha != null and linhas.size() < 100:
		linhas.append(linha)
		var prox := linha.next_id
		if not linha.responses.is_empty():
			prox = linha.responses[escolhas.pop_front() if not escolhas.is_empty() else 0].next_id
		linha = await dm.get_next_dialogue_line(recurso, prox, [stub])
	return linhas


func _rodar() -> void:
	await process_frame
	dm = root.get_node("DialogueManager")
	historia = root.get_node("Historia")
	var elenco: Node = root.get_node("Elenco")

	for nome in CUES:
		var caminho: String = PASTA + nome + ".dialogue"
		var texto := FileAccess.get_file_as_string(caminho)
		checar("%s existe" % nome, not texto.is_empty())
		var r: DMCompilerResult = DMCompiler.compile_string(texto, caminho)
		checar("%s compila sem erros" % nome, r.errors.is_empty(), r.errors.map(func(e): return "linha %d: %s" % [e.line_number + 1, DMConstants.get_error_message(e.error)]))
		for cue in CUES[nome]:
			checar("%s tem ~ %s" % [nome, cue], r.cues.has(cue))
		for falante in r.character_names:
			checar("%s: '%s' tem personagem" % [nome, falante], elenco.buscar(falante).cor != elenco.COR_PADRAO)
		var n := 0
		for l in texto.split("\n"):
			n += 1
			for p in PROIBIDOS:
				if l.contains(p):
					checar("%s:%d sem '%s'" % [nome, n, p], false, l)

	if falhou:  # sem arquivos válidos não dá para percorrer as cues
		_fim()
		return

	var excalibur: DialogueResource = dm.create_resource_from_text(FileAccess.get_file_as_string(PASTA + "excalibur.dialogue"))
	var stub := _stub(0)
	await _andar(excalibur, "conversa", stub, [0])
	checar("excalibur com 0 tickets e 'sim' não segue", stub.vai_seguir == false)
	stub.free()
	stub = _stub(30)
	await _andar(excalibur, "conversa", stub, [0])
	checar("excalibur com 30 tickets e 'sim' segue", stub.vai_seguir == true)
	stub.free()
	stub = _stub(30)
	await _andar(excalibur, "conversa", stub, [1])
	checar("excalibur com 30 tickets e 'não' não segue", stub.vai_seguir == false)
	stub.free()

	var tatame: DialogueResource = dm.create_resource_from_text(FileAccess.get_file_as_string(PASTA + "tatame.dialogue"))
	historia.resetar()
	stub = _stub()
	await _andar(tatame, "vitoria", stub, [1])
	checar("tatame/vitoria segunda escolha -> mentor", historia.montanha == "mentor", historia.montanha)
	historia.resetar()
	await _andar(tatame, "vitoria", stub, [0])
	checar("tatame/vitoria primeira escolha -> respeito", historia.montanha == "respeito", historia.montanha)
	await _andar(tatame, "desafio", stub, [0])
	checar("tatame/desafio 'sim' -> quer_lutar", stub.quer_lutar == true)
	stub.free()

	var tritomos: DialogueResource = dm.create_resource_from_text(FileAccess.get_file_as_string(PASTA + "tritomos.dialogue"))
	historia.resetar()
	stub = _stub()
	var linhas := await _andar(tritomos, "errou", stub, [0])
	checar("tritomos/errou primeira escolha -> verdade", historia.tritomos == "verdade", historia.tritomos)
	checar("tritomos/errou mostra a palavra", linhas.any(func(l): return l.text.contains("banana")))
	historia.resetar()
	await _andar(tritomos, "errou", stub, [1])
	checar("tritomos/errou segunda escolha -> acreditou", historia.tritomos == "acreditou", historia.tritomos)
	historia.resetar()
	stub.free()

	var forca: DialogueResource = dm.create_resource_from_text(FileAccess.get_file_as_string(PASTA + "teste_forca.dialogue"))
	var dicas := {}
	for e in [1, 2, 3]:
		stub = _stub()
		stub.erros = e
		var ls := await _andar(forca, "dica", stub)
		dicas[ls.map(func(l): return l.text)] = true
		checar("dica %d fala o Cmdzinho" % e, not ls.is_empty() and ls.all(func(l): return l.character == "Cmdzinho"))
		stub.free()
	checar("três dicas diferentes", dicas.size() == 3)
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
