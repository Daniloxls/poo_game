extends SceneTree
## Mochila: juntar, gastar, itens-chave e o usar(alvo) de cada item.

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
	var m := Mochila.new()
	var pocao: ITEM = load("res://scenes/items/repo/potion.tres")
	var mudancas := [0]
	m.mudou.connect(func(): mudancas[0] += 1)

	m.adicionar(pocao, 2)
	m.adicionar(pocao)
	checar("junta pela mesma poção", m.itens.size() == 1 and m.itens[0].QUANTITY == 3, m.itens)
	checar("guarda uma cópia, não o .tres", m.itens[0] != pocao)
	checar("poção pode ser usada", pocao.pode_usar())
	checar("armadura não pode ser usada", not load("res://scenes/items/repo/armadura_ferro.tres").pode_usar())

	var alvo = root.get_node("Party/Turin")
	alvo.hp = alvo.get_max_hp() - 10
	checar("usar cura o que falta", m.itens[0].usar(alvo) == 10)
	checar("hp no máximo", alvo.hp == alvo.get_max_hp(), alvo.hp)
	checar("usar com hp cheio cura 0", m.itens[0].usar(alvo) == 0 and alvo.hp == alvo.get_max_hp())

	var antes: int = mudancas[0]
	m.gastar(m.itens[0])
	checar("gastar avisa mudou", mudancas[0] == antes + 1)
	m.gastar(m.itens[0])
	m.gastar(m.itens[0])
	checar("gastar o último tira da mochila", m.itens.is_empty(), m.itens)

	var k := ITEM.new()
	k.ITEM_NAME = "Chave"
	k.CHAVE = true
	m.adicionar(k)
	checar("item-chave não é descartado", not m.descartar(m.itens[0]) and m.itens.size() == 1)
	checar("separa itens-chave", m.chave().size() == 1 and m.comuns().is_empty())

	var ferro: ITEM = load("res://scenes/items/repo/armadura_ferro.tres")
	m.adicionar(ferro)
	checar("descartar item comum", m.descartar(m.itens[1]) and m.comuns().is_empty())
	m.adicionar(ferro)
	checar("equipamento por slot", m.de_slot([EQUIP_ITEM.Slot.BODY]).size() == 1 and m.de_slot([EQUIP_ITEM.Slot.HEAD]).is_empty())
	var vestida: ITEM = m.de_slot([EQUIP_ITEM.Slot.BODY])[0]
	m.gastar(vestida)      # equipou a única
	m.adicionar(vestida)   # tirou: volta para a mochila
	m.adicionar(ferro)     # achou outra
	var pilhas := m.de_slot([EQUIP_ITEM.Slot.BODY])
	checar("equipar e tirar não divide a pilha", pilhas.size() == 1 and pilhas[0].QUANTITY == 2, pilhas.map(func(i): return [i.ITEM_NAME, i.QUANTITY]))
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
