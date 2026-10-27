extends SceneTree
## Mochila: usar em alguém com a linha de Java, descartar, itens-chave e o último item.

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
	var pocao: ITEM = load("res://scenes/items/repo/potion.tres")
	var ferro: ITEM = load("res://scenes/items/repo/armadura_ferro.tres")
	inv.mochila.adicionar(pocao, 1)
	turin.hp = turin.get_max_hp() - 30
	inv.abrir()
	inv.ir("itens")
	await process_frame
	var s: Control = inv.tela_atual()
	checar("cena de itens", s.has_method("usar_em"), s)
	if not s.has_method("usar_em"):
		_fim()
		return
	checar("abas Itens e Itens-chave", s.abas.get_tab_count() == 2 and s.abas.get_tab_title(1) == "Itens-chave")
	checar("poção na grade", s.grade_comuns.get_node_or_null("Poção") != null)

	var item: ITEM = inv.mochila.itens[0]
	s.selecionar(item)
	checar("valor em bits", s.valor.text == "Vale 30 bits", s.valor.text)
	checar("poção tem Usar", s.usar_btn.visible)
	var esperado: int = mini(turin.get_max_hp() - 30 + 40, turin.get_max_hp())
	s.usar_em(item, turin)
	await create_timer(1.0).timeout
	checar("curou", turin.hp == esperado, [turin.hp, esperado])
	checar("grade vazia depois do último", s.grade_comuns.get_child_count() == 0, s.grade_comuns.get_child_count())
	checar("seleção limpa", s.selecionado() == null)
	checar("linha em OBJETO", s.linha.get_parsed_text() == "turin.hp = turin.hp + pocao.cura;", s.linha.get_parsed_text())

	prog.desbloquear("metodos")
	inv.mochila.adicionar(pocao, 1)
	s.usar_em(inv.mochila.itens[0], turin)
	await create_timer(1.0).timeout
	checar("linha em METODOS", s.linha.get_parsed_text() == "pocao.usar(turin);", s.linha.get_parsed_text())

	var k := ITEM.new()
	k.ITEM_NAME = "Chave do Código"
	k.CHAVE = true
	inv.mochila.adicionar(k)
	s.abas.current_tab = 1
	await process_frame
	checar("item-chave na aba dele", s.grade_chave.get_child_count() == 1 and s.grade_comuns.get_child_count() == 0)
	s.selecionar(inv.mochila.itens[0])
	checar("item-chave não descarta", s.descartar_btn.disabled and s.valor.text.begins_with("Item-chave"), s.valor.text)

	s.abas.current_tab = 0
	inv.mochila.adicionar(ferro)
	var arm: ITEM = inv.mochila.comuns()[0]
	s.selecionar(arm)
	checar("armadura sem Usar", not s.usar_btn.visible)
	s.descartar(arm)
	checar("descartou", inv.mochila.comuns().is_empty())
	checar("linha do descarte", s.linha.get_parsed_text() == "mochila.remove(armaduraDeFerro);", s.linha.get_parsed_text())

	inv.mochila.itens.clear()
	turin.hp = turin.get_max_hp()
	prog.resetar()
	inv.fechar()
	_fim()


func _fim() -> void:
	print("\n%d testes passaram, %d falharam" % [passou, falhou])
	quit(1 if falhou else 0)
