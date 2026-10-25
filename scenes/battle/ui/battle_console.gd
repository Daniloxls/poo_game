class_name BattleConsole
extends PanelContainer
## Console de código: o jogador digita "Turin.atacar(Montanha)" com autocompletar,
## erros sublinhados e mensagens de ensino. Um erro nunca custa o turno.

signal command_ready(cmd: ResolvedCommand)

const OK_COLOR := Color("#3fae5a")
const ERR_COLOR := Color("#e8463a")
const MAX_SUGGESTIONS := 6


var text: String:
	get:
		return _line.text
	set(v):
		_line.text = v
		_line.set_caret_column(v.length())
		_clear_error()
		_refresh()

var _ctx: BattleContext
var _line: CodeEdit
var _list: VBoxContainer
var _err: Label
var _hint: Label
var _status: Label
var _sugs: Array[ConsoleSuggestion] = []
var _hi := 0
var _err_span := Vector2i(-1, -1)
var _pad := false


func _init() -> void:
	theme = load("res://scenes/battle/ui/battle_theme.tres")
	theme_type_variation = &"BattlePanel"
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	visible = false
	var box := VBoxContainer.new()
	add_child(box)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 0)
	box.add_child(_list)
	_line = CodeEdit.new()
	_line.custom_minimum_size = Vector2(0, 38)
	_line.scroll_fit_content_height = true
	_line.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	_line.add_theme_font_override("font", BattleFonts.mono())
	_line.add_theme_font_size_override("font_size", 18)
	_line.syntax_highlighter = ConsoleHighlighter.new()
	_line.placeholder_text = "Turin.atacar(Montanha)"
	_line.draw.connect(_draw_error)
	_line.text_changed.connect(_on_text_changed)
	_line.gui_input.connect(_on_line_input)
	box.add_child(_line)
	_err = _msg_label(ERR_COLOR)
	_hint = _msg_label(Color("#1b1b1b"))
	_status = _msg_label(OK_COLOR)
	for l in [_err, _hint, _status]:
		box.add_child(l)


func _msg_label(c: Color) -> Label:
	var l := Label.new()
	l.add_theme_color_override("font_color", c)
	l.add_theme_font_override("font", BattleFonts.mono())
	l.visible = false
	return l


func error_label() -> Label:
	return _err


func status_label() -> Label:
	return _status


func suggestion_labels() -> Array:
	return _sugs.map(func(s): return s.label)


func set_context(ctx: BattleContext) -> void:
	_ctx = ctx
	_refresh()


func is_typing() -> bool:
	return _line.has_focus()


func open(from_joypad := false) -> void:
	visible = true
	_pad = from_joypad
	_line.editable = not from_joypad
	_refresh()
	if not from_joypad:
		_line.grab_focus()
		_line.set_caret_column(_line.text.length())


func close() -> void:
	visible = false
	_line.release_focus()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("battle_console") and not is_typing():
		open(ev is InputEventJoypadButton)
		get_viewport().set_input_as_handled()
	elif _pad and visible and ev.is_action_pressed("ui_cancel"):
		_delete_last_token()
		get_viewport().set_input_as_handled()


# Clique fora do console tira o foco sem deixar o clique chegar ao botão embaixo.
func _input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb and mb.pressed and _line.has_focus() and not get_global_rect().has_point(mb.position):
		_line.release_focus()
		get_viewport().set_input_as_handled()


## Teclas do console. Todo evento de teclado/ação é consumido aqui (ou pelo próprio
## CodeEdit, ao digitar), então nada vaza para _unhandled_input enquanto há foco.
func _on_line_input(ev: InputEvent) -> void:
	var key := ev as InputEventKey
	if key and key.pressed and key.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		submit()
	elif key and key.pressed and key.keycode == KEY_TAB:
		_accept(_hi)
	elif ev.is_action_pressed("ui_up", true):
		_move(-1)
	elif ev.is_action_pressed("ui_down", true):
		_move(1)
	elif ev.is_action_pressed("ui_cancel"):
		_line.release_focus()
	elif ev is InputEventAction and ev.is_action_pressed("ui_accept"):
		_accept(_hi)
	elif key and key.pressed and (key.unicode != 0 or key.ctrl_pressed or key.meta_pressed
			or key.keycode in [KEY_BACKSPACE, KEY_DELETE, KEY_LEFT, KEY_RIGHT, KEY_HOME, KEY_END]):
		return  # edição normal: o CodeEdit trata e consome
	elif not (ev is InputEventKey or ev is InputEventAction):
		return
	_line.accept_event()


