class_name ActionMenu
extends Control
## Menu de métodos do personagem da vez, ao lado do sprite.

signal skill_chosen(skill: SKILL)

const THEME := preload("res://scenes/battle/ui/battle_theme.tres")
const ROT := [-2.0, 1.5, -1.0]

var _box: VBoxContainer
var _tip: PanelContainer
var _tip_label: Label


func _init() -> void:
	theme = THEME
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)
	_tip = PanelContainer.new()
	_tip.theme_type_variation = &"BattlePanel"
	_tip.visible = false
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_label = Label.new()
	_tip_label.add_theme_color_override("font_color", Color("#1b1b1b"))
	_tip_label.add_theme_font_size_override("font_size", 14)
	_tip.add_child(_tip_label)
	add_child(_tip)


func buttons() -> Array:
	return _box.get_children().filter(func(n): return not n.is_queued_for_deletion())


# Abre à esquerda do sprite (anchor = posição do sprite na tela).
func open_for(_actor, skills: Array, anchor: Vector2) -> void:
	close()
	visible = true
	for i in skills.size():
		var s: SKILL = skills[i]
		var b := Button.new()
		b.theme_type_variation = &"MethodButton"
		b.text = BattleContext.method_name(s) + "()"
		b.icon = DamageType.icon(s.DAMAGE_TYPE)
		b.custom_minimum_size = Vector2(190, 44)
		b.rotation_degrees = ROT[i % ROT.size()]
		_tint(b, DamageType.color(s.DAMAGE_TYPE))
		b.resized.connect(func(): b.pivot_offset = b.size / 2)
		b.focus_entered.connect(_on_focus.bind(b, s))
		b.focus_exited.connect(func(): _tip.visible = false; _scale_to(b, 1.0))
		b.mouse_entered.connect(b.grab_focus)
		b.pressed.connect(func(): skill_chosen.emit(s))
		_box.add_child(b)
		b.scale = Vector2.ZERO
		b.modulate.a = 0.0
		var t := b.create_tween().set_parallel()
		t.tween_property(b, "modulate:a", 1.0, 0.15).set_delay(i * 0.05)
		t.tween_property(b, "scale", Vector2.ONE, 0.25).set_delay(i * 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.finished.connect(func(): if b.has_focus(): _scale_to(b, 1.1))
		b.set_meta("pop", t)
	_box.position = anchor - Vector2(230, 24 * skills.size())
	_tip.position = _box.position + Vector2(0, 52 * skills.size() + 8)
	if _box.get_child_count() > 0:
		_box.get_child(0).grab_focus.call_deferred()


func close() -> void:
	visible = false
	_tip.visible = false
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()


# Fundo na cor do tipo de dano (cópia das caixas do tema).
func _tint(b: Button, col: Color) -> void:
	for n in ["normal", "hover", "pressed"]:
		var sb = THEME.get_stylebox(n, &"MethodButton").duplicate()
		sb.bg_color = col if n != "pressed" else col.darkened(0.2)
		b.add_theme_stylebox_override(n, sb)


func _on_focus(b: Button, s: SKILL) -> void:
	_tip_label.text = s.DESCRIPTION
	_tip.visible = s.DESCRIPTION != ""
	_tip.size = Vector2.ZERO
	_scale_to(b, 1.1)


func _scale_to(b: Button, k: float) -> void:
	if b.has_meta("pop") and (b.get_meta("pop") as Tween).is_running():
		return  # o fim da animação de entrada aplica o foco
	if b.has_meta("sc"):
		(b.get_meta("sc") as Tween).kill()
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector2.ONE * k, 0.1)
	b.set_meta("sc", t)
