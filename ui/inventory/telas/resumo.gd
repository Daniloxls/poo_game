extends HBoxContainer
## Resumo (o que o E abre): grupo à esquerda; à direita, a mochila e dinheiro, lugar e tempo.
## A navegação entre seções fica na barra de cima.

const ITENS_NA_PREVIA := 6

var _linhas: VBoxContainer
var _trilha: TrilhaConceitos
var _previa: Button
var _previa_itens: GridContainer
var _dinheiro: Label
var _lugar: Label
var _tempo: Label


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	var grupo := UiInv.painel()
	grupo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var g := UiInv.caixa(true, 12)
	_linhas = UiInv.caixa(true, 10)
	_linhas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_trilha = TrilhaConceitos.new()
	g.add_child(_linhas)
	g.add_child(UiInv.divisor())
	g.add_child(_trilha)
	grupo.add_child(g)
	add_child(grupo)

	var lado := UiInv.caixa(true, 14)
	lado.custom_minimum_size.x = 300
	# prévia da mochila: um botão grande que abre os Itens
	_previa = Button.new()
	_previa.name = "PreviaMochila"
	_previa.theme_type_variation = &"InvCelula"
	_previa.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_previa.pressed.connect(func(): Inventory.clique(); Inventory.trocar("itens"))
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado_m in ["left", "top", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + lado_m, 12)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := UiInv.caixa(true, 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UiInv.rotulo("Mochila", 20))
	_previa_itens = GridContainer.new()
	_previa_itens.columns = 1
	_previa_itens.add_theme_constant_override("h_separation", 10)
	_previa_itens.add_theme_constant_override("v_separation", 8)
	_previa_itens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_previa_itens)
	m.add_child(v)
	_previa.add_child(m)
	lado.add_child(_previa)
	var rodape := UiInv.painel()
	var r := UiInv.caixa(true, 4)
	_dinheiro = UiInv.rotulo("", 16)
	_lugar = UiInv.rotulo("", 16)
	_tempo = UiInv.rotulo("", 16)
	for l in [_dinheiro, _lugar, _tempo]:
		r.add_child(l)
	rodape.add_child(r)
	lado.add_child(rodape)
	add_child(lado)
	Inventory.mudou.connect(_atualizar)


func abrir_tela(_p) -> void:
	_atualizar()
	linhas()[0].grab_focus()


func linhas() -> Array:
	return _linhas.get_children()


func texto_dinheiro() -> String:
	return _dinheiro.text


func _process(_d: float) -> void:
	if is_visible_in_tree():
		var s := int(Inventory.tempo_jogo)
		_tempo.text = "Tempo  %02d:%02d" % [s / 3600, (s / 60) % 60]


func _atualizar() -> void:
	if _linhas == null:
		return
	UiInv.limpar(_linhas)
	for p in Party.get_children():
		_linhas.add_child(_linha(p))
	_trilha.atualizar()
	_atualizar_previa()
	_dinheiro.text = "%d %s" % [Inventory.dinheiro, Inventory.MOEDA]
	var cena := get_tree().current_scene
	var lugar = cena.get("nome_local") if cena else null
	_lugar.text = lugar if lugar is String else (str(cena.name) if cena else "")


func _linha(p) -> Button:
	var b := Button.new()
	b.theme_type_variation = &"InvComando"
	b.custom_minimum_size.y = 104
	b.pressed.connect(_on_personagem.bind(p))
	var h := UiInv.caixa(false, 16)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8
	h.offset_right = -8
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(UiInv.retrato(p))
	var nome := UiInv.caixa(true, 4)
	nome.custom_minimum_size.x = 160
	nome.alignment = BoxContainer.ALIGNMENT_CENTER
	nome.add_child(UiInv.rotulo(p.get_nome(), 24))
	var tag := UiInv.chip(p.get_class_name())
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	nome.add_child(tag)
	nome.add_child(UiInv.rotulo("Nv %d" % p.get_level(), 14))
	h.add_child(nome)
	h.add_child(UiInv.medidor("HP", p.get_hp(), p.get_max_hp(), UiInv.VERDE))
	h.add_child(UiInv.medidor("PP", p.get_pp(), p.get_max_pp(), UiInv.AZUL))
	for c in h.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	return b


func _atualizar_previa() -> void:
	UiInv.limpar(_previa_itens)
	var itens := Inventory.mochila.comuns()
	for it in itens.slice(0, ITENS_NA_PREVIA):
		var h := UiInv.caixa(false, 6)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := TextureRect.new()
		ic.texture = it.get_icon()
		ic.custom_minimum_size = Vector2(32, 32)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(ic)
		var l := UiInv.rotulo("%s x%d" % [it.ITEM_NAME, it.QUANTITY], 14)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(l)
		_previa_itens.add_child(h)
	if itens.is_empty():
		_previa_itens.add_child(UiInv.rotulo("vazia", 14, &"InvTextoBloqueado"))
	elif itens.size() > ITENS_NA_PREVIA:
		_previa_itens.add_child(UiInv.rotulo("+%d" % (itens.size() - ITENS_NA_PREVIA), 14))


func _on_personagem(p) -> void:
	Inventory.clique()
	Inventory.ir("status", p)
