class_name JavaCodePanel
extends PanelContainer
## Painel lateral com o editor de código do jogo.
##
## Fica preso na borda direita da tela, pode ser recolhido (sobra só uma aba
## fina) e o jogador pode arrastar a borda para deixá-lo mais largo.
## Coloque-o dentro de um CanvasLayer para ficar por cima do jogo:
##
##     var painel := JavaCodePanel.new()
##     $CanvasLayer.add_child(painel)
##     painel.open_code(template_com_marcas, "Porta da fase 1", "Complete a condição do if")
##     painel.run_requested.connect(func(codigo): ...)

## O jogador apertou Executar (ou Ctrl+Enter).
signal run_requested(code: String)
## O código mudou (mudança aceita).
signal code_changed
## Abriu ou recolheu.
signal toggled(aberto: bool)

@export var largura := 460.0
@export var largura_minima := 300.0
@export var comecar_aberto := true
@export var fonte_codigo: Font
@export var tamanho_fonte := 15
@export var altura_console := 110.0

var editor: LockedCodeEdit
var console: RichTextLabel
var aberto := true

var _titulo: Label
var _dica: Label
var _status: Label
var _btn_executar: Button
var _btn_reset: Button
var _btn_fechar: Button
var _aba: Button
var _aba_texto: Label
var _alca: Control
var _conteudo: VBoxContainer
var _arrastando := false
var _tween: Tween
var _status_id := 0

const LARGURA_ABA := 26.0
const AJUDA := "Tab: próxima parte editável   Ctrl+Enter: executar"


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona com o jogo pausado
	_montar()


func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_top = 0.0
	offset_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	aberto = comecar_aberto
	_posicionar(aberto, false)


# ---------------------------------------------------------------- API

## Abre o painel com um código (com ou sem marcas {| |}).
func open_code(template: String, titulo := "", dica := "") -> bool:
	_titulo.text = titulo if titulo != "" else "Código"
	_dica.text = dica
	_dica.visible = dica != ""
	clear_output()
	var ok := editor.load_template(template)
	if not ok:
		_escrever("[color=#ff6b6b]Marcação {| |} inválida (veja o Output do Godot)[/color]\n")
	_btn_reset.visible = true
	_mostrar_ajuda()
	expand()
	return ok


func get_code() -> String:
	return editor.get_code()


func get_region_texts() -> PackedStringArray:
	return editor.get_region_texts()


## Mostra um erro do interpretador: mensagem no console e a linha marcada.
func show_error(mensagem: String, linha := 0) -> void:
	expand()
	var texto := _escapar(mensagem)
	if linha > 0:
		texto = "[url=%d]%s[/url]" % [linha, texto]
	_escrever("[color=#ff6b6b]%s[/color]\n" % texto)
	editor.show_error(linha, mensagem)


## Texto de System.out.println etc.
func print_output(texto: String) -> void:
	_escrever(_escapar(texto))


func print_success(texto: String) -> void:
	_escrever("[color=#7ee787]%s[/color]\n" % _escapar(texto))


func clear_output() -> void:
	console.clear()
	editor.clear_error()


## Enquanto o jogo anima o resultado, desliga o botão Executar.
func set_running(rodando: bool) -> void:
	_btn_executar.disabled = rodando
	_btn_executar.text = "Executando..." if rodando else "Executar"


## true se o jogador está digitando (use para ignorar as teclas do jogo).
func is_typing() -> bool:
	return aberto and editor.has_focus()


func expand() -> void:
	if not aberto:
		_posicionar(true, true)


func collapse() -> void:
	if aberto:
		editor.release_focus()
		_posicionar(false, true)


func toggle() -> void:
	if aberto:
		collapse()
	else:
		expand()


# ---------------------------------------------------------------- montagem

