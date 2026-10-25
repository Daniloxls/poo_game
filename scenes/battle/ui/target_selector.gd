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


func choose(candidates: Array, sprite_of: Callable) -> Array:
	if candidates.is_empty():
		return []
	_cands = candidates
	_sprite_of = sprite_of
	_idx = 0
	var cand_sprites := candidates.map(sprite_of)
	_dim_others(cand_sprites)
	for s in cand_sprites:
		_saved[s] = s.modulate
		var m := Label.new()
		m.text = "▼"
		m.add_theme_font_size_override("font_size", 28)
		m.add_theme_color_override("font_color", Color("#ffd23f"))
		m.add_theme_color_override("font_outline_color", Color("#1b1b1b"))
		m.add_theme_constant_override("outline_size", 6)
		m.position = Vector2(-10, -90)
		s.add_child(m)
		_markers[s] = m
		var base: Color = s.modulate
		var t := create_tween().set_loops()
		t.tween_property(s, "modulate", base * Color(1.35, 1.35, 1.35, 1), 0.35)
		t.tween_property(s, "modulate", base, 0.35)
		var bob := create_tween().set_loops()
		bob.tween_property(m, "position:y", -98.0, 0.3)
		bob.tween_property(m, "position:y", -90.0, 0.3)
		_tweens.append_array([t, bob])
	set_process_unhandled_input(true)
	var r: Array = await _done
	return r


# Escurece (alpha 0.5) os irmãos dos candidatos que não são candidatos.
func _dim_others(cand_sprites: Array) -> void:
	for c in cand_sprites:
		for s in c.get_parent().get_children():
			if s is Node2D and s not in cand_sprites and not _saved.has(s):
				_saved[s] = s.modulate
				s.modulate.a = 0.5


func _unhandled_input(event: InputEvent) -> void:
	if _cands.is_empty():
		return
	if event.is_action_pressed("ui_cancel"):
		_finish([])
	elif event.is_action_pressed("ui_accept"):
		_finish([_cands[_idx]])
	elif event.is_action_pressed("ui_right"):
		_idx = (_idx + 1) % _cands.size()
	elif event.is_action_pressed("ui_left"):
		_idx = (_idx - 1 + _cands.size()) % _cands.size()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for e in _cands:
			var s: Node2D = _sprite_of.call(e)
			var p := s.get_global_mouse_position()
			var hit: bool = s.to_local(p).length() < 48
			if s.has_method("get_rect"):
				hit = s.get_rect().has_point(s.to_local(p))
			if hit:
				_finish([e])
				return


func _finish(result: Array) -> void:
	for t in _tweens:
		t.kill()
	_tweens.clear()
	for s in _markers:
		_markers[s].queue_free()
	for s in _saved:
		if is_instance_valid(s):
			s.modulate = _saved[s]
	_markers.clear()
	_saved.clear()
	_cands = []
	set_process_unhandled_input(false)
	_done.emit(result)
