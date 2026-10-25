class_name StackPanel
extends Control
## Painel da pilha de chamadas (canto superior direito). Anima push, pop,
## remoção e KO, em fila, para o jogador enxergar a pilha.

signal animation_finished

const ViewScene = preload("res://scenes/battle/ui/stack_frame_view.tscn")

var frames_box: VBoxContainer
var count_label: Label

var _stack: CallStack
var _world_pos_of: Callable
var _views := {}      # TurnFrame -> StackFrameView
var _queue: Array = []
var _running := false


func _init() -> void:
	theme = load("res://scenes/battle/ui/battle_theme.tres")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := PanelContainer.new()
	box.theme_type_variation = &"StackContainer"
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.offset_left = -260
	box.offset_right = -16
	box.offset_top = 16
	add_child(box)
	var col := VBoxContainer.new()
	box.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	head.add_child(_label("PILHA", false))
	count_label = _label("0", true)
	head.add_child(count_label)
	frames_box = VBoxContainer.new()
	frames_box.add_theme_constant_override("separation", 6)
	col.add_child(frames_box)
	var base := ColorRect.new()  # linha de base da pilha
	base.color = Color("#fff8e7")
	base.custom_minimum_size = Vector2(0, 4)
	col.add_child(base)


func _label(t: String, expand: bool) -> Label:
	var l := Label.new()
	l.theme_type_variation = &"MonoLabel"
	l.text = t
	l.add_theme_color_override("font_color", Color("#fff8e7"))
	if expand:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return l


func bind(stack: CallStack, world_pos_of: Callable) -> void:
	_stack = stack
	_world_pos_of = world_pos_of
	stack.pushed.connect(func(f, i): _enqueue(_anim_push.bind(f, i)))
	stack.popped.connect(func(f, r): _enqueue(_anim_pop.bind(f, r)))
	stack.frame_removed.connect(func(f): _enqueue(_anim_remove.bind(f)))
	stack.knocked_out.connect(func(f): _enqueue(_anim_ko.bind(f)))


func view_for(frame: TurnFrame) -> StackFrameView:
	return _views.get(frame)


## Ainda animando a fila (o orquestrador espera antes de seguir).
func is_busy() -> bool:
	return _running


## Fim da batalha: some com todas as views. Chamar com a fila parada.
func clear() -> void:
	for f in _views:
		_views[f].queue_free()
	_views.clear()
	count_label.text = "0"


func _enqueue(anim: Callable) -> void:
	_queue.append(anim)
	if _running:
		return
	_running = true
	while not _queue.is_empty():
		await _queue.pop_front().call()
	_running = false
	animation_finished.emit()


## Reaplica estado/tema em todas as views e atualiza a contagem.
func _refresh_all() -> void:
	var topo := _stack.peek()
	for f in _views:
		_views[f].refresh(f == topo)
	count_label.text = str(_stack.size())


func _anim_push(frame: TurnFrame, interrupted: TurnFrame) -> void:
	var v: StackFrameView = ViewScene.instantiate()
	v.frame = frame
	_views[frame] = v
	v.modulate.a = 0.0
	frames_box.add_child(v)
	frames_box.move_child(v, 0)  # topo da pilha fica em cima
	await get_tree().process_frame  # deixa o container posicionar
	# cartão voa do sprite até o lugar
	var ghost := PanelContainer.new()
	ghost.theme_type_variation = &"StackFrameTop"
	var gl := Label.new()
	gl.theme_type_variation = &"MonoLabel"
	gl.text = frame.label()
	gl.add_theme_color_override("font_color", Color("#1b1b1b"))
	ghost.add_child(gl)
	add_child(ghost)
	ghost.top_level = true
	ghost.global_position = _world_pos_of.call(frame.entity)
	ghost.scale = Vector2(0.5, 0.5)
	if interrupted and _views.has(interrupted):
		_interrupt_tag(v)
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ghost, "global_position", v.global_position, 0.28)
	tw.tween_property(ghost, "scale", Vector2.ONE, 0.28)
	await tw.finished
	ghost.queue_free()
	v.modulate.a = 1.0
	_refresh_all()  # o de baixo escurece e mostra "⏸ pausado"


## Etiqueta amarela "INTERROMPE!" (-6°) que pisca e some.
func _interrupt_tag(v: Control) -> void:
	var tag := Label.new()
	tag.text = "INTERROMPE!"
	tag.theme_type_variation = &"MonoLabel"
	tag.add_theme_color_override("font_color", Color.BLACK)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#ffd23f")
	sb.set_content_margin_all(3)
	tag.add_theme_stylebox_override("normal", sb)
	add_child(tag)
	tag.top_level = true
	tag.rotation_degrees = -6.0
	tag.global_position = v.global_position + Vector2(-10, -14)
	var tw := create_tween()
	tw.tween_interval(0.15)
	tw.tween_property(tag, "modulate:a", 0.0, 0.2)
	tw.tween_callback(tag.queue_free)


## Tira a view do container (que reposicionaria o tween), mantendo a posição na tela.
func _detach(v: Control) -> void:
	var gp := v.global_position
	var sz := v.size
	frames_box.remove_child(v)
	add_child(v)
	v.top_level = true
	v.size = sz
	v.global_position = gp


func _anim_pop(frame: TurnFrame, resumed: TurnFrame) -> void:
	var v: StackFrameView = _views.get(frame)
	_views.erase(frame)
	if v:
		_detach(v)
		var tw := create_tween().set_parallel()
		tw.tween_property(v, "position:y", v.position.y - 14, 0.15)  # levanta
		tw.tween_property(v, "modulate:a", 0.0, 0.25)
		tw.tween_property(v, "position:x", v.position.x + 60, 0.25).set_delay(0.1)
		await tw.finished
		v.get_parent().remove_child(v)
		v.queue_free()
	_refresh_all()
	if resumed and _views.has(resumed):
		_views[resumed].flash_status("▶ retoma", 0.6)


func _anim_remove(frame: TurnFrame) -> void:
	var v: StackFrameView = _views.get(frame)
	_views.erase(frame)
	if v == null:
		return
	v.mark_destroyed()
	_detach(v)
	var tw := create_tween()
	tw.tween_interval(0.1)
	tw.tween_property(v, "position:x", v.position.x + 300, 0.25)
	await tw.finished
	v.get_parent().remove_child(v)
	v.queue_free()
	_refresh_all()


func _anim_ko(frame: TurnFrame) -> void:
	_refresh_all()  # estado KO -> "⏸ HP 0"
	var v := view_for(frame)
	if v:
		var tw := create_tween()
		tw.tween_property(v, "scale", Vector2(1.08, 1.08), 0.08)
		tw.tween_property(v, "scale", Vector2.ONE, 0.12)
		await tw.finished