func _montar() -> void:
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("1b1e25f5")
	fundo.border_color = Color("3a404d")
	fundo.border_width_left = 1
	fundo.corner_radius_top_left = 8
	fundo.corner_radius_bottom_left = 8
	fundo.content_margin_left = 0
	fundo.content_margin_right = 8
	fundo.content_margin_top = 6
	fundo.content_margin_bottom = 8
	add_theme_stylebox_override("panel", fundo)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	add_child(hbox)

	_aba = Button.new()
	_aba.flat = true
	_aba.custom_minimum_size = Vector2(LARGURA_ABA, 0)
	_aba.focus_mode = Control.FOCUS_NONE
	_aba.tooltip_text = "Abrir/fechar o editor de código"
	_aba.pressed.connect(toggle)
	hbox.add_child(_aba)
	_aba_texto = Label.new()
	_aba_texto.text = "C\nÓ\nD\nI\nG\nO"
	_aba_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aba_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_aba_texto.add_theme_font_size_override("font_size", 12)
	_aba_texto.add_theme_color_override("font_color", Color("8b93a3"))
	_aba_texto.add_theme_constant_override("line_spacing", -2)
	_aba_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aba_texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	_aba.add_child(_aba_texto)

	_alca = Control.new()
	_alca.custom_minimum_size = Vector2(6, 0)
	_alca.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	_alca.tooltip_text = "Arraste para mudar a largura"
	_alca.gui_input.connect(_on_alca_input)
	hbox.add_child(_alca)

	_conteudo = VBoxContainer.new()
	_conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_conteudo.add_theme_constant_override("separation", 6)
	hbox.add_child(_conteudo)

	var cab := HBoxContainer.new()
	_conteudo.add_child(cab)
	_titulo = Label.new()
	_titulo.text = "Código"
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_titulo.clip_text = true
	_titulo.add_theme_font_size_override("font_size", 16)
	_titulo.add_theme_color_override("font_color", Color("e6e9ef"))
	cab.add_child(_titulo)
	_btn_reset = _botao("Recomeçar", "Volta ao código original (Ctrl+Z desfaz)")
	_btn_reset.pressed.connect(func(): editor.reset_code())
	cab.add_child(_btn_reset)
	_btn_executar = _botao("Executar", "Executar o código (Ctrl+Enter)")
	_btn_executar.add_theme_color_override("font_color", Color("0d1117"))
	_btn_executar.add_theme_color_override("font_hover_color", Color("0d1117"))
	_btn_executar.add_theme_color_override("font_pressed_color", Color("0d1117"))
	_btn_executar.add_theme_stylebox_override("normal", _caixa(Color("3fb950")))
	_btn_executar.add_theme_stylebox_override("hover", _caixa(Color("56d364")))
	_btn_executar.add_theme_stylebox_override("pressed", _caixa(Color("2ea043")))
	_btn_executar.add_theme_stylebox_override("disabled", _caixa(Color("3a404d")))
	_btn_executar.pressed.connect(_executar)
	cab.add_child(_btn_executar)
	_btn_fechar = _botao("»", "Recolher")
	_btn_fechar.pressed.connect(collapse)
	cab.add_child(_btn_fechar)

	_dica = Label.new()
	_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dica.add_theme_font_size_override("font_size", 13)
	_dica.add_theme_color_override("font_color", Color("c9a227"))
	_dica.visible = false
	_conteudo.add_child(_dica)

	editor = LockedCodeEdit.new()
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.custom_minimum_size = Vector2(0, 120)
	editor.add_theme_color_override("background_color", Color("12141a"))
	editor.add_theme_color_override("current_line_color", Color(1, 1, 1, 0.04))
	editor.add_theme_color_override("line_number_color", Color("5c6370"))
	editor.add_theme_color_override("font_color", Color("d4d4d4"))
	editor.add_theme_color_override("selection_color", Color("264f78"))
	editor.add_theme_color_override("caret_color", Color("e6e9ef"))
	var borda := StyleBoxFlat.new()
	borda.bg_color = Color("12141a")
	borda.set_corner_radius_all(4)
	borda.set_content_margin_all(4)
	editor.add_theme_stylebox_override("normal", borda)
	var borda_foco := borda.duplicate()
	borda_foco.border_color = Color("3b82f6")
	borda_foco.set_border_width_all(1)
	editor.add_theme_stylebox_override("focus", borda_foco)
	editor.code_edited.connect(func(): code_changed.emit())
	editor.edit_blocked.connect(_on_bloqueado)
	editor.run_shortcut.connect(_executar)
	_conteudo.add_child(editor)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 12)
	_status.clip_text = true
	_conteudo.add_child(_status)

	console = RichTextLabel.new()
	console.bbcode_enabled = true
	console.scroll_following = true
	console.selection_enabled = true
	console.custom_minimum_size = Vector2(0, altura_console)
	console.add_theme_font_size_override("normal_font_size", 13)
	var cfundo := StyleBoxFlat.new()
	cfundo.bg_color = Color("0d0f13")
	cfundo.set_corner_radius_all(4)
	cfundo.set_content_margin_all(6)
	console.add_theme_stylebox_override("normal", cfundo)
	console.meta_clicked.connect(func(meta): _ir_para_linha(int(str(meta))))
	_conteudo.add_child(console)
	_mostrar_ajuda()


