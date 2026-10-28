class_name UiInv
extends RefCounted
## Peças repetidas das telas do inventário (o estilo vem de tema_inventario.tres).

const TINTA := Color("#1b1b1b")
const VERDE := Color("#3fae5a")
const AZUL := Color("#3b7dd8")
# toques dos pacotes da Kenney (assets/gui/kenney/LEIAME.txt)
const SETA := preload("res://assets/gui/kenney/seta.png")
const EXCLAMACAO := preload("res://assets/gui/kenney/exclamacao.png")
const DIVISOR_ESQ := preload("res://assets/gui/kenney/divisor_esq.png")
const DIVISOR_DIR := preload("res://assets/gui/kenney/divisor_dir.png")


static func rotulo(texto: String, tamanho := 0, variacao := &"") -> Label:
	var l := Label.new()
	l.text = texto
	if tamanho:
		l.add_theme_font_size_override("font_size", tamanho)
	l.theme_type_variation = variacao
	return l


static func painel(variacao := &"InvPainel") -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variacao
	return p


static func caixa(vertical := true, separacao := 8) -> BoxContainer:
	var c: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	c.add_theme_constant_override("separation", separacao)
	return c


static func barra(cor: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, 14)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color.WHITE
	fundo.border_color = TINTA
	fundo.set_border_width_all(2)
	fundo.set_corner_radius_all(5)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = cor
	cheio.set_corner_radius_all(4)
	b.add_theme_stylebox_override("background", fundo)
	b.add_theme_stylebox_override("fill", cheio)
	return b


## "HP      42/50" com a barra embaixo.
static func medidor(texto: String, valor: int, maximo: int, cor: Color) -> VBoxContainer:
	var v := caixa(true, 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var topo := caixa(false, 0)
	topo.add_child(rotulo(texto, 14))
	var n := rotulo("%d/%d" % [valor, maximo], 14)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	topo.add_child(n)
	v.add_child(topo)
	var b := barra(cor)
	b.max_value = maxi(maximo, 1)
	b.value = valor
	v.add_child(b)
	return v


## Etiqueta amarela (classe, conceito); bloqueado = cinza.
static func chip(texto: String, ligado := true) -> PanelContainer:
	var p := painel(&"InvChip" if ligado else &"InvChipBloqueado")
	var l := rotulo(texto, 12, &"" if ligado else &"InvTextoBloqueado")
	l.name = "Texto"
	p.add_child(l)
	return p


## O "!" de algo novo desbloqueado.
static func badge() -> TextureRect:
	var b := TextureRect.new()
	b.name = "Badge"
	b.texture = EXCLAMACAO
	b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -20
	b.offset_top = -10
	b.offset_right = 6
	b.offset_bottom = 16
	b.hide()
	return b


## Linha decorativa ── ◇◇ ── entre partes de um painel: duas metades espelhadas,
## a linha estica e o enfeite do meio fica do tamanho certo.
static func divisor() -> HBoxContainer:
	var d := HBoxContainer.new()
	d.name = "Divisor"
	d.modulate = TINTA
	d.add_theme_constant_override("separation", 0)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in [[DIVISOR_ESQ, "patch_margin_right"], [DIVISOR_DIR, "patch_margin_left"]]:
		var metade := NinePatchRect.new()
		metade.texture = lado[0]
		metade.set(lado[1], 48)  # o enfeite ocupa a metade da imagem
		metade.custom_minimum_size = Vector2(48, 14)
		metade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		metade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.add_child(metade)
	return d


## Painel escuro com um RichTextLabel de código; devolve o painel (o texto é o filho "Codigo").
static func codigo() -> PanelContainer:
	var p := painel(&"InvCodigo")
	var t := RichTextLabel.new()
	t.name = "Codigo"
	t.theme_type_variation = &"InvCodigoTexto"
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	p.add_child(t)
	return p


static func comando(nome: String, texto: String) -> Button:
	var b := Button.new()
	b.name = nome
	b.text = texto
	b.theme_type_variation = &"InvComando"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 20)
	b.add_child(badge())
	# a seta aparece no comando com foco ou com o mouse em cima
	var mostrar := func(): b.icon = SETA
	var esconder := func(): if not b.has_focus() and not b.is_hovered(): b.icon = null
	b.focus_entered.connect(mostrar)
	b.mouse_entered.connect(mostrar)
	b.focus_exited.connect(esconder)
	b.mouse_exited.connect(func(): if not b.has_focus(): b.icon = null)
	return b


## Retrato do personagem com a cor provisória da classe.
static func retrato(p, lado := 86) -> TextureRect:
	var r := TextureRect.new()
	r.texture = p.get_retrato()
	r.modulate = p.get_cor_classe()
	r.custom_minimum_size = Vector2(lado, lado)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return r


static func limpar(no: Node) -> void:
	for c in no.get_children():
		no.remove_child(c)
		c.queue_free()
