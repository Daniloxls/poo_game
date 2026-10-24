class_name LockedCodeEdit
extends CodeEdit
## CodeEdit em que o level designer trava partes do código.
##
## Carregue o código com load_template(); as partes marcadas com {| ... |}
## (veja JavaEditableMarkup) são as únicas que o jogador consegue mudar.
## O texto do editor é sempre o código Java "limpo", pronto para o interpretador:
## os números de linha dos erros batem com o que o jogador vê.
##
## Como a trava funciona: depois de cada mudança o editor compara o texto novo
## com o último texto aceito. Se a mudança caiu inteira dentro de uma região
## editável, ela é aceita e as regiões andam junto; se não, o texto volta como
## era. Assim nenhum caminho de edição escapa (digitar, colar, recortar,
## arrastar, completar chaves, Ctrl+Backspace...). O desfazer (Ctrl+Z / Ctrl+Y)
## é do próprio editor, para que desfazer nunca traga de volta uma mudança proibida.

## Mudança aceita.
signal code_edited
## O jogador tentou mexer numa parte travada. motivo: "travado" ou "uma_linha".
signal edit_blocked(motivo: String)
## Ctrl+Enter.
signal run_shortcut

## Sem nenhum marcador {| |}, true = tudo livre; false = tudo só leitura.
@export var livre_sem_marcas := true
@export var cor_regiao := Color(0.30, 0.65, 1.0, 0.13)
@export var cor_borda := Color(0.40, 0.72, 1.0, 0.70)
@export var cor_erro := Color(1.0, 0.25, 0.25, 0.22)
@export var cor_bloqueio := Color(1.0, 0.45, 0.30, 0.9)

## Regiões editáveis: [{"start", "end", "multiline"}], em ordem, sem sobreposição.
var regions: Array = []
## true quando existe trava (o código tem marcadores, ou livre_sem_marcas = false).
var locked := false

var _template := ""
var _texto := ""                       # último texto aceito
var _inicios := PackedInt32Array([0])  # posição onde começa cada linha de _texto
var _caret_ok := Vector2i.ZERO
var _scroll_ok := 0.0
var _undo: Array = []
var _redo: Array = []
var _ultima_edicao := 0
var _ultimo_tipo := ""
var _ultima_regiao := -1
var _erro_linha := -1
var _erro_msg := ""
var _gutter := -1
var _flash := 0.0:
	set(v):
		_flash = v
		queue_redraw()
var _flash_linha := -1
var _flash_tween: Tween


func _init() -> void:
	syntax_highlighter = JavaRegionHighlighter.new()
	gutters_draw_line_numbers = true
	indent_automatic = true
	auto_brace_completion_enabled = true
	code_completion_enabled = false
	caret_multiple = false
	drag_and_drop_selection_enabled = false
	highlight_current_line = true
	draw_tabs = false
	indent_use_spaces = true
	indent_size = 4
	scroll_past_end_of_file = false
	# linhas longas quebram no limite do painel, mantendo a indentação
	wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	indent_wrapped_lines = true
	_gutter = get_gutter_count()
	add_gutter()
	set_gutter_type(_gutter, TextEdit.GUTTER_TYPE_CUSTOM)
	set_gutter_width(_gutter, 14)
	set_gutter_custom_draw(_gutter, _desenhar_gutter)
	text_changed.connect(_on_text_changed)
	caret_changed.connect(_on_caret_changed)


# ---------------------------------------------------------------- API

## Carrega um código com marcação {| |}. Devolve false (e avisa) se a marcação
## estiver errada.
func load_template(template: String) -> bool:
	var r := JavaEditableMarkup.parse(template)
	if r.error != "":
		push_error("LockedCodeEdit: " + r.error)
		return false
	_template = template
	locked = not r.regions.is_empty() or not livre_sem_marcas
	_aplicar_estado({"text": r.text, "regions": r.regions, "caret": Vector2i.ZERO})
	_undo.clear()
	_redo.clear()
	if not regions.is_empty():
		go_to_region(0)
	return true


