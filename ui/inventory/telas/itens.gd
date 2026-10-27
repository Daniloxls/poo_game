extends HBoxContainer
## Mochila: grade de itens (comuns e itens-chave) e, ao lado, o item escolhido.
## Usar ou descartar escreve a linha de Java da ação.

var abas: TabContainer
var grade_comuns: GridContainer
var grade_chave: GridContainer
var nome: Label
var descricao: Label
var valor: Label
var usar_btn: Button
var descartar_btn: Button
var linha: RichTextLabel
var _alvos: HBoxContainer
var _sel: ITEM
var _tween: Tween


func _ready() -> void:
	add_theme_constant_override("separation", 18)
	abas = TabContainer.new()
	abas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade_comuns = _grade("Itens")
	grade_chave = _grade("Itens-chave")
	abas.tab_changed.connect(func(_t): _selecionar_primeiro())
	add_child(abas)

	var det := UiInv.painel()
	det.custom_minimum_size.x = 420
	var v := UiInv.caixa(true, 10)
	nome = UiInv.rotulo("", 24)
	descricao = UiInv.rotulo("", 16)
	descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	valor = UiInv.rotulo("", 14)
	var botoes := UiInv.caixa(false, 8)
	usar_btn = _botao("Usar", _on_usar)
	descartar_btn = _botao("Descartar", func(): if _sel: descartar(_sel))
	botoes.add_child(usar_btn)
	botoes.add_child(descartar_btn)
	_alvos = UiInv.caixa(false, 8)
	_alvos.hide()
	var cod := UiInv.codigo()
	linha = cod.get_node("Codigo")
	for n in [nome, descricao, valor, botoes, _alvos, cod]:
		v.add_child(n)
	det.add_child(v)
	add_child(det)
	Inventory.mudou.connect(_atualizar)


func abrir_tela(_p) -> void:
	_alvos.hide()
	linha.text = CodigoJava.colorir("// escolha um item")
	_atualizar()
	_selecionar_primeiro()


func selecionado() -> ITEM:
	return _sel


func selecionar(item: ITEM) -> void:
	_sel = item
	_alvos.hide()
	_mostrar()


func usar_em(item: ITEM, alvo) -> void:
	Inventory.clique()
	item.usar(alvo)
	Inventory.mochila.gastar(item)
	_digitar("\n".join(CodigoJava.linha_usar(item, alvo, Progresso.estagio()).map(CodigoJava.colorir)))
	var bar: ProgressBar = _alvos.get_node_or_null(str(alvo.get_instance_id()) + "/Barra")
	if bar:
		bar.create_tween().tween_property(bar, "value", alvo.get_hp(), 0.5)


func descartar(item: ITEM) -> void:
	if Inventory.mochila.descartar(item):
		Inventory.clique()
		_digitar(CodigoJava.colorir(CodigoJava.linha_descartar(item)))


func _grade(titulo: String) -> GridContainer:
	var rolagem := ScrollContainer.new()
	rolagem.name = titulo
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	rolagem.add_child(g)
	abas.add_child(rolagem)
	return g


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.theme_type_variation = &"InvCelula"
	b.pressed.connect(acao)
	return b


func _atualizar() -> void:
	if grade_comuns == null:
		return
	for par in [[grade_comuns, Inventory.mochila.comuns()], [grade_chave, Inventory.mochila.chave()]]:
		UiInv.limpar(par[0])
		for it in par[1]:
			par[0].add_child(_celula(it))
	if _sel and not Inventory.mochila.itens.has(_sel):  # o último foi usado ou descartado
		_sel = null
		_selecionar_primeiro()
	_mostrar()


func _celula(it: ITEM) -> Button:
	var b := Button.new()
	b.name = it.ITEM_NAME
	b.theme_type_variation = &"InvCelula"
	b.text = "%s\nx%d" % [it.ITEM_NAME, it.QUANTITY]
	b.icon = it.get_icon()
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_constant_override("icon_max_width", 40)
	b.add_theme_font_size_override("font_size", 13)
	b.custom_minimum_size = Vector2(112, 100)
	b.focus_entered.connect(selecionar.bind(it))
	b.mouse_entered.connect(selecionar.bind(it))
	b.pressed.connect(func(): selecionar(it); (usar_btn if usar_btn.visible else descartar_btn).grab_focus())
	return b


func _selecionar_primeiro() -> void:
	var g := grade_comuns if abas.current_tab == 0 else grade_chave
	if g.get_child_count() > 0:
		g.get_child(0).grab_focus()
	else:
		_sel = null
		_mostrar()
		abas.get_tab_bar().grab_focus()


func _mostrar() -> void:
	var tem := _sel != null
	nome.text = _sel.ITEM_NAME if tem else "—"
	descricao.text = _sel.get_item_text() if tem else "Escolha um item."
	if not tem:
		valor.text = ""
	elif _sel.CHAVE:
		valor.text = "Item-chave: não pode ser descartado."
	else:
		valor.text = "Vale %d %s" % [_sel.PRICE, Inventory.MOEDA]
	usar_btn.visible = tem and _sel.pode_usar()
	descartar_btn.visible = tem
	descartar_btn.disabled = tem and _sel.CHAVE
	for b in _alvos.get_children():
		b.get_child(0).disabled = not (tem and _sel.pode_usar())


func _on_usar() -> void:
	if _sel == null:
		return
	UiInv.limpar(_alvos)
	for p in Party.get_children():
		var caixa := UiInv.caixa(true, 2)
		caixa.name = str(p.get_instance_id())
		var b := Button.new()
		b.text = "%s  %d/%d" % [p.get_nome(), p.get_hp(), p.get_max_hp()]
		b.theme_type_variation = &"InvCelula"
		b.pressed.connect(func(): if _sel: usar_em(_sel, p))
		var bar := UiInv.barra(UiInv.VERDE)
		bar.name = "Barra"
		bar.max_value = p.get_max_hp()
		bar.value = p.get_hp()
		caixa.add_child(b)
		caixa.add_child(bar)
		_alvos.add_child(caixa)
	_alvos.show()
	_alvos.get_child(0).get_child(0).grab_focus()


func _digitar(bb: String) -> void:
	linha.text = bb
	linha.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(linha, "visible_ratio", 1.0, 0.02 * linha.get_total_character_count())
