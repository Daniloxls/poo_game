extends SceneTree
## Equipamento: uma aba por membro, prévia ▲▼ e a peça trocada volta para a mochila.

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
	var turin = root.get_node("Party/Turin")
	inv.mochila.adicionar(load("res://scenes/items/repo/armadura_ferro.tres"))
	inv.mochila.adicionar(load("res://scenes/items/repo/armadura_couro.tres"))
	var corpo := func(nome: String) -> EQUIP_ITEM:
		for e in inv.mochila.de_slot([EQUIP_ITEM.Slot.BODY]):
			if e.ITEM_NAME == nome:
				return e
		return null
	var ferro: EQUIP_ITEM = corpo.call("Armadura de Ferro")
	var couro: EQUIP_ITEM = corpo.call("Armadura de couro")
	inv.abrir()
	inv.ir("equipamento", turin)
	await process_frame
	var s: Control = inv.tela_atual()
	checar("cena de equipamento", s.has_method("equipar"), s)
	if not s.has_method("equipar"):
		_fim()
		return
	checar("uma aba por membro", s.abas.get_tab_count() == 1 and s.abas.get_tab_title(0) == "Turin")

	var def0: int = turin.get_def()
	checar("prévia da defesa", s.previsao(turin, "body_slot", ferro)["def"] == [def0, def0 + 5], s.previsao(turin, "body_slot", ferro))
	checar("prévia não muda o personagem", turin.get_equip("body_slot") == null and turin.get_def() == def0)

	s.equipar(turin, "body_slot", couro)
	checar("couro saiu da mochila", corpo.call("Armadura de couro") == null)
	s.equipar(turin, "body_slot", ferro)
	checar("ferro equipado", turin.get_equip("body_slot").ITEM_NAME == "Armadura de Ferro")
	checar("couro voltou para a mochila", corpo.call("Armadura de couro") != null)

	s.escolher_slot("body_slot")
	s.prever(corpo.call("Armadura de couro"))
	checar("defesa cai ▼2", s.valores["def"].get_parsed_text().contains("▼2"), s.valores["def"].get_parsed_text())
	s.prever(null)
	checar("linha de tirar", s.linha.get_parsed_text() == "turin.corpo = null;", s.linha.get_parsed_text())
	s.equipar(turin, "body_slot", null)
	checar("tirar devolve à mochila", turin.get_equip("body_slot") == null and corpo.call("Armadura de Ferro") != null)

	inv.mochila.itens.clear()
	inv.fechar()
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