## Volta ao código original do template (pode ser desfeito com Ctrl+Z).
func reset_code() -> void:
	var r := JavaEditableMarkup.parse(_template)
	if r.error != "":
		return
	_empilhar_undo(_estado_atual(), true)
	_aplicar_estado({"text": r.text, "regions": r.regions, "caret": Vector2i.ZERO})
	if not regions.is_empty():
		go_to_region(0)
	code_edited.emit()


## O código Java do jogador, pronto para java.load_source().
func get_code() -> String:
	return _texto


## O texto de cada região editável, na ordem. Útil para conferir a resposta
## de um puzzle (ex.: qual condição o jogador escreveu).
func get_region_texts() -> PackedStringArray:
	var res := PackedStringArray()
	for r in regions:
		res.append(_texto.substr(r.start, r.end - r.start))
	return res


## Estado completo (código + regiões) para salvar o progresso do jogador.
## É só Dictionary/Array/String/int, dá para salvar em JSON.
func get_state() -> Dictionary:
	return {"text": _texto, "regions": regions.duplicate(true), "template": _template, "locked": locked}


func set_state(estado: Dictionary) -> void:
	_template = estado.get("template", "")
	locked = estado.get("locked", not estado.regions.is_empty())
	var regs: Array = []
	for r in estado.regions:   # JSON devolve float; volta para int
		regs.append({"start": int(r.start), "end": int(r.end), "multiline": bool(r.multiline)})
	_aplicar_estado({"text": estado.text, "regions": regs, "caret": Vector2i.ZERO})
	_undo.clear()
	_redo.clear()


## Marca a linha do erro (linha começando em 1, como nas mensagens do interpretador).
func show_error(linha: int, mensagem: String) -> void:
	clear_error()
	if linha < 1 or linha > get_line_count():
		return
	_erro_linha = linha - 1
	_erro_msg = mensagem
	set_line_background_color(_erro_linha, cor_erro)
	set_caret_line(_erro_linha)
	center_viewport_to_caret()
	queue_redraw()


func clear_error() -> void:
	if _erro_linha >= 0 and _erro_linha < get_line_count():
		set_line_background_color(_erro_linha, Color(0, 0, 0, 0))
	_erro_linha = -1
	_erro_msg = ""
	queue_redraw()


## Pode editar nesta posição do texto (índice de caractere)?
func is_offset_editable(pos: int) -> bool:
	return not locked or _regiao_em(pos, pos) >= 0


## Coloca o cursor na região i (seleciona o conteúdo se for de uma linha só).
func go_to_region(i: int) -> void:
	if regions.is_empty():
		return
	i = posmod(i, regions.size())
	var r: Dictionary = regions[i]
	var a := _lc(r.start)
	var b := _lc(r.end)
	if r.multiline or r.start == r.end:
		deselect()
		set_caret_line(b.x)
		set_caret_column(b.y)
	else:
		select(a.x, a.y, b.x, b.y)
		set_caret_line(b.x)
		set_caret_column(b.y)
	grab_focus()


## Pedaços da linha [[col_ini, col_fim, travado], ...] (usado pelas cores).
func locked_ranges_on_line(linha: int) -> Array:
	if not locked or linha >= _inicios.size():
		return []
	var ini := _inicios[linha]
	var fim := _fim_linha(linha)
	var res: Array = []
	var col := 0
	for r in regions:
		var a: int = maxi(r.start, ini)
		var b: int = mini(r.end, fim)
		if b <= a:
			continue
		if a - ini > col:
			res.append([col, a - ini, true])
		res.append([a - ini, b - ini, false])
		col = b - ini
	if col < fim - ini or res.is_empty():
		res.append([col, fim - ini, true])
	return res


# ---------------------------------------------------------------- trava

