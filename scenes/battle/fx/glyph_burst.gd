class_name GlyphBurst
extends Node2D
## Glifos de código (0 1 { } ;) que sobem 60 px e somem: o inimigo virou lixo coletado.

const GLYPHS := ["0", "1", "{", "}", ";"]


static func spawn(parent: Node, at: Vector2) -> void:
	var b: GlyphBurst = load("res://scenes/battle/fx/glyph_burst.tscn").instantiate()
	parent.add_child(b)
	b.global_position = at


func _ready() -> void:
	for i in 12:
		var l := Label.new()
		l.text = GLYPHS[i % GLYPHS.size()]
		l.add_theme_font_override("font", BattleFonts.mono())
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", Color("#7ee787"))
		l.add_theme_color_override("font_outline_color", Color("#1b1b1b"))
		l.add_theme_constant_override("outline_size", 4)
		l.position = Vector2(randf_range(-40, 40), randf_range(-30, 30))
		add_child(l)
		var tw := create_tween().set_parallel()
		tw.tween_property(l, "position:y", l.position.y - 60.0, randf_range(0.6, 1.0))
		tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.2)
	get_tree().create_timer(1.2).timeout.connect(queue_free)
