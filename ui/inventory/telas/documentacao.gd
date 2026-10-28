extends VBoxContainer
## Documentação: uma página por conceito liberado. Só explicação geral, sem dica de puzzle.

const PASTA := "res://ui/inventory/documentacao/"

var paginas: Array[PaginaDoc] = []
var trilha: TrilhaConceitos
var exemplo: RichTextLabel
var _lista: VBoxContainer
var _titulo: Label
var _texto: RichTextLabel


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	for f in ResourceLoader.list_directory(PASTA):
		if f.ends_with(".tres"):
			var pg: PaginaDoc = load(PASTA + f)
			pg.set_meta("id", f.get_basename())
			paginas.append(pg)
	paginas.sort_custom(func(a, b): return a.ORDEM < b.ORDEM)
	trilha = TrilhaConceitos.new()
	add_child(trilha)
	var h := UiInv.caixa(false, 18)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var p_lista := UiInv.painel()
	p_lista.custom_minimum_size.x = 240
	_lista = UiInv.caixa(true, 2)
	p_lista.add_child(_lista)
	h.add_child(p_lista)
	var p_pag := UiInv.painel()
	p_pag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UiInv.caixa(true, 12)
	_titulo = UiInv.rotulo("", 28)
	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.fit_content = true
	_texto.add_theme_color_override("default_color", UiInv.TINTA)
	_texto.add_theme_font_size_override("normal_font_size", 18)
	_texto.add_theme_font_size_override("bold_font_size", 18)
	var cod := UiInv.codigo()
	exemplo = cod.get_node("Codigo")
	exemplo.add_theme_font_size_override("normal_font_size", 15)
	for n in [_titulo, UiInv.divisor(), _texto, cod]:
		v.add_child(n)
	p_pag.add_child(v)
	h.add_child(p_pag)
	add_child(h)


func abrir_tela(_p) -> void:
	UiInv.limpar(_lista)
	for pg in paginas:
		var livre := Progresso.tem(pg.REQUER)
		var b := UiInv.comando(pg.get_meta("id"), pg.TITULO if livre else "???")
		b.disabled = not livre
		if livre:
			b.pressed.connect(abrir_pagina.bind(pg))
			b.focus_entered.connect(abrir_pagina.bind(pg))
		else:
			b.focus_mode = Control.FOCUS_NONE  # senão o foco abriria a página e mostraria o nome
		_lista.add_child(b)
	trilha.atualizar()
	for id in Progresso.CONCEITOS:  # primeira vez: o ??? vira o nome
		if Progresso.novo(id):
			trilha.revelar(id)
			Progresso.marcar_visto(id)
	Progresso.marcar_visto("basico")
	var primeira := _lista.get_child(0) as Button
	abrir_pagina(paginas[0])
	primeira.grab_focus()


func pagina(id: String) -> PaginaDoc:
	for pg in paginas:
		if pg.get_meta("id") == id:
			return pg
	return null


func titulo() -> String:
	return _titulo.text


func botao(id: String) -> Button:
	return _lista.get_node_or_null(id)


func abrir_pagina(pg: PaginaDoc) -> void:
	if not Progresso.tem(pg.REQUER):
		return
	_titulo.text = pg.TITULO
	_texto.text = pg.TEXTO
	exemplo.get_parent().visible = pg.EXEMPLO.strip_edges() != ""
	exemplo.text = "\n".join(Array(pg.EXEMPLO.split("\n")).map(CodigoJava.colorir))
