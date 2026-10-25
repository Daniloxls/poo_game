class_name TargetSelector
extends Node
## Escolha de alvo no campo: realça candidatos, escurece o resto.

signal _done(result: Array)

var _cands: Array = []
var _sprite_of: Callable
var _idx := 0
var _saved := {}    # sprite -> modulate original
var _markers := {}  # sprite -> Label
var _tweens: Array = []
var _scales := {}   # sprite -> escala original
var _active := false


func choose(candidates: Array, sprite_of: Callable) -> Array:
	if _active:
		_finish([])  # não deixa o chamador anterior pendurado
	if candidates.is_empty():
		return []
	_cands = candidates
	_sprite_of = sprite_of
	_idx = 0
	_active = true
	var cand_sprites := candidates.map(sprite_of)
	_dim_others(cand_sprites)
	for sp in cand_sprites:
		_saved[sp] = sp.modulate
		_scales[sp] = sp.scale
		var m := Label.new()
		m.text = "▼"
		m.add_theme_font_size_override("font_size", 28)
		m.add_theme_color_override("font_color", Color("#ffd23f"))
		m.add_theme_color_override("font_outline_color", Color("#1b1b1b"))
		m.add_theme_constant_override("outline_size", 6)
		m.position = Vector2(-10, -90)
		sp.add_child(m)
		_markers[sp] = m
	_refresh()
	set_process_unhandled_input(true)
	var r: Array = await _done
	return r


# Só o alvo selecionado pulsa, balança o marcador e cresce; os outros ficam discretos.
func _refresh() -> void:
	for t in _tweens:
		t.kill()
	_tweens.clear()
	for i in _cands.size():
		var sp: Node2D = _sprite_of.call(_cands[i])
		if not is_instance_valid(sp) or not _markers.has(sp):
			continue
		var m: Label = _markers[sp]
		sp.modulate = _saved[sp]
		sp.scale = _scales[sp]
		var sel := i == _idx
		m.modulate.a = 1.0 if sel else 0.4
		m.position.y = -90
		if sel:
			sp.scale = _scales[sp] * 1.08
			var base: Color = _saved[sp]
			var t := create_tween().set_loops()
			t.tween_property(sp, "modulate", base * Color(1.5, 1.5, 1.5, 1), 0.3)
			t.tween_property(sp, "modulate", base, 0.3)
			var bob := create_tween().set_loops()
			bob.tween_property(m, "position:y", -98.0, 0.3)
			bob.tween_property(m, "position:y", -90.0, 0.3)
			_tweens.append_array([t, bob])


func _select(i: int) -> void:
	if i != _idx:
		_idx = i
		_refresh()


# Escurece (alpha 0.5) os irmãos dos candidatos que não são candidatos.
func _dim_others(cand_sprites: Array) -> void:
	for c in cand_sprites:
		for s in c.get_parent().get_children():
			if s is Node2D and s not in cand_sprites and not _saved.has(s):
				_saved[s] = s.modulate
				s.modulate.a = 0.5


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish([])
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_finish([_cands[_idx]])
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_select((_idx + 1) % _cands.size())
	elif event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		_select((_idx - 1 + _cands.size()) % _cands.size())
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := _hit(event.position)
		if i >= 0:
			get_viewport().set_input_as_handled()
			_finish([_cands[i]])
	elif event is InputEventMouseMotion:
		var i := _hit(event.position)
		if i >= 0:
			_select(i)


# Índice do candidato sob o mouse, ou -1.
func _hit(_screen_pos: Vector2) -> int:
	for i in _cands.size():
		var sp: Node2D = _sprite_of.call(_cands[i])
		if not is_instance_valid(sp):
			continue
		var local := sp.to_local(sp.get_global_mouse_position())
		var hit: bool = local.length() < 48
		if sp.has_method("get_rect"):
			hit = sp.get_rect().has_point(local)
		if hit:
			return i
	return -1


func _finish(result: Array) -> void:
	_active = false
	for t in _tweens:
		t.kill()
	_tweens.clear()
	for sp in _markers:
		if is_instance_valid(_markers[sp]):
			_markers[sp].queue_free()
	for sp in _saved:
		if is_instance_valid(sp):
			sp.modulate = _saved[sp]
	for sp in _scales:
		if is_instance_valid(sp):
			sp.scale = _scales[sp]
	_markers.clear()
	_saved.clear()
	_scales.clear()
	_cands = []
	set_process_unhandled_input(false)
	_done.emit(result)