func _on_text_changed() -> void:
	var novo := text
	if novo == _texto:
		return
	var m := _encontrar_mudanca(_texto, novo)
	if m.is_empty() or (locked and m.regiao < 0):
		var motivo := "travado"
		if not m.is_empty() and m.get("uma_linha", false):
			motivo = "uma_linha"
		_voltar(m)
		edit_blocked.emit(motivo)
		return
	var antes := _estado_atual()
	if locked:
		var delta: int = m.inserido.length() - (m.b - m.a)
		for i in range(m.regiao, regions.size()):
			if i > m.regiao:
				regions[i].start += delta
			regions[i].end += delta
	var tipo := "quebra" if m.inserido.contains("\n") else ("apaga" if m.inserido == "" else "escreve")
	_empilhar_undo(antes, tipo != _ultimo_tipo or tipo == "quebra" or m.regiao != _ultima_regiao)
	_ultimo_tipo = tipo
	_ultima_regiao = m.regiao
	_texto = novo
	_recalcular_linhas()
	clear_undo_history()
	if _erro_linha >= 0:
		clear_error()
	_caret_ok = Vector2i(get_caret_line(), get_caret_column())
	_scroll_ok = scroll_vertical
	syntax_highlighter.clear_highlighting_cache()
	queue_redraw()
	code_edited.emit()


## Descobre o que mudou entre `velho` e `novo`: velho[a, b) virou `inserido`.
## Quando há letras repetidas a posição é ambígua (digitar ")" antes de um ")"),
## então testa todas as posições possíveis e fica com a que cabe numa região,
## preferindo a mais perto do cursor.
func _encontrar_mudanca(velho: String, novo: String) -> Dictionary:
	var lv := velho.length()
	var ln := novo.length()
	var menor := mini(lv, ln)
	var p := 0
	while p < menor and velho.unicode_at(p) == novo.unicode_at(p):
		p += 1
	var s := 0
	while s < menor and velho.unicode_at(lv - 1 - s) == novo.unicode_at(ln - 1 - s):
		s += 1
	var total := mini(p + s, menor)
	var cursor := _offset(get_caret_line(), get_caret_column(), novo)
	var melhor := {}
	var melhor_dist := 1 << 30
	var uma_linha := false
	for pp in range(mini(p, total), maxi(0, total - s) - 1, -1):
		var q := total - pp
		var m := {"a": pp, "b": lv - q, "inserido": novo.substr(pp, ln - q - pp), "regiao": -1}
		if locked:
			var r := _regiao_em(m.a, m.b)
			if r >= 0 and not regions[r].multiline and m.inserido.contains("\n"):
				uma_linha = true
				r = -1
			m.regiao = r
		var dist := absi(cursor - (ln - q))
		if melhor.is_empty() or (m.regiao >= 0 and (melhor.regiao < 0 or dist < melhor_dist)):
			melhor = m
			melhor_dist = dist
		if not locked:
			break
	if not melhor.is_empty() and melhor.regiao < 0:
		melhor["uma_linha"] = uma_linha
	return melhor


## Região que contém o trecho [a, b) (as bordas contam: dá para escrever
## logo antes ou logo depois do que já está na região). -1 se nenhuma.
func _regiao_em(a: int, b: int) -> int:
	for i in regions.size():
		var r: Dictionary = regions[i]
		if r.start <= a and b <= r.end:
			return i
	return -1


func _voltar(m: Dictionary) -> void:
	var linha := _caret_ok.x
	if not m.is_empty():
		linha = _lc(m.a).x
	var scroll := _scroll_ok
	var caret := _caret_ok
	text = _texto
	clear_undo_history()
	deselect()
	set_caret_line(caret.x)
	set_caret_column(caret.y)
	scroll_vertical = scroll
	_piscar(linha)


func _on_caret_changed() -> void:
	if text == _texto:
		_caret_ok = Vector2i(get_caret_line(), get_caret_column())
		_scroll_ok = scroll_vertical


func _piscar(linha: int) -> void:
	_flash_linha = linha
	if _flash_tween:
		_flash_tween.kill()
	if not is_inside_tree():
		return
	_flash = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "_flash", 0.0, 0.45)


# ---------------------------------------------------------------- desfazer

func _estado_atual() -> Dictionary:
	return {"text": _texto, "regions": regions.duplicate(true), "caret": _caret_ok}


func _empilhar_undo(estado: Dictionary, forcar: bool) -> void:
	var agora := Time.get_ticks_msec()
	# letras digitadas em sequência viram um passo só de desfazer
	if forcar or _undo.is_empty() or agora - _ultima_edicao > 800:
		_undo.append(estado)
		if _undo.size() > 300:
			_undo.pop_front()
	_ultima_edicao = agora
	_redo.clear()