func _on_text_changed() -> void:
	if "\n" in _line.text:  # colar não pode trazer quebra de linha
		var col := _line.get_caret_column()
		_line.text = _line.text.replace("\r", "").replace("\n", " ")
		_line.set_caret_column(col)
	_clear_error()
	_refresh()


func _clear_error() -> void:
	_err_span = Vector2i(-1, -1)
	_err.visible = false
	_hint.visible = false
	_line.queue_redraw()


func submit() -> void:
	if _ctx == null:
		return
	var r := CommandResolver.resolve(CommandParser.parse(_line.text), _ctx)
	if not r.ok:
		_err.text = r.error.message
		_err.visible = true
		_hint.text = r.error.hint
		_hint.visible = r.error.hint != ""
		_err_span = r.error.span
		_line.queue_redraw()
		return
	_status.text = "✓ compilado, executando…"
	_status.visible = true
	get_tree().create_timer(0.4).timeout.connect(func(): _status.visible = false)
	text = ""
	command_ready.emit(r)


func _refresh() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_sugs = []
	if _ctx != null:
		_sugs = CommandCompleter.suggest(_line.text, _ctx)
	_hi = clampi(_hi, 0, maxi(_sugs.size() - 1, 0))
	if not _sugs.is_empty() and not _sugs[_hi].enabled:
		_hi = 0
	for i in mini(_sugs.size(), MAX_SUGGESTIONS):
		var s := _sugs[i]
		var b := Button.new()
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_ALL if _pad else Control.FOCUS_NONE
		b.text = "%s%s   %s" % ["▶ " if i == _hi else "   ", s.label, s.detail]
		b.add_theme_font_override("font", BattleFonts.mono())
		b.add_theme_color_override("font_color", Color("#1b1b1b") if s.enabled else Color("#9aa3b2"))
		b.pressed.connect(_accept.bind(i))
		_list.add_child(b)
	if _pad and _list.get_child_count() > 0:
		_list.get_child(mini(_hi, _list.get_child_count() - 1)).grab_focus.call_deferred()


func _move(dir: int) -> void:
	if _sugs.is_empty():
		return
	_hi = posmod(_hi + dir, mini(_sugs.size(), MAX_SUGGESTIONS))
	_refresh()


func _accept(i: int) -> void:
	if i >= _sugs.size() or not _sugs[i].enabled:
		return
	_hi = 0
	text = _sugs[i].result_text
	if not _pad:
		_line.grab_focus()


func _delete_last_token() -> void:
	var t := _line.text.rstrip(" ,.(")
	var cut := maxi(t.rfind("."), maxi(t.rfind("("), t.rfind(",")))
	text = t.substr(0, cut + 1) if cut >= 0 else ""


# Sublinhado vermelho ondulado sob o trecho com erro.
func _draw_error() -> void:
	if _err_span.x < 0:
		return
	var f := _line.get_theme_font("font")
	var fs := _line.get_theme_font_size("font_size")
	var box := _line.get_theme_stylebox("normal")
	var t := _line.text
	var x0 := box.get_margin(SIDE_LEFT) + f.get_string_size(t.substr(0, _err_span.x), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x1 := box.get_margin(SIDE_LEFT) + f.get_string_size(t.substr(0, _err_span.y), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var y := box.get_margin(SIDE_TOP) + f.get_height(fs) + 1.0
	var pts := PackedVector2Array()
	var x := x0
	var up := false
	while x < x1:
		pts.append(Vector2(x, y - (2.0 if up else 0.0)))
		up = not up
		x += 3.0
	pts.append(Vector2(x1, y))
	_line.draw_polyline(pts, ERR_COLOR, 2.0)
