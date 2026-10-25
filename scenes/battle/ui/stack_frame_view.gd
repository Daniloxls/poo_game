class_name StackFrameView
extends PanelContainer
## Um frame da pilha: "Turin.turno()" num cartão creme.

var frame: TurnFrame
var label: Label
var status: Label
var _strike: ColorRect
var _fade: Tween
var _status_timer: SceneTreeTimer


func _ready() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	add_child(box)
	label = _mono(16)
	box.add_child(label)
	status = _mono(12)
	status.visible = false
	box.add_child(status)
	_strike = ColorRect.new()
	_strike.color = Color("#1b1b1b")
	_strike.visible = false
	_strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_strike)
	_strike.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	_strike.anchor_top = 0.35
	_strike.anchor_bottom = 0.35
	_strike.offset_top = -1.5
	_strike.offset_bottom = 1.5


func _mono(font_size: int) -> Label:
	var l := Label.new()
	l.theme_type_variation = &"MonoLabel"
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("#1b1b1b"))
	return l


## Aparência segundo o estado do frame; is_top = é o topo da pilha.
func refresh(is_top: bool) -> void:
	if frame == null or label == null:
		return
	var ativo := frame.state == TurnFrame.State.ACTIVE
	if is_top:
		theme_type_variation = &"StackFrameTop"
		rotation_degrees = -2.0
	else:
		theme_type_variation = &"StackFrame" if frame.entity.is_party_member() else &"StackFrameEnemy"
		rotation_degrees = 0.0
	label.text = ("▶ " if is_top else "") + frame.label()
	pivot_offset = size / 2.0
	if _status_timer == null:  # não pisa no "▶ retoma" temporário
		_set_status(_state_text())
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 1.0 if ativo else 0.6, 0.12)


func _state_text() -> String:
	match frame.state:
		TurnFrame.State.PAUSED: return "⏸ pausado"
		TurnFrame.State.KO: return "⏸ HP 0"
	return ""


func _set_status(t: String) -> void:
	status.text = t
	status.visible = t != ""


## Texto temporário (ex.: "▶ retoma"), some sozinho.
func flash_status(t: String, secs: float) -> void:
	_set_status(t)
	var timer := get_tree().create_timer(secs)
	_status_timer = timer
	await timer.timeout
	if _status_timer == timer and is_inside_tree():
		_status_timer = null
		_set_status(_state_text())


func mark_destroyed() -> void:
	_strike.visible = true
	_set_status("destruído")
