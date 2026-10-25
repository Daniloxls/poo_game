class_name ResultPanel
extends Control
## Base dos painéis de fim: desliza, espera confirmar/clicar e fecha.

signal closed

const THEME := preload("res://scenes/battle/ui/battle_theme.tres")

var instant := false
var _open_ms := 0
var _armed := false  # a confirmação começou com o painel já aberto


func _ready() -> void:
	hide()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = THEME


func _present(title: String, lines: Array, tint: Color) -> void:
	if instant:
		return
	for c in get_children():
		c.free()
	var box := PanelContainer.new()
	box.theme_type_variation = &"BattlePanel"
	box.modulate = tint
	var v := VBoxContainer.new()
	box.add_child(v)
	for i in lines.size() + 1:
		var l := Label.new()
		l.theme_type_variation = &"MonoLabel"
		l.text = title if i == 0 else str(lines[i - 1])
		l.add_theme_color_override("font_color", Color("#1b1b1b"))
		v.add_child(l)
	add_child(box)
	show()
	await get_tree().process_frame
	var target := (size - box.size) / 2.0
	box.position = target + Vector2(0, 80)
	box.modulate.a = 0.0
	_open_ms = Time.get_ticks_msec()
	_armed = false
	var tw := create_tween().set_parallel().set_ignore_time_scale(true)
	tw.tween_property(box, "position", target, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(box, "modulate:a", 1.0, 0.2)
	await closed
	hide()


## Fecha ao SOLTAR (tecla ou clique) uma confirmação apertada com o painel aberto:
## o aperto não chega ao mapa como "interact" logo depois que a batalha libera o jogador.
func _confirm(down: bool) -> void:
	if down:
		_armed = Time.get_ticks_msec() - _open_ms > 300
	elif _armed:
		_armed = false
		closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_confirm(event.is_pressed())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_confirm(event.pressed)