func undo_edit() -> void:
	if _undo.is_empty():
		return
	_redo.append(_estado_atual())
	_aplicar_estado(_undo.pop_back())
	_ultimo_tipo = ""
	code_edited.emit()


func redo_edit() -> void:
	if _redo.is_empty():
		return
	_undo.append(_estado_atual())
	_aplicar_estado(_redo.pop_back())
	_ultimo_tipo = ""
	code_edited.emit()


func _aplicar_estado(estado: Dictionary) -> void:
	clear_error()
	_texto = estado.text
	regions = estado.regions.duplicate(true)
	_recalcular_linhas()
	text = _texto
	clear_undo_history()
	var c: Vector2i = estado.caret
	set_caret_line(c.x)
	set_caret_column(c.y)
	_caret_ok = Vector2i(get_caret_line(), get_caret_column())
	_ultima_edicao = 0
	syntax_highlighter.clear_highlighting_cache()
	queue_redraw()


# ---------------------------------------------------------------- teclado

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	if event.is_action_pressed("ui_redo", true, true):
		redo_edit()
		accept_event()
	elif event.is_action_pressed("ui_undo", true, true):
		undo_edit()
		accept_event()
	elif event.keycode == KEY_ENTER and (event.ctrl_pressed or event.meta_pressed):
		run_shortcut.emit()
		accept_event()
	elif locked and (event.is_action_pressed("ui_text_indent", true, true)
			or event.is_action_pressed("ui_text_dedent", true, true)):
		# Tab pula para a próxima região (Shift+Tab, a anterior). Dentro de um
		# bloco de várias linhas o Tab continua recuando o código.
		var atual := _regiao_no_cursor()
		if atual >= 0 and regions[atual].multiline:
			return
		var dir := -1 if event.shift_pressed else 1
		go_to_region(_proxima_regiao(dir))
		accept_event()


func _regiao_no_cursor() -> int:
	var o := _offset(get_caret_line(), get_caret_column(), _texto)
	return _regiao_em(o, o)


func _proxima_regiao(dir: int) -> int:
	if regions.is_empty():
		return 0
	var o := _offset(get_caret_line(), get_caret_column(), _texto)
	var atual := _regiao_em(o, o)
	if atual >= 0:
		return atual + dir
	if dir > 0:
		for i in regions.size():
			if regions[i].start > o:
				return i
		return 0
	for i in range(regions.size() - 1, -1, -1):
		if regions[i].end < o:
			return i
	return regions.size() - 1


func _get_tooltip(at: Vector2) -> String:
	if _erro_linha >= 0:
		var lc := get_line_column_at_pos(Vector2i(at))
		if lc.y == _erro_linha:
			return _erro_msg
	return ""


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if not locked or get_line_count() != _inicios.size():
		return
	var primeira := get_first_visible_line()
	var ultima := mini(get_last_full_visible_line() + 1, get_line_count() - 1)
	var largura_util := size.x - (get_v_scroll_bar().size.x if get_v_scroll_bar().visible else 0.0)
	for r in regions:
		var a := _lc(r.start)
		var b := _lc(r.end)
		if b.x < primeira or a.x > ultima:
			continue
		var bloco: bool = r.multiline and a.y == 0 and r.end == _fim_linha(b.x)
		for linha in range(maxi(a.x, primeira), mini(b.x, ultima) + 1):
			var y := _y_linha(linha)
			if y < 0:
				continue
			if bloco:
				var h := _altura_linha(linha)
				var x0 := _x_base() - 4.0
				draw_rect(Rect2(x0, y, largura_util - x0, h), cor_regiao)
				draw_rect(Rect2(x0, y, 3, h), cor_borda)
			else:
				var c0: int = a.y if linha == a.x else 0
				var c1: int = b.y if linha == b.x else get_line(linha).length()
				for ret in _caixas(linha, c0, c1, y):
					draw_rect(ret, cor_regiao)
					draw_rect(ret, cor_borda, false, 1.0)
	if _flash > 0.0 and _flash_linha >= primeira and _flash_linha <= ultima:
		var y := _y_linha(_flash_linha)
		if y >= 0:
			var c := cor_bloqueio
			c.a *= _flash * 0.25
			draw_rect(Rect2(_x_base() - 4.0, y, largura_util, _altura_linha(_flash_linha)), c)