func _enter_tree() -> void:
	var f := fonte_codigo
	if f == null:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["JetBrains Mono", "Cascadia Mono", "Consolas",
				"DejaVu Sans Mono", "Menlo", "Liberation Mono", "monospace"])
		f = sf
	editor.add_theme_font_override("font", f)
	editor.add_theme_font_size_override("font_size", tamanho_fonte)
	console.add_theme_font_override("normal_font", f)
	console.custom_minimum_size.y = altura_console


func _botao(texto: String, dica: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.tooltip_text = dica
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 13)
	return b


func _caixa(cor: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	s.set_corner_radius_all(4)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	return s


# ---------------------------------------------------------------- comportamento

func _executar() -> void:
	if _btn_executar.disabled:
		return
	clear_output()
	run_requested.emit(editor.get_code())


func _on_bloqueado(motivo: String) -> void:
	var msg := "Essa parte do código está travada. Edite só o que está destacado em azul."
	if motivo == "uma_linha":
		msg = "Aqui só cabe uma linha (sem Enter)."
	elif editor.regions.is_empty():
		msg = "Este código é só para leitura."
	_mostrar_status(msg, Color("ff9e64"))


func _mostrar_status(msg: String, cor: Color, segundos := 2.5) -> void:
	_status_id += 1
	var id := _status_id
	_status.text = msg
	_status.add_theme_color_override("font_color", cor)
	if is_inside_tree():
		await get_tree().create_timer(segundos, true, false, true).timeout
		if id == _status_id:
			_mostrar_ajuda()


func _mostrar_ajuda() -> void:
	_status.text = AJUDA if editor.locked and not editor.regions.is_empty() else "Ctrl+Enter: executar"
	_status.add_theme_color_override("font_color", Color("6b7280"))


func _ir_para_linha(linha: int) -> void:
	if linha < 1:
		return
	editor.set_caret_line(linha - 1)
	editor.set_caret_column(0)
	editor.center_viewport_to_caret()
	editor.grab_focus()


func _escrever(bb: String) -> void:
	console.append_text(bb)


static func _escapar(t: String) -> String:
	return t.replace("[", "[lb]")


func _posicionar(abrir: bool, animar: bool) -> void:
	aberto = abrir
	var alvo_esq := -largura if abrir else -LARGURA_ABA
	var alvo_dir := 0.0 if abrir else largura - LARGURA_ABA
	if _tween:
		_tween.kill()
	if animar and is_inside_tree():
		_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "offset_left", alvo_esq, 0.22)
		_tween.tween_property(self, "offset_right", alvo_dir, 0.22)
	else:
		offset_left = alvo_esq
		offset_right = alvo_dir
	_aba_texto.add_theme_color_override("font_color", Color("8b93a3") if abrir else Color("e6e9ef"))
	toggled.emit(abrir)


func _on_alca_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		_arrastando = ev.pressed
	elif ev is InputEventMouseMotion and _arrastando and aberto:
		var maximo := get_viewport_rect().size.x * 0.85
		largura = clampf(largura - ev.relative.x, largura_minima, maximo)
		offset_left = -largura
		offset_right = 0.0
