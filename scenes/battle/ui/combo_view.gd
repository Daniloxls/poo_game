class_name ComboView
extends PanelContainer
## "COMBO xN" com barra de calor de 5 passos; pulsa ao subir, treme e fica cinza ao zerar.

const COLD := Color("#3a7be8")
const HOT := Color("#ffb347")
const GREY := Color("#9aa3b2")

var _label: Label
var _steps: Array[ColorRect] = []
var _level := 0


func _init() -> void:
	theme = load("res://scenes/battle/ui/battle_theme.tres")
	theme_type_variation = &"BattlePanel"
	var box := VBoxContainer.new()
	add_child(box)
	_label = Label.new()
	_label.add_theme_font_override("font", BattleFonts.display())
	box.add_child(_label)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 3)
	box.add_child(bar)
	for i in ComboMeter.MAX_LEVEL:
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(18, 10)
		bar.add_child(r)
		_steps.append(r)
	resized.connect(func(): pivot_offset = size / 2)
	_show(0)


func bind(meter: ComboMeter) -> void:
	meter.changed.connect(_on_changed)
	_show(meter.level)


func _on_changed(level: int) -> void:
	var up := level > _level
	_show(level)
	var t := create_tween()
	if up:
		scale = Vector2(1.25, 1.25)
		t.tween_property(self, "scale", Vector2.ONE, 0.2)
	else:
		var x := position.x
		for i in 4:
			t.tween_property(self, "position:x", x + (4 if i % 2 == 0 else -4), 0.03)
		t.tween_property(self, "position:x", x, 0.03)


func _show(level: int) -> void:
	_level = level
	_label.text = "COMBO x%d" % level
	_label.add_theme_color_override("font_color", GREY if level == 0 else Color("#1b1b1b"))
	for i in _steps.size():
		_steps[i].color = COLD.lerp(HOT, i / float(_steps.size() - 1)) if i < level else GREY.darkened(0.4)
