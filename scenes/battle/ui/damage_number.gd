class_name DamageNumber
extends Node2D
## Número flutuante no mundo: sobe com overshoot, quica uma vez e some.

var label: Label


static func spawn(parent: Node, at: Vector2, outcome: ActionOutcome) -> void:
	var n := DamageNumber.new()
	n.position = at
	parent.add_child(n)
	n._start(outcome)


func _start(o: ActionOutcome) -> void:
	var text := "MISS"
	var color := Color("#9aa3b2")
	var size := 22
	match o.kind:
		ActionOutcome.Kind.DAMAGE:
			text = ("%d!" % o.amount) if o.crit else str(o.amount)
			color = Color("#ffb347") if o.crit else Color("#ffffff")
			size = 40 if o.crit else 28
		ActionOutcome.Kind.HEAL:
			text = "+%d" % o.amount
			color = Color("#7ee787")
			size = 28
	label = Label.new()
	label.text = text
	label.add_theme_font_override("font", BattleFonts.display())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#1b1b1b"))
	label.add_theme_constant_override("outline_size", 8)
	add_child(label)
	label.position = -label.get_minimum_size() / 2.0
	var y0 := position.y
	var tw := create_tween()
	tw.tween_property(self, "position:y", y0 - 46.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", y0 - 40.0, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.28)
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
