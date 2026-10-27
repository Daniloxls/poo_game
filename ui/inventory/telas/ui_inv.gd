class_name UiInv
extends RefCounted
## Peças repetidas das telas do inventário (o estilo vem de tema_inventario.tres).

const TINTA := Color("#1b1b1b")
const VERDE := Color("#3fae5a")
const AZUL := Color("#3b7dd8")


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


## Etiqueta amarela (classe, conceito); bloqueado = cinza.
static func chip(texto: String, ligado := true) -> PanelContainer:
	var p := painel(&"InvChip" if ligado else &"InvChipBloqueado")
	var l := rotulo(texto, 12, &"" if ligado else &"InvTextoBloqueado")
	l.name = "Texto"
	p.add_child(l)
	return p


static func badge() -> Panel:
	var b := Panel.new()
	b.name = "Badge"
	b.theme_type_variation = &"InvBadge"
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -10
	b.offset_top = -6
	b.offset_right = 6
	b.offset_bottom = 10
	b.hide()
	return b


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
