class_name HardShadowStyleBox
extends StyleBox
## Painel cartoon: contorno grosso e sombra dura deslocada (sem blur).

@export var bg_color := Color("#fff8e7"):
	set(v):
		bg_color = v
		emit_changed()
@export var border_color := Color("#1b1b1b"):
	set(v):
		border_color = v
		emit_changed()
@export var border_width := 4:
	set(v):
		border_width = v
		emit_changed()
@export var corner_radius := 10:
	set(v):
		corner_radius = v
		emit_changed()
@export var shadow_offset := Vector2(5, 5):
	set(v):
		shadow_offset = v
		emit_changed()
@export var shadow_color := Color("#1b1b1b"):
	set(v):
		shadow_color = v
		emit_changed()

func _init() -> void:
	content_margin_left = 10; content_margin_right = 10
	content_margin_top = 6; content_margin_bottom = 6

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var sombra := StyleBoxFlat.new()
	sombra.bg_color = shadow_color
	sombra.set_corner_radius_all(corner_radius)
	sombra.draw(to_canvas_item, Rect2(rect.position + shadow_offset, rect.size))
	var painel := StyleBoxFlat.new()
	painel.bg_color = bg_color
	painel.border_color = border_color
	painel.set_border_width_all(border_width)
	painel.set_corner_radius_all(corner_radius)
	painel.draw(to_canvas_item, rect)

func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect.merge(Rect2(rect.position + shadow_offset, rect.size))
