extends SceneTree
## Troca de classe: lista as quatro, troca, mostra a linha e apaga a novidade.

var passou := 0
var falhou := 0


func checar(titulo: String, ok: bool, detalhe = "") -> void:
	print(("  ok   " if ok else "  FALHOU ") + titulo + ("" if ok else "  -> " + str(detalhe)))
	if ok:
		passou += 1
	else:
		falhou += 1


func _initialize() -> void:
	await process_frame  # autoloads só ficam prontos após o primeiro frame
	await process_frame
	var inv: Node = root.get_node("Inventory")
	var prog: Node = root.get_node("Progresso")
	var turin = root.get_node("Party/Turin")
	prog.desbloquear("classes")
	inv.abrir()
	inv.ir("classe", turin)
	await process_frame
	var c: Control = inv.tela_atual()
	checar("cena de classe", c.has_method("escolher"), c)
	if not c.has_method("escolher"):
		_fim()
		return
	checar("quatro classes", c.botoes().size() == 4, c.botoes().size())
	checar("abrir apaga a novidade", not prog.novo("classes"))
	c.botao("BlackHat").pressed.emit()
	checar("trocou a classe", turin.get_class_name() == "BlackHat")
	checar("linha da troca", c.linha.get_parsed_text() == "turin = new BlackHat(turin);", c.linha.get_parsed_text())
	checar("frente atualizada", c.frente.find_children("*", "Label", true, false).any(func(l): return l.text == "BlackHat"))

	turin.mudar_classe(load("res://rpg_classes/commoner.tres"))
	prog.resetar()
	inv.fechar()
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