# Altura da linha na tela, contando as quebras de linha.
func _altura_linha(linha: int) -> float:
	return get_line_height() * (get_line_wrap_count(linha) + 1)


# Caixas que cobrem as colunas [c0, c1) da linha, uma por pedaço quebrado.
# get_rect_at_line_column erra a caixa perto da quebra, então só pegamos dele
# o começo de cada pedaço e medimos o texto com a fonte.
func _caixas(linha: int, c0: int, c1: int, y: float) -> Array[Rect2]:
	var h := get_line_height()
	var fonte := get_theme_font("font")
	var tam := get_theme_font_size("font_size")
	var caixas: Array[Rect2] = []
	var ini := 0
	for pedaco in get_line_wrapped_text(linha):
		var fim := ini + pedaco.length()
		var a := maxi(c0, ini)
		var b := mini(c1, fim)
		var vazia := c0 == c1 and c0 >= ini and c0 <= fim
		if a < b or vazia:
			var origem := Vector2(_x_base(), y)
			if ini > 0:   # na coluna da quebra o retângulo já é o do pedaço novo
				origem = Vector2(get_rect_at_line_column(linha, ini).position)
			var x0 := origem.x + fonte.get_string_size(pedaco.substr(0, a - ini), HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x - 2.0
			var x1 := maxf(origem.x + fonte.get_string_size(pedaco.substr(0, b - ini), HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + 2.0, x0 + 8.0)
			caixas.append(Rect2(x0, origem.y + 1, x1 - x0, h - 2))
			if vazia:
				break
		ini = fim
	return caixas


func _desenhar_gutter(linha: int, _g: int, area: Rect2) -> void:
	var centro := area.get_center()
	if linha == _erro_linha:
		draw_circle(centro, 4.5, Color(1, 0.35, 0.35))
		return
	if not locked:
		return
	var tem_editavel := false
	var ini := _inicios[linha] if linha < _inicios.size() else -1
	var fim := _fim_linha(linha)
	for r in regions:
		if r.start <= fim and r.end >= ini:
			tem_editavel = true
			break
	if tem_editavel:
		draw_rect(Rect2(centro.x - 1.5, area.position.y + 2, 3, area.size.y - 4), cor_borda)
	else:
		# cadeado pequeno
		var cor := Color(0.55, 0.58, 0.63, 0.8)
		draw_rect(Rect2(centro.x - 4, centro.y - 1, 8, 6), cor)
		draw_arc(Vector2(centro.x, centro.y - 1), 2.6, PI, TAU, 8, cor, 1.4)


func _x_base() -> float:
	return get_total_gutter_width() + get_theme_stylebox("normal").get_margin(SIDE_LEFT) - scroll_horizontal


func _y_linha(linha: int) -> float:
	var r := get_rect_at_line_column(linha, 0)
	if r.position.y < 0 and r.size == Vector2i.ZERO:
		return -1.0
	return r.position.y


# ---------------------------------------------------------------- posições

func _recalcular_linhas() -> void:
	_inicios = PackedInt32Array([0])
	var i := _texto.find("\n")
	while i >= 0:
		_inicios.append(i + 1)
		i = _texto.find("\n", i + 1)


func _fim_linha(linha: int) -> int:
	if linha + 1 < _inicios.size():
		return _inicios[linha + 1] - 1
	return _texto.length()


## posição no texto -> Vector2i(linha, coluna)
func _lc(pos: int) -> Vector2i:
	var linha := _inicios.bsearch(pos, false) - 1
	linha = clampi(linha, 0, _inicios.size() - 1)
	return Vector2i(linha, pos - _inicios[linha])


## (linha, coluna) -> posição em `t`
func _offset(linha: int, col: int, t: String) -> int:
	if t == _texto:
		if linha >= _inicios.size():
			return _texto.length()
		return _inicios[linha] + col
	var pos := 0
	for _i in linha:
		var n := t.find("\n", pos)
		if n < 0:
			return t.length()
		pos = n + 1
	return pos + col
